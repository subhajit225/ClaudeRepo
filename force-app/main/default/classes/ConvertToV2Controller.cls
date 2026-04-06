public class ConvertToV2Controller { 
    
    SBQQ__Quote__c quote {get; set;}
    
    public ConvertToV2Controller(ApexPages.StandardController sc){
        quote = (SBQQ__Quote__c) sc.getRecord();
    }
    
    public PageReference convert(){
        
        try{
            //check old products are present
            Boolean oldProducts = false;
            for (SBQQ__QuoteLine__c qli : [SELECT SBQQ__Product__r.Product_Level__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c=:quote.Id]){
                if (String.isBlank(qli.SBQQ__Product__r.Product_Level__c)){
                    oldProducts = true;
                }
            }
            
            if (!oldProducts){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, Label.No_Old_Products));
                return null;
            }
            
            //call conversion batch
            Database.executeBatch(new ConvertToSaasRenewalBatch(new List<SBQQ__Quote__c>{quote}));
            
            //return to quote
            PageReference pr = new PageReference('/' + quote.Id);
            pr.setRedirect(true);
            return pr;
        }
        
        catch (Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
        }
        
        return null;
    }
	
}