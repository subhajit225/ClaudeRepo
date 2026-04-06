/********************************************************************************************************
* Name              : Account_LookBookExtnClass_Test 
* Purpose           : Account_LookBookExtnClass_Test is Used for Testing Account_LookBookExtnClass Class
*********************************************************************************************************/
@isTest
public class Account_LookBookExtnClass_Test{
    static testmethod void testFetchCustomSettingValuesWithoutLookBook(){
        Account acc= new Account(Name='Test');
        insert acc;
        
        Look_Book__c lbook =new Look_Book__c(Name =acc.id,Asset_Label__c='Case study', Asset_URL__c='http://www.rubrik.com/content/uploads/2015/08/Customer-Success-Driscolls.pdf');
        
        PageReference pageRef = Page.Account_LookBookPage; // Adding VF page Name here
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id', acc.Id);//for page reference
        ApexPages.StandardController sc = new ApexPages.standardController(acc);
        Account_LookBookExtnClass  controller = new Account_LookBookExtnClass(sc);
    }
    
    static testmethod void testFetchCustomSettingValuesWithLookBook(){
        Account acc= new Account(Name='Test');
        insert acc;
        
        list<Look_Book__c> listLook_Book= new list<Look_Book__c> ();

        Look_Book__c Lo1= new Look_Book__c ();
        Lo1.name= acc.id;
        Lo1.addnl_asset_label__c= 'Video';
        Lo1.addnl_asset_url__c= 'https://www.youtube.com/watch?v=lti2uxmTBXQ';
        Lo1.asset_label__c= 'Case Study';
        Lo1.asset_url__c= 'http://www.rubrik.com/content/uploads/2015/08/Customer-Success-Driscolls.pdf';

        listLook_Book.add(Lo1);

        insert listLook_Book;
 
        Look_Book__c lbook =new Look_Book__c(Name =acc.id,Asset_Label__c='Case study', Asset_URL__c='http://www.rubrik.com/content/uploads/2015/08/Customer-Success-Driscolls.pdf');
        
        PageReference pageRef = Page.Account_LookBookPage; // Adding VF page Name here
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id', acc.Id);//for page reference
        ApexPages.StandardController sc = new ApexPages.standardController(acc);
        Account_LookBookExtnClass  controller = new Account_LookBookExtnClass(sc);
    }

}