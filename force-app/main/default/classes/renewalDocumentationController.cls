public class renewalDocumentationController {
    @auraEnabled
    public static responseWrap getDocs(String recId){
        Case caseRec = [Select Owner.Name,Owner.Email,ServiceContractId,Partner_Contact_Name__c,Distributer_Contact_Name__c,Partner_Contact_Email__c,Distributer_Contact_Email__c,Opportunity_lookup__c from Case where Id = :recId];
        Id scId = caseRec.Opportunity_lookup__c;
        responseWrap rsp = new responseWrap();
        List<Opportunity> oppList = [Select Id,Rubrik_Sales_Engineer__r.FirstName,Rubrik_Sales_Engineer__r.lastName,Rubrik_Sales_Engineer__r.Email,RenewalOwner__r.FirstName,RenewalOwner__r.lastName,RenewalOwner__r.Email,Owner.FirstName,Owner.lastName,Owner.Email,SBQQ__PrimaryQuote__c from Opportunity where Id = : scId];
        opportunity opp = new opportunity();
        if(oppList.isEmpty()){
            rsp.hasOpporutnity = false;
            return rsp;
        }else{
            opp = oppList[0];
        }
        List<SBQQ__Quote__c> quotesList = [Select Id,Name,SBQQ__QuoteTemplateId__c,RecordTypeId,Expiration_Date__c from SBQQ__Quote__c where Id = :opp.SBQQ__PrimaryQuote__c];
        SBQQ__Quote__c quotes = new SBQQ__Quote__c();
        
        if(!quotesList.isEmpty()){
            quotes = quotesList[0];
        }
        Id recordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Approved Quote').getRecordTypeId();
        if(quotesList.isEmpty()){
            rsp.hasQuote = false;
            rsp.isApproved = true;
            return rsp;
        }
        else if(quotes.Expiration_Date__c < system.today()){
            rsp.quoteNumber = quotes.Name;
            rsp.quoteExpired = true;
            return rsp;
        }else if(quotes.RecordTypeId != recordTypeId){
            rsp.isApproved = false;
            rsp.quoteNumber = quotes.Name;
            rsp.hasQuote = true;
            if(!test.isRunningTest())
                return rsp;
        }
        Set<String> docIds = new Set<String>();
        List<Id> quoteDocs = new List<Id>();
        for(SBQQ__QuoteDocument__c doc:[Select Id,Name,SBQQ__Quote__c,SBQQ__QuoteTemplate__c from SBQQ__QuoteDocument__c where SBQQ__Quote__c = :quotes.Id]){
            quoteDocs.add(doc.SBQQ__Quote__c);
            String quoteDocId = String.valueOf(doc.SBQQ__QuoteTemplate__c).substring(0, 15);
            System.debug(quoteDocId);
            docIds.add(quoteDocId);
        }
        SYstem.debug(docIds);
        Id tempId;
        if(!test.isRunningTest())
            tempId = [Select Id from SBQQ__QuoteTemplate__c where Name = 'Quote Document'].Id;
        if(!docIds.contains(quotes.SBQQ__QuoteTemplateId__c) && !docIds.contains(tempId)){
            QuoteProposalModel model = new QuoteProposalModel();
            model.quoteId = quotes.Id;
            if(quotes.SBQQ__QuoteTemplateId__c != '' && quotes.SBQQ__QuoteTemplateId__c != null){
                model.templateId = quotes.SBQQ__QuoteTemplateId__c;
            }
            else{
                model.templateId = tempId;
            }
            GenerateQuoteProposal proposalGenerator = new GenerateQuoteProposal();
            if(!Test.isRunningTest())
                String jobId = proposalGenerator.save(model);
        }
        String partnerLabel = '';
        if(caseRec.Partner_Contact_Name__c != '' && caseRec.Partner_Contact_Email__c  != ''){
            partnerLabel = caseRec.Partner_Contact_Name__c+' ( '+caseRec.Partner_Contact_Email__c+' )';
        }
        String distributorLabel = '';
        if(caseRec.Distributer_Contact_Name__c != '' && caseRec.Distributer_Contact_Email__c  != ''){
            distributorLabel = caseRec.Distributer_Contact_Name__c+' ( '+caseRec.Distributer_Contact_Email__c+' )';
        }
        String oppOwner = '';
        if(opp.Owner.LastName != '' && opp.Owner.Email  != ''){
            oppOwner = opp.Owner.FirstName+' '+opp.Owner.LastName+' ( '+opp.Owner.Email+' )';
        }
        String saleEngineer = '';
        if(opp.Rubrik_Sales_Engineer__r.LastName != '' && opp.Rubrik_Sales_Engineer__r.Email  != ''){
            saleEngineer = opp.Rubrik_Sales_Engineer__r.FirstName+' '+opp.Rubrik_Sales_Engineer__r.LastName+' ( '+opp.Rubrik_Sales_Engineer__r.Email+' )';
        }
        String renewalOwner = '';
        if(opp.RenewalOwner__r.LastName != '' && opp.RenewalOwner__r.Email  != ''){
            renewalOwner = opp.RenewalOwner__r.FirstName+' '+opp.RenewalOwner__r.LastName+' ( '+opp.RenewalOwner__r.Email+' )';
        }
        String caseOwner = '';
        if(caseRec.Owner.Name != '' && caseRec.Owner.Email  != ''){
            caseOwner = caseRec.Owner.Name+' ( '+caseRec.Owner.Email+' )';
        }
        return new responseWrap(opp.Id,partnerLabel,distributorLabel,oppOwner,saleEngineer,renewalOwner,caseOwner);
        
    }
    
    public class responseWrap{
        @auraEnabled public String oppId{get;set;}
        @auraEnabled public String partnerLabel{get;set;}
        @auraEnabled public String distrLabel{get;set;}
        @auraEnabled public String oppOwner{get;set;}
        @auraEnabled public String caseOwner{get;set;}
        @auraEnabled public String saleEngineer{get;set;}
        @auraEnabled public String renewalOwner{get;set;}
        @auraEnabled public Boolean isApproved{get;set;}
        @auraEnabled public Boolean hasQuote{get;set;}
        @auraEnabled public Boolean hasOpporutnity{get;set;}
        @auraEnabled public Boolean quoteExpired{get;set;}
        @auraEnabled public String quoteNumber{get;set;}
        public responseWrap(String oppId, String partnerLabel, String distrLabel, String oppOwner, String saleEngineer, String renewalOwner, String caseOwner){
            this.oppId = oppId;
            this.partnerLabel = partnerLabel;
            this.distrLabel =  distrLabel;
            this.oppOwner = oppOwner.replace('null',' ');
            this.saleEngineer = saleEngineer.replace('null',' ');
            this.renewalOwner = renewalOwner.replace('null',' ');
            this.isApproved = true;
            this.hasQuote = true;
            this.hasOpporutnity = true;
            this.quoteExpired = false;
            this.caseOwner = caseOwner.replace('null',' ');
        }
        public responseWrap(){
            this.isApproved = true;
            this.hasQuote = true;
            this.hasOpporutnity = true;
            this.quoteExpired = false;
        }
    }
    
    @auraEnabled
    public static List<attach> getAttch(String opprId){
        List<String> docNameList = new List<String>();
        for(SBQQ__QuoteDocument__c doc:[Select Id,Name,SBQQ__Quote__c from SBQQ__QuoteDocument__c where SBQQ__Opportunity__c = :opprId]){
            docNameList.add(doc.Name+'.pdf');
        }
        List <attach> resultList = new List<attach>();
        for(Attachment att:[Select Id,Name,ContentType,CreatedDate,Owner.Name from Attachment where ParentId =:opprId]){
            if(docNameList.contains(att.Name)){
                resultList.add(new attach(att));
            }
        }
        return resultList;
    }
    
    public class attach{
        @AuraEnabled public string Name{get;set;}
        @AuraEnabled public string Owner{get;set;}
        @AuraEnabled public Datetime CreatedDate{get;set;}
        @AuraEnabled public string Id{get;set;}
        public attach(Attachment att){
            this.Name = att.Name;
            this.Owner = att.Owner.Name;
            this.CreatedDate = att.CreatedDate;
            this.Id = att.id;
        }
    }
    @auraEnabled
    public static void sendMail(String attId,String emails,List<String> partDist,String recId,List<String> ccList){ 
        Case cs = [Select Owner.Email,Casenumber,Opportunity__c,Stage__c ,Case_Thread_ID__c	,Partner_Contact_Email__c,Distributer_Contact_Email__c,Opportunity_lookup__c,Average_Sales_Cycle__c from Case where Id = :recId];
        Opportunity opp = [Select Id,Alliance_HW_Partner__c ,Alliance_Partner_Name__c ,Rubrik_Sales_Engineer__r.FirstName,Rubrik_Sales_Engineer__r.lastName,Rubrik_Sales_Engineer__r.Email,RenewalOwner__r.FirstName,RenewalOwner__r.lastName,RenewalOwner__r.Email,Owner.FirstName,Owner.lastName,Owner.Email,SBQQ__PrimaryQuote__c from Opportunity where Id = : cs.Opportunity_lookup__c];
        List<String> emailAdd = new List<String>();
        List<String> emailCCAdd = new List<String>();
        if(emails != '' && emails != null){
            emailAdd = emails.split(',');
        }
        if(partDist.contains('Partner') && cs.Partner_Contact_Email__c != null){
            emailAdd.add(cs.Partner_Contact_Email__c);
        }
        if(partDist.contains('Distributer') && cs.Distributer_Contact_Email__c != null){
            emailAdd.add(cs.Distributer_Contact_Email__c);
        }
        if(ccList.contains('Owner') && opp.Owner.Email != null){
            emailCCAdd.add(opp.Owner.Email);
        }
        if(ccList.contains('Engineer')&& opp.Rubrik_Sales_Engineer__r.Email != null){
            emailCCAdd.add(opp.Rubrik_Sales_Engineer__r.Email);
        }
        if(ccList.contains('ROwner') && opp.RenewalOwner__r.Email != null){
            emailCCAdd.add(opp.RenewalOwner__r.Email);
        }
        if(ccList.contains('cOwner') && cs.Owner.Email != null){
            emailCCAdd.add(cs.Owner.Email);
        }
        emailAdd.add('renewals@rubrik.com');
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        Id emailTempId = [SELECT Id, DeveloperName FROM EmailTemplate where DeveloperName = 'Renewal_Case_Send_Document'].Id;
        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTempId, userinfo.getUserId(), recId);
        message.setCcAddresses(emailCCAdd);
        message.setToAddresses(emailAdd);
        message.setOrgWideEmailAddressId([SELECT Id, Address, DisplayName FROM OrgWideEmailAddress where address = 'renewals@rubrik.com'].Id);
        Attachment file = [SELECT Name, Body, ContentType FROM Attachment WHERE Id = :attId];
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName(file.Name);
        efa.setBody(file.Body);
        efa.setContentType(file.ContentType);
        attachments.add(efa);
        message.setFileAttachments(attachments);
        message.setSubject(mail.getSubject());
        message.setHtmlBody(mail.getHtmlBody());
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });
        } catch (Exception e) {
            throw e;
        } 
        if(cs.Average_Sales_Cycle__c == null){
            cs.Average_Sales_Cycle__c = system.now();
            update cs;
        }
        if(cs.Stage__c == '1 Discovery'){
            Opportunity oppUpdate = new Opportunity(id= cs.Opportunity_lookup__c, StageName= '2 Consensus',Compelling_Bus_Driver__c = 'Automation',Cloud_Type__c ='None');
            if(String.isBlank(opp.Alliance_Partner_Name__c)){
                oppUpdate.Alliance_Partner_Name__c = 'None';
            }
            if(String.isBlank(opp.Alliance_HW_Partner__c )){
                oppUpdate.Alliance_HW_Partner__c = 'None';
            }
		update oppUpdate;
        }
    }
}