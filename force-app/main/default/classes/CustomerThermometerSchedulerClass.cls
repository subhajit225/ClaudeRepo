global class CustomerThermometerSchedulerClass implements Schedulable {
    global void execute(SchedulableContext SC) {
        CustomerThermometerSchedulerClass.thermometerBlastResults();
    }
    
    @future(callout = true)
    public static void thermometerBlastResults(){
        try{
            Customer_Thermometer__c ctCustomSettings = new Customer_Thermometer__c();
            Customer_Thermometer__c ctApiSetting = new Customer_Thermometer__c();
            if(Customer_Thermometer__c.getAll() != null && Customer_Thermometer__c.getAll().containsKey('getApiKey')){
                ctApiSetting =  Customer_Thermometer__c.getInstance('getApiKey');
            }
            Date d = System.today();
            String startDate;// = DateTime.newInstance(2016,11,1).format('YYYY-MM-dd');
            String endDate;// =DateTime.newInstance(d.year(),d.month(),d.day()).format('YYYY-MM-dd');
            Map<String,Integer> mapCount = new Map<String,Integer>();
            if(Customer_Thermometer__c.getAll() != null && Customer_Thermometer__c.getAll().containsKey('getBlastResults') && Customer_Thermometer__c.getAll().containsKey('getApiKey')){
                ctCustomSettings =  Customer_Thermometer__c.getInstance('getBlastResults');
                if(ctCustomSettings.Latest_Date__c == null){
                    startDate = DateTime.newInstance(2017,01,15).format('YYYY-MM-dd');
                    endDate = DateTime.newInstance(d.year(),d.month(),d.day()).format('YYYY-MM-dd');
                    ctCustomSettings.Latest_Date__c = endDate;
                }else{
                    startDate = ctCustomSettings.Latest_Date__c;
                    endDate = DateTime.newInstance(d.year(),d.month(),d.day()).format('YYYY-MM-dd');
                    ctCustomSettings.Latest_Date__c = endDate;
                }
                ctCustomSettings.Gold_Star__c = ctCustomSettings.Gold_Star__c == null ? 0: ctCustomSettings.Gold_Star__c;
                ctCustomSettings.Green_Light__c = ctCustomSettings.Green_Light__c == null ? 0: ctCustomSettings.Green_Light__c;
                ctCustomSettings.Yellow_Light__c = ctCustomSettings.Yellow_Light__c == null ? 0: ctCustomSettings.Yellow_Light__c;
                ctCustomSettings.Red_Light__c = ctCustomSettings.Red_Light__c == null ? 0: ctCustomSettings.Red_Light__c;
                ctCustomSettings.Total_Response__c = ctCustomSettings.Total_Response__c == null ? 0: ctCustomSettings.Total_Response__c;
                Date stdt = date.valueOf(startDate);
                Integer i = 0 ;
                Integer alltotal = 0;
                Boolean startLoop = true;
                Boolean failSafe = false;
                while(startLoop){
                    ctCustomSettings.Latest_Date__c = String.valueOf(DateTime.newInstance(d.year(),d.month(),d.day()).format('YYYY-MM-dd'));
                    HttpRequest req = new HttpRequest();
                    req.setEndpoint('https://app.customerthermometer.com/api.php?apiKey='+ctApiSetting.API_Key__c+'&getMethod=getBlastResults&blastID='+ctApiSetting.blast_id__c+'&fromDate='+startDate+'&toDate='+endDate);
                    req.setMethod('GET');
                    Http http = new Http();
                    HTTPResponse res = http.send(req);
                    Integer total = 0;
                    if(res.getBody() != null && res.getBody() != ''){
                        Dom.Document doc = new Dom.Document();
                        doc.load(res.getBody());
                        for(Dom.XmlNode node :doc.getRootElement().getChildElements()){
                            if(node.getName() == 'thermometer_blast_response'){
                                for(Dom.XmlNode node2 :node.getChildElements()){
                                    if(node2.getName() == 'response'){
                                        String str = String.valueOf(node2.getText());
                                        if(!mapCount.containsKey(str)){
                                            mapCount.put(str,0);
                                        }
                                        mapCount.put(str,mapCount.get(str)+1);
                                        total++;
                                    }
                                    if(node2.getName() == 'response_date'){
                                        String[] dateString = node2.getText().split(' ');
                                        endDate = dateString[0];
                                    }
                                }
                            }
                        }
                    
                        Date endt = date.valueOf(endDate);
                        if(stdt >= endt){
                            startLoop = false;
                        }
                        if(i == 98){//Fail safe switch,api count is 99
                            startLoop = false;
                        }
                        alltotal += total;
                        i++;
                    }else{
                        startLoop = false;
                    }
                }
                if(mapCount.containsKey('Gold Star'))ctCustomSettings.Gold_Star__c += mapCount.get('Gold Star');
                if(mapCount.containsKey('Green Light'))ctCustomSettings.Green_Light__c += mapCount.get('Green Light');
                if(mapCount.containsKey('Yellow Light'))ctCustomSettings.Yellow_Light__c += mapCount.get('Yellow Light');
                if(mapCount.containsKey('Red Light'))ctCustomSettings.Red_Light__c += mapCount.get('Red Light');
                ctCustomSettings.Total_Response__c += alltotal;
                update ctCustomSettings;
            }
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        
    }
}