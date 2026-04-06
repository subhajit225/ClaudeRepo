public class POCReturnTriggerHelper {
    private static final String UNASSIGNED_AMER = 'Unassigned AMER POC Pool'; 
    private static final String UNASSIGNED_CANADA = 'Unassigned Canada POC Pool'; 
    private static final String UNASSIGNED_APAC = 'Unassigned APAC POC Pool'; 
    private static final String UNASSIGNED_EMEA = 'Unassigned EMEA POC Pool';

    public map<String, String> mapReturntatusWithRequest = new map<String, String> {'Submitted' => 'Return Initiated', 
                                                            'Approved' => 'Return Approved', 
                                                            'Rejected' => 'Return Rejected',
                                                            'Returned' => 'Return Completed'};
	public void updateStatusOnPOCRequest(List<POC_Return__c> newList, Map<Id, POC_Return__c> oldMap){
        List<POC__c> pocRequestList = new List<POC__c>();
        for(POC_Return__c returnRecord: newList){
            if(mapReturntatusWithRequest.containsKey(returnRecord.status__c) 
                && returnRecord.status__c != oldMap.get(returnRecord.Id).status__c) {
                pocRequestList.add(new POC__c(id=returnRecord.POC_Request__c, Approval_Status__c= mapReturntatusWithRequest.get(returnRecord.status__c)))    ;            
            }
        }
        if(!pocRequestList.isEmpty())
            update pocRequestList;
    }
    
    public void checkLocationBeforeApproval(List<POC_Return__c> newList, Map<Id, POC_Return__c> oldMap){
        for(POC_Return__c req : newList){
            if('Approved' == req.Status__c 
                && req.Status__c != oldMap.get(req.Id).Status__c
                && String.isBlank(req.Location__c)
            ){
                req.addError('Please fill the location before approving the return');
            }
        }
    }

    public void checkSelfApprovalBeforeApproval(List<POC_Return__c> newList, Map<Id, POC_Return__c> oldMap){
        for(POC_Return__c newPOCReturn : newList){
            POC_Return__c oldPOCReturn = oldMap.get(newPOCReturn.Id);
            if(newPOCReturn.Status__c != oldPOCReturn.Status__c && newPOCReturn.Status__c == 'Approved' && newPOCReturn.CreatedById == UserInfo.getUserId()){
                newPOCReturn.addError('Operation not permitted. Please contact your manager for assistance.');
            }
        }
    }
    
    public void returnAssets(List<POC_Return__c> newList, Map<Id, POC_Return__c> oldMap){
        List<Id> returnAssets = new List<Id>();
        List<Asset> updateAssets = new List<Asset>();
        Map<String,Id> unassignedNameToId = new Map<String, Id> {
            UNASSIGNED_AMER => null,
            UNASSIGNED_CANADA => null,
            UNASSIGNED_APAC => null,
            UNASSIGNED_EMEA => null
        };
        for(POC_Return__c req : newList){
            if('Returned' == req.Status__c
                && req.Status__c != oldMap.get(req.Id).Status__c
            ){
                returnAssets.add(req.Id);
            }
        }
        
        //query the accounts 
        for(Account acc : [SELECT Id, Name FROM Account WHERE Name IN :unassignedNameToId.keySet()]){
            unassignedNameToId.put(acc.Name, acc.Id);
        }
        for(POC_Return_Item__c retItem : [SELECT Id, Asset__c, POC_Return__r.Location__c, POC_Return__r.Pickup_Required__c, POC_Return__r.Return_to_Rubrik_warehouse__c, POC_Return__r.Delivery_Account__c
                            FROM POC_Return_Item__c 
                            WHERE POC_Return__c IN :returnAssets]){
            Asset asst =  new Asset(Id = retItem.Asset__c);
            if(!retItem.POC_Return__r.Return_to_Rubrik_warehouse__c && retItem.POC_Return__r.Delivery_Account__c!=null){
                //assign to Patner/Disti
                asst.AccountId = retItem.POC_Return__r.Delivery_Account__c;
            }
            else {
                if('America' == retItem.POC_Return__r.Location__c){
                    asst.AccountId = unassignedNameToId.get(UNASSIGNED_AMER);
                }
                else if('Canada' == retItem.POC_Return__r.Location__c){
                    asst.AccountId = unassignedNameToId.get(UNASSIGNED_CANADA);
                }
                else if('APAC' == retItem.POC_Return__r.Location__c){
                    asst.AccountId = unassignedNameToId.get(UNASSIGNED_APAC);
                }
                else if('EMEA' == retItem.POC_Return__r.Location__c){
                    asst.AccountId = unassignedNameToId.get(UNASSIGNED_EMEA);
                }
            }
            asst.POC_Request__c = null;
            asst.Order_Service_Item__c = null;
            asst.InstallDate = null;
            asst.POO_Ship_Date__c = null;
            asst.SE_POC_Expected_Return_Date__c = null;
            asst.SE_POC_Notes__c = null;
            asst.SE_POC_Return_Status__c = null;
            asst.Status = 'POC Unassigned';
            asst.Support_Start_Date__c = null;
            asst.Premium_Support_End_Date__c = null;
            asst.Location__c = null;
            asst.licensed_capacity__c = null;
            updateAssets.add(asst);
        }
        if(!updateAssets.isEmpty())
            update updateAssets;
    }

    public void mapReturnToPOCOrder(List<POC_Return__c> newList){
        Map<Id, Id> mapPOCIdToOrderIds = new Map<Id, Id>();
        for( POC_Return__c objReturn : newList ) {
            if( objReturn.POC_Request__c != null && objReturn.Order__c == null )
            	mapPOCIdToOrderIds.put( objReturn.POC_Request__c, null );
        }
        if( !mapPOCIdToOrderIds.isEmpty() ) {
            for( Order objOrder : [Select Id, POC_Request__c From Order Where POC_Request__c IN:mapPOCIdToOrderIds.keySet() ]) {
                mapPOCIdToOrderIds.put( objOrder.POC_Request__c, objOrder.Id);
            }
            for( POC_Return__c objReturn : newList ) {
                if( mapPOCIdToOrderIds.containsKey(objReturn.POC_Request__c) ) {
                    objReturn.Order__c = mapPOCIdToOrderIds.get(objReturn.POC_Request__c);
                }
            }
        }
    }
}