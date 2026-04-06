@isTest
public Without sharing class ClusterChartControllerTest {
    static testmethod void LtngVideoBlockControllerTest(){
        Id communityprofileId = [select Id from Profile where name like '%Customer Community Super%'].id;

        Account a = new Account(name ='Test Account') ;
        Database.insert(a);

        Contact con = new Contact(LastName ='test Last Create Long Name for Test functionality', FirstName = 'Test First', AccountId = a.Id,  Email = System.now().millisecond() + 'test@test.com');
        Database.insert(con);
        Cluster__c clus = new Cluster__c();
        clus.account__c = a.id;
        clus.software_version__c = '4.0';
        clus.is_callhome_on__c = true;
        insert clus;

        User portalAccountOwner = new User(alias = 'test123', email='test123@noemail.com',
                                           emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                                           localesidkey='en_US', profileid = communityprofileId, country='United States',IsActive =true,
                                           ContactId = con.Id, FirstName = 'Test First',
                                           timezonesidkey='America/Los_Angeles', username='tester@noemail.com', isAuthorizedUser__c=true);

        Database.insert(portalAccountOwner);
        ApexPages.StandardController sc = new ApexPages.StandardController(clus);
        ClusterChartController cs = new ClusterChartController(sc);
        cs.getVersionHistory();

        Test.startTest();

        system.runAs(portalAccountOwner) {
            ClusterChartController.getChartsData();
            ClusterChartController.getClusterData(clus.id);
        }
        Test.stopTest();
    }
}