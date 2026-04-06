public with sharing class GenerateQuoteProposal {
    
    public String save(QuoteProposalModel context) {
        try{
            return SBQQ.ServiceRouter.save('SBQQ.QuoteDocumentAPI.Save', JSON.serialize(context));
        }catch(Exception e){
            return null;
        }
        
    }
}