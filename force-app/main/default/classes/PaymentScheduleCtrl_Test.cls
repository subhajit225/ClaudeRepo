@isTest
public class PaymentScheduleCtrl_Test {
    private static Map<Integer, String> OPP_STAGENAME_MAP = new Map<Integer, String>{ 4 => '4 Business Justification', 5 => '5 Negotiate & Close', 6 => '6 PO With Channel' };
     static testmethod void testPaymentSchedule(){
        Map<String, Schema.RecordTypeInfo> AcRecTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByName();
            List<Account> accounts = new List<Account>{
                new Account(Name = 'Test Account', RecordTypeId = AcRecTypeInfo.get('Customer/Prospect').getRecordTypeId()),
                new Account(Name = 'Promark Technology, Inc.', Type = 'Distributor', RecordTypeId = AcRecTypeInfo.get('Partner/Distributor').getRecordTypeId())
            };
            insert accounts;
            Id standardPBId = test.getStandardPricebookId();

            Opportunity oppNew = new opportunity();
            oppNew.Name = 'New mAWS Deal Second';
            oppNew.AccountId = accounts[1].Id;
            oppNew.Distributor_Lookup__c = accounts[1].Id;
            oppNew.Partner_Lookup__c = accounts[1].Id;
            oppNew.Aspen_Eligibility__c = 'Proposed non-Aspen';
            oppNew.StageName = '1 Discovery’ stage';
                //OPP_STAGENAME_MAP.get(4);
            oppNew.Pricebook2Id =  standardPBId;
        	oppNew.CloseDate = System.today()+30;
            insert oppNew;
         
         SBQQ__Quote__c quoteSecond = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(
                new SBQQ__Quote__c(),
                new Map<String, Object>{
                    'SBQQ__Account__c' => oppNew.AccountId,
                    'SBQQ__Opportunity2__c' => oppNew.Id,
                    'SBQQ__Primary__c' => true,
                    'SBQQ__SubscriptionTerm__c' => 12,
                    // 'Is_RWD_Polaris_Quote__c' => true,
                    'SBQQ__PaymentTerms__c' => 'Net 45',
                    'SBQQ__Type__c'=> 'Renewal+Expansion'
                    //'SBQQ__NetAmount__c'=> 160000
                }
            );
            insert quoteSecond;
         
         List<Product2> prods = new List<Product2>();
            Product2 newProd = new Product2(
                Name = 'RBK-MSP-R6404S-HW-01',
                ProductCode = 'RBK-MSP-R6404S-HW-01',
                IsActive = true,
                Product_Level__c = 'Hardware'

            );
            prods.add(newProd);
            Product2 newProd2 = new Product2(
                Name = 'RCA-R6KSE-64-N-02',
                ProductCode = 'RBK-MSP-R6404S-HW-01',
                IsActive = true,
                Product_Level__c = 'Hardware'

            );
            prods.add(newProd2);

            Product2 newProd3 = new Product2(
                 Name = 'RCA-DDR4-16',
                ProductCode = 'RCA-DDR4-16',
                IsActive = true,
                Product_Level__c = 'Hardware'

            );
            prods.add(newProd3);

            insert prods;
        
                PriceBookEntry pbEntry = new PriceBookEntry(
                UnitPrice = 400,
                PriceBook2Id = oppNew.PriceBook2Id,
                Product2Id = newProd.Id,
                IsActive = true,
                UseStandardPrice=false);
                insert pbEntry ;
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteSecond.Id, SBQQ__Product__c=newProd.Id, SBQQ__Quantity__c=10, SBQQ__Number__c=1, SBQQ__NetPrice__c = 1328.18, SBQQ__ListPrice__c = 228.00, Payment_Options__c = 'Monthly', SBQQ__SubscriptionTerm__c = 36);  
        qliList.add(qli1);
        SBQQ__QuoteLine__c qli12 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteSecond.Id, SBQQ__Product__c=newProd2.Id, SBQQ__Quantity__c=10, SBQQ__Number__c=1, SBQQ__NetPrice__c = 1500, SBQQ__ListPrice__c = 228.00);  
        qliList.add(qli12);
        SBQQ__QuoteLine__c qli13 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteSecond.Id, SBQQ__Product__c=newProd3.Id, SBQQ__Quantity__c=10, SBQQ__Number__c=1, SBQQ__NetPrice__c = 1800.80, SBQQ__ListPrice__c = 228.00);  
        qliList.add(qli13);
        insert qliList;
         
         Payment_Schedule__c headerSchedule = new Payment_Schedule__c(
                Quote_Line__c = qli1.Id,
                Type__c = 'Header',
                Product__c = qli1.SBQQ__Product__c,
                Quote_Number__c = quoteSecond.Id,
                Quantity__c = String.valueOf(qli1.SBQQ__Quantity__c),
                Unit_List__c = qli1.SBQQ__ListPrice__c,
                Net_Total__c = qli1.SBQQ__NetTotal__c,
                Payment_Option__c = 'Monthly'

            );
         insert headerSchedule;
         List<Payment_Schedule__c> lstPaymentSchedule = new List<Payment_Schedule__c>();
         for (Integer i = 0; i < 36; i++) {
                lstPaymentSchedule.add(new Payment_Schedule__c(
                    payment__c = 0,
                    Override_Amount__c = 0,
                    Quote_Line__c = qli1.Id,
                    Payment_Option__c = 'Monthly',
                    Number_of_Invoices__c = '36',
                    Type__c = 'Line',
                    Product__c = qli1.SBQQ__Product__c,
                    Quote_Number__c = qli1.SBQQ__Quote__c,
                    Parent__c = headerSchedule.Id
                ));
            }
         insert lstPaymentSchedule;
         //String json = '';
         JSONGenerator gen = JSON.createGenerator(true);
        	gen.writeStartObject();
         for(Payment_Schedule__c oPaymentSchedule : lstPaymentSchedule){
             gen.writeNumberField(oPaymentSchedule.Id,1);
         }
         gen.writeEndObject();
         String sJSON = gen.getAsString();
         JSONGenerator gen1 = JSON.createGenerator(true);
         gen1.writeStartObject();
         for(Payment_Schedule__c oPaymentSchedule : lstPaymentSchedule){
         gen1.writeNumberField(oPaymentSchedule.Id, 49248);
         }
         gen1.writeEndObject();
         String sOverrideamount = gen1.getAsString();
         
         JSONGenerator gen2 = JSON.createGenerator(true);
         gen2.writeStartObject();
         for(Payment_Schedule__c oPaymentSchedule : lstPaymentSchedule){
         gen2.writeNumberField(oPaymentSchedule.Id, 49248);
         }
         gen2.writeEndObject();
         String sMonthlyAmount = gen2.getAsString();
         
         test.startTest();
         PaymentScheduleCtrl.getRelatedQuoteLines(quoteSecond.Id);
         PaymentScheduleCtrl.createPayment(quoteSecond.Id, 36, 'Monthly');
         PaymentScheduleCtrl.updateStatus(new List<Id>{qli1.Id},'Approved');
         PaymentScheduleCtrl.updatePaymentAmount(sJSON, sOverrideamount, sMonthlyAmount);
         PaymentScheduleCtrl.createPayment(quoteSecond.Id, null, 'Monthly');
         PaymentScheduleCtrl.updatePaymentAmount(null, sOverrideamount, sMonthlyAmount);
         test.stopTest();
    }    

}