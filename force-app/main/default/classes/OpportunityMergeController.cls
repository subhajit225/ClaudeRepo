public with sharing class OpportunityMergeController {
    //public List<Opportunity> sourceOpp {get;set;}
    //public List<Opportunity> targetOpp {get;set;}  
    Id sourceId,targetId;
    public Boolean tick {get {return true;} set;}
    public Boolean untick {get {return false;} set;}
    private Boolean errorSuccessMessage = false;
    private String showMsg ;
    public  Opportunity opTarget;
    public Sobject record {private set; get;}
    public Sobject record2 {private set; get;}
    public String jsonHidden {get;set;}
    private Set<String> notAllowedField = new Set<String>();
    public OpportunityMergeController() {
        sourceId = ApexPages.currentPage().getParameters().get('Id');
        targetId = ApexPages.currentPage().getParameters().get('oppId');
        notAllowed();
       
        
    }
    
    public List<Opportunity> getSourceOpp(){
        return [select Name,Id from Opportunity where Id = :sourceId];
    }
    public List<Opportunity> getTargetOpp(){
        return null;
    }
    
    public Map<String,String> getApiLabel (){
        
        Map<String, String> apiLabelMap = new Map<String, String>();
        String type='Opportunity';
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType oppSchema = schemaMap.get(type);
        Map<String, Schema.SObjectField> fieldMap = oppSchema.getDescribe().fields.getMap();
        
        for (String fieldName: fieldMap.keySet()) {
            //System.debug('##Field API Name='+fieldName);// list of all field API name
            String label = fieldMap.get(fieldName).getDescribe().getLabel();//It provides to get the object fields label.
            if(!isFormula(fieldMap.get(fieldName))){
                system.debug('notallo '+fieldName);
                //system.assert(1==2);
                apiLabelMap.put(fieldName, label);
            }
            
            //system.debug('label is '+label);
            
        }
        
        
        List<String> fieldList = new List<String>();
        fieldList.addAll(fieldMap.keySet());
        
        /* JOIN field Name to generate a query*/
        String querySource = 'SELECT ' + String.escapeSingleQuotes(String.join( fieldList, ',' )) + ' FROM Opportunity WHERE id = :sourceId LIMIT 1 ';
        
        /* JOIN field Name to generate a query*/
        String queryTarget = 'SELECT ' + String.escapeSingleQuotes(String.join( fieldList, ',' )) +' FROM Opportunity WHERE id = :targetId LIMIT 1 ';
        
        // return generic list of sobjects or typecast to expected type
        List<SObject> records = Database.query( querySource );
        record = records[0];
        
        List<SObject> records2 = Database.query( queryTarget );
        record2 = records2[0];
        
        
        return apiLabelMap;
    } 
    
     public PageReference Cancel(){
         PageReference pg = new PageReference('/'+sourceId); 
         return pg;
     }
    public PageReference CopyValues(){
        system.debug('jsonHidden '+jsonHidden);
        try {
            if(jsonHidden != null) {
                List<Object> apiList = (List<Object>) JSON.deserializeUntyped(jsonHidden);
                system.debug('apiList '+apiList);
                for(Object o : apiList) {
                    String s = (String) o;
                    system.debug('record2.get(s)'+record2.get(s));
                    record.put(s, record2.get(s));
                    
                }
                
                try {
                    update record;
                    errorSuccessMessage = true;
                }
                catch(Exception e){
                    showMsg = e.getMessage();
                    errorSuccessMessage = false;
                    
                }
                
            }
            
            if(errorSuccessMessage == true) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'All selected Opportunity Values Copied Successfully.'));
             }
            else {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Error while copying some fields\n'+showMsg));
                    
            }
            PageReference pageRef = new PageReference(ApexPages.currentPage().getUrl());
            pageRef.getParameters().put('Id',sourceId);
            pageRef.getParameters().put('oppId',targetId);
            pageRef.setRedirect(false);
            system.debug('~~~pageRef'+pageRef);
           
            return pageRef;
           
            
        }
        catch (Exception e){
            
            showMsg = e.getMessage();
            PageReference pageRef = new PageReference(ApexPages.currentPage().getUrl());
             pageRef.getParameters().put('Id',sourceId);
            pageRef.getParameters().put('oppId',targetId);
            pageRef.setRedirect(false);
            //system.assert(1==2);
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Error while copying some fields\n'+showMsg));
               
            return pageRef;
        }
        
        
    }
    
    public void notAllowed(){
        notAllowedField.add(toLowerCase('iD'));
        notAllowedField.add(toLowerCase('CreatedBy'));
        notAllowedField.add(toLowerCase('LastModifiedBy'));
        notAllowedField.add(toLowerCase('Owner'));
        
        notAllowedField.add(toLowerCase('SyncedQuote'));
        notAllowedField.add(toLowerCase('RecordType'));
        notAllowedField.add(toLowerCase('isdeleted'));
        notAllowedField.add(toLowerCase('Amount'));
        notAllowedField.add(toLowerCase('lastactivitydate'));
        notAllowedField.add(toLowerCase('original_lead_owners_role__c'));
         
         
    }
    private String toLowerCase(String s1) {
        return s1.toLowerCase();
    }
    public static Boolean isFormula(SObjectField field) 
    { 
        return field.getDescribe().isCalculated(); 
    }

}