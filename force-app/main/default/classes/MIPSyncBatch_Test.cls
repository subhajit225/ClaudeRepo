@isTest
public class MIPSyncBatch_Test {
    @testSetup static void testDataSetup(){
        Account aObj = new Account(Name='Test CDW', 
                                   RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId(),
                                   Type='Prospect',
                                   Primary_Contact_Email__c ='abc.xyz@rubrik.com');
        insert aObj;
        
        Contact cObj = new Contact(FirstName='Test MIP Contact', 
                                   LastName='Ending Name',
                                   AccountId=aObj.Id);
        insert cObj;
        
        MIP_Contract__c mipConObj = new MIP_Contract__c(Status__c ='Approved',
                                                        Start_Date__c = date.today().addDays(-50), 
                                                        End_Date__c = date.today().addDays(7),
                                                        Partner_Account__c = aObj.Id,
                                                        IsActive__c = true,
                                                        Fiscal_Period__c = 'FY25H1');
        insert mipConObj;
        
        List<MIP_Element__c> mipEleList = new List<MIP_Element__c>();
        MIP_Element__c mipEle1 = new MIP_Element__c(RecordTypeId = Schema.SObjectType.MIP_Element__c.getRecordTypeInfosByName().get('Bookings Element').getRecordTypeId(),
                                                    Element_Type__c='Total Bookings',
                                                    MIP_Contract__c = mipConObj.Id);
        mipEleList.add(mipEle1);
        MIP_Element__c mipEle2 = new MIP_Element__c(RecordTypeId = Schema.SObjectType.MIP_Element__c.getRecordTypeInfosByName().get('Bookings Element').getRecordTypeId(),
                                                    Element_Type__c='PSNL Bookings',
                                                    MIP_Contract__c = mipConObj.Id);
        mipEleList.add(mipEle2);

        MIP_Element__c mipEle3 = new MIP_Element__c(RecordTypeId = Schema.SObjectType.MIP_Element__c.getRecordTypeInfosByName().get('Rebate Milestone').getRecordTypeId(),
                                                    Element_Type__c='Rebate Milestone',
                                                    MIP_Contract__c = mipConObj.Id);
        mipEleList.add(mipEle3);
        MIP_Element__c mipEle4 = new MIP_Element__c(RecordTypeId = Schema.SObjectType.MIP_Element__c.getRecordTypeInfosByName().get('Enrollment').getRecordTypeId(),
                                                    Element_Type__c='Enrollment',Enrollment_Payout_Rate__c=5,Max_Enrollment_Payout__c=10000,
                                                    MIP_Contract__c = mipConObj.Id);
        mipEleList.add(mipEle4);
        insert mipEleList;
        
        
        TriggerControl__c setting = new TriggerControl__c();
        setting.Name = 'Opportunity';
        setting.DisableTrigger__c = False;
        insert setting;
        
        Opportunity opp = new Opportunity(StageName='7 Closed Won',
                                          Name='Test MIP Opty',
                                          Cloud_Type__c ='Microsoft Azure',
                                          Partner_Lookup__c= aObj.Id,
                                          Amount= 1000,
                                          ACV_Amount__c = 1000,
                                          Deal_Registration_Type__c='Partner Sourced New Logo (PSNL)',
                                          CloseDate = date.today(),
                                          ContactId = cObj.Id,
                                          Initial_Contacts_Name__c = cObj.Id,
                                          Opportunity_Type__c ='Debooking',
                                          Opportunity_Sub_Type__c ='MSP Coverage');
        insert opp;
        
        List<MIP_Account_Contribution__c> mipAccConList = new List<MIP_Account_Contribution__c>();
        MIP_Account_Contribution__c mipAc1 = new MIP_Account_Contribution__c(Partner_Account__c = aObj.Id,
                                                                             MIP_Contract__c = mipConObj.Id,
                                                                             PSNL_Bookings__c = 1000);
        insert mipAc1;
    }
    static testMethod void MIPSyncBatchtest(){
        MIP_Contract__c mipCon =[SELECT Id from MIP_Contract__c LIMIT 1];
        test.startTest();
        MIPContractRecalculateController.initiateMIPSyncBatch(mipCon.Id);
        test.stopTest();
    }

    static testMethod void MIPElementHelpertest(){
        MIP_Contract__c mipCon =[SELECT Id,Max_Rebate_Payout__c from MIP_Contract__c LIMIT 1];
        List<MIP_ELement__c> allMIPEle = [SELECT ID,Name,Milestone_Percent__c,Payout_Type__c,RecordTypeId,Prior_Year_Bookings_TCV__c,Tier_1_Bookings_Expected_Growth__c,Tier_2_Bookings_Expected_Growth__c,Baseline_Bookings_Expected_Growth__c,Contract_Period_Bookings__c,Tier_3_Bookings_Expected_Growth__c,Bookings_Percent__c
                                            FROM MIP_ELement__c
                                            WHERE MIP_Contract__c =: mipCon.ID];
        test.startTest();
        mipCon.Max_Rebate_Payout__c = 200000;
        update mipCon;
        for(MIP_ELement__c ele : allMIPEle){
            if(ele.RecordTypeId == Schema.SObjectType.MIP_Element__c.getRecordTypeInfosByName().get('Rebate Milestone').getRecordTypeId()){
                ele.Milestone_Percent__c = 10;
                ele.Payout_Type__c = 'All or Nothing';
            }
            if(ele.RecordTypeId == Schema.SObjectType.MIP_Element__c.getRecordTypeInfosByName().get('Bookings Element').getRecordTypeId()){
                ele.Bookings_Percent__c = 40;
                ele.Prior_Year_Bookings_TCV__c = 100000;
                ele.Baseline_Bookings_Expected_Growth__c = 10.00;
                ele.Tier_1_Bookings_Expected_Growth__c = 20.00;
                ele.Tier_2_Bookings_Expected_Growth__c = 25.00;
                ele.Tier_3_Bookings_Expected_Growth__c = 30.00;
                ele.Tier_1_Bookings_Rebate_Distribution__c = 5.00; 
                ele.Tier_2_Bookings_Rebate_Distribution__c = 10.00;
                ele.Tier_3_Bookings_Rebate_Distribution__c = 15.00;
                ele.Contract_Period_Bookings__c = 30000;
            }
        }
        update allMIPEle;

        for(MIP_ELement__c ele : allMIPEle){
            if(ele.RecordTypeId == Schema.SObjectType.MIP_Element__c.getRecordTypeInfosByName().get('Bookings Element').getRecordTypeId()){
                ele.Prior_Year_Bookings_TCV__c = 10000;
                ele.Tier_2_Bookings_Expected_Growth__c = 10;
                ele.Tier_1_Bookings_Rebate_Distribution__c = 10;
                ele.Baseline_Bookings_Rebate_Distribution__c = 10;
                ele.Tier_1_Bookings_Rebate_Distribution__c = 5.00; 
                ele.Tier_2_Bookings_Rebate_Distribution__c = 10.00;
                ele.Tier_3_Bookings_Rebate_Distribution__c = 15.00;
                ele.Contract_Period_Bookings__c = 40000;
            }
        }
        update allMIPEle;
        MIPElementTriggerUtility utilObj = new MIPElementTriggerUtility();
        test.stopTest();
    }
}