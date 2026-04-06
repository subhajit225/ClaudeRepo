@isTest
public class DealUpdateTriggerTest {
    static testmethod void TestdealUpdatesonParent(){
        FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        //insert custom setting record for deal update
        TriggerControl__c setting1 = new TriggerControl__c();
        setting1.Name = 'Opportunity';
        setting1.DisableTrigger__c = False;
        insert setting1;
        
        DealUpdate__c setting = new DealUpdate__c();
        setting.Name = 'OpportunitySE';
        setting.Field_API_Name__c = 'MostRecentSEUpdate__c';
        setting.Date_Field_API_Name__c ='MostRecentSEUpdateDate__c';
        insert setting; 
        //insert account,contact to refer in opportunity 
        account acc=new account(name='dealUpdate test account');
        insert acc;
        contact con=new contact(lastname='dealUpdate test contact',leadsource='web',
                              email='dealcn@test.com',accountId=acc.id);
        insert con;
        //create opportunity to refer in Deal_Update__c
        list<opportunity> oppListforInsert=new list<Opportunity>();
        for(integer i=0;i<10;i++){
        oppListforInsert.add(new Opportunity (name='dealUpdate test opportunity'+i,AccountId=acc.id, StageName='1 Discovery', CloseDate=system.Today(),
                                     ForecastCategoryName='Best Case',Initial_Contacts_Name__c=con.id,Business_Unit__c='Rubrik'));
        }
        insert oppListforInsert;

        FlowControll.opportunityTriggerHandler = true;
        FlowControll.AccountTrigger = true;
        //insert dealupdate records
        list<Deal_Update__c> dealsForInsert=new list<Deal_Update__c>();
        for(integer i=0;i<10;i++){
        dealsForInsert.add(new Deal_Update__c(Account__c=acc.id, Opportunity__c=oppListforInsert[i].id, 
                                                   Body__c='This is sample text', Type__c='SE', Object_Type__c='Opportunity'));
        }
        insert dealsForInsert;
        //get created date of dealupdate
        Deal_Update__c dlupdate=new Deal_Update__c();
        dlupdate=[select id,createdDate from Deal_Update__c limit 1];
        DateTime dT = dlupdate.createdDate;
        Date dealCreationDate = date.newinstance(dT.year(), dT.month(), dT.day()); 
        //check if records updated successfully
        //system.assertEquals(10,[select count() from opportunity where name like 'dealUpdate test opportunity%' AND MostRecentSEUpdateDate__c=:dealCreationDate]);
        //integer count=0;
        //for(opportunity o:[select id,MostRecentSEUpdate__c from opportunity where name 
        //                   like 'dealUpdate test opportunity%' AND MostRecentSEUpdateDate__c=:dealCreationDate]) {
        //                       if(o.MostRecentSEUpdate__c.contains('This is sample text')){
        //                           count=count+1;
        //                       }
        //                   }
        //system.assertEquals(100, count);
    }
}