global class EntitlementAccountMismatchEmailAlert implements Schedulable {
    global void execute(SchedulableContext sc) {
        List<Entitlement> EntitlementData=new List<Entitlement>();
        List <Entitlement> RetriveEnt = New List <Entitlement>(); 
        //Query Updated to add new fields
        if(!Test.isRunningTest()){
              RetriveEnt=[select id,Name,Asset.Name,Asset.Product2.Id,Asset.Account.Name,Asset.Account.Id,Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Account__r.Name,Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Account__r.Id,Account.Name,AccountId,Order_Service_Item__r.OrderId,Order_Service_Item__r.Order.OrderNumber from Entitlement where Order_Service_Item__c != null AND Order_Service_Item__r.SBQQ__QuoteLine__c != null];
        }
        else{
               RetriveEnt=[select id,Name,Asset.Name,Asset.Product2.Id,Asset.Account.Name,Asset.Account.Id,Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Account__r.Name,Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Account__r.Id,Account.Name,AccountId,Order_Service_Item__r.OrderId,Order_Service_Item__r.Order.OrderNumber from Entitlement Limit 10];
        }
       for(Entitlement Ent : RetriveEnt){
            if(Ent.Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Account__r.id != Ent.AccountId || Ent.Asset.Account.Id != Ent.AccountId){
                EntitlementData.add(Ent);
                system.debug('Entitlement ids = '+Ent.id);
             }
        }
        
        if(EntitlementData.size() > 0) {
            User u;
            EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Entitlement_Account_Name_Mismatch_Alert'];
            Email_Preferences__mdt mdt = [Select Id, Receipient__c, cc__c, Email_Subject__c from Email_Preferences__mdt where MasterLabel = 'Entitlement Account Name Mismatch' LIMIT 1];
            if(!test.isRunningTest()){
            u = [Select Id from User where IsActive = true and Email = :mdt.Receipient__c LIMIT 1];
            }
            else{
            u = [Select Id from User where IsActive = true and Email='varsha.chechare@rubrik.com' LIMIT 1];
            }
            Messaging.SingleEmailMessage email = 
            Messaging.renderStoredEmailTemplate(et.Id, u.Id, EntitlementData[0].Id);
            List<String> ccAddresses = new List<String>();
            if(mdt.cc__c != null){
                for(String address: mdt.cc__c.split(',')){
                    ccAddresses.add(address.trim());
                }
            }
            email.setCcAddresses(ccAddresses);
            email.setSaveAsActivity(false);
            try{
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            }catch(exception e){
                //apexpages.addmessage(new apexpages.message(apexpages.severity.error,e.getMessage()));
                System.debug(e.getMessage());
            }
        }

    }
}