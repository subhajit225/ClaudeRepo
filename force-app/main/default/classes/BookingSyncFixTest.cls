@isTest 
public class BookingSyncFixTest {
         @testSetup
         public static void setup() {  
          BookingSyncBatchTest.setup();
          TriggerControls.disableQuoteTrigger = true;
          TriggerControls.disableQuoteLineTrigger = true;
         }
          public static testMethod void testBookingMethod() {
            test.startTest(); 
            Booking__c bkg=[SELECT id from Booking__c where Original_Booking__c=NULL LIMIT 1 ];
            set<ID> bkngId= new set<ID>();
            bkngId.add(bkg.Id);
            BookingSyncFix.fixbkngSync(bkngId,Date.today());
            test.stopTest();   
          }
          
          public static testMethod void testBookingMethod2() {
            test.startTest(); 
            Booking__c bkg=[SELECT id from Booking__c where Original_Booking__c=NULL LIMIT 1 ];
            bkg.Field_Update_Status__c=' ';
            update bkg;         
            set<ID> bkngId= new set<ID>();
            bkngId.add(bkg.Id);
            BookingSyncFix.fixbkngSync(bkngId,Date.newInstance(2020,5,2));
            test.stopTest();   
          }
          
          public static testMethod void testBookingMethod3() {
            test.startTest(); 
            Booking__c bkg=[SELECT id from Booking__c where Original_Booking__c=NULL LIMIT 1 ];
            bkg.Field_Update_Status__c='Core Attributes - Frozen';
            update bkg;         
            set<ID> bkngId= new set<ID>();
            bkngId.add(bkg.Id);
            BookingSyncFix.fixbkngSync(bkngId,Date.newInstance(2020,5,5));
            test.stopTest();   
          } 
          
          public static testMethod void testBookingMethod4() {
            test.startTest(); 
            Booking__c bkg=[SELECT id from Booking__c where Original_Booking__c=NULL LIMIT 1 ];
            bkg.Field_Update_Status__c='Core Attributes - Frozen';
            update bkg;         
            set<ID> bkngId= new set<ID>();
            bkngId.add(bkg.Id);
            BookingSyncFix.fixbkngSync(bkngId,Date.newInstance(2020,1,5));
            test.stopTest();   
          }
}