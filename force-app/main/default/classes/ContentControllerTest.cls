@isTest(seealldata=false)
public class ContentControllerTest {
    
    public static testmethod void testContentController(){
        ApexPages.StandardController StandCon= new ApexPages.StandardController(new opportunity(Name = 'Acme'));
        ContentController Con  = new ContentController(StandCon);
        test.starttest();
            Con.FM1.fileName = 'Sizing Presentation';
            Con.FM2.fileName = 'Sizing Response';
            Con.upload();
            Con.FM1.fileName = 'Sizing Presentation';
            Con.FM1.file = blob.valueof(EncodingUtil.base64Encode(blob.toPDF('test1')));
            Con.FM2.fileName = 'Sizing Response';
            Con.upload();
            Con.FM1.fileName = 'Sizing Presentation';
            Con.FM2.fileName = 'Sizing Response';
            Con.FM2.file = blob.valueof(EncodingUtil.base64Encode(blob.toPDF('test2')));
            Con.upload();
            Con.FM1.fileName = 'Sizing Presentation';
            Con.FM1.file = blob.valueof(EncodingUtil.base64Encode(blob.toPDF('test2')));
            Con.FM2.fileName = 'Sizing Response';
            Con.FM2.file = blob.valueof(EncodingUtil.base64Encode(blob.toPDF('test4')));
            Con.upload();
            Con.back();
        test.stoptest();
    }
    
     public static testmethod void testDataDumping(){
        Account acct = new Account(Name='tAccount');
        insert acct;
       // DataDumping.DataDumpingPost(acct.id);
     }

}