/*
 * Class Name :- CustomerTemperatureController
 * Visualforce Component :- CustomerTemperatureComponent
 * Author :- Shiva Sharma
 * Created Date :- 25-05-2018
 * Description : This Controller is being used in CustomerTemperatureComponent for creating charts with integration from customerthermometer.
 * 
 // ********************Change Logs *****************************************************************************
 * 
 * Modified By          Date        Description 
 * 
 * 
 * 
 // ********************Change Logs Ends*************************************************************************
*/
public class CustomerTemperatureController {
    public String result1{get;set;}
    public String result2{get;set;}
    public String result3{get;set;}
    public String responseTillDate{get;set;}
    public chartWrapper resultDegree1{get;set;}
    public chartWrapper resultDegree2{get;set;}
    public Map<String,String> mapCount2{get;set;}
    public Customer_Thermometer__c ctApiSetting = new Customer_Thermometer__c();
        
    
    public CustomerTemperatureController(){
        try{
            if(Customer_Thermometer__c.getAll() != null && Customer_Thermometer__c.getAll().containsKey('getApiKey')){
                ctApiSetting =  Customer_Thermometer__c.getInstance('getApiKey');
                TempRatingValue();
                BlastResults();
                HappinessValue();
                TotalResponses();
            }
        }catch(exception e){
            System.debug(e.getMessage());
        }
        
    }
    
    public void TempRatingValue(){
        try{
            HttpRequest req = new HttpRequest();
            Date d = System.today();
            String startDate =DateTime.newInstance(2016,11,1).format('YYYY-MM-dd');
            String endDate =DateTime.newInstance(d.year(),d.month(),d.day()).format('YYYY-MM-dd');
            req.setEndpoint('https://app.customerthermometer.com/api.php?apiKey='+ctApiSetting.API_Key__c+'&getMethod=getTempRatingValue&blastID='+ctApiSetting.blast_id__c+'&fromDate='+startDate+'&toDate='+endDate);
            System.debug(req.getEndpoint());
            req.setMethod('GET');
            Http http = new Http();
            HTTPResponse res = http.send(req);
            String resVal = res.getBody();
            if(resVal.contains('%')){
                resVal = resVal.replace('%','');
            }
            System.debug(ctApiSetting.API_Key__c);
            resultDegree1 = new chartWrapper(Decimal.valueOf(resVal).setScale(1));
            result1= JSON.serialize(resultDegree1);
        }catch(exception e){
            System.debug(e.getMessage());
        }
    }
    public void BlastResults(){
        try{
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
                result2 = JSON.serialize(mapCount2);
            }
        }catch(exception e){
            System.debug(e.getMessage());
        }
            
        //responseTillDate = total;
       
    }
    public void HappinessValue(){
        try{
            HttpRequest req = new HttpRequest();
            Date d = System.today();
            String startDate =DateTime.newInstance(2016,12,6).format('YYYY-MM-dd');
            String endDate =DateTime.newInstance(d.year(),d.month(),d.day()).format('YYYY-MM-dd');
            req.setEndpoint('https://app.customerthermometer.com/api.php?apiKey='+ctApiSetting.API_Key__c+'&getMethod=getHappinessValue&blastID='+ctApiSetting.blast_id__c+'&fromDate='+startDate+'&toDate='+endDate);
            req.setMethod('GET');
            Http http = new Http();
            HTTPResponse res = http.send(req);
            String resVal = res.getBody();
            if(resVal.contains('%')){
                resVal = resVal.replace('%','');
            }
            resultDegree2 = new chartWrapper(Decimal.valueOf(resVal).setScale(1));
            result3 = JSON.serialize(resultDegree2);
        }catch(exception e){
            System.debug(e.getMessage());
        }
    }
    
    public void TotalResponses(){
        try{
            HttpRequest req = new HttpRequest();
            Date d = System.today();
            String startDate =DateTime.newInstance(2016,12,6).format('YYYY-MM-dd');
            String endDate =DateTime.newInstance(d.year(),d.month(),d.day()).format('YYYY-MM-dd');
            req.setEndpoint('https://app.customerthermometer.com/api.php?apiKey='+ctApiSetting.API_Key__c+'&getMethod=getNumResponsesValue&blastID='+ctApiSetting.blast_id__c+'&fromDate='+startDate+'&toDate='+endDate);
            req.setMethod('GET');
            Http http = new Http();
            HTTPResponse res = http.send(req);
            String resVal = res.getBody();
            if(resVal.contains('%')){
                resVal = resVal.replace('%','');
            }
            responseTillDate = String.valueOf(Decimal.valueOf(resVal));
        }catch(exception e){
            System.debug(e.getMessage());
        }
    }
    
    public class chartWrapper{
        public Decimal result{get;set;}
        
        public chartWrapper(Decimal res){
            this.result = res;
        }
        
    }

}