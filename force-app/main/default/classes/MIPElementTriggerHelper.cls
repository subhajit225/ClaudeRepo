public without sharing class MIPElementTriggerHelper {
    private static string BookingElementRecordId = Schema.SObjectType.MIP_Element__c.getRecordTypeInfosByName().get('Bookings Element').getRecordTypeId();
    private static string RebateMilestoneRecordId = Schema.SObjectType.MIP_Element__c.getRecordTypeInfosByName().get('Rebate Milestone').getRecordTypeId();
    private static string FundedHeadRecordId = Schema.SObjectType.MIP_Element__c.getRecordTypeInfosByName().get('Funded Head').getRecordTypeId();
	private static string EnrollmentRecordId = Schema.SObjectType.MIP_Element__c.getRecordTypeInfosByName().get('Enrollment').getRecordTypeId();

    //Populate Max Total on Contract on Element Insert
    public void populateBookingsTotals(Map<Id,MIP_Element__c> newEleMap){
        Map<Id,Decimal> contractIDMaxTotalRebateInsertMap =  new Map<Id,Decimal>();
        //Map<Id,Decimal> contractIDMaxROIInsertMap =  new Map<Id,Decimal>();
        Set<ID> contractIdSet = new Set<Id>();
        Set<Id> eleInsertSet = new Set<Id>();
        //Map<Id,Decimal> contractIdOldTotalRebateMap = new Map<Id,Decimal>();
        Map<Id,Decimal> contractIdOldMaxTotalRebateInsertMap = new Map<Id,Decimal>();

        for(MIP_Element__c eleMIP : newEleMap.values()){
            //Max Total Rebate Calculation
            if(eleMIP.RecordTypeId == BookingElementRecordId && eleMIP.Max_Bookings_Payout__c != null && (eleMIP.Element_Type__c == 'PSNL Bookings' || eleMIP.Element_Type__c == 'Total Bookings')){
                if(!contractIDMaxTotalRebateInsertMap.containsKey(eleMIP.MIP_Contract__c)){
                    contractIDMaxTotalRebateInsertMap.put(eleMIP.MIP_Contract__c, eleMIP.Max_Bookings_Payout__c);
                }else{
                    contractIDMaxTotalRebateInsertMap.put(eleMIP.MIP_Contract__c, contractIDMaxTotalRebateInsertMap.get(eleMIP.MIP_Contract__c) + eleMIP.Max_Bookings_Payout__c);
                }
                contractIdSet.add(eleMIP.MIP_Contract__c);
                eleInsertSet.add(eleMIP.Id);
            }

            //Max ROI Calculation
            /*if(eleMIP.RecordTypeId == BookingElementRecordId && eleMIP.Max_Bookings_ROI__c != null && (eleMIP.Element_Type__c == 'PSNL Bookings' || eleMIP.Element_Type__c == 'Total Bookings')){
                if(!contractIDMaxROIInsertMap.containsKey(eleMIP.MIP_Contract__c)){
                    contractIDMaxROIInsertMap.put(eleMIP.MIP_Contract__c, eleMIP.Max_Bookings_ROI__c);
                }else{
                    contractIDMaxROIInsertMap.put(eleMIP.MIP_Contract__c, contractIDMaxROIInsertMap.get(eleMIP.MIP_Contract__c) + eleMIP.Max_Bookings_ROI__c);
                }
                contractIdSet.add(eleMIP.MIP_Contract__c);
            }*/
        }

        List<MIP_Contract__c> contractsToUpdateList = [SELECT ID,
                                                            (SELECT ID,Name,Actual_Bookings_Payout__c,Actual_Milestone_Payout__c,Max_Bookings_Payout__c,MIP_Contract__c
                                                            FROM MIP_Elements__r
                                                            WHERE RecordTypeId !=: FundedHeadRecordId AND ID NOT IN: eleInsertSet),Name,Actual_Rebate_ROI__c,Max_Rebate_ROI__c,Actual_Rebate_Payout__c,Max_Rebate_Payout__c,Actual_Total_Milestone_Payout__c,MDF_Payout__c,SPIFF_Payout__c
                                                        FROM MIP_Contract__c
                                                        WHERE ID IN:contractIdSet];
        //Updates on Contract
        if(!contractsToUpdateList.isEmpty()){
            for(MIP_Contract__c con : contractsToUpdateList){
                for(MIP_Element__c ele : con.MIP_Elements__r){
                    if(!contractIdOldMaxTotalRebateInsertMap.containsKey(ele.MIP_Contract__c)){
                        contractIdOldMaxTotalRebateInsertMap.put(ele.MIP_Contract__c, ele.Max_Bookings_Payout__c);
                    }else{
                        contractIdOldMaxTotalRebateInsertMap.put(ele.MIP_Contract__c, contractIdOldMaxTotalRebateInsertMap.get(ele.MIP_Contract__c) + ele.Max_Bookings_Payout__c);
                    }
                }

                if(contractIDMaxTotalRebateInsertMap.containsKey(con.Id) && contractIDMaxTotalRebateInsertMap.get(con.Id) != null && contractIdOldMaxTotalRebateInsertMap.containsKey(con.Id) && contractIdOldMaxTotalRebateInsertMap.get(con.Id) != null){
                    con.Max_Rebate_Payout__c = contractIDMaxTotalRebateInsertMap.get(con.Id) + contractIdOldMaxTotalRebateInsertMap.get(con.Id);
                }else if(contractIDMaxTotalRebateInsertMap.containsKey(con.Id) && contractIDMaxTotalRebateInsertMap.get(con.Id) != null){
                    con.Max_Rebate_Payout__c = contractIDMaxTotalRebateInsertMap.get(con.Id);
                }
                /*if(contractIDMaxROIInsertMap.containsKey(con.Id) && contractIDMaxROIInsertMap.get(con.Id) != null && con.Max_Rebate_ROI__c != contractIDMaxROIInsertMap.get(con.Id)){
                    con.Max_Rebate_ROI__c = contractIDMaxROIInsertMap.get(con.Id);
                }*/
            }
        }

        if(!contractsToUpdateList.isEmpty()){
            System.debug('contractsToUpdateList'+contractsToUpdateList);
            Update contractsToUpdateList;
        }
    }

    //Populate Max Total/Actual Total on Contract on Element Update
    public void calculateBookingsTotals(List<MIP_Element__c> newEleList, Map<Id,MIP_Element__c> oldEleMap){
        Map<Id,Decimal> contractIDTotalRebateMap =  new Map<Id,Decimal>();
        Map<Id,Decimal> contractIDMaxTotalRebateMap =  new Map<Id,Decimal>();
        //Map<Id,Decimal> contractIDActualROIMap =  new Map<Id,Decimal>();
        //Map<Id,Decimal> contractIDMaxROIMap =  new Map<Id,Decimal>();
        Set<ID> contractIdSet = new Set<Id>();
        Set<Id> eleUpdatedSet = new Set<Id>();
        Map<Id,Decimal> contractIdOldTotalRebateMap = new Map<Id,Decimal>();
        Map<Id,Decimal> contractIdOldMaxTotalRebateMap = new Map<Id,Decimal>();
		Map<Id,MIP_Element__c> contractIdEnrollmentPayMap = new Map<Id,MIP_Element__c>();
		boolean actualRebatePayoutCalculated = false;
		boolean maxRebatePayoutCalculated = false; 

        for(MIP_ELement__c eleMIP : newEleList){
            //Commented as part of PRIT24-429 as to include Max Enrollment Payout in Max Total Rebate Payout at contract level
            //if(eleMIP.RecordTypeId == BookingElementRecordId && eleMIP.Max_Bookings_Payout__c != oldEleMap.get(eleMIP.Id).Actual_Bookings_Payout__c && (eleMIP.Element_Type__c == 'PSNL Bookings' || eleMIP.Element_Type__c == 'Total Bookings')){
            
            //Max Total Rebate Calculation
            if(eleMIP.RecordTypeId == BookingElementRecordId &&  (eleMIP.Element_Type__c == 'PSNL Bookings' || eleMIP.Element_Type__c == 'Total Bookings')){
                if(!contractIDMaxTotalRebateMap.containsKey(eleMIP.MIP_Contract__c)){
                    contractIDMaxTotalRebateMap.put(eleMIP.MIP_Contract__c, eleMIP.Max_Bookings_Payout__c);
                }else{
                    contractIDMaxTotalRebateMap.put(eleMIP.MIP_Contract__c, contractIDMaxTotalRebateMap.get(eleMIP.MIP_Contract__c) + eleMIP.Max_Bookings_Payout__c);
                }
                contractIdSet.add(eleMIP.MIP_Contract__c);
                eleUpdatedSet.add(eleMIP.Id);
            }

            //Actual Total Rebate Calculation
            if(eleMIP.RecordTypeId == BookingElementRecordId && (eleMIP.Element_Type__c == 'PSNL Bookings' || eleMIP.Element_Type__c == 'Total Bookings')){
                if(!contractIDTotalRebateMap.containsKey(eleMIP.MIP_Contract__c)){
                    contractIDTotalRebateMap.put(eleMIP.MIP_Contract__c, eleMIP.Actual_Bookings_Payout__c);
                }else{
                    contractIDTotalRebateMap.put(eleMIP.MIP_Contract__c, contractIDTotalRebateMap.get(eleMIP.MIP_Contract__c) + eleMIP.Actual_Bookings_Payout__c);
                }
                contractIdSet.add(eleMIP.MIP_Contract__c);
                eleUpdatedSet.add(eleMIP.Id);
            }

				
            //PRIT24-429
            //Update 'Actual Total Rebate Payout' Field to include 'Actual Enrollment Payout'
            if((eleMIP.RecordTypeId == EnrollmentRecordId && eleMIP.Element_Type__c == 'Enrollment' )|| (eleMIP.RecordTypeId == BookingElementRecordId && eleMIP.Element_Type__c == 'PSNL Bookings')){
                contractIdSet.add(eleMIP.MIP_Contract__c);
            }
				
            //Actual ROI Calculation
            /*if(eleMIP.RecordTypeId == BookingElementRecordId && eleMIP.Actual_Bookings_ROI__c != oldEleMap.get(eleMIP.Id).Actual_Bookings_ROI__c && (eleMIP.Element_Type__c == 'PSNL Bookings' || eleMIP.Element_Type__c == 'Total Bookings')){
                if(!contractIDActualROIMap.containsKey(eleMIP.MIP_Contract__c)){
                    contractIDActualROIMap.put(eleMIP.MIP_Contract__c, eleMIP.Actual_Bookings_ROI__c);
                }else{
                    contractIDActualROIMap.put(eleMIP.MIP_Contract__c, contractIDActualROIMap.get(eleMIP.MIP_Contract__c) + eleMIP.Actual_Bookings_ROI__c);
                }
                contractIdSet.add(eleMIP.MIP_Contract__c);
            }*/

            //Max ROI Calculation
            /*if(eleMIP.RecordTypeId == BookingElementRecordId && eleMIP.Max_Bookings_ROI__c != null && (eleMIP.Element_Type__c == 'PSNL Bookings' || eleMIP.Element_Type__c == 'Total Bookings')){
                if(!contractIDMaxROIMap.containsKey(eleMIP.MIP_Contract__c)){
                    contractIDMaxROIMap.put(eleMIP.MIP_Contract__c, eleMIP.Max_Bookings_ROI__c);
                }else{
                    contractIDMaxROIMap.put(eleMIP.MIP_Contract__c, contractIDMaxROIMap.get(eleMIP.MIP_Contract__c) + eleMIP.Max_Bookings_ROI__c);
                }
                contractIdSet.add(eleMIP.MIP_Contract__c);
            }*/
        }

        List<MIP_Contract__c> contractsToUpdateList = [SELECT ID,
														   (SELECT ID,Name,Actual_Bookings_Payout__c,Actual_Milestone_Payout__c,Actual_Enrollment_Payout__c,Max_Bookings_Payout__c,MIP_Contract__c, Element_Type__c, Max_Enrollment_Payout__c 
                                                            FROM MIP_Elements__r
                                                            WHERE RecordTypeId !=: FundedHeadRecordId AND ID NOT IN: eleUpdatedSet),Name,Actual_Rebate_ROI__c,Max_Rebate_ROI__c,Actual_Rebate_Payout__c,Max_Rebate_Payout__c,Actual_Total_Milestone_Payout__c,MDF_Payout__c,SPIFF_Payout__c
                                                        FROM MIP_Contract__c
                                                        WHERE ID IN:contractIdSet];
        //Updates on Contract
        if(!contractsToUpdateList.isEmpty()){
            for(MIP_Contract__c con : contractsToUpdateList){
                for(MIP_Element__c ele : con.MIP_Elements__r){
                    if(!contractIdOldTotalRebateMap.containsKey(ele.MIP_Contract__c)){
                        contractIdOldTotalRebateMap.put(ele.MIP_Contract__c, ele.Actual_Bookings_Payout__c);
                    }else{
                        contractIdOldTotalRebateMap.put(ele.MIP_Contract__c, contractIdOldTotalRebateMap.get(ele.MIP_Contract__c) + ele.Actual_Bookings_Payout__c);
                    }

                    if(!contractIdOldMaxTotalRebateMap.containsKey(ele.MIP_Contract__c)){
                        contractIdOldMaxTotalRebateMap.put(ele.MIP_Contract__c, ele.Max_Bookings_Payout__c);
                    }else{
                        contractIdOldMaxTotalRebateMap.put(ele.MIP_Contract__c, contractIdOldMaxTotalRebateMap.get(ele.MIP_Contract__c) + ele.Max_Bookings_Payout__c);
                    }
						
					if(!contractIdEnrollmentPayMap.containsKey(ele.MIP_Contract__c) && ele.Element_Type__c == 'Enrollment' && ele.Actual_Enrollment_Payout__c != null && ele.Max_Enrollment_Payout__c != null){
						contractIdEnrollmentPayMap.put(ele.MIP_Contract__c, ele);
                }
				}
				
				
                if(contractIDTotalRebateMap.containsKey(con.Id) && contractIDTotalRebateMap.get(con.Id) != null && contractIdOldTotalRebateMap.containsKey(con.Id) && contractIdOldTotalRebateMap.get(con.Id) != null){
                    con.Actual_Rebate_Payout__c = contractIDTotalRebateMap.get(con.Id) + contractIdOldTotalRebateMap.get(con.Id);
					actualRebatePayoutCalculated = true;
                }else if(contractIDTotalRebateMap.containsKey(con.Id) && contractIDTotalRebateMap.get(con.Id) != null){
                    con.Actual_Rebate_Payout__c = contractIDTotalRebateMap.get(con.Id);
					actualRebatePayoutCalculated = true;
                }

                if(contractIDMaxTotalRebateMap.containsKey(con.Id) && contractIDMaxTotalRebateMap.get(con.Id) != null && contractIdOldMaxTotalRebateMap.containsKey(con.Id) && contractIdOldMaxTotalRebateMap.get(con.Id) != null){
                    con.Max_Rebate_Payout__c = contractIDMaxTotalRebateMap.get(con.Id) + contractIdOldMaxTotalRebateMap.get(con.Id);
					maxRebatePayoutCalculated = true;
                }else if(contractIDMaxTotalRebateMap.containsKey(con.Id) && contractIDMaxTotalRebateMap.get(con.Id) != null){
                    con.Max_Rebate_Payout__c = contractIDMaxTotalRebateMap.get(con.Id);
					maxRebatePayoutCalculated = true;
                }

				//PRIT24-429
                //Update 'Actual Total Rebate Payout' Field to include 'Actual Enrollment Payout'
                if(contractIdEnrollmentPayMap.containsKey(con.Id) && actualRebatePayoutCalculated){
                    con.Actual_Rebate_Payout__c = con.Actual_Rebate_Payout__c + contractIdEnrollmentPayMap.get(con.Id).Actual_Enrollment_Payout__c;
                }else if(contractIdEnrollmentPayMap.containsKey(con.Id) && !actualRebatePayoutCalculated){
					con.Actual_Rebate_Payout__c = contractIdEnrollmentPayMap.get(con.Id).Actual_Enrollment_Payout__c;
				}
				
				//PRIT24-429
				//Update 'Max Total Rebate Payout' Field to include 'Max Enrollment Payout'
				if(contractIdEnrollmentPayMap.containsKey(con.Id) && maxRebatePayoutCalculated){
                    con.Max_Rebate_Payout__c = con.Max_Rebate_Payout__c + contractIdEnrollmentPayMap.get(con.Id).Max_Enrollment_Payout__c;
                }else if(contractIdEnrollmentPayMap.containsKey(con.Id) && !maxRebatePayoutCalculated){
					con.Max_Rebate_Payout__c = contractIdEnrollmentPayMap.get(con.Id).Max_Enrollment_Payout__c;
                }

                /*if(contractIDActualROIMap.containsKey(con.Id) && contractIDActualROIMap.get(con.Id) != null && con.Actual_Rebate_ROI__c != contractIDActualROIMap.get(con.Id)){
                    con.Actual_Rebate_ROI__c = contractIDActualROIMap.get(con.Id);
                }
                if(contractIDMaxROIMap.containsKey(con.Id) && contractIDMaxROIMap.get(con.Id) != null && con.Max_Rebate_ROI__c != contractIDMaxROIMap.get(con.Id)){
                    con.Max_Rebate_ROI__c = contractIDMaxROIMap.get(con.Id);
                }*/
            }
        }

        if(!contractsToUpdateList.isEmpty()){
            System.debug('contractsToUpdateList'+contractsToUpdateList);
            Update contractsToUpdateList;
        }
    }
}