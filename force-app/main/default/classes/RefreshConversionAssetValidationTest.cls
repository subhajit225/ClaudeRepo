/**
* @File Name          : RefreshConversionAssetValidationTest.cls
* @Description        : 
* @Author             : Nipun Kalal
* @Group              : 
* @Last Modified By   : 
* @Last Modified On   : 
**/
@isTest
public class RefreshConversionAssetValidationTest {
    @isTest static void testSerialNumbers() {
        String saasAsset = 'ABC10001,ABC10002,ABC10003';
        String suppAsset = 'XYZ10001,XYZ10002,XYZ10003';
        
        // Set up a test request
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse(); 
        req.requestURI = '/services/apexrest/validateAsset/';
        req.addParameter('ba', saasAsset);
        req.addParameter('sa', suppAsset);
        req.httpMethod = 'GET'; 
        RestContext.request = req; 
        RestContext.response = res;
        
        // Call the method to test
        RefreshConversionAssetValidation.assetValidation();
        
    }
    
}