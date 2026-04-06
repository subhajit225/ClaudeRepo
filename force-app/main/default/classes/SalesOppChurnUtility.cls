/**
* @description handle opportunity churn related functionalities
*/
public with sharing class SalesOppChurnUtility {
    public static final String OPPORTUNITY = 'Opportunity';
    /**
* @description retrieves combination of Primary churn, secondary churn & HelpText.
* @return List<MappingMatrix__mdt>
*/
    public List<MappingMatrix__mdt> getChurnReasonInfo(){
        try{
            return getMappingMatrix(OPPORTUNITY); 
        }catch(Exception e) { ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));}   return null;     
        
    }
    
    /**
* @description retrieves mapping data for primary and secondary dependent fields
* @param objectName - API name of object.
* @return List<MappingMatrix__mdt> 
*/
    public static List<MappingMatrix__mdt> getMappingMatrix(String objectName){
        return [Select id,PrimaryInput__c,SecondaryInput__c,OutputMapping__c from MappingMatrix__mdt where ObjectName__c = :objectName WITH USER_MODE ];      
    }
    
}