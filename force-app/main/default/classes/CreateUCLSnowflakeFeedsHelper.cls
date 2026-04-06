public class CreateUCLSnowflakeFeedsHelper {        
@AuraEnabled
    public static String createSnowFlakeFeed(Map<String,String> scaleUtilityOverageRec)  {
        system.debug('scaleUtilityOverageRec @@@@ ' + scaleUtilityOverageRec);
        Snowflake_Feed__c snowFlakeFeedInstance =new Snowflake_Feed__c();
        date today  = System.Today();
        Date currentMonthSnapshotDate  = date.newinstance(today.year(), today.month(),25);
        String snowFlakeId = '';
        if(!scaleUtilityOverageRec.isEmpty()){
            if(scaleUtilityOverageRec.containskey(Constants.SNOWFLAKE_CLUSTERNAME)){
                snowFlakeFeedInstance.Cluster_UUID__c=scaleUtilityOverageRec.get(Constants.SNOWFLAKE_CLUSTERNAME);
            }
            if(scaleUtilityOverageRec.containskey(Constants.SNOWFLAKE_CLUSTERUSAGE)){
                snowFlakeFeedInstance.Cluster_Usage_FETB__c =decimal.valueOf(scaleUtilityOverageRec.get(Constants.SNOWFLAKE_CLUSTERUSAGE));
            }
            snowFlakeFeedInstance.Snapshot_Date__c=currentMonthSnapshotDate;
            if(scaleUtilityOverageRec.containskey(Constants.SNOWFLAKE_Global_Commit)){
                snowFlakeFeedInstance.Global_Commit_ID__c=scaleUtilityOverageRec.get(Constants.SNOWFLAKE_Global_Commit);
            }
            
            if(scaleUtilityOverageRec.containskey(Constants.SNOWFLAKE_AccountID)){
                snowFlakeFeedInstance.Account_ID__c=scaleUtilityOverageRec.get(Constants.SNOWFLAKE_AccountID);
            }
            
            if(scaleUtilityOverageRec.containskey(Constants.SNOWFLAKE_Original_Order)){
                snowFlakeFeedInstance.Original_Order__c=scaleUtilityOverageRec.get(Constants.SNOWFLAKE_Original_Order);
            }
            snowFlakeFeedInstance.Is_UCL__c=true;
            
            snowFlakeFeedInstance.Scale_Utility_Overage_ID__c= scaleUtilityOverageRec.get(Constants.SNOWFLAKE_RECORDID);
            // Set the Type Based on M365 or Regular SU sku for CSU-347
            if(scaleUtilityOverageRec.containskey(Constants.PRODUCT_FIELD_BUNDLETYPE)){
                if(scaleUtilityOverageRec.get(Constants.PRODUCT_FIELD_BUNDLETYPE) == Constants.SNOWFLAKE_TYPE_M365H){
                snowFlakeFeedInstance.Type__c = scaleUtilityOverageRec.get(Constants.PRODUCT_FIELD_BUNDLETYPE); 
                }else{
                snowFlakeFeedInstance.Type__c = Constants.SNOWFLAKE_TYPE_CNP;      
                }
            }
            snowFlakeFeedInstance.Origin__c= Constants.SNOWFLAKE_ORIGIN_SFDC;
            system.debug('snowFlakeFeedInstance  to be inserted ' + snowFlakeFeedInstance);
             insert snowFlakeFeedInstance ;
        	  snowFlakeId = snowFlakeFeedInstance.Id;
        }
        return snowFlakeId;
    }
 
}