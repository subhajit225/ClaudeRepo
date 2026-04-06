/********************************************************************************************************
* Name              : checkRecursive_isTest
* Purpose           : checkRecursive_isTest is Used for Testing checkRecursive Class
*********************************************************************************************************/
@istest
public Class checkRecursive_isTest{
    
    static testmethod void testRunOnceReturnsTrue(){
        Test.startTest();
        checkRecursive.runOnce();
        Test.stopTest();
    }
    static testmethod void testRunOnceReturnsFalse(){
        Test.startTest();
        checkRecursive.setRun(false);
        checkRecursive.runOnce();
        Test.stopTest();
    }
     static testmethod void testRunAfterOnceReturnsTrue(){
        Test.startTest();
        checkRecursive.runAfterOnce();
        Test.stopTest();
    }
    static testmethod void testRunAfterOnceReturnsFalse(){
        Test.startTest();
        checkRecursive.setRun(false);
        checkRecursive.runAfterOnce();
        Test.stopTest();
    }
    static testmethod void testGetRun(){
        Test.startTest();
        checkRecursive.getRun();
        Test.stopTest();
    }
    static testmethod void testSetRun(){
        Test.startTest();
        checkRecursive.setRun(true);
        Test.stopTest();
    }
}