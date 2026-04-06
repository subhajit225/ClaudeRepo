public class AssetEntitlementEndDateController {
    public Boolean notificationPanel{get;set;}
    //constructor
    public AssetEntitlementEndDateController() {
        notificationPanel = false;
    }

    public void getReport(){
        Database.executeBatch(new AssetEntitlementEndDateBatch(), 200);
        notificationPanel = true;
    }



}