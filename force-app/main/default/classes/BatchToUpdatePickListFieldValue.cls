/**
* @Author       :   Grazitti Interactive
* @CreatedDate  :   11/06/2023
* @Description  :   Below Batch code is written to insert the new Value in the Picklist Field through Metadata
* @TestClass    :
* @Note         :   Script To execute the batch from anonymous window in developer console:
Database.executeBatch(new BatchToUpdatePickListFieldValue(), 1);
*/

global class BatchToUpdatePickListFieldValue implements Schedulable, Database.Batchable <sObject> , Database.AllowsCallouts, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        Datetime oneHourAgo = System.now().addHours(-1);

        //String query = 'SELECT Id,Name,Escalation__c,For_Workspace__c ,Product_Area__c,Product_Component__c,Idea_Category__c,Idea_Tags__c,Status__c FROM Aha_Ideas__c WHERE ID = \'a1B77000000Mc0O\'';
        String query = 'SELECT Id,Name,Escalation__c,For_Workspace__c ,Product_Area__c,Product_Component__c,Idea_Category__c,Idea_Tags__c,Status__c FROM Aha_Ideas__c WHERE CreatedDate >= :oneHourAgo OR LastModifiedDate >= :oneHourAgo';
        return Database.getQueryLocator(query);
    }

    global void execute(SchedulableContext ctx){
        BatchToUpdatePickListFieldValue batch = new BatchToUpdatePickListFieldValue();
        Database.executebatch(batch, 5);
    }

    global void execute(Database.BatchableContext BC, List<Aha_Ideas__c> scope){
        Map<String,Set<String>> fieldNameAndValues = new Map<String,Set<String>>();
        try{

            for(Aha_Ideas__c idea : scope){
                //For Escalation__c Picklist Field
                if(idea.Escalation__c!= null){
                    if(!fieldNameAndValues.isEmpty() && fieldNameAndValues.containskey('Escalation__c')){
                        fieldNameAndValues.get('Escalation__c').add(idea.Escalation__c);
                    }
                    else{
                        fieldNameAndValues.put('Escalation__c',new Set<String>{idea.Escalation__c});
                    }
                }

                //For For_Workspace__c Picklist Field
                if(idea.For_Workspace__c!= null){
                    if(!fieldNameAndValues.isEmpty() && fieldNameAndValues.containskey('For_Workspace__c')){
                        fieldNameAndValues.get('For_Workspace__c').add(idea.For_Workspace__c);
                    }
                    else{
                        fieldNameAndValues.put('For_Workspace__c',new Set<String>{idea.For_Workspace__c});
                    }
                }

                //For Product_Area__c Picklist Field
                if(idea.Product_Area__c != null){
                    if(!fieldNameAndValues.isEmpty() && fieldNameAndValues.containskey('Product_Area__c ')){
                        fieldNameAndValues.get('Product_Area__c ').add(idea.Product_Area__c );
                    }
                    else{
                        fieldNameAndValues.put('Product_Area__c ',new Set<String>{idea.Product_Area__c  });
                    }
                }

                //For Idea_Category__c Picklist Field
                if(idea.Idea_Category__c!= null){
                    if(!fieldNameAndValues.isEmpty() && fieldNameAndValues.containskey('Idea_Category__c')){
                        fieldNameAndValues.get('Idea_Category__c').add(idea.Idea_Category__c);
                    }
                    else{
                        fieldNameAndValues.put('Idea_Category__c',new Set<String>{idea.Idea_Category__c});
                    }
                }

                //For Idea_Tags__c Picklist Field
                if(idea.Idea_Tags__c!= null){
                    if(!fieldNameAndValues.isEmpty() && fieldNameAndValues.containskey('Idea_Tags__c')){
                        fieldNameAndValues.get('Idea_Tags__c').add(idea.Idea_Category__c);
                    }
                    else{
                        fieldNameAndValues.put('Idea_Tags__c',new Set<String>{idea.Idea_Tags__c});
                    }
                }

                //For Status__c Picklist Field
                if(idea.Status__c!= null){
                    if(!fieldNameAndValues.isEmpty() && fieldNameAndValues.containskey('Status__c')){
                        fieldNameAndValues.get('Status__c').add(idea.Idea_Category__c);
                    }
                    else{
                        fieldNameAndValues.put('Status__c',new Set<String>{idea.Status__c});
                    }
                }

                //For Product_Component__c Multipicklist Field
                if(idea.Product_Component__c!= null){
                    List<String> productComponentList = idea.Product_Component__c.Split(';');
                    Set<String> productComponentSet = new Set<String>();
                    productComponentSet.addall(productComponentList);
                    if(!fieldNameAndValues.isEmpty() && fieldNameAndValues.containskey('Product_Component_For_Idea_Form__c')){
                        fieldNameAndValues.get('Product_Component_For_Idea_Form__c').addall(productComponentSet);
                    }
                    else{
                        fieldNameAndValues.put('Product_Component_For_Idea_Form__c',productComponentSet);
                    }
                }
            }

            if(!fieldNameAndValues.isEmpty()){
                for(String fieldName : fieldNameAndValues.keySet()){
                    String objectName = 'Aha_Ideas__c';
                    Set<string> fieldValue = fieldNameAndValues.get(fieldName);
                    if(fieldValue.Size() > 0){
                        AhaWebhookReceiver.updatePicklistValues(fieldName,objectName,fieldValue);
                    }
                }
            }
        }
        catch(exception e){

        }
    }

    global void finish(Database.BatchableContext BC){

    }
}