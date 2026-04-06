/**
* Date :23-December-2023
* Author : Rajat Jain
* JIRA : SAL24-641 - Trade-Up
* TestClass : Asset_Tradeup_Batch_Test
**/

global class Asset_TradeUp_Batch implements Database.Batchable<sObject>, Schedulable{
    global set<Id> accIdSetGlbl = new set<Id>();
    
    global Asset_TradeUp_Batch(){ 
        Set<Id> accIds = new Set<Id>();
        List<Account> accConts = [Select Id , TradeUp_Contact_Email_Temp__c from Account where TradeUp_Contact_Email_Temp__c!=''];
        
        for(Account acc : accConts){
            accIds.add(acc.Id);
        }
        this.accIdSetGlbl = accIds; 
    }	
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'Select ID,Owner.Email, (Select Id,Name, AccountId, Premium_Support_End_Date__c from Assets where Premium_Support_End_Date__c >=2024-05-01'
            +' and Eligible_for_Free_HW__c in (\'True - Manual\',\'True\') and Free_HW_Refresh_Forfeited__c =false and status in (\'Purchased\',\'Dispatched\',null))'
            +' from Account where id in: accIdSetGlbl';
        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Account> liAcc){
        Set<Id> accIdSet = new Set<Id>();
        Set<Id> assetId = new Set<ID>();
        Map<Id,Set<Id>> accIdtoAssetMap = new Map<Id,Set<Id>>();
        Map<Id,List<Asset>> accIdToLiAssetMap = new Map<Id,List<Asset>>();
        Map<id,String> accIdtoOwnerMap = new Map<id,String>();
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        List<Attachment> liAtt = new List<Attachment>();
        List<EmailTemplate> emTemp = [SELECT Id, DeveloperName, Subject, HtmlValue FROM EmailTemplate where DeveloperName in ('Asset_TradeUp_Email_Notification')];
        List<OrgWideEmailAddress> owEmail = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName ='No Reply' LIMIT 1];
        List<EmailMessage> emailMessageList = new List<EmailMessage>();
        Map<Id, String> accIdVsOwnerEmail = new Map<Id, String>();
        Map<Id,String> accIdtoContactEmail = new Map<Id,String>();
        try{
            for(Account acObj : liAcc){
                accIdSet.add(acObj.Id);
                if(!accIdtoOwnerMap.containsKey(acObj.Id)){
                    accIdtoOwnerMap.put(acObj.Id, acObj.OwnerId);
                    accIdVsOwnerEmail.put(acObj.Id,acObj.Owner.Email);
                }
                for(Asset asObj : acObj.Assets){
                    assetId.add(asObj.Id);
                    if(!accIdtoAssetMap.containsKey(asObj.AccountId)){
                        accIdtoAssetMap.put(asObj.AccountId,new Set<Id>{asObj.Id});
                    }
                    else{
                        accIdtoAssetMap.get(asObj.AccountId).add(asObj.Id);
                    }
                    if(!accIdToLiAssetMap.containsKey(asObj.AccountId)){
                        accIdToLiAssetMap.put(asObj.AccountId,new list<Asset>{asObj});
                    }
                    else{
                        accIdToLiAssetMap.get(asObj.AccountId).add(asObj);
                    }
                }
            }
            
            
            List<Account> accConts = [Select Id , TradeUp_Contact_Email_Temp__c from Account where TradeUp_Contact_Email_Temp__c!=''];
            for(Account acc : accConts){
                accIdtoContactEmail.put(acc.Id,acc.TradeUp_Contact_Email_Temp__c);
            }
            
            if(accIdSet!=null && accIdSet.size()>0){
                for(Id accId : accIdSet){
                    String assetInfo = '';
                    Set<String> accContactEmail = new Set<String>();
                    String conEmails = accIdtoContactEmail.get(accId);
                    List<String> conEmailLi = conEmails.split(',');
                    for(String st: conEmailLi){
                        accContactEmail.add(st);
                    }
                    Set<String> accOwnerCcSend = new Set<String>{accIdtoOwnerMap.get(accId)};
                    
                    Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                    attach.setContentType('application/pdf');
                    attach.setFileName('PDF Addendum Notice.pdf');
                    
                    assetInfo = '<table border="1" style="border-collapse: collapse"><tr><th><h3>Asset Name</h3></th><th><h3>Support End Date / Renewal Date</h3></th></tr>';
                    for(Asset ast : accIdToLiAssetMap.get(accId)){
                        String sedate = String.valueOf(ast.Premium_Support_End_Date__c);
                        assetInfo += '<tr><td>' + ast.Name + '</td><td>' + sedate + '</td></tr>';
                    }
                    assetInfo += '</table>';
                    
                    attach.Body = Blob.toPDF(assetInfo);
                    Messaging.SingleEmailMessage email = EmailHelper.getSingleEmailMessageObj(accContactEmail,accOwnerCcSend,null,null, accId, emTemp[0].Id );
                    email.setOrgWideEmailAddressId(owEmail[0].Id);
                    email.setSaveAsActivity(true);
                    email.setFileAttachments(new Messaging.EmailFileAttachment[] { attach });
                    mails.add(email);
                    
                    
                    for(Asset ast : accIdToLiAssetMap.get(accId)){
                        EmailMessage emailMessage = new EmailMessage();
                        emailMessage.relatedToId = ast.Id; 
                        emailMessage.fromAddress = owEmail[0].Address; // from address
                        emailMessage.ToAddress = accIdtoContactEmail.get(accId);
                        emailMessage.Subject = emTemp[0].Subject;
                        emailMessage.CcAddress = accIdVsOwnerEmail.get(accId);
                        emailMessage.HtmlBody = emTemp[0].HtmlValue;
                        emailMessageList.add(emailMessage);
                        
                        if(assetInfo!='' && assetInfo!=null){
                            Attachment attForAsset = new Attachment();
                            attForAsset.Name = 'PDF Addendum Notice.pdf';
                            attForAsset.Body = Blob.toPDF(assetInfo);
                            attForAsset.ContentType = 'application/pdf';
                            attForAsset.ParentId = ast.Id;
                            liAtt.add(attForAsset);
                        }
                    }
                    if(assetInfo!='' && assetInfo!=null){
                        Attachment att = new Attachment();
                        att.Name = 'PDF Addendum Notice.pdf';
                        att.Body = Blob.toPDF(assetInfo);
                        att.ContentType = 'application/pdf';
                        att.ParentId = accId;
                        liAtt.add(att);
                    }
                    assetInfo = '';
                    accOwnerCcSend.clear();           
                }
                
            }
            if(!emailMessageList.isEmpty()) {
                flowControll.taskTrigger = false;
                insert emailMessageList;
                flowControll.taskTrigger = true;
            }
            if(!mails.isEmpty() && !test.isRunningTest()){
                flowControll.taskTrigger = false;
                Messaging.sendEmail(mails,false);
                flowControll.taskTrigger = true;
            } 
            if(!liAtt.isEmpty() && !test.isRunningTest()){
                Database.SaveResult[] srList = Database.insert(liAtt, false);
            }
        }
        catch(exception ex){
            system.debug('Asset error occured ==> '+ex.getMessage() +' '+ex.getLineNumber());
        }
    }
    
    global void finish(Database.BatchableContext bc){
    } 
    
    //Schedulable execute method
    public void execute(SchedulableContext sc) {
        //Asset_TradeUp_Batch batch = new Asset_Tradeup_Account_Batch(); 
        //database.executebatch(batch,1);
        
    }
    
}