@isTest
public class MIPFetchFormReviewDetails_Test {

    @testSetup 
    static void testDataSetup(){
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
                                                        Start_Date__c = System.today().addDays(-180), 
                                                        End_Date__c = System.today(),
                                                        Partner_Account__c = aObj.Id);
        insert mipConObj;
        
        List<MIP_Element__c> mipEleList = new List<MIP_Element__c>();
        MIP_Element__c mipEle1 = new MIP_Element__c(RecordTypeId = Schema.SObjectType.MIP_Element__c.getRecordTypeInfosByName().get('Funded Head').getRecordTypeId(),
                                                    Element_Type__c='Funded Head', Payout_Type__c='All or Nothing',Head_Count__c=3,Roles__c='Sales',
                                                    Max_Funded_Head_Payout__c=10000, MIP_Contract__c = mipConObj.Id);
        mipEleList.add(mipEle1);
        MIP_Element__c mipEle2 = new MIP_Element__c(RecordTypeId = Schema.SObjectType.MIP_Element__c.getRecordTypeInfosByName().get('Rebate Milestone').getRecordTypeId(),
                                                    Element_Type__c='Rebate Milestone', Payout_Type__c='All or Nothing',Rebate_Type__c ='Concierge',MIP_Contract__c = mipConObj.Id);
        mipEleList.add(mipEle2);
        MIP_Element__c mipEle3 = new MIP_Element__c(RecordTypeId = Schema.SObjectType.MIP_Element__c.getRecordTypeInfosByName().get('Bookings Element').getRecordTypeId(),
                                                    Element_Type__c='PSNL Bookings',Rebate_Type__c ='Concierge',Prior_Year_Bookings_ACV__c=10000,Baseline_Bookings_Expected_Growth__c=5,
                                                    Tier_1_Bookings_Expected_Growth__c=5, Tier_2_Bookings_Expected_Growth__c=5, Tier_3_Bookings_Expected_Growth__c=5,
                                                    MIP_Contract__c = mipConObj.Id);
        mipEleList.add(mipEle3);
        MIP_Element__c mipEle4 = new MIP_Element__c(RecordTypeId = Schema.SObjectType.MIP_Element__c.getRecordTypeInfosByName().get('Bookings Element').getRecordTypeId(),
                                                    Element_Type__c='Total Bookings',Rebate_Type__c ='Concierge',Prior_Year_Bookings_ACV__c=10000,Baseline_Bookings_Expected_Growth__c=5,
                                                    Tier_1_Bookings_Expected_Growth__c=5, Tier_2_Bookings_Expected_Growth__c=5, Tier_3_Bookings_Expected_Growth__c=5,
                                                    MIP_Contract__c = mipConObj.Id);
        mipEleList.add(mipEle4);
        insert mipEleList;

        MIP_Element__c mipEle5 = new MIP_Element__c(RecordTypeId = Schema.SObjectType.MIP_Element__c.getRecordTypeInfosByName().get('Enrollment').getRecordTypeId(),
                                                    Element_Type__c='Enrollment',Max_Enrollment_Payout__c=6000.56,Enrollment_Payout_Rate__c=2.5,
                                                    MIP_Contract__c = mipConObj.Id);
        mipEleList.add(mipEle5);

        MIP_Milestone__c mipMile = new MIP_Milestone__C(Milestone_Type__c='Assessment',Quantity__c=3,Role__c='Market',Status__c='Completed',Target_Completion_Date__c=System.today().addDays(3),MIP_Element__c=mipEle1.Id);
        insert mipMile;
    }

    @isTest
    static void getMIPFormReviewDetails(){
        MIP_Contract__c mipCon =[SELECT Id from MIP_Contract__c LIMIT 1];
        MIPFetchFormReviewDetails.getFHRecs(mipCon.Id);
        MIPFetchFormReviewDetails.getRMRecs(mipCon.Id);
        MIPFetchFormReviewDetails.getPSNLRecs(mipCon.Id);
        MIPFetchFormReviewDetails.getTotalRecs(mipCon.Id);
        MIPFetchFormReviewDetails.getEnrollRecs(mipCon.Id);
        MIPFetchFormReviewDetails.getMilestoneRecs(mipCon.Id, System.now());
    }
    
}