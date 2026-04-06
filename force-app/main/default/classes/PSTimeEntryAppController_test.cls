@isTest
public class PSTimeEntryAppController_test {
    @testSetup static void setup() { 
        insert new ShGl_DisableBusinessLogic__c(SetupOwnerId = UserInfo.getOrganizationId(), Disable_Account_Triggers__c = TRUE, Disable_Opportunity_Triggers__c = TRUE, Disable_PS_Task_Triggers__c = true);
        List<TriggerControl__c> TriggerCon              =  CustomTestDataFactory.TriggerControlSetting(true);
        List<Account> Accountid                         =  CustomTestDataFactory.createAccounts(1); 
        list<Contact> conId                             =  CustomTestDataFactory.createcont(Accountid);
        List<Opportunity> OppoId                        =  createOpp(Accountid,conId);
        List<PS_Project__c> ProjectId                   =  CustomTestDataFactory.createPS_Projectwithopp(OppoId,conId,Accountid);
        List<PS_Task__c> PStaskId                       =  CustomTestDataFactory.createPstaskConsult1(ProjectId,true);
        list<PS_Time_Card__c> TimeCard                  =  CustomTestDataFactory.CreatTimecard1(ProjectId);
        List<PS_Time_Entry__c> PSTimeEntry              =  CustomTestDataFactory.createPSTimeEntryConsult2(PStaskId,TimeCard);
     
        system.debug('PStaskId============='+PStaskId);
        system.debug('TimeCard============'+TimeCard);
        system.debug('PSTimeEntry========='+PSTimeEntry);

        List<PS_Task__c> tasklst =  new List<PS_Task__c>();
            PS_Task__c pt = new PS_Task__c();
            pt.Task_Start_Date__c =  system.today().AddDays(-1);
            pt.Task_Status__c = 'Open';
            pt.Task_Type__c = 'Non-Billable Admin';
            pt.Consult_Quantity__c = 1;
            pt.Project__c = ProjectId[0].Id;
            pt.Account__c = Accountid[0].id;
            pt.Billable_Hours_Expected__c = 40;
            tasklst.add(pt);
        insert tasklst;

        List<PS_Time_Card__c> PsTimeInsert = new List<PS_Time_Card__c>();
            PS_Time_Card__c PST = new PS_Time_Card__c();
            PST.Name = 'TEST';
            PST.Approver__c = userinfo.getuserid();
            PST.PS_Project__c = ProjectId[0].id;
            PST.Time_Card_Start_Date__c = system.today();
            PST.Time_Card_End_Date__c   = system.today();
            PST.Status__c ='Draft';
            PST.Assignee__c = userinfo.getuserid();
            PsTimeInsert.add(PST);
        insert PsTimeInsert;

        list<PS_Time_Entry__c> psoList = new list<PS_Time_Entry__c>();
        Date tmeEntryDate = Date.today().addDays(7).toStartOfWeek();
        Date tmeEntryDate1 = Date.today().addDays(7);
        PS_Time_Entry__c psot1 = new PS_Time_Entry__c(Hours_Spent__c=1,Time_Entry_Date__c=tmeEntryDate,PS_Task__c=pt.id,PS_Time_Card__c = PST.id,Assignee__c =userinfo.getUserId(),Comments__c='hii',Status__c ='Draft');
        PS_Time_Entry__c psot2 = new PS_Time_Entry__c(Hours_Spent__c=1,Time_Entry_Date__c=tmeEntryDate1,PS_Task__c=pt.id,PS_Time_Card__c = PST.id,Assignee__c =userinfo.getUserId(),Comments__c='hii',Status__c ='Draft');
        psoList.add(psot1);
        psoList.add(psot2);
        insert psoList;
    }
    
