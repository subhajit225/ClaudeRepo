public with sharing class OpportunityStage1ToClosedLostBatch  implements Database.Batchable<SObject>, Database.Stateful, Schedulable{
    String queryStr;
    public OpportunityStage1ToClosedLostBatch(String queryStr){
        this.queryStr = queryStr;
    }
    public Database.queryLocator start(Database.BatchableContext batchContext){
        Opportunity_Stage_Days__c stageDays = Opportunity_Stage_Days__c.getInstance(UserInfo.getUserId()); 
        Set<String> stageNameSet = new Set<String>{'1 Discovery'};
        ID oppRecTypeIdSalesOpp = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        Integer maxDaysSendEmail = (Integer)stageDays.Max_Days_To_Send_Email__c - 1;
        String queryStrStart = 'SELECT Id, StageName, Days_in_Current_Stage__c, Next_Step_date_time__c, RD_Notes_Timestamp__c, peopleai__LastTouched__c, manager_note_date_time__c, CloseDate, CreatedDate, OwnerId, Owner.ManagerId ' +
                                ' FROM Opportunity ' +
                                ' WHERE RecordTypeId = :oppRecTypeIdSalesOpp AND StageName in :stageNameSet ' +
                                ' AND Days_in_Current_Stage__c >= :maxDaysSendEmail ' +
                                ' AND peopleai__LastTouched__c !=null AND peopleai__LastTouched__c != LAST_N_DAYS:' + maxDaysSendEmail +
                                ' AND Next_Step_date_time__c != LAST_N_DAYS:'+maxDaysSendEmail +
                                ' AND RD_Notes_Timestamp__c != LAST_N_DAYS:'+maxDaysSendEmail +
                                ' AND manager_note_date_time__c != LAST_N_DAYS:'+maxDaysSendEmail +
                                ' AND Opportunity_Sub_Type__c NOT IN(\'MSP Consumption Renewal\',\'MSP Overage\') ' +
                                ' AND Opportunity_Type__c NOT IN (\'Debooking\') ' + 
                                ' AND ETM_Theatre__c IN (\'AMER\',\'APAC\',\'EMEA\') ' + 
                                ' AND Opportunity_Split_Parent__c = null ' + //SAL24-155
                                ' order by Days_in_Current_Stage__c desc'; 
        queryStr = queryStr != null ? queryStr : queryStrStart;
        return Database.getQueryLocator(queryStr); 
    }
    public void execute(Database.BatchableContext batchContext, List<Opportunity> oppList){
        system.debug('oppList**'+ oppList);
        Opportunity_Stage_Days__c stageDays = Opportunity_Stage_Days__c.getInstance(UserInfo.getUserId()); 
        Date todayDate =System.Today();
        List<Opportunity> updateOppList = new List<Opportunity>();
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Id templateId = [Select id from EmailTemplate where DeveloperName = 'OpptyMovedToClosedLost_NoAEActivity'].id;
        //SAL24-155
        Map<Id, List<Opportunity>> oppToSplitOppMap = new Map<Id, List<Opportunity>>();
        for(Opportunity splitOpp :[SELECT Id,Opportunity_Split_Parent__c FROM Opportunity where Opportunity_Split_Parent__c IN :oppList and isClosed = FALSE]){
            List<Opportunity> splitOpps = new List<Opportunity>();
            if(oppToSplitOppMap.containsKey(splitOpp.Opportunity_Split_Parent__c))
                splitOpps = oppToSplitOppMap.get(splitOpp.Opportunity_Split_Parent__c);
            splitOpps.add(splitOpp);
            oppToSplitOppMap.put(splitOpp.Opportunity_Split_Parent__c, splitOpps);
        }
        //End
        for(Opportunity opp : oppList){
            
            Date lastNextStepChangeDate = opp.Next_Step_date_time__c?.date();
            Date lastRDNotesChangeDate = opp.RD_Notes_Timestamp__c?.date();
            Date lastPeopleaiTouchDate = opp.peopleai__LastTouched__c?.date();
            Date lastRSMNoteChangeDate = opp.manager_note_date_time__c?.date();
            //if(lastPeopleaiTouchDate!=null && lastNextStepChangeDate != null && lastRDNotesChangeDate != null && lastRSMNoteChangeDate != null){
            if(lastPeopleaiTouchDate!=null){
                //get the last AE activity date - most recent date from Next Step, RD Notes, RSM Notes and Peopleai lastTouch.
                //List<Date> changeDateList = new List<Date> {lastNextStepChangeDate,lastRDNotesChangeDate,lastPeopleaiTouchDate,lastRSMNoteChangeDate};
                List<Date> changeDateList = new List<Date>{lastPeopleaiTouchDate};
                if(lastNextStepChangeDate!=null) { changeDateList.add(lastNextStepChangeDate);}
                if(lastRDNotesChangeDate!=null) { changeDateList.add(lastRDNotesChangeDate); }
                if(lastRSMNoteChangeDate!=null) { changeDateList.add(lastRSMNoteChangeDate); }
                changeDateList.sort();
                Date lastAEActivityDate = changeDateList[changeDateList.size()-1];
                Integer stageAge = (Integer)opp.Days_in_Current_Stage__c;
                //Update Opp Stage to 7 Closed Lost with 'No AE Activity' as lost reason if opp is in stage 1 and no ae actiivty for N no. of days
                if(stageAge > stageDays.Max_Days_To_Move_Stg1_To_Closed_Lost__c && lastAEActivityDate.daysBetween(todayDate) > stageDays.Max_Days_To_Move_Stg1_To_Closed_Lost__c){
                    //SAL24-155
                    /*opp.StageName = '7 Closed Lost';
                    opp.Lost_Reason__c = 'No AE Activity';
                    opp.Lost_To_Won_Against__c = 'Not Sure';
                    opp.Win_Loss_Comments__c = 'Closed by automation as No AE Activity';
                    //SAL23-945
                    opp.CloseDate = System.today();
                    //opp.Actual_Close_Lost_Date__c = System.today();*/
                    updateOppList.add(setCloseLostValues(opp));

                    //SAL24-155
                    if(oppToSplitOppMap.containsKey(opp.Id)){
                        for(Opportunity splitOpp :oppToSplitOppMap.get(opp.Id)){
                            updateOppList.add(setCloseLostValues(splitOpp));
                        }
                    }
                    //End
                }
                //Send an email to Owner and Manager
                if(stageAge >= stageDays.Max_Days_To_Send_Email__c && lastAEActivityDate.daysBetween(todayDate) == stageDays.Max_Days_To_Send_Email__c){
                    mails.add(EmailHelper.getSingleEmailMessageObj(
                                /*toUserIds = */ new Set<String>{'' + opp.OwnerId, '' + opp.Owner.ManagerId}, 
                                /*ccUserIds = */ null, //new Set<String>{'' + '0056f000009zhDa'},
                                /*bccUserIds = */ null,
                                /*fromUserId = */ null, //opp.LastModifiedById, 
                                /*recordIdToMailMerge = */ opp.id, 
                                /*templateId = */ templateId
                            ));
                }
            }
        }
        if(!updateOppList.isEmpty()){
            Database.SaveResult[] sRlt = Database.update(updateOppList, false);
            LogError.createDMLErrorLog(updateOppList,sRlt,'OpportunityStage1ToClosedLostBatch','OpportunityStage1ToClosedLostBatch');
        }
        if(!stageDays.Disable_Closed_Lost_Email_Alert__c && !mails.isEmpty() && !Test.isRunningTest()){
            Messaging.SendEmailResult[] r = Messaging.sendEmail(mails);
        }
    }

    public void finish(Database.BatchableContext batchContext){
    }

    public void execute(SchedulableContext sc){
        Opportunity_Stage_Days__c stageDays = Opportunity_Stage_Days__c.getInstance(UserInfo.getUserId());
		Database.executeBatch(new OpportunityStage1ToClosedLostBatch(null), (Integer)stageDays.OpportunityStageDownGradeBatch_Size__c);
    }

    //SAL24-155
    public static Opportunity setCloseLostValues(Opportunity opp){
        opp.StageName = '7 Closed Lost';
        opp.Lost_Reason__c = 'No AE Activity';
        opp.Lost_To_Won_Against__c = 'Not Sure';
        opp.Win_Loss_Comments__c = 'Closed by automation as No AE Activity';
        //SAL23-945
        opp.CloseDate = System.today();
        return opp;
    }
    //End
}