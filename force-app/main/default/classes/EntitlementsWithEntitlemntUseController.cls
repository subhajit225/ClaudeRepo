public with sharing class EntitlementsWithEntitlemntUseController {
    //controller for EntitlementsWithNodeAndAsset
    public Integer pages{get;set;}
    public Integer currentPage{get;set;}
    public EntitlementsWithEntitlemntUseController(){
        pages = [Select count() from Entitlement_Use__c where entitlement__r.Account.name='TOTVS S.A.'];
        pages = Integer.valueOf(Math.ceil(Decimal.valueOf(pages)/200));
        currentPage = 1;
    }

    public ApexPages.StandardSetController setCon {
        get {
            if(setCon == null) {
                setCon = new ApexPages.StandardSetController(Database.getQueryLocator(
                    [select Id,serial_number__c, entitlement__r.Product__r.ProductCode,entitlement__r.Order_Service_Item__r.Product_Name__c, entitlement__r.StartDate, entitlement__r.EndDate, node__r.asset__r.Name,node__r.serial_number__c, node__r.chassis__c,entitlement__r.Account.name,entitlement__r.Account.Id,node__r.chassis__r.serial_number__c from Entitlement_Use__c where entitlement__r.Account.name='TOTVS S.A.']));
                setCon.setPageSize(200);
            }
            return setCon;
        }
        set;
    }

    // Initialize setCon and return a list of records
    public List<Entitlement_Use__c> getEntitlements() {
        return (List<Entitlement_Use__c>) setCon.getRecords();
    }

    public Boolean hasNext  
    {  
        get  
        {  
            return setCon.getHasNext();  
        }  
        set;  
    }  
    public Boolean hasPrevious  
    {  
        get  
        {  
            return setCon.getHasPrevious();  
        }  
        set;  
    } 

    public void previous()  
    {  
        currentPage -= 1;
        setCon.previous();  
    }  
    public void next()  
    {  
        currentPage += 1;
        setCon.next();  
    }  
    
}