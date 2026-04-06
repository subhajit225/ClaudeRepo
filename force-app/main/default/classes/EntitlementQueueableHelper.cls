/**************************************************************************************************
 * @description       : Depreciated EntitlementQueueableHelper  class as PRDOPS26-287
 * @last modified on  : 11-03-2025
 * @last modified by  : Prashant Kumar
 ******************************************************************************/

public class EntitlementQueueableHelper implements Queueable{
   /* List<Id> entIds = new List<Id>();
    public EntitlementQueueableHelper(List<Id> lstEntIDs){
        this.entIds = lstEntIDs;
    }*/
    
    /**
    * @author Prashant Kumar
    * @date 11-03-2025
    * @description Execute Logic For  EntitlementQueueableHelper but this is commented as part of PRDOPS26-287  
    * @param context
    */
    public void execute(QueueableContext context) {
        system.debug(LoggingLevel.DEBUG, 'logic si deppreciated');
       // populatePriorEntitlement(List < Id > entIds ) 
      /* System.debug('Inside populatePriorEntitlement');
        List<Entitlement> entList = new List<Entitlement>();
        List<Entitlement> InitialCLIEnt = new List<Entitlement>();
        List<Entitlement> toUpdateList = new List<Entitlement>();
        List<Entitlement> recordsToUpdateList = new List<Entitlement>();
        set<Id> CLIEntToBeFilled = new set<Id>();
        set<Id> assignedEnt = new Set<Id>(); 
        Map<Id, List<Entitlement>> InitialCLIEntMap = new Map<Id, List<Entitlement>>();
        
        entList = [select Id,PriorCLIId__c,AssetId,ContractLineItemId,ContractLineItem.Quantity,isAssigned__c FROM Entitlement Where Id IN: entIds];
        
        for(Entitlement et : entList){
            if(et.PriorCLIId__c != null){
                CLIEntToBeFilled.add(et.PriorCLIId__c);
            }
        }
        System.debug('CLIEntMap '+CLIEntToBeFilled.size());
            
        if(!CLIEntToBeFilled.isEmpty()){
            InitialCLIEnt = [Select Id, Name, AssetId,ContractLineItemId,ContractLineItem.Quantity,isAssigned__c,ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__Product__r.SBQQSC__EntitlementConversion__c FROM Entitlement WHERE ContractLineItemId IN: CLIEntToBeFilled];
            for(Entitlement obj : InitialCLIEnt){
                if(InitialCLIEntMap.containsKey(obj.ContractLineItemId)){
                    List<Entitlement> PreEntList = InitialCLIEntMap.get(obj.ContractLineItemId);
                    PreEntList.add(obj);
                    InitialCLIEntMap.put(obj.ContractLineItemId,PreEntList);                    
                }else{
                    List<Entitlement> InEntList = new List<Entitlement>();
                    InEntList.add(obj);
                    InitialCLIEntMap.put(obj.ContractLineItemId,InEntList);
                }
            }           
            System.debug('InitialCLIEntMap '+InitialCLIEntMap.size());
            
            for(Entitlement ent: entList ){
                if(InitialCLIEntMap.containsKey(ent.PriorCLIId__c)){
                    for(Entitlement entL : InitialCLIEntMap.get(ent.PriorCLIId__c)){
                        if(entL.ContractLineItem.Quantity > 1 && entL.AssetId != null){
                            if(entL.AssetId == ent.AssetId){
                                system.debug('1st Match');
                                ent.Prior_Entitlement__c = entL.Id;
                                recordsToUpdateList.add(ent);                               
                            }   
                        }else if(entL.ContractLineItem.Quantity > 1 && entL.AssetId == null){
                            system.debug('2nd Match');
                            if(entL.ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__Product__r.SBQQSC__EntitlementConversion__c == 'One per unit'){
                                if(entL.isAssigned__c == false){
                                    ent.Prior_Entitlement__c = entL.Id;
                                    entL.isAssigned__c = true;
                                    toUpdateList.add(entL);
                                    recordsToUpdateList.add(ent);
                                break;
                            }
                            }else if(entL.ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__Product__r.SBQQSC__EntitlementConversion__c == 'One per quote line'){
                                ent.Prior_Entitlement__c = entL.Id;  
                                recordsToUpdateList.add(ent);                               
                            }                           
                        }else{
                            system.debug('3rd Match');
                            ent.Prior_Entitlement__c = entL.Id;
                            recordsToUpdateList.add(ent);
                        }
                    }
                }
            }
            
        //ARY-596 - as part of this ticket. it should be commented.   
        if(!toUpdateList.isEmpty()){
            //update toUpdateList;
        }
        if(!recordsToUpdateList.isEmpty()){
            //update recordsToUpdateList;
        }
        
       }*/
    }
    /*public static void testCoverage(){
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }*/
    

}