/************************************************************  
 * @description       : Logic For Getting the Dynamic Url For Document
 * 						Based on its Name
 * @author            : Prashant Kumar
 * Modifications Log
 * Ver   Date          Author        Modification
 **************************************************************/
global class generateDocument {
    global String docName{get;set;}
    global String urlGenerated{
        get {
            list<Document> lstDocument = [SELECT Id FROM Document WHERE DeveloperName = : docName];
            String strOrgId = UserInfo.getOrganizationId();
            String strLogoUrl = System.URL.getSalesforceBaseUrl().toExternalForm() +
                '/servlet/servlet.ImageServer?id='+lstDocument[0].Id +
                '&oid=' + strOrgId;
            return strLogoUrl;
        }
        set;
    }

    


}