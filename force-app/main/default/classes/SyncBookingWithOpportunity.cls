/***************************************************************
* @description       : SyncBookingWithOpportunity class to sync booking based on Opportunity  
* @author            : Shrutika
* @last modified on  : 01-08-2026
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
* Modifications Log 
* Ver   Date          Author        Modification
************************************************************/

public class SyncBookingWithOpportunity {
    
    @AuraEnabled
    public static response_Wrapper updateBLIAndRelatedBooking(string opptyId, Boolean isUpdateBook, Boolean isUpdateBLI , Boolean isUpdateBSplit){

        response_Wrapper response = new response_Wrapper();
        Map<Id, Booking_Line_Item__c> mapBLIIdtoBLIRecords = new Map<Id, Booking_Line_Item__c>();
        Map<Id, Decimal> mapBKGIdToRebate = new Map<Id, Decimal>(); // Distributor Fee
        Map<Id, Booking_Line_Item__c> mapOppIdToPRFRecord = new Map<Id, Booking_Line_Item__c>(); // PRF
       // Map<Id, Decimal> mapOrgOppIdToAmount = new Map<Id, Decimal>(); //original Amount
        Map<Id, Decimal> mapBKGIdToGrossTCV = new Map<Id, Decimal>();
        Map<Id, Decimal> mapBKGIdToNewTCV = new Map<Id, Decimal>();
        Map<Id, Decimal> mapBKGIdToRenewalTCV = new Map<Id, Decimal>();
        Map<Id, Decimal> mapBKGIdToGrossACV = new Map<Id, Decimal>();
        Map<Id, Decimal> mapBKGIdToNewACV = new Map<Id, Decimal>();
        Map<Id, Decimal> mapBKGIdToRenewalACV = new Map<Id, Decimal>();
		List<string> splitOppField = new list<string>();
        
        	
        List<Booking_Line_Item__c> lstUpdateBLI = new List<Booking_Line_Item__c>();
        Map<Id, Booking_Line_Item__c> mapBKGIdToBLIRecord = new Map<Id, Booking_Line_Item__c>();
        List<Booking_Line_Item__c> lstBLIRecords = [SELECT Id, Net_TCV_Amount__c, OrderProduct__r.Opportunity_Product__r.Quantity, OrderProduct__r.Quantity, OrderProduct__r.TotalPrice, Booking__r.Order__c, CCR__r.Opportunity__r.Amount, CCR__r.Opportunity__r.New_Expansion_TCV__c, CCR__r.Opportunity__r.Subsumed_Renewal_TCV__c, 
        CCR__r.Opportunity__r.ACV_Amount__c, CCR__r.Opportunity__r.New_Expansion_ACV__c, CCR__r.Opportunity__r.Renewal_Subsumed_ACV__c,
        CCR__c, CCR__r.Opportunity__c, Total_Price__c, OrderProduct__r.Opportunity_Product__r.Opportunity.Opportunity_Sub_Type__c, New_Expansion_TCV__c, Gross_New_Expansion_ACV__c, Subsumed_Renewal_TCV__c,
                                                    Gross_Subsumed_Renewal_ACV__c, Gross_ACV_Amount__c, OrderProduct__c, OrderProduct__r.Opportunity_Product__c, Type__c,
                                                    PromoDiscTCV__c,Prepayment_Credit__c,Oppty_Trade_Up_Discount__c,
                                                    OrderProduct__r.Opportunity_Product__r.New_Expansion_TCV__c,
                                                    OrderProduct__r.Opportunity_Product__r.Subsumed_Renewal_TCV__c,
                                                    OrderProduct__r.Opportunity_Product__r.New_Expansion_ACV__c	,
                                                    OrderProduct__r.Opportunity_Product__r.Subsumed_Renewal_Amount__c,
                                                    OrderProduct__r.Opportunity_Product__r.ACV_Amount__c,
                                                    OrderProduct__r.Opportunity_Product__r.PromoDiscTCV__c,
                                                    OrderProduct__r.Opportunity_Product__r.Oppty_Trade_Up_Discount__c,
                                                    OrderProduct__r.Opportunity_Product__r.Prepayment_Credit__c,
                                                    Booking__r.Field_Update_Status__c, Booking__r.Opportunity__c, Rebate__c,
                                                    Booking__r.Opportunity__r.New_Expansion_TCV__c, Booking__r.Opportunity__r.Subsumed_Renewal_TCV__c,
                                                    Booking__r.Opportunity__r.ACV_Amount__c, Booking__r.Opportunity__r.New_Expansion_ACV__c, 
                                                    Booking__r.Opportunity__r.Renewal_Subsumed_ACV__c, OrderProduct__r.Opportunity_Product__r.TotalPrice
                                               		FROM Booking_Line_Item__c 
                                                    WHERE Booking__r.Opportunity__c = : opptyId
                                                    Order by createdDate ASC];// ASC 
        system.debug('::lstBLIRecords::'+lstBLIRecords.size()); // lstBLIRecords[0].Booking__r.Order = 'Opp doesn't contains order'
        if(lstBLIRecords.isEmpty()){
            response.isSuccess = false;
            response.errorMessage = 'Booking Line Items are not Present!';
            return response;
        }
        else if(lstBLIRecords[0].Booking__r.Order__c == null){
            response.isSuccess = false;
            response.errorMessage = 'Opportunity doesn\'t contains the Order';
            return response;
        }else if(lstBLIRecords[0].Booking__r.Field_Update_Status__c != null){
            response.isSuccess = false;
            response.errorMessage = 'Booking record can not update as this is freezed';
            return response;
        }else {
            if(!lstBLIRecords.isEmpty()){
                mapBKGIdToBLIRecord.put(lstBLIRecords[0].Booking__c, lstBLIRecords[0]);
                for(Booking_Line_Item__c objBLI :lstBLIRecords){
                    
                    mapBLIIdtoBLIRecords.put(objBLI.Id, objBLI);
                    
                    if(objBLI.Type__c == 'Distributor Fee' && objBLI.Total_Price__c < 0){ //-ve add condition
                        mapBKGIdToRebate.put(objBLI.Booking__c, objBLI.Rebate__c);
                    }else if(objBLI.Type__c == 'Partner Referral Fee' && objBLI.CCR__c != null){
                       // mapOrgOppIdToAmount.put(objBLI.CCR__r.Opportunity__c, objBLI.CCR__r.Opportunity__r.Amount);
                        mapOppIdToPRFRecord.put(objBLI.OrderProduct__r.Opportunity_Product__r.OpportunityId, objBLI);
                    }else {
                        Decimal qtyFactor =  (objBLI.OrderProduct__r.Opportunity_Product__c != null && objBLI.OrderProduct__r.Opportunity_Product__r.Quantity != null && objBLI.OrderProduct__r.Quantity != 0.0) ? objBLI.OrderProduct__r.Quantity/objBLI.OrderProduct__r.Opportunity_Product__r.Quantity : 1;
                                    Decimal grossTCV = null;
                                    Decimal newTCV = null;
                                    Decimal renewalTCV = null;
                                    Decimal grossACV = null;
                                    Decimal grossNewACV = null;
                                    Decimal grossRenewalACV = null;
                                    
                                    if(objBLI.OrderProduct__r.Opportunity_Product__c != null){
                                        grossTCV = objBLI.OrderProduct__r.TotalPrice;
                                        newTCV = objBLI.OrderProduct__r.Opportunity_Product__r?.New_Expansion_TCV__c == null ? 0.0 :(objBLI.OrderProduct__r.Opportunity_Product__r?.New_Expansion_TCV__c * qtyFactor) ;
                                        renewalTCV = objBLI.OrderProduct__r.Opportunity_Product__r?.Subsumed_Renewal_TCV__c == null ? 0.0 :(objBLI.OrderProduct__r.Opportunity_Product__r?.Subsumed_Renewal_TCV__c * qtyFactor) ; 
                                    	grossACV = objBLI.OrderProduct__r.Opportunity_Product__r?.ACV_Amount__c == null ? 0.0 :(objBLI.OrderProduct__r.Opportunity_Product__r?.ACV_Amount__c * qtyFactor) ;
                                        grossNewACV = objBLI.OrderProduct__r.Opportunity_Product__r?.New_Expansion_ACV__c == null ? 0.0 :(objBLI.OrderProduct__r.Opportunity_Product__r?.New_Expansion_ACV__c * qtyFactor) ;
                                        grossRenewalACV = objBLI.OrderProduct__r.Opportunity_Product__r?.Subsumed_Renewal_Amount__c == null ? 0.0 :(objBLI.OrderProduct__r.Opportunity_Product__r?.Subsumed_Renewal_Amount__c * qtyFactor) ;  
                                    }
                        
                        if(objBLI.Booking__r.Order__c != null && objBLI.OrderProduct__r.Opportunity_Product__c != null){
                            if(grossTCV != null){
                            
                                if(!mapBKGIdToGrossTCV.containsKey(objBLI.Booking__c)){
                                    mapBKGIdToGrossTCV.put(objBLI.Booking__c, grossTCV );
                                }else {
                                    mapBKGIdToGrossTCV.put(objBLI.Booking__c, mapBKGIdToGrossTCV.get(objBLI.Booking__c) + grossTCV);

                                }
                            }   
                            if(newTCV != null){
                                if(!mapBKGIdToNewTCV.containsKey(objBLI.Booking__c)){
                                    mapBKGIdToNewTCV.put(objBLI.Booking__c, newTCV );
                                }else {
                                    mapBKGIdToNewTCV.put(objBLI.Booking__c, mapBKGIdToNewTCV.get(objBLI.Booking__c) + newTCV);
                                }
                            }

                            if(renewalTCV  != null){
                                if(!mapBKGIdToRenewalTCV.containsKey(objBLI.Booking__c)){
                                    mapBKGIdToRenewalTCV.put(objBLI.Booking__c, renewalTCV );
                                }else {
                                    mapBKGIdToRenewalTCV.put(objBLI.Booking__c, mapBKGIdToRenewalTCV.get(objBLI.Booking__c) + renewalTCV);
                                }
                            }
                            if(grossACV  != null){
                                if(!mapBKGIdToGrossACV.containsKey(objBLI.Booking__c)){
                                    mapBKGIdToGrossACV.put(objBLI.Booking__c, grossACV );
                                }else {
                                    mapBKGIdToGrossACV.put(objBLI.Booking__c, mapBKGIdToGrossACV.get(objBLI.Booking__c) + grossACV);
                                }
                            }
                         if(grossNewACV  != null){
                                if(!mapBKGIdToNewACV.containsKey(objBLI.Booking__c)){
                                    mapBKGIdToNewACV.put(objBLI.Booking__c, grossNewACV );
                                }else {
                                    mapBKGIdToNewACV.put(objBLI.Booking__c, mapBKGIdToNewACV.get(objBLI.Booking__c) + grossNewACV);
                                }
                            }
                            if(grossRenewalACV  != null){
                                if(!mapBKGIdToRenewalACV.containsKey(objBLI.Booking__c)){
                                    mapBKGIdToRenewalACV.put(objBLI.Booking__c, grossRenewalACV );
                                }else {
                                    mapBKGIdToRenewalACV.put(objBLI.Booking__c, mapBKGIdToRenewalACV.get(objBLI.Booking__c) + grossRenewalACV);
                                }
                            }


                        }
                                    

                    }
                    
                }

                if(!mapBLIIdtoBLIRecords.isEmpty()){

                    for(Booking_Line_Item__c obBLI : mapBLIIdtoBLIRecords.values()){


                        if(obBLI.Type__c == 'Distributor Fee'){
                            lstUpdateBLI.add(new Booking_Line_Item__c (Id = obBLI.Id,
                            New_Expansion_TCV__c = mapBKGIdToNewTCV.containsKey(obBLI.Booking__c) && mapBKGIdToNewTCV.get(obBLI.Booking__c) != null ? mapBKGIdToNewTCV.get(obBLI.Booking__c)  * obBLI.Rebate__c  * -0.01 : obBLI.New_Expansion_TCV__c,  
                            Subsumed_Renewal_TCV__c = mapBKGIdToRenewalTCV.containsKey(obBLI.Booking__c) && mapBKGIdToRenewalTCV.get(obBLI.Booking__c) != null ? mapBKGIdToRenewalTCV.get(obBLI.Booking__c) * obBLI.Rebate__c  * -0.01 : obBLI.Subsumed_Renewal_TCV__c,  
                            Gross_ACV_Amount__c = mapBKGIdToGrossACV.containsKey(obBLI.Booking__c) && mapBKGIdToGrossACV.get(obBLI.Booking__c) != null ? mapBKGIdToGrossACV.get(obBLI.Booking__c) * obBLI.Rebate__c  * -0.01 : obBLI.Gross_ACV_Amount__c,  
                            Gross_New_Expansion_ACV__c = mapBKGIdToNewACV.containsKey(obBLI.Booking__c) && mapBKGIdToNewACV.get(obBLI.Booking__c) != null ? mapBKGIdToNewACV.get(obBLI.Booking__c) * obBLI.Rebate__c  * -0.01 : obBLI.Gross_New_Expansion_ACV__c,  
                            Gross_Subsumed_Renewal_ACV__c = mapBKGIdToRenewalACV.containsKey(obBLI.Booking__c) && mapBKGIdToRenewalACV.get(obBLI.Booking__c) != null ? mapBKGIdToRenewalACV.get(obBLI.Booking__c) * obBLI.Rebate__c  * -0.01 : obBLI.Gross_Subsumed_Renewal_ACV__c
                            ));
                           

                        }else if(obBLI.Type__c == 'Partner Referral Fee' && obBLI.CCR__c != null){
                            if(mapOppIdToPRFRecord.containsKey(obBLI.CCR__r.Opportunity__c)){
                                
                               // Booking_Line_Item__c  PRF_Bli = mapOppIdToPRFRecord.get(obBLI.CCR__r.Opportunity__c);
                                Booking_Line_Item__c objPRF = new Booking_Line_Item__c (Id = obBLI.Id);
                                objPRF.Gross_ACV_Amount__c = objPRF.Net_ACV_Amount__c = obBLI.Total_Price__c * (obBLI.CCR__r.Opportunity__r.ACV_Amount__c / obBLI.CCR__r.Opportunity__r.Amount);
                                objPRF.Net_New_Expansion_ACV__c = objPRF.Gross_New_Expansion_ACV__c =  objPRF.Gross_ACV_Amount__c * (obBLI.CCR__r.Opportunity__r.New_Expansion_ACV__c / obBLI.CCR__r.Opportunity__r.ACV_Amount__c);
                                objPRF.Net_Subsumed_Renewal_ACV__c = objPRF.Gross_Subsumed_Renewal_ACV__c = objPRF.Gross_ACV_Amount__c * (obBLI.CCR__r.Opportunity__r.Renewal_Subsumed_ACV__c / obBLI.CCR__r.Opportunity__r.ACV_Amount__c);
                                objPRF.Net_New_Expansion_TCV__c = objPRF.New_Expansion_TCV__c =  obBLI.Total_Price__c * (obBLI.CCR__r.Opportunity__r.New_Expansion_TCV__c / obBLI.CCR__r.Opportunity__r.Amount);
                                objPRF.Net_Subsumed_Renewal_TCV__c = objPRF.Subsumed_Renewal_TCV__c =  obBLI.Total_Price__c * (obBLI.CCR__r.Opportunity__r.Subsumed_Renewal_TCV__c / obBLI.CCR__r.Opportunity__r.Amount);
                                lstUpdateBLI.add(objPRF);					    
                                                            
                            }
                        }
                        else{

                        if(obBLI?.OrderProduct__r?.Opportunity_Product__c != null){
                            
                            Decimal rebatePercentage = mapBKGIdToRebate.containsKey(obBLI?.Booking__c) ? mapBKGIdToRebate.get(obBLI?.Booking__c) : 0;
                            system.debug('::rebatePercentage::'+rebatePercentage);
                            system.debug('::mapBKGIdToRebate::'+mapBKGIdToRebate);
                            Decimal qtyFactor =  (obBLI.OrderProduct__r.Opportunity_Product__c != null && obBLI.OrderProduct__r.Quantity != null && obBLI.OrderProduct__r.Quantity != 0.0) ? obBLI.OrderProduct__r.Quantity/obBLI.OrderProduct__r.Opportunity_Product__r.Quantity : 1;
                            Decimal promoDiscTCV = obBLI?.OrderProduct__r?.Opportunity_Product__r?.PromoDiscTCV__c != null ? (obBLI?.OrderProduct__r?.Opportunity_Product__r.PromoDiscTCV__c * qtyFactor): 0.0;
                            Decimal opptyTradeUpDiscount = obBLI?.OrderProduct__r?.Opportunity_Product__r?.Oppty_Trade_Up_Discount__c != null ? (obBLI?.OrderProduct__r?.Opportunity_Product__r.Oppty_Trade_Up_Discount__c * qtyFactor): 0.0;
                            Decimal prepaymentCredit = obBLI?.OrderProduct__r?.Opportunity_Product__r?.Prepayment_Credit__c != null ? (obBLI?.OrderProduct__r?.Opportunity_Product__r.Prepayment_Credit__c * qtyFactor): 0.0;
                            //< -1 or >1
                            Decimal newExpTCVDiff = obBLI?.OrderProduct__r?.Opportunity_Product__r?.New_Expansion_TCV__c != null  ? ((obBLI?.OrderProduct__r?.Opportunity_Product__r?.New_Expansion_TCV__c * qtyFactor) -( obBLI.New_Expansion_TCV__c ?? 0) ) : 0;
                            Decimal renwalTCVDiff = obBLI?.OrderProduct__r?.Opportunity_Product__r?.Subsumed_Renewal_TCV__c != null  ? ((obBLI?.OrderProduct__r?.Opportunity_Product__r?.Subsumed_Renewal_TCV__c * qtyFactor) - (obBLI.Subsumed_Renewal_TCV__c ?? 0)) : 0;
                            Decimal newExpACVDiff = obBLI?.OrderProduct__r?.Opportunity_Product__r?.New_Expansion_ACV__c != null  ? ((obBLI?.OrderProduct__r?.Opportunity_Product__r?.New_Expansion_ACV__c * qtyFactor) - (obBLI.Gross_New_Expansion_ACV__c ?? 0)) : 0;
                            Decimal renewalACVDiff = obBLI?.OrderProduct__r?.Opportunity_Product__r?.Subsumed_Renewal_Amount__c != null  ? ((obBLI?.OrderProduct__r?.Opportunity_Product__r?.Subsumed_Renewal_Amount__c * qtyFactor) - (obBLI.Gross_Subsumed_Renewal_ACV__c ?? 0)) : 0;
                            Decimal grossACVDiff = obBLI?.OrderProduct__r?.Opportunity_Product__r?.ACV_Amount__c != null  ?  ((obBLI?.OrderProduct__r?.Opportunity_Product__r?.ACV_Amount__c * qtyFactor) - (obBLI.Gross_ACV_Amount__c ?? 0) ): 0;
                            

                            if(newExpTCVDiff <= -1 || newExpTCVDiff >= 1 || renwalTCVDiff <= -1 || renwalTCVDiff >= 1 || newExpACVDiff <= -1 || newExpACVDiff >= 1 ||
                            renewalACVDiff <= -1 || renewalACVDiff >= 1 || grossACVDiff <= -1 || grossACVDiff >= 1 || hasSignificantDifference(obBLI.PromoDiscTCV__c, promoDiscTCV) ||
                                    hasSignificantDifference(obBLI.Oppty_Trade_Up_Discount__c, opptyTradeUpDiscount) ||
                                    hasSignificantDifference(obBLI.Prepayment_Credit__c, prepaymentCredit)) {
                           system.debug('::newExpTCVDiff::'+newExpTCVDiff);
                            Booking_Line_Item__c bliOb = new Booking_Line_Item__c(Id = obBLI.Id);
                            bliOb.Net_TCV_Amount__c = ((obBLI?.OrderProduct__r?.TotalPrice ?? 0) * ((100 - rebatePercentage)* 0.01)).setScale(2, RoundingMode.HALF_UP);
                            
                            bliOb.New_Expansion_TCV__c =  obBLI?.OrderProduct__r?.Opportunity_Product__r?.New_Expansion_TCV__c != null ? (obBLI?.OrderProduct__r?.Opportunity_Product__r?.New_Expansion_TCV__c * qtyFactor) : 0;
                            bliOb.Net_New_Expansion_TCV__c =bliOb.New_Expansion_TCV__c != null ? (bliOb.New_Expansion_TCV__c * ((100 - rebatePercentage)* 0.01)).setScale(2, RoundingMode.HALF_UP) : 0;
                                
                            bliOb.Subsumed_Renewal_TCV__c =  obBLI?.OrderProduct__r?.Opportunity_Product__r?.Subsumed_Renewal_TCV__c != null ? (obBLI.OrderProduct__r.Opportunity_Product__r.Subsumed_Renewal_TCV__c * qtyFactor) : 0;
                            bliOb.Net_Subsumed_Renewal_TCV__c = bliOb.Subsumed_Renewal_TCV__c != null ? (bliOb.Subsumed_Renewal_TCV__c * ((100 - rebatePercentage)* 0.01)).setScale(2, RoundingMode.HALF_UP) : 0;
                                
                            bliOb.Gross_New_Expansion_ACV__c =  obBLI?.OrderProduct__r?.Opportunity_Product__r?.New_Expansion_ACV__c != null ? obBLI.OrderProduct__r.Opportunity_Product__r.New_Expansion_ACV__c * qtyFactor : 0;
                            bliOb.Net_New_Expansion_ACV__c = bliOb.Gross_New_Expansion_ACV__c != null ? (bliOb.Gross_New_Expansion_ACV__c * ((100 - rebatePercentage)* 0.01)).setScale(2, RoundingMode.HALF_UP) : 0;
                            bliOb.Gross_Subsumed_Renewal_ACV__c =  obBLI?.OrderProduct__r?.Opportunity_Product__r?.Subsumed_Renewal_Amount__c != null ? obBLI.OrderProduct__r.Opportunity_Product__r.Subsumed_Renewal_Amount__c * qtyFactor : 0;
                            bliOb.Net_Subsumed_Renewal_ACV__c = bliOb.Gross_Subsumed_Renewal_ACV__c != null ? (bliOb.Gross_Subsumed_Renewal_ACV__c * ((100 - rebatePercentage)* 0.01)).setScale(2, RoundingMode.HALF_UP) : 0;
                            bliOb.Gross_ACV_Amount__c =  obBLI?.OrderProduct__r?.Opportunity_Product__r?.ACV_Amount__c != null ? obBLI.OrderProduct__r.Opportunity_Product__r.ACV_Amount__c * qtyFactor : 0;
                            bliOb.Net_ACV_Amount__c = bliOb.Gross_ACV_Amount__c != null ? (bliOb.Gross_ACV_Amount__c * ((100 - rebatePercentage)* 0.01)).setScale(2, RoundingMode.HALF_UP) : 0;
                            bliOb.PromoDiscTCV__c = promoDiscTCV;
                            bliOb.Oppty_Trade_Up_Discount__c = opptyTradeUpDiscount;
                            bliOb.Prepayment_Credit__c = prepaymentCredit;    
                            
                             if(bliOb != null)
                                lstUpdateBLI.add(bliOb);
                            
                            }
                        }

                        }
                    }

                }
            }
            Boolean isUpdateBookingRecord = Boolean.valueOf(Order_control__mdt.getInstance('isUpdateBookingRecord').Value__c);
            Boolean isUpdateBLIRecord = Boolean.valueOf(Order_control__mdt.getInstance('isUpdateBLIRecord').Value__c);
            Boolean isUpdateBSplitRecord = Boolean.valueOf(Order_control__mdt.getInstance('isUpdateBSplitRecord').Value__c);
            
            system.debug('::lstUpdateBLI::'+lstUpdateBLI);
            system.debug('::isUpdateBLIRecord::'+isUpdateBLIRecord);
            system.debug('::isUpdateBLI::'+isUpdateBLI);
            if(!lstUpdateBLI.isEmpty() && isUpdateBLIRecord && isUpdateBLI)
                update lstUpdateBLI;
                list<Booking__c> lstUpdateBooking = getBookingRecords(opptyId);
            if(!lstUpdateBooking.isEmpty() && isUpdateBookingRecord && isUpdateBook){
                
                system.debug('::lstUpdateBooking::'+lstUpdateBooking);
                update lstUpdateBooking;
                
            }
            list<Booking_Split__c> lstUpdateBSplit = getBookingSplitRecords(opptyId);
            if(!lstUpdateBSplit.isEmpty() && isUpdateBSplitRecord && isUpdateBSplit){
                update lstUpdateBSplit;
            }
            return response;
        }

        //return null;
    }

