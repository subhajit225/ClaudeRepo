/**
* @description : EULA acceptance on the Support Portal with Ironclad - JIRA - CS21-706
*
* @CreatedDate 15th Dec 2021
* @Created By Veera Gandi
* 
* @Test Class DocumentationControllerTest
*/
public without sharing class IroncladContractController {
    
    /**
    * @description to send signer details to Ironclad when the EULA contract is accepted
    * return: user
    */
    @AuraEnabled
    public static User getUserDetails() {
        return [SELECT Id, Account.Name, Name, FirstName, LastName, Email FROM User
                WHERE Id = :userInfo.getUserId()];
    }
     
    @AuraEnabled 
    public static string getContractDetails(String siteAccessId,String groupKey){
        try {
            String customLabelVaultURL = System.label.EULA_vaultURL;
            Map<String,Object> responseMap = new Map<String,Object>();
            
            String endpointURL = System.label.EULA_vaultURL+'s/'+ siteAccessId +'/groups/'+ groupKey +'/group.js';
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpointURL);    
            request.setHeader('Content-Type', 'application/json');    
            request.setHeader('disable_sending', 'true'); 
            request.setMethod('GET'); 
            HTTPResponse response = http.send(request);
            responseMap.put('statusCode', response.getStatusCode());
            responseMap.put('resBody', response.getBody());
            return JSON.serialize(responseMap);
        } catch (Exception e) {
            system.debug('Exception__'+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static Integer calloutToIronClad(String requestBody) {
        try{
            String customLabelSendURL = System.label.EULA_sendURL;
            if (String.isNotBlank(requestBody) && customLabelSendURL != null && String.isNotBlank(customLabelSendURL)) {
                // ----- CREATE CUSTOM LABELS FOR URL -----
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint(customLabelSendURL);
                request.setHeader('Content-Type', 'application/json');
                request.setMethod('POST');
                request.setTimeout(120000);
                String body = requestBody.replace('versions', 'version');   
                request.setBody(body);
                HTTPResponse response = http.send(request);
                return response.getStatusCode();
            }
        }
        catch (Exception e) {
            system.debug('Exception__'+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
        return 0;
    }
    
    @AuraEnabled
    public static String gets3Link(String Id, Boolean isName, String ironcladResponse) {
        return DocumentationController.gets3Link(Id, isName, ironcladResponse);
    }
}