    public static testmethod void Test(){
        string timecard;
        date weekStart;
        date weekEnd;
        date cmpStartDate = system.today();
        string weekType = 'Next Week';
        string weekType1 = 'Previous Week';
        boolean onload = true;
        string saveList;
        string buttonClicked;
        buttonClicked = 'SaveSubmit';
        list<PS_Time_Entry__c> psTimeEntryList = [SELECT Id,Time_Entry_Date__c,PS_Task__c,Assignee__c,Hours_Spent__c,Comments__c,Status__c,PS_Time_Card__c FROM PS_Time_Entry__c];

        list<PS_Time_Card__c> TimeCardIdList = [select id from PS_Time_Card__c];
        list<PS_Project__C>   pro            = [select id,Name,Account__C,Project_Manager__c, 
                                                Account__r.Name,Project_Status__c,Total_Billable_Hours_Remaining__c,Consult_Hours_Billed__c,Install_Hours_Billed__c,
                                                Opportunity__c,Opportunity__r.Name,Total_Billable_Hours_Expected__c,Actual_Billable_hours_logged__c 
                                                FROM PS_Project__C]; 
        timecard = TimeCardIdList[0].id;
        list<id> listOfProjId = new list<id>();
        listOfProjId.add(pro[0].id);
        
       saveList = '[{"project":{"Id":"aB3P000000003ejKAA","Name":"Rizvan Demo Account - Rizvan Test Opportunity(1)","Account__c":"001P000001gHOMOIA4","Project_Manager__c":"0051W000004R2ecQAC","Project_Status__c":"Open","Total_Billable_Hours_Remaining__c":310,"Consult_Hours_Billed__c":75,"Install_Hours_Billed__c":79,"Opportunity__c":"006P000000BKbV0IAL","Total_Billable_Hours_Expected__c":464,"Actual_Billable_hours_logged__c":154,"Account__r":{"Name":"Rizvan Demo Account","Id":"001P000001gHOMOIA4"},"Opportunity__r":{"Name":"Rizvan Test Opportunity","Id":"006P000000BKbV0IAL"}},"selected":true,"taskWrapperList":[{"comment":"test","hrsExclCurrWeek":0,"taskRec":{"Id":"aB5P00000008SLCKA2","Name":"PST-0001223","Billable_Hours_Expected__c":96,"Billable_Hours_Actual__c":79,"Billable_Hours_Approved__c":0,"Task_Type__c":"Install","Project__c":"aB3P000000003ejKAA","PS_Time_Entries__r":[{"PS_Task__c":"aB5P00000008SLCKA2","Id":"aB6P00000008bVxKAI","Hours_Spent__c":1,"Time_Entry_Date__c":"2020-08-23","Assignee__c":"005P00000057HYSIA2","Status__c":"Recalled","Read_Only__c":false,"Comments__c":"test"},{"PS_Task__c":"aB5P00000008SLCKA2","Id":"aB6P00000008bXeKAI","Hours_Spent__c":1,"Time_Entry_Date__c":"2020-08-24","Assignee__c":"005P00000057HYSIA2","Status__c":"Recalled","Read_Only__c":false,"Comments__c":"test"},{"PS_Task__c":"aB5P00000008SLCKA2","Id":"aB6P00000008bXoKAI","Hours_Spent__c":1,"Time_Entry_Date__c":"2020-08-25","Assignee__c":"005P00000057HYSIA2","Status__c":"Recalled","Read_Only__c":false,"Comments__c":"test"},{"PS_Task__c":"aB5P00000008SLCKA2","Id":"aB6P00000008bXtKAI","Hours_Spent__c":1,"Time_Entry_Date__c":"2020-08-26","Assignee__c":"005P00000057HYSIA2","Status__c":"Recalled","Read_Only__c":false,"Comments__c":"test"}]},"timeEntryList":[{"PS_Task__c":"aB5P00000008SLCKA2","Id":"aB6P00000008bVxKAI","Hours_Spent__c":1,"Time_Entry_Date__c":"2020-08-23","Assignee__c":"005P00000057HYSIA2","Status__c":"Recalled","Read_Only__c":false,"Comments__c":"test"},{"PS_Task__c":"aB5P00000008SLCKA2","Id":"aB6P00000008bXeKAI","Hours_Spent__c":1,"Time_Entry_Date__c":"2020-08-24","Assignee__c":"005P00000057HYSIA2","Status__c":"Recalled","Read_Only__c":false,"Comments__c":"test"},{"PS_Task__c":"aB5P00000008SLCKA2","Id":"aB6P00000008bXoKAI","Hours_Spent__c":1,"Time_Entry_Date__c":"2020-08-25","Assignee__c":"005P00000057HYSIA2","Status__c":"Recalled","Read_Only__c":false,"Comments__c":"test"},{"PS_Task__c":"aB5P00000008SLCKA2","Id":"aB6P00000008bXtKAI","Hours_Spent__c":"1","Time_Entry_Date__c":"2020-08-26","Assignee__c":"005P00000057HYSIA2","Status__c":"Recalled","Read_Only__c":false,"Comments__c":"test"},{"Time_Entry_Date__c":"2020-08-27","PS_Task__c":"aB5P00000008SLCKA2","Assignee__c":"005P00000057HYSIA2","Hours_Spent__c":"1"},{"Time_Entry_Date__c":"2020-08-28","PS_Task__c":"aB5P00000008SLCKA2","Assignee__c":"005P00000057HYSIA2","Hours_Spent__c":""},{"Time_Entry_Date__c":"2020-08-29","PS_Task__c":"aB5P00000008SLCKA2","Assignee__c":"005P00000057HYSIA2"}],"TotHours":"5"},{"comment":"","hrsExclCurrWeek":0,"taskRec":{"Id":"aB5P00000008SLDKA2","Name":"PST-0001224","Billable_Hours_Expected__c":96,"Billable_Hours_Actual__c":0,"Billable_Hours_Approved__c":0,"Task_Type__c":"Install - Non Billable","Project__c":"aB3P000000003ejKAA"},"timeEntryList":[{"Time_Entry_Date__c":"2020-08-23","PS_Task__c":"aB5P00000008SLDKA2","Assignee__c":"005P00000057HYSIA2"},{"Time_Entry_Date__c":"2020-08-24","PS_Task__c":"aB5P00000008SLDKA2","Assignee__c":"005P00000057HYSIA2"},{"Time_Entry_Date__c":"2020-08-25","PS_Task__c":"aB5P00000008SLDKA2","Assignee__c":"005P00000057HYSIA2"},{"Time_Entry_Date__c":"2020-08-26","PS_Task__c":"aB5P00000008SLDKA2","Assignee__c":"005P00000057HYSIA2","Hours_Spent__c":""},{"Time_Entry_Date__c":"2020-08-27","PS_Task__c":"aB5P00000008SLDKA2","Assignee__c":"005P00000057HYSIA2","Hours_Spent__c":""},{"Time_Entry_Date__c":"2020-08-28","PS_Task__c":"aB5P00000008SLDKA2","Assignee__c":"005P00000057HYSIA2"},{"Time_Entry_Date__c":"2020-08-29","PS_Task__c":"aB5P00000008SLDKA2","Assignee__c":"005P00000057HYSIA2"}],"TotHours":0},{"comment":"test","hrsExclCurrWeek":0,"taskRec":{"Id":"aB5P00000008SLEKA2","Name":"PST-0001225","Billable_Hours_Expected__c":96,"Billable_Hours_Actual__c":0,"Billable_Hours_Approved__c":0,"Task_Type__c":"Consult - Non Billable","Project__c":"aB3P000000003ejKAA","PS_Time_Entries__r":[{"PS_Task__c":"aB5P00000008SLEKA2","Id":"aB6P00000008bTcKAI","Hours_Spent__c":45,"Time_Entry_Date__c":"2020-08-24","Assignee__c":"005P00000057HYSIA2","Status__c":"Recalled","Read_Only__c":false,"Comments__c":"test"},{"PS_Task__c":"aB5P00000008SLEKA2","Id":"aB6P00000008bU6KAI","Hours_Spent__c":6,"Time_Entry_Date__c":"2020-08-25","Assignee__c":"005P00000057HYSIA2","Status__c":"Recalled","Read_Only__c":false,"Comments__c":"test"},{"PS_Task__c":"aB5P00000008SLEKA2","Id":"aB6P00000008bU1KAI","Hours_Spent__c":1,"Time_Entry_Date__c":"2020-08-27","Assignee__c":"005P00000057HYSIA2","Status__c":"Recalled","Read_Only__c":false,"Comments__c":"test"}]},"timeEntryList":[{"Time_Entry_Date__c":"2020-08-23","PS_Task__c":"aB5P00000008SLEKA2","Assignee__c":"005P00000057HYSIA2"},{"PS_Task__c":"aB5P00000008SLEKA2","Id":"aB6P00000008bTcKAI","Hours_Spent__c":45,"Time_Entry_Date__c":"2020-08-24","Assignee__c":"005P00000057HYSIA2","Status__c":"Recalled","Read_Only__c":false,"Comments__c":"test"},{"PS_Task__c":"aB5P00000008SLEKA2","Id":"aB6P00000008bU6KAI","Hours_Spent__c":6,"Time_Entry_Date__c":"2020-08-25","Assignee__c":"005P00000057HYSIA2","Status__c":"Recalled","Read_Only__c":false,"Comments__c":"test"},{"Time_Entry_Date__c":"2020-08-26","PS_Task__c":"aB5P00000008SLEKA2","Assignee__c":"005P00000057HYSIA2","Hours_Spent__c":""},{"PS_Task__c":"aB5P00000008SLEKA2","Id":"aB6P00000008bU1KAI","Hours_Spent__c":1,"Time_Entry_Date__c":"2020-08-27","Assignee__c":"005P00000057HYSIA2","Status__c":"Recalled","Read_Only__c":false,"Comments__c":"test"},{"Time_Entry_Date__c":"2020-08-28","PS_Task__c":"aB5P00000008SLEKA2","Assignee__c":"005P00000057HYSIA2"},{"Time_Entry_Date__c":"2020-08-29","PS_Task__c":"aB5P00000008SLEKA2","Assignee__c":"005P00000057HYSIA2"}],"TotHours":"52"},{"comment":"test test test","hrsExclCurrWeek":0,"taskRec":{"Id":"aB5P00000008SEWKA2","Name":"PST-0001187","Billable_Hours_Expected__c":80,"Billable_Hours_Actual__c":75,"Billable_Hours_Approved__c":64,"Task_Type__c":"Consult","Project__c":"aB3P000000003ejKAA","PS_Time_Entries__r":[{"PS_Task__c":"aB5P00000008SEWKA2","Id":"aB6P00000008bJmKAI","Hours_Spent__c":1,"Time_Entry_Date__c":"2020-08-24","Assignee__c":"005P00000057HYSIA2","Status__c":"Recalled","Read_Only__c":false,"Comments__c":"test test test"}]},"timeEntryList":[{"Time_Entry_Date__c":"2020-08-23","PS_Task__c":"aB5P00000008SEWKA2","Assignee__c":"005P00000057HYSIA2"},{"PS_Task__c":"aB5P00000008SEWKA2","Id":"aB6P00000008bJmKAI","Hours_Spent__c":1,"Time_Entry_Date__c":"2020-08-24","Assignee__c":"005P00000057HYSIA2","Status__c":"Recalled","Read_Only__c":false,"Comments__c":"test test test"},{"Time_Entry_Date__c":"2020-08-25","PS_Task__c":"aB5P00000008SEWKA2","Assignee__c":"005P00000057HYSIA2"},{"Time_Entry_Date__c":"2020-08-26","PS_Task__c":"aB5P00000008SEWKA2","Assignee__c":"005P00000057HYSIA2","Hours_Spent__c":""},{"Time_Entry_Date__c":"2020-08-27","PS_Task__c":"aB5P00000008SEWKA2","Assignee__c":"005P00000057HYSIA2"},{"Time_Entry_Date__c":"2020-08-28","PS_Task__c":"aB5P00000008SEWKA2","Assignee__c":"005P00000057HYSIA2"},{"Time_Entry_Date__c":"2020-08-29","PS_Task__c":"aB5P00000008SEWKA2","Assignee__c":"005P00000057HYSIA2"}],"TotHours":"1"}]}]';
        
        PSTimeEntryAppController.GetTimeCards(); 
        PSTimeEntryAppController.GetTimeCard();
        PSTimeEntryAppController.UnlockRecordMethod(timecard);
        PSTimeEntryAppController.UnlockRecordMethod('');
        PSTimeEntryAppController.getUserName();
        PSTimeEntryAppController.getProject(cmpStartDate,weekType);
        PSTimeEntryAppController.getProjList(listOfProjId,cmpStartDate,weekType,onload);
        PSTimeEntryAppController.getProjList(listOfProjId,cmpStartDate,weekType1,onload);
        PSTimeEntryAppController.savePSEntries(saveList,buttonClicked);
        PSTimeEntryAppController.workedProjects(weekStart,weekEnd);
        PSTimeEntryAppController.workedTasks(weekStart,weekEnd);
        PSTimeEntryAppController.saveDirectPSEntries(psTimeEntryList);
    }
    
