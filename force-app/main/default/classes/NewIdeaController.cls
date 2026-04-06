public without sharing class NewIdeaController{
    
    @AuraEnabled
    public static List <String> getPiklistValues() {
        List<String> plValues = new List<String>();
         
        //Get the object type from object name. Here I've used custom object Book.
        Schema.SObjectType objType = Schema.getGlobalDescribe().get('Idea');
         
        //Describe the sObject using its object type.
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
         
        //Get the specific field information from field name. Here I've used custom field Genre__c of Book object.
        Schema.DescribeFieldResult objFieldInfo = objDescribe.fields.getMap().get('Categories').getDescribe();
         
        //Get the picklist field values.
        List<Schema.PicklistEntry> picklistvalues = objFieldInfo.getPicklistValues();
         
        //Add the picklist values to list.
        for(Schema.PicklistEntry plv: picklistvalues) {
            plValues.add(plv.getValue());
        }
        plValues.sort();
        return plValues;
    }
    
    @AuraEnabled
    public static String createIdea(String title, String body, List<String> categories,String commid){
        User usr = [select id,Contact.AccountId,Contact.Account.OwnerId from user where id =: Userinfo.getUserId()];
        String salesEngineerId = '';
        List<AccountTeamMember> atmList = new List<AccountTeamMember>();
        atmList = [SELECT Id, AccountId, UserId, TeamMemberRole FROM AccountTeamMember where AccountId =: usr.Contact.AccountId AND TeamMemberRole = 'Sales Engineer'];
        if(atmlist.size() > 0){
            salesEngineerId = atmList[0].UserId;
        }
        string categs='';
        for(String str : categories){
            categs += str + ';';
        }
        categs = categs.removeEnd(';');
        
        Idea temp = new Idea(title=title,body=body,categories=categs,CommunityId=commid,status='Submitted');
        if(salesEngineerId != '')
            temp.Sales_Engineer__c=salesEngineerId;
        if(usr.Contact.Account.OwnerId != null)
            temp.Account_Owner__c=usr.Contact.Account.OwnerId;
        insert temp;
        return temp.id;
        
    }
}