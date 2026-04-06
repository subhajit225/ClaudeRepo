/*****************************************************************************
 * @description Provides bulkified order and OrderItems list  
*               Example call: /services/apexrest/getPolarisOrders  
* @author: Shadab Hussain
* @date:   12/Apr/2019
*  12/2020 :    Enhancement to include dynamic fieldset in response,Req Logs           
*****************************************************************************/

@RestResource(urlMapping = '/getPolarisOrders/*')
/** 
 * @description Provides bulkified order and OrderItems list
*/
global class PolarisFulfilment_WebService {
    
    
    @HttpGet
    /**
     * @description This method has the logic for processing the Get request
     * @return Response
     */
    global static Response getPolarisOrders()
    {
        
        Map<String,object> reqHeader = new Map<String,object>();
        string ordFields,ordItemFields,orderId;
        String booleanReadonly = 'false';
        List<Setup_Integration_Log__mdt> logCntrlr = new List<Setup_Integration_Log__mdt>();
        Custom_Error_Log__c IntegrationLog = new Custom_Error_Log__c(Class__c = 'PolarisFulfilment_WebService',Functionality__c ='Polaris',Server_Endpoint__c='/getPolarisOrders/*');
        try
        {
            logCntrlr = [select id,Enable_Custom_Logs__c from Setup_Integration_Log__mdt where DeveloperName ='Polaris'];
            final string STATUSNOTSTARTED = 'Not Started';
            final string STATUSINPROGRESS = 'In Progress';
            final string STATUSMANUAL = 'Manual Fulfillment';
            final string STATUSSYNCDATE = 'Resync Support Dates';
            final string POLARISFULFILMENTORDERQUERY = 'PolarisFulfilmentOrderQuery';
            final string POLARISFULFILMENTORDERITEMQUERY = 'PolarisFulfilmentOrderItemQuery';
            final String RSCINSATNCE_QUERY = 'PolarisFulfilmentRSCInstanceQuery';
            
            
            RestRequest request = RestContext.request;
            reqHeader = request.headers;
            IntegrationLog.Http_Request__c = JSON.serialize(reqHeader);
            
            if((string)reqHeader.get('ordFields') != null)
                ordFields = (string)reqHeader.get('ordFields');
            else if((string)reqHeader.get('ordfields') != null)
                ordFields = (string)reqHeader.get('ordfields');
            
            if((string)reqHeader.get('ordItemFields') != null)
                ordItemFields = (string)reqHeader.get('ordItemFields');
            else if((string)reqHeader.get('orditemfields') != null)
                ordItemFields = (string)reqHeader.get('orditemfields');
            
            orderId = (string)reqHeader.get('orderid');
            booleanReadonly = (String)reqHeader.get('readonly') != null ? (String)reqHeader.get('readonly') : 'false';
            System.debug(LOGGINGLEVEL.DEBUG,'Request :::>'+reqHeader.get('orderid'));
            String query = '';
            Map<String, StoreSOQLQuery__mdt> soqlQueryMdtByName = new Map<String, StoreSOQLQuery__mdt>();
            for (StoreSOQLQuery__mdt soqlQuery : [
                SELECT 
                Id,
                DeveloperName,
                Label,
                Query__c 
                FROM StoreSOQLQuery__mdt
                WHERE DeveloperName IN ('PolarisFulfilmentOrderQuery', 'PolarisFulfilmentOrderItemQuery', 'PolarisFulfilmentRSCInstanceQuery')
            ]) {
                soqlQueryMdtByName.put(soqlQuery.DeveloperName, soqlQuery);
            }

            //FY26WL-127
            if (soqlQueryMdtByName != null && soqlQueryMdtByName.containsKey(RSCINSATNCE_QUERY) && String.isNotBlank(soqlQueryMdtByName.get(RSCINSATNCE_QUERY).Query__c)) {
              PolarisFulfilmentAPI.rscQueryString = soqlQueryMdtByName.get(RSCINSATNCE_QUERY).Query__c;
            }
            
            if (soqlQueryMdtByName != null && soqlQueryMdtByName.containsKey(POLARISFULFILMENTORDERQUERY) && String.isNotBlank(soqlQueryMdtByName.get(POLARISFULFILMENTORDERQUERY).Query__c)) {
                query = (String) soqlQueryMdtByName.get(POLARISFULFILMENTORDERQUERY).Query__c;
            }
            
            
            if(ordFields!=null){
                query+= ordFields+',';
            }
            if (soqlQueryMdtByName != null && soqlQueryMdtByName.containsKey(POLARISFULFILMENTORDERITEMQUERY) && String.isNotBlank(soqlQueryMdtByName.get(POLARISFULFILMENTORDERITEMQUERY).Query__c)) {
                query+= soqlQueryMdtByName.get(POLARISFULFILMENTORDERITEMQUERY).Query__c;
            }
            if(ordItemFields!=null) {
                query+=','+ordItemFields;
            }
            
            query+= ' from orderItems) from Order';
            if(booleanReadonly.equalsIgnoreCase('false')){
                query += ' WHERE Send_for_Polaris_Fulfilment__c = TRUE AND RSC_G_Enabled__c = FALSE';
                query +=  ' AND (Polaris_Fulfillment_Status__c = \'' + statusNotStarted + '\' ';
                query +=  ' OR Polaris_Fulfillment_Status__c = \'' + statusInProgress + '\' ';
                query +=  ' OR Polaris_Fulfillment_Status__c = \'' + statusSyncDate + '\' ';
                query +=  ' OR Polaris_Fulfillment_Status__c = \'' + statusManual + '\' )';
            }
            Integer remainingRows = Limits.getLimitQueryRows() - Limits.getQueryRows();
            if(orderId!=null && booleanReadonly.equalsIgnoreCase('false')){
                query +=  ' AND Id = \'' + orderId + '\'';
            }else if(orderId!=null && booleanReadonly.equalsIgnoreCase('true')){
                query +=  ' WHERE Id = \'' + orderId + '\'';
            }
            system.debug(LOGGINGLEVEL.DEBUG,'query'+ query);
                        
            List<Order> orderList = Database.Query(query);
            PolarisFulfilmentAPI.OrderWithFeaturesWrapper JSONResponse = PolarisFulfilmentAPI.polarisFulfilmentJSON(orderList);
            string resp = JSON.serialize(JSONResponse.OrderItems);
            Response finalResponse = new Response(200, 'SUCCESS', resp, JSON.serialize(JSONResponse.OIFeature),JSONResponse.use_rsc_instances);
            System.debug(LOGGINGLEVEL.DEBUG,'orderList :::>'+orderList);
            List<Order> ordersToUpdate = new List<Order>();
            System.debug(LOGGINGLEVEL.DEBUG,'booleanReadonly :::>'+booleanReadonly);
            if(orderList != null && booleanReadonly.equalsIgnoreCase('false')){
                for(Order ord : orderList){
                    if(ord.Polaris_Fulfillment_Status__c == 'Manual Fulfillment'){
                        continue;
                    }
                    ordersToUpdate.add(new Order(Id = ord.Id, Polaris_Fulfillment_Status__c = 'In Progress'));
                }
            }
            if(ordersToUpdate != null && !ordersToUpdate.isEmpty()){
                update ordersToUpdate;
            }
            if(resp.length()>131072){
                resp = resp.substring(0,131072);
            }
            IntegrationLog.Http_Response__c = resp ;
            if(!logCntrlr.isEmpty() && logCntrlr[0].Enable_Custom_Logs__c) { 
                insert IntegrationLog ; 
            }  
            return finalResponse;
        }
        catch(Exception e)
        {
            System.debug(LOGGINGLEVEL.DEBUG,'Exception Occured :::>'+e.getMessage());
            System.debug(LOGGINGLEVEL.DEBUG,'Exception Line :::>'+String.valueOf(e.getLineNumber()));
            IntegrationLog.Http_Response__c = e.getMessage() ;
            if(!logCntrlr.isEmpty() && logCntrlr[0].Enable_Custom_Logs__c) { 
                insert IntegrationLog ; 
            }  
            return new Response(400, 'An unexpected exception occurred. Please try again later.'+e.getMessage()+e.getLineNumber(), null, null,false);
        }
    }
    
    /**
     * @description This is a wrapper class 
     */
    global class Response
    {
        public Integer code;
        public String responseMessage;      
        public String OrderItems;
        public string OIfeature;
        public Boolean use_rsc_instances; //Added as part of Multi Accounting
        /**
         * @description Constructor for Response Wrapper
         * @param code
         * @param responseMessage
         * @param OrderItems
         * @param OIfeature
         * @param use_rsc_instances
         */
        public Response(Integer code, String responseMessage, String OrderItems, string OIfeature, Boolean use_rsc_instances)
        {
            this.code = code;
            this.responseMessage = responseMessage;
            this.orderItems = OrderItems;
            this.OIfeature = OIfeature;
            this.use_rsc_instances = use_rsc_instances;
        }
    }
}