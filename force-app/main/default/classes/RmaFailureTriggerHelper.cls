/* RmaFailureTriggerHelper-  class is created for Failure Main PRDOPS21-102 */
public class RmaFailureTriggerHelper {
    public static void ProcessRmaFailedRecords(List<Failure__c> EditedfailuerRecord, Map<Id, Failure__c> oldFailRecordMap){
        Map<String,string> ReceivedSerialNoAndNode = New Map<String,string>(); 
        Map<String,string> ReceivedSerialNoAndDrive = New Map<String,string>();
        Map<String,string> ReceivedSerialNoAndChassis = New Map<String,string>();
        Map<String,string> ReceivedSerialNoAndPSU = New Map<String,string>();
        Map<String,string> ReceivedSerialNoAndMemory = New Map<String,string>();
    
        for(Failure__c FailRecorddata :EditedfailuerRecord){
            Failure__c oldFailRecord = oldFailRecordMap.get( FailRecorddata.Id);
            if(FailRecorddata.Serial_Number_Received__c != null && ((oldFailRecord.Serial_Number_Received__c == null) ||((FailRecorddata.Serial_Number_Received__c !=oldFailRecord.Serial_Number_Received__c)) ) ){
                if(FailRecorddata.Component_Type__c=='Node' && FailRecorddata.Node__c != null ){   
                    ReceivedSerialNoAndNode.put(FailRecorddata.Serial_Number_Received__c,FailRecorddata.Node__c);
                }
                if(FailRecorddata.Component_Type__c=='Drive' && FailRecorddata.Drive__c != null ){
                    ReceivedSerialNoAndDrive.put(FailRecorddata.Serial_Number_Received__c,FailRecorddata.Drive__c);
                }
                if(FailRecorddata.Component_Type__c=='Chassis' && FailRecorddata.Chassis__c != null ){
                    ReceivedSerialNoAndChassis.put(FailRecorddata.Serial_Number_Received__c,FailRecorddata.Chassis__c);
                }
                if(FailRecorddata.Component_Type__c=='Power Supply' && FailRecorddata.Power_Supply__c != null ){
                    ReceivedSerialNoAndPSU.put(FailRecorddata.Serial_Number_Received__c,FailRecorddata.Power_Supply__c);
                }
                if(FailRecorddata.Component_Type__c=='Memory' && FailRecorddata.Memory__c != null ){
                    ReceivedSerialNoAndMemory.put(FailRecorddata.Serial_Number_Received__c,FailRecorddata.Memory__c);
                }
            }
        }
        if(!ReceivedSerialNoAndNode.isEmpty()){
            List<Node__c> NodetoDisassociate = new List<Node__c>();
            for(Node__c oldNode: [select Id,serial_number__c,name,chassis__c,asset__c,cluster__c from Node__c where serial_number__c IN :ReceivedSerialNoAndNode.keySet()]){
                if(ReceivedSerialNoAndNode.containsKey(oldNode.serial_number__c )){
                    if(String.isNotBlank(oldNode.cluster__c) || String.isNotBlank(oldNode.asset__c) ||String.isNotBlank(oldNode.chassis__c)  ){
                        oldNode.cluster__c=null;
                        oldNode.asset__c=null;
                        oldNode.chassis__c=null;
                        NodetoDisassociate.add(oldNode);
                    }
                }
            }
            if(NodetoDisassociate.size()>0){
                update NodetoDisassociate;
            }
    
        }
        if(!ReceivedSerialNoAndDrive.isEmpty()){  
            List<Drive__c> drivetoDisassociate = new List<Drive__c>();
            for(Drive__c olddrive: [select Id,serial_number__c,Name,node__c,asset__c ,type__c, capacity__c from Drive__c where serial_number__c IN :ReceivedSerialNoAndDrive.keySet()]){
                if(ReceivedSerialNoAndDrive.containsKey(olddrive.serial_number__c) ){
                    if(String.isNotBlank(olddrive.node__c) || String.isNotBlank(olddrive.asset__c) ){
                        olddrive.node__c=null;
                        olddrive.asset__c=null;
                        drivetoDisassociate.add(olddrive);
                    }
                }
            }
            if(drivetoDisassociate.size()>0){
                System.debug('drivetoDisassociate'+drivetoDisassociate);
                update drivetoDisassociate;
            }
        }
        // Added for Chassis Dis association
        if(!ReceivedSerialNoAndChassis.isEmpty()){
            List<Chassis__c> ChassistoDisassociate = new List<Chassis__c>();
            for(Chassis__c oldchassis: [select Id,serial_number__c,name,asset__c from Chassis__c where serial_number__c IN :ReceivedSerialNoAndChassis.keySet()]){
                if(ReceivedSerialNoAndChassis.containsKey(oldchassis.serial_number__c )){
                    if(String.isNotBlank(oldchassis.asset__c) ){ 
                        oldchassis.asset__c=null;
                        ChassistoDisassociate.add(oldchassis);
                    }
                }
            }
            if(ChassistoDisassociate.size()>0){
                    update ChassistoDisassociate;
            }
        }
        //Added for PSU Dis-association
        if(!ReceivedSerialNoAndPSU.isEmpty()){
            List<Power_Supply__c> PSUtoDisassociate = new List<Power_Supply__c>();
            for(Power_Supply__c oldpsu: [select Id,serial_number__c,name,asset__c from Power_Supply__c where serial_number__c IN :ReceivedSerialNoAndPSU.keySet()]){
                if(ReceivedSerialNoAndPSU.containsKey(oldpsu.serial_number__c)){
                    if(String.isNotBlank(oldpsu.asset__c) ){ 
                        oldpsu.asset__c=null;
                        PSUtoDisassociate.add(oldpsu);
                    }
                }
            }
            if(PSUtoDisassociate.size()>0){
                    update PSUtoDisassociate;
            } 
        }
        // Added for Memory Dis-association
        if(!ReceivedSerialNoAndMemory.isEmpty()){
            List<Memory__c> MemorytoDisassociate = new List<Memory__c>();
            for(Memory__c oldmem: [select Id,serial_number__c,name,asset__c,node__c from Memory__c where serial_number__c IN :ReceivedSerialNoAndMemory.keySet()]){
                if(ReceivedSerialNoAndMemory.containsKey(oldmem.serial_number__c)){
                    if(String.isNotBlank(oldmem.asset__c) || String.isNotBlank(oldmem.node__c) ){ 
                        oldmem.asset__c=null;
                        oldmem.node__c=null;
                        MemorytoDisassociate.add(oldmem);
                    }
                }
            }
            if(MemorytoDisassociate.size()>0){
                update MemorytoDisassociate;
            }
        }
    
        //end
    
    }
 }