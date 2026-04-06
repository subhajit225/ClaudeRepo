/**
* @description  :   Test class for ProcessMetadataRequestsBatch.cls
* @Author       :   Saakshi Gupta
* @CreatedDate  :   30-07-2020
* @Jira Ticket  :   CS21-83 - Enable a method for Rob Tipton to manage software releases in Salesforce
*/
@isTest(seeAllData=true)
public class ProcessMetadataRequestsBatchTest {
    private static testMethod void testMetadataRequestsBatchSuccess() {
        Metadata_Request__c metadataRequestObject = new Metadata_Request__c();
        metadataRequestObject.Field__c = 'Software Version';
        metadataRequestObject.Object__c = 'Case;User, Knowledge Centered Support (KCS), Release Version, Release';
        metadataRequestObject.Value__c = '1.0.Test picklist value';
        metadataRequestObject.Controlling_Product_Lines__c = 'CDM;Duplicate';
        metadataRequestObject.Status__c = 'Open';
        
        insert metadataRequestObject;
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            
            //System.Test.setMock(HttpCalloutMock.class, new DestinationQueueSettingControllerTest.DestinationQueueSettingControllerMock());
            Test.setMock(WebServiceMock.class, new MetadataServiceTest.WebServiceMockImpl());
            Database.executeBatch(new ProcessMetadataRequestsBatch());
            
            Test.stopTest();
        }
        
