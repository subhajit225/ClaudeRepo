/** 
* @Author      : Raveesh Layal
* @CreatedDate : 18th July 2023
* @Description : Add Cluster Id and Additional Cluster ID information to JIRA.
* @Jira		   : CS21-1820
* @Apex Classes: SFJIRACaseClusterUpdateBatch.apxc
* -------------------------- @History --------------------------------------------------------------------------------------------
* Story Number       Modified By              Date           Description
*  		           
* --------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class SFJIRACaseClusterUpdateBatchTest {
    @isTest
    public static void method1()
    {
        
        // creating a account to use for creating case data
        list<account> acclist=new list<account>();
        for(Integer i=0;i<10;i++)
        {
            account acc=new Account();
            acc.name='testing'+i;
            acc.BillingCountry = 'United States';
            acclist.add(acc);
        }
        insert acclist;
        list<cluster__c> clList= new list<cluster__c>();
        // creating cluster data
        for(integer i=0;i<10;i++)
        {
            cluster__c cl= new cluster__c();
            cl.account__c=acclist[i].id;
            cl.name='3d04e794-c526-498b-b652-a513a0f07c'+i;
            cl.uuid__c='3d04e794-c526-498b-b652-a513a0f07c'+i;
            clList.add(cl);
            
        }
        
        if(clList.size()>0)
        {
            insert clList;
        }
        
        
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
            caseUser.Cluster__c=clList[i].id;
            caseUser.Additional_Cluster__c=clList[i].id;
            casedata.add(caseUser);
        }
        insert casedata;
        //
        
        //creating ZIssue data
        zsfjira__ZIssue__c zi=new zsfjira__ZIssue__c(zsfjira__IssueKey__c='CDM-103905',
                                                     SalesforceTicket__c='00042086',
                                                     zsfjira__IssueId__c=219441,
                                                     Name='CDM-103905',
                                                     OwnerId=UserInfo.getUserId()
                                                    );
        insert zi;                                                                                    
        // creating zsfjira__ZIssue_Case__c data
        zsfjira__ZIssue_Case__c zzc= new zsfjira__ZIssue_Case__c();
        zzc.zsfjira__CaseId__c=casedata[0].id;                                        
        zzc.Name='Test';
        zzc.zsfjira__ZIssueId__c=zi.id;
        insert zzc;
        Test.startTest();
        String query=' SELECT Id, zsfjira__CaseId__c, zsfjira__CaseId__r.CaseNumber,  zsfjira__ZIssueId__r.zsfjira__IssueKey__c, zsfjira__ZIssueId__r.SalesforceTicket__c, CreatedDate FROM zsfjira__ZIssue_Case__c';
        SFJIRACaseClusterUpdateBatch obj2=new SFJIRACaseClusterUpdateBatch(query);
        Id batchprocessid= DataBase.executeBatch(obj2);
        List<AsyncApexJob> aaj = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors 
                            FROM AsyncApexJob WHERE ID =: batchprocessid ];
        System.assertEquals(true, aaj.size()>0);
        Test.stopTest();
        
        
    }
    
}