global class E2CAHistoryMigrationBatch implements Database.Batchable<sObject>, Database.Stateful{

    global String query='';
    global String fields='';
    global Integer cpuTime;
    global Integer heapSize;
    global String lcId='';
    global String LgCaseId='';
    global E2CAHistoryMigrationBatch(String queryString, String fields,String lcId,String LgCaseId, Integer cpuTime, Integer heapSize){
        this.query = queryString;
        this.fields = fields;
        this.cpuTime = cpuTime;
        this.heapSize = heapSize;
        this.lcId = lcId;
        this.LgCaseId = LgCaseId;
    }

    global Database.Querylocator start(Database.BatchableContext BC){
        String finalQuery = 'SELECT id FROM Case '+ query;
        return Database.getQueryLocator(finalQuery);
    }
    global void execute(Database.BatchableContext BC,List<Case> caseList){
        Boolean IsExitLoop=false;
        List<String> caseIdList = new List<String>();
        List<E2CAdv__Long_Comments__c> longCommentsList = new List<E2CAdv__Long_Comments__c>();
        Map<String, E2CAdv__Long_Comments__c> CaseLongComment = new Map<String, E2CAdv__Long_Comments__c>();
        Map<String, E2CAdv__Long_Comments__c> ExistingCaseLongComment = new Map<String, E2CAdv__Long_Comments__c>();
        set<String> CaseStaticLongcomment = new Set<String>();
        Map<String, List<CaseHistory>> CaseIdToHistoryMap = new Map<String, List<CaseHistory>>();
        for(Case cs: caseList){
            caseIdList.add(cs.id);
        }
        System.debug('caseIdList.size==> '+ caseIdList.size());
        for(E2CAdv__Long_Comments__c lc : [Select id,purpose__c,E2CAdv__Parent__c from E2CAdv__Long_Comments__c where E2CAdv__For_Case_History__c=true AND E2CAdv__Parent__c IN: caseIdList]){
            if(!ExistingCaseLongComment.containsKey(lc.E2CAdv__Parent__c)){
                ExistingCaseLongComment.put(lc.E2CAdv__Parent__c,lc);
            }
        }
        System.debug('ExistingCaseLongComment.size==> '+ ExistingCaseLongComment.size());
        for(Case cs: caseList){
            if(!ExistingCaseLongComment.containsKey(cs.id)){
                // History  long comment
                E2CAdv__Long_Comments__c HistoryLongCommentObj = new E2CAdv__Long_Comments__c();
                HistoryLongCommentObj.E2CAdv__Parent__c = cs.Id;
                HistoryLongCommentObj.E2CAdv__Comment_Body__c = 'History Long Comment for Legacy Data';
                HistoryLongCommentObj.E2CAdv__Comment_Status__c = 'Sent';
                HistoryLongCommentObj.E2CAdv__IsCommentTrimmed__c = false;
                HistoryLongCommentObj.E2CAdv__Published__c = false;
                HistoryLongCommentObj.E2CAdv__For_Case_History__c  = true;
                HistoryLongCommentObj.purpose__c ='History';
                CaseLongComment.put(cs.id, HistoryLongCommentObj);

            }
        }
        System.debug('CaseLongComment.size==> '+ CaseLongComment.size());
        List<String> cscList = new List<String>();
        for(E2CAdv__CommentSourceControllers__c csc: [select E2CAdv__Entity_Id__c
                                                     from E2CAdv__CommentSourceControllers__c where E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c in:caseIdList ]){
                                                         cscList.add(csc.E2CAdv__Entity_Id__c);
                                                     }
        System.debug('cscList.size==> '+ cscList.size());
        System.debug('fields==> '+ fields);
        Integer count = 0;
        if(!String.isBlank(fields)){
            List<String> fieldsToMigrate = fields.split(',');
            System.debug('fieldsToMigrate==> '+ fieldsToMigrate);
            for(CaseHistory HistoryRecord: [SELECT Id, CaseId, DataType, CreatedDate, Field, OldValue, NewValue,CreatedById,CreatedBy.profile.Name, CreatedBy.Name FROM CaseHistory where CaseId IN:caseIdList AND  Field IN:fieldsToMigrate AND Id NOT IN: cscList]){
                if(limits.getHeapSize()>heapSize || limits.getCpuTime()>cpuTime){
                    IsExitLoop = true;
                    break;
                }
                if(HistoryRecord.DataType != ''
                   && HistoryRecord.DataType != null
                   && HistoryRecord.DataType == 'EntityId'){
                       continue;
                   }
                if(CaseIdToHistoryMap.containsKey(HistoryRecord.CaseId)){
                    CaseIdToHistoryMap.get(HistoryRecord.CaseId).add(HistoryRecord);
                }
                else{
                    CaseIdToHistoryMap.put(HistoryRecord.CaseId, new List<CaseHistory>{HistoryRecord});
                }
                count++;
            }
        }
        System.debug('count==> '+ count);
        List<E2CAdv__CommentSourceControllers__c> sourceControllerList = new List<E2CAdv__CommentSourceControllers__c>();

        if(!CaseLongComment.IsEmpty()){
            try{
                List<Database.SaveResult> results = Database.insert(CaseLongComment.values(),false);
            }
            catch(Exception e) {
                System.debug('<b>Cause :</b> ' + e.getCause() + '<br/><br/> <b>Line Number:</b> ' + e.getLineNumber() + '<br/> <b>Error Message:</b> ' + e.getMessage() + '<br/> <b>Stack trace:</b>' + e.getStackTraceString() + '<br/> <b>Exception Type:</b> ' + e.getTypeName());
            }
        }
        for(String csId: CaseIdToHistoryMap.keySet()){
            if(IsExitLoop==true){
                break;
            }
            System.debug('csId==> '+ csId);
            List<CaseHistory> historyList= CaseIdToHistoryMap.get(csId);
            System.debug('historyList.size==> '+ historyList.size());
            for(CaseHistory his: historyList){
                if(limits.getHeapSize()>heapSize || limits.getCpuTime()>cpuTime){
                    IsExitLoop = true;
                    break;
                }
                E2CAdv__CommentSourceControllers__c csc = new E2CAdv__CommentSourceControllers__c();
                csc.E2CAdv__Comment_Source__c = 'CaseHistory';
                if(!CaseLongComment.IsEmpty() && CaseLongComment.containsKey(csId) && CaseLongComment.get(csId)!=null){
                    csc.E2CAdv__Long_Comments_Id__c = CaseLongComment.get(csId).Id;
                }
                else{
                    csc.E2CAdv__Long_Comments_Id__c = ExistingCaseLongComment.get(csId).Id;
                }
                csc.E2CAdv__Entity_Id__c = his.Id;
                csc.isMigrated__c =true;
                //csc.OwnerId = his.CreatedById;
                csc.CreatedById = his.CreatedById;
                csc.createddate =his.createddate;
                sourceControllerList.add(csc);
            }
        }

        System.debug('sourceControllerList.size==> '+ sourceControllerList.size());
        if(!sourceControllerList.isEmpty()){
            try{
                insert sourceControllerList;
            }
            catch(Exception e) {
                System.debug('<b>Cause :</b> ' + e.getCause() + '<br/><br/> <b>Line Number:</b> ' + e.getLineNumber() + '<br/> <b>Error Message:</b> ' + e.getMessage() + '<br/> <b>Stack trace:</b>' + e.getStackTraceString() + '<br/> <b>Exception Type:</b> ' + e.getTypeName());
            }
        }
        if(IsExitLoop==true){
            try{
                E2CAdv__Long_Comments__c lc = [Select Id, E2CAdv__Comment_Body__c from E2CAdv__Long_Comments__c where Id=:lcId];
                String cmntBody = lc.E2CAdv__Comment_Body__c;
                if(String.isNotBlank(cmntBody)){
                    List<String> newCaseList = new List<String>();
                    for(String cId: caseIdList){
                        if(!cmntBody.contains(String.valueOf(cId))){
                            newCaseList.add(cId);
                        }
                    }
                    if(newCaseList.size()>0){
                        String newCaseString = String.join(newCaseList, ';');
                        cmntBody = cmntBody+';'+newCaseString;
                        lc.E2CAdv__Comment_Body__c = cmntBody;
                    }
                    else{
                        lc.E2CAdv__Comment_Body__c = cmntBody;
                    }
                }
                else{
                    lc.E2CAdv__Comment_Body__c = String.join(caseIdList, ';');
                }
                update lc;
            }
            catch(Exception ex){
                E2CAdv__Long_Comments__c lc1 = new E2CAdv__Long_Comments__c();
                lc1.Name = 'History 1st Batch failed';
                lc1.E2CAdv__Parent__c = LgCaseId;
                insert lc1;
                if(lc1.Id!=null){
                    E2CAdv__Long_Comments__c lcRec = [Select Id, E2CAdv__Comment_Body__c from E2CAdv__Long_Comments__c where Id=:lc1.Id];
                    try{
                        if(String.isNotBlank(lcRec.E2CAdv__Comment_Body__c)){
                            String cmntBody = lcRec.E2CAdv__Comment_Body__c;
                            List<String> newCaseList = new List<String>();
                            for(String cId: caseIdList){
                                if(!cmntBody.contains(String.valueOf(cId))){
                                    newCaseList.add(cId);
                                }
                            }
                            if(newCaseList.size()>0){
                                String newCaseString = String.join(newCaseList, ';');
                                cmntBody = cmntBody+';'+newCaseString;
                                lcRec.E2CAdv__Comment_Body__c = cmntBody;
                            }
                            else{
                                lcRec.E2CAdv__Comment_Body__c = cmntBody;
                            }
                        }
                        else{
                            lcRec.E2CAdv__Comment_Body__c = String.join(caseIdList, ';');
                        }

                        update lcRec;
                      lcId=lcRec.id;
                    }
                    catch(Exception ex1){

                    }
                }
            }
        }
    }
    global void finish(Database.BatchableContext BC){}
}