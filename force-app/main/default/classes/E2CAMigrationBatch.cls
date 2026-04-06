global class E2CAMigrationBatch implements Database.Batchable<sObject>, Database.Stateful{

    global String query='';
    global String queryLimit='';
    global String lcId='';
    global String LgCaseId='';

    global Integer cpuTime;
    global Integer heapSize;
    global List<String> csIds;
    global List<String> lcIdList = new List<String>();
    global E2CAMigrationBatch(String queryString, List<String> csIds,String lcId,String LgCaseId, Integer cpuTime, Integer heapSize){
        this.query = queryString;
        this.queryLimit = queryLimit;
        this.lcId = lcId;
        this.LgCaseId = LgCaseId;

        this.cpuTime = cpuTime;
        this.heapSize = heapSize;
        this.csIds = csIds;
    }

    global Database.Querylocator start(Database.BatchableContext BC){
        List<String> csList = csIds;
        String finalQuery = 'SELECT id FROM Case '+ query;
        return Database.getQueryLocator(finalQuery);
    }
    global void execute(Database.BatchableContext BC,List<Case> caseList){
        List<String> caseIdList = new List<String>();
        List<E2CAdv__Long_Comments__c> longCommentsList = new List<E2CAdv__Long_Comments__c>();
        Map<String, E2CAdv__Long_Comments__c> CaseLongComment = new Map<String, E2CAdv__Long_Comments__c>();
        Map<String, E2CAdv__Long_Comments__c> ExistingCaseLongComment = new Map<String, E2CAdv__Long_Comments__c>();
        set<String> CaseStaticLongcomment = new Set<String>();
        for(Case cs: caseList){
            caseIdList.add(cs.id);
        }

        for(E2CAdv__Long_Comments__c lc : [Select id,purpose__c,E2CAdv__Parent__c from E2CAdv__Long_Comments__c where purpose__c!=null AND E2CAdv__Parent__c IN: caseIdList]){
            ExistingCaseLongComment.put(lc.E2CAdv__Parent__c+'_'+lc.purpose__c,lc);
        }

        for(Case cs: caseList){

            if(!ExistingCaseLongComment.containsKey(cs.id+'_Private')){
                // Private long comment
                E2CAdv__Long_Comments__c privateLongCommentObj = new E2CAdv__Long_Comments__c();
                privateLongCommentObj.E2CAdv__Parent__c = cs.Id;
                privateLongCommentObj.E2CAdv__Comment_Body__c = 'Private Long Comment for legacy data';
                privateLongCommentObj.E2CAdv__Comment_Status__c = 'Sent';
                privateLongCommentObj.E2CAdv__Published__c = false;
                privateLongCommentObj.E2CAdv__IsCommentTrimmed__c = false;
                privateLongCommentObj.purpose__c ='Private';
                CaseLongComment.put(cs.id+'_Private', privateLongCommentObj);

            }

            if(!ExistingCaseLongComment.containsKey(cs.id+'_Public')){
                // Public  long comment
                E2CAdv__Long_Comments__c PublicLongCommentObj = new E2CAdv__Long_Comments__c();
                PublicLongCommentObj.E2CAdv__Parent__c = cs.Id;
                PublicLongCommentObj.E2CAdv__Comment_Body__c = 'Public Long Comment for legacy data';
                PublicLongCommentObj.E2CAdv__Comment_Status__c = 'Sent';
                PublicLongCommentObj.E2CAdv__Published__c = true;
                PublicLongCommentObj.E2CAdv__IsCommentTrimmed__c = false;
                PublicLongCommentObj.purpose__c ='Public';

                CaseLongComment.put(cs.id+'_Public', PublicLongCommentObj);

            }
            if(!ExistingCaseLongComment.containsKey(cs.id+'_History')){
                // History  long comment
                E2CAdv__Long_Comments__c HistoryLongCommentObj = new E2CAdv__Long_Comments__c();
                HistoryLongCommentObj.E2CAdv__Parent__c = cs.Id;
                HistoryLongCommentObj.E2CAdv__Comment_Body__c = 'History Long Comment for Legacy Data';
                HistoryLongCommentObj.E2CAdv__Comment_Status__c = 'Sent';
                HistoryLongCommentObj.E2CAdv__IsCommentTrimmed__c = false;
                HistoryLongCommentObj.E2CAdv__Published__c = false;
                HistoryLongCommentObj.E2CAdv__For_Case_History__c  = true;
                HistoryLongCommentObj.purpose__c ='History';
                CaseLongComment.put(cs.id+'_History', HistoryLongCommentObj);

            }
        }

        Map<String, List<CaseComment>> CaseIdToCaseCommentMap = new Map<String, List<CaseComment>>();
        Map<String, List<EmailMessage>> CaseIdToEmailMap = new Map<String, List<EmailMessage>>();
        List<String> cscList = new List<String>();
        List<String> cscEntityIdList = new List<String>();
        for(E2CAdv__CommentSourceControllers__c csc: [select E2CAdv__CaseCommentId__c, E2CAdv__Entity_Id__c
                                                      from E2CAdv__CommentSourceControllers__c where E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c in:caseIdList ]){
                                                          if(!Test.isRunningTest()){
                                                              cscList.add(csc.E2CAdv__CaseCommentId__c);
                                                              cscEntityIdList.add(csc.E2CAdv__Entity_Id__c);
                                                          }
                                                      }
        Map<String, CaseComment> IdToCCMap = new Map<String, CaseComment>();
        Map<String, EmailMessage> IdToEmailMap = new Map<String, EmailMessage>();
        String query = 'SELECT Id,CreatedById, ParentId, CommentBody,createdDate,IsPublished FROM CaseComment where ParentId IN: caseIdList AND Id NOT IN:cscList order by createddate desc';
        System.debug('query==> '+ query);
        for(CaseComment cc: Database.query(query)){
            if(!CaseIdToCaseCommentMap.containsKey(String.valueOf(cc.ParentId))){
                CaseIdToCaseCommentMap.put(cc.ParentId, new List<CaseComment>{cc});
            }
            else{
                CaseIdToCaseCommentMap.get(cc.ParentId).add(cc);
            }
            IdToCCMap.put(cc.Id, cc);
        }
        if(IdToCCMap.isEmpty()){
           return;
        }
        for(EmailMessage eml: [SELECT Id, ParentId, TextBody, CreatedDate FROM EmailMessage where ParentId IN: caseIdList and Id NOT IN:cscEntityIdList order by createddate desc ]){
            if(!CaseIdToEmailMap.containsKey(String.valueOf(eml.ParentId))){
                CaseIdToEmailMap.put(eml.ParentId, new List<EmailMessage>{eml});
            }
            else{
                CaseIdToEmailMap.get(eml.ParentId).add(eml);
            }
            IdToEmailMap.put(eml.Id, eml);
        }

        Map<String, Map<String,List<String>>> CsIdToCCIdToEmailIdMap = new Map<String, Map<String,List<String>>>();
        Set<id> doesNotContainEmailMsg = new Set<id>();
        Boolean IsExitLoop=false;
        List<E2CAdv__CommentSourceControllers__c> sourceControllerList = new List<E2CAdv__CommentSourceControllers__c>();
        System.debug('limits.getCpuTime() 1==> '+ limits.getCpuTime());
        System.debug('limits.getHeapSize() 1==> '+ limits.getHeapSize());
        for(String csId: CaseIdToCaseCommentMap.keyset()){
            if(IsExitLoop==true){
                break;
            }
            for(CaseComment cc: CaseIdToCaseCommentMap.get(csId)){
                if(IsExitLoop==true){
                    break;
                }
                if(CaseIdToEmailMap.containsKey(csId) && CaseIdToEmailMap.get(csId)!=null){
                    for(EmailMessage emg: CaseIdToEmailMap.get(csId)){
                        if(limits.getHeapSize()>heapSize || limits.getCpuTime()>cpuTime){
                            IsExitLoop = true;
                            break;
                        }
                        Datetime ccnegtime =   cc.createdDate.addSeconds(-5);
                        Datetime ccpostime =   cc.createdDate.addSeconds(+10);
                        if(ccnegtime<=emg.CreatedDate && ccpostime>emg.CreatedDate){
                            if(!CsIdToCCIdToEmailIdMap.containsKey(String.valueOf(cc.ParentId))){
                                Map<String, List<String>> CaseCommentToEmailMap = new Map<String, List<String>>();
                                CaseCommentToEmailMap.put(cc.Id, new List<String>{emg.Id});
                                CsIdToCCIdToEmailIdMap.put(cc.ParentId, CaseCommentToEmailMap);
                            }
                            else{
                                Map<String, List<String>> CCIdToEmailMap = CsIdToCCIdToEmailIdMap.get(cc.ParentId);
                                if(!CCIdToEmailMap.containsKey(String.valueOf(cc.Id))){
                                    CCIdToEmailMap.put(cc.Id, new List<String>{emg.Id});
                                }
                                else{
                                    CCIdToEmailMap.get(cc.Id).add(emg.Id);
                                }
                                CsIdToCCIdToEmailIdMap.get(cc.ParentId).putAll(CCIdToEmailMap);
                            }
                        }else{

                            if(CsIdToCCIdToEmailIdMap.containsKey(cc.ParentId)){
                                if(CsIdToCCIdToEmailIdMap.get(cc.ParentId).containsKey(cc.Id)){
                                    // nothing to do here because map already has parent case and case comment id
                                }else{
                                    Map<String, List<String>> CaseCommentToEmailMap = new Map<String, List<String>>();
                                    CaseCommentToEmailMap.put(cc.Id, new List<String>());
                                    CsIdToCCIdToEmailIdMap.get(cc.ParentId).putAll(CaseCommentToEmailMap);
                                }
                            }else{
                                Map<String, List<String>> CaseCommentToEmailMap = new Map<String, List<String>>();
                                CaseCommentToEmailMap.put(cc.Id, new List<String>());
                                CsIdToCCIdToEmailIdMap.put(cc.ParentId, CaseCommentToEmailMap);
                            }
                        }

                    }
                }
                else{
                    doesNotContainEmailMsg.add(cc.id);
                }
            }
        }

        if(!CaseLongComment.IsEmpty() && IsExitLoop==false){
            try{
                List<Database.SaveResult> results = Database.insert(CaseLongComment.values(),false);
            }
            catch(Exception e) {
                System.debug('<b>Cause :</b> ' + e.getCause() + '<br/><br/> <b>Line Number:</b> ' + e.getLineNumber() + '<br/> <b>Error Message:</b> ' + e.getMessage() + '<br/> <b>Stack trace:</b>' + e.getStackTraceString() + '<br/> <b>Exception Type:</b> ' + e.getTypeName());
            }
        }
        for(String csId: CsIdToCCIdToEmailIdMap.keySet()){
            if(IsExitLoop==true){
                break;
            }
            Map<String, List<String>> mp= CsIdToCCIdToEmailIdMap.get(csId);
            for(String ccId: mp.keySet()){
                List<String> emailIdList = mp.get(ccId);
                if(emailIdList.isEmpty()){
                    doesNotContainEmailMsg.add(ccId);
                }else if(emailIdList.size()>1){
                    boolean matchflag =false;
                    for(String emId: emailIdList){
                        if(IdToEmailMap.get(emId).TextBody != null){
                            String CaseCommentBody = (IdToCCMap.get(ccId).CommentBody).stripHTMLtags();
                            String EmailBody = (IdToEmailMap.get(emId).TextBody).stripHTMLtags();
                            if((CaseCommentBody.contains(EmailBody)) || (EmailBody.contains(CaseCommentBody))){
                                E2CAdv__CommentSourceControllers__c csc = new E2CAdv__CommentSourceControllers__c();
                                csc.E2CAdv__Comment_Source__c = 'Email';
                                if(!CaseLongComment.IsEmpty()){
                                    csc.E2CAdv__Long_Comments_Id__c = IdToCCMap.get(ccId).IsPublished?CaseLongComment.get(csId+'_Public').Id:CaseLongComment.get(csId+'_Private').Id;
                                }
                                else{
                                    csc.E2CAdv__Long_Comments_Id__c = IdToCCMap.get(ccId).IsPublished?ExistingCaseLongComment.get(csId+'_Public').Id:ExistingCaseLongComment.get(csId+'_Private').Id;
                                }
                                csc.E2CAdv__Entity_Id__c = emId;
                                csc.E2CAdv__CaseCommentId__c = ccId;
                                csc.isMigrated__c =true;
                                //csc.OwnerId = IdToCCMap.get(ccId).CreatedById;
                                csc.CreatedById = IdToCCMap.get(ccId).CreatedById;
                                csc.createddate =IdToCCMap.get(ccId).createddate;

                                sourceControllerList.add(csc);
                                matchflag =true;
                                break;
                            }
                        }
                    }
                    if(!matchflag){
                        E2CAdv__CommentSourceControllers__c csc = new E2CAdv__CommentSourceControllers__c();
                        csc.E2CAdv__Comment_Source__c = 'CaseComment';
                        if(!CaseLongComment.IsEmpty()){
                            csc.E2CAdv__Long_Comments_Id__c = IdToCCMap.get(ccId).IsPublished?CaseLongComment.get(csId+'_Public').Id:CaseLongComment.get(csId+'_Private').Id;
                        }
                        else{
                            csc.E2CAdv__Long_Comments_Id__c = IdToCCMap.get(ccId).IsPublished?ExistingCaseLongComment.get(csId+'_Public').Id:ExistingCaseLongComment.get(csId+'_Private').Id;
                        }                        csc.E2CAdv__CaseCommentId__c = ccId;
                        csc.E2CAdv__Entity_Id__c = ccId;
                        csc.isMigrated__c =true;
                        csc.CreatedById = IdToCCMap.get(ccId).CreatedById;
                        csc.createddate =IdToCCMap.get(ccId).createddate;

                        sourceControllerList.add(csc);
                    }
                }
                else if(emailIdList.size()==1){
                    // having a seperate section as here we do not need to compare the body and it will help us to save processing time.
                    E2CAdv__CommentSourceControllers__c csc = new E2CAdv__CommentSourceControllers__c();
                    csc.E2CAdv__Comment_Source__c = 'Email';
                    if(!CaseLongComment.IsEmpty()){
                        csc.E2CAdv__Long_Comments_Id__c = IdToCCMap.get(ccId).IsPublished?CaseLongComment.get(csId+'_Public').Id:CaseLongComment.get(csId+'_Private').Id;
                    }
                    else{
                        csc.E2CAdv__Long_Comments_Id__c = IdToCCMap.get(ccId).IsPublished?ExistingCaseLongComment.get(csId+'_Public').Id:ExistingCaseLongComment.get(csId+'_Private').Id;
                    }
                    csc.E2CAdv__Entity_Id__c = emailIdList[0];
                    csc.E2CAdv__CaseCommentId__c = ccId;
                    csc.CreatedById = IdToCCMap.get(ccId).CreatedById;
                    csc.isMigrated__c =true;
                    csc.createddate =IdToCCMap.get(ccId).createddate;

                    sourceControllerList.add(csc);
                }
            }

        }
        for(String CCID: doesNotContainEmailMsg){
            if(IsExitLoop==true){
                break;
            }
            E2CAdv__CommentSourceControllers__c csc = new E2CAdv__CommentSourceControllers__c();
            csc.E2CAdv__Comment_Source__c = 'CaseComment';

            if(!CaseLongComment.IsEmpty()){
                csc.E2CAdv__Long_Comments_Id__c = IdToCCMap.get(CCID).IsPublished?CaseLongComment.get(IdToCCMap.get(CCID).ParentId+'_Public').Id:CaseLongComment.get(IdToCCMap.get(CCID).ParentId+'_Private').Id;
            }
            else{
                csc.E2CAdv__Long_Comments_Id__c = IdToCCMap.get(CCID).IsPublished?ExistingCaseLongComment.get(IdToCCMap.get(CCID).ParentId+'_Public').Id:ExistingCaseLongComment.get(IdToCCMap.get(CCID).ParentId+'_Private').Id;
            }
            csc.E2CAdv__Entity_Id__c = CCID;
            csc.E2CAdv__CaseCommentId__c = CCID;
            csc.isMigrated__c =true;
            csc.CreatedById = IdToCCMap.get(CCID).CreatedById;
            csc.createddate =IdToCCMap.get(CCID).createddate;

            sourceControllerList.add(csc);
        }

        System.debug('sourceControllerList.size==> '+ sourceControllerList.size());
        if(!sourceControllerList.isEmpty() && IsExitLoop==false){
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
                if(!lcIdList.contains(lc.Id)){
                    lcIdList.add(lc.Id);
                }
            }
            catch(Exception ex){
                E2CAdv__Long_Comments__c lc1 = new E2CAdv__Long_Comments__c();
                lc1.Name = 'Migration 1';
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
    global void finish(Database.BatchableContext BC){

    }
}