/**
 * Author       :   Saakshi Gupta
 * CreatedDate  :   29th May 2020
 * Description  :   Test class for Workday_UsersOnTimeOffSchedular
 */
@isTest(SeeAllData = false)
public class Workday_UsersOnTimeOffSchedularTest {
    public static testMethod void testWorkday_UsersOnTimeOffSchedular(){
        Workday_UsersOnTimeOffSchedular ws = new Workday_UsersOnTimeOffSchedular();
        String sch = '0 15 * * * ?';
        System.schedule('Test schedule', sch, ws);
    }
}