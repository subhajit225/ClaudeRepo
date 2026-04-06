@isTest
public class attachArticleToCase_test {
    public static testMethod void attachArticleToCase_test(){
        
        User userRecord = [SELECT Id FROM User WHERE id=: UserInfo.getUserId()];
        
        //Run As userRecord
        System.RunAs(userRecord){ 
            //Create acount
            Account acc = New Account();
            acc.Name = 'Acc1';
            acc.Heads_UpTo_Support_Team__c = 'abc';        
            insert acc;
            
            Contact ct = new Contact();
            ct.AccountId = acc.Id;
            ct.FirstName = 'Rajesh';
            ct.LastName = 'Gosetty';
            ct.Email = 'rajesh.gosetty@rubrik.com';
            insert ct;
            
            How_To__kav kRecord = new How_To__kav();
            kRecord.Title = 'APEX TEST';
            kRecord.UrlName = 'APEX-TEST';
            kRecord.Language = 'en_US';
            insert kRecord;
            How_To__kav kRecord1 = [SELECT KnowledgeArticleId FROM How_To__kav WHERE Id = :kRecord.Id];    
            KbManagement.PublishingService.publishArticle(kRecord1.KnowledgeArticleId, true);
            
            
            Case cs = New Case();
            cs.Subject = 'CASE-93282';
            cs.Description = 'Test';
            cs.Type = 'Other';
            cs.Product_Area__c = 'Other';
            cs.Problem_Type__c = 'Other';
            cs.Status = 'New';
            cs.Priority = 'P1';
            cs.ContactId = ct.Id;
            cs.Resolution_Details__c = 'Test';
            cs.Cause__c = 'Test';
            cs.Software_Version__c = 'Polaris 1.0';
            cs.Solution__c = 'Test';
            cs.Additional_Notes__c = 'Test';
            cs.Article_Created__c = true;
            cs.KCS_Article_Candidate__c = 'New Article Created';
            cs.KCS_Article_Status__c = 'Draft';
            cs.If_Other__c = 'test';
            insert cs;
            
            
            
            
            //sObject sObj = Schema.getGlobalDescribe().get('KnowledgeArticle').newSObject();
            //system.debug(sObj);
            //insert sObj;
            //system.debug(sObj.get('Id'));
            attachArticleToCase.searchArticle('APEX TEST', cs.Id);
            attachArticleToCase.attachToCase1(new List<string>{kRecord1.KnowledgeArticleId},cs.Id);
            attachArticleToCase.getArticlesApex(cs.Id);
            attachArticleToCase.removeFromCase1(kRecord1.KnowledgeArticleId,cs.Id);
            
        }
    }
}