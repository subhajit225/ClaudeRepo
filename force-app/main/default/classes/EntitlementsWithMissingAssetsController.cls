public with sharing class EntitlementsWithMissingAssetsController {

	public Integer pages{get;set;}
	public Integer currentPage{get;set;}
    private List<String> lstProductName{get;set;} 
    private List<String> lstProdsExclude{get;set;}
    private List<String> lstAccountsExclude{get;set;}
    
	public EntitlementsWithMissingAssetsController(){
        
        lstProdsExclude = Order_control__mdt.getInstance('Exclude_Products').Value__c.split(',');
        lstAccountsExclude = Order_control__mdt.getInstance('Exclude_Accounts').Value__c.split(',');

        String productName = Label.Product_Name_for_Report.deleteWhitespace();
        lstProductName = productName.split(',');

		pages = [SELECT count() FROM Entitlement 
                    WHERE AssetId = null AND Product__r.Product_Type__c != 'Training' AND Entitlement_Status__c != 'Expired'
                        AND(
                            (   
                                Order_Service_Item__r.Order.Is_RWD_Polaris_Quote__c = false
                                AND(
                                    (   Product__r.Category__c ='Support' 
                                        OR Product__r.Product_Subtype__c IN ('GO','Rubrik Promo','Saas Cloud') 
                                        OR Product__r.Product_Type__c ='NFR'
                                    )
                                    OR(
                                        Product__r.Product_Level__c = 'Hybrid Software'
                                        AND (Product__r.Product_Subtype__c = 'SaaS Cloud' OR Product__r.Product_Type__c IN ('Complete','Complete Elite','Complete Pro') 
                                            OR Product__r.Family = 'Third Party License')
                                    )
                                    OR(
                                        Product__r.Product_Level__c = 'On Prem' AND  Product__r.Product_Type__c IN ('Foundation Edition','Business Edition','Enterprise Edition')
                                    ) 
                                    OR Product__r.Product_Level__c = 'LOD Software'
                                )
                            )
                            OR(
                                Order_Service_Item__r.Order.Is_RWD_Polaris_Quote__c = true 
                                AND(
                                    (Product__r.Product_Type__c  = 'HW Support' AND Product__r.Product_Level__c = 'Support')
                                    OR  
                                    (Product__r.Product_Type__c  = 'RCDM Support' AND Product__r.Product_Level__c = 'Support')
                                )
                            )
                        ) 
                        AND Name NOT IN : lstProductName
                        AND Order_Service_Item__r.Order.Type != 'POC' 
                        AND (NOT(Product__r.Product_Type__c  = 'NFR' AND Product__r.Product_Subtype__c  = 'RCDM' )) 
                        AND (Product__r.Family not in ('CEM', 'Dell', 'HPE', 'UCS','ASE'))
                        AND Product__r.Id NOT IN :lstProdsExclude
                        AND AccountId NOT IN :lstAccountsExclude
                        AND ( Order_Service_Item__r.Required_by_Product_Code__c  != null AND ( Order_Service_Item__r.SBQQ__QuoteLine__r.Required_By_Product_Code__c != null 
                            OR (  Order_Service_Item__r.SBQQ__QuoteLine__r.Required_By_Product_Code__c = null 
                                AND( Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__ProductOption__r.SBQQ__ConfiguredSKU__r.Product_Type__c != 'Add-On Node' OR Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__ProductOption__r.SBQQ__ConfiguredSKU__r.Appliance_Model__c = null OR Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__ProductOption__r.SBQQ__ConfiguredSKU__r.Item_Type__c = 'Serialized Inventory Item')
                            )
                        ))
                        ];
		pages = Integer.valueOf(Math.ceil(Decimal.valueOf(pages)/200));
		currentPage = 1;
	}

	public ApexPages.StandardSetController setCon {
        get {
            if(setCon == null) {
                setCon = new ApexPages.StandardSetController(Database.getQueryLocator(
                    [SELECT CreatedDate, Id, Name, Order_Service_Item__r.OrderItemNumber, Order_Service_Item__c, 
						StartDate, EndDate, Order_Service_Item__r.Order.OrderNumber,   Order_Service_Item__r.OrderId, 
                     	Order_Service_Item__r.Order.ProcessType__c, Order_Service_Item__r.Order.SD_Status__c
						FROM  Entitlement 
                        WHERE AssetId = null AND Product__r.Product_Type__c != 'Training' AND Entitlement_Status__c != 'Expired'
                        AND(
                            (   
                                Order_Service_Item__r.Order.Is_RWD_Polaris_Quote__c = false
                                AND(
                                    (   Product__r.Category__c ='Support' 
                                        OR Product__r.Product_Subtype__c IN ('GO','Rubrik Promo','Saas Cloud') 
                                        OR Product__r.Product_Type__c ='NFR'
                                    )
                                    OR(
                                        Product__r.Product_Level__c = 'Hybrid Software'
                                        AND (Product__r.Product_Subtype__c = 'SaaS Cloud' OR Product__r.Product_Type__c IN ('Complete','Complete Elite','Complete Pro') 
                                            OR Product__r.Family = 'Third Party License')
                                    )
                                    OR(
                                        Product__r.Product_Level__c = 'On Prem' AND  Product__r.Product_Type__c IN ('Foundation Edition','Business Edition','Enterprise Edition')
                                    ) 
                                    OR Product__r.Product_Level__c = 'LOD Software'
                                )
                            )
                            OR(
                                Order_Service_Item__r.Order.Is_RWD_Polaris_Quote__c = true 
                                AND(
                                    (Product__r.Product_Type__c  = 'HW Support' AND Product__r.Product_Level__c = 'Support')
                                    OR  
                                    (Product__r.Product_Type__c  = 'RCDM Support' AND Product__r.Product_Level__c = 'Support')
                                )
                            )
                        ) 
                        AND Name NOT IN : lstProductName
                        AND Order_Service_Item__r.Order.Type != 'POC' 
                        AND (NOT(Product__r.Product_Type__c  = 'NFR' AND Product__r.Product_Subtype__c  = 'RCDM' )) 
                        AND (Product__r.Family not in ('CEM', 'Dell', 'HPE', 'UCS','ASE'))
                        AND Product__r.Id NOT IN :lstProdsExclude
                        AND AccountId NOT IN :lstAccountsExclude
                        AND (Order_Service_Item__r.Required_by_Product_Code__c  != null   
                        AND 
                        (   Order_Service_Item__r.SBQQ__QuoteLine__r.Required_By_Product_Code__c != null 
                            OR 
                            (   Order_Service_Item__r.SBQQ__QuoteLine__r.Required_By_Product_Code__c = null 
                                AND
                                (
                                    Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__ProductOption__r.SBQQ__ConfiguredSKU__r.Product_Type__c != 'Add-On Node' 
                                    OR Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__ProductOption__r.SBQQ__ConfiguredSKU__r.Appliance_Model__c = null
                                    OR Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__ProductOption__r.SBQQ__ConfiguredSKU__r.Item_Type__c = 'Serialized Inventory Item'
                                )
                            )
                        )    
                    )
                    ORDER BY CreatedDate desc]));
                setCon.setPageSize(200);
            }
            return setCon;
        }
        set;
    }

    // Initialize setCon and return a list of recordss
    public List<Entitlement> getEntitlements() {
        return (List<Entitlement>) setCon.getRecords();
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