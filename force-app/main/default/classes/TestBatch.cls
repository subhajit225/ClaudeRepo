public with sharing class TestBatch implements Database.Batchable<sObject>, Database.RaisesPlatformEvents {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT id,name,NumberOfEmployees FROM Account where name ='test' limit 1]);
    }

    // The process has no meaning as it is a test for error occurrence.
    public void execute(Database.BatchableContext bc, List<Account> scope) {
            throw new CustomException('Simulated batch failure');
                 
    }

    public void finish(Database.BatchableContext bc) {
        system.debug('TestBatch finish');
    }
    
     // Custom Exception class
    public class CustomException extends Exception {}
}