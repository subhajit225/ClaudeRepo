/**
 * @description Amount based class
 */
public class CreateBLIorBLIwithBooking{  
    
    public static List<Booking_Line_Item__c> bliTobeInserted = new List<Booking_Line_Item__c>();
    public static List<Opportunity> debookingOppsToBeInserted = new List<Opportunity>();
    public static final string ERROR_FUNCTIONALITY = 'Bookings';  
    public static Date currentDate = Date.Today();
    public static Map<Id,CCR__c> MapOfccrIdAndCCRrecord=new Map<Id,CCR__c>();
    public static Map<ID,Decimal> mapOfCCRIdAndOriginalOrdAmount=new Map<Id,Decimal>();
    public static List<Custom_Error_Log__c> errLog = new List<Custom_Error_Log__c>();
    public static final string className ='CreateBLIorBLIwithBooking';  
    public static List<BLI_Impact__mdt> BLIimpactList = BLI_Impact__mdt.getAll().values();         
    public static string ErrorMessage ='';
    public static string UnProcessedRecord ='';
    public static Set<Id> SuccessBookingInsertIdSet=new Set<Id>();
    public static Set<Id> SuccessBookingLineInsertIdSet=new Set<Id>();
    public static Set<Id> SuccessOpportunityInsertIdSet=new Set<Id>();
    public static Set<Id> SuccessCCRUpdateIdSet=new Set<Id>();
    private static Map<Id,Id> CCRIdBkgId = new Map<Id,Id>();
    private static Map<Id, Opportunity> mapCCRIdToDebookOpp = new Map<Id, Opportunity>();
    private static map<Id, Id> mapBkgIdToCCRId = new Map<Id, Id>();
    private static map<Id, Id> mapDebookBkgIdToOrgBkgId = new Map<Id, Id>();
    private static Map<Id,Booking_Line_Item__c> mapCCROrignalRebate = new Map<Id,Booking_Line_Item__c>();
    @TestVisible
    private static Map<Id, Booking_Line_Item__c> mapCCROppIdToOriginalPRF = new Map<Id, Booking_Line_Item__c>();
    private static map<Id, List<Booking_Line_Item__c>> mapBkgIdToRevenueDebookBLI = new Map<Id, List<Booking_Line_Item__c>>();
    private static Map<Id,Decimal> origOppIdReferalFee = new Map<Id,Decimal>(); // hold original oppids and its PRF which had completed debooking
    private static Map<Id, Opportunity> mapOrigOppIdToOrigOpp = new Map<Id, Opportunity>(); // hold original Opp Id and its record. 
    @TestVisible
    private static Map<Id, Id> mapBookingIdToOppId = new Map<Id, Id>();
    //This method invoked from Process Builder when CCR is Approved
    /**
     * @description createBLIorBLIwithBkg
     * @param CCRs
     */
    public static void createBLIorBLIwithBkg(List<CCR__c> CCRs){
        try{
            //Collect Financial year quarter record details from custom metadata
            BookingHelper.bypassBookingValidationRule = true;
            List<Financial_Year__mdt> quarterMap = Financial_Year__mdt.getAll().values();
            List<Booking__c> newDebookingsList = new List<Booking__c>();
            List<Booking_Split__c> newDebookingSplits = new List<Booking_Split__c>();
            Date ccrApprovedDate = Date.Today();
            String OrderQuarter=' ';
            String CurrentQuarter = ' ';
            integer OrderYear;
            Map<ID,List<CCR__c>> mapOfOppIdAndCCRs = New Map<ID,List<CCR__c>>();
            Map<ID,List<CCR__c>> mapOfOriginalBkgIdAndCCRs = New Map<ID,List<CCR__c>>();
            Map<Id,id>mapOriginalNewBkg = new Map<id,id>();
            Map<ID,Booking__c> mapOfOppIdAndBkg = New Map<ID,Booking__c>();
            Map<Id, Decimal> mapOppIdToTotalAmount = new Map<Id, Decimal>();
            List<CCR__c> ccrsTobeUpdated = New List<CCR__c>(); 
            List<Booking_Line_Item__c> lstUpdateBLI = new List<Booking_Line_Item__c>();
            Set<ID> BLIsinserted = new Set<Id>();   
            Set<ID> oppIdSet = new Set<ID>();
            String fiscalPeriodQuarter = ' ';
            String fiscalPeriodYear = ' ';
           set<id> OrgBkgCCRIds = new set<Id>();
           Set<Id> setPRFCCRId = new Set<Id>();
            //Get Opportunity's unassigned CCRs and bookings if any existing
            for(Opportunity opp : [SELECT id,AccountId,CloseDate,SBQQ__PrimaryQuote__r.SBQQ__NetAmount__c, Amount,Split_percentage__c, New_Expansion_TCV__c, Subsumed_Renewal_TCV__c,
                                      (SELECT id,Booking__c,Opportunity__c, Booking__r.Fiscal_Period__c, Affective_Person__c,CCR_Type__c,Referral_Fee_Amount__c,Impacts_Commission__c,Amount__c,Effective_Date__c,Customer_Returns_Type__c,AssignmentStatus__c FROM CCRs__r WHERE (CCR_Type__c = : Constants.PARTNER_REFERRAL_FEE OR CCR_Type__c IN : Constants.CCR_TYPES) AND  User__c='Approved' order by createddate),
                                      (SELECT Id,Order__r.Opportunity.CloseDate,CreatedDate,Fiscal_Period__c, Order__r.ID,Order__r.Order_Accepted_Timestamp__c,recordType.name,
                                              OwnerId, Name, Account_Name__c, Address__c, Shipping_Adresss__c, Deal_Registration_Type__c, Distributor__c, Fed_SI_Partner_Lookup__c, ISR_SDR_Oppty_Credit_Total_c__c, 
                                              Opportunity_Close_Date__c, Opportunity_Owner_Employee_ID__c, Opportunity_Split__c, Opportunity_Sub_Type__c,Opportunity_Type__c, Order_Type__c, Original_Lead_Owner__c, PO_Date__c, PO_Number__c, Partner_Email__c, Partner_Name__c, R2K__c, Renewal_Opportunity_Owner__c, SDR_Led__c, 
                                              SE_Misaligned__c, Sales_Engineer__c, Fiscal_Year__c, Secondary_Owner__c, Status__c, Strategic_Account__c, Booking_Total__c, Affected_Person__c, Alliance_HW_Partner__c, Alliance_Partner_Name__c, Original_Booking__c, Opportunity__c, Order__c 
                                       FROM Bookings__r  ORDER BY CreatedDate DESC LIMIT 1),
                                        (SELECT Id, TotalPrice FROM OpportunityLineItems WHERE ProductCode = : System.Label.OpportunitySplitProduct)
                                   FROM Opportunity WHERE id IN (SELECT Opportunity__c FROM CCR__c where ID IN :CCRs)] ){
                 Decimal refFee = 0.0 , debookingAmount =  0.0;      
                 Decimal TotalPriceSplit = 0.0;    
                  mapOrigOppIdToOrigOpp.put(opp.Id, opp);
                 if(opp.Amount != null){
                if(!opp.OpportunityLineItems.isEmpty()) {
                    for(OpportunityLineItem objOppLI :  opp.OpportunityLineItems) {
                        TotalPriceSplit += Math.abs(objOppLI.TotalPrice);
                    }
                    mapOppIdToTotalAmount.put(opp.Id, (TotalPriceSplit + opp.Amount));                     
                }else{
                    mapOppIdToTotalAmount.put(opp.Id, opp.Amount);                     
                }
                 }

                 if(!opp.CCRs__r.isEmpty()){ 
                    for(CCR__c ccr: opp.CCRs__r){
                        if(ccr.AssignmentStatus__c !='Assigned'){
                            if(mapOfOppIdAndCCRs.containsKey(opp.id)) {
                                mapOfOppIdAndCCRs.get(opp.id).add(ccr); 
                            }
                             else{
                                mapOfOppIdAndCCRs.put(opp.id,new List<CCR__c>{ccr}); 
                             }
                        }
                      if(ccr.CCR_Type__c =='Partner Referral Fee' && ccr.Referral_Fee_Amount__c != null){
                          setPRFCCRId.add(ccr.Id);
                          refFee += ccr.Referral_Fee_Amount__c;
                      }
                      else if(ccr.CCR_Type__c !='Partner Referral Fee' && ccr.Amount__c != null){
                        debookingAmount += ccr.Amount__c ;
                      }
                    }
                    if(!mapOppIdToTotalAmount.isEmpty() && mapOppIdToTotalAmount.containskey(opp.Id) && debookingAmount != null  &&
                     math.abs(mapOppIdToTotalAmount.get(opp.Id).setScale(2, RoundingMode.HALF_UP) - debookingAmount)<= decimal.valueOf(System.Label.PRF_Tolerable_Adjustment)){

                        origOppIdReferalFee.put(opp.id,refFee);
                    } 
                  } 
                 if(!opp.Bookings__r.isEmpty()){     
                     mapOfOppIdAndBkg.put(opp.id,opp.Bookings__r);
                  }
            }
            for(CCR__c ccr : CCRs){
               if(ccr.Booking__c != null){
                OrgBkgCCRIds.add(ccr.Booking__c);
               }
            }
            if(!OrgBkgCCRIds.isEmpty()){
            for(Booking_Line_Item__c BLI : [SELECT id,Rebate__c, CCR__r.Opportunity__c, CCR__r.Booking__c, CCR__r.Booking__r.Fiscal_Period__c, Booking__r.Opportunity__c, Booking__r.Fiscal_Period__c, Booking__c, New_Expansion_TCV__c, Subsumed_Renewal_TCV__c, CCR__c, Distributor__c,Impacts_Gross_Bookings__c,Impacts_Net_Bookings__c,Impacts_Commission__c, Type__c,
                                            Total_Price__c, Net_TCV_Amount__c, Net_New_Expansion_TCV__c, Net_Subsumed_Renewal_TCV__c, Gross_ACV_Amount__c, Gross_New_Expansion_ACV__c, Gross_Subsumed_Renewal_ACV__c, Net_ACV_Amount__c, Net_New_Expansion_ACV__c, Net_Subsumed_Renewal_ACV__c 
                                            FROM Booking_Line_Item__c where Booking__c IN : OrgBkgCCRIds OR CCR__c IN : setPRFCCRId]){
              if(BLI.Type__c == 'Distributor Fee'){
                 mapCCROrignalRebate.put(BLI.Booking__c,BLI);  
              }
              if(BLI.Type__c == 'Partner Referral Fee'){
                  if(BLI.CCR__c != null && BLI?.CCR__r?.Opportunity__c != null)
                  mapCCROppIdToOriginalPRF.put(BLI.CCR__r.Opportunity__c, BLI);
                                                     
              }
            
            }
           } 
            if( ! mapOfOppIdAndCCRs.keySet().isEmpty()){
              for(Id oppId : mapOfOppIdAndCCRs.keySet()){
                //exit from loop if opportunity doesn't have any bookings
                if( mapOfOppIdAndBkg.get(oppId) == NULL){ 
                    continue;                    
                }else{               
                if(mapOfOppIdAndBkg.containsKey(oppId) && mapOfOppIdAndCCRs.containsKey(oppId) && mapOfOppIdAndBkg.get(oppId) != null && mapOfOppIdAndCCRs.get(oppId) != null){
                    //check booking record type if it's a booking or debooking. If booking, check order activated date for quarter else check created date of debooking
                    //then call createBLI method(booking id,ccr list)
                    //if not in quarter create booking and attach original booking to it
                    for(Financial_Year__mdt fy : quarterMap){
                           //Get quarter detail of when Order is Accepted
                           if(mapOfOppIdAndBkg.get(oppId).recordType.name == 'Booking'){
                               if( mapOfOppIdAndBkg.get(oppId).Order__r.Order_Accepted_Timestamp__c != NULL ){
                                   if( mapOfOppIdAndBkg.get(oppId).Order__r.Order_Accepted_Timestamp__c.Month() >= fy.Quarter_Start_Month__c && mapOfOppIdAndBkg.get(oppId).Order__r.Order_Accepted_Timestamp__c.Month() <= fy.Quarter_End_Month__c){
                                      OrderQuarter = fy.Quarter__c;
                                      OrderYear = mapOfOppIdAndBkg.get(oppId).Order__r.Order_Accepted_Timestamp__c.year();
                                    }else if(mapOfOppIdAndBkg.get(oppId).Order__r.Order_Accepted_Timestamp__c.Month() >= 11 || mapOfOppIdAndBkg.get(oppId).Order__r.Order_Accepted_Timestamp__c.Month() == 1){
                                       OrderQuarter = '4';
                                       OrderYear = mapOfOppIdAndBkg.get(oppId).Order__r.Order_Accepted_Timestamp__c.year();
                                    }
                                }else{
                                    if( mapOfOppIdAndBkg.get(oppId).Order__r.Opportunity.CloseDate.Month() >= fy.Quarter_Start_Month__c && mapOfOppIdAndBkg.get(oppId).Order__r.Opportunity.CloseDate.Month() <= fy.Quarter_End_Month__c){
                                        OrderQuarter = fy.Quarter__c;
                                        OrderYear = mapOfOppIdAndBkg.get(oppId).Order__r.Opportunity.CloseDate.year();
                                    }else if(mapOfOppIdAndBkg.get(oppId).Order__r.Opportunity.CloseDate.Month() >= 11 || mapOfOppIdAndBkg.get(oppId).Order__r.Opportunity.CloseDate.Month() == 1){
                                        OrderQuarter = '4';
                                        OrderYear = mapOfOppIdAndBkg.get(oppId).Order__r.Opportunity.CloseDate.year();
                                    }
                                
                                }
                            }else if(mapOfOppIdAndBkg.get(oppId).recordType.name == 'Booking Adjustment'){    
                                if( mapOfOppIdAndBkg.get(oppId).CreatedDate.Month() >= fy.Quarter_Start_Month__c && mapOfOppIdAndBkg.get(oppId).CreatedDate.Month() <= fy.Quarter_End_Month__c){
                                  OrderQuarter = fy.Quarter__c;
                                  OrderYear = mapOfOppIdAndBkg.get(oppId).CreatedDate.Year();
                                }else if(mapOfOppIdAndBkg.get(oppId).CreatedDate.Month() >= 11 || mapOfOppIdAndBkg.get(oppId).CreatedDate.Month() == 1){
                                    OrderQuarter = '4';
                                    OrderYear = mapOfOppIdAndBkg.get(oppId).CreatedDate.Year();
                                 }
                            }                        
                            if( ccrApprovedDate.Month() >= fy.Quarter_Start_Month__c && ccrApprovedDate.Month() <= fy.Quarter_End_Month__c){
                               CurrentQuarter = fy.Quarter__c;                          
                            }else if(ccrApprovedDate.Month() >= 11 || ccrApprovedDate.Month() == 1){
                                CurrentQuarter = '4'; 
                            }
                    }
                    //If Booking existing per quarter create BLI under that Booking
                    //system.debug('Orderquarter-->'+Orderquarter+' CurrentQuarter-->'+CurrentQuarter+' OrderYear-->'+OrderYear+'ccrApprovedDate.Month()-->'+ccrApprovedDate.Month()+'ccrApprovedDate.year()-->'+ ccrApprovedDate.year());
                    if( Orderquarter== CurrentQuarter && ( OrderYear == ccrApprovedDate.year() || (orderQuarter == '4' &&  ccrApprovedDate.Month()== 1 && (ccrApprovedDate.year()-OrderYear) == 1) )){
                       if(mapOfOppIdAndCCRs.containsKey(oppId) && mapOfOppIdAndCCRs.get(oppId)[0]?.Booking__r?.Fiscal_Period__c == mapOfOppIdAndBkg.get(oppId)?.Fiscal_Period__c){
                        
                        CreateBLI(mapOfOppIdAndCCRs.get(oppId)[0].Booking__c,mapOfOppIdAndCCRs.get(oppId));
                       }else{
                        CreateBLI(mapOfOppIdAndBkg.get(oppId).id,mapOfOppIdAndCCRs.get(oppId));
                       }
                    }else {
                            //If there is no booking existing per quarter, then create one
                            //Booking__c bkg = new Booking__c();
                            Booking__c bkg = mapOfOppIdAndBkg.get(oppId).clone();
                            fiscalPeriodYear = String.valueOf( ccrApprovedDate.Month() >= 2 ? ccrApprovedDate.Year()+1 : ccrApprovedDate.Year() ) ;                      
                            for(Financial_Year__mdt fy : quarterMap){
                                 if( ccrApprovedDate.Month() >= fy.Quarter_Start_Month__c && ccrApprovedDate.Month() <= fy.Quarter_End_Month__c){
                                     fiscalPeriodQuarter = fy.Quarter__c;                          
                                 }else if(ccrApprovedDate.Month() >= 11 || ccrApprovedDate.Month() == 1){
                                     fiscalPeriodQuarter = '4';
                                 }
                            }                      
                            bkg.Fiscal_Period__c='Q'+fiscalPeriodQuarter+'-'+fiscalPeriodYear;
                            bkg.Fiscal_Quarter__c= fiscalPeriodQuarter ;
                            bkg.Fiscal_Year__c= string.valueof(fiscalPeriodYear);
                            bkg.status__c='Completed';
                            bkg.Order__c=NULL;
                            bkg.Opportunity_Close_Date__c=mapOfOppIdAndCCRs.get(oppId)[0].Effective_Date__c;
                            bkg.Order_Type__c='Booking Adjustment';
                            bkg.RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking Adjustment').getRecordTypeId();
                            bkg.Opportunity__c = oppId ;
                            if(mapOfOppIdAndBkg.get(oppId).recordType.name == 'Booking'){
                                bkg.Original_Booking__c = mapOfOppIdAndBkg.get(oppId).id;
                                mapOfOriginalBkgIdAndCCRs.put(mapOfOppIdAndBkg.get(oppId).id,mapOfOppIdAndCCRs.get(oppId));
                             }else{
                                bkg.Original_Booking__c = mapOfOppIdAndBkg.get(oppId).Original_Booking__c;
                                mapOfOriginalBkgIdAndCCRs.put(mapOfOppIdAndBkg.get(oppId).Original_Booking__c,mapOfOppIdAndCCRs.get(oppId));
                            }
                            newDebookingsList.add(bkg);
                       }
                    }
                }
            }
         }
        //insert new debooking per quarter and it's line items    
        if(!newDebookingsList.isEmpty()){
                Database.SaveResult[] bkgInsertSR = Database.insert(newDebookingsList, false);
                // Iterate through each returned result
                for(Integer i=0;i<bkgInsertSR.size();i++){
                        if(!bkgInsertSR[i].isSuccess()){//only look at failures, or NOT Successes
                            for(Database.Error err : bkgInsertSR[i].getErrors()){
                                ErrorMessage += err.getFields()+'::'+err.getMessage() +',';
                            }
                            UnProcessedRecord+= 'Error with inserting Booking Adjustment for Original Booking::'+newDebookingsList[i].Original_Booking__c+',';
                        }else{
                            SuccessBookingInsertIdSet.add(bkgInsertSR[i].getId());
                            mapOriginalNewBkg.put(newDebookingsList[i].Original_Booking__c,bkgInsertSR[i].getId());
                        }
                } 
                if(!SuccessBookingInsertIdSet.isEmpty()){  
                        for(Booking__c bkg : newDebookingsList ){
                            if(mapOfOriginalBkgIdAndCCRs.containsKey(bkg.Original_Booking__c)){
                                mapDebookBkgIdToOrgBkgId.put(bkg.Id, bkg.Original_Booking__c);
                                CreateBLI(bkg.id,mapOfOriginalBkgIdAndCCRs.get(bkg.Original_Booking__c));
                            }
                        }
                        for(Booking_Split__c BS : [select Area__c,Booking__c,Region__c,Opportunity_Split__c,Sales_Rep__c,Territory__c,Theatre__c,Booking__r.Opportunity__c,Opportunity__c, Opp_PLS_ETM_Area__c, Opp_PLS_ETM_Region__c, Opp_PLS_ETM_Territory__c, Opp_PLS_ETM_Theatre__c from Booking_Split__c where Booking__c IN:mapOfOriginalBkgIdAndCCRs.keyset()]){
                              Booking_Split__c bsplit = BS.clone(false,true);
                              bsplit.Booking__c = mapOriginalNewBkg.get(BS.Booking__c); 
                              newDebookingSplits.add(bsplit);
                            
                        }
                        if(!newDebookingSplits.isEmpty()){
                          Database.insert(newDebookingSplits,false);
                        }
                }    
        }
        //insert BLIs and update it's CCR's assignment status to Assigned
        if(!bliTobeInserted.isEmpty()){
            Database.SaveResult[] bkgLineInsertSR = Database.insert(bliTobeInserted, false);
            // Iterate through each returned result
            for(Integer i=0;i<bkgLineInsertSR.size();i++){
                    if(!bkgLineInsertSR[i].isSuccess()){//only look at failures, or NOT Successes
                            for(Database.Error err : bkgLineInsertSR[i].getErrors()){
                                    ErrorMessage += err.getFields()+'::'+err.getMessage() +',';
                            }
                            UnProcessedRecord+= 'Error with inserting Booking Lines of Booking::'+bliTobeInserted[i].Booking__c+',';
                    }else{
                            SuccessBookingLineInsertIdSet.add(bkgLineInsertSR[i].getId());
                    }
            }          
            //Collect BLI ids insert successfully under new debooking
            if(!SuccessBookingLineInsertIdSet.isEmpty()){
                    for( Booking_Line_Item__c BLItem: bliTobeInserted){
                           BLIsinserted.add(BLItem.id);
                     }
                     for(CCR__c ccr : [SELECT id, Booking__c, Booking__r.Id,Booking__r.Order__r.TotalAmount,Name,Opportunity__c,AssignmentStatus__c,CCR_Type__c,Referral_Fee_Amount__c,Amount__c,Effective_Date__c,Effective_End_Date__c FROM CCR__c where ID IN (SELECT CCR__c FROM Booking_Line_Item__c where ID IN :BLIsinserted)]){
                             CCR__c ccrRec = new CCR__c(id=ccr.id,AssignmentStatus__c='Assigned');
                             if(ccr.Booking__r.Id == null && CCRIdBkgId.get(ccr.id)!=null){
                                ccrRec.Booking__c = CCRIdBkgId.get(ccr.id);
                             } 
                         mapBookingIdToOppId.put(ccrRec.Booking__c != null ? ccrRec.Booking__c : ccr.Booking__c, ccr.Opportunity__c);
                             ccrsTobeUpdated.add(ccrRec);
                                     MapOfccrIdAndCCRrecord.put(ccr.id,ccr);
                                     oppIdSet.add(ccr.Opportunity__c);
                                     if(ccr.Booking__r.id != NULL)
                                         mapOfCCRIdAndOriginalOrdAmount.put(ccr.id,ccr.Booking__r.Order__r.TotalAmount);
                             
                     }
                   if(!ccrsTobeUpdated.isEmpty()){             
                           Database.UpsertResult[] ccrInsertSR = Database.upsert(ccrsTobeUpdated, false);
                           // Iterate through each returned result
                           for(Integer i=0;i<ccrInsertSR.size();i++){
                                   if(!ccrInsertSR[i].isSuccess()){//only look at failures, or NOT Successes
                                       for(Database.Error err : ccrInsertSR[i].getErrors()){
                                               ErrorMessage += err.getFields()+'::'+err.getMessage() +',';
                                        }
                                        UnProcessedRecord+= 'Error with updating assignment status of CCR::'+ccrsTobeUpdated[i].Name+',';
                                   }else{
                                   SuccessCCRUpdateIdSet.add(ccrInsertSR[i].getId());
                                   }
                            }  
                            if(!MapOfccrIdAndCCRrecord.keySet().isEmpty() && !SuccessCCRUpdateIdSet.isEmpty()){
                                    CreateDebookingOpp(oppIdSet);
                                if(!bliTobeInserted.isEmpty()){
                                    for(Booking_Line_Item__c objBLI : bliTobeInserted){
                                    Id origBookingId = mapDebookBkgIdToOrgBkgId.containsKey(objBLI.Booking__c) && mapDebookBkgIdToOrgBkgId.get(objBLI.Booking__c) != null && objBLI.Booking__c != mapDebookBkgIdToOrgBkgId.get(objBLI.Booking__c) ? mapDebookBkgIdToOrgBkgId.get(objBLI.Booking__c) : objBLI.Booking__c;
                                        
                                        if(objBLI.CCR__c != null && mapCCRIdToDebookOpp.containsKey(objBLI.CCR__c)){
                                            Decimal grossRenewalTCV = mapCCRIdToDebookOpp.get(objBLI.CCR__c).Subsumed_Renewal_TCV__c != null ? mapCCRIdToDebookOpp.get(objBLI.CCR__c).Subsumed_Renewal_TCV__c : 0.00;
                                            Decimal grossNewTCV = mapCCRIdToDebookOpp.get(objBLI.CCR__c).New_Expansion_TCV__c != null ? mapCCRIdToDebookOpp.get(objBLI.CCR__c).New_Expansion_TCV__c : 0.00;
                                            Decimal grossACVAmt = mapCCRIdToDebookOpp.get(objBLI.CCR__c).ACV_Amount__c != null ? mapCCRIdToDebookOpp.get(objBLI.CCR__c).ACV_Amount__c : 0.00;
                                            Decimal grossNewACV = mapCCRIdToDebookOpp.get(objBLI.CCR__c).New_Expansion_ACV__c != null ? mapCCRIdToDebookOpp.get(objBLI.CCR__c).New_Expansion_ACV__c : 0.00;
                                            Decimal grossRenewalACV = mapCCRIdToDebookOpp.get(objBLI.CCR__c).Renewal_Subsumed_ACV__c != null ? mapCCRIdToDebookOpp.get(objBLI.CCR__c).Renewal_Subsumed_ACV__c : 0.00;
                                            Decimal netTCVAmt, netNewTCV, netRenewalTCV , netACVAmt, netNewACV, netRenewalACV;
                                            Decimal rebateCalculate = mapCCROrignalRebate.containsKey(origBookingId) && mapCCROrignalRebate.get(origBookingId).Rebate__c != null ? mapCCROrignalRebate.get(origBookingId).Rebate__c : 0; 
                                       	    netTCVAmt = netNewTCV = netRenewalTCV = netACVAmt = netNewACV = netRenewalACV = 0.00;

                                            if(objBLI.Type__c == 'Partner Referral Fee'){
                                                netTCVAmt = objBLI.Total_Price__c;
                                                netRenewalTCV = grossRenewalTCV;
                                                netNewTCV = grossNewTCV;
                                                netACVAmt = grossACVAmt;
                                                netNewACV  = grossNewACV;
                                                netRenewalACV = grossRenewalACV;
                                            }else if(rebateCalculate != null){
                                             	netTCVAmt = objBLI.Total_Price__c != null ? objBLI.Total_Price__c * ((100 - rebateCalculate) * 0.01) : 0.00;
                                            	netRenewalTCV = grossRenewalTCV != null ? grossRenewalTCV * ((100 - rebateCalculate) * 0.01) : 0.00;
                                            	netNewTCV = grossNewTCV != null ? grossNewTCV * ((100 - rebateCalculate) * 0.01) : 0.00;
                                            	netACVAmt = grossACVAmt != null ? grossACVAmt * ((100 - rebateCalculate) * 0.01) : 0.00; 
                                                netNewACV = grossNewACV != null ? grossNewACV * ((100 - rebateCalculate) * 0.01) : 0.00;
                                                netRenewalACV = grossRenewalACV != null ? grossRenewalACV * ((100 - rebateCalculate) * 0.01) : 0.00;
                                            }
                                         lstUpdateBLI.add(new Booking_Line_Item__c(Id = objBLI.Id, Subsumed_Renewal_TCV__c = grossRenewalTCV.setScale(2, RoundingMode.HALF_UP) , New_Expansion_TCV__c = grossNewTCV.setScale(2, RoundingMode.HALF_UP),
                                                                                     Net_TCV_Amount__c = netTCVAmt.setScale(2, RoundingMode.HALF_UP) , Net_New_Expansion_TCV__c = netNewTCV.setScale(2, RoundingMode.HALF_UP), Net_Subsumed_Renewal_TCV__c = netRenewalTCV.setScale(2, RoundingMode.HALF_UP),
                                                                                     Gross_ACV_Amount__c = grossACVAmt.setScale(2, RoundingMode.HALF_UP), Gross_New_Expansion_ACV__c = grossNewACV.setScale(2, RoundingMode.HALF_UP), Gross_Subsumed_Renewal_ACV__c = grossRenewalACV.setScale(2, RoundingMode.HALF_UP) , 
                                                                                      Net_ACV_Amount__c = netACVAmt.setScale(2, RoundingMode.HALF_UP),Net_New_Expansion_ACV__c = netNewACV.setScale(2, RoundingMode.HALF_UP) ,Net_Subsumed_Renewal_ACV__c = netRenewalACV.setScale(2, RoundingMode.HALF_UP)));
                                         }else if(objBLI.Type__c == 'Distributor Fee' || objBLI.Type__c == 'Partner Referral Fee') {
											
                                            
                                            if((origBookingId != null && mapBkgIdToCCRId.containsKey(origBookingId) && 
												mapCCRIdToDebookOpp.containsKey(mapBkgIdToCCRId.get(origBookingId))) ||
                                               (mapBookingIdToOppId.containsKey(objBLI.Booking__c) &&
                                              mapCCROppIdToOriginalPRF.containsKey(mapBookingIdToOppId.get(objBLI.Booking__c)))){ 
                                                    
                                                 Booking_Line_Item__c obBLI = new Booking_Line_Item__c(Id = objBLI.Id);
                                                    if(objBLI.Type__c == 'Distributor Fee'){
                                                        obBLI.Subsumed_Renewal_TCV__c = mapCCRIdToDebookOpp.get(mapBkgIdToCCRId.get(origBookingId)).Subsumed_Renewal_TCV__c != null ? (mapCCRIdToDebookOpp.get(mapBkgIdToCCRId.get(origBookingId)).Subsumed_Renewal_TCV__c * objBLI.Rebate__c * -0.01).setScale(2, RoundingMode.HALF_UP) : 0.00;
                                                        obBLI.New_Expansion_TCV__c = mapCCRIdToDebookOpp.get(mapBkgIdToCCRId.get(origBookingId)).New_Expansion_TCV__c != null ? (mapCCRIdToDebookOpp.get(mapBkgIdToCCRId.get(origBookingId)).New_Expansion_TCV__c  * objBLI.Rebate__c * -0.01).setScale(2, RoundingMode.HALF_UP) : 0.00;
                                                    	obBLI.Gross_ACV_Amount__c = mapCCRIdToDebookOpp.get(mapBkgIdToCCRId.get(origBookingId)).ACV_Amount__c != null ? (mapCCRIdToDebookOpp.get(mapBkgIdToCCRId.get(origBookingId)).ACV_Amount__c  * objBLI.Rebate__c * -0.01).setScale(2, RoundingMode.HALF_UP) : 0.00;
                                                        obBLI.Gross_New_Expansion_ACV__c = mapCCRIdToDebookOpp.get(mapBkgIdToCCRId.get(origBookingId)).New_Expansion_ACV__c != null ? (mapCCRIdToDebookOpp.get(mapBkgIdToCCRId.get(origBookingId)).New_Expansion_ACV__c  * objBLI.Rebate__c * -0.01).setScale(2, RoundingMode.HALF_UP) : 0.00;
                                                        obBLI.Gross_Subsumed_Renewal_ACV__c =  mapCCRIdToDebookOpp.get(mapBkgIdToCCRId.get(origBookingId)).Renewal_Subsumed_ACV__c != null ? (mapCCRIdToDebookOpp.get(mapBkgIdToCCRId.get(origBookingId)).Renewal_Subsumed_ACV__c  * objBLI.Rebate__c * -0.01).setScale(2, RoundingMode.HALF_UP) : 0.00;
                                                    }else if(objBLI.Type__c == 'Partner Referral Fee'){
                                                         if(mapBookingIdToOppId.containsKey(objBLI.Booking__c) && mapBookingIdToOppId.get(objBLI.Booking__c) != null && mapCCROppIdToOriginalPRF.containsKey(mapBookingIdToOppId.get(objBLI.Booking__c))){
                                                        Booking_Line_Item__c objPRFBLI = mapCCROppIdToOriginalPRF.get(mapBookingIdToOppId.get(objBLI.Booking__c));
                                                        obBLI.New_Expansion_TCV__c = objPRFBLI.New_Expansion_TCV__c != null ? (objPRFBLI.New_Expansion_TCV__c  * -1).setScale(2, RoundingMode.HALF_UP) : 0.00;
                                                    	obBLI.Subsumed_Renewal_TCV__c = objPRFBLI.Subsumed_Renewal_TCV__c != null ? (objPRFBLI.Subsumed_Renewal_TCV__c * -1).setScale(2, RoundingMode.HALF_UP) : 0.00;
                                                      	obBLI.Net_TCV_Amount__c =  objPRFBLI.Total_Price__c != null ? (objPRFBLI.Total_Price__c * -1).setScale(2, RoundingMode.HALF_UP) : 0.00;
                                                        obBLI.Net_New_Expansion_TCV__c = obBLI.New_Expansion_TCV__c != null ? obBLI.New_Expansion_TCV__c :0.00;
                                                        obBLI.Net_Subsumed_Renewal_TCV__c = obBLI.Subsumed_Renewal_TCV__c != null ? obBLI.Subsumed_Renewal_TCV__c : 0.00;
                                                        obBLI.Gross_ACV_Amount__c = objPRFBLI.Gross_ACV_Amount__c != null ? (objPRFBLI.Gross_ACV_Amount__c * -1).setScale(2, RoundingMode.HALF_UP) : 0.00;
                                                        obBLI.Gross_New_Expansion_ACV__c = objPRFBLI.Gross_New_Expansion_ACV__c != null ? (objPRFBLI.Gross_New_Expansion_ACV__c * - 1).setScale(2, RoundingMode.HALF_UP) : 0.00;
                                                        obBLI.Gross_Subsumed_Renewal_ACV__c = objPRFBLI.Gross_Subsumed_Renewal_ACV__c != null ? (objPRFBLI.Gross_Subsumed_Renewal_ACV__c * -1).setScale(2, RoundingMode.HALF_UP) : 0.00;
                                                        obBLI.Net_ACV_Amount__c = obBLI.Gross_ACV_Amount__c != null ? obBLI.Gross_ACV_Amount__c : 0.00;
                                                        obBLI.Net_New_Expansion_ACV__c= obBLI.Gross_New_Expansion_ACV__c != null ? obBLI.Gross_New_Expansion_ACV__c : 0.00;
                                                        obBLI.Net_Subsumed_Renewal_ACV__c= obBLI.Gross_Subsumed_Renewal_ACV__c != null ? obBLI.Gross_Subsumed_Renewal_ACV__c : 0.00;
                                                        }
                                                    }
                                                    if(obBLI != null){
														lstUpdateBLI.add(obBLI);
                                                  	}
                                                }
					}                              
                                    }
                                }
                                 if(!debookingOppsToBeInserted.isEmpty()){
                                            OpportunityObjectTriggerHandler.bypassClosedWonUpdateValidation = true;//SFDCSOX-1105
                                            Database.SaveResult[] OppInsertSR = Database.insert(debookingOppsToBeInserted, false);
                                            // Iterate through each returned result
                                            for(Integer i=0;i<OppInsertSR.size();i++){
                                                   if(!OppInsertSR[i].isSuccess()){//only look at failures, or NOT Successes
                                                           for(Database.Error err : OppInsertSR[i].getErrors()){
                                                                   ErrorMessage += err.getFields()+'::'+err.getMessage() +',';
                                                           }
                                                           UnProcessedRecord+= 'Error with inserting Debooking Opportunity::'+debookingOppsToBeInserted[i].Name+',';
                                                    }else{
                                                            SuccessOpportunityInsertIdSet.add(OppInsertSR[i].getId());
                                                    }
                                           }  
                                           if(!SuccessOpportunityInsertIdSet.isEmpty()){
                                                   for(Opportunity opp : debookingOppsToBeInserted){
                                                        opp.StageName='7 Closed Won';
                                                    }
                                                    Database.UpsertResult[] oppUpsertSR = Database.upsert(debookingOppsToBeInserted, false);
                                                    // Iterate through each returned result
                                                    for(Integer i=0;i<oppUpsertSR.size();i++){
                                                           if(!oppUpsertSR[i].isSuccess()){//only look at failures, or NOT Successes
                                                                for(Database.Error err : OppUpsertSR[i].getErrors()){
                                                                         ErrorMessage += err.getFields()+'::'+err.getMessage() +',';
                                                                 }
                                                                 UnProcessedRecord+= 'Error with updating Opportunity to ClosedWon Stage for::'+debookingOppsToBeInserted[i].Name+',';
                                                            }  
                                                    } 
                                            }                     
                                    }

                                if(!lstUpdateBLI.isEmpty()){
                                    Database.SaveResult[] BLIUpdateSR = Database.update(lstUpdateBLI, false);  
                                    for(Integer i=0;i<BLIUpdateSR.size();i++){
                                        if(!BLIUpdateSR[i].isSuccess()){//only look at failures, or NOT Successes
                                        	for(Database.Error err : BLIUpdateSR[i].getErrors()){
                                                
                                            	ErrorMessage += err.getFields()+'::'+err.getMessage() +',';
                                             }
                                             UnProcessedRecord+= 'Error with updating Booking Line Item::'+BLIUpdateSR[i].Id+',';
                                            }
                                    }
                                }
                                                               }
                   }
            }

        }
        if(String.isNotBlank(UnProcessedRecord)){
            UnProcessedRecord= UnProcessedRecord.removeEnd(',');
            ErrorMessage = ErrorMessage.removeEnd(',');
            errLog.add(LogError.CreateDMLErrorLog(className,UnProcessedRecord,ErrorMessage,ERROR_FUNCTIONALITY));
        } 
        
        }catch(exception e){
            errLog.add(LogError.CreateGenericErrorLog(className,e,ERROR_FUNCTIONALITY));

        }
         if(!errLog.isEmpty()){
            insert errLog ;  
         }                            
    }

