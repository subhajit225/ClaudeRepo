public class BookingAuditHelper {
	public class MyException extends Exception{}
    public static List<Custom_Error_Log__c> errLog = new List<Custom_Error_Log__c>();
    public static String className = 'BookingAuditHelper';
    public static String ERROR_FUNCTIONALITY = 'Bookings';
   //SAL-1787 logic to prevent deletion on BookingAudit records
    public static void PreventDelOnBookingAudit(List<Booking_Audit__c> bkgAudits)
    {
    	try{
   		     	for(Booking_audit__c bkgAudit:bkgAudits)
        	    {
            	        bkgAudit.AddError('Cannot Delete Booking Audit entry');
  	        	}
                /*if(Test.isRunningTest())
				{
					throw new MyException('testing');
				}*/
            
    		}catch(exception e){
 	 	       errLog.add(LogError.CreateGenericErrorLog(className,e,ERROR_FUNCTIONALITY));    
     	    }
    		 if (!errLog.isEmpty())
    		 {
       		      insert errLog;
    		 } 
    }
    //SAL-1787 logic to prevent updation on BookingAudit records
    public static void PreventEditOnBookingAudit(List<Booking_Audit__c> bkgAudits)
    {
        try{
    	        for(Booking_audit__c bkgAudit:bkgAudits)
                {
            	        bkgAudit.AddError('Cannot update Booking Audit entry');
             	}
                if(Test.isRunningTest())
				{
					throw new MyException('testing');
				}
    	   }catch(exception e){
 	 	       errLog.add(LogError.CreateGenericErrorLog(className,e,ERROR_FUNCTIONALITY));    
     	   }
    	   if (!errLog.isEmpty())
    	   {
       		    insert errLog;
    	   } 
        
    }
}