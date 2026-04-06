public class EscalationApexController {

    
    @AuraEnabled
    public static recordWrapper getDetails(String recordId , String accountId){
        List<Contact> conList = new List<Contact>();
        if(!String.isEmpty(accountId))
            conList = [select id,name, title,email,phone from contact where accountId =: accountId]; 
        List<contactClass> contactList = new List<contactClass>();
        for(Contact con : conList){
            contactList.add(new contactClass(con));
        }
        Escalation_Request__c esc = new Escalation_Request__c();
        if(recordId != null)
            esc = [SELECT Id, IsDeleted, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp,
                   LastActivityDate, Account__c, Description_of_events__c, Desired_outcome_of_escalation__c, 
                   Factors_involved_leading_to_escalation__c, Product_Line_involved_in_the_escalation__c, Rubrik_contacts_who_should_be_involved__c,
                   //ETM-141
                   //Reporting_User__r.Email,Reporting_User__r.Title,Reporting_User__r.Phone,Reporting_User__r.Region__c, Reporting_User__r.Theatre__c,
                   //Account__r.Owner.Email,Account__r.Owner.Title,Account__r.Owner.Phone,Account__r.Owner.Region__c, Account__r.Owner.Theatre__c,
                   Reporting_User__r.Email,Reporting_User__r.Title,Reporting_User__r.Phone,
                   Account__r.Owner.Email,Account__r.Owner.Title,Account__r.Owner.Phone,Account__r.ETM_Region__c, Account__r.ETM_Theatre__c,
                   (select Contact__c,Contact_Type__c from Escalation_Contacts__r)
                   Are_any_other_vendors_involved__c, Reporting_User__c, Status__c, Escalation_Severity__c FROM Escalation_Request__c Where id =: recordId];
        Map<String,List<picklist>> fieldMap = new Map<String,List<picklist>>();
        fieldMap.putAll( getFieldValue('Factors_involved_leading_to_escalation__c'));
        fieldMap.putAll( getFieldValue('Product_Line_involved_in_the_escalation__c'));
        return new recordWrapper(esc,fieldMap,contactList);
    }
    @AuraEnabled
    public static List<contactClass> getContactList(Id accountId){
        List<contactClass> contactList = new List<contactClass>();
        for(Contact con : [select id,name, title,email,phone from contact where accountId =: accountId]){
            contactList.add(new contactClass(con));
        }
        return contactList; 
    }
    
    @AuraEnabled
    public static Contact getContactDetail(Id contactId){
        return [select id,name, title,email,phone from contact where Id =: contactId]; 
    }
    
    @AuraEnabled
    public static void assignMe(Id escalationId){
        update new Escalation_Request__c(id=escalationId,OwnerId = Userinfo.getUserId());
    }
    
    @AuraEnabled
    public static String copyEmails(Id escalationId,String emailType){
        Escalation_Request__c esc = [SELECT Id,Rubrik_contacts_who_should_be_involved__c,Rubrik_contacts_who_should_be_involved__r.Name,Rubrik_contacts_who_should_be_involved__r.Email,
                                     (select Contact__c,Contact__r.Name , Contact__r.Email,Contact_Type__c from Escalation_Contacts__r where Contact__r.Email != null)
                                     FROM Escalation_Request__c Where id =: escalationId];
        String emailString = '';
        for(Escalation_Contact__c con : esc.Escalation_Contacts__r){
            if(emailType == 'RubrikContact' && con.Contact_Type__c == 'Rubrik contact'){
                emailString += con.Contact__r.Name + '<'+con.Contact__r.Email+'>,';
            }
            if(emailType == 'customerContact' && con.Contact_Type__c == 'Primary customer contact'){
                emailString += con.Contact__r.Name + '<'+con.Contact__r.Email+'>,';
            }
        }
        if(emailString != null)
            emailString = emailString.removeEnd(',');
        return emailString;
    }
    
    @AuraEnabled
    public static List<Escalation_Contact__c> addEscalationContact(String recordId , List<Contact> primaryContacts,List<Contact> rubrikContacts){
		Map<String,Set<Id>> contactsTypeMap = new Map<String,Set<Id>>();
        for(Escalation_Contact__c escList : [Select id,Contact__c,Contact_Type__c from Escalation_Contact__c where Escalation_Request__c =: recordId]){
            if(!contactsTypeMap.containsKey(escList.Contact_Type__c)){
                contactsTypeMap.put(escList.Contact_Type__c,new Set<Id>());
            }
            contactsTypeMap.get(escList.Contact_Type__c).add(escList.Contact__c);
        }
        if(!contactsTypeMap.containsKey('Primary customer contact')){ contactsTypeMap.put('Primary customer contact',new Set<Id>());}
        if(!contactsTypeMap.containsKey('Rubrik contact')){ contactsTypeMap.put('Rubrik contact',new Set<Id>());}
        List<Escalation_Contact__c> escContact = new List<Escalation_Contact__c>();
        for(Contact con: primaryContacts){
            if(!contactsTypeMap.get('Primary customer contact').contains(con.Id)){
                escContact.add(new Escalation_Contact__c(Contact__c = con.Id, Contact_Type__c = 'Primary customer contact',Escalation_Request__c=recordId));
            }
        }
        for(Contact con: rubrikContacts){
            if(!contactsTypeMap.get('Rubrik contact').contains(con.Id)){
                escContact.add(new Escalation_Contact__c(Contact__c = con.Id, Contact_Type__c = 'Rubrik contact',Escalation_Request__c=recordId));
            }
        }
        insert escContact;
        return escContact;
    }
    
    public static Map<String,List<picklist>> getFieldValue(String fieldName){
        Map<String,List<picklist>> fieldMap = new Map<String,List<picklist>>();
        List<picklist> pickListValuesList= new List<picklist>();
        Schema.SObjectType s = Schema.getGlobalDescribe().get('Escalation_Request__c') ;
        Schema.DescribeSObjectResult r = s.getDescribe() ;
        Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(new picklist(pickListVal.getLabel(),pickListVal.getValue()));
        }     
        fieldMap.put(fieldName,new List<picklist>());
        fieldMap.get(fieldName).addAll(pickListValuesList);
        return fieldMap;
    }
    
    public class recordWrapper{
        @AuraEnabled public Escalation_Request__c escalationRecord{get;set;}
        @AuraEnabled public Map<String,List<picklist>> fieldMap{get;set;}
        @AuraEnabled public List<Contact> primaryContacts{get;set;}
        @AuraEnabled public List<Contact> rubrikContacts{get;set;}
        @AuraEnabled public List<contactClass> accountContacts{get;set;}
        public recordWrapper(Escalation_Request__c escalationRecord,Map<String,List<picklist>> fieldMap,List<contactClass> accountContacts){
            this.escalationRecord = escalationRecord;
            this.fieldMap = fieldMap;
            this.primaryContacts = new List<Contact>();
            this.rubrikContacts = new List<Contact>();
            this.accountContacts = accountContacts;
            if(!escalationRecord.Escalation_Contacts__r.isEmpty()){
                Set<Id> contactIds = new Set<Id>();
                for(Escalation_Contact__c esc : escalationRecord.Escalation_Contacts__r){
                    contactIds.add(esc.Contact__c);
                }
                Map<Id,Contact> contactMap = new Map<Id,Contact>([select id,name, title,email,phone from contact where id IN: contactIds]);
                for(Escalation_Contact__c esc : escalationRecord.Escalation_Contacts__r){
                    if(contactMap.containsKey(esc.Contact__c)){
                        if(esc.Contact_Type__c == 'Primary customer contact')
                            primaryContacts.add(contactMap.get(esc.Contact__c));	
                        else	
                            rubrikContacts.add(contactMap.get(esc.Contact__c));		
                    }
                }
            }
        }
    }
    
    public class contactClass{
        @AuraEnabled public Contact con{get;set;}
        @AuraEnabled public boolean isSelected{get;set;}
        public contactClass(Contact con){
            this.con = con;
            this.isSelected = false;
        }        
    }
    
    public class picklist{
        @AuraEnabled public String label{get;set;}
        @AuraEnabled public String value{get;set;}
        public picklist(String label, String value){
            this.label = label;
            this.value = value;
        }        
    }
}