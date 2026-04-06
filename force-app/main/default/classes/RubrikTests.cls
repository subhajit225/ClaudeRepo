@IsTest(SeeAllData=true)
public class RubrikTests{

    public testMethod static void test_LastComment()
    {

        System.Test.startTest();
        Account acct = TestDataFactory.getAccount();
        insert acct;
        Contact contacts = TestDataFactory.getContact(acct);
        insert contacts;
        Contact cont = TestDataFactory.getContact(acct);
        insert cont;
        Case c = TestDataFactory.getCase(acct, contacts);
        c.Resolution_Details__c = 'tertetre';
        insert c;

        CaseSubHistoryController controller = new CaseSubHistoryController();

        controller.isprivate=true;
        controller.cseID = c.id;
        controller.getLastEmail();
        controller.getLastComment();
        controller.getAnyComment();
        controller.getResolutionText();
        controller.getResolutionDetails();
        controller.getE2CPHistory();


       System.Test.stopTest();
    }

    public testMethod static void test_EmailHelper(){
        EmailHelper obj = new EmailHelper();
        obj.NewLine = '\r\n';
        system.assertNotEquals(obj.NewLine, null);
    }


    static testMethod void test_ServiceConsoleCommentExtension() {
        System.Test.startTest();

        Account acct = TestDataFactory.getAccount();
        insert acct;
        Contact contacts = TestDataFactory.getContact(acct);
        insert contacts;
        Contact cont = TestDataFactory.getContact(acct);
        insert cont;
        Case c = TestDataFactory.getCase(acct, contacts);
        insert c;

        Apexpages.StandardController sc = new Apexpages.standardController(c);
        ServiceConsoleCommentExtension sset  = new ServiceConsoleCommentExtension(sc);

        sset.addComment();

        List<SelectOption> selOpts4 = sset.getStatuses();

        System.Test.stopTest();
    }

    static testMethod void test_CommunityCaseExtension_Close() {
            System.Test.startTest();

            Account acct = TestDataFactory.getAccount();
            insert acct;
            Contact contacts = TestDataFactory.getContact(acct);
            insert contacts;
            Contact cont = TestDataFactory.getContact(acct);
            insert cont;
            Case c = TestDataFactory.getCase(acct, contacts);
            c.Priority='P2';
            insert c;

            Apexpages.StandardController sc = new Apexpages.standardController(c);
            CommunityCaseExtension cce = new CommunityCaseExtension(sc);

            cce.getComments();
            cce.closeCase();


            System.Test.stopTest();
        }


    static testMethod void test_AttachmentUploadController(){

        Test.startTest();
        Account acct = TestDataFactory.getAccount();
        insert acct;
        Contact contacts = TestDataFactory.getContact(acct);
        insert contacts;
        Contact cont = TestDataFactory.getContact(acct);
        insert cont;
        Case c = TestDataFactory.getCase(acct, contacts);
        insert c;

        PageReference pageref = Page.CaseView;
        Test.setCurrentPage(pageref);

        ApexPages.currentPage().getParameters().put('Id', c.id);
        AttachmentUploadController  controller = new AttachmentUploadController();


        controller = new AttachmentUploadController();

        controller.attach.Name = 'unit test Attachment';
        controller.attach.Body = Blob.valueOf('unit test Attachment Body');
        controller.upload();

        List<Attachment> attachments = [SELECT ID, Name FROM Attachment WHERE parent.id= :c.id];
        System.assertEquals(1, attachments.size());
        test.stopTest();
    }


