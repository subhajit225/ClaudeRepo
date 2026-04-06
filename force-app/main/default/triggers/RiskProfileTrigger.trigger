/*
* @Author       :   Sushant Arora
* @CreatedDate  :   23-09-2024
* @Jira Ticket  :   
* @Description  :   Trigger to assign the change the owner on the basis of Account
* @Handler      :   RiskProfileTriggerHandler.cls
* @TestClass    :   .cls
* -------------------------- @History --------------------------------------------------------------------------------------------
* --------------------------------------------------------------------------------------------------------------------------------
*/
trigger RiskProfileTrigger on Risk_Profile__c (before insert, before update, after update, after insert, after delete) {
    	
    RiskProfileTriggerHandler handler = new RiskProfileTriggerHandler();
    if(Trigger.isBefore){
        if( Trigger.isInsert ){        
            handler.OnBeforeInsert(trigger.New);
        }
        if( Trigger.isUpdate ){        
            handler.OnBeforeUpdate(trigger.New, Trigger.oldMap);
        }
    }
    
    if(Trigger.isAfter){
        if( Trigger.isInsert ){        
            handler.OnAfterInsert(Trigger.newMap, Trigger.oldMap);
        }
        if( Trigger.isUpdate ){            
            handler.OnAfterUpdate(Trigger.new, Trigger.oldMap);
        }
        if( Trigger.isDelete){
            handler.onAfterDelete(Trigger.newMap, Trigger.oldMap);
        }
    }
}