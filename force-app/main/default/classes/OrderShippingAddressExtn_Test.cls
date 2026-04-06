/********************************************************************************************************
* Name              : OrderShippingAddressExtn_Test
* Purpose           : OrderShippingAddressExtn_Test is Used for Testing OrderShippingAddressExtn Class
*********************************************************************************************************/
@isTest
public class OrderShippingAddressExtn_Test{ 
    
    public static testMethod void testOrderShippingAddressExtn(){
        testDataFactoryClass.createCustomSettings();
        
        CountryWithCode__c CountrySetting1 = new CountryWithCode__c();
        CountrySetting1.Name = 'United States';
        CountrySetting1.Code__c = 'US';
        insert CountrySetting1;
        
        CountryWithCode__c countrySetting2 = new CountryWithCode__c();
        countrySetting2.Name = 'Canada';
        countrySetting2.Code__c = 'CA';
        insert CountrySetting2;
        
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account acct = new Account(Name='tAccount', RecordTypeId = partnerRecordTypeId);
        insert acct;
        Date closeDt = System.Today()+30;
        
        opportunity oppr = new opportunity(Name='testing DIEtestsalesforce 4/6/2015' ,  AccountId= acct.Id,StageName = '1 Discovery',
                                           CloseDate = closeDt, Lead_Email_Hidden__c='',Installation_Assigned_To__c ='Partner Install', partner_lookup__c=acct.id, Alliance_Partner_Name__c='None', Alliance_Source_Type__c='Alliance Initiated Deal');
        insert oppr;
         
        shipping_Address__C sAddr = new Shipping_Address__C(Account__c = acct.Id,Name='Test 1',Shipping_State__C ='CA',Shipping_Country__c='United States');
        insert sAddr;
        System.debug('sAddr===>'+sAddr);

        Order od = new Order();
        od.AccountId = acct.Id;
        od.OpportunityId =oppr.Id;
        od.EffectiveDate = Date.Today();
        //od.Status = 'PO Received';
        od.Order_Status__c = 'PO Received';
        od.ShippingStreet ='Test Street';
        od.ShippingCity ='Test City';
        od.ShippingState ='California';
        od.ShippingCountry ='United States';
        od.ShippingPostalcode ='94820';
        //od.ship_To_Name__c=acct.id;
        od.Shipping_Address_Label__c = saddr.Name;
        insert od;

        
        Test.startTest();
        

        PageReference pageRef = Page.Order_Shipping_Address;
        Test.setCurrentPage(pageRef);
        ApexPages.Standardcontroller SC = new ApexPages.Standardcontroller(od);
        ApexPages.currentPage().getParameters().put('id',od.id);
        OrderShippingAddressExtn orderExtn = new OrderShippingAddressExtn(sc);
        
        

        orderExtn.setAddress();
        orderExtn.getSAddresses();
        orderExtn.updateOrder();
        orderExtn.closePopup();
        
        orderExtn.selectedAddress=String.ValueOf(sAddr.id);
        
        orderExtn.setAddress();
        orderExtn.getSAddresses();
        orderExtn.updateOrder();
        orderExtn.closePopup();
        
        Test.stopTest();
    }
}