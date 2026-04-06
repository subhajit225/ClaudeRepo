@isTest(SeeAllData=false)
public with sharing class GenericFiveMinutesSchedularTest {
    @IsTest
    static void methodName(){
        
        Test.startTest();
        GenericFiveMinutesSchedular sch1 = new GenericFiveMinutesSchedular();
        String sch = '0 0 * * * ?';
        system.schedule('Test GenericFiveMinutesSchedular', sch, sch1);
        Test.stopTest();
        
    }
}