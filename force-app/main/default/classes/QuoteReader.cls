public with sharing class QuoteReader {
    public QuoteModel read(String quoteId) {
        System.debug('>>> quoteId: '+quoteId);
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', quoteId);
        return (QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class);
    }
}