global class Opportunity_EOLProductBatch implements Database.Batchable<sObject>, Database.stateful{
    public Set<Opportunity> processedOpptys = new Set<Opportunity>();
   global String timestamp;
   List<Custom_Error_Log__c> errorLogList = new List<Custom_Error_Log__c>();
    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        timestamp = String.Valueof(datetime.now()); //and OpportunityId = \'006S0000009yFdQ\' ,Order_Service_Item__r.Product2Id
    /* FOR TEST PURPOSE ONLY
        string oppId='0061W00000xYA3ZQAW';
        string whereClause = ' id = \'' + oppId + '\' ';
        //String query = 'SELECT Id,PBE_Product_Code__c,Product2.Family, ProductCode,OpportunityId, Opportunity.StageName,Opportunity.CloseDate FROM OpportunityLineItem where '+whereClause;
        return Database.getQueryLocator('select id ,Account.name,AccountID, Renewed__c, Account.OwnerID,startDate,EndDate,Order_Service_Item__r.Order.Opportunity.OwnerID,Order_Service_Item__r.Order.Opportunity.LeadSource,Order_Service_Item__r.Order.Opportunity.Partner_Lookup__c,Order_Service_Item__r.Order.Opportunity.Distributor_Lookup__c  from Entitlement where '+whereClause);
    */
        //date triggerDate = System.Today().addMonths(4);
        List<String> stagesToExclude = new List<String>();
        stagesToExclude.addAll(System.Label.Opportunity_Stages.split(','));
        List<String> prodFamily = new List<String>();
        prodFamily.addAll(System.Label.EOL_Products.split(','));
        date EOLDate = date.parse(System.Label.Product_EOL_Date);
        System.debug('EOLDate=='+EOLDate);
        System.debug('stagesToExclude=='+stagesToExclude);
        System.debug('prodFamily=='+prodFamily);
        string whereClause_Date = ' CloseDate = '+ EOLDate ;
        String dateStr = DateTime.newInstance(EOLDate.year(),EOLDate.month(),EOLDate.day()).format('yyyy-MM-dd');
        //String query = 'select id ,CloseDate from Opportunity where closeDate >='+ dateStr+' AND StageName NOT IN '+stagesToExclude + (Test.isRunningTest()?' LIMIT 20':'');

        String query = 'SELECT Id'
                          + ', PBE_Product_Code__c'
                          + ', Product2.Family'
                          + ', ProductCode'
                          + ', OpportunityId'
                          + ', Opportunity.StageName'
                          + ', Opportunity.CloseDate'
                    + ' FROM OpportunityLineItem' 
                    + ' WHERE Opportunity.CloseDate >= ' + dateStr
                    + ' AND Opportunity.StageName NOT IN ' + stagesToExclude
                    + ' AND Product2.Family IN ' + prodFamily
                    + ' AND Opportunity.SBQQSC__AmendedServiceContract__c = NULL'
                    + (Test.isRunningTest()? ' LIMIT 20' : '');
        System.debug('query---'+query);
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<OpportunityLineItem> scope){
        String relatedRecordId;
        try{
            
            System.debug('scope=='+scope);
            Set<Id> matchingOpptys= new Set<Id>();
            List<Opportunity> oppsToBeUpdated = new List<Opportunity>();
            for(OpportunityLineItem oItem : scope){
                matchingOpptys.add(oItem.OpportunityId);
            }
            for(Opportunity opp :[select id,Send_EOL_Email__c from  Opportunity where ID IN :matchingOpptys]){
                relatedRecordId = opp.Id;
                opp.Send_EOL_Email__c = true;
                oppsToBeUpdated.add(opp);
            }
            System.debug('oppsToBeUpdated Size=='+oppsToBeUpdated.size());
            if(!oppsToBeUpdated.isEmpty()){
                if(Test.isRunningTest()){
                    oppsToBeUpdated[0].Id = '';
                }
                List<Database.SaveResult> srList = Database.update(oppsToBeUpdated,false);
                /*** Start SAL25-717 */
                errorLogList = LogError.createDMLErrorLogWithRetrunType((List<SObject>)oppsToBeUpdated, srList, 'Opportunity_EOLProductBatch','Opportunity update failed');
                /*** End SAL25-717 */
                
            }
        }
        catch(Exception ex){
            system.debug('Excpetion in Opportunity_EOLProductBatch Execute Method'+ex);
            EntitlementToSCHelperClass.createErrorRecord(ex.getMessage(),'Opportunity_EOLProductBatch','Opportunity_EOLProductBatch', ex.getTypeName(), ex.getLineNumber(),relatedRecordId,null,timestamp,'');
        }
    }
    global void finish(Database.BatchableContext processOpptys) {
        /*** Start SAL25-717 */
        if(!errorLogList.IsEmpty()){
            string emailDetail = EmailHelper.prepareEmailBodyForCustomErrorLog(errorLogList);
            EmailHelper.sendBatchErrorsEmail(new List<String>{System.Label.SalesApps_Support_Email},
                                            'Opportunity_EOLProductBatch - ' + Date.today().format(),
                                            emailDetail); 
         }
        /*** End SAL25-717 */
    }
}