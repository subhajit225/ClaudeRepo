//this test class is used for testing "CommunityCaseExtension", which is used to display the Rubrik Case Attachments in the community
@isTest
                    
private class  Test_AC_S3_Case_Attachment_View {

    private static testMethod void runTest() {

            // Create a Case
            Case c = new Case();
            c.Priority='P2';
            insert c;  

            Apexpages.StandardController sc = new Apexpages.standardController(c);
            CommunityCaseExtension cce = new CommunityCaseExtension(sc); 
                   
            //cce.getRubrikCaseAttachments();
            //removing since we moved to using the default SFDC Attachment object
            cce.getComments();            
            cce.closeCase();
        
                       
           }
    
}