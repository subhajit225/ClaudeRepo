/**
 * Author       :   Saakshi Gupta
 * CreatedDate  :   30th July 2020
 * Description  :   To schedule the batch class every 2 hours to process Metadata requests as per CS21-83
 * TestClass    :   ProcessMetadataRequestSchedularTest
 *
 * To schedule this class, execute the following in Developer console.
 *
System.schedule('Process Open Metadata Requests - Class : ProcessMetadataRequestsBatchSchedular', '0 0 0,4,8,12,16,20 ? * *', new ProcessMetadataRequestsBatchSchedular());
*/
global class ProcessMetadataRequestsBatchSchedular implements Schedulable
{
    global void execute(SchedulableContext sc)
    {
        ProcessMetadataRequestsBatch b = new ProcessMetadataRequestsBatch();
        Database.executeBatch(b, 1);
    }
}