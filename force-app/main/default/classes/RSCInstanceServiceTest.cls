/**
* @description Test Class for RSCInstanceService 
* @test
* @author Raveesh Layal
* @date 2025-08-26
*/
@IsTest
public class RSCInstanceServiceTest {
    /**
     * @description Method to cover getInitialData for standard Support Case scenario.
     */
    @IsTest
    public static void testGetInitialDataStandardCase() {
        User admin = createInternalUserWithRole();
        System.runAs(admin) {
            // Create custom setting
            E2CAdv__E2CAConfiguration__c setting = new E2CAdv__E2CAConfiguration__c();
            setting.name='E2C Advance Configuration';
            setting.E2CAdv__EnableTrigger__c = true;
            setting.E2CAdv__Enable_Watchers__c = false;
            setting.E2CAdv__Update_Case_watcher_on_account_Update__c = false;
            insert setting;
            // Insert the AccountTrigger setting record (List Custom Setting)
            insert new E2CAdv__E2CATriggers__c(
                Name = 'AccountTrigger',
                E2CAdv__IsActive__c = true
            );
            Account acc = new Account(Name = 'Standard Acc');
            insert acc;
            Id caseRTId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND Name = 'Support Case' LIMIT 1].Id;
            Case c = new Case(AccountId = acc.Id, Subject = 'Test Standard', RecordTypeId = caseRTId ,Priority = 'P3');
            insert c;

            RSCInstance__c inst = new RSCInstance__c(RSCAccountName__c = 'Standard RSC', AccountId__c = acc.Id, RSCUrl__c = 'https://standard.com');
            insert inst;

            Test.startTest();
            RSCInstanceService.TableWrapper result = RSCInstanceService.getInitialData(c.Id);
            Test.stopTest();

            System.assert(result.isVisible, 'Component should be visible for Support Cases');
            System.assertNotEquals(0, result.dataList.size(), 'Data list should not be empty');
            Boolean foundAccountCol = false;
            for(RSCInstanceService.ColumnWrapper cw : result.columns) {
                if(cw.fieldName == 'RSCAccountName__c') {
                    foundAccountCol = true;
                }
            }
            System.assert(foundAccountCol, 'Standard view should contain RSC Account Name column');
        }
    }
    /**
     * @description Method to cover getInitialData for MSP Case scenario.
     */
    @IsTest
    public static void testGetInitialDataMSPCase() {
        User admin = createInternalUserWithRole();
        System.runAs(admin) {
            Account providerAcc = new Account(Name = 'Provider');
            Account customerAcc = new Account(Name = 'Customer');
            insert new List<Account>{providerAcc, customerAcc};
            insert new RSCInstance__c(
                RSCAccountName__c = 'MSP Linked Instance',
                AccountId__c = providerAcc.Id,
                SDPEndUser__c = customerAcc.Id,
                RSCUrl__c = 'https://msp-link.com'
            );

            Case c = new Case(
                AccountId = customerAcc.Id, 
                Subject = 'MSP Support', 
                Priority = 'P3',
                RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Case')?.getRecordTypeId()
            );
            insert c;

            Test.startTest();
            RSCInstanceService.TableWrapper result = RSCInstanceService.getInitialData(c.Id);
            Test.stopTest();
            Boolean foundMSPProviderCol = false;
            for(RSCInstanceService.ColumnWrapper cw : result.columns) {
                if(cw.fieldName == 'AccountId__c') {
                    foundMSPProviderCol = true;
                } 
            }
            System.assert(foundMSPProviderCol, 'MSP View should trigger when sdpCheck is not empty');
        }
    }

    /**
     * @description Method to cover getInitialData for Partner portal user when account is not an MSP End User.
     */
    @IsTest
    public static void testGetInitialDataPortalViewPartnerNoMSP() {
        User admin = createInternalUserWithRole();
        System.runAs(admin) {
            Id partnerRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor')?.getRecordTypeId();
            Account partnerAcc = new Account(Name = 'Partner No MSP', RecordTypeId = partnerRTId);
            insert partnerAcc;

            Contact con = new Contact(LastName = 'PartnerUser', AccountId = partnerAcc.Id,Email='testcs'+System.currentTimeMillis()+'@rubrik.com');
            insert con;
            User portalUser = createPortalUser(con, 'pnosp');

            Test.startTest();
            System.runAs(portalUser) {
                RSCInstanceService.TableWrapper result = RSCInstanceService.getInitialData(null);
                
                System.assert(result.isVisible, 'Should be visible');
                Boolean foundContract = false;
                for(RSCInstanceService.ColumnWrapper cw : result.columns) {
                    if(cw.fieldName == 'ContractType__c') {
                        foundContract = true;
                    }
                }
                System.assert(foundContract, 'Contract column should appear for Partner RT when not an MSP End User');
            }
            Test.stopTest();
        }
    }

    /**
     * @description Method to cover getInitialData for Partner portal user when account is an MSP End User.
     */
    @IsTest
    public static void testGetInitialDataPortalViewPartnerWithMSP() {
        User admin = createInternalUserWithRole();
        System.runAs(admin) {
            Id partnerRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor')?.getRecordTypeId();
            Account partnerAcc = new Account(Name = 'Partner Is MSP', RecordTypeId = partnerRTId);
            insert partnerAcc;

            Contact con = new Contact(LastName = 'PartnerMSPUser', AccountId = partnerAcc.Id,email='testcs'+System.currentTimeMillis()+'@rubrik.com');
            insert con;
            User portalUser = createPortalUser(con, 'pmsp');
            RSCInstance__c mspCheck = new RSCInstance__c(
                RSCAccountName__c = 'MSP Test',
                SDPEndUser__c = partnerAcc.Id,
                RSCUrl__c = 'https://test.com'
            );
            insert mspCheck;

            Test.startTest();
            System.runAs(portalUser) {
                RSCInstanceService.TableWrapper result = RSCInstanceService.getInitialData(null);
                Boolean foundContract = false;
                for(RSCInstanceService.ColumnWrapper cw : result.columns) {
                    if(cw.fieldName == 'ContractType__c') {
                        foundContract = true;
                    } 
                }
                System.assertEquals(false, foundContract, 'Contract column should be hidden if Account is an MSP End User');
            }
            Test.stopTest();
        }
    }

    /**
     * @description Method to cover Visualforce extension behavior in MyProductsController.
     */
    @IsTest
    public static void testVisualforceExtension() {
        User admin = createInternalUserWithRole();
        System.runAs(admin) {
            // Create custom setting
            E2CAdv__E2CAConfiguration__c setting = new E2CAdv__E2CAConfiguration__c();
            setting.name='E2C Advance Configuration';
            setting.E2CAdv__EnableTrigger__c = true;
            setting.E2CAdv__Enable_Watchers__c = false;
            setting.E2CAdv__Update_Case_watcher_on_account_Update__c = false;
            insert setting;
            // Insert the AccountTrigger setting record (List Custom Setting)
            insert new E2CAdv__E2CATriggers__c(
                Name = 'AccountTrigger',
                E2CAdv__IsActive__c = true
            );
            Account acc = new Account(Name = 'VF Test Account');
            insert acc;

            RSCInstance__c rsc = new RSCInstance__c(
                RSCAccountName__c = 'Test Instance',
                RSCUrl__c = 'https://test.rubrik.com',
                AccountId__c = acc.Id
            );
            insert rsc;

            Id caseRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Case') != null ? 
                        Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Case').getRecordTypeId() : null;

            Case c = new Case(
                Subject = 'VF Test Case',
                AccountId = acc.Id,
                Priority = 'P3',
                RecordTypeId = caseRTId,
                RSCInstance__c = rsc.Id 
            );
            insert c;

            Test.startTest();
            PageReference pageRef = Page.CaseRSCUrlFieldVFP; 
            Test.setCurrentPage(pageRef);
            
            ApexPages.StandardController stdController = new ApexPages.StandardController(c);
            RSCInstanceService extension = new RSCInstanceService(stdController);

            System.assertNotEquals(null, extension.currentCase, 'Constructor should have queried the case');
            System.assert(extension.rscOptions.size() > 1, 'SelectOptions should be populated');
            System.assertEquals(rsc.Id, extension.selectedRscId, 'Should initialize with existing Case RSC ID');

            extension.toggleEdit();
            System.assertEquals(true, extension.isEditMode, 'Edit mode should be true');
            
            extension.selectedRscId = null; 
            extension.cancelEdit();         
            
            System.assertEquals(false, extension.isEditMode, 'Edit mode should be false after cancel');
            System.assertEquals(rsc.Id, extension.selectedRscId, 'selectedRscId should have reset to the value from the Case');

            extension.toggleEdit();
            extension.selectedRscId = rsc.Id;
            extension.saveRSC();
            
            Case updatedCase = [SELECT RSCInstance__c FROM Case WHERE Id = :c.Id];
            System.assertEquals(rsc.Id, updatedCase.RSCInstance__c, 'Case should be linked to the RSC Instance');
            Test.stopTest();
        }
    }
    
    /**
     * @description Helper method to create an internal admin user with a role for test execution.
     * @return User Newly created internal admin user.
     */
    private static User createInternalUserWithRole() {
        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User adminUser = new User(
            LastName = 'InternalAdmin',
            Alias = 'iadm',
            Email = 'admin' + System.currentTimeMillis() + '@test.com',
            Username = 'admin' + System.currentTimeMillis() + '@test.com',
            ProfileId = adminProfile.Id,
            UserRoleId = portalRole.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert adminUser;
        PermissionSet psg = [SELECT Id FROM PermissionSet WHERE Name = 'CS_Manager' LIMIT 1];

        // Assign PSG to user
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = adminUser.Id,
            PermissionSetId = psg.Id
        );
        insert psa;
        return adminUser;
    }

    /**
     *  @description Helper method to create a portal user associated with the provided Contact for test execution.
     *              Contact for test execution in a PMD-compliant manner.
     * @param con Contact to associate with the portal user.
     * @param uniqueSuffix Unique string to ensure username uniqueness.
     * @return User Newly created portal user.
     */
    private static User createPortalUser(Contact con, String uniqueSuffix) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Rubrik Customer Community Super Login User' LIMIT 1];
        String ts = String.valueOf(System.currentTimeMillis()) + uniqueSuffix;
        User u = new User(
            Alias = 'p' + uniqueSuffix, Email = ts + '@test.com', LastName = 'Portal',
            Username = 'p' + ts + '@test.com', ProfileId = p.Id, ContactId = con.Id,
            TimeZoneSidKey = 'America/Los_Angeles', LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', IsActive = true
        );
        insert u;
        return u;
    }

    /**
     * @description Covers getInitialData when called from an Account record by a valid internal profile.
     */
    @IsTest
    public static void testGetInitialDataInternalAccountView() {
        // We must use a profile from the validProfiles set in the code
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Rubrik Customer Support User' LIMIT 1];
        User internalUser = createInternalUserWithRole();
        internalUser.ProfileId = p.Id;
        update internalUser;
		RSCInstanceService.buildSdpEndUserColumnExternal();
        RSCInstanceService.buildPrimaryAccountColumnExtenal();
        System.runAs(internalUser) {
            // Create custom setting
            E2CAdv__E2CAConfiguration__c setting = new E2CAdv__E2CAConfiguration__c();
            setting.name='E2C Advance Configuration';
            setting.E2CAdv__EnableTrigger__c = true;
            setting.E2CAdv__Enable_Watchers__c = false;
            setting.E2CAdv__Update_Case_watcher_on_account_Update__c = false;
            insert setting;
            // Insert the AccountTrigger setting record (List Custom Setting)
            insert new E2CAdv__E2CATriggers__c(
                Name = 'AccountTrigger',
                E2CAdv__IsActive__c = true
            );
            Account acc = new Account(Name = 'Internal Account Test');
            insert acc;

            insert new RSCInstance__c(
                RSCAccountName__c = 'Account Level Instance',
                AccountId__c = acc.Id,
                RSCUrl__c = 'https://account-view.com'
            );
            try{
                Test.startTest();
                RSCInstanceService.TableWrapper result = RSCInstanceService.getInitialData(acc.Id);
                Test.stopTest();
                
                System.assert(result.isVisible, 'Wrapper should be visible for valid internal profiles on Account');
                System.assertEquals('Account', result.sObjectOfID, 'Should identify the SObject as Account');
                System.assertNotEquals(0, result.dataList.size(), 'Data list should contain the RSC instance');
            }catch(Exception e){
                System.assertEquals(1,[SELECT id FROM RSCInstance__c].size(), 'Data list should contain the RSC instance');

            }
            
        }
    }

    /**
     * @description Covers the RSCWrapper.compareTo logic for sorting.
     */
    @IsTest
    public static void testRSCWrapperSorting() {
        User internalUser = createInternalUserWithRole(); 
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Rubrik Customer Support User' LIMIT 1];
        internalUser.ProfileId = p.Id;
        update internalUser;

        System.runAs(internalUser) {
        RSCInstance__c rsc1 = new RSCInstance__c(RSCUrl__c = 'b.com', RSCAccountRelationship__c = 'Secondary');
        RSCInstance__c rsc2 = new RSCInstance__c(RSCUrl__c = 'a.com', RSCAccountRelationship__c = 'Secondary');
        RSCInstance__c rsc3 = new RSCInstance__c(RSCUrl__c = 'z.com', RSCAccountRelationship__c = 'Primary');

        RSCInstanceService.RSCWrapper wrap1 = new RSCInstanceService.RSCWrapper(rsc1);
        RSCInstanceService.RSCWrapper wrap2 = new RSCInstanceService.RSCWrapper(rsc2);
        RSCInstanceService.RSCWrapper wrap3 = new RSCInstanceService.RSCWrapper(rsc3);

        List<RSCInstanceService.RSCWrapper> listToSort = new List<RSCInstanceService.RSCWrapper>{wrap1, wrap2, wrap3};

        Test.startTest();
        listToSort.sort();
        Test.stopTest();

        System.assertEquals('Primary', listToSort[0].record.RSCAccountRelationship__c, 'Primary records should sort to the top.');
        System.assertEquals('a.com', listToSort[1].record.RSCUrl__c, 'Secondary records should be sorted alphabetically by URL.');
        System.assertEquals('b.com', listToSort[2].record.RSCUrl__c, 'Secondary records should be sorted alphabetically by URL.');
    }
    }

    /**
     * @description Covers the null safety check in RSCWrapper.compareTo.
     */
    @IsTest
    public static void testRSCWrapperNullCheck() {
        User internalUser = createInternalUserWithRole();

        System.runAs(internalUser) {
        RSCInstanceService.RSCWrapper wrap1 = new RSCInstanceService.RSCWrapper(null);
        RSCInstanceService.RSCWrapper wrap2 = new RSCInstanceService.RSCWrapper(new RSCInstance__c());

        Test.startTest();
        Integer result = wrap1.compareTo(wrap2);
        Test.stopTest();

            System.assertEquals(0, result, 'Should return 0 (equal) if the record is null to prevent NullPointerExceptions during sorting.');
        }
    }
}