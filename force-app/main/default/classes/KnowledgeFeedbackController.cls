public class KnowledgeFeedbackController {
    
     @AuraEnabled
    public static List<ContentDocumentLink> getRelatedAttachment(String recordId){
        return [SELECT ContentDocumentId, ContentDocument.Title , ContentDocument.FileExtension, ContentDocument.ContentModifiedDate, ContentDocument.Description,ContentDocument.ContentSize
            FROM ContentDocumentLink 
            WHERE LinkedEntityId =: recordId];
    }
    
    
    @AuraEnabled
    public static void saveFeedback(String kbId, String title , String body){
        body = body.replace('<span','<p').replace('</span','</p');
        body = body.replaceAll('<h1>', '<p>').replaceAll('<h2>', '<p>').replaceAll('<h3>', '<p>').replaceAll('<h4>', '<p>').replaceAll('<h5>', '<p>').replaceAll('<h6>', '<p>');
        body = body.replaceAll('</h1>', '</p>').replaceAll('</h2>', '</p>').replaceAll('</h3>', '</p>').replaceAll('</h4>', '</p>').replaceAll('</h5>', '</p>').replaceAll('</h6>', '</p>');
        body = body.replaceAll('<br>', '');
        body = body.replaceAll('style=.*;"', '');
        body = body.replaceAll('target=.*"', '');
        body = body.replaceAll('class=.*"', '');
        How_To__kav hw = [SELECT Id, KnowledgeArticleId FROM How_To__kav where id =: kbId];
        FeedItem post = new FeedItem();
        post.ParentId = hw.KnowledgeArticleId;
        post.Visibility = 'AllUsers';
        post.IsRichText = true;
        post.Body = body.unescapeHtml4();
        post.Title = title;
        post.Type = 'QuestionPost';
        insert post;
    }

}