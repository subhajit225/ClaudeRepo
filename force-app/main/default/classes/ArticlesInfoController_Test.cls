@isTest
public class ArticlesInfoController_Test {
    
    @isTest static void test(){
        
        How_To__kav kav = new How_To__kav();
        kav.Title = 'test article';
        kav.UrlName = 'test-article-url';
        kav.Language = 'en_US';
        insert kav;
        //System.debug('kav---'+kav);
        How_To__kav kRecord1 = [SELECT id,ArticleNumber,KnowledgeArticleId,PublishStatus FROM How_To__kav WHERE Id = :kav.Id];    
        KbManagement.PublishingService.publishArticle(kRecord1.KnowledgeArticleId, true);
        //System.debug('kRecord1.PublishStatus----'+kRecord1.PublishStatus);
        System.debug('kRecord1.KnowledgeArticleId----'+kRecord1.KnowledgeArticleId);
        How_To__kav kav1 = [SELECT Id,Title, ArticleNumber,UrlName, KnowledgeArticleId,PublishStatus FROM How_To__kav WHERE Id = :kav.Id and  PublishStatus='Online'];
        
        System.debug('kav1---'+kav1);
        How_To__kav kav2 = new How_To__kav();
        kav2.Title = 'test article11';
        kav2.UrlName = 'test-article11-url';
        insert kav2;
        How_To__kav kRecord2 = [SELECT id,ArticleNumber,KnowledgeArticleId,PublishStatus FROM How_To__kav WHERE Id = :kav2.Id]; 
        
        List<String> strList = new List<String>();
        How_To__DataCategorySelection dcs = new How_To__DataCategorySelection();
        dcs.ParentId = kav.Id;
        dcs.DataCategoryName = 'api';
        strList.add(dcs.DataCategoryName);
        ArticlesInfoController.getAllData(kav1.PublishStatus);
        ArticlesInfoController.getArticles1(kav1.PublishStatus);
        ArticlesInfoController.getAllCategoryGroups();
        ArticlesInfoController.searchArticle('test article', kav1.PublishStatus);
        ArticlesInfoController.getSoftwareVersions();
        ArticlesInfoController.softwareVerWrap sWrap = new ArticlesInfoController.softwareVerWrap('testLabel','testVal');
        ArticlesInfoController.categorywrapper cWrap = new ArticlesInfoController.categorywrapper();
        List<ArticlesInfoController.KavObj> kvWrap = new List<ArticlesInfoController.KavObj>();
        ArticlesInfoController.KavObj wrap = new ArticlesInfoController.KavObj();
        wrap.objId = kav1.Id;
        wrap.ArticleNumber = kav1.ArticleNumber;
        wrap.KnowledgeArticleId = kav1.KnowledgeArticleId;
        wrap.PublishStatus = kav1.PublishStatus;
        kvWrap.add(wrap);
        System.debug('kvWrap---'+kvWrap); 
        ArticlesInfoController.changeStatus1(kvWrap,'Archived','');
        
        List<ArticlesInfoController.KavObj> kvWrap1 = new List<ArticlesInfoController.KavObj>();
        ArticlesInfoController.KavObj wrap1 = new ArticlesInfoController.KavObj();
        wrap1.objId = kRecord2.Id;
        wrap1.PublishStatus = kRecord2.PublishStatus;
        wrap1.ArticleNumber = kRecord2.ArticleNumber;
        kvWrap1.add(wrap1);
        System.debug('kvWrap1---'+kvWrap1);
        ArticlesInfoController.changeCategory1(kvWrap,strList,'');
        ArticlesInfoController.setSoftwareVersion(kvWrap1,'','');
        
    }
    @isTest static void test1(){
        
        How_To__kav kav = new How_To__kav();
        kav.Title = 'test article';
        kav.UrlName = 'test-article-url';
        kav.Language = 'en_US';
        insert kav;
        How_To__kav kRecord1 = [SELECT id,ArticleNumber,KnowledgeArticleId,PublishStatus FROM How_To__kav WHERE Id = :kav.Id];    
        KbManagement.PublishingService.publishArticle(kRecord1.KnowledgeArticleId, true);
        How_To__kav kav1 = [SELECT Id,Title, ArticleNumber,UrlName, KnowledgeArticleId,PublishStatus FROM How_To__kav WHERE Id = :kav.Id and  PublishStatus='Online'];
        
        List<ArticlesInfoController.KavObj> kvWrap2 = new List<ArticlesInfoController.KavObj>();
        ArticlesInfoController.KavObj wrap2 = new ArticlesInfoController.KavObj();
        wrap2.objId = kav1.Id;
        wrap2.ArticleNumber = kav1.ArticleNumber;
        wrap2.KnowledgeArticleId = kav1.KnowledgeArticleId;
        wrap2.PublishStatus = kav1.PublishStatus;
        kvWrap2.add(wrap2);
        ArticlesInfoController.changeStatus1(kvWrap2,'Draft','');
    }
    @isTest static void test2(){
        
        How_To__kav kav = new How_To__kav();
        kav.Title = 'test article';
        kav.UrlName = 'test-article-url';
        kav.Language = 'en_US';
        insert kav;
        How_To__kav kRecord1 = [SELECT id,ArticleNumber,KnowledgeArticleId,PublishStatus FROM How_To__kav WHERE Id = :kav.Id];    
        List<ArticlesInfoController.KavObj> kvWrap2 = new List<ArticlesInfoController.KavObj>();
        ArticlesInfoController.KavObj wrap2 = new ArticlesInfoController.KavObj();
        wrap2.objId = kRecord1.Id;
        wrap2.ArticleNumber = kRecord1.ArticleNumber;
        wrap2.KnowledgeArticleId = kRecord1.KnowledgeArticleId;
        wrap2.PublishStatus = kRecord1.PublishStatus;
        kvWrap2.add(wrap2);
        ArticlesInfoController.changeStatus1(kvWrap2,'Online','');
    }
    
    @isTest static void test3(){
        How_To__kav kav = new How_To__kav();
        kav.Title = 'test article';
        kav.UrlName = 'test-article-url';
        kav.Language = 'en_US';
        insert kav;
        How_To__kav kRecord1 = [SELECT id,ArticleNumber,KnowledgeArticleId,PublishStatus FROM How_To__kav WHERE Id = :kav.Id];    
        KbManagement.PublishingService.publishArticle(kRecord1.KnowledgeArticleId, true);
        How_To__kav kav1 = [SELECT Id,Title, ArticleNumber,UrlName, KnowledgeArticleId,PublishStatus FROM How_To__kav WHERE Id = :kav.Id and  PublishStatus='Online'];
        
        List<ArticlesInfoController.KavObj> kvWrap2 = new List<ArticlesInfoController.KavObj>();
        ArticlesInfoController.KavObj wrap2 = new ArticlesInfoController.KavObj();
        wrap2.objId = kav1.Id;
        wrap2.ArticleNumber = kav1.ArticleNumber;
        wrap2.KnowledgeArticleId = kav1.KnowledgeArticleId;
        wrap2.PublishStatus = kav1.PublishStatus;
        kvWrap2.add(wrap2);
        ArticlesInfoController.setSoftwareVersion(kvWrap2, '', '');
    }
    
}