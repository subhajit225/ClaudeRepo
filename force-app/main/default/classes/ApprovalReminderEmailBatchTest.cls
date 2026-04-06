/**************************************************************************************************************
Class Name			:  ApprovalReminderEmailBatchTest
Author				:  Rahul Kappa
Purpose				:  Test Class for ApprovalReminderEmailBatch class
Date Created		:  18/11/2024
/**************************************************************************************************************/
@isTest
public class ApprovalReminderEmailBatchTest {

/**************************************************************************************************************
Method Name			:  Test Data Setup
Author				:  Rahul Kappa
Purpose				:  Prepares Test Data for the Test Methods
Date Created		:  18/11/2024
/**************************************************************************************************************/    
    @TestSetUp
    static void initialDataSetup() {
        // Create the TriggerControl__c record
       TriggerControl__c triggerControl = new TriggerControl__c(
            Name = 'Approval',
            DisableTrigger__c = false
        );
        insert triggerControl;
        
        // Create profiles, users, groups, and other necessary data for testing
        List<Profile> listProfile = [Select Id
                                     From Profile
                                     Where Name = 'Rubrik Inside Sales'
                                     OR Name = 'System Administrator'
                                     Order By Name];
        
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 3);
        
        listUser.addAll(TestDataFactory.getUsers('testClassUserAdmin', new Set<Id>{listProfile[1].Id}, 1));
        insert listUser;
        
        List<Group> listGroup = TestDataFactory.getGroups('Test Group', 2);
        
        System.runAs(listUser[3]){
            insert listGroup;
            
            List<GroupMember> listGroupMember = TestDataFactory.getGroupMembers(listGroup[0].Id, new Set<Id>{listUser[1].Id, listUser[2].Id});
            listGroupMember.addAll(TestDataFactory.getGroupMembers(listGroup[1].Id, new Set<Id>{listUser[2].Id}));
            
            GroupMember gpm = new GroupMember();
            gpm.GroupId = listGroup[1].Id;
            gpm.UserOrGroupId = listGroup[0].Id;
            listGroupMember.add(gpm);
            
            insert listGroupMember;
        }
        	
        Opportunity objOpportunity = TestDataFactory.getOpportunity();
        insert objOpportunity;
        
        List<SBQQ__Quote__c> listQuote = TestDataFactory.getQuotes(new Set<Id>{objOpportunity.Id}, 1);
        listQuote[0].SBQQ__Status__c = 'In Review';
        insert listQuote;
        
        List<sbaa__Approver__c> listApprover = TestDataFactory.getApprovers(
            new Set<Id> {
                listUser[0].Id,
                    listUser[1].Id
                    },
            new Set<Id> {
                listGroup[0].Id,
                    listGroup[1].Id
                    }
        );
        
        insert listApprover;
        List<sbaa__Approver__c> lstApp = [SELECT Id, sbaa__GroupId__c, sbaa__DelegatedApprover__c, sbaa__DelegationEnd__c, sbaa__DelegationStart__c FROM sbaa__Approver__c LIMIT 2];
        
        if(!lstApp.isEmpty()){
            sbaa__Approver__c  userApp = new sbaa__Approver__c();
            sbaa__Approver__c grpApp = new sbaa__Approver__c();
            
            for(sbaa__Approver__c sb: lstApp){
                if(sb.sbaa__GroupId__c != NULL){
                    grpApp = sb; 
                }else{
                    userApp = sb;
                    userApp.sbaa__DelegatedApprover__c = listApprover[0].Id;
                    userApp.sbaa__DelegationStart__c = system.today();
                    userApp.sbaa__DelegationEnd__c = system.today();
                }
            }
        
        List<sbaa__Approval__c> listApproval = new List<sbaa__Approval__c> {
            new sbaa__Approval__c(
                Quote__c = listQuote[0].Id,
                sbaa__Opportunity__c = objOpportunity.Id,
                sbaa__Status__c = 'Assigned',
                sbaa__Approver__c = userApp.Id,
                sbaa__AssignedTo__c = listUser[0].Id,
                sbaa__RecordField__c = 'Quote__c',
                sbaa__ApprovalStep__c = 1
            ),
            new sbaa__Approval__c(
                Quote__c = listQuote[0].Id,
                sbaa__Opportunity__c = objOpportunity.Id,
                sbaa__Status__c = 'Assigned',
                sbaa__Approver__c = grpApp.Id,
                sbaa__AssignedGroupId__c = listGroup[1].Id,
                sbaa__RecordField__c = 'Quote__c',
                sbaa__ApprovalStep__c = 1
            ),
            new sbaa__Approval__c(
                Quote__c = listQuote[0].Id,
                sbaa__Opportunity__c = objOpportunity.Id,
                sbaa__Status__c = 'Assigned',
                sbaa__Approver__c = userApp.Id,
                sbaa__AssignedTo__c = listUser[0].Id,
                sbaa__RecordField__c = 'Quote__c',
                sbaa__ApprovalStep__c = 1
            )
                };
                    insert listApproval;  
          }
        
        List<sbaa__Approval__c> lstAppUp = [SELECT Id,Name, sbaa__Status__c FROM sbaa__Approval__c WHERE sbaa__Status__c = 'Assigned' LIMIT 3];
            List<sbaa__Approval__c> lstUp = new List<sbaa__Approval__c>();
            if(!lstAppUp.isEmpty()){
                for(sbaa__Approval__c sbb: lstAppUp){
                    sbb.sbaa__Status__c = 'Requested';
                    system.debug(sbb.Name);
                    lstUp.add(sbb);
                }
                update lstUp;
            }
     }

/**************************************************************************************************************
Method Name			:  userToapprovalTest
Author				:  Rahul Kappa
Purpose				:  Launch Batch class for code check
Date Created		:  18/11/2024
/**************************************************************************************************************/ 
    
    public static testMethod void userToapprovalTest() {         
        Test.startTest();
        ApprovalReminderEmailBatch batch = new ApprovalReminderEmailBatch();
        Database.executeBatch(batch,50);
        Test.stopTest();
    } 
}