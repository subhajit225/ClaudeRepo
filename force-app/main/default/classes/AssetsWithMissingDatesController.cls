/*
*********************************************************
Apex Class Name    : AssetsWithMissingDatesController
Created Date       : May 10,2024
@description       : This is class is a controller class for VF Page AssetsWithMissingDates
@author            : Abir Chakraborty
Modification Log:
Ver   Date         Author                               Modification
1.0   05-010-2024                Initial Version
*********************************************************
*/
public with sharing class AssetsWithMissingDatesController {
    public Integer pages{get;set;}
    public Integer currentPage{get;set;}
    public  List<string> AccountIDs = new List<string>(); 
    
    
/*
*********************************************************
@Method Name    : AssetsWithMissingDatesController
@description    : This method is a constructor which initializes/sets values to few variables used in VF page.
@param          : N.A
@return         : N.A
********************************************************
*/
    public AssetsWithMissingDatesController(){
    //added for PRDOPS21-84 
        List<RubrikInternalAccounts__c> cstlist = RubrikInternalAccounts__c.getall().values();
        if(cstlist.size()>0){
            for(RubrikInternalAccounts__c cst :cstlist){
                if(cst.Accounts_ID__c!= null){
                    for(String Ids: cst.Accounts_ID__c.split(',')){
                        AccountIDs.add(Ids.trim());
                    }
                }
            }
        }
       
        pages = [Select count() from Asset 
                    where Account.Name != 'Unassigned' and (not Account.Name like '%Rubrik%') and (AccountId not IN :AccountIDs) and Status = 'Purchased' and ((Product2.Name like 'RBK%' and 
                    SerialNumber  like 'AA%') OR Product2.product_level__c = 'Hardware')  and (Support_Start_Date__c = null or Premium_Support_End_Date__c = null) 
                    and product2.Product_Type__c != 'Spares']; 
        pages = Integer.valueOf(Math.ceil(Decimal.valueOf(pages)/200)); 
        currentPage = 1; 
    }

/*********************************************************
@Method Name    : setCon
@description    : This is setter method which sets value to SetCOn Variables which is used to display data in VF table
@param          : N.A
@return         : N.A
********************************************************
*/  
    public ApexPages.StandardSetController setCon {
        get {
            if(setCon == null) {
               List<String> excludedAssetName = Order_control__mdt.getInstance('Missing_Support_Date_Excluded_Products').Values__c.Split(','); 

                setCon = new ApexPages.StandardSetController(Database.getQueryLocator(
                    [Select Id, SerialNumber, Support_Start_Date__c, Premium_Support_End_Date__c, AccountId, Account.Name, 
                    Status, Product2Id, Product2.Name, Order_Service_Item__c, Order_Service_Item__r.OrderItemNumber, 
                    Order_Service_Item__r.OrderId, Order_Service_Item__r.Order.OrderNumber,Description from Asset 
                    where Account.Name != 'Unassigned' and (not Account.Name like '%Rubrik%') and(AccountId not IN :AccountIDs) and Status = 'Purchased' and ((Product2.Name like 'RBK%' and 
                    SerialNumber  like 'AA%') OR Product2.product_level__c = 'Hardware')  and (Support_Start_Date__c = null or Premium_Support_End_Date__c = null) and product2.Name Not In :excludedAssetName
                    and product2.Product_Type__c != 'Spares']));
                setCon.setPageSize(200);
            }
            return setCon;
        }
        set;
    }
    
/*********************************************************
@Method Name    : getAssets
@description    : This is getter method which gets asset list used to display data in VF table
@param          : N.A
@return         : N.A
********************************************************
*/  

    // Initialize setCon and return a list of records
    public List<Asset> getAssets() {
        return (List<Asset>) setCon.getRecords();
    }
    
/*********************************************************
@Method Name    : hasNext
@description    : This is getter method which checks if VF page has Next Page based on current page number and no of pages
@param          : N.A
@return         : N.A
********************************************************
*/  

    public Boolean hasNext  
    {  
        get  
        {  
            return setCon.getHasNext();  
        }  
        set;  
    }
    
/*********************************************************
@Method Name    : hasPrevious
@description    : This is getter method which checks if VF page has previous Page based on current page number and no of pages
@param          : N.A
@return         : N.A
********************************************************
*/     
    public Boolean hasPrevious  
    {  
        get  
        {  
            return setCon.getHasPrevious();  
        }  
        set;  
    } 
/*********************************************************
@Method Name    : hasPrevious
@description    : This is method which set current page value on click of previous button.
@param          : N.A
@return         : N.A
********************************************************
*/    
    public void previous()  
    {  
        currentPage -= 1;
        setCon.previous();  
    }  
/*********************************************************
@Method Name    : hasNext
@description    : This is method which set current page value on click of previous button.
@param          : N.A
@return         : N.A
********************************************************/
    
    public void next()  
    {  
        currentPage += 1;
        setCon.next();  
    }  

}