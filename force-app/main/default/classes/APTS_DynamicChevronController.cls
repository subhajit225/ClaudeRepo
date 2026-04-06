/*
 * Class Name: APTS_DynamicChevronController
 * Author: Krishna Patel
 * Usage: This class is used to dynamically fetch the picklist values and display as chevron on detail page of Opportunity,Quote/Proposal, Agreement. 
 */

public with sharing class APTS_DynamicChevronController {

    public List<string> options {get;set;}
    public List<string> shortLabels {get;set;}
    public String OptionsStr{get;set;}
    public String  shortLabelsStr {get;set;}

    public APTS_DynamicChevronController(ApexPages.StandardController controller) {
       options = new list <String>(); 
       shortLabels = new List<String>();
       
       //Sobject obj = new Sobject(Apttus_Proposal__Proposal__c);
       String recordId = controller.getId();
       Schema.sObjectType sobjType= findObjectNameFromRecordIdPrefix(recordId);
       System.debug('>>>> sObjeType : '+sobjType);
       if(sobjType!=null && String.valueOf(sobjType).equalsignorecase('Apttus_Proposal__Proposal__c')){
           options = getPicklistValues(sobjType,'Apttus_Proposal__Approval_Stage__c');
       }else if(sobjType!=null && String.valueOf(sobjType).equalsignorecase('Opportunity')){
           options = getPicklistValues(sobjType,'StageName');
       }else if(sobjType!=null && String.valueOf(sobjType).equalsignorecase('Apttus__APTS_Agreement__c')){
           options = getPicklistValues(sobjType,'Apttus__Status_Category__c');
       }    
       System.debug('>>>> options: '+options);
       Set<String> tempLabelCheck = new Set<String>();
       for(string option: options){
           String label = findShortLabel(option);
           if(!tempLabelCheck.contains(label)){
               shortLabels.add(label.toUppercase());
               tempLabelCheck.add(label.toUppercase());
           }else{
               shortLabels.add(option.subString(0,2).toUppercase());
               tempLabelCheck.add(option.subString(0,2).toUppercase());
           }
       }
        OptionsStr = JSON.serialize(Options);
        shortLabelsStr = JSON.serialize(shortLabels); 
   
    }
    public APTS_DynamicChevronController(){
    }
    public List<string> getPicklistValues(Schema.sObjectType sobjType, String field_name) {
        List<selectOption> options = new List<selectOption>();
        list <string> optionList = new list <string>();
        Schema.sObjectType sobject_type = sobjType; //grab the sobject that was passed
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe(); //describe the sobject
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject    
        List<Schema.PicklistEntry> pick_list_values = field_map.get(field_name).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
        for (Schema.PicklistEntry a : pick_list_values) { 
        //for all values in the picklist list                   
            //options.add(new selectOption(a.getValue(), a.getLabel())); //add the value and label to our final list
            optionList.add(a.getLabel());
        }
        return optionList; //return the List
    }
    public Schema.SObjectType findObjectNameFromRecordIdPrefix(String recordIdOrPrefix){
        String objectName = '';
        Schema.SObjectType sobjType;
        try{
            //Get prefix from record ID
            //This assumes that you have passed at least 3 characters
            String myIdPrefix = String.valueOf(recordIdOrPrefix).substring(0,3);
             
            //Get schema information
            Map<String, Schema.SObjectType> gd =  Schema.getGlobalDescribe(); 
             
            //Loop through all the sObject types returned by Schema
            for(Schema.SObjectType stype : gd.values()){
                Schema.DescribeSObjectResult r = stype.getDescribe();
                String prefix = r.getKeyPrefix();
                System.debug('Prefix is ' + prefix);
                 
                //Check if the prefix matches with requested prefix
                if(prefix!=null && prefix.equals(myIdPrefix)){
                    objectName = r.getName();
                    sobjType = stype;
                    System.debug('Object Name! ' + objectName);
                    break;
                }
            }
        }catch(Exception e){
            System.debug(e);
        }
        return sobjType;
    }  
    public String findShortLabel(String option){
        String retLabel='';
        String [] optArray = option.split(' ');
        System.debug('>>>> optArray : '+optArray);
        if(optArray.size() > 1){
            retLabel = optArray[0].subString(0,1)+optArray[1].subString(0,1);
        }else{
            retLabel = optArray[0].subString(0,1);
        }
        return retLabel;
    }    
}