        Metadata_Request__c metadataRequest = [SELECT Status__c FROM Metadata_Request__c LIMIT 1];
        System.assert(metadataRequest.Status__c == 'Closed');
    }
    
    private static testMethod void testMetadataRequestsBatchFailure() {
        List<Metadata_Request__c> metadataRequestList = new List<Metadata_Request__c>();
        Metadata_Request__c metadataRequestObject = new Metadata_Request__c();
        metadataRequestObject.Field__c = 'Software Version';
        metadataRequestObject.Object__c = 'Case;User, Knowledge Centered Support (KCS), Release Version, Release';
        metadataRequestObject.Value__c = 'Test picklist value';
        metadataRequestObject.Controlling_Product_Lines__c = 'CDM';
        metadataRequestObject.Status__c = 'Open';
        metadataRequestList.add(metadataRequestObject);
        
        metadataRequestObject = new Metadata_Request__c();
        metadataRequestObject.Field__c = 'Software Version';
        metadataRequestObject.Object__c = 'Case;User, Knowledge Centered Support (KCS), Release Version, Release';
        metadataRequestObject.Value__c = '1.0.Test picklist value';
        metadataRequestObject.Controlling_Product_Lines__c = 'CDM';
        metadataRequestList.add(metadataRequestObject);
        
        insert metadataRequestList;
        
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(testUser) {
            
            Test.startTest();
            
            //System.Test.setMock(HttpCalloutMock.class, new DestinationQueueSettingControllerTest.DestinationQueueSettingControllerMock());
            Test.setMock(WebServiceMock.class, new MetadataServiceTest.WebServiceMockImpl());
            Database.executeBatch(new ProcessMetadataRequestsBatch());
            
            Test.stopTest();
        }
        
        Metadata_Request__c metadataRequest = [SELECT Status__c FROM Metadata_Request__c LIMIT 1];
        System.assert(metadataRequest.Status__c == 'Closed');
    }
    private static testMethod void testifRecordTypesAreUpdated() {
        Metadata_Request__c metadataRequestObject = new Metadata_Request__c();
        metadataRequestObject.Field__c = 'Software Version';
        metadataRequestObject.Object__c = 'Case;User, Knowledge Centered Support (KCS), Release Version, Release';
        metadataRequestObject.Value__c = '1.0.Test picklist value';
        metadataRequestObject.Controlling_Product_Lines__c = 'CDM';
        metadataRequestObject.Status__c = 'Open';
        metadataRequestObject.message__c = 'and the value will be added to the Record Types shortly.';
        
        insert metadataRequestObject;
        
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(testUser) {
            
            Test.startTest();
            
            //System.Test.setMock(HttpCalloutMock.class, new DestinationQueueSettingControllerTest.DestinationQueueSettingControllerMock()); 
            Test.setMock(WebServiceMock.class, new MetadataServiceTest.WebServiceMockImpl());
            Database.executeBatch(new ProcessMetadataRequestsBatch());
            
            Test.stopTest();
        }
        
        Metadata_Request__c metadataRequest = [SELECT Status__c FROM Metadata_Request__c LIMIT 1];
        System.assert(metadataRequest.Status__c == 'Closed');
    }
    private static testMethod void testifRecordTypesAreUpdated3() {
        Metadata_Request__c metadataRequestObject = new Metadata_Request__c();
        metadataRequestObject.Field__c = 'Abra Tags';
        metadataRequestObject.Object__c = 'Case';
        metadataRequestObject.Value__c = '1.0.Test picklist value';
        metadataRequestObject.Status__c = 'Open';
        metadataRequestObject.message__c = 'and the value will be added to the Record Types shortly.';
        
        insert metadataRequestObject;
        
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(testUser) {
            
            Test.startTest();
            
            Test.setMock(WebServiceMock.class, new MetadataServiceTest.WebServiceMockImpl());
            Database.executeBatch(new ProcessMetadataRequestsBatch());
            
            Test.stopTest();
        }
        
        Metadata_Request__c metadataRequest = [SELECT Status__c FROM Metadata_Request__c LIMIT 1];
        System.assert(metadataRequest.Status__c == 'Closed');
    }
    
    
    private static testMethod void testifRecordTypesAreUpdated2() {
        Metadata_Request__c metadataRequestObject = new Metadata_Request__c();
        metadataRequestObject.Field__c = 'Software Version';
        metadataRequestObject.Object__c = 'Case;User, Knowledge Centered Support (KCS), Release Version, Release';
        metadataRequestObject.Value__c = '2.0.Test picklist value';
        metadataRequestObject.Controlling_Product_Lines__c = 'Duplicate';
        metadataRequestObject.Status__c = 'Open';
        insert metadataRequestObject;
        
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            
            //System.Test.setMock(HttpCalloutMock.class, new DestinationQueueSettingControllerTest.DestinationQueueSettingControllerMock());
            Test.setMock(WebServiceMock.class, new MetadataServiceTest.WebServiceMockImpl());
            Database.executeBatch(new ProcessMetadataRequestsBatch());
            
            Test.stopTest();
        }
        Metadata_Request__c metadataRequest = [SELECT Status__c FROM Metadata_Request__c LIMIT 1];
        System.assert(metadataRequest.Status__c == 'Closed');
    } 
    
    private static testMethod void testMetadataRequestsBatchSuccess2() {
        Metadata_Request__c metadataRequestObject = new Metadata_Request__c();
        metadataRequestObject.Field__c = 'Abra Tags';
        metadataRequestObject.Object__c = 'Case';
        metadataRequestObject.Value__c = '2.0.Test picklist value';
        metadataRequestObject.Status__c = 'Open';
        
        insert metadataRequestObject;
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            
            //System.Test.setMock(HttpCalloutMock.class, new DestinationQueueSettingControllerTest.DestinationQueueSettingControllerMock());
            Test.setMock(WebServiceMock.class, new MetadataServiceTest.WebServiceMockImpl());
            Database.executeBatch(new ProcessMetadataRequestsBatch());
            
            Test.stopTest();
        }
        
        Metadata_Request__c metadataRequest = [SELECT Status__c FROM Metadata_Request__c LIMIT 1];
        System.assert(metadataRequest.Status__c == 'Closed');
    }
    
    private static testMethod void testMetadataRequestsBatchSuccessDelete() {
        Metadata_Request__c metadataRequestObject = new Metadata_Request__c();
        metadataRequestObject.Field__c = 'Abra Tags';
        metadataRequestObject.Object__c = 'Case';
        metadataRequestObject.Value__c = '2.0.Test picklist value';
        metadataRequestObject.Status__c = 'Open';
        metadataRequestObject.Operation_Type__c = 'Delete';
        
        insert metadataRequestObject;
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(testUser) {
            
            Test.startTest();
            
            //System.Test.setMock(HttpCalloutMock.class, new DestinationQueueSettingControllerTest.DestinationQueueSettingControllerMock());
            Test.setMock(WebServiceMock.class, new MetadataServiceTest.WebServiceMockImpl());
            Database.executeBatch(new ProcessMetadataRequestsBatch());
            
            Test.stopTest();
        }
        
        Metadata_Request__c metadataRequest = [SELECT Status__c FROM Metadata_Request__c LIMIT 1];
        System.assert(metadataRequest.Status__c == 'Closed');
    }
    
    private static testMethod void testMetadataRequestsBatchSuccessUpdate() {
        Metadata_Request__c metadataRequestObject = new Metadata_Request__c();
        metadataRequestObject.Field__c = 'Abra Tags';
        metadataRequestObject.Object__c = 'Case';
        metadataRequestObject.Value__c = '2.0.Test picklist value';
        metadataRequestObject.Status__c = 'Open';
        metadataRequestObject.Operation_Type__c = 'Update';
        
        insert metadataRequestObject;
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            
            //System.Test.setMock(HttpCalloutMock.class, new DestinationQueueSettingControllerTest.DestinationQueueSettingControllerMock());
            Test.setMock(WebServiceMock.class, new MetadataServiceTest.WebServiceMockImpl());
            Database.executeBatch(new ProcessMetadataRequestsBatch());
            
            Test.stopTest();
        }
        
        Metadata_Request__c metadataRequest = [SELECT Status__c FROM Metadata_Request__c LIMIT 1];
        System.assert(metadataRequest.Status__c == 'Closed');
    }
    
    private static testMethod void testDelete2() {
        Metadata_Request__c metadataRequestObject = new Metadata_Request__c();
        metadataRequestObject.Field__c = 'Software Version';
        metadataRequestObject.Object__c = 'Case';
        metadataRequestObject.Value__c = '2.0.Test picklist value';
        metadataRequestObject.Status__c = 'Open';
        metadataRequestObject.Controlling_Product_Lines__c = 'CDM';
        metadataRequestObject.Operation_Type__c = 'Delete';
        
        insert metadataRequestObject;
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(testUser) {
            
            Test.startTest();
            
            //System.Test.setMock(HttpCalloutMock.class, new DestinationQueueSettingControllerTest.DestinationQueueSettingControllerMock());
            Test.setMock(WebServiceMock.class, new MetadataServiceTest.WebServiceMockImpl());
            Database.executeBatch(new ProcessMetadataRequestsBatch());
            
            Test.stopTest();
        }
        
        Metadata_Request__c metadataRequest = [SELECT Status__c FROM Metadata_Request__c LIMIT 1];
        System.assert(metadataRequest.Status__c == 'Closed');
    }
    private static testMethod void testUpdateWithOldValue() {
        Metadata_Request__c metadataRequestObject = new Metadata_Request__c();
        metadataRequestObject.Field__c = 'Abra Tags';
        metadataRequestObject.Object__c = 'Case';
        metadataRequestObject.Value__c = '2.0.Test picklist value';
         metadataRequestObject.Old_Value__c = '2.0.Test picklist value';
        metadataRequestObject.Status__c = 'Open';
        metadataRequestObject.Operation_Type__c = 'Update';
        
        insert metadataRequestObject;
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            
            //System.Test.setMock(HttpCalloutMock.class, new DestinationQueueSettingControllerTest.DestinationQueueSettingControllerMock());
            Test.setMock(WebServiceMock.class, new MetadataServiceTest.WebServiceMockImpl());
            Database.executeBatch(new ProcessMetadataRequestsBatch());
            
            Test.stopTest();
        }
        
        Metadata_Request__c metadataRequest = [SELECT Status__c FROM Metadata_Request__c LIMIT 1];
        System.assert(metadataRequest.Status__c == 'Closed');
    }
    private static testMethod void testMetadataRequestsBatchSuccess3() {
        Metadata_Request__c metadataRequestObject = new Metadata_Request__c();
        metadataRequestObject.Field__c = 'Abra Tags';
        metadataRequestObject.Object__c = 'Case';
        metadataRequestObject.Value__c = '1.0.Test picklist value';
        metadataRequestObject.Status__c = 'Open';
        
        insert metadataRequestObject;
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            
            //System.Test.setMock(HttpCalloutMock.class, new DestinationQueueSettingControllerTest.DestinationQueueSettingControllerMock());
            Test.setMock(WebServiceMock.class, new MetadataServiceTest.WebServiceMockImpl());
            Database.executeBatch(new ProcessMetadataRequestsBatch());
            
            Test.stopTest();
        }
        
        Metadata_Request__c metadataRequest = [SELECT Status__c FROM Metadata_Request__c LIMIT 1];
        System.assert(metadataRequest.Status__c == 'Closed');
    }
}