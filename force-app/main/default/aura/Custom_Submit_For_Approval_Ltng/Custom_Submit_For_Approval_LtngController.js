({
	handleRecordUpdated: function(component, event, helper){  
		helper.handleBusinesLogicSetting(component, event, helper); 
        var quoteQuery ='select Id,SBQQ__Primary__c,Credit_Calculation_Start_Date__c,SBQQ__Opportunity2__r.CloseDate,SBQQ__NetAmount__c,QuoteApprovalCategory__c, Scale_Eligible__c,Selective_Account_Eligible_for_RCDM_T__c,Eligible_for_RCDM_T__c,RCDMCount__c'
        + ',SBQQ__Account__r.RCDMT_EOL_Date__c,RCDMT_EOL_Date__c,RWD_Opportunity_Close_Date__c,Is_Customer_Fully_Transitioned__c,Opportunity_Program__c,RWD_Deal_Ops_Exception__c'
        + ',RWD_Sales_Rep_Exception__c,RWD_Sales_Rep_Exception_Justification__c, SBQQ__StartDate__c,Polaris_Conversion__c,CreatedDate,Is_Scale_Utility_Quote__c'
        + ',Installed_By__c,Opportunity_Stage__c,Running_User_Profile__c,ApprovalStatus__c,Is_Selected_Partners_Customers_for_L3__c,Count_of_Rubrik_Basic_Edition__c'
        + ',Discount_Justification__c,SBQQ__Type__c,Discount_Floor_Breached__c,SBQQ__Account__c,Is_Refreshed_Identifier__c,Non_Standard_billing_term_detail__c,ETM_Theatre__c, Customer_Has_NASCD_RCMD__c, Account_Type__c'
        + ',Non_Standard_billing_flag__c,Is_RWD_Polaris_Quote__c,OpportunitySubType__c,Discounted_Units_due_to_CSAT_or_Sizing__c,Eligible_for_Onsite_Consulting__c,ETM_Area__c'
        + ',RWD_Eligible_LA_DA_Products_RSCP__c,Trade_Up_Serial_Numbers__c,ProcessType__c,RSCP_count__c,Manual_Fulfillment_Quote__c, SBQQ__ExpirationDate__c,Is_Data_Issue__c,SBQQ__SubscriptionTerm__c,SBQQ__Status__c,Count_of_Rubrik_Install_For_THP__c'
        + ',SBQQ__Opportunity2__r.Bypass_PSO__c,Is_Federal_Eligible_Quote__c, Opportunity_Type__c,Todays_Date__c,Check_for_ER_UA_DA__c,Quoting_Desk_Exception__c,RBRK_NotSummaryVarCustomRuleId__c ,Account_Has_Phone_Support_Entitlement__c,Prepayment_Credit__c,Expiration_Date__c,SBQQ__Distributor__c,SBQQ__Distributor__r.Name,Distributor_s_Name__c'
        + ' from sbqq__quote__c where id = \''+ component.get("v.recordId") + '\'';
        helper.executeQuery(component, event, helper, quoteQuery, 'quoteRec'); 
		var query = 'select Id,Family_and_ProductLevel__c,License_Subtype__c,SBQQ__RenewedAsset__c,SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Product_Type__c,'
		+ 'SBQQSC__RenewedContractLine__r.Product2.Name,SBQQSC__RenewedContractLine__r.Product2Id,SBQQ__Product__r.Product_Subtype__c,SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Name,'
		+ 'SBQQSC__RenewedContractLine__r.Product2.Product_Level__c,DiscJustiReq__c,Sales_Comp_Category__c,Product_Subtype__c,SBQQSC__RenewedContractLine__c,'
        + 'Replacement_Details__c,SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__c,SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__r.Atlassian_Quantity__c,'
        + 'SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__r.Salesforce_Quantity__c,SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__r.Rubrik_Hosted_M365_Quantity__c,'
        + 'SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__r.Dynamics_Quantity__c,SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__r.Google_Workspace_Quantity__c,Name,Atlassian_Quantity__c,Salesforce_Quantity__c,Rubrik_Hosted_M365_Quantity__c,Dynamics_Quantity__c,' 
		+ 'SBQQ__Quote__r.SBQQ__Type__c,SBQQ__Quote__r.Co_Term__c,Subscribed_Asset_Name__c,SBQQ__Quote__r.RWD_Deal_Ops_Exception__c,Special_Program__c,Prepayment_Credit__c,SBQQ__RequiredBy__r.Licensing_Model__c,'
		+ 'SBQQ__SubscribedAssetIds__c,Arroyo_Subsumed_Old_Contract_Line_Items__c,SBQQ__StartDate__c,SBQQ__Product__c,SBQQ__Product__r.Product_Level__c,'
		+ 'SBQQ__Product__r.Eligible_for_RCDM_T__c,SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,SBQQ__RequiredBy__r.Quote_Line_Type__c,SBQQ__RequiredBy__r.SBQQ__Quantity__c,'
		+ 'SBQQ__RequiredBy__r.Disposition_Reason__c,Scale_Utility_Product__c,EOL_Product_Status__c, SBQQ__EffectiveStartDate__c,SBQQ__Product__r.Rel_SubsAsst__c,'
		+ 'SBQQ__RequiredBy__r.SBQQ__ProductCode__c, SBQQ__EffectiveEndDate__c, SBQQ__ProductCode__c,SBQQ__ProductFamily__c,Product_Type__c,SBQQ__Discount__c,'
		+ 'Add_on_Level__c,Line_Type__c,Required_By_Product_Code__c,SBQQ__RequiredBy__c,SBQQ__RequiredBy__r.SBQQ__Product__r.Category__c, SBQQ__Product__r.X0__c, '
		+ 'SubscribedAssetNames__c,SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Category__c,SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Product_Level__c,'
		+ 'SBQQ__ListPrice__c,SBQQ__ProratedListPrice__c,SBQQ__ListTotal__c,Licensing_Model__c,SBQQ__Product__r.Is_Attributes_Blank__c,SBQQ__Product__r.SBQQ__ExcludeFromOpportunity__c,'
		+ 'SBQQ__Source__c,TPH_Models_Gen__c,TPH_Drive_Size__c,TPH_OEM__c,TPH_Quantity__c,SBQQ__Existing__c,SBQQ__EffectiveQuantity__c,SBQQ__Optional__c,SBQQ__AdditionalDiscountAmount__c,'
		+ 'SBQQ__EndDate__c, SBQQ__SubscriptionPricing__c, Quote_Line_Type__c,  QuoteLine_Group_Name__c, Disposition_Reason__c, Check_of_POLARIS_Hardware__c, Check_of_ASPEN_Hardware__c, '
		+ 'SKU_Type__c, License_Category__c, SBQQ__Product__r.License_Category__c, Product_Level__c,SBQQ__Quantity__c,Replace_By__c,SBQQ__Group__c,SBQQ__Group__r.Name,' 
		+ 'PRE_Promo_Expiration_Date__c,Promo_Code__c,List_Price_Update__c,Target_NetTotal__c,SBQQ__NetTotal__c,Wrapper_Line__c,Product_Payment_Option__c,Storage_Tier__c,SBQQSC__RenewedContractLine__r.Required_by_Product_Code__c,'
		+ 'SBQQ__OptionType__c,SBQQ__Product__r.IsHardwareNotRequiredForHybridLicense__c,SBQQ__RequiredBy__r.Product_Type__c,SBQQ__RequiredBy__r.Arroyo_Subsumed_Old_Contract_Line_Items__c,'
		+ 'SBQQ__RequiredBy__r.Subscribed_Asset_Name__c,SBQQ__RequiredBy__r.SubscribedAssetNames__c,SBQQ__RequiredBy__r.SBQQ__Optional__c,SBQQ__RequiredBy__r.SBQQ__Existing__c,'
		+ 'Trade_Up_Discount__c, Ary_Product_Level__c, Product_Type_Segment_Index__c, Is_Hardware_and_New__c, GO_PA_True_and_New__c, PL_Not_Null_and_New__c, Is_RBK_Appliance_and_New__c, Ary_Product_Family__c,'
		+ 'LPT_Complete_Edition_and_New_Line__c, Rubrik_GO_PA__c, Is_Subscription_term_Minimum_term__c, Scale_Utility_Product_RSV_OND__c, Scale_Utility_Product_Identifier__c, Approval_Discount__c, ProductTypeReqByDR__c, Support_Type__c,'
		+ 'SBQQSC__RenewedContractLine__r.AMER_FED_Exception__c,Ary_Product_Type__c ,Per_Year_Price__c ,SBQQ__SegmentIndex__c ,SBQQ__SubscriptionTerm__c,Pre_Promo_Net_Amount__c,SBQQ__Product__r.Tradeup_Pattern__c,SBQQ__RequiredBy__r.Ary_Product_Type__c, SBQQ__Product__r.Sales_Comp_Category__c, SBQQ__Product__r.Product_Master_Id__c,'
	+ 'SBQQ__Product__r.Restrict_Quoting_For__c, SBQQ__RequiredBy__r.SBQQ__Product__c, SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__c, SBQQ__RequiredBy__r.SBQQ__Product__r.Restrict_Quoting_For__c, SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Restrict_Quoting_For__c, Upgrade_Path__c , Account_s_Entitlement__c , End_of_Renewals_Date__c '
    + ', Edition__c, SBQQ__Product__r.Bundle_Features__c, ACV__c,ExpACV__c,SBQQ__Product__r.EOL_Date__c,Quoting_Desk_Exception__c, RWD_Deal_Ops_Exception__c , EOL_Date__c , Payment_Options__c,' 
	+ 'Approval_Flags__c,Approval_Category__c, GPL__c, Is_Hardware_and_Not_Disposed__c, LastModifiedDate, Product_Type_ListPrice_Update__c, RWD_Line_Product_Type__c, Support_Type_and_Not_Disposed__c,RWD_Expected_Default_Quantity__c,Ary_Product_Code__c,CompletedEdition__c,Family_And_PL_and_Not_Disposed__c,Total_Usable_Capacity__c,Quantity_TB__c,SBQQ__SegmentLabel__c,RWD_Is_Subscription_term_Maximum_term__c,Account_s_Entitlement__r.Quantity__c'
		+ ' from SBQQ__QuoteLine__c where SBQQ__Quote__c = \''+ component.get("v.recordId") + '\'';
	helper.executeQuery(component, event, helper, query, 'quoteLineItemsRecds');
	var queryPBE = 'SELECT Id, UnitPrice, Product2Id, Pricebook2.name, isactive, ProductCode from PricebookEntry where IsActive = true and Pricebook2.name =\'CPQ PriceBook\' and Product2Id IN (select SBQQ__Product__c from SBQQ__QuoteLine__c where ((SBQQ__ProductOption__c = null OR (SBQQ__ProductOption__c!=null AND SBQQ__ProductOption__r.POT_Parent_s_Source__c=null)) AND (SBQQ__ProductOption__r.Product_Option_Percent_of_Total__c=null OR SBQQ__SubscriptionPercent__c = null))and SBQQ__Quote__c = \''+ component.get("v.recordId") + '\')';
	helper.executeQuery(component, event, helper, queryPBE, 'pbeRecords');
        var queryDLP='select id,Unit_Price__c, Product__r.ProductCode, Storage_Tier__c from Dynamic_Pricing_Lookup__c where Product__c IN(select SBQQ__Product__c from SBQQ__QuoteLine__c where SBQQ__Quote__c =\''+ component.get("v.recordId") + '\')';
	helper.executeQuery(component, event, helper, queryDLP, 'dlpRecords');
	var queryCLI='select id,Status,SBQQSC__Product__r.Family_and_ProductLevel__c,SBQQSC__Product__r.License_Subtype__c,SBQQSC__Product__r.ProductCode,SBQQSC__Product__r.Product_Level__c,SBQQSC__Product__r.X0__c,SBQQSC__Product__r.Product_Subtype__c,SBQQSC__Product__r.Product_Type__c,'  
                + 'SBQQSC__QuoteLine__r.SBQQ__Optional__c,EndDate, Status_Product_Code__c from ContractLineItem where EndDate > TODAY AND SBQQSC__Account__c  IN (Select SBQQ__Account__c from SBQQ__Quote__c where id =\''+ component.get("v.recordId") + '\')';
        helper.executeQuery(component, event, helper, queryCLI, 'CLIRecords');
	var ruleConditionsQuery='select RBRKRuleName__c,RBRKQuoteExceptions__c,RuleJSON__c,RuleSVJSON__c from RBRKRuleCondition__c'  ;	
		helper.executeQuery(component, event, helper, ruleConditionsQuery, 'ruleConditions');
	var assetConditionsQuery='select id,Is_Valid_Support_for_RBK__c from Asset where SBQQ__QuoteLine__r.SBQQ__Quote__c =  \''+ component.get("v.recordId") + '\'' ;	
		helper.executeQuery(component, event, helper, assetConditionsQuery, 'assetRecords');
    
	},

	sendForApproval : function(component, event, helper){
		var isApproval = event.getParam("isApproval");
		//helper.processExceptions(component,true)
		//CPQ22-5846 starts
		let alertExceptionMessage = component.get("v.alertExceptionMessage");
		if(Array.isArray(alertExceptionMessage) && alertExceptionMessage.length > 0){
			alertExceptionMessage=alertExceptionMessage.join(';')
		}else{
			alertExceptionMessage="";
		}
		//CPQ22-5846 Ends
		helper.updateExceptionsOnQuote(component,alertExceptionMessage)
            .then(() => {
            if(isApproval) {
				debugger;
			component.set("v.isApproval", false);
			helper.submitQuoteRec(component, event, helper, false);
		}
            })
            .catch(error => {
                console.error("Error in Apex call: ", error);
            });
	} 
})