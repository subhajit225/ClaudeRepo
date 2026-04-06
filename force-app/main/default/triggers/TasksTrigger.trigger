/** 
* @Author      :  
* @Description : 
* @Handler     : UpdatingSupportManager
* @TestClass   : UpdatingSupportManagerTest
* -------------------------- @History -------------------------------------
* Story Number       Modified By              Date           Description
* CS21-1923        Vijay Kumar K R        Oct 10 2023      Escalation Task assignment - Not in CSE queue or OPEN
* -------------------------------------------------------------------------
*/ 
trigger TasksTrigger on Tasks__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new UpdatingSupportManager().run(); 
}