/*******************************************************************************************************************
* @description       : Proccessed autobooked Orders only 1day of each Quarter 
* @author            : Shrutika
* @last modified on  : 06-19-2025
* @last modified by  : Shrutika
* @Job Run   :: This job runs in every quarter of 1st day to booked the Orders of current quarter which is having only Hold code ''
********************************************************************************************************************/
public class BookedOrdersPerQuarterBatch implements Database.batchable<sObject>, Database.stateful {
  @TestVisible
  private Date currentDate = date.Today();
  private Date QuarterStartDate;
  private Date QuarterEndDate;

  public List<Custom_Error_Log__c> errLog = new List<Custom_Error_Log__c>();
  public final string className = 'BookedOrderPerQuarterBatch';
  public string ERROR_FUNCTIONALITY = 'Booked Orders';
  public final List<Financial_Year__mdt> quarterMap = Financial_Year__mdt.getAll().values(); 
  public String currentQuarter = ' ';

	/**
   * @description start method
   * @param bc
   * @return list of Orders which are on Hold
   */
  public Database.QueryLocator start(Database.BatchableContext bc) {
      
       for (Financial_Year__mdt fy : quarterMap) {
          //Get current Quarter details
          if (currentDate.Month() >= fy.Quarter_Start_Month__c && currentDate.Month() <= fy.Quarter_End_Month__c) {
            currentQuarter = fy.Quarter__c;
            if (currentQuarter != '1') {
              QuarterStartDate = Date.NewInstance(currentDate.Year(), fy.Quarter_Start_Month__c.intValue(), 1);
              QuarterEndDate = Date.NewInstance(currentDate.Year(), fy.Quarter_End_Month__c.IntValue(), 31);
            } else {
              QuarterStartDate = Date.NewInstance(currentDate.Year(), fy.Quarter_Start_Month__c.intValue(), 1);
              QuarterEndDate = Date.NewInstance(currentDate.Year(), fy.Quarter_End_Month__c.IntValue(), 30);
            }
          } else if (currentDate.Month() >= 11) {
            currentQuarter = '4';
            QuarterStartDate = Date.NewInstance(currentDate.Year(), 11, 1);
            QuarterEndDate = Date.NewInstance(currentDate.Year() + 1, 1, 31);
          } else if (currentDate.Month() == 1) {
            currentQuarter = '4';
            QuarterStartDate = Date.NewInstance(currentDate.Year() - 1, 11, 1);
            QuarterEndDate = Date.NewInstance(currentDate.Year(), 1, 31);
          }
        }

    String finalQuery = 'SELECT Id, customer_required_ship_date__c, Internal_Order_Stage__c, Hold_Code__c FROM Order WHERE customer_required_ship_date__c != null AND Order_Status__c = \'On Hold\' AND Hold_Code__c includes (\''+Constants.ORDER_CRSD_HOLD_CODE+'\') AND  (customer_required_ship_date__c >= :QuarterStartDate AND customer_required_ship_date__c <= :QuarterEndDate)  ';
	
    return Database.getQueryLocator(finalQuery);
  }
  /**
   * @description execute method
   * @param bc
   * @param scope
   */
  public void execute(Database.BatchableContext bc, List<Order> scope) {
    List<Order> lstUpdateOrders = new List<Order>();
    String ErrorMessage = '';
    String UnProcessedRecord = '';
    try{
        for(Order objOrder : scope){
        if(objOrder.Hold_Code__c == Constants.ORDER_CRSD_HOLD_CODE){
			lstUpdateOrders.add(new Order(Id = objOrder.Id, Hold_Code__c = null, Order_Status__c = 'Pending',Internal_Order_Stage__c = 'Pending Validation'));
        }
        }
      
      if(!lstUpdateOrders.isEmpty()){
         Database.saveResult[] updateOrderRecords = Database.update(lstUpdateOrders, false);
         
        // Iterate through each returned result
        for (Integer i = 0; i < updateOrderRecords.size(); i++) {
          if (!updateOrderRecords[i].isSuccess()) {
            //only look at failures, or NOT Successes
            for (Database.Error err : updateOrderRecords[i].getErrors()) {
              ErrorMessage += err.getFields() + '::' + err.getMessage() + ',';
            }
            UnProcessedRecord += lstUpdateOrders[i].Id + ',';
           errLog.add(LogError.CreateDMLErrorLog(className, 'Error with Updating Orders::' + UnProcessedRecord, ErrorMessage, ERROR_FUNCTIONALITY));
          } 
        }
      }
      }Catch(Exception ex){
          errLog.add(LogError.CreateGenericErrorLog(className, ex, ERROR_FUNCTIONALITY));
      }
  }
  
  /**
  * @description Finish method
  * @param BC
  */
  public void finish(Database.BatchableContext BC) {
    system.debug(logginglevel.DEBUG,'BC');
  }
}