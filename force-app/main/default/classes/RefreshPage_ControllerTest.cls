/**
 * @author Paritosh
 * @Date Created/Modified: 12/03/25
 * @description Test class for RefreshPage_Controller
 */
@isTest
public with sharing class RefreshPage_ControllerTest {
    
    /**
     * @description test method get target skus
     */
    @isTest
    public static void getEligibleProducts() {
        List<Product2> productsInsert = new List<Product2>();

        Product2 hwR7 = new Product2(Name='RH-7412-02',ProductCode = 'RH-7412-02' ,
            IsActive=true, Quotable_Date__c = Date.newInstance(2004, 11, 11),
            RWD_Hardware_Family__c = ReplacementConstants.PRODUCTCODE_R7000, 
            Family=ReplacementConstants.PRODUCTCODE_R7000, 
            Product_Type__c=ReplacementConstants.HARDWARE, 
            Refresh_Eligibility__c = 'Eligible for Refresh target'); 
        productsInsert.add(hwR7);

        Product2 hwR6V2 = new Product2(Name='RH-6403-02',ProductCode = 'RH-6403-02' ,
            IsActive=true, Quotable_Date__c = Date.newInstance(2004, 11, 11),
            RWD_Hardware_Family__c = ReplacementConstants.PRODUCTCODE_R6000, 
            Family=ReplacementConstants.PRODUCTCODE_R6000, 
            Product_Type__c=ReplacementConstants.HARDWARE, 
            Refresh_Eligibility__c = 'Eligible for R7 hardware refresh combos'); 
        productsInsert.add(hwR6V2);

        Product2 hwR6V1 = new Product2(Name='RBK-R6410-01',ProductCode = 'RBK-R6410-01' ,
            IsActive=true, Quotable_Date__c = Date.newInstance(2004, 11, 11),
            RWD_Hardware_Family__c = ReplacementConstants.PRODUCTCODE_R6000, 
            Family=ReplacementConstants.PRODUCTCODE_R6000, 
            Product_Type__c=ReplacementConstants.HARDWARE, 
            Refresh_Eligibility__c = 'Eligible for Like to Like R7 HW refresh'); 
        productsInsert.add(hwR6V1);

        insert productsInsert;

        User runAsUser = new User(Id = UserInfo.getUserId());

        Test.startTest();
        System.runAs(runAsUser){
            List<Product2> productsResult = RefreshPage_Controller.getEligibleProducts();
            System.assertEquals(true, productsResult.size() > 0, 'Excepted Products');

            //Test exception
            RefreshPage_Controller.REPLACEMENT_REFRESH_ELIGIBLE_SKU_QUERY_MDT = null;
            try{
                RefreshPage_Controller.getEligibleProducts();
            }
            catch(Exception e){
                system.debug(System.LoggingLevel.DEBUG, e.getMessage());
            }
            
        }
        Test.stopTest();
    }
}