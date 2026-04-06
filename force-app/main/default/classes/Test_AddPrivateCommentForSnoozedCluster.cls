@isTest
public class Test_AddPrivateCommentForSnoozedCluster {
    public static testMethod void addTestComment(){
        List<case> newcaseList = testDataFactoryClass.createCase(1);
        AddPrivateCommentForSnoozedCluster.addComment(new List<Id>{newcaseList.get(0).Id});
    }
}