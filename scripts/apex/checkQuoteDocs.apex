// Check existing docs and try CPQ document generation for Q-848689
Id quoteId = 'a6TU8000000ZO97MAG';

// Check ContentDocumentLink for existing files
List<ContentDocumentLink> links = [
    SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.FileType,
           ContentDocument.CreatedDate, ContentDocument.FileExtension
    FROM ContentDocumentLink
    WHERE LinkedEntityId = :quoteId
    ORDER BY ContentDocument.CreatedDate DESC
    LIMIT 10
];
System.debug('Existing docs on quote: ' + links.size());
for (ContentDocumentLink l : links) {
    System.debug('  ' + l.ContentDocument.Title + ' | ' + l.ContentDocument.FileType
        + ' | ' + l.ContentDocument.CreatedDate + ' | Id: ' + l.ContentDocumentId);
}

// Check Attachments (legacy)
List<Attachment> atts = [
    SELECT Id, Name, ContentType, CreatedDate
    FROM Attachment WHERE ParentId = :quoteId
    ORDER BY CreatedDate DESC LIMIT 5
];
System.debug('Attachments: ' + atts.size());
for (Attachment a : atts) {
    System.debug('  ' + a.Name + ' | ' + a.ContentType + ' | ' + a.CreatedDate);
}

// Current quote doc status
SBQQ__Quote__c q = [SELECT SBQQ__DocumentStatus__c, SBQQ__Status__c, ApprovalStatus__c,
                           Generate_Document__c
                    FROM SBQQ__Quote__c WHERE Id = :quoteId];
System.debug('Quote status: ' + q.SBQQ__Status__c);
System.debug('DocStatus: ' + q.SBQQ__DocumentStatus__c);
System.debug('Generate_Document__c: ' + q.Generate_Document__c);
