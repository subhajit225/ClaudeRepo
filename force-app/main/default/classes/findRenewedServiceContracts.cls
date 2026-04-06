/*Starts - [Shaloo Mishra] Arroyo 2.0 ARY-31: Trigger Task created send email when an Oppty has Primary Renewal/Expansion Quote created*/
global with sharing class findRenewedServiceContracts {
    /**accountId*/
    global String accountId {get;set;}
    /**account */
    global Account account{
        get {
            account = accountId != null? [SELECT Id, Name FROM Account WHERE Id =: accountId]: new Account();
            return account; }
        set;
    }
    /**contractsRec */
    global List<ServiceContract> contractsRec;
    
    /**findRenewedServiceContracts */
    global findRenewedServiceContracts() {
        //contractsRec = [SELECT Name FROM ServiceContract WHERE AccountId =: account.Id]; //tsk.WhatId
    }
    
    /**getRenewedServiceContracts */
    global List<ServiceContract> getRenewedServiceContracts() {
        
        Date dfuture = System.today().addDays(365);
        Date dpast = System.today().addDays(-90);
        
        if(account!=null){
            contractsRec = [SELECT Name, SBQQSC__RenewalOpportunity__c, SBQQSC__RenewalOpportunity__r.Name, 
                            SBQQSC__RenewalOpportunity__r.SBQQ__PrimaryQuote__c, 
                            SBQQSC__RenewalOpportunity__r.SBQQ__PrimaryQuote__r.Name, SBQQSC__RenewalOpportunity__r.Renewal_ACV__c 
                            FROM ServiceContract WHERE AccountId =: account.Id 
                            AND GPL_Deal__c!= 'NetApp' AND 
                            SBQQSC__Opportunity__r.Opportunity_Sub_Type__c != 'MSP Consumption Renewal' AND 
                            SBQQSC__Opportunity__r.Opportunity_Sub_Type__c != 'MSP Overage' AND (NOT Name LIKE '%Test%') 
                            AND EndDate <= :dfuture AND EndDate >= :dpast]; //Put later  
            
            system.debug('Value of contractsRec:-> '+contractsRec);
        }        
        return contractsRec;
    }
}
//Ends - [Shaloo Mishra] Arroyo 2.0 ARY-31: Trigger Task created send email when an Oppty has Primary Renewal/Expansion Quote created