// Generate quote document for Q-848689 using CPQ managed package
Id quoteId = 'a6TU8000000ZO97MAG';
Id templateId = 'a6RU8000000DS05MAG';

try {
    // Use SBQQ QuoteDocument generation
    SBQQ.DocumentAPI docApi = new SBQQ.DocumentAPI();
    String result = docApi.generate(quoteId, templateId, null, false, true);
    System.debug('Document API result: ' + result);
} catch (Exception ex) {
    System.debug('DocumentAPI error: ' + ex.getMessage());
    System.debug('Type: ' + ex.getTypeName());

    // Fallback: check existing docs
    List<ContentDocumentLink> links = [
        SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.FileType,
               ContentDocument.CreatedDate
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :quoteId
        ORDER BY ContentDocument.CreatedDate DESC
        LIMIT 5
    ];
    System.debug('Existing docs: ' + links.size());
    for (ContentDocumentLink l : links) {
        System.debug(l.ContentDocument.Title + ' | ' + l.ContentDocument.FileType + ' | ' + l.ContentDocument.CreatedDate);
    }
}