    public static List<Booking__c> getBookingRecords(Id opptyId){
        List<Booking_Sync_Mapping__mdt> bookingSyncMapsList =[SELECT Booking_Field_name__c, Opportunity_Field_Name__c,Type__c,
                                                                       (SELECT Booking_API_Name__c,Operator__c,Booking_Value__c FROM ConfigureBookingSyncs__r LIMIT 1000)
                                                                      FROM Booking_Sync_Mapping__mdt LIMIT 1000];  
    
        String finalQuery='';
        String whereClause= '';
        for(Booking_Sync_Mapping__mdt b : bookingSyncMapsList)
        {
            for(integer i=0;i<b.ConfigureBookingSyncs__r.size();i++)
            {
                 whereClause =  ' '+b.ConfigureBookingSyncs__r[i].Booking_API_Name__c   +' '+b.ConfigureBookingSyncs__r[i].Operator__c +
                                ' '+b.ConfigureBookingSyncs__r[i].Booking_Value__c+' AND Opportunity__c = : opptyId';
            }
       } 
       
       string tempString='';     
            for (Integer i = 0; i < bookingSyncMapsList.size(); i++)
            {
                if (i == 0){
                    finalQuery = 'Select  ' + bookingSyncMapsList[i].Booking_Field_name__c + ' , ' + bookingSyncMapsList[i].Opportunity_Field_Name__c;
                    tempString += bookingSyncMapsList[i].Booking_Field_name__c;
                }else{
                    finalQuery += ' , ' + bookingSyncMapsList[i].Booking_Field_name__c+ ' , ' + bookingSyncMapsList[i].Opportunity_Field_Name__c;    
                    tempString += ' , ' + bookingSyncMapsList[i].Booking_Field_name__c;     
                }         
                if (i == bookingSyncMapsList.size() - 1)
                    finalQuery += ' ,id,Field_Update_Status__c,CreatedDate,BookingName__c,(select id ,Field_Update_Status__c, ' +tempString+' from BookingAdjustments__r) FROM Booking__c where '+ WhereClause ;               
             }
			 
			 system.debug('::finalQuery::'+finalQuery);
             List<Booking__c> bookingListQuery = Database.query(finalQuery); 
             List<string> splitOppField = new list<string>();
             List<Booking__c> lstBooking = new List<Booking__c>();
             if(!bookingListQuery.isEmpty()){
             for(Booking__c oBooking : bookingListQuery){
                Booking__c bookingRecord =new Booking__c(id=oBooking.id);
                     
                     if(!bookingSyncMapsList.isEmpty()){
                         for(Booking_Sync_Mapping__mdt bookingMap : bookingSyncMapsList){ 
                            splitOppField = bookingMap.Opportunity_Field_Name__c.split('\\.');
                             sObject bkgSobj = oBooking;
                             for (Integer i = 0; i < (splitOppField.size() - 1) && bkgSobj != null; i++)
                             {
                                 if (bkgSobj.getSObject(splitOppField[i]) == null)
                                 {
                                                bkgSobj = null;
                                                break;
                                 }                     
                                 bkgSobj = bkgSobj.getSObject(splitOppField[i]);
                             }
                             if(String.isBlank(oBooking.Field_Update_Status__c))
                             {
                                  if (bkgSobj != null && bkgSobj.get(splitOppField.get(splitOppField.size() - 1)) != null)
                                  {             
                                      if(oBooking.get(bookingMap.Booking_Field_name__c) != bkgSobj.get(splitOppField.get(splitOppField.size() - 1))){  
                                          bookingRecord.put(bookingMap.Booking_Field_name__c, bkgSobj.get(splitOppField.get(splitOppField.size() - 1)));
                                      }
                                  }  
                              }

                         }
                    }
                    lstBooking.add(bookingRecord);
             }}

        
             if(!lstBooking.isEmpty())
                return lstBooking;
                else 
                return null;
    }

