@isTest
public class DocumentationControllerTest {

    public static testMethod void getreleaseVersiontest(){

        //UserRole obj=new UserRole(Name= 'ABC');
        //insert obj;

        insert new TriggerControl__c(Name='Entitlement');
        insert new AWS_S3_Creds__c(Name='Entitlement',secretKey__c='sadasd',AccessKey__c='sadas');
        Account acc = new Account();
        acc.name ='Test Account';
        acc.type = 'Partner';
        insert acc ;

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

        Release_Version__c rv = new Release_Version__c();
        rv.Visible__c = true;
        rv.Blocked__c = false;
        rv.Version__c = '5.0.0-EA3-353';
        rv.Release_Type__c = 'Generally Available (GA)';
        rv.Release_Date__c=date.today();
        insert rv;

        Releases__c rel = new Releases__c();
        rel.Product_Type__c = 'Air';
        rel.version__c = '5.0.0-EA3-353';
        rel.Release_Type__c = 'Generally Available (GA)';
        rel.name = 'test';
        rel.Release_Version__c = rv.id;
        insert rel;

        Release_Software__c  rs = new Release_Software__c();
        rs.Bytes__c = 'test';
        rs.MD5__c = 'test';
        rs.Release__c = rel.id;
        rs.S3_File_URL__c = 'sadsa';
        rs.S3_Bucket_Name__c = 'sadsad';
        insert rs;

        Id userLicenseId = [ select Id from UserLicense where NAME = 'Customer Community' LIMIT 1].id;
        Id roleId = [ select Id from UserRole LIMIT 1].id;
        Id communityprofileId = [select Id from Profile where name like '%Rubrik Community Super User%' and UserLicenseId=:userLicenseId].id;

        User portalAccountOwner = new User(alias = 'test123', email='test123@noemail.com',
                                           emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                                           localesidkey='en_US', profileid = communityprofileId, country='United States',IsActive =true,
                                           ContactId = con.Id, FirstName = 'Test First',
                                           timezonesidkey='America/Los_Angeles', username='tester@noemail.com', isAuthorizedUser__c=true);

        Database.insert(portalAccountOwner);
        
        string ironcladResponse = '{"client_version":"1.0.1","client_library":"ps.js","uuid":"61dd52930d92ea6d5bd8c00f","sample_rate":100,"site_id":';
        ironcladResponse += '"35ebe570-3b6e-4726-b439-2915afd18336","signer_id":"veera.gandi@rubrik.com.invalid","versions":["61d4ab473144b428fde08f8e"],';
        ironcladResponse += '"contracts":[153563],"group":30324,"custom_data":{"Source":"Rubrik Support Portal","AccountName":"Rubrik","FullName":"Veera Gandi",';
        ironcladResponse += '"SoftwareName":"rbk-log (1.0.0)"},"confirmation_email":false,"page_title":"Documentation and Downloads","page_url":';
        ironcladResponse += '"https://rbkuat-rubrik.cs218.force.com/CustomerSupport/s/documentationdetail?id=a5B1W000000HxX2UAK",';
        ironcladResponse += '"page_domain":"rbkuat-rubrik.cs218.force.com","page_path":"/CustomerSupport/s/documentationdetail",';
        ironcladResponse += '"page_encoding":"UTF-8","hostname":"rbkuat-rubrik.cs218.force.com","referrer":';
        ironcladResponse += '"https://rbkuat-rubrik.cs218.force.com/CustomerSupport/s/documentationdetail?id=a5B1W000000HxX2UAK",';
        ironcladResponse += '"browser_timezone":-5.5,"browser_locale":"en-gb","java_enabled":false,"operating_system":"MacOS",';
        ironcladResponse += '"environment":"desktop","screen_color_depth":"30-bit","screen_resolution":"1792x1120","screen_dimensions"';
        ironcladResponse += ':"1669x412","jurisdiction":"en-gb","_s":5,"session":"61dd66cef8ef146d63cffa98"}';

        Test.startTest();
        system.runAs(portalAccountOwner) {
            DocumentationController.getReleaseVersions(true);
            DocumentationController.getAllReleaseVersions(true);
            DocumentationController.getReleaseSoftware(rv.id,'test');
            DocumentationController.getLink(rs.Id);
            DocumentationController.gets3Link(rs.Id,false, ironcladResponse);
            DocumentationController.gets3Link(rs.Id,true, ironcladResponse);
            IroncladContractController.gets3Link(rs.Id,false, ironcladResponse);
            IroncladContractController.getUserDetails();
        }
        Test.stoptest();



    }
 
    @isTest
    static void testGetContractDetails() {
        // Set up test data
        String siteAccessId = 'siteAccessId';
        String groupKey = 'groupKey';
        String expectedVaultURL = 'ExpectedVaultURL';
        
        // Create a mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Call the method to be tested
        String result = IroncladContractController.getContractDetails(siteAccessId, groupKey);
        
        // Verify the response
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(200, responseMap.get('statusCode'));
    }
    
    @isTest
    static void testCalloutToIronClad() {
        // Set up test data
        String requestBody = '{"key": "value"}';
        String expectedSendURL = 'ExpectedSendURL';
                
        // Create a mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Call the method to be tested
        Integer result = IroncladContractController.calloutToIronClad(requestBody);
        
        // Verify the response
        System.assertEquals(200, result);
    }
    
   
}