    @isTest
    static void testSaveDirectPSEntries(){
        List<PS_Time_Entry__c> psTimeEntryList = [SELECT Id,Time_Entry_Date__c,PS_Task__c,Assignee__c,Hours_Spent__c,Comments__c,Status__c,PS_Time_Card__c FROM PS_Time_Entry__c];
        List<PS_Time_Entry__c> psTimeEntryList1 = new List<PS_Time_Entry__c>();
    	PS_Time_Entry__c psot2 = new PS_Time_Entry__c(Hours_Spent__c=2,Time_Entry_Date__c=psTimeEntryList[0].Time_Entry_Date__c,PS_Task__c=psTimeEntryList[0].PS_Task__c,PS_Time_Card__c = psTimeEntryList[0].PS_Time_Card__c,Assignee__c =userinfo.getUserId(),Comments__c='hola',Status__c ='test');
        psTimeEntryList1.add(psot2);
        
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        Test.startTest();
        System.runAs(thisUser) {
            PSTimeEntryAppController.saveDirectPSEntries(psTimeEntryList1);
        }
        System.assertEquals(psTimeEntryList1.isEmpty(), false);
        Test.stopTest();
    }
    
    public static List<Opportunity> createOpp(List<Account> actlst, List<Contact> conlst){
        List<Opportunity> opplst = new List<Opportunity>();
        for (Integer j=0;j<actlst.size();j++) {
            Opportunity opp = new Opportunity();
            opp.Name = 'testopp';
            opp.StageName = '1 Discovery';
            opp.AccountId = actlst[0].id;
            opp.Opportunity_Type__c = 'New Customer';
            opp.Opportunity_Sub_Type__c = 'Regular';
            opp.CloseDate = system.today();
            opp.Business_Unit__c = 'Mosaic';
            //opp.ForecastCategory = 'Upside';
            opp.ContactId = conlst[0].id;
            opp.Deal_Registration_Type__c = 'Rubrik Sourced';
            opplst.add(opp);
        }
        insert opplst;
        return opplst;
    }
}