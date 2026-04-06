/*
* @Author           :   Vijay Kumar K R
* @CreatedDate      :   
* @lwc              :   customDataTable.lwc
* @TestClass        :   customDataTableControllerTest.cls
* -------------------------- @History ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Story Number       Modified By              Date                          Description
* CS21-1378         Vijay Kumar K R        Nov 29 2022    Enable Escalation Management Team (EMT) Reporting within Salesforce Lightning
* ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class customDataTableController {
    
    @AuraEnabled(cacheable=true)
    public static WrapperClass getFieldsInfo(String objectName, String fieldSetName, Id parentRecordId, String filterStr) {
        System.debug('getFieldsInfo: objectName: '+objectName+' fieldSetName: '+fieldSetName+' parentRecordId: '+parentRecordId+' filter: '+filterStr);
        try {
            
            Schema.SObjectType objectType = null;
            if (String.isNotBlank(objectName)) {
                objectType = Schema.getGlobalDescribe().get(objectName);
            }
            
            Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
            Map<String, Schema.FieldSet> fieldSetMap = objectDescribe.fieldSets.getMap();
            Schema.FieldSet fieldSet = fieldSetMap.get(fieldSetName);
            List<Schema.FieldSetMember> fieldSetMembers = fieldSet.getFields();

            Map<String, String> typeInfoByDevName = new Map<String, String>();
            for(FieldDefinition objFldDef : [SELECT DeveloperName, ExtraTypeInfo 
                                                FROM FieldDefinition 
                                                WHERE EntityDefinitionId = 'Note__c']){
                typeInfoByDevName.put(objFldDef.DeveloperName, objFldDef.ExtraTypeInfo);
            }
            
            String fldApiStr = '';

            List<FieldDetail> fldInfo = new List<FieldDetail>();
            for (Schema.FieldSetMember fsm : fieldSetMembers) {

                // Initial fld info
                String fldApiName = String.valueOf(fsm.getSObjectField());
                String fldLabelName = String.valueOf(fsm.getLabel());
                String fldType = String.valueOf(fsm.getType());

                // Reference Fields
                if(fldType == 'REFERENCE'){
                    // Custom fields
                    if(fldApiName.contains('__c')){
                        fldApiName = fldApiName.split('__c')[0]+'__r.Name';
                        fldLabelName = String.valueOf(fsm.getSObjectField()).split('__c')[0].replace('_', ' ');
                    }
                    // Standard fields
                    else{
                        fldApiName = fldApiName.split('Id')[0]+'.Name';
                        fldLabelName = String.valueOf(fsm.getSObjectField()).split('Id')[0];
                    }
                }
                // distinguish between RichText / LongText Area fields
                else if(fldType == 'TEXTAREA'){
                        fldType = typeInfoByDevName.get(fldApiName.split('__c')[0]);   
                }
                if(fldLabelName == 'CreatedBy'){
                    fldLabelName = 'Created By';
                }
                // fields Concatination for Query String
                fldApiStr += fldApiName+' ';
                // Requeired type
                Boolean isReq = fsm.getRequired() || fsm.getDBRequired();
                // Standard fields
                Boolean isFldUpdateable = objectType.getDescribe().fields.getMap().get(String.valueOf(fsm.getSObjectField())).getDescribe().isUpdateable();
                // Final field Info from Wrapper
                fldInfo.add(new FieldDetail(fldLabelName, fldType, String.valueOf(fsm.getSObjectField()), isReq, isFldUpdateable));
            }
            
            List<sObject> sObjList = prepareQuery(fldApiStr, objectName, parentRecordId, filterStr);
            return new WrapperClass(fldInfo, sObjList);} catch(Exception e) {throw new AuraHandledException('getFields expection: '+e.getMessage());
        }
    }

    /**
     * Method: prepareQuery 
     * Description: return list of records based on filter condition 
     * params: 
     * return: WrapperClass
     **/
    @AuraEnabled(cacheable=true)
    public static List<sObject> prepareQuery(String fldApiStr, String objectName, Id parentRecordId, String sectionFilter){
        try{
            String[] values = fldApiStr.split(' ');
            String parentObjFilter = '';
            
            if(parentRecordId.getSObjectType().getDescribe().getName() == 'Escalation__c'){
                parentObjFilter = ' Escalation__c = \''+String.escapeSingleQuotes(parentRecordId)+'\'';
            }else{
                parentObjFilter = ' Lessons_Learned__c = \''+String.escapeSingleQuotes(parentRecordId)+'\'';
            }
            
            String query = 'SELECT Id, isDraft__c, '+String.escapeSingleQuotes(String.join( values, ' , ' ))+' FROM '+String.escapeSingleQuotes(objectName);
            query += ' WHERE '+ parentObjFilter +' AND Section_Type__c = \''+String.escapeSingleQuotes(sectionFilter)+'\' ORDER BY CreatedDate DESC ';
            
            System.debug('query: '+query);
            return Database.query(query);} catch (Exception e) {throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Method:      saveNotes 
     * Description: UPDATE notes edited
     * params:      notesStrData
     * return:      void
     **/
    @AuraEnabled
    public static List<Note__c> saveNotes(String notesStrData){
        System.debug('notesStrData:: '+notesStrData);
        try{
            List<Note__c> noteList = (List<Note__c>) JSON.deserialize(notesStrData, List<Note__c>.class);
            UPDATE noteList;
            return noteList;} catch (Exception e) {throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class FieldDetail{
        @AuraEnabled
        public String fldLabel {get; set;}
        @AuraEnabled
        public String fldType {get; set;}
        @AuraEnabled
        public String fldApi {get; set;}
        @AuraEnabled
        public Boolean isFldReq {get; set;}
        @AuraEnabled
        public Boolean isFldUpdateable {get; set;}
        public FieldDetail(String fldLabel, String fldType, String fldApi, Boolean isFldReq, Boolean isFldUpdateable) {
            this.fldLabel = fldLabel;
            this.fldType = fldType;
            this.fldApi = fldApi;
            this.isFldReq = isFldReq;
            this.isFldUpdateable = isFldUpdateable;
        }
    }

    public class WrapperClass{
        @AuraEnabled
        public List<FieldDetail> FieldDetail {get; set;}
        @AuraEnabled
        public List<sObject> sObjectRecords {get; set;}
        public WrapperClass(List<FieldDetail> FieldDetail, List<sObject> sObjectRecords) {
            this.FieldDetail = FieldDetail;
            this.sObjectRecords = sObjectRecords;
        }
    }
}