public with sharing class SandboxRefreshCustomMetadataBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
        private String objectApiName;
        private List<String> updateFieldList;
        private String configName;
        
        public SandboxRefreshCustomMetadataBatch(){}
        public SandboxRefreshCustomMetadataBatch(String objectApiName, List<String> updateFieldList,String configName){
            this.objectApiName = objectApiName;
            this.updateFieldList = updateFieldList;
            this.configName = configName;
        }
        public Iterable<SObject> Start(Database.BatchableContext BC){   
            
            if(!String.isBlank(objectApiName) && !updateFieldList.isEmpty()) {
                String[] objectNameList = new String[]{objectApiName};
                    // Make the describe call
                Schema.DescribeSobjectResult[] results = Schema.describeSObjects(objectNameList);
                Map<String, Schema.SObjectField> fieldInfo = results[0].fields.getMap();
                //get the object details
                String query = 'SELECT '; 
                // For each returned result, get some info
                for(String apiName : fieldInfo.keySet()) {
                    query += apiName + ', ';
                }
                //remove extra ,
                query = query.substring(0, query.length()-2);
                //query and output messages
                query += ' FROM ' + objectApiName + (Test.isRunningTest() ? ' LIMIT 1 ' : '');
                System.debug(query);
                return Database.getQueryLocator(query); 
            }else{
                return null;
            }
        }
        
        public void execute (Database.BatchableContext BC, List<SObject> scope){   
            for(sObject sObjectRecord : scope) {
                Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
                customMetadata.fullName = objectApiName+'.'+sObjectRecord.get('DeveloperName');
                customMetadata.Label = String.valueOf(sObjectRecord.get('Label'));
                for(String fieldUpdate : updateFieldList) {
                    if(String.valueOf(sObjectRecord.get(fieldUpdate)) != null) {
                        Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
                        customField.field = fieldUpdate;
                        String emailsCSV = String.valueOf(sObjectRecord.get(fieldUpdate));
                        emailsCSV = emailsCSV.replaceAll(' ', '');
                        emailsCSV = emailsCSV.replaceAll('\n', ',');
                        List<String> recordEmails = emailsCSV.split(',');

                        System.debug('recordEmails :: '+recordEmails);
                        String emails = '';
                        for(String emailStr: recordEmails) {
                            if(String.isNotBlank(emailStr)){
                                emails += (emailStr.endsWithIgnoreCase(SandboxRefreshUtil.EMAIL_SUFFIX) ? emailStr : emailStr + SandboxRefreshUtil.EMAIL_SUFFIX) + ', ';
                            }
                        }
                        emails = emails.removeEnd(', ').trim();
                        customField.value = emails;
                        customMetadata.values.add(customField);
                    }
                }
                Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
                mdContainer.addMetadata(customMetadata);
                PostMetaDataUpdateCallback callback = new PostMetaDataUpdateCallback();
                if(!Test.isRunningTest()){
                    Metadata.Operations.enqueueDeployment(mdContainer, callback);
                }
            }
        }


            
        public void finish(Database.BatchableContext bc){
            SandboxRefreshUtil.updateSandboxRefreshConfig(configName, 'Completed', '');
        }
    }