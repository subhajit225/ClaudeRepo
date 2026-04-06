public class OrderControllerExtension{
    public Opportunity relatedOpp;
    public OrderControllerExtension(ApexPages.StandardController controller)
    {    
        if(apexpages.currentpage().getparameters().get('oppid') != null){
            Id OppId = apexpages.currentpage().getparameters().get('oppid');
            System.debug('controller=='+controller);
            relatedOpp = [select id, name ,AccountId,Account.Name,Account.IOR_Received__c,Partner_Lookup__r.Payment_Term__c, Partner_Lookup__c,Partner_Lookup__r.Name,Partner_Lookup__r.Id,Partner_Lookup__r.ShippingStreet,Partner_Lookup__r.ShippingCity,Partner_Lookup__r.ShippingState,Partner_Lookup__r.ShippingCountry,Partner_Lookup__r.ShippingPostalCode,Partner_Lookup__r.ShippingAddress from opportunity where id=:OppId];
        }
    }
    
    
    public Pagereference pageRedirect()
    { 
        string newId = apexpages.currentpage().getparameters().get('id');
        string shipid=label.ShipId;
        //Pagereference newpage = new Pagereference ('/801/e?Oppid='+relatedOpp.Id+'&accid='+relatedOpp.Account.Name+'&accid_lkid='+relatedOpp.AccountId+'&EffectiveDate='+Date.Today().format()+'&CF00NS0000001QjXu='+relatedOpp.Partner_Lookup__r.Name+'&CF00NS0000001QjXu_lkid='+relatedOpp.Partner_Lookup__r.Id+'&00NS0000001Qjao='+relatedOpp.Partner_Lookup__r.Payment_Term__c+'&opptyid='+relatedOpp.Name+'&opptyid_lkid='+relatedOpp.Id+&Status=Received&'+shipId+'='+relatedOpp.Account.Name+'&'+shipId+'_lkid='+relatedOpp.AccountId+'&saveurl=../../');
        Pagereference newpage = new Pagereference ('/801/e?Oppid='+relatedOpp.Id+'&accid='+relatedOpp.Account.Name+'&accid_lkid='+relatedOpp.AccountId+'&EffectiveDate='+Date.Today().format()+'&CF00NS0000001QjXu='+relatedOpp.Partner_Lookup__r.Name+'&CF00NS0000001QjXu_lkid='+relatedOpp.Partner_Lookup__r.Id+'&00NS0000001Qjao='+relatedOpp.Partner_Lookup__r.Payment_Term__c+'&opptyid='+relatedOpp.Name+'&opptyid_lkid='+relatedOpp.Id+'&Status=Pending&'+shipId+'='+relatedOpp.Account.Name+'&'+shipId+'_lkid='+relatedOpp.AccountId+'&saveURL=/apex/OrderRedirect?oppId='+relatedOpp.Id+'&Id='+newId+'&action=new');
       // Pagereference newpage = new Pagereference ('/801/e?Oppid='+relatedOpp.Id+'&accid='+relatedOpp.Account.Name+'&accid_lkid='+relatedOpp.AccountId+'&EffectiveDate='+Date.Today().format()+'&CF00NS0000001QjXu='+relatedOpp.Partner_Lookup__r.Name+'&CF00NS0000001QjXu_lkid='+relatedOpp.Partner_Lookup__r.Id+'&00NS0000001Qjao='+relatedOpp.Partner_Lookup__r.Payment_Term__c+'&opptyid='+relatedOpp.Name+'&opptyid_lkid='+relatedOpp.Id+'&Status=Received&'+shipId+'='+relatedOpp.Account.Name+'&'+shipId+'_lkid='+relatedOpp.AccountId+'&save_new_url=/'+relatedOpp.id+'&'+shipId+'='+relatedOpp.Account.Name+'&'+shipId+'_lkid='+relatedOpp.AccountId); //+'&ShippingAddresscountry='+relatedOpp.Partner_Lookup__r.ShippingCountry+'&ShippingAddresscity='+relatedOpp.Partner_Lookup__r.ShippingCity+'&ShippingAddressstreet='+relatedOpp.Partner_Lookup__r.Shippingstreet+'&ShippingAddressstate='+relatedOpp.Partner_Lookup__r.ShippingState+'&ShippingAddresszip='+relatedOpp.Partner_Lookup__r.ShippingPostalCode
        //Pagereference newpage = new Pagereference ('/setup/ui/recordtypeselect.jsp?ent=Order&save_new_url=/801/e?Oppid='+relatedOpp.Id+'&accid='+relatedOpp.Account.Name+'&accid_lkid='+relatedOpp.AccountId+'&'+shipId+'='+relatedOpp.Account.Name+'&'+shipId+'_lkid='+relatedOpp.AccountId);
        return newpage;
    }
 
}