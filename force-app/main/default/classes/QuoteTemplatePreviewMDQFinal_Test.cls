@isTest
public class QuoteTemplatePreviewMDQFinal_Test {
    @isTest static void testMethod1() {
        TriggerControls.disableQuoteTrigger=true;
        Account acct = new Account(Name='tAccount');
        insert acct;
        
        TriggerControl__c setting = new TriggerControl__c();
        setting.Name = 'Opportunity';
        setting.DisableTrigger__c = true;
        insert setting;
        
        TriggerControl__c objOrderTrigger = new TriggerControl__c(Name = 'Order', Disable_Trigger__c = false, 
                                                                  DisableTrigger__c = true, SendEmail__c = false);
        insert objOrderTrigger;
        TriggerControl__c objAccTrigger = new TriggerControl__c(Name = 'Account', Disable_Trigger__c = false, 
                                                                DisableTrigger__c = true, SendEmail__c = false);
        insert objAccTrigger;
        
        Date closeDt = System.Today()+30;
        Opportunity oppty = new Opportunity(Name = 'Test Opportunity',
                                            StageName = '1. Discovery',
                                            CloseDate = closeDt,
                                            Alliance_Partner_Name__c = 'Amazon',
                                            Alliance_Source_Type_SW__c = 'Rubrik Initiated Alliance Deal',
                                            Alliance_HW_Partner__c = 'Cisco',
                                            Alliance_Source_Type_HW__c = 'Rubrik Initiated Alliance Deal',
                                            Alliance_Source_Type__c = 'Rubrik Initiated Alliance Deal', 
                                            Installation_Assigned_To__c = 'FE Install',
                                            Type = 'Repeat/Upsell Business',
                                            AccountId = acct.Id);
        insert oppty;
        
        
        SBQQ__Quote__c quoteObj = new SBQQ__Quote__c(SBQQ__Opportunity2__c = oppty.Id,
                                                     SBQQ__Primary__c = true,
                                                     SBQQ__SubscriptionTerm__c = 32,Task_Products__c='RBK-DISK-RETENTION');
        insert quoteObj;
        
        Product2 pd1 = new Product2(Name='Pord A',ProductCode='prod_A',isActive=true, Description = 'Consumption MDQ');
        insert pd1;
        Product2 pd2 = new Product2(Name='Pord B Addon',ProductCode='prod_B',isActive=true, Description = 'Add-On');
        insert pd2;
        Product2 pd3 = new Product2(Name='MSP Hardware',ProductCode='MSP_Hardware',isActive=true, Description = 'MSP Hardware Parent');
        insert pd3;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = pd1.Id, UnitPrice = 99, isActive = true);
        insert pbe1;
        PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = pd2.Id, UnitPrice = 100, isActive = true);
        insert pbe2;
        PricebookEntry pbe3 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = pd3.Id, UnitPrice = 500, isActive = true);
        insert pbe3;
        
        SBQQ__QuoteLine__c qlObj=new SBQQ__QuoteLine__c();
        List<SBQQ__QuoteLine__c> lstQuateLines = new List<SBQQ__QuoteLine__c>();
        
        SBQQ__QuoteLine__c qlObjHW = new SBQQ__QuoteLine__c(SBQQ__Product__c = pd2.Id, SBQQ__Quantity__c = 1, SBQQ__ListPrice__c = 500, 
                                                            SBQQ__Description__c = 'MSP Hardware Parent', CPQ_MSP_Sales_Price__c = 5.0, 
                                                            Back_End_Capacity_TB__c = 2,SBQQ__SegmentIndex__c=0, SBQQ__Quote__c = quoteObj.Id);
        insert qlObjHW;
        //insert qlObjHW;
        
        SBQQ__QuoteLine__c qlObj1 = new SBQQ__QuoteLine__c(SBQQ__Product__c = pd1.Id, SBQQ__Quantity__c = 1, SBQQ__ListPrice__c = 99, 
                                                           SBQQ__Description__c = 'Consumption MDQ1',
                                                           CPQ_MSP_Sales_Price__c = 5.0, Back_End_Capacity_TB__c = 4, SBQQ__SegmentLabel__c = 'Quarter 1', 
                                                           SBQQ__SegmentIndex__c = 1, SBQQ__Quote__c = quoteObj.Id, SBQQ__RequiredBy__c = qlObjHW.Id);
        lstQuateLines.add(qlObj1);   
        SBQQ__QuoteLine__c qlObj2 = new SBQQ__QuoteLine__c(SBQQ__Product__c = pd1.Id, SBQQ__Quantity__c = 1, SBQQ__ListPrice__c = 99, 
                                                           SBQQ__Description__c = 'Consumption MDQ2',
                                                           CPQ_MSP_Sales_Price__c = 5.0, Back_End_Capacity_TB__c = 6, SBQQ__SegmentLabel__c = 'Quarter 2', 
                                                           SBQQ__SegmentIndex__c = 2, SBQQ__Quote__c = quoteObj.Id, SBQQ__RequiredBy__c = qlObjHW.Id);
        lstQuateLines.add(qlObj2); 
        
        SBQQ__QuoteLine__c qlObj3 = new SBQQ__QuoteLine__c(SBQQ__Product__c = pd1.Id, SBQQ__Quantity__c = 1, SBQQ__ListPrice__c = 99,
                                                           SBQQ__Description__c = 'Consumption MDQ3',
                                                           CPQ_MSP_Sales_Price__c = 5.0, Back_End_Capacity_TB__c = 17, SBQQ__SegmentLabel__c = 'Quarter 3', 
                                                           SBQQ__SegmentIndex__c = 9, SBQQ__Quote__c = quoteObj.Id, SBQQ__RequiredBy__c = qlObjHW.Id);
        lstQuateLines.add(qlObj3); 
        
        SBQQ__QuoteLine__c qlObj4 = new SBQQ__QuoteLine__c(SBQQ__Product__c = pd1.Id, SBQQ__Quantity__c = 1, SBQQ__ListPrice__c = 99,
                                                           SBQQ__Description__c = 'Consumption MDQ4',
                                                           CPQ_MSP_Sales_Price__c = 5.0, Back_End_Capacity_TB__c = 13,
                                                           SBQQ__SegmentLabel__c = 'Quarter 4', 
                                                           SBQQ__SegmentIndex__c = 4, SBQQ__Quote__c = quoteObj.Id, SBQQ__RequiredBy__c = qlObjHW.Id);
        lstQuateLines.add(qlObj4); 
        
        SBQQ__QuoteLine__c qlObjAddon = new SBQQ__QuoteLine__c(SBQQ__Product__c = pd2.Id, SBQQ__Quantity__c = 1, SBQQ__ListPrice__c = 100, 
                                                               SBQQ__Description__c = 'Add-On', CPQ_MSP_Sales_Price__c = 5.0, Back_End_Capacity_TB__c = 2,
                                                               Feature_Name__c = 'Add-Ons', SBQQ__Quote__c = quoteObj.Id,
                                                               SBQQ__RequiredBy__c = qlObjHW.Id);
        lstQuateLines.add(qlObjAddon);
        insert lstQuateLines;
        
        //SBQQ__Quote__c qObj = [SELECT Id,SBQQ__SubscriptionTerm__c FROM SBQQ__Quote__c WHERE SBQQ__SubscriptionTerm__c = 13 LIMIT 1];
        test.startTest();
        QuoteTemplatePreviewMDQFinal obj =  new QuoteTemplatePreviewMDQFinal();
        PageReference myVfPage = Page.QuoteTemplatePreviewMDQFinalPage;
        Test.setCurrentPage(myVfPage);
        
        // Put Id into the current page Parameters
        ApexPages.currentPage().getParameters().put('qid',quoteObj.Id);
        system.debug('CheckTest'+quoteObj.Id);
        
        List<string> strList = new List<string>();
        strList.add('prodQty');
        strList.add('prodCode');
        obj.defineQuarters(quoteObj.Id);
        
        obj.getMDQLines(quoteObj.Id);
       
        obj.netTotalMDQ = 0;
        obj.strNetTotalMDQ = '';
        obj.strPaymentSchedule = '';
        obj.strPaymentVerbage = '';
        obj.lstPaymentScheduleToDisplay = strList;
        QuoteTemplatePreviewMDQFinal.wrapperQuoteLines checkObj= new QuoteTemplatePreviewMDQFinal.wrapperQuoteLines();
        checkObj.prodQty = 0;
        checkObj.prodTerm = 0;
        checkObj.prodSalesPrice = 0;
        checkObj.prodNetTotal = 0;
        checkObj.prodBackendCapacity = 0;
        checkObj.netTotal = '123';
        checkObj.strProdQty = '12';
        checkObj.strSalesPrice = '12';
        List<QuoteTemplatePreviewMDQFinal.wrapperQuoteLines> lstQuoteLinesToDisplay = new List<QuoteTemplatePreviewMDQFinal.wrapperQuoteLines>();
        lstQuoteLinesToDisplay.add(checkObj);
        obj.lstQuoteLinesToDisplay = lstQuoteLinesToDisplay;
        Set<Integer> setInt = new Set<Integer>();
        obj.setQuarters = setInt;
        test.stopTest();
        
    }
}