    public static testMethod void test_CaseTeamExtension() {

        Account acct = TestDataFactory.getAccount();
        insert acct;
        Contact contacts = TestDataFactory.getContact(acct);
        insert contacts;
        Contact cont = TestDataFactory.getContact(acct);
        insert cont;
        Case c = TestDataFactory.getCase(acct, contacts);
        insert c;

        // Switch to test context
        Test.startTest();

        try {

            pageReference p = Page.AddColleagues;
            p.getParameters().put('id', c.id);
            Test.setCurrentPage(p);

            ApexPages.standardController controller = new ApexPages.standardController(c);
            CaseTeamExtension ctmExt = new CaseTeamExtension(controller);
            system.assertEquals(ctmExt.caseRec.Id, c.id);

            system.assertEquals(ctmExt.CaseTeamMembersCount, 0);
            system.assertEquals(ctmExt.selectAll, false);
            system.assertEquals(ctmExt.AccountContacts.size(), 2);

            system.assertEquals(ctmExt.CaseTeamMembersAllCount, 2);
            system.assertNotEquals(ctmExt.EmailCCRoleId, null);

            ctmExt.saveRec();

            ctmExt.CaseTeamMembersAll[0].checked = true;
            ctmExt.saveRec();

            ctmExt = new CaseTeamExtension(controller);
            system.assertEquals(ctmExt.CaseTeamMembersCount, 1);
            system.assertEquals(ctmExt.CaseTeamMembersAllCount, 2);

            ctmExt.CaseTeamMembersAll[0].checked = false;
            ctmExt.CaseTeamMembersAll[1].checked = false;
            ctmExt.saveRec();

            ctmExt.saveCon();

            ctmExt.cancel();

            // create a new contact and a portal user
            CaseTeamExtension.createContact('firstName2', 'lastname2', 'email238988223@1212.com', 'title2','0987654321');

            // raise an error in the constructor
            controller = new ApexPages.standardController(acct);
            ctmExt = new CaseTeamExtension(controller);

        } catch (Exception ex) {
            system.debug('\n ### error ' + ex);
        }

        // Switch back to runtime context
        Test.stopTest();

    }


    static testMethod void test_CommunityHomeController() {

        CommunityHomeController hp = new CommunityHomeController();

        hp.getTopSolutions();
        hp.getNewArticles();
        hp.getPortalNews();
        hp.getRankedSolutions();

    }

    static testMethod void test_ResourceSearchController() {

        ResourceSearchController rs = new ResourceSearchController();

        rs.getworkspaceID();
        rs.getFeatured();
        rs.getRecent();
        rs.getall();
    }

    static testMethod void test_PartnerCommunityHomeController() {

        PartnerCommunityHomeController rs = new PartnerCommunityHomeController();

        rs.getWebinars();
        rs.getCampaigns();
        rs.getIncentives();

    }


    static testMethod void test_CCRExtension() {

            {
            System.Test.startTest();

            // Create a Case
            CCR__c c = new CCR__c();
            c.Affective_Person__c = UserInfo.getUserId();
            c.CCR_Type__c = 'Other';
            c.Justifications__c='Other';
            insert c;

            Apexpages.StandardController sc = new Apexpages.standardController(c);
            CCRExtension sset  = new CCRExtension(sc);

            System.Test.stopTest();
           }

        }


    static testMethod void test_DownloadController() {

       DownloadController rl = new DownloadController();

        //rl.getReleases();
        rl.getUserReleases();
        rl.getEntitlements();
        rl.getReleaseVersions();
        rl.getReleaseDocs();
        rl.getReleaseSoftwareV();
        rl.getReleaseProductType();
    }


    static testMethod void test_ProductsController() {

      ProductsController pr = new ProductsController();

        ProductsController.nodeList = new List<Node__c>();
        pr.getDarkNodes();
        ProductsController.edgeList = new List<Entitlement>();
        pr.getEdgeNodes();
        ProductsController.cloutList = new list<Entitlement>();
        pr.getClout();
        ProductsController.clonList = new list<Entitlement>();
        pr.getClon();
        ProductsController.clclList = new list<Entitlement>();
        pr.getClCL();

    }
/* //This test method is getting failed due to Queries are not having any limits and this test class enabled SeeAllData=true
   static testMethod void test_InstallBaseDownloadController() {

      InstallBaseDownloadController ibw = new InstallBaseDownloadController();

        ibw.getibWrapperObj();


   }
   */

   static testmethod void test_ReleaseExtension()
     {
         Release_Version__c relobj = new Release_Version__c(Name ='Test', Release_Date__c= system.today(), visible__c=true);
         insert relobj;

         Test.startTest();
         PageReference pageRef = Page.ReleasesView;
         pageref.getParameters().put('id',relobj.id);
         Test.setCurrentPage(pageRef);
         ApexPages.StandardController sc = new ApexPages.StandardController(relobj);
         ReleaseExtension re = new ReleaseExtension(sc);

          Test.stopTest();


    }


