@isTest
public class SearchPatchManagerVFC_Test {
    @testSetup static void setupTestData() {
        String jsonInput = '[ { "attributes" : { "type" : "PatchManager__c", "url" : "/services/data/v42.0/sobjects/PatchManager__c/a4z29000000723TAAQ" }, "CountryGlobal__c" : "United States", "County__c" : "Miami-Dade", "Industry_Category__c" : "SLG", "Object_Type__c" : "All", "Region__c" : "East", "State__c" : "Florida", "StateGlobal__c" : "FL", "Zip_code__c" : "33198" }, { "attributes" : { "type" : "PatchManager__c", "url" : "/services/data/v42.0/sobjects/PatchManager__c/a4z29000000723UAAQ" }, "CountryGlobal__c" : "United States", "County__c" : "Miami-Dade", "Industry_Category__c" : "SLG", "Object_Type__c" : "All", "Region__c" : "East", "State__c" : "Florida", "StateGlobal__c" : "FL", "Zip_code__c" : "33199"}, { "attributes" : { "type" : "PatchManager__c", "url" : "/services/data/v42.0/sobjects/PatchManager__c/a4z29000000723VAAQ" }, "CountryGlobal__c" : "United States", "County__c" : "Miami-Dade", "Industry_Category__c" : "SLG", "Object_Type__c" : "All", "Region__c" : "East", "State__c" : "Florida", "StateGlobal__c" : "FL", "Zip_code__c" : "33206"}, { "attributes" : { "type" : "PatchManager__c", "url" : "/services/data/v42.0/sobjects/PatchManager__c/a4z29000000723WAAQ" }, "CountryGlobal__c" : "United States", "County__c" : "Miami-Dade", "Industry_Category__c" : "SLG", "Object_Type__c" : "All", "Region__c" : "East", "State__c" : "Florida", "StateGlobal__c" : "FL", "Zip_code__c" : "33222"}, { "attributes" : { "type" : "PatchManager__c", "url" : "/services/data/v42.0/sobjects/PatchManager__c/a4z29000000723yAAA" }, "CountryGlobal__c" : "United States", "County__c" : "Broward", "Industry_Category__c" : "SLG", "Object_Type__c" : "All", "Region__c" : "East", "State__c" : "Florida", "StateGlobal__c" : "FL", "Zip_code__c" : "33308"} ]';
        //List<PatchManager__c> pmList = (List<PatchManager__c>)JSON.deserializeUntyped(patchJson);
        Type t=Type.forName('List<PatchManager__c>');
        List<PatchManager__c> pmList = (List<PatchManager__c>)JSON.deserialize(jsonInput,t);
        insert pmList;
    }
    
    
    /* This  method will test Searching/Add Patch Manager/Update Patchmanager/Validate and some functions. */
    @isTest
    private static void myunit1(){
        SearchPatchManagerVFC ser = new SearchPatchManagerVFC();
        List<PatchManager__c> pmList = [Select Country__c, CountryGlobal__c, County__c, Industry_Category__c, LeadSource__c, Lead_Source_Detail__c, Object_Type__c, Region__c, SIC__c, State__c,StateGlobal__c, Zip_code__c from PatchManager__c Limit 10];
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(pmList);
        stdSetController.setSelected(pmList);
        ser.setMan = stdSetController;
        Pagereference pg = Page.SearchPatchManagers;
        pg.getParameters().put('objType','All');
        Test.setCurrentPageReference(pg);
        List<Selectoption> nameList = ser.getselectedNameFields();
        List<SelectOption> getPick = ser.getpicklistValue();
        ser.getLeadSorces();
        ser.getObjectTypes();
        ser.getIndustries();
        ser.getPatchManagers();
        ser.getListItems();
        
        
        /* Add Patch */
        PatchManager__c objPM=new PatchManager__c();
        objPM.CountryGlobal__c = 'United States';
        objPM.StateGlobal__c = 'FL';
        objPM.OwnerId = UserInfo.getUserId();
        ser.patchForOwner = objPM;
        ser.county = 'Miami-Dade';
        ser.industry = 'SLG';
        ser.objectType = 'All';
        ser.addNewPM();
        
        system.assertEquals(1,ser.noOfRecords);
        
        /* Edit Patch */
        List<PatchManager__c> upList = [Select id from PatchManager__c Limit 1];
        ser.selectedItem = 'Zip Code';
        ser.searchTerm = '53198';
        ser.selectedItemId = '["'+upList[0].Id+ '"]';
        ser.updateRecordsPatchManager();
        upList = [Select id from PatchManager__c where Zip_code__c = '53198'];
        system.assert(upList.size()>0);
        
        ser.selectedItem = 'Industry';
        ser.pindustry = 'SLG';
        ser.selectedItemId = '["'+upList[0].Id+ '"]';
        ser.updateRecordsPatchManager();
        ser.getRedir();
        
        /* Validate Patch*/
        String searchText = ',,,53198#All';
        String message = SearchPatchManagerVFC.validation(searchText);
        system.assertEquals('Patch manager record with Zip code already exist.',message);
        
    }
    
