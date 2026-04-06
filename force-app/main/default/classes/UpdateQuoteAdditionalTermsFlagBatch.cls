/**
 * @class Name :- UpdateQuoteAdditionalTermsFlagBatch 
 * @description :- CPQ22-5226, Batch class to update the Additional_Terms_Required__c flag on Inflight Quote records based on specific conditions.
 * It evaluates both Quote-level and QuoteLine-level conditions, and also checks associated QuoteTerms.
 * If any conditions are met, the flag is set to true and the record is updated.
 * After processing, it sends an email with a CSV attachment of the updated records.
 * @author :- Mustakim Shaikh
 * @Created Date :- 30-07-2025 
 * To execute this batch with 3 records at a time, run the following Anonymous Apex:
 * Database.executeBatch(new UpdateQuoteAdditionalTermsFlagBatch(), 3);
*   
//********************Change Logs*****************************************************************************
* 
* Change Request            Modified By          Date           Description 
* 
*  
//********************Change Logs Ends*************************************************************************
**/
public class UpdateQuoteAdditionalTermsFlagBatch implements Database.Batchable<SObject>, Database.Stateful {

        // To collect processed Quotes for the email
        List<SBQQ__Quote__c> processedQuotes = new List<SBQQ__Quote__c>();

       /**
        * @description : This method is called at the start of the batch process.
        * It constructs a query to retrieve SBQQ__Quote__c records that meet specific criteria.
        * The query includes fields related to the quote and its associated opportunity, as well as line items that meet certain conditions.
        * @param bc : The context for the batchable operation.
        * @return : A Database.QueryLocator object that contains the results of the query.
        **/ 
        public Database.QueryLocator start(Database.BatchableContext bc) {
            String query = 'SELECT SBQQ__Primary__c, Id, Name, SBQQ__Status__c, ApprovalStatus__c, SBQQ__Opportunity2__r.Id, SBQQ__Opportunity2__r.Name, SBQQ__Opportunity2__r.StageName, SBQQ__QuoteTemplateId__c, OpportunitySubType__c, Additional_Month_added__c, Check_RCV__c, Special_Requirements_Needed__c, Additional_Terms_Required__c, ' +
                '(SELECT Id, Product_Type__c, Disposition_Reason__c FROM SBQQ__LineItems__r WHERE (Disposition_Reason__c = null OR Disposition_Reason__c IN (\'None\', \'Renewing\', \'Upgrade\')) AND Product_Type__c IN (\'Cloud Vault Archive\', \'Cloud Vault Backup\') ) ' +
                'FROM SBQQ__Quote__c ' +
                'WHERE ApprovalStatus__c = \'Approved\' AND SBQQ__QuoteTemplateId__c != null ' +
                'AND (SBQQ__Opportunity2__r.StageName IN (\'0 Nurture\', \'1 Discovery\', \'2 Consensus\', \'3 Technical Validation\', \'4 Business Justification\', \'5 Negotiate & Close\') ' +
                'OR (SBQQ__Opportunity2__r.StageName = \'6 PO With Channel\' AND SBQQ__Opportunity2__r.SBQQ__Ordered__c = false)) ' +
                'ORDER BY SBQQ__Opportunity2__r.StageName, SBQQ__Status__c ';
            return Database.getQueryLocator(query);
        }

