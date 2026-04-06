/**
 * Author       :   Saakshi Gupta
 * CreatedDate  :   29th May 2020
 * Description  :   To schedule the batch class every 15 minutes to update Employee Time-Off flag on User based on Time-Off
 *                  Dates field updated by Workday as per CS21-22
 * TestClass    :   Workday_UsersOnTimeOffSchedularTest
 *
 * To schedule this class, execute the following in Developer console.
 *
System.schedule('Workday Integration For Employee Time-Off1 - Class : Workday_UsersOnTimeOffSchedular', '0 0 * * * ?', new Workday_UsersOnTimeOffSchedular());
System.schedule('Workday Integration For Employee Time-Off2 - Class : Workday_UsersOnTimeOffSchedular', '0 15 * * * ?', new Workday_UsersOnTimeOffSchedular());
System.schedule('Workday Integration For Employee Time-Off3 - Class : Workday_UsersOnTimeOffSchedular', '0 30 * * * ?', new Workday_UsersOnTimeOffSchedular());
System.schedule('Workday Integration For Employee Time-Off4 - Class : Workday_UsersOnTimeOffSchedular', '0 45 * * * ?', new Workday_UsersOnTimeOffSchedular());
*/
global class Workday_UsersOnTimeOffSchedular implements Schedulable
{
    global void execute(SchedulableContext sc)
    {
        Workday_UserOnTimeOff b = new Workday_UserOnTimeOff();
        Database.executeBatch(b, 200);
    }
}