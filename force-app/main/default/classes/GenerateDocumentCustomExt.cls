/***********************************************************
 * Story : CPQ22-4425
 * Purpose : Custom "Generate Document" extension controller
 * Created : 22/08/24
************************************************************/

public class GenerateDocumentCustomExt {
    Id quoteId {get; set;}
    String jobId = '';
    public Boolean waitPoll { get; set; }
    public Boolean showError { get; set; }
    public String errorMessage { get; set; }
    
    public GenerateDocumentCustomExt(ApexPages.StandardController sc){
        quoteId = sc.getId();
    }
    
    public PageReference init(){
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__QuoteTemplateId__c, Name, SBQQ__Opportunity2__r.Name, SBQQ__Account__r.Name  FROM SBQQ__Quote__c WHERE Id =:quoteId];
        showError = false;
        createDocument(quote);
        return redirectOrWait();
    }
    
    public void createDocument(SBQQ__Quote__c quote){
        QuoteProposalModel model = new QuoteProposalModel();
        model.quoteId = quote.Id;
        model.templateId = quote.SBQQ__QuoteTemplateId__c;
        model.Name = quote.Name +'_'+ quote.SBQQ__Opportunity2__r.Name +'_'+ quote.SBQQ__Account__r.Name;
        model.Name = model.Name.left(80);
        
        GenerateQuoteProposal proposalGenerator = new GenerateQuoteProposal();
        if (!Test.isRunningTest()) {
            jobId = proposalGenerator.save(model);
        }
        jobId = jobId.remove('"').remove('\\');
    }
    
    public PageReference redirectOrWait(){
        String profileName = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()][0].Name;
        if (Label.Generate_Document_Bypass_Page.contains(profileName)){
            waitPoll = true;
            return null;
        }
        else {
            return getGeneratePage();
        }
    }

    public PageReference checkStatus() {
        AsyncApexJob job = [SELECT Status, ExtendedStatus FROM AsyncApexJob WHERE Id = :jobId];
        if(job.Status == 'Completed' || job.Status == 'Failed' || job.Status == 'Aborted') {
            return resolve(job.Status, job.ExtendedStatus);
        }
        return null;
    }
    
    public PageReference resolve(String Status, String ExtendedStatus){
        if(Status == 'Completed') {
            return getViewPage();
        }
        else if (Status == 'Failed' || Status == 'Aborted'){
            showError = true;
            waitPoll = false;
            errorMessage = ExtendedStatus;
        }
        return null;
    }
    
    public PageReference getViewPage(){
        List<SBQQ__QuoteDocument__c> docList = [SELECT Id FROM SBQQ__QuoteDocument__c WHERE SBQQ__Quote__c = :quoteId ORDER BY CreatedDate Desc LIMIT 1];
        if (!docList.isEmpty()){
            Id docId = docList[0].Id;

            ApexPages.PageReference viewPage = Page.SBQQ__ViewDocument;
            viewPage.getParameters().put('Id', docId);
            viewPage.setRedirect(true);
            return viewPage;
        }
        return null;
    }
    
    public PageReference getGeneratePage(){
        ApexPages.PageReference generatePage = Page.SBQQ__GenerateDocument;
        generatePage.getParameters().put('Id', quoteId);
        generatePage.setRedirect(true);
        return generatePage;
    }
}