/**
* @description       : Controller Class to fetch data for Cluster Search Component.
* @author            : 
* @last modified on  : 03-11-2021
* @last modified by  : Veera Gandi
* Modifications Log 
* Ver   Date                Author        Modification
* 1.0 
* 1.1   11th March 21       Veera         CS21-450 - Updated search logic to consider Asset Name and refactored methods.
**/
public without sharing class searchClusterController {
    
    /**
    @description : method to fetch User details for the customer portal user
    @return      : User
    */
    private static User getUser() {
        User user;
        
        if (user == null) {
            user = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        }
        
        return user;
    }
    
    /**
    @description : method to return Clusters related to user account based on the search string
    @param       : String Search Keyword
    @return      : List<Cluster__c>
    */
    @AuraEnabled
    public static List <Cluster__c> fetchAccount(String searchKeyWord) {
        User user = getUser();
        String searchKey = '%'+searchKeyWord + '%';
        
        if(user.AccountId == null && !test.isRunningTest()) {
            return null;  
        } 
        
        List <Cluster__c> clusters = [SELECT Id, Name, UUID__c, Description__c, Account__r.Name, CDM_End_of_Support_Status__c,
                                      Tag__c, Software_Version__c, Objects_Protected__c, Storage_Usage__c,
                                      Snapshot_Count__c FROM Cluster__c  
                                      WHERE Name LIKE :searchKey AND Account__c = :user.Accountid  
                                      LIMIT 500];
       
        return clusters;
    }
    
    /**
    @description : method to return Nodes related to user account based on the search string
    @param       : String Search Keyword
    @return      : List<Node__c>
    */
    @AuraEnabled
    public static List<Node__c> fetchNode(String searchKeyWord) {
        
        User user = getUser();
        String searchKey = '%'+searchKeyWord + '%';
        
        if (user.AccountId == null && !test.isRunningTest()) {
            return null;
        }
        
        List <Node__c> nodes = [SELECT Id, Name, Serial_Number__c, Cluster__r.Tag__c, Cluster__r.Name, Chassis__r.Name,
                                Asset__r.Name, Software_Version__c FROM Node__c
                                WHERE (Serial_Number__c LIKE :searchKey OR Asset__r.Name LIKE :searchKey)
                                AND Cluster__r.Account__c = :user.AccountId  
                                LIMIT 500];
        
        return nodes;
    }
    
    
}