    public static List<Booking_Split__c> getBookingSplitRecords(Id opptyId){
        List<Booking_Split__c> lstUpdateSplitBooking = new List<Booking_Split__c>();
        List<Booking_Split__c> lstBSplit = [Select Id,Booking__c, Opportunity__c,Sales_Rep__c,Opportunity_Split__c,
        Opportunity__r.OwnerId, Opportunity__r.Split_percentage__c, Opportunity__r.ETM_Theatre__c,
        Opportunity__r.ETM_Area__c, Opportunity__r.ETM_Region__c, Opportunity__r.ETM_Territory__c,
        Theatre__c,Area__c,Region__c,Territory__c,Opportunity__r.Opportunity_Split_Parent__c,
        Opportunity__r.Opp_PLS_ETM_Area__c, Opportunity__r.Opp_PLS_ETM_Region__c, Opportunity__r.Opp_PLS_ETM_Territory__c, Opportunity__r.Opp_PLS_ETM_Theatre__c,Opportunity__r.Opp_PLS_NCD_ETM_Area__c, Opportunity__r.Opp_PLS_NCD_ETM_Region__c, Opportunity__r.Opp_PLS_NCD_ETM_Territory__c, Opportunity__r.Opp_PLS_NCD_ETM_Theatre__c, Opportunity__r.Opp_PLS_SaaS_ETM_Area__c, Opportunity__r.Opp_PLS_SaaS_ETM_Region__c, Opportunity__r.Opp_PLS_SaaS_ETM_Territory__c, Opportunity__r.Opp_PLS_SaaS_ETM_Theatre__c
        from Booking_Split__c Where Opportunity__c  = : opptyId] ;

        if(!lstBSplit.isEmpty()){
            for(Booking_Split__c obSplit : lstBSplit){
                lstUpdateSplitBooking.add(new Booking_Split__c(Id = obSplit.Id, 
                Sales_Rep__c = obSplit.Opportunity__r.OwnerId ?? null,
                Opportunity_Split__c = obSplit.Opportunity__r.Split_percentage__c ?? null, 
                Theatre__c = obSplit.Opportunity__r.ETM_Theatre__c ?? null,
                Area__c = obSplit.Opportunity__r.ETM_Area__c ?? null,
                Region__c = obSplit.Opportunity__r.ETM_Region__c ?? null,
                Territory__c = obSplit.Opportunity__r.ETM_Territory__c ?? null,
                Opp_PLS_ETM_Region__c = obSplit.Opportunity__r.Opp_PLS_ETM_Region__c ?? null,
                Opp_PLS_ETM_Area__c = obSplit.Opportunity__r.Opp_PLS_ETM_Area__c ?? null,
                Opp_PLS_ETM_Territory__c = obSplit.Opportunity__r.Opp_PLS_ETM_Territory__c ?? null,
                Opp_PLS_ETM_Theatre__c = obSplit.Opportunity__r.Opp_PLS_ETM_Theatre__c ?? null,Opp_PLS_NCD_ETM_Region__c = obSplit.Opportunity__r.Opp_PLS_NCD_ETM_Region__c ?? null,
                Opp_PLS_NCD_ETM_Area__c = obSplit.Opportunity__r.Opp_PLS_NCD_ETM_Area__c ?? null,
                Opp_PLS_NCD_ETM_Territory__c = obSplit.Opportunity__r.Opp_PLS_NCD_ETM_Territory__c ?? null,
                Opp_PLS_NCD_ETM_Theatre__c = obSplit.Opportunity__r.Opp_PLS_NCD_ETM_Theatre__c ?? null,
                Opp_PLS_SaaS_ETM_Region__c = obSplit.Opportunity__r.Opp_PLS_SaaS_ETM_Region__c ?? null,
                Opp_PLS_SaaS_ETM_Area__c = obSplit.Opportunity__r.Opp_PLS_SaaS_ETM_Area__c ?? null,
                Opp_PLS_SaaS_ETM_Territory__c = obSplit.Opportunity__r.Opp_PLS_SaaS_ETM_Territory__c ?? null,
                Opp_PLS_SaaS_ETM_Theatre__c = obSplit.Opportunity__r.Opp_PLS_SaaS_ETM_Theatre__c ?? null));  
            }
        }
        if(!lstUpdateSplitBooking.isEmpty()){
            return lstUpdateSplitBooking;
        }else {
            return null;
        }
        
    }


    /**
   * @description Method to return true or false if given numbers has some difference
   * @param previousVal
   * @param currentValue
   * @return Boolean if there is significantDifference
   */
    public static Boolean hasSignificantDifference(Decimal previousVal, Decimal currentValue){
        previousVal = previousVal != null ? previousVal : 0;
        currentValue = currentValue != null ? currentValue : 0;
        Decimal diffVal = (currentValue - previousVal); 
        if(diffVal >= 1 || diffVal <= -1){
            return true;
        }
        return false;
    }
    public class response_Wrapper {
        @auraEnabled public boolean isSuccess{get;set;}
        @auraEnabled public string errorMessage  {get;set;}
        
        public response_Wrapper(){
            this.isSuccess = true;
            this.errorMessage = '';
        }
    }
  
}