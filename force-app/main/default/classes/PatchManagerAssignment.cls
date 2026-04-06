public class PatchManagerAssignment{

    public Deal_Registration__c vDeal;
    //public Contact vContact;
    //public Account vAccount;
    //public Lead vLead;
    public SObject vObject;
    public String objectType;

    public PatchManagerAssignment(ApexPages.StandardController controller) {
        vObject = controller.getRecord();
        objectType = controller.getRecord().getSObjectType().getDescribe().getName();           
    }
    
    /*
     public PageReference reAssignment() {

        List<SObject> vList = new List<SObject>();
        if(objectType == PatchManager.DEAL_REG){
            vDeal = [select Alliance_Partner_Name__c, Authority__c, Budget__c, City__c, Company__c, Country__c, Domain__c,
                            CreatedById, CreatedDate, Current_Backup_Vendor__c, Current_Storage_Vendor__c, Customer_Category__c, 
                            Distributor_Company_Name__c, Email__c, FirstName__c, Id, LastName__c, Lead_Source__c, Lead_Source_Details__c, 
                            Name, Need__c, Number_of_protected_machines__c, OwnerId, Partner__c, Partner_Rep__c, Partner_Rep_Email_Address__c, 
                            Partner_Rep_Phone_Number__c, Partner_Rep_Title__c, Partner_SE_Email__c, Partner_SE_Name__c, Partner_SE_Phone__c, 
                            PatchManager__c, Phone__c, PostalCode__c, Purchase_Timeframe__c, StateCode__c, Street__c, Title__c, Segment_Revenue__c,Industry_Category__c
                            from Deal_Registration__c where Id = :vObject.Id];        
            vList.add(vDeal);
        } else if (objectType == PatchManager.LEAD){
                vLead = [select Id, City, State, StateCode, Country, PostalCode, LeadSource, Domain__c, MatchedAccountOwner__c, Lead_Source_Details__c, 
                            Industry,PatchManager__c,Industry_Category__c, Deal_Registration__c
                            from Lead where Id = :vObject.Id];        
            vList.add(vLead);
        } else if (objectType == PatchManager.CONTACT){
                vContact = [select Id, MailingCity, MailingPostalCode, MailingState, MailingCountry, PatchManager__c from Contact where Id = :vObject.Id];
                vList.add(vContact);
        } else if (objectType == PatchManager.ACCOUNT){
                vAccount = [select Id, BillingCity, BillingPostalCode, BillingState, BillingCountry,BillingStateCode, PatchManager__c from Account where Id = :vObject.Id];
                vList.add(vAccount);
        }                
        PatchManager.reAssignObject(vList, objectType);      
        PageReference pageRef = new PageReference('/'+vObject.Id);
        pageRef.setRedirect(true);
        return pageRef;
    }  
     */
    
    public PageReference reAssignment() {
        List<SObject> vList = getRecords(vObject.Id, objectType);
        PatchManager.reAssignObject(vList, objectType);
        PageReference pageRef = new PageReference('/'+vObject.Id);
        pageRef.setRedirect(true);
        return pageRef;
    }   
    @InvocableMethod(label = 'Patch Manager Assignment' description = 'Patch Manager Assignment')
    public static list<String> reAssignment(List <Id> recordIds) {
        try{
            system.debug('recordIds..!'+recordIds);
            //Always this method will get invoked from a screen flow. So, recordIds will contains only 1 record.
            Id recordId = recordIds[0];
            String objectType = recordId.getSObjectType().getDescribe().getName();
            List<SObject> vList = getRecords(recordId, objectType);
            PatchManager.reAssignObject(vList, objectType);
            return new list<String>{'SUCCESS'};
        } catch (Exception ex){
            return new list<String>{ex.getMessage()};
        }
    }
    private static List<SObject> getRecords(Id recordId, String objectType){
        Contact vContact;
        Account vAccount;
        Lead vLead;
        Deal_Registration__c vDeal;
        List<SObject> vList = new List<SObject>();
        if(objectType == PatchManager.DEAL_REG){
            vDeal = [select Alliance_Partner_Name__c, Authority__c, Budget__c, City__c, Company__c, Country__c, Domain__c,
                     CreatedById, CreatedDate, Current_Backup_Vendor__c, Current_Storage_Vendor__c, Customer_Category__c, 
                     Distributor_Company_Name__c, Email__c, FirstName__c, Id, LastName__c, Lead_Source__c, Lead_Source_Details__c, 
                     Name, Need__c, Number_of_protected_machines__c, OwnerId, Partner__c, Partner_Rep__c, Partner_Rep_Email_Address__c, 
                     Partner_Rep_Phone_Number__c, Partner_Rep_Title__c, Partner_SE_Email__c, Partner_SE_Name__c, Partner_SE_Phone__c, 
                     PatchManager__c, Phone__c, PostalCode__c, Purchase_Timeframe__c, StateCode__c, Street__c, Title__c, Segment_Revenue__c,Industry_Category__c,Rubrik_Complete_Edition_Reg__c
                     from Deal_Registration__c where Id =: recordId];        
            vList.add(vDeal);
        } else if (objectType == PatchManager.LEAD){
            vLead = [select Id, City, State, StateCode, Country, PostalCode, LeadSource, Domain__c, MatchedAccountOwner__c, Lead_Source_Details__c, 
                     Industry,PatchManager__c,Industry_Category__c, Deal_Registration__c
                     from Lead where Id = : recordId];        
            vList.add(vLead);
        } else if (objectType == PatchManager.CONTACT){
            vContact = [select Id, MailingCity, MailingPostalCode, MailingState, MailingCountry, PatchManager__c from Contact where Id = :recordId];
            vList.add(vContact);
        } else if (objectType == PatchManager.ACCOUNT){
            vAccount = [select Id, BillingCity, BillingPostalCode, BillingState, BillingCountry,BillingStateCode, PatchManager__c from Account where Id = :recordId];
            vList.add(vAccount);
        }
        return vList;
    }
}