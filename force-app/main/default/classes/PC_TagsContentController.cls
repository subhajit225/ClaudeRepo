/**
 * @Modifieddate 2026-06-05
 * @description Controller for content files based on tags/library/object
 */
public without sharing class PC_TagsContentController{
    /**
     * @description Fetches content details based on the provided tag name and library name.
     * @returns List<ContentVersion> - A list of ContentVersion records that match the specified tag and library.
     */
    @AuraEnabled
    public static List<ContentVersion> fetchContentDetails(string TagsName, string LibraryName){
        ID workspaceId;
        List<ContentWorkspace> contentworkspaceList = new List<ContentWorkspace>();
        contentworkspaceList = [SELECT Id
                                FROM ContentWorkspace
                                WHERE Name = :LibraryName];
        if (contentworkspaceList.size() > 0){
            workspaceId = contentworkspaceList[0].Id;
        }
        List<User> userRecord = new List<User>();
        List<ContentVersion> contentRecordList = new List<ContentVersion>();
        List<ContentVersion> contentList = new List<ContentVersion>();

        /* Querying Logged in User Information */
        userRecord = [select id, contact.Account.type, AccountId, contact.Account.ETM_Theatre__c, Contact.Primary_Role__c, name, contact.Account.ChannelProgramLevelName, contact.Account.ChannelProgramName
                      from User
                      where Id = :userinfo.getUserId()];//prit26-464

        /** Querying contentversion based on Filters **/
        contentRecordList = [select id, Title, Description, FileType, Owner.Name, VersionNumber, ContentDocumentId, TagCsv, ContentDocument.ParentId
                             from ContentVersion
                             WHERE IsLatest = TRUE
                             Order By CreatedDate Desc];

        /** Looping Content Records **/
        for (ContentVersion content : contentRecordList){
            if (content.TagCsv != null){
                if (content.TagCsv.contains(TagsName)){
                    contentList.add(content);
                }
            }
        }
        return contentList;
    }

    /**
     * @description Fetches content details based on the provided tag name, library name, and default tag.
     * @returns List<ContentVersion> - A list of ContentVersion records that match the specified tag, library, and default tag.
     */
    @AuraEnabled
    public static List<ContentVersion> fetchContentDetailsForCustomTags(String TagsName, String LibraryName, String DefaultTag){
        ID workspaceId;
        List<ContentWorkspace> contentworkspaceList = new List<ContentWorkspace>();
        contentworkspaceList = [SELECT Id
                                FROM ContentWorkspace
                                WHERE Name = :LibraryName];
        if (contentworkspaceList.size() > 0){
            workspaceId = contentworkspaceList[0].Id;
        }

        List<User> userRecord = new List<User>();
        List<ContentVersion> contentRecordList = new List<ContentVersion>();
        List<ContentVersion> contentList = new List<ContentVersion>();

        /* Querying Logged in User Information */
        userRecord = [SELECT Id, contact.Account.type, AccountId, contact.Account.ETM_Theatre__c, Contact.Primary_Role__c, name, contact.Account.ChannelProgramLevelName, contact.Account.ChannelProgramName
                      FROM User
                      WHERE Id = :userinfo.getUserId()];//prit26-464

        /** Querying contentversion based on Filters **/
        contentRecordList = [SELECT Id, Title, Description, FileType, Owner.Name, VersionNumber, ContentDocumentId, Tags__c, ContentDocument.ParentId
                             FROM ContentVersion
                             WHERE IsLatest = TRUE
                             ORDER BY CreatedDate Desc];

        Set<Id> fsIdSet = new Set<Id>();
        Set<Id> cdocIdSet = new Set<Id>();
        fsIdSet = FileSharingController.queryCVSharing();
        if (!fsIdSet.isEmpty()){
            for (Contentdocumentlink cdl : [SELECT Id, linkedentityId, ContentDocumentId, ShareType, Visibility
                                            FROM Contentdocumentlink
                                            WHERE linkedentityId IN:fsIdSet]){
                cdocIdSet.add(cdl.ContentDocumentId);
            }
        }
        if (!cdocIdSet.isEmpty()){
            for (ContentVersion cvl : [SELECT Id, Title, Description, FileType, Owner.Name, VersionNumber, ContentDocumentId, Tags__c, ContentDocument.ParentId
                                       FROM ContentVersion
                                       WHERE IsLatest = TRUE AND ContentDocumentId IN:cdocIdSet
                                       ORDER BY CreatedDate Desc]){
                contentRecordList.add(cvl);
            }
        }

        /** Looping Content Records **/
        for (ContentVersion content : contentRecordList){
            if (content.Tags__c != null){
                if (content.Tags__c.containsIgnoreCase(TagsName) && content.Tags__c.containsIgnoreCase(DefaultTag)){
                    contentList.add(content);
                }
            }
        }
        return contentList;
    }

    /**
     * @description Fetches content details based on the provided Content ID.
     * @returns Id - The ContentDocumentId associated with the specified ContentVersion ID.
     */
    @AuraEnabled
    public static Id PreviewContentDetails(String ContentIds){
        Id contentdocId;
        List<contentversion> contentList = new List<contentversion>();
        contentList = [SELECT Id, contentDocumentId
                       FROM contentversion
                       WHERE Id = :ContentIds];
        if (contentList.size() > 0){
            contentdocId = contentList[0].contentDocumentId;
        }
        return contentdocId;
    }

    @AuraEnabled
    public static List<Id> fetchAttachedContentDocDetails(){
        Set<Id> cvIds = new Set<Id>();
        List<Id> cvIdList = new List<Id>();
        Id accId = [SELECT AccountId
                    FROM User
                    WHERE Id = :UserInfo.getUserId()].AccountId;
        for (Account acc : [SELECT Id, Name, (select ContentDocument.LatestPublishedVersionId
                                              FROM AttachedContentDocuments)
                            FROM Account 
                            WHERE Id = :accId]){
            for (AttachedContentDocument attachDoc : acc.AttachedContentDocuments){
                cvIds.add(attachDoc.ContentDocument.LatestPublishedVersionId);
            }
        }
        if (!cvIds.isEmpty()){
            cvIdList.addAll(cvIds);
        }
        return cvIdList;
    }
}