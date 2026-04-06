public with sharing class CreateCaseOrOpportunityController {
    private String clusterIssueId = '';
    private String objectName = '';
    public String recordId {get; set;}
    public String tabId {get; set;}

    public CreateCaseOrOpportunityController(ApexPages.StandardController clusterIssueObject) {
        clusterIssueId = ApexPages.currentPage().getParameters().get('id');
        objectName =  ApexPages.currentPage().getParameters().get('object');
        tabId = ApexPages.currentPage().getParameters().get('tabId');
        recordId = '';
    }

    public PageReference createCaseOrOpportunity() {
        SObject recordToBeInserted;

        List<Cluster_Issue_Conversion_Mapping__mdt> fieldMappingList = [SELECT Id, Object_Field_Value__c, Object_Field__c, Object_Field_Datatype__c, Dynamic__c, Object__c
                                                                        FROM Cluster_Issue_Conversion_Mapping__mdt
                                                                        WHERE Object__c =: objectName];

        Cluster_Issue__c clusterIssueRecord = [SELECT Id, Name, Account__c, Account__r.Name, Account__r.OwnerId,
                                                Cluster__r.Capacity_Days_Until_100__c, Priority__c, Cluster__r.software_version__c,
                                                Case__c, Opportunity__c, Status__c, Close_Reason__c, RecordTypeId
                                                FROM Cluster_Issue__c
                                                WHERE Id =: clusterIssueId];

        //RecordType readOnlyRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Read_Only' AND SobjectType = 'Cluster_Issue__c'];

        if(objectName == 'Case') {
            recordToBeInserted = (SObject)prepareCase(clusterIssueRecord, fieldMappingList);
        }
        else if(objectName == 'Opportunity') {
            recordToBeInserted = (SObject)prepareOpportunity(clusterIssueRecord, fieldMappingList);
        }

        try {
            insert recordToBeInserted;
            recordId = recordToBeInserted.Id;

            if(objectName == 'Case') {
                clusterIssueRecord.Case__c = recordToBeInserted.Id;
            }
            else if(objectName == 'Opportunity') {
                clusterIssueRecord.Opportunity__c = recordToBeInserted.Id;
            }

            clusterIssueRecord.Close_Reason__c = objectName + ' created';
            //clusterIssueRecord.RecordTypeId = readOnlyRecordType.Id;
            clusterIssueRecord.Mute_Notifications__c = true;
            clusterIssueRecord.Status__c = 'Closed';

            update clusterIssueRecord;
        } catch(DmlException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, e.getDmlMessage(0)));
            return null;
        } catch(Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, ex.getMessage()));
            return null;
        }
        return null;
    }

    public PageReference redirectToCreatedRecord() {
        return new PageReference('/' + recordId);
    }

    private Case prepareCase(Cluster_Issue__c clusterIssueRecord, List<Cluster_Issue_Conversion_Mapping__mdt> fieldMappingList) {
        Case caseObject = new Case();
        caseObject.Subject = clusterIssueRecord.Name;

        if(clusterIssueRecord.Cluster__r.Capacity_Days_Until_100__c != null) {
            caseObject.Subject += ' - ' + (System.Label.Cluster_Utilisation_Message).replace('<days>', String.valueOf(clusterIssueRecord.Cluster__r.Capacity_Days_Until_100__c));
            caseObject.Description = (System.Label.Cluster_Utilisation_Message).replace('<days>', String.valueOf(clusterIssueRecord.Cluster__r.Capacity_Days_Until_100__c));
        }

        caseObject.Software_Version__c = clusterIssueRecord.Cluster__r.software_version__c;

        //Map fields directly from the data stored in Campaign to Opportunity Field mapping custom metadata
        for(Cluster_Issue_Conversion_Mapping__mdt eachField : fieldMappingList) {
            if(eachField.Dynamic__c) {
                caseObject.put(eachField.Object_Field__c, clusterIssueRecord.get(eachField.Object_Field_Value__c));
            }
            else {
                if(eachField.Object_Field_Datatype__c.equalsIgnoreCase('Text')) {
                    caseObject.put(eachField.Object_Field__c, eachField.Object_Field_Value__c);
                }
                /*else if(eachField.Object_Field_Datatype__c.equalsIgnoreCase('Number')) {
                    caseObject.put(eachField.Object_Field__c, Integer.valueOf(eachField.Object_Field_Value__c));
                }
                else if(eachField.Object_Field_Datatype__c.equalsIgnoreCase('Date')) {
                    caseObject.put(eachField.Object_Field__c, System.today() + Integer.valueOf(eachField.Object_Field_Value__c));
                }*/
            }
        }
        return caseObject;
    }

    private Opportunity prepareOpportunity(Cluster_Issue__c clusterIssueRecord, List<Cluster_Issue_Conversion_Mapping__mdt> fieldMappingList) {
        Opportunity opportunityObject = new Opportunity();

        opportunityObject.Name = clusterIssueRecord.Account__r.Name + ' - ' + clusterIssueRecord.Name;

        //Relate the opportunity to the Account of the member who responded to the campaign
        //opportunityObject.AccountId = clusterIssueRecord.Cluster__r.Account__c;

        //Map the owner of the Account of the member who responded to the Opportunity owner
        opportunityObject.OwnerId = clusterIssueRecord.Account__r.OwnerId;

        //Map fields directly from the data stored in Campaign to Opportunity Field mapping custom metadata
        for(Cluster_Issue_Conversion_Mapping__mdt eachField : fieldMappingList) {
            if(eachField.Dynamic__c) {
                opportunityObject.put(eachField.Object_Field__c, clusterIssueRecord.get(eachField.Object_Field_Value__c));
            }
            else {
                if(eachField.Object_Field_Datatype__c.equalsIgnoreCase('Text')) {
                    opportunityObject.put(eachField.Object_Field__c, eachField.Object_Field_Value__c);
                }
                else if(eachField.Object_Field_Datatype__c.equalsIgnoreCase('Number')) {
                    opportunityObject.put(eachField.Object_Field__c, Integer.valueOf(eachField.Object_Field_Value__c));
                }
                else if(eachField.Object_Field_Datatype__c.equalsIgnoreCase('Date')) {
                    opportunityObject.put(eachField.Object_Field__c, System.today() + Integer.valueOf(eachField.Object_Field_Value__c));
                }
            }
        }
        return opportunityObject;
    }
}