    @isTest
    private static void testRemoteMethods(){
        Account acc = new Account(name='PatchManager87');
        insert acc;
        List<Account> listAccount;
        Test.startTest();
        listAccount = SearchPatchManagerVFC.searchAccount('ger87');
        Test.stopTest();
        system.assert(listAccount.size()>0);
        
    }
    
    @isTest
    private static void testSearchUser(){
        Profile pf = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User u = createTestUser(pf.Id, 'Test RubrikName', 'Test LastName');
        insert u;
        List<User> lstUsr;
        Test.startTest();
        lstUsr = SearchPatchManagerVFC.searchUser('RubrikName');
        Test.stopTest();
        system.assert(lstUsr.size()>0);
     }
     
    @isTest
    private static void deleteAll(){
        PatchManager__c pm = new PatchManager__c();
        pm.Industry_Category__c = 'SLG';
        pm.Object_Type__c = 'All';
        pm.Zip_code__c = '53198';
        insert pm;
        String message='';
        String pId = '["'+pm.Id+'"]';
        Test.startTest();
        message = SearchPatchManagerVFC.deleteUser(pId);
        Test.stopTest();
        system.assertEquals('Success',message);
        
    }
    
    @isTest
    private static void searchPatchManagerVFCMethods(){
        PatchManager__c pm = new PatchManager__c();
        pm.Industry_Category__c = 'SLG';
        pm.Object_Type__c = 'All';
        pm.Zip_code__c = '53198';
        insert pm;
        String message='';
        String pId = '["'+pm.Id+'"]';
        Test.startTest();
        SearchPatchManagerVFC message1 = new SearchPatchManagerVFC();
        String value1 =message1.state;
        String value2 =message1.country;
        String value3 =message1.smbOwner;
        String value4 =message1.sdr;
        String value5 =message1.account;
        String value6 =message1.pleadsource;
        String value7 =message1.pobjecttype;
        String value8 =message1.updateStateHidden;
        String value9 =message1.updateCountryHidden;
        String value10 =message1.srchCounty;
        String value11 =message1.srchSIC;
        String value12 =message1.selectedAllValue;
        Boolean value13 =message1.selectAll;
        Boolean value14 =message1.descSort;
        Test.stopTest();
        
    }
    
    private static User createTestUser(Id profID, String fName, String lName)
    {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User tuser = new User(  firstname = fName,
                              lastName = lName,
                              email = uniqueName + '@test' + orgId + '.org',
                              Username = uniqueName + '@test' + orgId + '.org',
                              EmailEncodingKey = 'ISO-8859-1',
                              Alias = uniqueName.substring(18, 23),
                              TimeZoneSidKey = 'America/Los_Angeles',
                              LocaleSidKey = 'en_US',
                              LanguageLocaleKey = 'en_US',
                              ProfileId = profId
                             );
        return tuser;
    }
    
}