public without sharing class ReleaseExtension
{

    private ApexPages.StandardController standardController;

    public ReleaseExtension(ApexPages.StandardController standardController)
    {
        this.standardController = standardController;
        Release_Version__c record = (Release_Version__c) standardController.getRecord();
    }


}