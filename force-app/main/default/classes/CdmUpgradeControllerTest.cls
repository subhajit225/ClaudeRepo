/********************************************************************************************************
* Name              : CdmUpgradeControllerTests
* Purpose           : CdmUpgradeControllerTests is Used for Testing CdmUpgradeController Class
*********************************************************************************************************/
@IsTest
public class CdmUpgradeControllerTest {

    @TestSetup
    static void setupTestData() {
        Id sysAdminprofileId = [select Id from Profile where name = 'System Administrator'].id;
        Id userRoleId = [SELECT Id FROM UserRole where name = 'Customer Support Staff Engineer'].id;
        User accountOwner = new User(alias = 'test987', email='test12356@noemail.com',
                                           emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                                           localesidkey='en_US', profileid = sysAdminprofileId, country='United States',IsActive =true,
                                            FirstName = 'Account Owner', userRoleId = userRoleId,
                                           timezonesidkey='America/Los_Angeles', username='tester'+System.now().getTime()+'@noemail.com', isAuthorizedUser__c=true);
        insert accountOwner;
        Account acc = new Account();
        system.runAs(accountOwner) {
            
            acc.name ='Test Account';
            acc.type = 'Partner';
            insert acc ;
        } 
    }
    
    public class MatrixHttpCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            // Create a fake response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('  \t 5.0.3-p5 \t 5.0.0 \t 5.0.4 \n 5.0.3-p5 \t true \t true \t true \n 5.0.0 \t true \t true \t true \n 5.0.4 \t true \t true \t true \n');
            response.setStatusCode(200);
            return response;
        }
    }

    public static testMethod void processListDownloadableReleasesRequest(){
        insert new TriggerControl__c(Name='Entitlement');   
        
		Account acc = [SELECT Id from account limit 1];
        Contact con = new Contact();
        con.lastName = 'Test Last';
        con.AccountId = acc.Id;
        insert con;

        Product2 pd = new Product2();
        pd.IsActive= true;
        pd.name = 'test';
        pd.Release_Product_Types__c = 'Air';
        pd.ProductCode = 'test-prod';
        pd.Family = 'AIR';
        insert pd;

        Entitlement  en = new Entitlement ();
        en.name = 'test entitlement';
        en.startdate = system.today();
        en.enddate = system.today().addDays(60);
        en.product__c = pd.Id;
        en.Accountid = acc.id;
        insert en;

        Release_Version__c rv1 = new Release_Version__c();
        rv1.Visible__c = true;
        rv1.Version__c = '5.0.0-817';
        rv1.Release_Type__c = 'Not Generally Available (GA)';
        rv1.Release_Date__c=date.today();
        rv1.Name = 'Something Random 5.0 (GA)';
        insert rv1;

        Release_Version__c rv = new Release_Version__c();
        rv.Visible__c = true;
        rv.Version__c = '5.0.0-817';
        rv.Release_Type__c = 'Generally Available (GA)';
        rv.Release_Date__c=date.today();
        rv.Name = 'Rubrik CDM 5.0 (GA)';
        insert rv;

        Releases__c rel = new Releases__c();
        rel.Product_Type__c = 'CDM';
        rel.version__c = '5.0.0-817';
        rel.Release_Type__c = 'Generally Available (GA)';
        rel.name = '5.0.0-817';
        rel.Release_Date__c=date.today();
        rel.Release_Version__c = rv.id;
        insert rel;

        Releases__c rel1 = new Releases__c();
        rel1.Product_Type__c = 'CDM';
        rel1.version__c = '5.0.3-p5-2548';
        rel1.Release_Type__c = 'Generally Available (GA)';
        rel1.name = 'test1';
        rel1.Release_Date__c=date.today();
        rel1.Release_Version__c = rv.id;
        insert rel1;

        Releases__c rel2 = new Releases__c();
        rel2.Product_Type__c = 'CDM';
        rel2.version__c = '5.0.4-2617';
        rel2.Release_Type__c = 'Generally Available (GA)';
        rel2.name = 'test2';
        rel2.Release_Date__c=date.today();
        rel2.Release_Version__c = rv.id;
        insert rel2;

        Release_Software__c  rs = new Release_Software__c();
        rs.Bytes__c = 'test';
        rs.MD5__c = 'test';
        rs.Release__c = rel.id;
        rs.Link__c = '5.0.0-817.zip';
        insert rs;

        Release_Software__c  rs2 = new Release_Software__c();
        rs2.Bytes__c = 'test';
        rs2.MD5__c = 'test';
        rs2.Release__c = rel2.id;
        rs2.Link__c = null;
        insert rs2;

        insert new AWS_Release_Notes_s3_creds__c(Name='Entitlement',secretKey__c='sadasd',AccessKey__c='sadas');

        Id communityprofileId = [select Id from Profile where name = 'Rubrik Customer Community Login User'].id;

        User portalAccountOwner = new User(alias = 'test123', email='test123@noemail.com',
                                           emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                                           localesidkey='en_US', profileid = communityprofileId, country='United States',IsActive =true,
                                           ContactId = con.Id, FirstName = 'Test First',
                                           timezonesidkey='America/Los_Angeles', username='tester@noemail.com', isAuthorizedUser__c=true);

        Database.insert(portalAccountOwner);

        Test.startTest();
        system.runAs(portalAccountOwner) {
            Test.setMock(HttpCalloutMock.class, new MatrixHttpCalloutMock());
            RestRequest request = new RestRequest();
            RestResponse response = new RestResponse();
            String endpoint = 'https://rubrikinc--cdmsb.lightning.force.com//services/apexrest/cdm/upgrade/listDownloadableReleases';
            request.requestUri = endpoint;
            request.httpMethod = 'GET';
            RestContext.request = request;
            RestContext.response = response;
            request.params.put('show_all', 'true');
            CdmUpgradeController.processListDownloadableReleasesRequest();

            request.params.put('filter_upgradable_versions', 'true');
            request.params.put('source_version', '5.0.0-817');
            CdmUpgradeController.processListDownloadableReleasesRequest();
        }

        system.runAs(portalAccountOwner) {
            Test.setMock(HttpCalloutMock.class, new MatrixHttpCalloutMock());
            RestRequest request = new RestRequest();
            RestResponse response = new RestResponse();
            String endpoint = 'https://rubrikinc--cdmsb.lightning.force.com//services/apexrest/cdm/upgrade/listDownloadableReleases';
            request.requestUri = endpoint;
            request.httpMethod = 'GET';
            RestContext.request = request;
            RestContext.response = response;
            request.params.put('fetch_links', 'true');
            request.params.put('filter_version', '5.0');
            CdmUpgradeController.processListDownloadableReleasesRequest();
        }

        system.runAs(portalAccountOwner) {
            Test.setMock(HttpCalloutMock.class, new MatrixHttpCalloutMock());
            RestRequest request = new RestRequest();
            RestResponse response = new RestResponse();
            String endpoint = 'https://rubrikinc--cdmsb.lightning.force.com//services/apexrest/cdm/upgrade/listDownloadableReleases';
            request.requestUri = endpoint;
            request.httpMethod = 'GET';
            RestContext.request = request;
            RestContext.response = response;
            request.params.put('fetch_links', 'true');
            CdmUpgradeController.processListDownloadableReleasesRequest();

            request.params.put('filter_upgradable_versions', 'true');
            request.params.put('source_version', '5.0.0-817');
            CdmUpgradeController.processListDownloadableReleasesRequest();
        }

        system.runAs(portalAccountOwner) {
            Test.setMock(HttpCalloutMock.class, new MatrixHttpCalloutMock());
            RestRequest request = new RestRequest();
            RestResponse response = new RestResponse();
            String endpoint = 'https://rubrikinc--cdmsb.lightning.force.com//services/apexrest/cdm/upgrade/listDownloadableReleases';
            request.requestUri = endpoint;
            request.params.put('filter_version', '5.0.3');
            request.httpMethod = 'GET';
            RestContext.request = request;
            RestContext.response = response;
            request.params.put('show_all', 'true');
            request.params.put('source_version', '5.0.0-817');
            CdmUpgradeController.processListDownloadableReleasesRequest();

            request.params.put('show_all', 'false');
            request.params.put('fetch_links', 'true');
            request.params.put('AccountID', acc.id);
            CdmUpgradeController.processListDownloadableReleasesRequest();

            request.params.put('filter_upgradable_versions', 'true');
            request.params.put('source_version', '5.0.0-817');
            CdmUpgradeController.processListDownloadableReleasesRequest();

            request.params.put('version', 'invalid');
            CdmUpgradeController.processListDownloadableReleasesRequest();

            request.params.put('filter_version', 'invalid');
            request.params.put('filter_upgradable_versions', 'false');
            CdmUpgradeController.processListDownloadableReleasesRequest();
        }
        
        // ----- catch block test coverage ------
        system.runAs(portalAccountOwner) {
            Test.setMock(HttpCalloutMock.class, new MatrixHttpCalloutMock());
            RestRequest request = new RestRequest();
            RestResponse response = new RestResponse();
            String endpoint = 'https://rubrikinc--cdmsb.lightning.force.com//services/apexrest/cdm/upgrade/listDownloadableReleases';
            request.requestUri = endpoint;
            request.httpMethod = 'GET';
            RestContext.request = request;
            RestContext.response = response;
            request.params.put('fetch_links', 'true');
            request.params.put('filter_version', '5.0');
            request.params.put('AccountID', 'null');
            request.params.put('expiry', 'abc');
            CdmUpgradeController.processListDownloadableReleasesRequest();
        }
        
        Set<ID> releaseversionIDs = new Set<ID>{rv.id};
        Set<String> ProdTypes = new set<String>{'CDM'};
        CdmUpgradeController.getReleaseVDocs(releaseversionIDs,ProdTypes);
        Test.stoptest();
    }
}