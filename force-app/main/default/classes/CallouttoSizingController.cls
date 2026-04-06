/**
* @File Name : CallouttoSizingController.cls
* @description : 
* @Author : 
* @Last Modified By : Deepak Verma 
* @Last Modified On : 
* @Modification Log :
* Test Class :  
*************************************************************************************************/
public without sharing class CallouttoSizingController  implements Queueable,Finalizer, Database.AllowsCallouts {
    public Set<Id> oppIdSet;
    /** 
     * @description 
     * @param oppIdSet1
     */
    public CallouttoSizingController(Set<Id> oppIdSet1){
        oppIdSet = oppIdSet1;
    }
    /** 
     * @description 
     * @param context
     */
    public void execute(QueueableContext context){
        try{
            System.attachFinalizer(this);
            if(!oppIdSet.isEmpty()){
                String Endpoint = system.label.Sizing_Endpoint;    
                if(Test.isRunningTest()){
                    Endpoint= 'http://sizing.com/example/test'; 
                }
                Http http = new Http();
                HttpRequest req = new HttpRequest();
                req.setEndpoint(Endpoint);
                req.setMethod('POST');
                req.setHeader('API-KEY',system.label.Sizing_API_Key);
                req.setHeader('APP-NAME',system.label.Sizing_App_Name);
                String oppIdStr = '';
                for(Id oppId : oppIdSet){
                    oppIdStr = oppId+','+oppIdStr;
                }
                if(oppIdStr.endswith(',')){
                    oppIdStr = oppIdStr.removeEnd(',');
                }
                oppIdStr = '"'+oppIdStr+'"';
                String jsonBody = '{"data":'+oppIdStr+'}';
                req.setBody(jsonBody);
                system.debug('@@ jsonBody '+jsonBody);
                HTTPResponse res = http.send(req);
                system.debug('response '+res.getBody());
                if(res.getstatuscode() != 200 && res.getstatuscode() != 201){
                    Custom_Error_Log__c log = new Custom_Error_Log__c();
                    log.Class__c='CallouttoSizingController';
                    log.Exception_Message__c = res+'  '+res.getBody();
                    log.Http_StatusCode__c = string.valueOf(res.getstatuscode());
                    log.Http_Response__c = string.valueOf(res.getBody());
                    if(string.valueOf(oppIdSet).length() < 255)
                        log.FailedRecords__c = string.valueOf(oppIdSet);
                    insert log;
                }
            }
        }catch(Exception e){
                Custom_Error_Log__c log = new Custom_Error_Log__c();
                log.Class__c='CallouttoSizingController';
                log.Exception_Message__c = e.getMessage()+' at line '+e.getLineNUmber();
                if(string.valueOf(oppIdSet).length() < 255)
                        log.FailedRecords__c = string.valueOf(oppIdSet);
                insert log;   
        }
    }
    /** 
     * @description Calculate Account Discount History FY26WL-499 
     * @param ctx
     */
    public void execute(FinalizerContext ctx) {
        system.enqueueJob(new accountDiscountHistoryQueuelable(oppIdSet));
    }
}