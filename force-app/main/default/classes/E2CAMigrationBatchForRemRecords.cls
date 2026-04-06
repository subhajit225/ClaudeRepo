global class E2CAMigrationBatchForRemRecords implements Database.Batchable<sObject>, Database.Stateful{

    global Integer cpuTime;
    global Integer heapSize;
    global String lcId='';
    global String LgCaseId='';
    global List<String> CsIdList;
    global List<String> cscEntityIdList;
    global List<String> lcIdList = new List<String>();
    global E2CAMigrationBatchForRemRecords(List<String> CsIdList,String lcId,String LgCaseId,Integer cpuTime, Integer heapSize){
        this.cscEntityIdList = new List<String>();
        this.CsIdList = CsIdList;
        this.lcId = lcId;
        this.LgCaseId = LgCaseId;
        this.cpuTime = cpuTime;
        this.heapSize = heapSize;
    }

    global Database.Querylocator start(Database.BatchableContext BC){
        List<String> cscList = new List<String>();
        for(E2CAdv__CommentSourceControllers__c csc: [select E2CAdv__CaseCommentId__c, E2CAdv__Entity_Id__c
                                                      from E2CAdv__CommentSourceControllers__c where E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c in:CsIdList]){
                                                          if(!Test.isRunningTest()){
                                                              cscList.add(csc.E2CAdv__CaseCommentId__c);
                                                              cscEntityIdList.add(csc.E2CAdv__Entity_Id__c);
                                                          }
                                                      }
        String finalQuery = 'SELECT Id,CreatedById, ParentId, CommentBody,createdDate,IsPublished FROM CaseComment where ParentId IN: CsIdList AND Id NOT IN:cscList order by createddate desc';
        return Database.getQueryLocator(finalQuery);
    }
    global void execute(Database.BatchableContext BC,List<CaseComment> caseCommentList){
        Map<String, E2CAdv__Long_Comments__c> CaseLongComment = new Map<String, E2CAdv__Long_Comments__c>();
        Map<String, E2CAdv__Long_Comments__c> ExistingCaseLongComment = new Map<String, E2CAdv__Long_Comments__c>();
        set<String> CaseStaticLongcomment = new Set<String>();


        Map<String, List<CaseComment>> CaseIdToCaseCommentMap = new Map<String, List<CaseComment>>();
        Map<String, List<EmailMessage>> CaseIdToEmailMap = new Map<String, List<EmailMessage>>();

        Map<String, CaseComment> IdToCCMap = new Map<String, CaseComment>();
        Map<String, EmailMessage> IdToEmailMap = new Map<String, EmailMessage>();
        for(CaseComment cc: caseCommentList){
            if(!CaseIdToCaseCommentMap.containsKey(String.valueOf(cc.ParentId))){
                CaseIdToCaseCommentMap.put(cc.ParentId, new List<CaseComment>{cc});
            }
            else{
                CaseIdToCaseCommentMap.get(cc.ParentId).add(cc);
            }
            IdToCCMap.put(cc.Id, cc);
        }
        DateTime maxTime;
        DateTime minTime;
        AggregateResult ccResult = [SELECT MAX(CreatedDate) maxTime,MIN(CreatedDate)minTime FROM CaseComment where Id in: caseCommentList];
        if(ccResult!=null){
            maxTime = (DateTime)ccResult.get('maxTime');
            maxTime = maxTime.addSeconds(+5);
            minTime = (DateTime)ccResult.get('minTime');
            minTime = minTime.addSeconds(-5);
        }

        if(IdToCCMap.isEmpty()){           return;
        }

         for(E2CAdv__Long_Comments__c lc : [Select id,purpose__c,E2CAdv__Parent__c from E2CAdv__Long_Comments__c where purpose__c!=null AND E2CAdv__Parent__c IN: CaseIdToCaseCommentMap.keySet()]){
            ExistingCaseLongComment.put(lc.E2CAdv__Parent__c+'_'+lc.purpose__c,lc);
        }

        for(String cs: CaseIdToCaseCommentMap.keySet()){

            if(!ExistingCaseLongComment.containsKey(cs+'_Private')){
                // Private long comment
                E2CAdv__Long_Comments__c privateLongCommentObj = new E2CAdv__Long_Comments__c();
                privateLongCommentObj.E2CAdv__Parent__c = cs;
                privateLongCommentObj.E2CAdv__Comment_Body__c = 'Private Long Comment for legacy data';
                privateLongCommentObj.E2CAdv__Comment_Status__c = 'Sent';
                privateLongCommentObj.E2CAdv__Published__c = false;
                privateLongCommentObj.E2CAdv__IsCommentTrimmed__c = false;
                privateLongCommentObj.purpose__c ='Private';
                CaseLongComment.put(cs+'_Private', privateLongCommentObj);

            }

            if(!ExistingCaseLongComment.containsKey(cs+'_Public')){
                // Public  long comment
                E2CAdv__Long_Comments__c PublicLongCommentObj = new E2CAdv__Long_Comments__c();
                PublicLongCommentObj.E2CAdv__Parent__c = cs;
                PublicLongCommentObj.E2CAdv__Comment_Body__c = 'Public Long Comment for legacy data';
                PublicLongCommentObj.E2CAdv__Comment_Status__c = 'Sent';
                PublicLongCommentObj.E2CAdv__Published__c = true;
                PublicLongCommentObj.E2CAdv__IsCommentTrimmed__c = false;
                PublicLongCommentObj.purpose__c ='Public';

                CaseLongComment.put(cs+'_Public', PublicLongCommentObj);

            }
            if(!ExistingCaseLongComment.containsKey(cs+'_History')){
                // History  long comment
                E2CAdv__Long_Comments__c HistoryLongCommentObj = new E2CAdv__Long_Comments__c();
                HistoryLongCommentObj.E2CAdv__Parent__c = cs;
                HistoryLongCommentObj.E2CAdv__Comment_Body__c = 'History Long Comment for Legacy Data';
                HistoryLongCommentObj.E2CAdv__Comment_Status__c = 'Sent';
                HistoryLongCommentObj.E2CAdv__IsCommentTrimmed__c = false;
                HistoryLongCommentObj.E2CAdv__Published__c = false;
                HistoryLongCommentObj.E2CAdv__For_Case_History__c  = true;
                HistoryLongCommentObj.purpose__c ='History';
                CaseLongComment.put(cs+'_History', HistoryLongCommentObj);

            }
        }




        for(EmailMessage eml: [SELECT Id, ParentId, TextBody, CreatedDate FROM EmailMessage where ParentId IN: CaseIdToCaseCommentMap.keySet() and Id NOT IN:cscEntityIdList and CreatedDate>:minTime and CreatedDate<:maxTime order by createddate desc ]){
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
        for(String csId: CaseIdToCaseCommentMap.keyset()){
            if(IsExitLoop==true){break;
            }
            for(CaseComment cc: CaseIdToCaseCommentMap.get(csId)){
                if(IsExitLoop==true){break;
                }
                if(CaseIdToEmailMap.containsKey(csId) && CaseIdToEmailMap.get(csId)!=null){
                    for(EmailMessage emg: CaseIdToEmailMap.get(csId)){
                        if(limits.getHeapSize()>heapSize || limits.getCpuTime()>cpuTime){IsExitLoop = true;break;
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
            if(IsExitLoop==true){break;
            }
            Map<String, List<String>> mp= CsIdToCCIdToEmailIdMap.get(csId);
            for(String ccId: mp.keySet()){
                if(IsExitLoop==true){break;
                }
                List<String> emailIdList = mp.get(ccId);
                if(emailIdList.isEmpty()){doesNotContainEmailMsg.add(ccId);
                }else if(emailIdList.size()>1){
                    boolean matchflag =false;
                    for(String emId: emailIdList){
                        if(limits.getHeapSize()>heapSize || limits.getCpuTime()>cpuTime){
                            IsExitLoop = true;
                            break;
                        }
                        if(IdToEmailMap.get(emId).TextBody != null){
                            String CaseCommentBody = (IdToCCMap.get(ccId).CommentBody).stripHTMLtags();
                            String EmailBody = (IdToEmailMap.get(emId).TextBody).stripHTMLtags();
                            if((CaseCommentBody.contains(EmailBody)) || (EmailBody.contains(CaseCommentBody))){
                                E2CAdv__CommentSourceControllers__c csc = new E2CAdv__CommentSourceControllers__c();
                                csc.E2CAdv__Comment_Source__c = 'Email';
                                if(!CaseLongComment.IsEmpty() && CaseLongComment.containsKey(csId+'_Public') && CaseLongComment.containsKey(csId+'_Private') ){
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
                        if(IsExitLoop==true){
                            break;
                        }
                        E2CAdv__CommentSourceControllers__c csc = new E2CAdv__CommentSourceControllers__c();
                        csc.E2CAdv__Comment_Source__c = 'CaseComment';
                        if(!CaseLongComment.IsEmpty() && CaseLongComment.containsKey(csId+'_Public') && CaseLongComment.containsKey(csId+'_Private') ){
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
                    if(IsExitLoop==true){break;
                    }
                    // having a seperate section as here we do not need to compare the body and it will help us to save processing time.
                    E2CAdv__CommentSourceControllers__c csc = new E2CAdv__CommentSourceControllers__c();
                    csc.E2CAdv__Comment_Source__c = 'Email';
                    if(!CaseLongComment.IsEmpty() && CaseLongComment.containsKey(csId+'_Public') && CaseLongComment.containsKey(csId+'_Private') ){
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
            if(limits.getHeapSize()>heapSize || limits.getCpuTime()>cpuTime){
                IsExitLoop = true;
                break;
            }
            E2CAdv__CommentSourceControllers__c csc = new E2CAdv__CommentSourceControllers__c();
            csc.E2CAdv__Comment_Source__c = 'CaseComment';

            if(!CaseLongComment.IsEmpty() && (CaseLongComment.containsKey(IdToCCMap.get(CCID).ParentId+'_Public') || CaseLongComment.containsKey(IdToCCMap.get(CCID).ParentId+'_Private')) ){
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
            List<String> CaseIdList = new List<String>();
            CaseIdList.addAll(CaseIdToCaseCommentMap.keyset());
            try{
                E2CAdv__Long_Comments__c lc = [Select Id, E2CAdv__Comment_Body__c from E2CAdv__Long_Comments__c where Id=:lcId];
                String cmntBody = lc.E2CAdv__Comment_Body__c;
                if(String.isNotBlank(cmntBody)){
                    List<String> newCaseList = new List<String>();
                    for(String cId: CaseIdList){
                        if(!cmntBody.contains(String.valueOf(cId))){newCaseList.add(cId);
                        }
                    }
                    if(newCaseList.size()>0){String newCaseString = String.join(newCaseList, ';');cmntBody = cmntBody+';'+newCaseString;lc.E2CAdv__Comment_Body__c = cmntBody;
                    }
                    else{
                        lc.E2CAdv__Comment_Body__c = cmntBody;
                    }
                }
                else{
                    lc.E2CAdv__Comment_Body__c = String.join(CaseIdList, ';');
                }
                update lc;
                if(!lcIdList.contains(lc.Id)){
                    lcIdList.add(lc.Id);
                }
            }
            catch(Exception ex){
                E2CAdv__Long_Comments__c lc1 = new E2CAdv__Long_Comments__c();
                lc1.Name = 'CaseComment 2nd Batch failed';
                lc1.E2CAdv__Parent__c = LgCaseId;
                lc1.E2CAdv__Comment_Body__c = String.join(CaseIdList, ';');

                insert lc1;
                lcId=lc1.id;

            }
        }
    }
    global void finish(Database.BatchableContext BC){
    }
}