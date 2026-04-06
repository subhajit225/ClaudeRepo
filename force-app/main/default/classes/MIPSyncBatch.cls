global class MIPSyncBatch implements Database.Batchable<sObject>{
    public Id recordId = null;
    global MIPSyncBatch(Id RecordId){
        this.recordId = RecordId;
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Partner_Account__c,(SELECT Id, MIP_Contract__c, Element_Type__c, Contract_Period_Bookings__c, Contract_Period_Bookings_ACV__c , Bookings_Last_Sync_Date__c, Actual_Enrollment_Payout__c, Enrollment_Payout_Rate__c  FROM MIP_Elements__r WHERE (Element_Type__c = \'Total Bookings\' OR Element_Type__c = \'PSNL Bookings\' OR Element_Type__c =\'Enrollment\') AND (RecordType.Name =\'Bookings Element\' OR RecordType.Name =\'Enrollment\')),';
        query += ' Participating_Partner_Accounts__c, End_Date__c, Start_Date__c, Status__c, Fiscal_Period__c FROM MIP_Contract__c WHERE Status__c =\'Approved\' AND IsActive__c = true';
        
        if(recordId != null){
            query += ' AND Id =: recordId';
        }
        //participating accounts , query on Contract - status, start date , end date, account ids
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, list<MIP_Contract__c> mipContractList){
        Map<Id, MIP_Contract__c> mipContractMap = new Map<Id, MIP_Contract__c>();
        List<MIP_Element__c> mipElementList = new List<MIP_Element__c>();
        Map<String, MIP_Account_Contribution__c> mipAccConMap = new Map<String ,MIP_Account_Contribution__c>();
        Map<String, List<MIP_Contract__c>> accContractMap = new Map<String, List<MIP_Contract__c>>();
        Map<Id, Decimal> conTotalBookings = new Map<Id, Decimal>();
        Map<Id, Decimal> conPSNLBookings = new Map<Id, Decimal>();
        Map<String, Decimal> accConTotalBookings = new Map<String, Decimal>();
        Map<String, Decimal> accConPSNLBookings = new Map<String, Decimal>();
        Map<Id, MIP_Account_Contribution__c> mipAccConMapToUpdate = new Map<Id, MIP_Account_Contribution__c>();
		Map<Id,List<MIP_Account_Contribution__c>> mipContractMIPAccConMap = new Map<Id,List<MIP_Account_Contribution__c>>();
        Decimal totalMIPAccContriPSNLBooking;
        
        for(MIP_Contract__c mipCon : mipContractList)
        {
            mipContractMap.put(mipCon.Id, mipCon);
            if(mipCon.MIP_Elements__r.size() > 0)
            mipElementList.addAll(mipCon.MIP_Elements__r);
        }
        
        for(MIP_Account_Contribution__c mipAccCon : [SELECT Id, AccountContractKey__c, MIP_Contract__c, Partner_Account__c, PSNL_Bookings__c, Total_Bookings__c FROM MIP_Account_Contribution__c WHERE MIP_Contract__c IN: mipContractMap.keySet()])
        {
            mipAccConMap.put(mipAccCon.AccountContractKey__c,mipAccCon);
            if(!accContractMap.containsKey(mipAccCon.Partner_Account__c)){
                accContractMap.put(mipAccCon.Partner_Account__c, new List<MIP_Contract__c>{mipContractMap.get(mipAccCon.MIP_Contract__c)});
            }else{
                List<MIP_Contract__c> mipConList = accContractMap.get(mipAccCon.Partner_Account__c);
                mipConList.add(mipContractMap.get(mipAccCon.MIP_Contract__c));
                accContractMap.put(mipAccCon.Partner_Account__c, mipConList);
            }
        }
        
        
        for(Opportunity opp : [SELECT Id, StageName, Partner_Lookup__c, ACV_Amount__c, Amount, Deal_Registration_Type__c, CloseDate from Opportunity WHERE Partner_Lookup__c IN:accContractMap.keySet() AND StageName ='7 Closed Won']){
             
            List<MIP_Contract__c> contrList = accContractMap.get(opp.Partner_Lookup__c);
            for(MIP_Contract__c contractRec : contrList)
            {
                String key = opp.Partner_Lookup__c+'-'+contractRec.Id;
                
                Decimal amountValue = 0;
                String tcvLabel = Label.MIP_Contract_TCV_Fiscal_Period;
                String acvLabel = Label.MIP_Contract_ACV_Fiscal_Period;
                
                if(contractRec.Fiscal_Period__c != null && contractRec.Fiscal_Period__c.contains(tcvLabel)){
                    amountValue = opp.Amount;
                }else{
                    amountValue = opp.ACV_Amount__c;
                }

                if(opp.CloseDate <= mipContractMap.get(contractRec.Id).End_Date__c && opp.CloseDate >= mipContractMap.get(contractRec.Id).Start_Date__c)
                {
                    //accConTotalBookings
                    if(!accConTotalBookings.containsKey(key)){
                        accConTotalBookings.put(key, amountValue);
                    }else{
                        accConTotalBookings.put(key, accConTotalBookings.get(key) + amountValue);
                    }
                    if(!conTotalBookings.containsKey(contractRec.Id)){
                        conTotalBookings.put(contractRec.Id, amountValue);
                    }else{
                        conTotalBookings.put(contractRec.Id, conTotalBookings.get(contractRec.Id) + amountValue);
                    }
                    //PSNL Bookings
                    if(opp.Deal_Registration_Type__c == 'Partner Sourced New Logo (PSNL)'){
                        if(!accConPSNLBookings.containsKey(key)){
                            accConPSNLBookings.put(key, amountValue);
                        }else{
                            accConPSNLBookings.put(key, accConPSNLBookings.get(key) + amountValue);
                        }
                        
                        if(!conPSNLBookings.containsKey(contractRec.Id)){
                            conPSNLBookings.put(contractRec.Id, amountValue);
                        }else{
                            conPSNLBookings.put(contractRec.Id, conPSNLBookings.get(contractRec.Id) + amountValue);
                        }
                    }
                }
            }
        }
        
        //update mip element PSNL/Total Bookings
        for(MIP_Element__c mipElement : mipElementList){
            if(conTotalBookings.containsKey(mipElement.MIP_Contract__c) && mipElement.Element_Type__c == 'Total Bookings')
            {
                mipElement.Contract_Period_Bookings_ACV__c = conTotalBookings.get(mipElement.MIP_Contract__c);
                mipElement.Bookings_Last_Sync_Date__c = date.today();
            }
            if(conPSNLBookings.containsKey(mipElement.MIP_Contract__c) && mipElement.Element_Type__c == 'PSNL Bookings')
            {
                mipElement.Contract_Period_Bookings_ACV__c = conPSNLBookings.get(mipElement.MIP_Contract__c);
                mipElement.Bookings_Last_Sync_Date__c = date.today();
            }
        }
        
        //update junction object
        for(MIP_Account_Contribution__c mipAccCon : mipAccConMap.values()){
            if(accConTotalBookings.containsKey(mipAccCon.AccountContractKey__c)){
                if(mipAccCon.Total_Bookings__c != accConTotalBookings.get(mipAccCon.AccountContractKey__c)){
                    mipAccCon.Total_Bookings__c = accConTotalBookings.get(mipAccCon.AccountContractKey__c);
                    mipAccConMapToUpdate.put(mipAccCon.Id, mipAccCon);
                }
            }
            if(accConPSNLBookings.containsKey(mipAccCon.AccountContractKey__c)){
                if(mipAccCon.PSNL_Bookings__c != accConPSNLBookings.get(mipAccCon.AccountContractKey__c)){
                    mipAccCon.PSNL_Bookings__c = accConPSNLBookings.get(mipAccCon.AccountContractKey__c);
                    mipAccConMapToUpdate.put(mipAccCon.Id, mipAccCon);
                }
            }
			
			if(!mipContractMIPAccConMap.containsKey(mipAccCon.MIP_Contract__c)){
				mipContractMIPAccConMap.put(mipAccCon.MIP_Contract__c, new List<MIP_Account_Contribution__c> {mipAccCon});
			}else{
				mipContractMIPAccConMap.get(mipAccCon.MIP_Contract__c).add(mipAccCon);
            }
        }
        
		
		//PRIT24-417
		//Populate MIP element Enrollment's Actual_Enrollment_Payout__c
		for(MIP_Element__c mipElement : mipElementList){
            if(mipElement.Element_Type__c == 'Enrollment' && mipContractMIPAccConMap.containsKey(mipElement.MIP_Contract__c)){
				totalMIPAccContriPSNLBooking = 0;
                system.debug('mipContractMIPAccConMap.get(mipElement.MIP_Contract__c)->'+mipContractMIPAccConMap.get(mipElement.MIP_Contract__c));
				for(MIP_Account_Contribution__c mipAccCont : mipContractMIPAccConMap.get(mipElement.MIP_Contract__c)){
                    system.debug('mipAccCont->'+mipAccCont.PSNL_Bookings__c);
					totalMIPAccContriPSNLBooking = totalMIPAccContriPSNLBooking + mipAccCont.PSNL_Bookings__c;
				}
				mipElement.Actual_Enrollment_Payout__c = totalMIPAccContriPSNLBooking * 0.01 * mipElement.Enrollment_Payout_Rate__c;
			}
		}
		
        
        List<Database.SaveResult> mipElementResult = Database.update(mipElementList, false);
        List<Database.SaveResult> mipAccConResult = Database.update(mipAccConMapToUpdate.values(), false);
        
        List<Custom_Error_Log__c> customErrorLogList = new List<Custom_Error_Log__c>();
        for(Integer i = 0 ; i < mipElementResult.size(); i++){
            Custom_Error_Log__c errorLogRec = new Custom_Error_Log__c();
            errorLogRec.Class__c = 'MIPSyncBatch';
            errorLogRec.Functionality__c = 'Recalculate MIP Contract';
            if(!mipElementResult.get(i).isSuccess() ){
                Database.Error dbError = mipElementResult.get(i).getErrors().get(0);
                errorLogRec.Exception_Message__c = dbError.getMessage();
                errorLogRec.FailedRecords__c  =mipElementList.get(i).Id;
                customErrorLogList.add(errorLogRec);
            }
        }
        for(Integer i=0; i < mipAccConResult.size(); i++){
            Custom_Error_Log__c errorLogRec = new Custom_Error_Log__c();
            errorLogRec.Class__c = 'MIPSyncBatch';
            errorLogRec.Functionality__c = 'Update Account Contract junction object';
            if(!mipAccConResult.get(i).isSuccess() ){
                Database.Error dbError = mipAccConResult.get(i).getErrors().get(0);
                errorLogRec.Exception_Message__c = dbError.getMessage();
                errorLogRec.FailedRecords__c  = mipAccConMapToUpdate.values().get(i).Id;
                customErrorLogList.add(errorLogRec);
            }
        }
        if(customErrorLogList.size()>0){
            insert customErrorLogList;
        }
        
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
}