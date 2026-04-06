/**************************************************************************************************
 * @description       : Order Trigger helper logic
 * @author            : 
 * @last modified on  : 06-10-2025
 * @last modified by  : Shrutika
 * Modifications Log
 * Ver   Date          Author        Modification
 * 1.0   06-10-2025   Shrutika        PRDOPS26-982
 ******************************************************************************/

public without sharing class BookingHelper {
    public static DateTime currentTime =DateTime.now(); 
    /**
     * @description MyException
     */
    public class MyException extends Exception{}
    public static List<Custom_Error_Log__c> errLog = new List<Custom_Error_Log__c>();
    public static String className = 'BookingHelper';
    public static String ERROR_FUNCTIONALITY = 'Bookings';
    public static User currentUser = new User();
    public static Boolean insertTransaction = false;
    public static Boolean isTestRunning = Test.isRunningTest();
    public static Boolean bypassBookingValidationRule = false;
    //SAL-1814-Trigger to track all Booking field changes and save the field changes in BookingAudit object
      /**
   * @description SAL-1814-Trigger to track all Booking field changes and save the field changes in BookingAudit object
   * @param bkgList
   * @param oldBkgMap
   */
    public static void TrackBookingChanges(List<Booking__c> bkgList,Map<Id,Booking__c> oldBkgMap)
    {
        try{
           List<Schema.FieldSetMember> trackedFields = SObjectType.Booking__c.FieldSets.Fields_to_track.getFields();
            List<Booking_Audit__c> fieldChanges = new List<Booking_Audit__c>();
            set<id> idsofbooking = new set<id>();
            if (trackedFields.isEmpty()) 
                return;
        
            for (Booking__c newBooking : bkgList) 
            {
                if(newBooking.Net_Bookings_Total__c != oldBkgMap.get(newBooking.Id).Net_Bookings_Total__c)
                {
                    idsofbooking.add(newBooking.Id);
                }
                Booking__c oldBooking = oldBkgMap.get(newBooking.Id);
                for (Schema.FieldSetMember fsm : trackedFields) 
                {
                    String fieldName  = fsm.getFieldPath();
                    String fieldLabel = fsm.getLabel();

                    if (newBooking.get(fieldName) == oldBooking.get(fieldName))
                        continue;

                    String oldValue = String.valueOf(oldBooking.get(fieldName));
                    String newValue = String.valueOf(newBooking.get(fieldName));

                    if (oldValue != null && oldValue.length()>255) 
                         oldValue = oldValue.substring(0,255);

                    if (newValue != null && newValue.length()>255) 
                         newValue = newValue.substring(0,255); 

                    final Booking_Audit__c bookingHistory = new Booking_Audit__c();

                    bookingHistory.Booking_Field__c   = fieldLabel;
                    bookingHistory.Booking_Modified__c = newBooking.Id;
                    bookingHistory.Changed_By__c = UserInfo.getUserId();
                    bookingHistory.Old_Value__c  = oldValue;
                    bookingHistory.New_Value__c  = newValue;
                    bookingHistory.Date_modified__c=currentTime;

                    fieldChanges.add(bookingHistory);
                    /*if(Test.isRunningTest())
                    {
                        throw new MyException('testing');
                    }*/
                }
            }

            if (!fieldChanges.isEmpty()) {
                insert fieldChanges;
                
            }
            
            list<booking_split__c> split = new list<booking_split__c>();
            if(!idsofbooking.isEmpty())
            {
                split = [select id from booking_split__c where Booking__c in : idsofbooking];
            }
            if(!split.isEmpty())
            {
                update split;
            }
        }catch(exception e){
               errLog.add(LogError.CreateGenericErrorLog(className,e,ERROR_FUNCTIONALITY));    
        }
        if (!errLog.isEmpty())
        {
                insert errLog;
        } 
    }
    
     /**
   * @description This method updateBooking
   * @param bkgList
   * @param oldBkgMap
   */
     public static void updateBooking(List<Booking__c> bkgList,Map<Id,Booking__c> oldBkgMap){
       Date bkgEffectivedate ; 
       String fiscalPeriodYear = ' ';
       List<Financial_Year__mdt> financialYearList = Financial_Year__mdt.getAll().values();//[SELECT Quarter__c,Quarter_End_Month__c,Quarter_Start_Month__c FROM Financial_Year__mdt];
       for(Booking__c bkg : bkgList){
          if(bkg.Opportunity_Close_Date__c!=null &&  (oldBkgMap ==null ||  (bkg.recordtypeId ==Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking Adjustment').getRecordTypeId() 
             && oldBkgMap.get(bkg.id).Opportunity_Close_Date__c != bkg.Opportunity_Close_Date__c))){
             // update fiscal quarter
                 bkgEffectivedate = bkg.Opportunity_Close_Date__c;
                 fiscalPeriodYear = String.valueOf(bkgEffectivedate.Month() >= 2 ? bkgEffectivedate.Year()+1 : bkgEffectivedate.Year() ) ;                      
                 for(Financial_Year__mdt fy : financialYearList){
                    if(bkgEffectivedate.Month() >= fy.Quarter_Start_Month__c && bkgEffectivedate.Month() <= fy.Quarter_End_Month__c){
                        bkg.Fiscal_Quarter__c = fy.Quarter__c;                          
                    }else if(bkgEffectivedate.Month() >= 11 || bkgEffectivedate.Month() == 1){
                        bkg.Fiscal_Quarter__c = '4';
                    }
                }                      
                bkg.Fiscal_Period__c='Q'+bkg.Fiscal_Quarter__c+'-'+fiscalPeriodYear;
                bkg.Fiscal_Year__c= string.valueof(fiscalPeriodYear);
            }
       }
       validateBookingUpdatePermissions(bkgList, oldBkgMap);
    }

    /**
   * @description This method checks for the Edit Permissions for Booking added validateBookingUpdatePermissions
   * @param lstNewBKG
   * @param oldBkgMap
   */
  public static void validateBookingUpdatePermissions(List<Booking__c> lstNewBKG, Map<Id,Booking__c> oldBkgMap){
    if(currentUser.Id != UserInfo.getUserId()){
      currentUser = [SELECT Id, User_Type__c, RBAC_Group__c, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    }
    
    Quiddity currentType = Request.getCurrent().getQuiddity();
    Boolean isUserInValidRBACGroup = currentUser.RBAC_Group__c == null || !new List<String>{'IT Prod Ops Support', 'API', 'System - IT'}.contains(currentUser.RBAC_Group__c);
    Boolean isUserOfValidType = currentUser.User_Type__c != 'API' && currentUser.User_Type__c != 'System';
    Boolean isNonSystemTriggeredTransaction = !System.isFuture() && !System.isBatch() && !System.isScheduled() && !System.isQueueable();
    Boolean isRestrictedQuiddity =  (currentType != Quiddity.AURA);
     for (Booking__c sBooking : lstNewBKG) {
        if (isUserInValidRBACGroup && isUserOfValidType && !bypassBookingValidationRule && isNonSystemTriggeredTransaction && isRestrictedQuiddity && !insertTransaction && !isTestRunning) {
          sBooking.addError('You aren’t authorized to edit Booking, hence please create a support ticket with ProdOps Support or email ProdOpsapps@rubrik.com” with details.');
        }
    }
  }
}