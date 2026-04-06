global class contrctWrapper {
    
    @AuraEnabled  webservice String Id {get;set;}   
    @AuraEnabled webservice String Name {get;set;}  
    @AuraEnabled webservice String ContractNumber {get;set;}
    @AuraEnabled webservice String StartDate {get;set;}
    @AuraEnabled webservice String EndDate {get;set;}
    @AuraEnabled webservice String Status {get;set;}
  //@AuraEnabled global String SBQQSC__RenewalOpportunity__c {get;set;}
                                                               
   
}