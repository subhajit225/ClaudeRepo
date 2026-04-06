public class BookingSyncFix 
{
 
    
        public static void fixbkngSync(set<Id> bkngSet, Date curDate)
        {
            Date currentDate = curDate; //system.Today();
            Date currentDateTemp;
            Date QuarterStartDate;
            Date QuarterEndDate; 
            List<Custom_Error_Log__c> errLog = new List<Custom_Error_Log__c>();
            DateTime currentTime =DateTime.now();
            string className = 'BookingSyncBatch';
            string ERROR_FUNCTIONALITY = 'Bookings';
            String selectedBookingRecordType = 'Booking';
            String selectedBookingStatus = 'Core Attributes - Frozen';
            List<Booking_Sync_Mapping__mdt> bookingSyncMapsList =[SELECT Booking_Field_name__c, Opportunity_Field_Name__c,Type__c,
                                                                       (SELECT Booking_API_Name__c,Operator__c,Booking_Value__c FROM ConfigureBookingSyncs__r LIMIT 1000)
                                                                       FROM Booking_Sync_Mapping__mdt LIMIT 1000]; 
            String currentQuarter = ' ';
            Integer currentQuarterNextMonth = 0;
            String bookingCreatedQuarter = ' ';
            Date quarterEndPlusDay1;
            Date quarterEndPlusDay5;
            Map<Booking__c,List<Booking__c>> mapOfIdAndBookings= new Map<Booking__c,List<Booking__c>>();
            string currentDateTimeAMPMcheck=  Integer.ValueOf( string.valueOf(DateTime.Now()).subString ( 11, 13 ) ) < 12 ? 'AM': 'PM'; 
                                                                       
            List<Financial_Year__mdt> quarterMap = Financial_Year__mdt.getAll().values(); 
            List<Booking__c> scope = [Select  SDR_Led__c , Opportunity__r.SDR_Led__c , Original_Lead_Owner__c , Opportunity__r.OriginalLeadOwner__c , Sales_Engineer__c , Opportunity__r.Rubrik_Sales_Engineer__c , Opportunity_Owner_Employee_ID__c , Opportunity__r.Owner.EmployeeNumber , OwnerId , Opportunity__r.OwnerId , Partner_Name__c , Opportunity__r.Partner_Lookup__c , Renewal_Opportunity_Owner__c , Opportunity__r.RenewalOwner__c , Strategic_Account__c , Opportunity__r.Strategic_Account__c , Alliance_HW_Partner__c , Opportunity__r.Alliance_HW_Partner__c , Opportunity_Type__c , Opportunity__r.Opportunity_Type__c , Opportunity_Close_Date__c , Opportunity__r.CloseDate , Fed_SI_Partner_Lookup__c , Secondary_Owner__c , Opportunity__r.SecondaryOwner__c , Opportunity_Sub_Type__c , Opportunity__r.Opportunity_Sub_Type__c , Deal_Registration_Type__c , Opportunity__r.Deal_Registration_Type__c , ISR_SDR_Oppty_Credit_Total_c__c , Opportunity__r.ISR_SDR_Oppty_Credit_Total__c , Order_PO_Accepted_Time_Stamp__c , Order__r.Order_Accepted_Timestamp__c , Opportunity_Split__c , Opportunity__r.split__c , R2K__c , Opportunity__r.Account.R2K_All__c , SE_Misaligned__c , Opportunity__r.SE_Misaligned__c , Alliance_Partner_Name__c , Opportunity__r.Alliance_Partner_Name__c ,id,Field_Update_Status__c,CreatedDate,BookingName__c,Opportunity__c,(select id ,Field_Update_Status__c, SDR_Led__c , Original_Lead_Owner__c , Sales_Engineer__c , Opportunity_Owner_Employee_ID__c , OwnerId , Partner_Name__c , Renewal_Opportunity_Owner__c , Strategic_Account__c , Alliance_HW_Partner__c , Opportunity_Type__c , Opportunity_Close_Date__c , Fed_SI_Partner_Lookup__c , Secondary_Owner__c , Opportunity_Sub_Type__c , Deal_Registration_Type__c , ISR_SDR_Oppty_Credit_Total_c__c , Order_PO_Accepted_Time_Stamp__c , Opportunity_Split__c , R2K__c , SE_Misaligned__c , Alliance_Partner_Name__c from BookingAdjustments__r) FROM Booking__c where  ID in : bkngSet];
        
            List<Booking__c> bookingsToBeUpdated = new List<Booking__c>(); 
            
            List<Booking__c> adjustmentsToBeUpdated = new List<Booking__c>(); 
            string ErrorMessage ='';
            string UnProcessedRecord ='';
            string ErrorMessageAdj ='';
            string UnProcessedAdj ='';
            Set<Id> SuccessBookingupdateIdSet=new Set<Id>();
            List<string> splitOppField = new list<string>();
            // PRDOPS23-284 - Prashant
            set<id> ProcessedOppIds=new set<id>();
            List<Booking_Split__c> bkgSplits= new List< Booking_Split__c>();
            
            
            try{
                if(!scope.isEmpty())
                {   


                     if(!quarterMap.isEmpty())
                        { 
                            //Current date is falling between QuarteEnd plus 1 to 5 days, still we should force the current date to be in previous quarter
                            if( (currentDate >= Date.NewInstance(currentDate.Year(),2,1) && currentDate < Date.NewInstance(currentDate.Year(),2,5)) ||
                               (currentDate >= Date.NewInstance(currentDate.Year(),5,1) && currentDate < Date.NewInstance(currentDate.Year(),5,5)) ||
                               (currentDate >= Date.NewInstance(currentDate.Year(),8,1) && currentDate < Date.NewInstance(currentDate.Year(),8,5)) ||
                               (currentDate >= Date.NewInstance(currentDate.Year(),11,1) && currentDate < Date.NewInstance(currentDate.Year(),11,5))||
                               (currentDate > Date.NewInstance(currentDate.Year(),2,1) && currentDate <= Date.NewInstance(currentDate.Year(),2,5)) ||
                               (currentDate > Date.NewInstance(currentDate.Year(),5,1) && currentDate <= Date.NewInstance(currentDate.Year(),5,5)) ||
                               (currentDate > Date.NewInstance(currentDate.Year(),8,1) && currentDate <= Date.NewInstance(currentDate.Year(),8,5)) ||
                               (currentDate > Date.NewInstance(currentDate.Year(),11,1) && currentDate <= Date.NewInstance(currentDate.Year(),11,5))
                              ){
                                  currentDateTemp=currentDate.addDays(-6);
                              }else{
                                  currentDateTemp=currentDate;
                              }
                            system.debug('AS-->currentDateTemp'+currentDateTemp+' currentDate'+currentDate);
                            
                            for(Financial_Year__mdt fy : quarterMap)
                            {
                                //Get current Quarter details
                                if( currentDateTemp.Month() >= fy.Quarter_Start_Month__c && currentDateTemp.Month() <= fy.Quarter_End_Month__c)
                                {
                                    currentQuarter = fy.Quarter__c;    
                                    if(currentQuarter != '1'){
                                            QuarterStartDate = Date.NewInstance(currentDateTemp.Year(),fy.Quarter_Start_Month__c.intValue(),1);
                                        QuarterEndDate =  Date.NewInstance(currentDateTemp.Year(),fy.Quarter_End_Month__c.IntValue(),31);  
                                    }else{
                                        QuarterStartDate = Date.NewInstance(currentDateTemp.Year(),fy.Quarter_Start_Month__c.intValue(),1);
                                        QuarterEndDate =  Date.NewInstance(currentDateTemp.Year(),fy.Quarter_End_Month__c.IntValue(),30); 
                                    }         
                                }else if(currentDateTemp.Month() >= 11 || currentDateTemp.Month() == 1){
                                    currentQuarter = '4';
                                    QuarterStartDate = Date.NewInstance(currentDateTemp.Year()-1,11,1);
                                    QuarterEndDate =  Date.NewInstance(currentDateTemp.Year(),1,31); 
                                }
                            }  
                            quarterEndPlusDay1=QuarterEndDate.addDays(1);
                            quarterEndPlusDay5=QuarterEndDate.addDays(5);
                        }
                        
                        
                    for(Booking__c bkg : scope)
                    {
                        //Get Booking Created Quarter Details
                        if(!quarterMap.isEmpty()){
                            for(Financial_Year__mdt fy : quarterMap)
                            {
                                if( bkg.CreatedDate.Month() >= fy.Quarter_Start_Month__c && bkg.CreatedDate.Month() <= fy.Quarter_End_Month__c)
                                {
                                    bookingCreatedQuarter = fy.Quarter__c;    
                                }else if( bkg.CreatedDate.Month() >= 11 || bkg.CreatedDate.Month() == 1){
                                    bookingCreatedQuarter = '4';
                                }
                            }
                        }
                        system.debug('AS-->bookingCreatedQuarter'+bookingCreatedQuarter);
                        Booking__c bookingRecord =new Booking__c(id=bkg.id);
                        if(!bookingSyncMapsList.isEmpty()){
                            for(Booking_Sync_Mapping__mdt bookingMap : bookingSyncMapsList)
                            {                                      
                                //Booking_Audit__c bkgAudit = new Booking_Audit__c(); 
                                splitOppField = bookingMap.Opportunity_Field_Name__c.split('\\.');
                                sObject bkgSobj = bkg;
                                for (Integer i = 0; i < (splitOppField.size() - 1) && bkgSobj != null; i++)
                                {
                                    if (bkgSobj.getSObject(splitOppField[i]) == null)
                                    {
                                        bkgSobj = null;
                                        break;
                                    }                     
                                    bkgSobj = bkgSobj.getSObject(splitOppField[i]);
                                }
                                //if current date is < Quarter End+2 days and BookingStatus is NULL, update all Attributes
                                system.debug('AS-->currentDate'+currentDate+'AS-->quarterEndPlusDay1'+quarterEndPlusDay1);
                                if( currentDate <= quarterEndPlusDay1 )
                                {
                                    //Update all Core and Commisionalbe fields if BookingStatus is NULL
                                    if(String.isBlank(bkg.Field_Update_Status__c))
                                    {
                                        if (bkgSobj != null && bkgSobj.get(splitOppField.get(splitOppField.size() - 1)) != null)
                                        {             
                                            if(bkg.get(bookingMap.Booking_Field_name__c) != bkgSobj.get(splitOppField.get(splitOppField.size() - 1))){  
                                                bookingRecord.put(bookingMap.Booking_Field_name__c, bkgSobj.get(splitOppField.get(splitOppField.size() - 1)));
                                            }
                                        }  
                                    }
                                    // PRDOPS23-284 - Prashant
                                    
                                    ProcessedOppIds.add(bkg.Opportunity__c);
                          //If current date is > Quarter End+2NDday && < QuarterEnd+5THday update only commissionalble attributes and update Booking status to 'Complte Freeze' on QEnd+day5
                                }else if(currentDate > quarterEndPlusDay1 && currentDate <= quarterEndPlusDay5){
                                    //Update all Commissionable fields if BookingStatus is CoreFreeze
                                    if(bkg.Field_Update_Status__c == 'Core Attributes - Frozen' && bookingMap.Type__c == 'Commissionable Attribute')
                                    {
                                        if (bkgSobj != null && bkgSobj.get(splitOppField.get(splitOppField.size() - 1)) != null)
                                        {        
                                            if(bkg.get(bookingMap.Booking_Field_name__c) != bkgSobj.get(splitOppField.get(splitOppField.size() - 1))){  
                                                bookingRecord.put(bookingMap.Booking_Field_name__c, bkgSobj.get(splitOppField.get(splitOppField.size() - 1)));
                                            }
                                        } 
                                        bookingRecord.Field_Update_Status__c = bkg.Field_Update_Status__c;                                                                                                                                                           
                                        
                                    }
                                    
                                }
                            }
                            //If Current Date is Quarter End plus SECOND day
                            if(currentDate == quarterEndPlusDay1 && currentDateTimeAMPMcheck =='PM' && String.isBlank(bkg.Field_Update_Status__c))
                            {                                           
                                //Update  Bookings Status to CoreFreeze from NULL
                                bookingRecord.Field_Update_Status__c = 'Core Attributes - Frozen'; 
                            }
                            
                            //If Current Date is Quarter End plus FIFTH day 
                            if( currentDate == quarterEndPlusDay5 && currentDateTimeAMPMcheck =='PM' && bkg.Field_Update_Status__c == 'Core Attributes - Frozen')
                            {
                                bookingRecord.Field_Update_Status__c = 'Freeze Completed'; 
                                
                            }   
                        } 
                        
                        bookingsToBeUpdated.add(bookingRecord);
                        if(!bkg.BookingAdjustments__r.isEmpty())
                            mapOfIdAndBookings.put(bookingRecord,bkg.BookingAdjustments__r);
                    }
                }
                
                //Update Bookings and capture success Ids/Error message
                if(!bookingsToBeUpdated.isEmpty())
                {
                    system.debug('AS-->bookingsToBeUpdated'+bookingsToBeUpdated);
                    Database.saveResult[] bkgupdateSR = Database.update(bookingsToBeUpdated, false);
                    // Iterate through each returned result
                    for(Integer i=0;i<bkgupdateSR.size();i++)
                    {
                        if(!bkgupdateSR[i].isSuccess())
                        {
                            //only look at failures, or NOT Successes
                            for(Database.Error err : bkgupdateSR[i].getErrors())
                            {
                                ErrorMessage += err.getFields()+'::'+err.getMessage() +',';
                            }
                            UnProcessedRecord+= bookingsToBeUpdated[i].BookingName__c+',';
                        }else{
                            SuccessBookingupdateIdSet.add(bkgupdateSR[i].getId());
                        }
                    }                                                     
                }
                // PRDOPS23-284 - Prashant
                if(!ProcessedOppIds.isEmpty()){
                    List<Booking_Split__c> splitToDelete = new List<Booking_Split__c>(); 
                    Map<Id,List<booking_split__c>> getSplit = new Map<Id,List<booking_split__c>>();
                    Map<Id,Id> bookingSplitWithOpportunity = new Map<Id,Id>();
                    Map<id,Opportunity> oppMap = new Map<id,Opportunity>([select id,Name,ETM_Theatre__c,ETM_Area__c,ETM_Region__c,ETM_Territory__c,split__c,Opportunity_Split_Parent__c,amount,Split_percentage__c,Split_Amount__c,OwnerId,(Select Id,Opportunity__c,Opportunity_Split__c,Sales_Rep__c,Theatre__c,Area__c,Region__c,Territory__c from booking_splits__r ), 
                                                                          (select id,Name,Split_percentage__c,Split_Amount__c,split__c,amount,ETM_Theatre__c,ETM_Area__c,ETM_Region__c,Opportunity_Split_Parent__c,ETM_Territory__c,OwnerId from Split_Opportunities__r) from Opportunity where id IN : ProcessedOppIds OR Opportunity_Split_Parent__c IN : ProcessedOppIds]);
                    Set<Id> splitOpptId = new Set<Id>();
                    List<Booking_Split__c> listToBeDeleted = new List<Booking_Split__c>();
                    for(Booking__c bkg:[select id,Opportunity__c,Opportunity__r.Opportunity_Split_Parent__c,
                                        (Select Id,Opportunity__c,Sales_Rep__c,Opportunity_Split__c,Theatre__c,Area__c,Region__c,Territory__c,Opportunity__r.Opportunity_Split_Parent__c from Booking_Splits__r)
                                        from booking__c where  id IN : SuccessBookingupdateIdSet]){
                                            if(oppMap.containsKey(bkg.Opportunity__c)){
                                                Opportunity opp = oppMap.get(bkg.Opportunity__c);
                                                if(bkg.Booking_Splits__r.size() > 0){
                                                    for(Booking_Split__c sb : bkg.Booking_Splits__r){
                                                      // Logic If Split opportunity is Deleted then Delete Booking Split
                                                        if(sb.Opportunity__c == null){
                                                            listToBeDeleted.add(sb);
                                                        }
                                                      // Logic If opportunity Has changed field values then Update Booking Split  
                                                        if(oppMap.containskey(sb.Opportunity__c)){
                                                            Opportunity opptyOnBs = oppMap.get(sb.Opportunity__c);
                                                            Decimal splitPercentage;
                                                            //removed if block of assigment of 100 when Split_percentage__c is null by Deep for PRODOPS24-844
                                                            if(sb.Opportunity_Split__c!=opptyOnBs.Split_percentage__c && opptyOnBs.Split_percentage__c!=null){
                                                                splitPercentage = opptyOnBs.Split_percentage__c;
                                                            } 
                                                            if(splitPercentage!=null || sb.Sales_Rep__c!= opptyOnBs.OwnerId || sb.Theatre__c!=opptyOnBs.ETM_Theatre__c || sb.Area__c!=opptyOnBs.ETM_Area__c || sb.Region__c!=opptyOnBs.ETM_Region__c || sb.Territory__c!=opptyOnBs.ETM_Territory__c){
                                                                bkgSplits.add(new Booking_split__c(Opportunity_Split__c = splitPercentage,Sales_Rep__c = opptyOnBs.OwnerId,Theatre__c = opptyOnBs.ETM_Theatre__c,Area__c = opptyOnBs.ETM_Area__c,Region__c = opptyOnBs.ETM_Region__c,Territory__c = opptyOnBs.ETM_Territory__c,Id = sb.Id));
                                                            }
                                                        }
                                                    }
                                                }
                                                if(oppMap.containskey(opp.Id) && oppMap.get(opp.Id).booking_splits__r.size() == 0){
                                                    Booking_Split__c bkgChildSplit = new Booking_Split__c();
                                                    bkgChildSplit = getBookingSplit(bkg.id,opp);
                                                    bkgSplits.add(bkgChildSplit); 
                                               }
                                                    // Logic If Split Opportunity Has No Child Booking Split then create one.
                                                    for(Opportunity spliopp : opp.Split_Opportunities__r){
                                                        if(spliopp.Opportunity_Split_Parent__c!=null){
                                                            if(oppMap.containskey(spliopp.id) && oppMap.get(spliopp.Id).booking_splits__r.size() == 0){
                                                                Booking_Split__c bkgChildSplit = new Booking_Split__c();
                                                                bkgChildSplit = getBookingSplit(bkg.id,spliopp);
                                                                bkgSplits.add(bkgChildSplit); 
                                                            }
                                                        }
                                                    }
                                            }
                                        }
                    
                    if(!bkgSplits.isEmpty()){
                        database.upsert(bkgSplits,false);
                    }
                    if(!listToBeDeleted.isEmpty()){
                        database.delete(listToBeDeleted,false);
                    }
                }
                // end PRDOPS23-284
                
                
                
                
                system.debug('AS__>SuccessBookingupdateIdSet'+SuccessBookingupdateIdSet);
                //Update Adjustments for successfully updated Bookings
                if( !SuccessBookingupdateIdSet.isEmpty()){
                    for(Booking__c bkg : mapOfIdAndBookings.keySet()){
                        if(SuccessBookingupdateIdSet.contains(bkg.Id)  && !mapOfIdAndBookings.get(bkg).isEmpty() ){
                            for(Booking__c adjustment : mapOfIdAndBookings.get(bkg)){
                                Booking__c adjBooking=new Booking__c(Id=adjustment.id);
                                if(!bookingSyncMapsList.isEmpty()){
                                    for(Booking_Sync_Mapping__mdt bookingMap : bookingSyncMapsList)
                                    {                                                                              
                                        if(bkg.get(bookingMap.Booking_Field_name__c) != NULL && adjustment.get(bookingMap.Booking_Field_name__c) != bkg.get(bookingMap.Booking_Field_name__c)  )
                                        {                                                       
                                            adjBooking.put(bookingMap.Booking_Field_name__c , bkg.get(bookingMap.Booking_Field_name__c)); 
                                        }
                                        
                                    }
                                    if(adjustment.Field_Update_Status__c != bkg.Field_Update_Status__c )
                                    {                                     
                                        adjBooking.Field_Update_Status__c=bkg.Field_Update_Status__c; 
                                    }         
                                } 
                                adjustmentsToBeUpdated.add(adjBooking);
                            } 
                        }                   
                    }
                }
                
                
                //Update Adjustments and capture error details if any
                if(!adjustmentsToBeUpdated.isEmpty())
                {
                    system.debug('AS-->adjustmentsToBeUpdated'+adjustmentsToBeUpdated);
                    Database.saveResult[] bkgAdjupdateSR = Database.update(adjustmentsToBeUpdated, false);
                    // Iterate through each returned result
                    for(Integer i=0;i<bkgAdjupdateSR.size();i++)
                    {
                        if(!bkgAdjupdateSR[i].isSuccess())
                        {
                            //only look at failures, or NOT Successes
                            for(Database.Error err : bkgAdjupdateSR[i].getErrors())
                            {
                                ErrorMessageAdj += err.getFields()+'::'+err.getMessage() +',';
                            }
                            UnProcessedAdj+= adjustmentsToBeUpdated[i].BookingName__c+',';
                        }
                    }                                                     
                }
                if(String.isNotBlank(UnProcessedRecord))
                {
                    if(UnProcessedRecord.length()>255)
                        UnProcessedRecord = UnProcessedRecord.substring(0,255);
                    if(ErrorMessage.length()>131072)
                        ErrorMessage = ErrorMessage.substring(0,131072);
                    errLog.add(LogError.CreateDMLErrorLog(className,'Error with Updating Bookings::'+UnProcessedRecord,ErrorMessage,ERROR_FUNCTIONALITY));
                } 
                
                if(String.isNotBlank(UnProcessedAdj))
                {            
                    if(UnProcessedAdj.length()>255)
                        UnProcessedAdj = UnProcessedAdj.substring(0,255);
                    if(ErrorMessage.length()>131072)
                        ErrorMessage = ErrorMessage.substring(0,131072);
                    errLog.add(LogError.CreateDMLErrorLog(className,'Error with Updating Adjustments::'+UnProcessedAdj,ErrorMessageAdj,ERROR_FUNCTIONALITY));
                } 
                
            }catch(Exception e){
                system.debug('AS-->exception is'+e);
                errLog.add(LogError.CreateGenericErrorLog(className, e,ERROR_FUNCTIONALITY));
                system.debug('AS-->exception added to errlog is'+errLog);
            }
        }
        
          public static Booking_Split__c getBookingSplit( Id bookingId,Opportunity oppty){
        Booking_Split__c bkgChildSplit = new Booking_Split__c();
        bkgChildSplit.Booking__c = bookingId;
        bkgChildSplit.Sales_Rep__c = oppty.OwnerId;
        if(oppty.Split_percentage__c!= null){
            bkgChildSplit.Opportunity_Split__c = oppty.Split_percentage__c;
        }
        bkgChildSplit.Theatre__c = oppty.ETM_Theatre__c;
        bkgChildSplit.Area__c = oppty.ETM_Area__c;
        bkgChildSplit.Region__c = oppty.ETM_Region__c;
        bkgChildSplit.Territory__c = oppty.ETM_Territory__c; 
        bkgChildSplit.Opportunity__c = oppty.id;
        return bkgChildSplit;
    }
    
}