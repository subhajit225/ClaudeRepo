public without sharing class CCRExtension
{
    private ApexPages.StandardController standardController;
    public List<Schema.FieldSetMember> fsm {get; set;}

     User loggedInUser = [Select id,contactId,Contact.AccountId from User where id = :UserInfo.getUserId()];


    public CCRExtension(ApexPages.StandardController standardController)
    {

        findFieldSet(ApexPages.currentPage().getParameters().get('fieldset').escapeHtml4());
        if (fsm != null && fsm.size() > 0){
            List<String> fields = fieldsToAdd();
            if(!test.isRunningTest())
                standardController.addFields(fields);  
        }

        string incentId1 = ApexPages.currentPage().getParameters().get('incent');
        string userId1 = ApexPages.currentPage().getParameters().get('uid');
        string partnerco = loggedInUser.Contact.AccountId;
        string ctype1 = ApexPages.currentPage().getParameters().get('type');

        string incentId = String.isBlank(incentId1) ? null : incentId1.escapeHtml4();
        string userId = String.isBlank(userId1) ? null : userId1.escapeHtml4();
        string ctype = String.isBlank(ctype1) ? null : ctype1.escapeHtml4();

        this.standardController = standardController;
        CCR__c record = (CCR__c) standardController.getRecord();
        if(incentId!=null) record.Incentive__c = incentId;    
        //if(userId!=null) record.Affective_Person__c = userId;
        if(partnerco!=null) record.Partner_Company_Name__c = partnerco;
        if(ctype!=null) record.CCR_Type__c = ctype;
        system.debug('test'+fsm);
        List<User> partnerUser = [select id,contact.name,contact.Email,contact.Phone,Country from User Where ID=:userId];
        if(partnerUser.size()>0){
            record.Partner_Rep_Name__c = partnerUser[0].contact.name;
            if(!string.isBlank(partnerUser[0].contact.Email))
                record.Partner_Rep_Email__c = partnerUser[0].contact.Email;
            if(!string.isBlank(partnerUser[0].contact.Phone))
                record.Partner_Rep_Phone_Number__c = partnerUser[0].contact.Phone;
            if(!string.isBlank(partnerUser[0].Country))
                record.Country__c = partnerUser[0].country;
        }
        List<AccountTeamMember> accTeamMember = [SELECT AccountId,Id,TeamMemberRole,UserId,User.email,User.Name,User.Phone FROM AccountTeamMember WHERE
         AccountId =:partnerco AND TeamMemberRole = 'Sales Engineer' LIMIT 1];
         
         if(accTeamMember.size()>0){
            record.Partner_SE_Name__c = accTeamMember[0].User.name;
            if(!string.isBlank(accTeamMember[0].User.Email))
                record.Partner_SE_Email__c = accTeamMember[0].User.Email;
            if(!string.isBlank(accTeamMember[0].User.Phone))
                record.Partner_SE_Phone__c = accTeamMember[0].User.Phone;
        }
         
        
        
    }
    
    public ApexPages.PageReference saveRecord() {
          try {
            standardController.save();
          }
          catch(Exception e) {
            return null;
          }
           PageReference ref = Page.SubmitThanks;
           ref.getParameters().put('type', 'ccr');
          
          return ref;
        }
            
    
    private void findFieldset(String s){
        fsm = null;
        if (SobjectType.CCR__c.FieldSets.getMap().containsKey(s)){
            if(SobjectType.CCR__c.FieldSets.getMap().get(s).getFields() != null){
                fsm = SobjectType.CCR__c.FieldSets.getMap().get(s).getFields();
            }
        }
    }
    
    
     private List<String> fieldsToadd(){
        List<String> fieldNames = new List<String>();
        for(Schema.FieldSetMember f : fsm){
            fieldNames.add(f.getFieldPath());
        }
        return fieldNames;
    }
    
}