        /**
         * @description : This method is called to process a batch of SBQQ__Quote__c records.
         * It evaluates each quote against a set of conditions defined in Addnl_TnC_Query_Clause__mdt metadata records.
         * If any conditions are met, the Additional_Terms_Required__c flag is set to true.
         * It also checks associated QuoteTerms to ensure the flag is set correctly.
         * @param bc : The context for the batchable operation.
         * @param scope : A list of SBQQ__Quote__c records to process in
         **/
        public void execute(Database.BatchableContext bc, List<SBQQ__Quote__c> scope) {
            List<Addnl_TnC_Query_Clause__mdt> clauseLst = Addnl_TnC_Query_Clause__mdt.getAll().values();
            List<SBQQ__Quote__c> updateQt = new List<SBQQ__Quote__c>();
            List<SBQQ__Quote__c> qtTobePassedToCheckQT = new List<SBQQ__Quote__c>();

            for(SBQQ__Quote__c quoteRec : scope){
                Boolean needsUpdate = false;
                if(quoteRec.OpportunitySubType__c == 'GC Offer'){
                    quoteRec.Additional_Terms_Required__c = true;
                    needsUpdate = true;
                }
                // Quote-level conditions
                for (Addnl_TnC_Query_Clause__mdt mdt : clauseLst) {
                    if (mdt.Object_Scope__c == 'Quote' && mdt.FieldName__c != null) {
                        Object fieldValue = quoteRec.get(mdt.FieldName__c);
                        if (QuoteTermReader.evaluateCondition(fieldValue, mdt.Operator__c, mdt.Value__c)) {
                            quoteRec.Additional_Terms_Required__c = true;
                            needsUpdate = true;
                        }
                    }
                }
                // QuoteLine-level conditions
                for (SBQQ__QuoteLine__c ql : quoteRec.SBQQ__LineItems__r) {
                    if (String.isBlank(ql.Disposition_Reason__c) ||
                        new Set<String>{'None', 'Renewing', 'Upgrade'}.contains(ql.Disposition_Reason__c)) {
                        for (Addnl_TnC_Query_Clause__mdt mdt : clauseLst) {
                            if (mdt.Object_Scope__c == 'QuoteLine' && 
                                mdt.FieldName__c != null && 
                                mdt.FieldName__c == 'Product_Type__c') {
                                Object fieldValue = ql.get(mdt.FieldName__c);
                                String value = mdt.Value__c != null ? mdt.Value__c.replaceAll('\'', '') : '';
                                if (QuoteTermReader.evaluateCondition(fieldValue, mdt.Operator__c, value)) {
                                    quoteRec.Additional_Terms_Required__c = true;
                                    needsUpdate = true;
                                }
                            }
                        }
                    }
                }
                if(needsUpdate){
                    updateQt.add(quoteRec);
                } else {
                    qtTobePassedToCheckQT.add(quoteRec);
                }
            }

            // QuoteTerm check
            if(!qtTobePassedToCheckQT.isEmpty()){
                Set<Id> qTermsIdSet = new Set<Id>();
                Map<Id, List<Id>> mapQtIdvsListofQTermIds = new Map<Id, List<Id>>();
                for(SBQQ__Quote__c quoteRec : qtTobePassedToCheckQT){
                    QuoteTermReader quoteTermReader = new QuoteTermReader();
                    List<QuoteTermModel> quoteTerms = quoteTermReader.load(quoteRec.Id, quoteRec.SBQQ__QuoteTemplateId__c, 'es');
                    for(QuoteTermModel qTerm: quoteTerms){
                        if(!mapQtIdvsListofQTermIds.containsKey(quoteRec.Id)) {
                            mapQtIdvsListofQTermIds.put(quoteRec.Id, new List<Id>());
                        }
                        mapQtIdvsListofQTermIds.get(quoteRec.Id).add(qTerm.Id);
                        qTermsIdSet.add(qTerm.Id);
                    }
                }
                if(!qTermsIdSet.isEmpty()){
                    Map<Id, SBQQ__QuoteTerm__c> adnlQuoteTermsList = new Map<Id, SBQQ__QuoteTerm__c>([SELECT Id FROM SBQQ__QuoteTerm__c WHERE Id IN :qTermsIdSet AND Additional_Term__c = true]);
                    for(SBQQ__Quote__c quoteRec : qtTobePassedToCheckQT){
                        for (Id qtId : adnlQuoteTermsList.keySet()) { if(mapQtIdvsListofQTermIds.containsKey(quoteRec.Id) && mapQtIdvsListofQTermIds.get(quoteRec.Id).contains(qtId)) {
                                quoteRec.Additional_Terms_Required__c = true;
                                updateQt.add(quoteRec);
                                break;
                            }
                        }
                    }
                }
            }

            if(!updateQt.isEmpty()){
                SBQQ.TriggerControl.disable();
                TriggerControls.disableQuoteTrigger = true;
                TriggerControls.disableQuoteLineTrigger = true;
                try{
                    update updateQt;
                }finally{
                    SBQQ.TriggerControl.enable();
                }
                processedQuotes.addAll(updateQt);
            }
        }

        /**
         * @description : This method is called at the end of the batch process.
         * It sends an email with a CSV attachment containing the processed quotes.
         * @param bc : The context for the batchable operation.
         * It checks if there are any processed quotes and sends an email with the CSV data.
         * If an error occurs during email sending, it logs the error message.
         **/
        public void finish(Database.BatchableContext bc) {
            if(!processedQuotes.isEmpty()){
                try{
                    sendCsvDataEmail(processedQuotes);
                } catch (Exception e) {
                    System.Debug(LoggingLevel.INFO, 'Error Message '+ e.getMessage());
                }
            }
        }

