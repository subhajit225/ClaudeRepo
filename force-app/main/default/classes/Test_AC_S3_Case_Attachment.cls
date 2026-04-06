@isTest
                    
private class  Test_AC_S3_Case_Attachment {

    private static testMethod void runTest() {
        Account theAccount = new Account();
        theAccount.name = 'testAccount';
        insert theAccount;
        
        Case theCase = new Case();
        theCase.AccountId = theAccount.id;
        theCase.Subject = 'test case';
        theCase.priority = 'P1';
        insert theCase;
        
        theCase = [select id, CaseNumber from case where id =:theCase.id];

        PageReference thetestedPage = Page.UploadFile;
        Test.setCurrentPage(thetestedPage);

        // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('ID', theCase.id);
        system.debug('current page: '+ ApexPages.currentPage());
        system.debug('thetestedPage: '+ thetestedPage.getParameters());
        
        AC_S3_Case_Attachment2 thetestedcontroller = new AC_S3_Case_Attachment2();
        //system.debug('thetestedcontroller: '+ thetestedcontroller.parentId);
        system.assertEquals(theCase.id, thetestedcontroller.parentId);
      
        test.startTest();
        thetestedcontroller.Attach_Success_Redirect();
		AC_S3_Case_Attachment2.Customer_Case_Attach2(string.valueOf(theCase.id), '50', 'test_Filename', 'test_fileKey', 'test_uploadStatus');
		test.stopTest();

        Attachment test_Result = [select id, name from Attachment where parentid = :theCase.id];
        system.debug('test_result: '+ test_Result);
        system.assertEquals('test_Filename', test_Result.name);
        
    }
}