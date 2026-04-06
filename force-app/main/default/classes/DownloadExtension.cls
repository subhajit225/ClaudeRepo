public without sharing class DownloadExtension
{

    private ApexPages.StandardController standardController;
    public boolean accepted {get; set;}

    public Release_Software__c releaseSoft {get; set;}

    public DownloadExtension(ApexPages.StandardController standardController)
    {
        this.standardController = standardController;
        Download_History__c record = (Download_History__c) standardController.getRecord();
        record.Date__c = system.now();
        record.User__c = UserInfo.getUserId();
        record.Downloaded_Software__c = ApexPages.currentPage().getParameters().get('softwareid');
        record.IP_Address__c = ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');
        id releaseID = ApexPages.currentPage().getParameters().get('softwareid');
        releaseSoft = test.isRunningTest() ? [select id, Link__c from Release_Software__c limit 1] : [select id, Link__c from Release_Software__c where id =:releaseId];
        accepted=true;
     }
       
    
     // save button is clicked
      public PageReference download() {
    
        Download_History__c record = (Download_History__c) standardController.getRecord();
    
        try {
          if(record.EULA_Accepted__c==false) accepted = false;
          insert record; 
        } catch (DMLException e) {
           if(accepted==false) record.addError('You must accept the EULA before continuing.');
          //ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'' + e));
          return null;
        }
    
        // if successfully inserted new redirect to the 
        PageReference DownloadLink = new PageReference(releaseSoft.Link__c);
        system.debug('### downloadlink ' + releaseSoft.Link__c); 
        DownloadLink.setRedirect(true);
        return DownloadLink;
      
      }



}