        /**
         * @description : This method generates a CSV string from a list of SBQQ__Quote__c records.
         * It includes various fields from the quote and its associated opportunity.
         * @param updateQt : A list of SBQQ__Quote__c records to convert to CSV format.
         **/
        public static void sendCsvDataEmail(List<SBQQ__Quote__c> updateQt) {
            String csvString = generateCsvString(updateQt);
            Blob csvBlob = Blob.valueOf(csvString);

            Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
            csvAttachment.setFileName('MS_5343_AdditionalTerm_UpdateQt_InflightData.csv');
            csvAttachment.setBody(csvBlob);

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSubject('MS 5343 AdditionalTerm Update Quote Inflight Data CSV');
            mail.setPlainTextBody('Please find the attached CSV file.');
            mail.setToAddresses(new String[] { 'mustakim.shaikh@rubrik.com' });
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] { csvAttachment });

            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            if (results[0].isSuccess()) {
                System.debug(LoggingLevel.INFO, 'Email sent successfully');
            } else {
                System.debug(LoggingLevel.INFO, 'MS 5226 Inflight Data Update Batch Error sending email: ' + results[0].getErrors()[0].getMessage());
            }
        }

        /**
         * @description : This method generates a CSV string from a list of SBQQ__Quote__c records.
         * It includes various fields from the quote and its associated opportunity.
         * @param updateQt : A list of SBQQ__Quote__c records to convert to CSV format.
         * @return : A string representing the CSV data.
         * The CSV includes fields such as Opportunity Stage, Subtype, Approval Status, Quote Status, Primary Flag, Quote ID, Name, Additional Month Added, Check RCV, Special Requirements Needed, Opportunity ID, Opportunity Name, and Quote Template ID.
         * Each field is separated by a comma, and each record is on a new line.
         * The method also handles null values by escaping them appropriately.
         **/
        public static String generateCsvString(List<SBQQ__Quote__c> updateQt) {
            String csvString = '';
            csvString += 'SBQQ__Opportunity2__r.StageName' + ',';
            csvString += 'OpportunitySubType__c' + ',';
            csvString += 'ApprovalStatus__c' + ',';
            csvString += 'SBQQ__Status__c' + ',';
            csvString += 'SBQQ__Primary__c' + ',';
            csvString += 'Id' + ',';
            csvString += 'Name' + ',';
            csvString += 'Additional_Month_added__c' + ',';
            csvString += 'Check_RCV__c' + ',';
            csvString += 'Special_Requirements_Needed__c' + ',';
            csvString += 'SBQQ__Opportunity2__r.Id' + ',';
            csvString += 'SBQQ__Opportunity2__r.Name' + ',';
            csvString += 'SBQQ__QuoteTemplateId__c' + '\n';    
            
            for (SBQQ__Quote__c qt : updateQt) {
                String oppId = qt.SBQQ__Opportunity2__r != null ? String.valueOf(qt.SBQQ__Opportunity2__r.Id) : '';
                String oppName = qt.SBQQ__Opportunity2__r != null ? qt.SBQQ__Opportunity2__r.Name.escapeCsv() : '';
                String oppStage = qt.SBQQ__Opportunity2__r != null ? qt.SBQQ__Opportunity2__r.StageName.escapeCsv() : '';
                csvString += 
                    oppStage + ',' +
                    (qt.OpportunitySubType__c != null ? qt.OpportunitySubType__c.escapeCsv() : '') + ',' +
                    (qt.ApprovalStatus__c != null ? qt.ApprovalStatus__c.escapeCsv() : '') + ',' +
                    (qt.SBQQ__Status__c != null ? qt.SBQQ__Status__c.escapeCsv() : '') + ','  +
                    qt.SBQQ__Primary__c + ',' +
                    qt.Id + ',' +
                    qt.Name.escapeCsv() + ',' +
                    qt.Additional_Month_added__c + ',' +
                    qt.Check_RCV__c + ',' +
                    qt.Special_Requirements_Needed__c + ',' +
                    oppId + ',' +
                    oppName + ',' +
                    qt.SBQQ__QuoteTemplateId__c + '\n';
            }
            return csvString;
        }
    }