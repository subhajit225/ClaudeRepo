/*******************************************************************************
 * @description       : PreviousTransRefWrapper to maintain wrapper details for
 * 						Orderitem Previous_Transaction_Reference__c field
 * @created on        : 25-03-2025
 * @created by        : Naveen S
 * @Test class 		  : OrderItemServiceTests
 * *****************************************************************************
 * History
 * Date                Modification           Author
 * 25-03-2025          FY25SR-1067            naveenkumar.selvaraj@rubrik.com
 *******************************************************************************
 */
public class PreviousTransRefWrapper {
  public Id orderItemId;
  public Decimal orderItemRemainingQuantity;
  public Id entId;
  public Decimal usedEntitlementQuantity;
  public Id phantomOrderItemId;
  public List<RelatedInactiveEntitlement> relatedInactiveEntitlements;
  public String orderNumber;
  public Boolean isMisMatched;

  /***************************************** *******************************************
      @description  Enhanced PreviousTransRefWrapper constructor method to set field values including new attributes.
      @param  OItmId --> OrderitemId
      @param OIleftQty -> remaining Qty,
      @param  entId --> orgEnt Id
      @param  usedEntQty --> Replaced Qty
      @param  phtmOid --> Previous Phantom orderItem id
      @param  relatedInactiveEnts --> List of related inactive entitlements
      @param  orderNum --> Order number
      @param  isMisMatchedFlag --> Boolean indicating if there's a mismatch
      Output : Sets the values for all fields including new attributes
    ***************************************************************************************/
  public PreviousTransRefWrapper(
    Id OItmId,
    Decimal OIleftQty,
    Id entId,
    Decimal usedEntQty,
    Id phtmOid,
    List<RelatedInactiveEntitlement> relatedInactiveEnts,
    String orderNum,
    Boolean isMisMatchedFlag
  ) {
    this.orderItemId = OItmId;
    this.orderItemRemainingQuantity = OIleftQty;
    this.entId = entId;
    this.usedEntitlementQuantity = usedEntQty;
    this.phantomOrderItemId = phtmOid;
    this.relatedInactiveEntitlements = relatedInactiveEnts;
    this.orderNumber = orderNum;
    this.isMisMatched = isMisMatchedFlag;
  }

  /***************************************** *******************************************  
      @description : To deserialize the QLI Replacement json. 
      @param jsonString -> qli json string
      @return List<PreviousTransRefWrapper> deserialized wrapper. 
    ***************************************************************************************/
  public static List<PreviousTransRefWrapper> deserializeJSON(String jsonString) {
    return (List<PreviousTransRefWrapper>) JSON.deserialize(jsonString, List<PreviousTransRefWrapper>.class);
  }
  /***************************************** *******************************************
      @description  Inner class to represent related inactive entitlements
    **************************************************************************************/
  public class RelatedInactiveEntitlement {
    public Id entitlementId;
    public Decimal remainingOrderItemQuantity;
    public Decimal usedEntitlementQuantity;
    public Id orderItemId;
    public String orderNumber;
    public RelatedInactiveEntitlement(Id entId, Decimal remainingQty, Decimal usedQty, Id orderItmId, String orderNum) {
      this.entitlementId = entId;
      this.remainingOrderItemQuantity = remainingQty;
      this.usedEntitlementQuantity = usedQty;
      this.orderItemId = orderItmId;
      this.orderNumber = orderNum;
    }
  }
  /****************************************************************
   *@description Inner Class used to deserialize Phantom Order Previous
   * transaction reference
   ****************************************************************/
  public class PhantomPrevLineDetail {
    public Id orderItemId;
    public Id entId;
    public Id phantomOrderItemId;
  }

  /****************************************************************
   *@description Inner Class used for creating phantom orderItems
   ****************************************************************/
  public class ReplacementLines {
    public set<string> replOrds = new Set<string>();
    public Map<String, PreviousTransRefWrapper> preOIDetails = new Map<String, PreviousTransRefWrapper>();
    public Boolean SubmitOrd = false;
  }
}