    static testmethod void test_DownloadExtension()
     {
         Release_Version__c relV = new Release_Version__c();
         relV.Release_Type__c = 'Early Access (EA)';
         insert relV;
     Releases__c rel = new Releases__c();
         rel.Name = 'Release';
         rel.Release_Version__c = relV.Id;
         insert rel;
         Release_Software__c relsoft = new Release_Software__c();
         relsoft.Release__c = rel.Id;
         insert relsoft;
      Download_History__c dobj = new Download_History__c(EULA_Accepted__c=true);
         insert dobj;

        ApexPages.StandardController sc = new ApexPages.StandardController(dobj);

        DownloadExtension de = new DownloadExtension(sc);
        de.download();


    }

    static testMethod void test_SearchController() {

        // switch to test context
        Test.startTest();

        pagereference ref = ApexPages.CurrentPage();
        ref.getParameters().put('search', 'T');

        SearchController needHelp = new SearchController();

        needHelp.setSearchText('teacvv45sdfgst');
        system.assertEquals(needHelp.getSearchText(), 'teacvv45sdfgst');

        needHelp.doSearch();
        needhelp.doSearchOnload();

        needHelp.setSearchText('testing');
        system.assertEquals(needHelp.getSearchText(), 'testing');

        needHelp.getcResults();
        needHelp.getiResults();
        needHelp.getnResults();
        needHelp.getrResults();

        needHelp.getContentdocs();
        needHelp.getincents();
        needHelp.getccrResults();
        needHelp.getlResults();



        needHelp.getworkspaceID();
        needHelp.getuserType();
        needHelp.geturlscope();


       Integer i1 = needHelp.getiSize();
       Integer i2 = needHelp.getcSize();
       Integer i3 = needHelp.getrSize();
       Integer i4 = needHelp.getnSize();
       Integer i5 = needHelp.getleadsize();
       Integer i6 = needHelp.getccrsize();
       Integer i7 = needHelp.getincentsize();
       Integer i8 = needHelp.getcontentSize() ;
       Decimal d1 = needhelp.getCurrentPageNumber();


       needHelp.getPrevRequired();
       needHelp.getNextRequired();

       needhelp.next();
       needhelp.previous();


        // switch back to runtime context
        Test.stopTest();

    }

    static testMethod void test_CommunityUserPhotoUploadController() {

        CommunityUserPhotoUploadController pr = new CommunityUserPhotoUploadController();

        pr.userId = [select id from user limit 1].id;
        id userId1 = pr.userId;

        pr.getLargePhotoUrl();
        pr.filename = 'name';
        pr.contentType = 'image/png';
        pr.blobValue = blob.valueof('data:image/png;base64,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');

        //ConnectApi.BinaryInput photoFileInput = new ConnectApi.BinaryInput(imageBlob, 'image/png', 'name');
       // ConnectApi.ChatterUsers.setPhoto(Network.getNetworkId(), userId1, photoFileInput);


    }


    static testMethod void test_CommunityCommentExtension_save() {
        Test.startTest();
        Account acct = TestDataFactory.getAccount();
        insert acct;
        Contact contacts = TestDataFactory.getContact(acct);
        insert contacts;
        Contact cont = TestDataFactory.getContact(acct);
        insert cont;
        Case c = TestDataFactory.getCase(acct, contacts);
        insert c;

        Apexpages.StandardController sc = new Apexpages.standardController(c);
        CommunityCommentExtension sset  = new CommunityCommentExtension(sc);

        sset.getComments();
        sset.saveComment();

        System.Test.stopTest();
    }


    static testMethod void test_CommunityCommentExtension_escalate() {
        Test.startTest();
        Account acct = TestDataFactory.getAccount();
        insert acct;
        Contact contacts = TestDataFactory.getContact(acct);
        insert contacts;
        Contact cont = TestDataFactory.getContact(acct);
        insert cont;
        Case c = TestDataFactory.getCase(acct, contacts);
        insert c;
        Apexpages.StandardController sc = new Apexpages.standardController(c);
        CommunityCommentExtension sset  = new CommunityCommentExtension(sc);
        sset.escalate();
        System.Test.stopTest();
    }

