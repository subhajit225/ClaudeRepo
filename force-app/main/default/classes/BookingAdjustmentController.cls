/************************************************************************************
Date : June 2019  
@description : Booking adjustment for customer returns,
              partner referal fee
              Non-payment 
              De-risk decision 
Developer : Chaitra
*******************************History***********************************************
Date            Modification        Author               Description
*************************************************************************************
June 2019         Intital           Chaitra
June 2023       PRDOPS26-21         Prashik             Line Based Partial Debooking
*************************************************************************************/
public with sharing class BookingAdjustmentController {
    
    /* ERROR and Validation collection */
    public static final string QUANTITY_ERROR ='Cannot adjust a greater quantity of [ProdName] than what was ordered [Quantity]';
    public static final string DEBOOK_ERROR ='Debook Amount $[Debook] cannot be a greater amount than the total line amount  $[Total] for [ProdName] '; //PRDOPS26-21
    public static final string ZERO_DEBOOK_ERROR ='Debook Amount cannot be a $0 for [ProdName] '; //PRDOPS26-21
    public static final string INVALID_ADJUSTMENT ='CCR should be linked to booking to make adjustments';
    public static final string ADJUSTMENT_TYPE_ERROR = 'This adjustment is applicable only for is only for LineItem based debooking' ;
    public static final string ADJUSTMENT_STATUS_ERROR = 'Cannot adjust line items once CCR is submitted or approved' ;
    public static final string POSITIVE_AMOUNT_VALIDATION ='Please enter positive amount for booking adjustment';
    public static final string OVER_AMOUNT_VALIDATION ='Combined booking adjustment amount should not exceed the total booking amount.';
    public static final string ORDERTOTAL_AMOUNT_VALIDATION = 'Debooked amount cannot be greater than order total';
    public static final string NO_BOOKINGLINEITEM_ERROR ='Booking has no LineItems';
    public static final string EFFECTIVEDATE_VALIDATION = 'Please enter Effective date';
    public static final string NO_ITEMS_SELECTED_ERROR = 'Select at least one record for submission';
    
    /* END ERROR and Validation collection */
    /** @description List of Order Items */
    public List<OrderItem> OIList;
    /** @description Id of the Order record */
    public Id orderId;
    /** @description Stores Selected Adjustment Type */
    public string selectedAType{get;set;}
    /** @description Stores Selected Return Type */
    public string selectedReturnType{get;set;}
    /** @description This stores the input for Return Amount Type */
    public string selectedReturnAmountType{get;set;} //PRDOPS26-21
    /** @description Total Adjustment Price */
    public transient Decimal adjustmentTotalPrice{get;set;}  
    /** @description Existing CCR Amount */
    public transient Decimal CRRAmount{get;set;}
    /** @description List of Wrapper Lines */
    public List<LineItems> orderLineItems {get;set;} 
    /** @description Map of already selected adjustment Ids and Adjustment records */
    public Map<Id,Booking_AdjustmentItems__c> AddedAdjustments {get;set;} 
    /** @description Map of Order Item Id and existing De-booked Amount */
    public Map<Id,Decimal> mapOfOLIvsDebookedAmount {get;set;}  //PRDOPS26-21
    /** @description List of exisiting Booking Adjustment Item List */
    public List<Booking_AdjustmentItems__c> existingAdjustmentItemList {get;set;}
    /** @description Flag to decide if to show/hide the line item table */
    public boolean displayLineItem{get;set;}
    /** @description CCR Record */
    public CCR__c CCR{get;set;}
    /** @description List of CCR Records */
    public List<CCR__c> ccrList{get;set;}
    /** @description CCR Amount  */
    public decimal currentCCRAmount{get;set;}
    /** @description Set of current Adjustment Order Item Id's */
    public set<Id> currentAdjustmentOrderItemIdSet{get;set;}
    /** @description Effective Date for De-booking */
    public string effectiveDate {get;set;}
    /** @description Order Record */
    public Order ord{get;set;}
    /** @description If trues displays the Submit button on the VF Page Form */
    public boolean showSubmit {get;set;}
    /** @description Index of the Selected Row */
    public integer selectedRowIndex{get;set;}
    /** @description This identifies if the transaction is performed to create or update ccr */
    public boolean updateadjustments {get;set;}
    /** @description This stores the row index for order lines */
    public Set<integer> error_RowIndex{get;set;}
    /** @description This stores the inout for Comments */
    public string commentsinput {get;set; }
    /** @description Option List for reason options */
    public List<SelectOption> reasonOptions { get;set;}
    /** @description Map of Quote Line Item Id and Opportunity Product */
    public Map<Id, OpportunityLineItem>  mapOriginalQLIToOppLI {get;set;}
    
  
    /*************************************************************************
    @description :  a) Used for customer returns/refund data history rendering
                    b) To set onLoad collections
    **************************************************************************/
    
    public BookingAdjustmentController(){
        displayLineItem = false;
        String bkngId='';
        currentCCRAmount = 0;
        currentAdjustmentOrderItemIdSet = new set<id>();
        orderLineItems = new List<LineItems>();
        OIList = new List<OrderItem>();
        error_RowIndex = new Set<integer>();
        showSubmit = false;
        CCR = new CCR__c();
        mapOriginalQLIToOppLI = new Map<Id, OpportunityLineItem>();
        selectedReturnAmountType = 'Complete'; //PRDOPS26-21
        try{
            String ccrID = ApexPages.currentPage().getParameters().get('CCRId');
            if(ccrID != null){
                updateadjustments = true;
                ccr = [select id,Booking__c,Booking__r.Order__c,User__c,CCR_Type__c,Comment__c,Effective_Date__c,Customer_Returns_type__c,Return_Reasons__c,Impacts_Commission__c,Return_Amount_Type__c from CCR__c where id=:ccrID];
                bkngId =  ccr.Booking__c;
                
                effectivedate = string.valueOf(ccr.Effective_Date__c);
                selectedAType = ccr.CCR_Type__c;
                selectedReturnType = ccr.Customer_Returns_type__c;
                selectedReturnAmountType = String.isNotBlank(ccr.Return_Amount_Type__c) ? ccr.Return_Amount_Type__c : selectedReturnAmountType; //PRDOPS26-21
                if(ccr.Booking__c != null)
                    orderId = ccr.Booking__r.Order__c ;
                else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error,INVALID_ADJUSTMENT));
                }
                
                if((ccr.CCR_Type__c !=Label.PartnerReferrals)&& ccr.User__c.equalsIgnoreCase('Pending')|| ccr.User__c.equalsIgnoreCase('Rejected')){
                    if(selectedReturnType=='Amount Based')
                        showSubmit = false;
                }
                else{
                    if(ccr.CCR_Type__c == Label.PartnerReferrals
                    || (ccr.CCR_Type__c !=Label.PartnerReferrals
                         && (ccr.Customer_Returns_type__c=='Amount Based' 
                            ||ccr.Customer_Returns_type__c==null))){
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error,ADJUSTMENT_TYPE_ERROR));
                            }  
                    else if(ccr.User__c.equalsIgnoreCase('Approved')|| ccr.User__c.equalsIgnoreCase('Submitted')){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error,ADJUSTMENT_STATUS_ERROR));
                    }
                    return ;
                }
                returnTypeSelected();
                calculateTotalPrice(); 
                
            }    
            else{
                selectedAType = Label.None; 
                String orderId1 =ApexPages.currentPage().getParameters().get('ordId');
                if(String.isNotBlank(orderId1)){
                    orderId = orderId1.escapeHtml4();
                }
                updateadjustments = false;
            }
            
            if(ApexPages.currentPage().getParameters().get('Id')!=null )
            {
                bkngId = ApexPages.currentPage().getParameters().get('Id');
            }       
            system.debug(logginglevel.DEBUG,'bkngId::'+bkngId );
            ccrList = [select id,Amount__c,CCR_Type__c,Referral_Fee_Amount__c, (select id,OrderLineItemId__c from Booking_AdjustmentItems__r) from CCR__c where Booking__c =: bkngId AND User__c!='Rejected'];
            system.debug(logginglevel.DEBUG,'ccrList::'+ccrList );
            for(CCR__c ccrObj : ccrList)
            {
                if(ccrObj.CCR_Type__c != 'Partner Referral Fee'){
                if(ccrObj.Amount__c!=null && ccrObj.Amount__c!=0)
                {
                         currentCCRAmount = currentCCRAmount+ ccrObj.Amount__c;
                }
                else if(ccrObj.Referral_Fee_Amount__c!=null && ccrObj.Referral_Fee_Amount__c!=0)
                {
                         currentCCRAmount = currentCCRAmount+ ccrObj.Referral_Fee_Amount__c;
                }
                }                
                for(Booking_AdjustmentItems__c bookingAdjstmentObj : ccrObj.Booking_AdjustmentItems__r)
                {
                    currentAdjustmentOrderItemIdSet.add(bookingAdjstmentObj.OrderLineItemId__c);
                }
            }
            system.debug(logginglevel.DEBUG,'currentCCRAmount::'+currentCCRAmount );
            system.debug(logginglevel.DEBUG,'currentAdjustmentOrderItemIdSet::'+currentAdjustmentOrderItemIdSet );
                
                
            ord = [select accountId,opportunityId,TotalAmount,Opportunity.OwnerId from order where Id =: orderId];
        }
        Catch(exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Warning,e.getMessage()));
        }
    }

    /**
     * @description This method sets the effective date
     */
    public void setDate()
    {   
        String effectiveDate1 = Apexpages.currentPage().getParameters().get('effDate');
        if(String.isNotBlank(effectiveDate1)){
            effectiveDate = effectiveDate1.escapeHtml4();
        }
    }
    
    /**
     * @description This method returns the options for Adjustment Type
     * @return List<SelectOption>
     */
    public List<SelectOption> getAdjustmentType() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(Label.None,Label.None));
        options.add(new SelectOption(Label.ReturnsOrRefund,Label.ReturnsOrRefund));
        options.add(new SelectOption(Label.BookingPolicyOrDe_RiskDecision,Label.BookingPolicyOrDe_RiskDecision));
        options.add(new SelectOption(Label.IncorrectOrder_MisQuote,Label.IncorrectOrder_MisQuote));
        options.add(new SelectOption(Label.latenonpayments,Label.latenonpayments));
        options.add(new SelectOption(Label.Unpaid_Replacement_Debooking,Label.Unpaid_Replacement_Debooking));
        return options;
    }
    /**
     * @description This method returns the options for Return Type
     * @return List<SelectOption>
     */
    public List<SelectOption> getReturnsType() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Amount Based','Amount Based De-booking'));
        options.add(new SelectOption('LineItem Based','Order Line Item Based De-booking'));
        return options;
    }
    /**
     * @description This method returns the options for Return Amount Type
     * @return List<SelectOption>
     */
    public List<SelectOption> getReturnsAmountType() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Complete','Complete'));
        options.add(new SelectOption('Partial','Partial'));
        return options;
    }
    
    /**
     * @description This method handles the Type Selection
     */
    public void typeSelected(){
        if(selectedAType !=  Label.BookingPolicyOrDe_RiskDecision && selectedAType != Label.IncorrectOrder_MisQuote){
            CCR.Impacts_Commission__c = true;
        }
        displayLineItem = false;
        showSubmit = true;
        if(selectedAType !=Label.PartnerReferrals){
               selectedReturnType='Amount Based'; // Default customer returns type
        }
    }

    /**
     * @description This method handles the changes to the Return Type selection.
     */
    public void returnTypeSelected(){
        showSubmit = true;
        if(selectedReturnType=='Amount Based'){
            displayLineItem = false;
            selectedReturnAmountType = 'Complete';
            return;
        }
        else{
            displayLineItem = true;
        }
        AddedAdjustments = new map<Id,Booking_AdjustmentItems__c>();
        Set<Id> setOriginalQLIIds = new Set<Id>();
        adjustmentTotalPrice = 0.0 ;
        if(OIList.size()==0){
            if(updateadjustments == true){
                String ccrId = ApexPages.currentPage().getParameters().get('CCRId');
                for(Booking_AdjustmentItems__c AddedItem : [select id,OrderLineItemId__c,Quantity__c from Booking_AdjustmentItems__c where CCR__c=:ccrId]){
                    AddedAdjustments.put((Id)AddedItem.OrderLineItemId__c,AddedItem);
                }
            }  
            OIList = [SELECT Id,Quantity,Product2.Name,totalprice,UnitPrice,Order.AccountId,order.OpportunityId,order.Opportunity.OwnerId,Product2.License_Type__c,
                      Product2.Description,Product2.Category__c,Product2.ProductCode,Product2.Family,Product2Id,Product2.Product_Payment_Option__c,SBQQ__SubscriptionTerm__c,SBQQ__QuoteLine__c, SBQQ__QuoteLine__r.SBQQ__TotalDiscountRate__c
                      FROM OrderItem WHERE OrderId =:orderId] ;
            //Start PRDOPS26-21
            if(existingAdjustmentItemList == null || existingAdjustmentItemList.size()==0){
                mapOfOLIvsDebookedAmount = new Map<Id,Decimal>();
                existingAdjustmentItemList = [SELECT Id,OrderLineItemId__c,Adjusted_Item_Total_Price__c FROM Booking_AdjustmentItems__c WHERE CCR__r.Booking__r.Order__c =:orderId AND CCR__r.User__c!='Rejected'];
                if(!existingAdjustmentItemList.isEmpty()){
                    for(Booking_AdjustmentItems__c adjItem : existingAdjustmentItemList){
                        if(mapOfOLIvsDebookedAmount.containskey(adjItem.OrderLineItemId__c)){
                            mapOfOLIvsDebookedAmount.put((Id)adjItem.OrderLineItemId__c,mapOfOLIvsDebookedAmount.get(adjItem.OrderLineItemId__c)+adjItem.Adjusted_Item_Total_Price__c);
                        }
                        else{
                            mapOfOLIvsDebookedAmount.put((Id)adjItem.OrderLineItemId__c,adjItem.Adjusted_Item_Total_Price__c);
                        }
                        system.debug(logginglevel.DEBUG,'mapOfOLIvsDebookedAmount >>> '+mapOfOLIvsDebookedAmount);
                    }
                }
            }
            //End PRDOPS26-21        
            for(OrderItem OI: OIList){
                setOriginalQLIIds.add(OI.SBQQ__QuoteLine__c);
                Decimal debookedAmount = !mapOfOLIvsDebookedAmount.isEmpty() && mapOfOLIvsDebookedAmount.containsKey(OI.id) ? mapOfOLIvsDebookedAmount.get(OI.Id) : 0; //PRDOPS26-21
                if(AddedAdjustments.containskey(OI.id)){
                    system.debug(logginglevel.DEBUG,'IN IF');
                    orderLineItems.add(new LineItems(AddedAdjustments.get(OI.id).id,true,OI.Product2.Name,AddedAdjustments.get(OI.id).Quantity__c,OI.Quantity,OI.Id,OI.UnitPrice,
                                                     OI.Product2.License_Type__c,OI.Product2.Category__c,OI.Product2.ProductCode,OI.Product2.Description,OI.Product2.Family,OI.Product2Id,
                                                     OI.Product2.Product_Payment_Option__c,OI.SBQQ__SubscriptionTerm__c,OI.SBQQ__QuoteLine__r.SBQQ__TotalDiscountRate__c,true, OI.SBQQ__QuoteLine__c,0,false,debookedAmount));
                }
                else{
                    system.debug(logginglevel.DEBUG,'IN Else::'+currentAdjustmentOrderItemIdSet );
                    if(currentAdjustmentOrderItemIdSet!=null && !currentAdjustmentOrderItemIdSet.isEmpty() && currentAdjustmentOrderItemIdSet.contains(OI.Id))
                    {
                        orderLineItems.add(new LineItems(null,false,OI.Product2.Name,OI.Quantity,OI.Quantity,OI.Id,OI.UnitPrice,OI.Product2.License_Type__c,OI.Product2.Category__c,OI.Product2.ProductCode,OI.Product2.Description,OI.Product2.Family,OI.Product2Id,
                                                         OI.Product2.Product_Payment_Option__c,OI.SBQQ__SubscriptionTerm__c,OI.SBQQ__QuoteLine__r.SBQQ__TotalDiscountRate__c,true, OI.SBQQ__QuoteLine__c,0,false,debookedAmount));
                    }
                    else {
                        orderLineItems.add(new LineItems(null,false,OI.Product2.Name,OI.Quantity,OI.Quantity,OI.Id,OI.UnitPrice,OI.Product2.License_Type__c,OI.Product2.Category__c,OI.Product2.ProductCode,OI.Product2.Description,OI.Product2.Family,OI.Product2Id,
                                                         OI.Product2.Product_Payment_Option__c,OI.SBQQ__SubscriptionTerm__c,OI.SBQQ__QuoteLine__r.SBQQ__TotalDiscountRate__c,false, OI.SBQQ__QuoteLine__c,0,false,debookedAmount));
                    }
                }
            }
            
            for(OpportunityLineItem objOppLI :[SELECT Id, SBQQ__QuoteLine__c,Subsumed_Renewal_Amount__c, Subsumed_Renewal_TCV__c,New_Expansion_ACV__c, New_Expansion_TCV__c, Renewal_TCV__c
                                               FROM OpportunityLineItem
                                               WHERE SBQQ__QuoteLine__c	 IN : setOriginalQLIIds]){
                     
                mapOriginalQLIToOppLI.put(objOppLI.SBQQ__QuoteLine__c, objOppLI);
            }
        }
        
        
        if(OIList.size()==0){
            displayLineItem = showSubmit =false; 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.info,NO_BOOKINGLINEITEM_ERROR));
            return;
        }    
    }

    /**
     * @description This method handles return amount type changes
     */
    public void returnAmountTypeSelected(){
        for(LineItems OI: orderLineItems){
            OI.selectDisabled = true;
            OI.debookAmount = 0;
            OI.selected = false;
            if(selectedReturnAmountType == 'Partial' && OI.remainingDebookAmount > 0){
                OI.selectDisabled = false;
            }else if(selectedReturnAmountType != 'Partial' && OI.remainingDebookAmount == OI.totalPrice){
                OI.selectDisabled = false;
            }
        }
    }
    
    /**
     * @description This method create update the CCR and related Booking Adjustment Line Records.
     * @return PageReference
     */
    public PageReference createUpdateCCR(){
        Integer selectedItems = 0; 
        Boolean valid = true;
        List<Booking_AdjustmentItems__c> adjItems = new List<Booking_AdjustmentItems__c>();
        set<id> UpdateAdjustmentId = new set<id>();
        List<Booking_AdjustmentItems__c> DeleteadjItems = new List<Booking_AdjustmentItems__c>();
        try{  
            system.debug(logginglevel.DEBUG,'effectiveDate'+effectiveDate); 
            if(effectiveDate == null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,EFFECTIVEDATE_VALIDATION));
                return null;
            } 
            if(ord.TotalAmount < CRRAmount && !(selectedAType !=Label.PartnerReferrals && selectedReturnType=='LineItem Based')){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ORDERTOTAL_AMOUNT_VALIDATION));
                return null;
            }
            CCR.Effective_Date__c =date.valueOf(effectiveDate);
            Double amt = 0.0;
            if(updateadjustments == false){
                CCR.CCR_Type__c=selectedAType;
                CCR.User__c='Pending';
                CCR.Effective_End_Date__c=System.today();
                CCR.Booking__c = ApexPages.currentPage().getParameters().get('id');
                CCR.Affective_Person__c = ord.Opportunity.OwnerId ;
                CCR.Account_Name__c=ord.accountId;
                CCR.Opportunity__c = ord.OpportunityId ;
                CCR.recordtypeId = Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Internal CCR').getRecordTypeId();
            }                
            if(selectedAType !=Label.PartnerReferrals){
                if(selectedReturnType=='LineItem Based'){
                    for (lineItems LI : orderLineItems) {
                        if (!LI.selected) continue;
                        
                        selectedItems++;
                        Boolean isValidDebook = selectedReturnAmountType == 'Partial' && LI.debookAmount != null && LI.debookAmount > 0 && LI.debookAmount <= LI.remainingDebookAmount && valid;
                        Boolean isValidQty = (LI.debookAmount == null || LI.debookAmount == 0) && LI.quantity <= LI.maxQuantity && selectedReturnAmountType != 'Partial' && valid;
                        Boolean isQtyExceeded = LI.quantity > LI.maxQuantity;
                        Boolean isDebookExceeded = LI.debookAmount != null && LI.debookAmount > LI.remainingDebookAmount;
                        Boolean isNotValidDebook = selectedReturnAmountType == 'Partial' && LI.debookAmount == 0;
                        if (isValidDebook || isValidQty) {
                            Decimal itemAmt = isValidDebook ? LI.debookAmount : LI.quantity * LI.totalUnitPrice;
                            amt += itemAmt;
                    
                            Booking_AdjustmentItems__c adj = new Booking_AdjustmentItems__c(
                                id = LI.ALI_Id,
                                CCR__c = CCR.Id,
                                Opportunity_Line_Item__c = mapOriginalQLIToOppLI?.get(LI.quoteLineItemId)?.Id,
                                OrderLineItemId__c = LI.OLId,
                                Quantity__c = isValidDebook ? LI.Quantity : LI.quantity,
                                Adjusted_Item_Total_Price__c = isValidDebook ? LI.debookAmount : LI.totalPrice,
                                Unit_Price__c = isValidDebook ? LI.debookAmount/LI.quantity : LI.totalUnitPrice,
                                License_Type_c__c = LI.licenseType,
                                Product_Category__c = LI.productCatogery,
                                Product_Code__c = LI.productCode,
                                Product_Description__c = LI.productDescription,
                                Product_Family__c = LI.productFamily,
                                Product_Name__c = LI.productName,
                                Product_Payment_Option__c = LI.productPaymentOption,
                                Subscription_Term__c = LI.subsriptionTerm,
                                Total_Discount__c = isValidQty ? LI.Discount : null
                            );
                    
                            adjItems.add(adj);
                            if (AddedAdjustments.containsKey(LI.OLId))
                                UpdateAdjustmentId.add(LI.OLId);
                        }
                        else if (isQtyExceeded) {
                            valid = false;
                            ApexPages.addMessage(new ApexPages.Message(
                                ApexPages.Severity.ERROR,
                                QUANTITY_ERROR.replace('[ProdName]', LI.prodName).replace('[Quantity]', String.valueOf(LI.maxQuantity))
                            ));
                        }
                        else if (isDebookExceeded) {
                            valid = false;
                            ApexPages.addMessage(new ApexPages.Message(
                                ApexPages.Severity.ERROR,
                                DEBOOK_ERROR.replace('[ProdName]', LI.prodName)
                                            .replace('[Debook]', String.valueOf(LI.debookAmount))
                                            .replace('[Total]', String.valueOf(LI.remainingDebookAmount))
                            ));
                        }
                        else if (isNotValidDebook){
                            valid = false;
                            ApexPages.addMessage(new ApexPages.Message(
                                ApexPages.Severity.ERROR,
                                ZERO_DEBOOK_ERROR.replace('[ProdName]', LI.prodName)
                            ));
                        }
                    }
                    
                    if(selectedItems == 0 || valid == false){
                        if(selectedItems == 0){
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Warning,NO_ITEMS_SELECTED_ERROR));
                        }
                        return null;
                    }
                    CCR.Amount__c = amt ;
                }
                else{
                    CCR.Amount__c = CRRAmount;
                }  
                CCR.Customer_Returns_type__c =selectedReturnType;
                CCR.Return_Amount_Type__c = selectedReturnAmountType;
            }
                else if(selectedAType ==  Label.PartnerReferrals ){
                    CCR.Referral_Fee_Amount__c =CRRAmount;
                }
                else if(selectedAType ==Label.BookingPolicyOrDe_RiskDecision || selectedAType ==Label.IncorrectOrder_MisQuote){
                    CCR.Amount__c = CRRAmount ;
                }
            system.debug(logginglevel.DEBUG,'IN Else currentCCRAmount::'+currentCCRAmount+': CCR.Amount__c::'+CCR.Amount__c+': ord.TotalAmount:'+ ord.TotalAmount );
            
            if(CRRAmount!=null && CRRAmount<0){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,POSITIVE_AMOUNT_VALIDATION));
                return null;
            }
            else if((CCR.Amount__c!=null && currentCCRAmount+ CCR.Amount__c > ord.TotalAmount) || (CRRAmount!=null && currentCCRAmount+ CRRAmount > ord.TotalAmount)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,OVER_AMOUNT_VALIDATION));
                return null;
            }
            upsert CCR ;
            if(selectedAType !=Label.PartnerReferrals && selectedReturnType=='LineItem Based'){
                for(Booking_AdjustmentItems__c AI :adjItems){
                    if(AI.CCR__c == null)
                        AI.CCR__c = CCR.Id;
                }    
                if(adjItems.size()>0)
                    upsert adjItems;
                if(UpdateAdjustmentId.size()!= AddedAdjustments.size()){    //check for lesser then
                    for(Id OLI : AddedAdjustments.keyset()){
                        if(!UpdateAdjustmentId.contains(OLI))
                            DeleteadjItems.add(AddedAdjustments.get(OLI));
                    } 
                } 
                if(DeleteadjItems.size()>0)
                    delete DeleteadjItems ;
            }
            PageReference pageRef = new PageReference('/'+CCR.id);
            return pageRef; 
        }
        catch(exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Warning,e.getMessage()));
            return null;
        }
    }
    
    /**
     * @description This method handles the cancel action for VF Page
     * @return PageReference
     */
    public PageReference cancel(){
        PageReference pageRef = null;
        String objId = ApexPages.currentPage().getParameters().get('id');
        String ccrId = ApexPages.currentPage().getParameters().get('CCRId');
        if(objId != null){
            pageRef = new PageReference('/'+ (objId.escapeHtml4()));
        }else if(ccrId != null){
            pageRef = new PageReference('/'+ (ccrId.escapeHtml4()));
        }
        return pageRef;
        
    }

    /**
     * @description This method handles the total and other calculation
     */
    public void calculateTotalPrice(){
        adjustmentTotalPrice = 0.0;
        for(lineItems LI : orderLineItems){
            if(LI.selected){
                if(LI.quantity > LI.maxQuantity)
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning,+(QUANTITY_ERROR.replace('[ProdName]',LI.prodName)).replace('[Quantity]',string.valueof(LI.maxQuantity))));
                //Start PRDOPS26-21
                if(LI.debookAmount > LI.remainingDebookAmount)
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,+(DEBOOK_ERROR.replace('[ProdName]',LI.prodName)).replace('[Debook]',string.valueof(LI.debookAmount)).replace('[Total]',string.valueof(LI.remainingDebookAmount))));
                if(selectedReturnAmountType == 'Partial'){
                    LI.partialDebook = true;
                    adjustmentTotalPrice += LI.debookAmount;
                }//End PRDOPS26-21
                else{
                    adjustmentTotalPrice += LI.totalPrice;
                }
                    
            }
            else{
                LI.partialDebook = false;
                LI.debookAmount = 0;
            }   
        }
    }
    /**
     * @description This method checkes the quantity for the line items
     */
    public void checkQuantity(){
        orderLineItems[selectedRowIndex].totalPrice = (orderLineItems[selectedRowIndex].totalUnitPrice*orderLineItems[selectedRowIndex].quantity).setScale(2);
        error_RowIndex.add(selectedRowIndex);
        adderror();
        calculateTotalPrice();
        return;    
    }
    /**
     * @description This method adds line level errors
     */
    public void adderror(){
        List<integer> removeIndex = new List<Integer>();
        for(Integer i : error_RowIndex){
            if(orderLineItems[i].quantity > orderLineItems[i].maxQuantity){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning,+(QUANTITY_ERROR.replace('[ProdName]',orderLineItems[i].prodName)).replace('[Quantity]',string.valueof(orderLineItems[i].maxQuantity))));
                
            }
            else{
                removeIndex.add(i);  
            }
            
        }
        if(!removeIndex.isEmpty()){
            for(integer i : removeIndex)
                error_RowIndex.remove(i); 
        }
        
    }
    
    /**
     * @description This method handles the total and other calculation
     */
    public class LineItems{
        /** @description Booking Adjustment Line Id */
        public Id ALI_Id;
        /** @description Identitifies if Line is Selected */
        public Boolean selected{get;set;}
        /** @description Identitifies if Line is disabled for selection */
        public Boolean selectDisabled{get;set;}
        /** @description Product Name */
        public String prodName{get;set;}
        /** @description Quantity for the Order Item */
        public Decimal quantity{get;set;}
        /** @description Maximum Quantity for the Order Item */
        public Decimal maxQuantity{get;set;}
        /** @description Order Item Id */
        public Id OLId{get;set;}
        /** @description Unit Price for the Order Item */
        public Decimal totalUnitPrice{get;set;}
        /** @description Product License Type */
        public String licenseType{get;set;}
        /** @description Product Category */
        public String productCatogery{get;set;}
        /** @description Product Code */
        public String productCode{get;set;}
        /** @description Product Description */
        public String productDescription{get;set;}
        /** @description Product Family */
        public String productFamily{get;set;}
        /** @description Product Name */
        public Id productName{get;set;}
        /** @description Payment Option for the Order Items */
        public String productPaymentOption{get;set;}
        /** @description Subscription Term of the Order Item */
        public Decimal subsriptionTerm{get;set;}
        /** @description Discount applied to the Order Item */
        public Decimal Discount{get;set;}
        /** @description Total Price for the Order Item */
        public Decimal totalPrice {get;set;}
        /** @description De-book Amount for the Line */
        public Decimal debookAmount {get;set;} //PRDOPS26-21
        /** @description Partial De-booked Line */
        public Boolean partialDebook {get;set;} //PRDOPS26-21
        /** @description Total Remaining Amount for Order Item */
        public Decimal remainingDebookAmount {get;set;} //PRDOPS26-21
        /** @description Quote Line Item Id */
        public Id quoteLineItemId {get;set;}
        
        /**
         * @description This is a constructor for lineItems
         * @param ALI_Id
         * @param Selected
         * @param ProdName
         * @param Quantity
         * @param maxQuantity
         * @param OLId
         * @param TotalUnitPrice
         * @param licenseType
         * @param productCatogery
         * @param productCode
         * @param productDescription
         * @param productFamily
         * @param productName
         * @param productPaymentOption
         * @param subsriptionTerm
         * @param Discount
         * @param selectDisabled
         * @param quoteLineItemId
         * @param debookAmount
         * @param partialDebook
         * @param remainingDebookAmount
         */
        public lineItems(Id ALI_Id,Boolean Selected,String ProdName,Decimal Quantity,Decimal maxQuantity,Id OLId,Decimal TotalUnitPrice,String licenseType,
                         String productCatogery,String productCode,String productDescription,String productFamily,Id productName,String productPaymentOption,Decimal subsriptionTerm,Decimal Discount, Boolean selectDisabled, Id quoteLineItemId,
                         Decimal debookAmount,Boolean partialDebook, Decimal remainingDebookAmount){//PRDOPS26-21
                             this.ALI_Id = ALI_Id;
                             this.selected = selected ;
                             this.prodName = prodName;
                             this.quantity = quantity;
                             this.maxQuantity = maxQuantity;
                             this.OLId  = OLId;
                             this.totalUnitPrice = totalUnitPrice;
                             this.licenseType = licenseType;
                             this.productCatogery = productCatogery;
                             this.productCode = productCode;
                             this.productDescription = productDescription;
                             this.productFamily = productFamily;
                             this.productName = productName;
                             this.productPaymentOption = productPaymentOption;
                             this.subsriptionTerm=subsriptionTerm;
                             this.Discount=Discount;
                             this.totalPrice = (totalUnitPrice*quantity).setScale(2);
                             this.selectDisabled = selectDisabled;
                             this.quoteLineItemId = quoteLineItemId;   
                             this.debookAmount = debookAmount; //PRDOPS26-21
                             this.partialDebook = false; //PRDOPS26-21
                             this.remainingDebookAmount = this.totalPrice - remainingDebookAmount; //PRDOPS26-21                             
                         }  
    }
}