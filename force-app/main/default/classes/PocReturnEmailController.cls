public  class PocReturnEmailController {
    
    public Id PocReturnID {get;set;}
    public List<responseWrapper> getPocReturnItem()
    {
        List<responseWrapper> result = new List<responseWrapper> ();
        system.debug('PocReturnIDVar>>'+PocReturnID);
        List<POC_Return_Item__c> pocReturnList = new List<POC_Return_Item__c>();
        pocReturnList = [SELECT Id,Name,Asset__c,Asset__r.Name,Product__c,POC_Return__c,Product__r.Name,Product__r.Description,Quantity__c,POC_Return__r.Retrun_Tracking_Number__c, POC_Return__r.Location__c,Serial_Number__c FROM POC_Return_Item__c WHERE POC_Return__c =: PocReturnID];
        system.debug('PocReturnIDVar>>'+pocReturnList);
        
        for(POC_Return_Item__c rsOpp:pocReturnList){
            responseWrapper resultTemp = new responseWrapper();
            resultTemp.ProductName =rsOpp.Product__r.Name;
            resultTemp.Description =rsOpp.Product__r.Description;
            resultTemp.Quantity =Integer.valueOf(rsOpp.Quantity__c);
            resultTemp.TrackingNumber =rsOpp.POC_Return__r.Retrun_Tracking_Number__c;
            resultTemp.SerialNumber= rsOpp.Serial_Number__c;
            if(rsOpp.POC_Return__r.Location__c=='EMEA'){
                resultTemp.LocationName ='Amsterdam 2B Refurb Primary';
                resultTemp.ShippingCompanyName ='Ziegler Group';
            }
            if(rsOpp.POC_Return__r.Location__c=='AMERICA'){
                resultTemp.LocationName ='Sacramento 2B Refurb Primary';
                resultTemp.ShippingCompanyName ='Watchpoint';
            
            }
            result.add(resultTemp);
        }
        
        return result;
    }
    
    public String getOrderList() {
        POC_Return__c objReturn = [Select Id, POC_Request__c From POC_Return__c Where id=:PocReturnID LIMIT 1];
        List<String> lstOrderNumbers = new List<String>();
        for( Order objOrder : [Select Id, OrderNumber From Order where POC_Request__c =:objReturn.POC_Request__c ]) {
            lstOrderNumbers.add( objOrder.OrderNumber );
        }
        return String.join(lstOrderNumbers, ',');
    }

    public class responseWrapper {
        
        public String ProductName {get;set;}
        public String Description{get;set;}
        public Integer Quantity{get;set;}
        public String SerialNumber{get;set;}
        public String LocationName {get;set;}
        public String ShippingCompanyName {get;set;}
        public String TrackingNumber {get;set;}
        
        
    }
 
}