    //Create BLI from CCR and assign it to booking id being passed
    /**
     * @description CreateBLI
     * @param bkgId
     * @param ccrs
     */
    public static void CreateBLI(ID bkgId,List<CCR__c> ccrs){
        Decimal totalAmount = 0.0;
        Id originalBkgId ;   
        for(CCR__c ccr : ccrs){
                 try{
                        
                        if(ccr.Customer_Returns_Type__c!='LineItem Based'){
                        Booking_Line_Item__c BLI = New Booking_Line_Item__c();
                        BLI.Booking__c = bkgId; 
                        if(ccr.CCR_Type__c == 'Partner Referral Fee'){
                            
                            if(ccr.Referral_Fee_Amount__c  != NULL){
                                BLI.Total_Price__c= ccr.Referral_Fee_Amount__c * -1;
                             }else{
                                 BLI.Total_Price__c = 0;
                             }
                             CCRIdBkgId.put(ccr.id,bkgId);
                            if(!mapBkgIdToCCRId.containsKey(bkgId)){
                                mapBkgIdToCCRId.put(bkgId, ccr.Id);
                            }
                        }
                        else if(Constants.CCR_TYPES.contains(ccr.CCR_Type__c)){
                            if(ccr.Amount__c != NULL){        
                                BLI.Total_Price__c= ccr.Amount__c * -1;
                                totalAmount += ccr.Amount__c ;
                             }else{
                                 BLI.Total_Price__c =0;
                             }
                             originalBkgId = ccr.Booking__c ;
                        }    
                        BLI.Impacts_Commission__c = ccr.Impacts_Commission__c;
                        BLI.Type__c= ccr.CCR_Type__c;
                        BLI.CCR__c = ccr.id;
                        for(BLI_Impact__mdt BLIimpact : BLIimpactList){
                            if(BLI.Type__c == BLIimpact.Adjustment_Type__c){
                                BLI.Impacts_Gross_Bookings__c = BLIimpact.Impacts_Gross_Bookings__c;
                                BLI.Impacts_Net_Bookings__c = BLIimpact.Impacts_Net_Bookings__c;
                                if(BLI.Type__c != 'Change in Booking Policy / De-Risk Decision' && BLI.Type__c != 'Incorrect Order/Mis-quote'){
                                    BLI.Impacts_Commission__c=BLIimpact.Impacts_Commissions__c;
                                }
                            }
                        }
                        mapDebookBkgIdToOrgBkgId.put(bkgId, ccr.Booking__c);
                        bliTobeInserted.add(BLI);  
                     }   
                  }catch(exception e){
                      errLog.add(LogError.CreateGenericErrorLog(className,e,ERROR_FUNCTIONALITY));

                  }
            }

            if(mapCCROrignalRebate.containsKey(originalBkgId) && totalAmount != 0.0){
                Booking_Line_Item__c rebateBLI = mapCCROrignalRebate.get(originalBkgId).clone();
                rebateBLI.Booking__c = bkgId; 
                rebateBLI.Total_Price__c = totalAmount*rebateBLI.Rebate__c*0.01 ; 
                if(!mapCCROrignalRebate.containsKey(bkgId)){
                    mapCCROrignalRebate.put(bkgId, rebateBLI);
                }
                if(!mapDebookBkgIdToOrgBkgId.containsKey(bkgId)){
                mapDebookBkgIdToOrgBkgId.put(bkgId, originalBkgId);
                }
        
                bliTobeInserted.add(rebateBLI);  
            }
        
            if(!ccrs.isEmpty() && ccrs[0].CCR_Type__c != 'Partner Referral Fee' && origOppIdReferalFee.containskey(ccrs[0].Opportunity__c) && origOppIdReferalFee.get(ccrs[0].Opportunity__c) != 0){
               Booking_Line_Item__c PRF_Bli = New Booking_Line_Item__c(Type__c = 'Partner Referral Fee' , Booking__c = bkgId , Total_Price__c = origOppIdReferalFee.get(ccrs[0].Opportunity__c)); 
               for(BLI_Impact__mdt BLIimpact : BLIimpactList){
                            if(BLIimpact.Adjustment_Type__c == 'Partner Referral Fee'){
                                PRF_Bli.Impacts_Gross_Bookings__c = BLIimpact.Impacts_Gross_Bookings__c;
                                PRF_Bli.Impacts_Net_Bookings__c = BLIimpact.Impacts_Net_Bookings__c;
                                PRF_Bli.Impacts_Commission__c=BLIimpact.Impacts_Commissions__c;
                                break;
                            }
                        }
                        
                bliTobeInserted.add(PRF_Bli);  
            }
            
     }
     /**
      * @description CreateDebookingOpp
      * @param oppIdsSet
      */
     public static void CreateDebookingOpp(Set<Id> oppIdsSet){ 
         try{
         //Collect Original Opps from Opportunities Ids collected
         Map<id,Opportunity> oldIdnewOpp =new Map<id,Opportunity>();
         Map<Id, Opportunity> mapIdOriginalToOpp = new Map<Id, Opportunity>(); 
         //PRDOPS25-947: Removal of Cloud_Partner_Led_Activity__c, Polaris_Portal_Contact__c ,Cloud_Type__c, Holdover_Requested__c ,Holdover_Extension__c field reference from debooking opportunity for specific fields
         List<Opportunity> originalOppsList=[SELECT id,name,accountid,Focused_Partner_Calc__c, National_Partner_Calc__c,ACV_Amount__c,StageName,Renewal_Subsumed_ACV__c, Subsumed_Renewal_TCV__c, New_Expansion_ACV__c, New_Expansion_TCV__c, ForecastCategoryName,Initial_Contacts_Name__c,Business_Unit__c,ownerid,
                                            Deal_Registration_Type__c,SE_Forecast_Category__c,Pricebook2Id,Partner_Lookup__c,Distributor_Lookup__c,In_Forecast_CRO__c, //SAL24-534
                                            Future_State__c,Compelling_Bus_Driver__c,Current_State__c,Cloud_Environment__c,
                                            Negative_Consequences__c,/*Help_Needed_From__c,*/Rubrik_Sales_Engineer__c,Lost_To_Won_Against__c,Positive_Business_Outcomes__c,
                                            Rubrik_CDM_Release_on_source_cluster__c,Customer_AWS_Account_Number__c,Customer_AWS_Account_Region__c,Number_of_CluodON_Products__c,
                                            amount,Referral_Program__c,DB_Type__c,Number_of_TB__c,Cloud_Type__c,Holdover_Extension_End_Date__c,Holdover_Extension_Reason__c,
                                            Installation_Assigned_To__c,Lost_Reason__c,Lost_To__c,Primary_Competitor__c,POC_Stage__c,
                                            Polaris_Region__c,Technical_Validation_Next_Step__c ,Win_Loss_Comments__c,RenewalOwner__c,Alliance_HW_Partner__c,Alliance_Source_Type_SW__c, //SAL22-327 
                                            ETM_Theatre__c,ETM_Area__c,ETM_Region__c,ETM_Territory__c,CDM_Area__c,CDM_Region__c,CDM_Territory__c,CDM_Theatre__c, //SAL24-279
                                            Alliance_Partner_Name__c,ISR_SDR_Oppty_Credit_Total__c,SecondaryOwner__c,SE_Misaligned__c,Strategic_Account__c, Security_Alliance_Contribution__c, Direct_Marketplace__c,Core_PLS_Source__c,Opp_PLS_ETM_Theatre__c,Opp_PLS_ETM_Area__c,Opp_PLS_ETM_Region__c,Opp_PLS_ETM_Territory__c,Opp_PLS_NCD_ETM_Area__c, Opp_PLS_NCD_ETM_Region__c, Opp_PLS_NCD_ETM_Territory__c, Opp_PLS_NCD_ETM_Theatre__c, Opp_PLS_SaaS_ETM_Area__c, Opp_PLS_SaaS_ETM_Region__c, Opp_PLS_SaaS_ETM_Territory__c, Opp_PLS_SaaS_ETM_Theatre__c,Co_Owner__c,SaaS_Co_Owner__c, NCD_Co_Owner__c,PLS_Gap_Deal__c,Managed_Services_Deal_type__c,
                                            Rubrik_Co_Sales_Engineer__c,UCL_Scale_Percentage__c,PLS_SE_Update__c,UK_Govt_Security_Clearance_Required__c //SAL26-173  //SAL26-282 //SAL26-153 //SAL26-393
                                            from Opportunity WHERE  Id IN :oppIdsSet];            // removing VM_Count__c from query SAL24-157  //SAL24-387 deprecated //SAL24-784 
         for(Opportunity opp : originalOppsList){
             Opportunity oppy = opp.clone();
             oppy.StageName='1 Discovery';
             oppy.ForecastCategoryName='Closed';
            String opptyName = oppy.name;
            if(opptyName.length() > 60){
            oppy.Name = opptyName.substring(0, 50) + '...';
            }

             oppy.Polaris_Portal_Contact__c = NULL;
             oppy.Has_Polaris_Product__c=False;
             oldIdnewOpp.put(opp.id,oppy);
             mapIdOriginalToOpp.put(opp.Id, opp);
         }                
     
         //Attach CCR on new debooking Opportunity
         for(Id ccrId : MapOfccrIdAndCCRrecord.keySet()){
             
             if(MapOfccrIdAndCCRrecord.containsKey(ccrId) && MapOfccrIdAndCCRrecord.get(ccrId)?.Booking__c != null && !mapBkgIdToCCRId.containsKey(MapOfccrIdAndCCRrecord.get(ccrId).Booking__c)){
             	mapBkgIdToCCRId.put(MapOfccrIdAndCCRrecord.get(ccrId).Booking__c, ccrId);
             }
             if(oldIdnewOpp.containsKey((MapOfccrIdAndCCRrecord.get(ccrId)).Opportunity__c)){
                 Opportunity newOpp = oldIdnewOpp.get((MapOfccrIdAndCCRrecord.get(ccrId)).Opportunity__c);
                 newOpp.CCR__c = ccrId;
                 newOpp.Opportunity_Type__c='Debooking';
                 newOpp.CloseDate = MapOfccrIdAndCCRrecord.get(ccrId).Effective_End_Date__c; 
                     if(MapOfccrIdAndCCRrecord.get(ccrId).CCR_Type__c == 'Partner Referral Fee'){
                         newOpp.name=newOpp.name+' - '+'Debooking'+' - '+ 'Referral Fee'; 
                         newOpp.Opportunity_Sub_Type__c='Referral Fee';
                         newOpp.amount=MapOfccrIdAndCCRrecord.get(ccrId).Referral_Fee_Amount__c * -1;
                     }else if(Constants.CCR_TYPES.contains(MapOfccrIdAndCCRrecord.get(ccrId).CCR_Type__c)){
                         if(MapOfccrIdAndCCRrecord.get(ccrId).CCR_Type__c=='Change in Booking Policy / De-Risk Decision'){
                            newOpp.name=newOpp.name+' - '+'Debooking'+' - '+ 'De-risk';
                         }   
                         else if(MapOfccrIdAndCCRrecord.get(ccrId).CCR_Type__c=='Non-Payment'){
                            newOpp.name=newOpp.name+' - '+'Debooking'+' - '+ 'Non-Payment';
                         }else if(MapOfccrIdAndCCRrecord.get(ccrId).CCR_Type__c=='Incorrect Order/Mis-quote'){
                            newOpp.name=newOpp.name+' - '+'Debooking'+' - '+ 'Mis-quote';
                         } else if(MapOfccrIdAndCCRrecord.get(ccrId).CCR_Type__c=='Customer Returns / Refunds'){
                            newOpp.name=newOpp.name+' - '+'Debooking'+' - '+ 'Returns/Refunds';
                         }else {
                            newOpp.name=newOpp.name+' - '+'Debooking'+' - '+ 'Replacement';
                         }   
                         if(mapOfCCRIdAndOriginalOrdAmount.containskey(ccrId)) {   
                         if(mapOfCCRIdAndOriginalOrdAmount.get(ccrId) == MapOfccrIdAndCCRrecord.get(ccrId).Amount__c ){
                             newOpp.Opportunity_Sub_Type__c='Full';
                         }else{                         
                             newOpp.Opportunity_Sub_Type__c='Partial';
                           } 
                         }
                         newOpp.amount=MapOfccrIdAndCCRrecord.get(ccrId).Amount__c * -1; 
                     }
                 if(mapIdOriginalToOpp.containsKey((MapOfccrIdAndCCRrecord.get(ccrId)).Opportunity__c)){
                    
                    Opportunity originalOpp =  mapIdOriginalToOpp.get((MapOfccrIdAndCCRrecord.get(ccrId)).Opportunity__c);
		            
                    Decimal percentDebooking = 0.00;
                     if(originalOpp.Amount != 0.00 && originalOpp.Amount != null){
                         percentDebooking = (newOpp.Amount / originalOpp.Amount);
                     }
                    if(MapOfccrIdAndCCRrecord.get(ccrId).CCR_Type__c == 'Unpaid Replacement Debooking'){
                         newOpp.ACV_Amount__c = 0.00;
                    }else{ 
                   if(originalOpp.ACV_Amount__c != null){
                    	newOpp.ACV_Amount__c = /*newOpp.Opportunity_Sub_Type__c != 'Full' &&*/ percentDebooking != null ? (originalOpp.ACV_Amount__c * percentDebooking) : originalOpp.ACV_Amount__c * -1;  
                    }
                  }
                    Decimal renewalACV = 0.00;
                    Decimal expAVC = 0.00;
                    if(MapOfccrIdAndCCRrecord.get(ccrId).CCR_Type__c != 'Unpaid Replacement Debooking'){
                    	renewalACV = originalOpp.Renewal_Subsumed_ACV__c != null ? (percentDebooking * originalOpp.Renewal_Subsumed_ACV__c) : 0.00;
                    	expAVC = originalOpp.New_Expansion_ACV__c != null ? (percentDebooking * originalOpp.New_Expansion_ACV__c) : 0.00;
                    }
                    Decimal renewalTCV = originalOpp.Subsumed_Renewal_TCV__c != null ? (percentDebooking * originalOpp.Subsumed_Renewal_TCV__c) : 0.00;
                    Decimal expTCV = originalOpp.New_Expansion_TCV__c != null ? (percentDebooking * originalOpp.New_Expansion_TCV__c) :  0.00;
             
		     newOpp.Renewal_Subsumed_ACV__c = renewalACV > 0 ? 0.00 : renewalACV;
		     newOpp.Subsumed_Renewal_TCV__c = renewalTCV > 0 ? 0.00 : renewalTCV;
		     newOpp.New_Expansion_ACV__c = expAVC > 0 ? 0.00 : expAVC;
		     newOpp.New_Expansion_TCV__c = expTCV > 0 ? 0.00 : expTCV;

            }
                 if(!mapCCRIdToDebookOpp.containsKey(ccrId)){
                   mapCCRIdToDebookOpp.put(ccrId, newOpp);  
            }
                 debookingOppsToBeInserted.add(newOpp);
              }               
         } 
         }catch(Exception e) {
            errLog.add(LogError.CreateGenericErrorLog(className,e,ERROR_FUNCTIONALITY));
         }
         
     
     }
}