    static testMethod void test_CommunityCommentExtension_cancel() {
        Test.startTest();
        Account acct = TestDataFactory.getAccount();
        insert acct;
        Contact contacts = TestDataFactory.getContact(acct);
        insert contacts;
        Contact cont = TestDataFactory.getContact(acct);
        insert cont;
        Case c = TestDataFactory.getCase(acct, contacts);
        insert c;

        Apexpages.StandardController sc = new Apexpages.standardController(c);
        CommunityCommentExtension sset  = new CommunityCommentExtension(sc);

        sset.cancel();

        System.Test.stopTest();
    }

     @IsTest(SeeAllData=true) static void test_CommunityIdeaExtension_cancel() {

            User currentUser = [select id, title, firstname, lastname, email, phone, mobilephone, fax, street, city, state, postalcode, country
                                FROM User WHERE profile.Name='System Administrator' and isactive=true limit 1];
            System.runAs(currentUser) {
            System.Test.startTest();

            //Create Community
            List<Community> c = [select Id from Community where isactive=true limit 1];

            //Create Idea
            Idea ideaToCreate = new Idea();
            ideaToCreate.Title = 'TestIdea';
            ideaToCreate.Body = 'TestIdea';
            ideaToCreate.CommunityId = c[0].Id;
            insert ideaToCreate;


            PageReference pageRef = Page.NewIdea;
            pageRef.getParameters().put('id', String.valueOf(ideaToCreate.Id));
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController sc = new ApexPages.StandardController(ideaToCreate);
            CommunityIdeaExtension ideascon = new CommunityIdeaExtension(sc);
            ideascon.cancel();
            Test.stoptest();
            }

        }

         @IsTest(SeeAllData=true) static void test_CommunityIdeaExtension_save() {

            User currentUser = [select id, title, firstname, lastname, email, phone, mobilephone, fax, street, city, state, postalcode, country
                                FROM User WHERE profile.Name='System Administrator' and isactive=true limit 1];
            System.runAs(currentUser) {
            System.Test.startTest();

            //Create Community
            List<Community> c = [select Id from Community where isactive=true limit 1];

            //Create Idea
            Idea ideaToCreate = new Idea();
            ideaToCreate.Title = 'TestIdea';
            ideaToCreate.Body = 'TestIdea';
            ideaToCreate.CommunityId = c[0].Id;
            insert ideaToCreate;


            PageReference pageRef = Page.NewIdea;
            pageRef.getParameters().put('id', String.valueOf(ideaToCreate.Id));
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController sc = new ApexPages.StandardController(ideaToCreate);
            CommunityIdeaExtension ideascon = new CommunityIdeaExtension(sc);
            ideascon.save();
            Test.stoptest();
            }

        }

     static testMethod void test_IdeaCommentExtension() {

            {
            Community community = [ SELECT Id FROM Community WHERE Name = 'Ideas Community' ];
            Idea Ida = new Idea();
            Ida.Body = 'Body';
            Ida.Title = 'Title';
            Ida.CommunityId = community.Id;
            insert Ida;
            System.Test.startTest();
           // List<Idea> i = [select Id, Body, Title from Idea limit 1];

            Apexpages.StandardController sc = new Apexpages.standardController(Ida);
            IdeaCommentExtension idea  = new IdeaCommentExtension(sc);

           idea.saveComment();


            System.Test.stopTest();
            }

        }


     static testMethod void test_IdeaCommentExtension_cancel() {

            {
            Community community = [ SELECT Id FROM Community WHERE Name = 'Ideas Community' ];
            Idea Ida = new Idea();
            Ida.Body = 'Body';
            Ida.Title = 'Title';
            Ida.CommunityId = community.Id;
            insert Ida;
            System.Test.startTest();
           // List<Idea> i = [select Id, Body, Title from Idea limit 1];

            Apexpages.StandardController sc = new Apexpages.standardController(Ida);
            IdeaCommentExtension idea  = new IdeaCommentExtension(sc);

           idea.cancel();


            System.Test.stopTest();
            }

        }

/*****************************************************************************************************************************************
                                                Setup test data
 *****************************************************************************************************************************************/

         /////Static Methods
        private static User user {
            get {
                if (user == null) {
                    Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
                    User user1 = [SELECT Id FROM User WHERE Profile.Id=:p.id and isActive = true limit 1];
                }
                return user;

            }
            private set;

        }

}