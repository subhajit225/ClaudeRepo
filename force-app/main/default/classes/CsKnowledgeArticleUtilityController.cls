/**
 * @author Sushant Arora
 * @date 2025-01-14
 * @description This class contains utility methods for handling Knowledge Article operations, such as updating,
 * 				publishing, and archiving articles in Salesforce.
 * 				It provides methods for processing articles, sending processing emails, and managing article versions.
 * @TestClass - CsKnowledgeArticleUtilityControllerTest
 */
public with sharing class CsKnowledgeArticleUtilityController {

    /**
     * @description Wrapper class for the response returned by various article processing operations.
     * Contains information about the success/failure of the operation and the related error message.
     */
    public class Response {
        
        /**
         * @description Unique identifier of the Knowledge Article.
         */
        @AuraEnabled
        public String id;
        
        /**
         * @description Success flag indicating whether the operation was successful.
         */
        @AuraEnabled
        public Boolean success;
        
        /**
         * @description Error message if the operation was unsuccessful.
         */
        @AuraEnabled
        public String errorMessage;

        /**
         * @description Constructor to initialize a response object.
         * @param id The ID of the Knowledge Article.
         * @param success Whether the operation was successful or not.
         * @param errorMessage Error message in case of failure.
         */
        public Response(String id, Boolean success, String errorMessage) {
            this.id = id;
            this.success = success;
            this.errorMessage = errorMessage;
        }
    }

    /**
     * @description Context object that holds details of the articles being processed, including articles to update,
     * IDs of drafted articles, and the list of responses.
     */
    private class ArticleProcessingContext {
        
        /**
         * @description List of Knowledge Articles to be updated.
         */
        List<How_To__kav> kavToUpdate;
        
        /**
         * @description Set of Knowledge Article IDs that are in 'Draft' status.
         */
        Set<String> idsDrafted;
        
        /**
         * @description List of responses corresponding to each processed article.
         */
        List<Response> responses;

        /**
         * @description Constructor to initialize the ArticleProcessingContext.
         * @param kavToUpdate The list of articles to update.
         * @param idsDrafted The set of drafted article IDs.
         * @param responses The list of responses.
         */
        ArticleProcessingContext(List<How_To__kav> kavToUpdate, Set<String> idsDrafted, List<Response> responses) {
            this.kavToUpdate = kavToUpdate;
            this.idsDrafted = idsDrafted;
            this.responses = responses;
        }
    }

    /**
     * @description Updates a list of Knowledge Articles based on the given IDs.
     * It checks if the necessary permissions are available and processes each article.
     * @param idList List of Knowledge Article IDs to update.
     * @return A list of Response objects containing the outcome of each operation.
     * @throws AuraHandledException If insufficient permissions to access or update Knowledge Articles
     */
    @AuraEnabled
    public static List<Response> updateRecords(List<String> idList) {
        if (!Schema.SObjectType.How_To__kav.isAccessible() || 
            !Schema.SObjectType.How_To__kav.isUpdateable()) {
            throw new AuraHandledException('Insufficient permissions to access or update Knowledge Articles');
        }

        List<Response> responses = new List<Response>();
        if (idList == null || idList.isEmpty()) {
            return responses;
        }

        List<How_To__kav> kavToUpdate = new List<How_To__kav>();
        Set<String> idsDrafted = new Set<String>();
        Map<String, ArticleStatus> articleStatusMap = new Map<String, ArticleStatus>();

        // Process all versions in a single query and loop
        for(How_To__kav article : [
            SELECT Id, Title, KnowledgeArticleId, PublishStatus,
                   Change_Log__c, IsVisibleInPkb, IsVisibleInCsp, IsVisibleInPrm
            FROM How_to__kav
            WHERE KnowledgeArticleId IN :idList
            AND PublishStatus IN ('Draft', 'Online', 'Archived')
            WITH SECURITY_ENFORCED
        ]) {
            ArticleStatus status = articleStatusMap.get(article.KnowledgeArticleId);
            if(status == null) {
                status = new ArticleStatus(article.KnowledgeArticleId);
                articleStatusMap.put(article.KnowledgeArticleId, status);
            }
            
            status.processVersion(article);
        }

        // Process results and create drafts for eligible articles
        ArticleProcessingContext context = new ArticleProcessingContext(kavToUpdate, idsDrafted, responses);
        
        for(ArticleStatus status : articleStatusMap.values()) {
            status.processArticle(context);
        }

        if (!kavToUpdate.isEmpty()) {
            updateArticles(kavToUpdate, context);
        }

        publishAndArchiveArticles(idsDrafted, responses);
        return responses;
    }

    /**
     * @description Drafts and edits a Knowledge Article that is in an 'Online' state.
     * This will create a draft and update the article accordingly.
     * @param onlineKav The online version of the Knowledge Article.
     * @param context The processing context for the articles.
     */
    private static void draftAndEditArticle(How_To__kav onlineKav, ArticleProcessingContext context) {
        try {
            String draftId = KbManagement.PublishingService.editOnlineArticle(onlineKav.KnowledgeArticleId, false);
            onlineKav.Id = draftId;
            onlineKav.Title = onlineKav.Title.contains('[Archived]') ? onlineKav.Title : '[Archived] ' + onlineKav.Title;
            onlineKav.Change_Log__c = buildChangeLog(onlineKav.Change_Log__c);
            onlineKav.IsVisibleInPkb = false;
            onlineKav.IsVisibleInCsp = false;
            onlineKav.IsVisibleInPrm = false;
            context.kavToUpdate.add(onlineKav);
            context.idsDrafted.add(onlineKav.KnowledgeArticleId);
        } catch (Exception e) {
            context.responses.add(new Response(onlineKav.KnowledgeArticleId, false, e.getMessage()));
        }
    }

    /**
     * @description Updates a list of Knowledge Articles and tracks the success or failure of the operation.
     * @param kavToUpdate List of Knowledge Articles to be updated.
     * @param context The context holding processing information.
     */
    private static void updateArticles(List<How_To__kav> kavToUpdate, ArticleProcessingContext context) {
        List<Database.SaveResult> saveResults = Database.update(kavToUpdate, false);
        for (Integer i = 0; i < saveResults.size(); i++) {
            Database.SaveResult result = saveResults[i];
            String articleId = kavToUpdate[i].KnowledgeArticleId;

            if (!result.isSuccess()) {
                String errorMessage = result.getErrors().isEmpty() ? 'Unknown error' : result.getErrors()[0].getMessage();
                context.responses.add(new Response(articleId, false, errorMessage));
                context.idsDrafted.remove(articleId);
            }
        }
    }

    /**
     * @description Publishes and archives articles that are drafted.
     * @param idsDrafted Set of IDs for articles that are in 'Draft' status.
     * @param responses List to track responses of each article's publish/archive operation.
     */
    private static void publishAndArchiveArticles(Set<String> idsDrafted, List<Response> responses) {

        for (String articleId : idsDrafted) {
            try {
                KbManagement.PublishingService.publishArticle(articleId, true);
                KbManagement.PublishingService.archiveOnlineArticle(articleId, null);
                responses.add(new Response(articleId, true, null));
            } catch (Exception e) {
                responses.add(new Response(articleId, false, e.getMessage()));
            }
        }
    }

    /**
     * @description Builds a change log entry for the Knowledge Article update.
     * @param existingLog The existing change log, if any.
     * @return The updated change log string.
     */
    private static String buildChangeLog(String existingLog) {
        String finalLog = (existingLog != null ? existingLog + '<br>' : '') + System.Label.Knowledge_Article_Archive_Changelog;
        return finalLog;
    }

    /**
     * @description Inner class representing the status of a specific article (draft, online, or archived).
     * This class helps manage article versions and their processing.
     */
    private class ArticleStatus {
        
        /**
         * @description The ID of the Knowledge Article.
         */
        private String articleId;
        
        /**
         * @description Flag indicating whether a draft version exists.
         */
        private Boolean hasDraft = false;
        
        /**
         * @description Flag indicating whether an online version exists.
         */
        private Boolean hasOnline = false;
        
        /**
         * @description Flag indicating whether an archived version exists.
         */
        private Boolean hasArchived = false;
        
        /**
         * @description The online version of the article.
         */
        private How_To__kav onlineVersion;
        
        /**
         * @description The title of the article.
         */
        private String title;

        /**
         * @description Constructor to initialize an ArticleStatus object for a specific article ID.
         * @param articleId The ID of the Knowledge Article.
         */
        public ArticleStatus(String articleId) {
            this.articleId = articleId;
        }

        /**
         * @description Processes a version of the article (draft, online, or archived).
         * @param version The article version to process.
         */
        public void processVersion(How_To__kav version) {
            if(version.PublishStatus == 'Draft') {
                hasDraft = true;
                title = version.Title;
            } else if(version.PublishStatus == 'Online') {
                hasOnline = true;
                onlineVersion = version;
                title = version.Title;
            } else if(version.PublishStatus == 'Archived') {
                hasArchived = true;
            }
        }

        /**
         * @description Processes the article and handles actions based on its status (draft, online, archived).
         * @param context The context holding information about articles to update and responses.
         */
        public void processArticle(ArticleProcessingContext context) {
            if(hasArchived && !hasOnline && !hasDraft) {
                context.responses.add(new Response(
                    articleId,
                    false,
                    'Article has already been archived'
                ));
            } else if(hasDraft) {
                context.responses.add(new Response(
                    articleId,
                    false,
                    'Draft version already exists for article: "' + title + '". Please archive or delete the draft first.'
                ));
            } else if(hasOnline) {
                draftAndEditArticle(onlineVersion, context);
            }
        }
    }

    /**
     * @description Sends a processing email with an attached report.
     * @param attachmentBody The body of the attachment in base64 encoded format.
     * @param fileName The name of the file to be attached.
     * @throws AuraHandledException If email sending fails
     */
    @AuraEnabled
    public static void sendProcessingEmail(String attachmentBody, String fileName) {
        try {
            EmailTemplate[] emailTemplates = [
                SELECT Id 
                FROM EmailTemplate 
                WHERE DeveloperName = 'Knowledge_Articles_Archive' 
                WITH SYSTEM_MODE 
                LIMIT 1
            ];
            if(emailTemplates.isEmpty()) {
                return;
            }
        	EmailTemplate emailTemplate = emailTemplates[0];
            String[] toAddresses = SYSTEM.LABEL.Knowledge_Article_Processing_Report_Subscribers.split(',');
            
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName(fileName);
            attachment.setBody(EncodingUtil.base64Decode(attachmentBody));
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setTemplateId(emailTemplate.Id);
            email.setTargetObjectId(UserInfo.getUserId());
            email.setTreatTargetObjectAsRecipient(false);
            email.setToAddresses(toAddresses);
            email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachment });
            email.setUseSignature(false);
            if(String.isNotBlank(System.Label.NoReplyAddressID)){
                email.setOrgWideEmailAddressId(System.Label.NoReplyAddressID);
            }
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
        } catch (Exception e) {
            throw new AuraHandledException('Failed to send email: ' + e.getMessage());
        }
    }
}