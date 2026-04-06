/** 
* @Author      : Raveesh Layal
* @CreatedDate : 18th July 2023
* @Description : Add Cluster Id and Additional Cluster ID information to JIRA.
* @Jira		: CS21-1820
* @Apex Classes: AssistRequestTrigger.apxt, UpdateJiraIssueWatchers.apxc, AddAssistReqOwnersToJira.apxc
* -------------------------- @History --------------------------------------------------------------------------------------------
* Story Number       Modified By              Date           Description
*  		           
* --------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class AssistRequestTriggerTest {
    @isTest 
    public static void method1()
    {
        // Query to profile data
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        // creating a temporary user 
        list<user> tempUser= new list<user>();
        for(integer i=0;i<10;i++)
        {
            User newUser = new User();
            
            // Set the required fields for the new user
            newUser.FirstName = 'Testing'+i;
            newUser.LastName = 'Testing'+i;
            newUser.Email = 'test_Rubrik'+i+'@example.com';
            newUser.Username = 'test_Rubrik'+i+'samar@example.com';
            newUser.Alias = 'JD'+i;
            newUser.CommunityNickname = 'test_Rubrik'+i;
            // profile id --------------------------------------------
            newUser.ProfileId =profileId.id; 
            newUser.TimeZoneSidKey = 'America/Los_Angeles';
            newUser.LocaleSidKey = 'en_US';
            newUser.EmailEncodingKey = 'UTF-8';
            newUser.LanguageLocaleKey = 'en_US';
            tempUser.add(newUser); 
        }
        if(tempUser.size()>0){
            insert tempuser;  
        }        
        // creating a account to use for creating case data
        list<account> acclist=new list<account>();
        for(Integer i=0;i<10;i++)
        {
            account acc=new Account();
            acc.name='kashif'+i;
            acc.BillingCountry = 'United States';
            acclist.add(acc);
        }
        insert acclist;
        
        // creating case data 
        list<case> casedata=new list<case>();
        for(integer i=0;i<10;i++)
        {
            case caseUser=new case();
            caseUser.AccountId=acclist[i].id;
            caseUser.OwnerId=UserInfo.getUserId();
            caseUser.Priority='P1-Critical';
            caseUser.Origin='Email';
            caseUser.Status='New';
            caseUser.Platform__c='Duplicate';
            caseUser.Subject='Testing';
            caseUser.Description='This for testing purpose';
            casedata.add(caseUser);
        }
        insert casedata;
        // creating Assist request data 
        list<Assist_Request__c > arList=new list<Assist_Request__c >();
        for(Integer i=0;i<10;i++)
        {
            Assist_Request__c ar=new Assist_Request__c();
            //ar.OwnerId=UserInfo.getUserId();
            ar.status__c = 'open';
            ar.Type__c = 'Need Assistance on Next Steps/Troubleshooting';
            if(i>7){
                ar.Case__c=casedata[0].id;   
                ar.account__c = acclist[0].id;
                ar.ownerId=tempuser[0].id;
                ar.JIRA_Reference__c='<a href="https://rubrik.atlassian.net/browse/CDM-198563" target="_blank">CDM-19856'+i+'</a>';
            }
            else if(i==1){
                ar.Case__c=casedata[i].id;
                ar.ownerId=tempuser[1].id;
                ar.account__c = acclist[i].id;
                ar.JIRA_Reference__c='<a href="https://rubrik.atlassian.net/browse/CDM-198563" target="_blank">CDM-19856'+i+'</a>,<a href="https://rubrik.atlassian.net/browse/CDM-198749" target="_blank">CDM-198749</a>';
            }  
            else{
                ar.Case__c=casedata[i].id; 
                ar.account__c = acclist[i].id;
                ar.ownerId=tempuser[i].id;
                ar.JIRA_Reference__c='<a href="https://rubrik.atlassian.net/browse/CDM-198563" target="_blank">CDM-19856'+i+'</a>,<a href="https://rubrik.atlassian.net/browse/CDM-198749" target="_blank">CDM-198749</a>';
            }
            arList.add(ar);
        }
        insert arList;
        Test.startTest();
        AddAssistReqOwnersToJira obj= new AddAssistReqOwnersToJira('select id,JIRA_Reference__c,owner.email from Assist_request__c LIMIT 1');
        Id batchprocessid= DataBase.executeBatch(obj);
        List<AsyncApexJob> aaj = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors 
                            FROM AsyncApexJob WHERE ID =: batchprocessid ];
        System.assertEquals(true, aaj.size()>0);
        
        Assist_Request__c arc=new Assist_Request__c();
        arc.id=arList[0].id; 
        arc.OwnerId=tempuser[0].id;
        arc.JIRA_Reference__c='<a href="https://rubrik.atlassian.net/browse/CDM-198511" target="_blank">CDM-198256</a>';
        update arc;
        
        Assist_Request__c arc1=new Assist_Request__c();
        arc1.id=arList[1].id;
        arc1.OwnerId=tempuser[0].id;
        update arc1;
        
        System.AssertEquals(arc1.OwnerId,[select ownerId from Assist_Request__c where id=:arList[1].id].OwnerId);
        
        Test.stopTest();
        
    }
    
}