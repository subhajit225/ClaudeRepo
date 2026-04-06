public class AboutController{
    
    @AuraEnabled
    public static String TotalResponses(){
        String responseTillDate;
        Customer_Thermometer__c ctApiSetting = new Customer_Thermometer__c();
        if(Customer_Thermometer__c.getAll() != null && Customer_Thermometer__c.getAll().containsKey('getApiKey'))
                ctApiSetting =  Customer_Thermometer__c.getInstance('getApiKey');
                
        try{
            HttpRequest req = new HttpRequest();
            Date d = System.today();
            String startDate =DateTime.newInstance(2016,12,6).format('YYYY-MM-dd');
            String endDate =DateTime.newInstance(d.year(),d.month(),d.day()).format('YYYY-MM-dd');
            req.setEndpoint('https://app.customerthermometer.com/api.php?apiKey='+ctApiSetting.API_Key__c+'&getMethod=getNumResponsesValue&blastID='+ctApiSetting.blast_id__c+'&fromDate='+startDate+'&toDate='+endDate);
            req.setMethod('GET');
            Http http = new Http();
            HTTPResponse res;
            String resVal='';
            if(!Test.isRunningTest()){
                res = http.send(req);
                resVal = res.getBody();
            }else{
                res = null;
                resVal= 'This is test respondse with % sign.';
            }
            if(resVal.contains('%')){
                resVal = resVal.replace('%','');
            }
            responseTillDate = String.valueOf(Decimal.valueOf(resVal));
        }catch(exception e){
            System.debug(e.getMessage());
        }
        
        return responseTillDate;
    }
    
    @AuraEnabled
    public static Map<String,String> blastResults(){
        Map<String,String> mapCount2 = new Map<String,String>();
        Customer_Thermometer__c ctCustomSeting = new Customer_Thermometer__c();
        if(Customer_Thermometer__c.getAll() != null && Customer_Thermometer__c.getAll().containsKey('getBlastResults')){
            ctCustomSeting =  Customer_Thermometer__c.getInstance('getBlastResults');
            ctCustomSeting.Gold_Star__c = ctCustomSeting.Gold_Star__c == null ? 25: ctCustomSeting.Gold_Star__c;
            ctCustomSeting.Green_Light__c = ctCustomSeting.Green_Light__c == null ? 25: ctCustomSeting.Green_Light__c;
            ctCustomSeting.Yellow_Light__c = ctCustomSeting.Yellow_Light__c == null ? 25: ctCustomSeting.Yellow_Light__c;
            ctCustomSeting.Red_Light__c = ctCustomSeting.Red_Light__c == null ? 25: ctCustomSeting.Red_Light__c;
            ctCustomSeting.Total_Response__c = ctCustomSeting.Total_Response__c == null ? 100: ctCustomSeting.Total_Response__c;
            if(ctCustomSeting.Total_Response__c != 0 ){
                Decimal Dividend = ctCustomSeting.Total_Response__c;
                mapCount2 = new Map<String,String>();
                mapCount2.put('Gold Star',String.valueOf(((ctCustomSeting.Gold_Star__c * 100)/Dividend).setscale(1,RoundingMode.UP)));
                mapCount2.put('Green Light',String.valueOf(((ctCustomSeting.Green_Light__c * 100)/Dividend).setscale(1,RoundingMode.UP)));
                mapCount2.put('Yellow Light',String.valueOf(((ctCustomSeting.Yellow_Light__c * 100)/Dividend).setscale(1,RoundingMode.UP)));
                mapCount2.put('Red Light',String.valueOf(((ctCustomSeting.Red_Light__c * 100)/Dividend).setscale(1,RoundingMode.UP)));
            }
        }
        return mapCount2;
    }
    
    @AuraEnabled
    public static String hapinessFactor(){
        String result;
        try{
            Customer_Thermometer__c ctApiSetting = new Customer_Thermometer__c();
            if(Customer_Thermometer__c.getAll() != null && Customer_Thermometer__c.getAll().containsKey('getApiKey'))
                    ctApiSetting =  Customer_Thermometer__c.getInstance('getApiKey');
            HttpRequest req = new HttpRequest();
            Date d = System.today();
            String startDate =DateTime.newInstance(2016,11,1).format('YYYY-MM-dd');
            String endDate =DateTime.newInstance(d.year(),d.month(),d.day()).format('YYYY-MM-dd');
            req.setEndpoint('https://app.customerthermometer.com/api.php?apiKey='+ctApiSetting.API_Key__c+'&getMethod=getTempRatingValue&blastID='+ctApiSetting.blast_id__c+'&fromDate='+startDate+'&toDate='+endDate);
            System.debug(req.getEndpoint());
            req.setMethod('GET');
            Http http = new Http();
            HTTPResponse res;
            String resVal = '';
            
            if(!Test.isRunningTest()){
                res = http.send(req);
                resVal = res.getBody();
            }else{
                res = null;
                resVal= 'This is test respondse with % sign.';
            }
            
            if(resVal.contains('%')){
                resVal = resVal.replace('%','');
            }
            result = String.valueOf(Decimal.valueOf(resVal).setScale(1));
            //result1= JSON.serialize(resultDegree1);
        }catch(exception e){
            System.debug(e.getMessage());
        }
        return result;
    }
    
    @AuraEnabled
    public static String HappinessValue(){
        String result;
        try{
            Customer_Thermometer__c ctApiSetting = new Customer_Thermometer__c();
            if(Customer_Thermometer__c.getAll() != null && Customer_Thermometer__c.getAll().containsKey('getApiKey'))
                    ctApiSetting =  Customer_Thermometer__c.getInstance('getApiKey');
                    
            HttpRequest req = new HttpRequest();
            Date d = System.today();
            String startDate =DateTime.newInstance(2016,12,6).format('YYYY-MM-dd');
            String endDate =DateTime.newInstance(d.year(),d.month(),d.day()).format('YYYY-MM-dd');
            req.setEndpoint('https://app.customerthermometer.com/api.php?apiKey='+ctApiSetting.API_Key__c+'&getMethod=getHappinessValue&blastID='+ctApiSetting.blast_id__c+'&fromDate='+startDate+'&toDate='+endDate);
            req.setMethod('GET');
            Http http = new Http();
            HTTPResponse res;
            String resVal = '';
            if(!Test.isRunningTest()){
                res = http.send(req);
                resVal = res.getBody();
            }else{
                res = null;
                resVal= 'This is test respondse with % sign.';
            }
            if(resVal.contains('%')){
                resVal = resVal.replace('%','');
            }
            result = String.valueOf(Decimal.valueOf(resVal).setScale(1));
            //result3 = JSON.serialize(resultDegree2);
        }catch(exception e){
            System.debug(e.getMessage());
        }
        return result;
    }
    
}