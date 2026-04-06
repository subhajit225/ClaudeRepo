@isTest
public class RubrikSupportUrlWriterClassTest  {

    static testmethod void test1(){
           RubrikSupportUrlWriterClass  tc = new RubrikSupportUrlWriterClass ();
           tc.mapRequestUrl(new Pagereference('/articles/How_To/0000'));
           tc.generateUrlFor(null);
    
    }


}