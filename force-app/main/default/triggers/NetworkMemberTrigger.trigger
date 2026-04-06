/**
* @Author       :   Saakshi Gupta
* @CreatedDate  :   08-08-2022
* @Jira Ticket  :   CS21-1100 - Forums 2.0 Rewards Redemption/Swag Store
* @Description  :   Trigger on NetworkMember object.
* @TestClass    :   NetworkMemberTriggerHandlerTest
*/
trigger NetworkMemberTrigger on NetworkMember (after update) {
    if(Trigger.isAfter){
        if(Trigger.isUpdate){
            NetworkMemberTriggerHandler.updateUserCoins(Trigger.new, Trigger.oldMap);
        }
    }
}