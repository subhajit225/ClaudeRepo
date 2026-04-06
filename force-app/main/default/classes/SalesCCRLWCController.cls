/**
 * @description Apex controller for SalesCCR Lightning Web Component 
 * @createdDate July 2025
 */
public without sharing class SalesCCRLWCController {
     /**
     * @description to saveCCR
     * @param finalSaveString
     * @return Response
     **/
    @AuraEnabled
    public static Response saveCCR(string finalSaveString){
        try{
            CCR__c ccr = new CCR__c();
            if(!String.isBlank(finalSaveString)){
                ccr = (CCR__c)JSON.deserialize(finalSaveString, CCR__c.class);
                if(String.isBlank(ccr.Id)){
                    ccr.RecordTypeId = Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Sales CCR').getRecordTypeId();
                    insert ccr;
                    return new Response(true, 'CCR Submitted Successfully!', ccr);
                }else{
                    if(ccr.Does_CCR_affect_People_or_Territory__c == 'People' || ccr.Does_CCR_affect_People_or_Territory__c == ''){
                        ccr.Affected_Territory__c = '';
                        ccr.Affected_Territory_2__c = '';
                        ccr.Affected_Territory_3__c = '';
                        ccr.Affected_Territory_4__c = '';
                        ccr.Affected_Territory_5__c = '';
                        ccr.Affected_Territory_6__c = '';
                    }
                    if(ccr.Does_CCR_affect_People_or_Territory__c == 'Territory' || ccr.Does_CCR_affect_People_or_Territory__c == ''){
                        ccr.Affective_Person__c = null;
                        ccr.Affected_Person_2__c = null;
                        ccr.Affected_Person_3__c = null;
                        ccr.Affected_Person_4__c = null;
                        ccr.Affected_Person_5__c = null;
                        ccr.Affected_Person_6__c = null;
                    }
                    update ccr;
                    return new Response(true, 'CCR Updated Successfully!', ccr);
                }
            }else{
                return new Response(false, 'Something went wrong please contact your administrator.',null);
            }
        }catch(Exception ex) {
            return new Response(false, 'Something went wrong please contact your administrator.'+ex.getMessage(), ex);
        } 
    }
    /**
    * @description Response DTO with success/error message and data
    */ 
     public class Response{
        @AuraEnabled public Boolean Success;
        @AuraEnabled public String Message;
        @AuraEnabled public Object Data;
        /**
        * @description Response DTO with success/error message and data
        * @param Success
        * @param Message
        * @param Data
        */ 
        public Response(Boolean Success, String Message, Object Data){
            this.Success = Success;
            this.Message = Message;
            this.Data = Data;
        }
    }   
}