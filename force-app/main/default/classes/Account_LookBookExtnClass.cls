public class Account_LookBookExtnClass {
    public Look_Book__c lookbook{get;set;}
    public boolean noContent{get;set;}
    public Account_LookBookExtnClass(ApexPages.StandardController controller) {
        try{
            string accountId = apexpages.currentpage().getparameters().get('id').escapeHtml4();
            noContent=false;
            fetchCustomSettingValues(accountId);
        }catch(Exception ex){
            system.debug('Exception Occured  '+ex);
        }
        
    }
    
    public void fetchCustomSettingValues(string accountId){
        
        lookbook = Look_Book__c.getValues(accountId);
        if(lookbook != null){
        String myCCVal = lookbook.Asset_Label__c;
        system.debug('lookbook--'+myCCVal);
        }
        else
           noContent= true; 
    }
    
}