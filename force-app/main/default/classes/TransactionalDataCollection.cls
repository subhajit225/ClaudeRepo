/*********************************************************
 * @description       : To hold transactional sobject data 
 * @author            : Chaitra
 * @last modified on  : 01-20-2021
 * @last modified by  : Chaitra
 * Modifications Log  
 * Ver   Date          Author        Modification
 * 1.0   01-20-2021    Chaitra        Initial Version
************************************************************/

public class TransactionalDataCollection {
  
  public static List<Opportunity> oppMainList = new List<opportunity>();
  public static List<OrderItem> orderItemMainList = new List<OrderItem>();
  public static List<SBQQ__Quote__c> quoteMainList = new List<SBQQ__Quote__c>();
  public static List<Account> accMainList = new List<Account>();
  public static List<Asset> assetMainList = new List<Asset>();
  public static List<RMA_Order__c> rmaReq = new List<RMA_Order__c>();
  public static List<PO_Stage__c> stagePo = new List<PO_Stage__c>();
  public static Map<id,List<ShipmentDetail__c>> ordIdHWItems = new Map<id,List<ShipmentDetail__c>>();
  public static Map<id, ShipmentDetail__c> quoteIdHWItems = new Map<id, ShipmentDetail__c>();  
  public static List<OrderItem> allOrderItems = new List<OrderItem>(); // Stores all the OrderItem related to the Quote
 
}