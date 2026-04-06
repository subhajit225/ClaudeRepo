({
	helperMethod : function(component, event, helper) {   
        var opp = component.get('v.quoteRec');
		
        if(opp.Opportunity_Program__c == 'Go Refresh' || opp.Opportunity_Program__c ==  'Go Refresh - No Email')
            window.open('/apex/DisplayAllAssetsClone2?newid='+component.get("v.QuotesRecds")[0].Id,'_top');
        else
            window.open('/apex/sbqq__sb?newid='+component.get("v.QuotesRecds")[0].Id,'_top')
    },
	 
    processData : function(component, event, helper) { 
        if(!component.get("v.quoteLineItemsRecds") || !component.get("v.accRecds") ||  !component.get("v.quoteRec")) return;
        //CPQ22-5846 starts
        helper.processExceptions(component,false);
        //CPQ22-5846 Ends
        component.set("v.content",''); 
        var isVerified = true;
        var todaysDate =new Date('{!TODAY()}').getTime(); 
        var legacyTakeoutPromotionDate = new Date('2021-04-30').getTime();
        // Legacy Takeout Promotion End
        var quotelinequeryresult = component.get("v.quoteLineItemsRecds");
        var entitlementQueryResult = component.get("v.entitlementRecords"); //CPQ22-2821
        var quote = component.get("v.quoteRec");
        //start CPQ22-4179 Khushboo
        const ProfileName = component.get('v.currentUser') ? component.get('v.currentUser')['Profile'].Name : '';
        console.log('@@ ProfileName '+ProfileName);
        var RSCPExistingUser=false;
		var ScaleExistingUser = false;
        var cliRcrds=component.get("v.CLIRecords");
        if(quotelinequeryresult.length === 0){
            isVerified = false;
            var validationMessage = $A.get("$Label.c.R_EQuotesWithZeroQLGroup");
            component.set("v.content",validationMessage);
            //component.set("v.content","This R+E quote is invalid as there are zero quote line groups.");
        }
        if(cliRcrds!=null && cliRcrds!=undefined)
        {
            console.log('@@inside cli '+cliRcrds);
            for(var i = 0; i < cliRcrds.length; i++) {
                var cli = cliRcrds[i]; 
                if(cli.SBQQSC__Product__r.Product_Level__c == 'OnPrem' && cli.SBQQSC__Product__r.X0__c == false && cli.SBQQSC__Product__r.Product_Subtype__c != 'LOD Addon'
                   && cli.SBQQSC__Product__r.Product_Type__c != 'PMC')
                {
                    RSCPExistingUser= true;
                    break;
                }
            } 
        }
         console.log('@@RSCPExistingUser '+RSCPExistingUser);
         //end CPQ22-4179 
		 //cpq22-4200 start
		 if(cliRcrds!=null && cliRcrds!=undefined)
        {
            console.log('@@inside cli before '+cliRcrds.length);
            for(var i = 0; i < cliRcrds.length; i++) {
                var cli = cliRcrds[i]; 
                if(cli.SBQQSC__Product__r.Family_and_ProductLevel__c  == 'Rubrik ScaleHybrid Software' && cli.SBQQSC__Product__r.License_Subtype__c  == 'ELA' && cli.Status == 'Active')
                {
                    console.log('status '+cli.Status);
                    console.log('PF '+cli.SBQQSC__Product__r.Family_and_ProductLevel__c);
                    console.log('LT '+cli.SBQQSC__Product__r.License_Subtype__c);
                    ScaleExistingUser = true;
                    break;
                }
            } 
			 console.log('@@ScaleExistingUser '+ScaleExistingUser);
        }
        //start CPQ22-3790
        var PBERcrd = component.get("v.pbeRecords");
        var pbeMap = {};
        if(PBERcrd!=null && PBERcrd!=undefined){
          for(var i = 0; i < PBERcrd.length; i++) {
            var pbe = PBERcrd[i];
            pbeMap[pbe.Product2Id] = pbe.UnitPrice;
            console.log('@@PEB records '+pbeMap[pbe.Product2Id]);
        }  
        }
        //for Storage tier products
        var DLPRcrd=component.get("v.dlpRecords");
        var dlpMap = {};
        if(DLPRcrd!=null && DLPRcrd!=undefined){
          for(var i = 0; i < DLPRcrd.length; i++) {
            var dlp = DLPRcrd[i];
            dlpMap[dlp.Product__c+dlp.Storage_Tier__c] = dlp.Unit_Price__c;
            console.log('@@DLP records '+dlpMap[dlp.Product__c+dlp.Storage_Tier__c]);
        }  
        }
        //FY25SR-1690 - starts
        if(isVerified) {
            if(quote.Prepayment_Credit__c != null && quote.Prepayment_Credit__c < 0) {
                var errorMessage = $A.get("$Label.c.Negative_Credit_Error");
                isVerified = false;
                component.set("v.content",errorMessage);
            }
        }
        //FY25SR-1690 - ends
        //end CPQ22-3790
        //PS Project validation on New Quote related to PS Configure
	 // CPQ22-339 added by Madhura 
        // GLCR-82 - Start - Commented As per business confirmation
        /*if(quote.Non_Standard_billing_flag__c == true && ( quote.Non_Standard_billing_term_detail__c == '' || quote.Non_Standard_billing_term_detail__c == null))  {
		  component.set("v.content","Please provide non-standard billing term details !!");	
        }*/
        // GLCR-82 - End - Commented As per business confirmation
        //GLCR-82 - Start - Commented As per business confirmation
        /*if(isVerified) {
            if(quote.SBQQ__Type__c == 'Quote') {
                var isWrapperPresent = false;
                var isInstallSkUExists = false;
                var isOtherSkUExists = false;
		//Added by Sumedha for CPQ22-502
		var isPolarisSKU = false;
                //CPQ22-502 ends
                var psWrapperCount = 0;
                var result = quotelinequeryresult;
                var quoteLinesrecords = quotelinequeryresult;
                for(var i = 0; i < quoteLinesrecords.length; i++) {
                    var quoteLine = quoteLinesrecords[i];
			
		//Added by Sumedha for CPQ22-502
                if (quote.Is_RWD_Polaris_Quote__c == true) {
                    isPolarisSKU = true;
                }//CPQ22-502 ends
			
			//Added Hybrid PS condition by Sumedha for RWD-206
                    if(quoteLine.SBQQ__ProductCode__c == 'PS-WRAPPER' || quoteLine.SBQQ__ProductCode__c == 'Hybrid Professional Services') {
                        isWrapperPresent = true;
                        psWrapperCount = psWrapperCount + 1;
                    }
                    //Added HYbrid PS condition by Sumedha for RWD-206
                    //Added New INST SKUs ProductCode by Sumedha for CPQ22-412 and CPQ22-541
                    if(((quoteLine.SBQQ__ProductCode__c == 'RBK-PS-INST' || quoteLine.SBQQ__ProductCode__c == 'RBK-PS-INST-ONST' || quoteLine.SBQQ__ProductCode__c == 'RBK-PS-INST-RMOT') 
                        || (quote.Count_of_Rubrik_Basic_Edition__c > 0 && quoteLine.SBQQ__ProductCode__c == 'RBK-SVC-CMPLT-RMOT')) || 
                       ((quoteLine.SBQQ__ProductCode__c == 'RA-PS-INT' || quoteLine.SBQQ__ProductCode__c == 'RA-PS-INST-ONST' || quoteLine.SBQQ__ProductCode__c == 'RA-PS-INST-RMOT') 
                        || (quote.Count_of_Rubrik_Basic_Edition__c > 0 && quoteLine.SBQQ__ProductCode__c == 'RA-SVC-CE-RMOT'))){
                        isInstallSkUExists = true;
                    }//CPQ22-412 and CPQ22-541 ends
                    
                    //Added Hybrid PS condition by Sumedha for RWD-206
                    if((quoteLine.SBQQ__ProductCode__c == 'RBK-PS-CNSLT-RMOT' || quoteLine.SBQQ__ProductCode__c ==
                       'RBK-PS-CNSLT-ONST' || quoteLine.SBQQ__ProductCode__c == 'RBK-PS-RES' || quoteLine
                       .SBQQ__ProductCode__c == 'RBK-PS-RCDM-INST' ) || 
                        (quoteLine.SBQQ__ProductCode__c == 'RA-PS-CON-RMOT' || quoteLine.SBQQ__ProductCode__c ==
                        'RA-PS-CON-ONST' || quoteLine.SBQQ__ProductCode__c == 'RA-PS-RES' || quoteLine
                        .SBQQ__ProductCode__c == 'RA-PS-RINT')) {
                        isOtherSkUExists = true;
                    }
                    // Legacy Takeout Promotion Start
                    // GLCR-82 - Start - Commented As per business confirmation
                    if(quote.Running_User_Profile__c != 'Sales Operations' && quote.Running_User_Profile__c != 'System Administrator'){
                        if(quoteLine.Product_Type__c == 'Hardware' && quoteLine.SBQQ__ProductFamily__c == 'R6000' && quoteLine.SBQQ__Discount__c == 100 && quote.Discounted_Units_due_to_CSAT_or_Sizing__c == 0 && quote.ApprovalStatus__c != 'Approved' && todaysDate > legacyTakeoutPromotionDate){
                            //legacyTakeoutPromotionCheck = true;
                            component.set("v.content","This quote does not qualify for a 100% discount on hardware. Please review and update the discounts for any hardware accordingly.");
                            isVerified = false;
                        }
                    }
                    //GLCR-82 - End - Commented As per business confirmation
                    // Legacy Takeout Promotion End
                }
                console.log('isWrapperPresent', isWrapperPresent);
                console.log('isInstallSkUExists', isInstallSkUExists);
		console.log('isPolarisSKU',isPolarisSKU);
                
                //Added isPolarisSKU condition by Sumedha for CPQ22-502
                if(isWrapperPresent == true && isInstallSkUExists == false && quote.Installed_By__c ==
                   'Rubrik' && isPolarisSKU == false) {
                    isVerified = false;
                    component.set("v.content","For Rubrik installed services, please add RBK-PS-INST SKU to the quote");
                    //alert("For Rubrik installed services, please add RBK-PS-INST SKU to the quote");
                }
		    
		//Added by Sumedha for CPQ22-502
                if(isWrapperPresent == true && isInstallSkUExists == false && quote.Installed_By__c ==
                   'Rubrik' && isPolarisSKU == true) {
                    isVerified = false;
                    component.set("v.content","For Rubrik installed services, please add RA-PS-INT SKU to the quote");
	            //alert("For Rubrik installed services, please add RA-PS-INT SKU to the quote");
		} //CPQ22-502 ends
		    
                if(isWrapperPresent == false && quote.Installed_By__c == 'Rubrik') {
                    isVerified = false;
                    component.set("v.content","PS Wrapper does not exist please edit lines and add PS Wrapper");
                    //alert("PS Wrapper does not exist please edit lines and add PS Wrapper");
                }
                // Commented as part of ITNPI-206 if(isWrapperPresent == true && isOtherSkUExists == false && (quote.Installed_By__c ==
                                                                             'Partner' || quote.Installed_By__c == 'Customer')) {
                  //  isVerified = false;
                  //  component.set("v.content","Please edit lines and delete/reconfigure PS Wrapper as it does not contain any product");
                    //alert("Please edit lines and delete/reconfigure PS Wrapper as it does not contain any product");
               // }
                if(psWrapperCount > 1) {
                    isVerified = false;
                    component.set("v.content","Only One PS Wrapper can exist per quote, Please Edit lines and delete one");
                    //alert("Only One PS Wrapper can exist per quote, Please Edit lines and delete one");
                }
            }
        }*/
        //GLCR-82 - End - Commented As per business confirmation
        //SF 9058
        // GLCR-82 - Start - Commented As per business confirmation
        /*if(isVerified){
            if(quote.SBQQ__Type__c=='Renewal'){
                var queryData = quotelinequeryresult;
                var showmssg = false;
                var quoteLinesrecords = quotelinequeryresult;
                if(quoteLinesrecords!=null && quoteLinesrecords!=undefined){
                    for (var i = 0; i < quoteLinesrecords.length; i++) {
                        var quoteLine = quoteLinesrecords[i];
                        if(quoteLine.SBQQ__EffectiveEndDate__c!=null && quoteLine.SBQQ__EffectiveStartDate__c!=null &&
                           quoteLine.SBQQ__EffectiveEndDate__c < quoteLine.SBQQ__EffectiveStartDate__c){
                            showmssg = true;
                            break;
                        }
                    }
                    if(showmssg){
                        isVerified = false;
                        component.set("v.content","One or more quote lines has a negative subscription term. Please edit the dates in quote line editor before proceeding.");
                        //alert('One or more quote lines has a negative subscription term. Please edit the dates in quote line editor before proceeding.');
                    }
                }
            }
        }*/
        if(isVerified){
            if(quote.ApprovalStatus__c=='Submitted'){
                isVerified = false;
                component.set("v.content","The Quote approval submission is in Progress . Please monitor ApprovalStatus for further details");
            }
            var ishWSupportValidation = $A.get("$Label.c.Is_Validate_HW_Support");
            if(quote.Is_Data_Issue__c && ishWSupportValidation != null && ishWSupportValidation === 'true') {
                var hWSupportValidation = $A.get("$Label.c.Validation_for_HW_Support");
                component.set("v.content",hWSupportValidation);
                isVerified = false;
            }
        } 

	//start CPQ22-3790
        if($A.get("$Label.c.ByPassRecalculation")){
         if(isVerified) {
            //replaced RWD_Deal_Ops_Exception__c with Quoting_Desk_Exception__c for SF-72381
            if((quote.Quoting_Desk_Exception__c == undefined || quote.Quoting_Desk_Exception__c == null || quote.Quoting_Desk_Exception__c == '') ||
                (quote.Quoting_Desk_Exception__c != null && !quote.Quoting_Desk_Exception__c.includes('Quoting Exception - Clone Pricing from Source Quote'))){
            //console.log('@@inside pricingchange15'+quote.RWD_Deal_Ops_Exception__c);
                  
                console.log('@@inside pricingchange95'+quote.Quoting_Desk_Exception__c);
                console.log('@@inside pricingchange95'+quote.Quoting_Desk_Exception__c);
            var quoteLinesrecords = quotelinequeryresult;
            var showalert = false;
            if(quoteLinesrecords!=null && quoteLinesrecords!=undefined){
                    for (var i = 0; i < quoteLinesrecords.length; i++) {
                        var quoteLine = quoteLinesrecords[i];
                        console.log('@@inside 3790');
                        console.log('@@inside 3790 '+quoteLine.SBQQ__ListPrice__c+' '+pbeMap[quoteLine.SBQQ__Product__c]);
                        if(quoteLine.Wrapper_Line__c==false && quoteLine.SBQQ__Optional__c==false && quoteLine.SBQQ__NetTotal__c!=0)
                        {
                          if(pbeMap[quoteLine.SBQQ__Product__c]!=null && quoteLine.SBQQ__ListPrice__c!=pbeMap[quoteLine.SBQQ__Product__c]
                             && !quoteLine.Storage_Tier__c)
                        {
                           showalert = true;
                           break;  
                        }
                         else if(dlpMap[quoteLine.SBQQ__Product__c+quoteLine.Storage_Tier__c]!=null && quoteLine.Storage_Tier__c!=null && 
                                    dlpMap[quoteLine.SBQQ__Product__c+quoteLine.Storage_Tier__c]!=quoteLine.SBQQ__ListPrice__c )
                            {
                               console.log('@@dlp '+dlpMap[quoteLine.SBQQ__Product__c+quoteLine.Storage_Tier__c]);
                               showalert = true;
                               break;   
                            }
                            
                        }
                      }
                 if(showalert){
                     isVerified = false;
                     var errorMessage = "Quote’s pricing has changed for your account please recalculate to see this in effect and then Submit it for approval";
                     component.set("v.content",errorMessage);
                  }
             }
           }
       } 
        }//End CPQ22-3790
		
		//CPQ22-3978 Starts
        if(isVerified) {
            console.log('quote.RWD_Deal_Ops_Exception__c----',quote.RWD_Deal_Ops_Exception__c);
            console.log('quotingdeskexpecion',quote.RWD_Deal_Ops_Exception__c);
            //replaced RWD_Deal_Ops_Exception__c with Quoting_Desk_Exception__c SF-72381
            if(quote.Quoting_Desk_Exception__c == null || quote.Quoting_Desk_Exception__c == undefined
                || (quote.Quoting_Desk_Exception__c != null
                    && !quote.Quoting_Desk_Exception__c.includes('Quoting Exception - HW without SW'))
            ){
                var countNewLines = 0;
                var countRenewalLines = 0;
                var quoteLinesrecords = quotelinequeryresult;
   
                if(quoteLinesrecords!=null && quoteLinesrecords!=undefined){
                    for (var i = 0; i < quoteLinesrecords.length; i++) {
                        var quoteLine = quoteLinesrecords[i];
                        console.log('quoteLine----',quoteLine.SBQQ__OptionType__c);
                        console.log('quoteLine----1',quoteLine.SBQQ__OptionType__c);
                            console.log('quoteLine----2',quoteLine.Product_Level__c);
                            console.log('quoteLine----3',quoteLine.Product_Type__c);
                            console.log('quoteLine----4',quoteLine.Quote_Line_Type__c);
                            console.log('quoteLine----5',quoteLine.Special_Program__c);
                        if(!quoteLine.Special_Program__c == 'Refresh'){
                           console.log('quoteLine----6',quoteLine.Special_Program__c);  
                        }
                        //added || quoteLine.Special_Program__c == undefined SF-72381
                        if((quoteLine.SBQQ__OptionType__c == ''
                            || quoteLine.SBQQ__OptionType__c == undefined
                            || quoteLine.SBQQ__OptionType__c == null)
                        && quoteLine.Product_Level__c == 'Hardware'
                        && quoteLine.Product_Type__c == 'Hardware'
                        && quoteLine.Quote_Line_Type__c == 'New' && !quoteLine.Replacement_Details__c) {//FY25SR-1958 //FY25SR-2009 updated to Replacement_Details__c
                                
                                countNewLines = countNewLines +1;
                            console.log('quoteLine----1',quoteLine.SBQQ__OptionType__c);
                            console.log('quoteLine----2',quoteLine.Product_Level__c);
                            console.log('quoteLine----3',quoteLine.Product_Type__c);
                            console.log('quoteLine----4',quoteLine.Quote_Line_Type__c);
                            console.log('quoteLine----5',quoteLine.Special_Program__c);
                        }
                    }
                }
                console.log('countNewLines----',countNewLines);
                if(countNewLines > 0) {
                    isVerified = false;
                    var errorMessage = "Rubrik Appliances may only be quoted with Software.";
                    component.set("v.content",errorMessage);
                }
            }
        }
        //CPQ22-3978 Ends
        
        // GLCR-82 - End - Commented As per business confirmation.Also Added Approval Status Validation
        
        //SF-7453 Subscribed Asset Requirement
        // GLCR-82 - Start - Commented As per business confirmation
        /*if (isVerified) {
            var result = quotelinequeryresult;
            var quoteLinesrecords = quotelinequeryresult;
            
            if(quote.Running_User_Profile__c != 'Sales Operations' && quoteLinesrecords!=null){
                var raiseSubscriptionAssetError=false;
                if(quoteLinesrecords != null && quoteLinesrecords.length > 0){
                    for (var i = 0; i < quoteLinesrecords.length; i++){
                        var varRCDMAddOnPresent=false;
                        var varSubcribedAssetPresent=false;
                        var quoteLine = quoteLinesrecords[i];
                        if(quote.SBQQ__Type__c=='Amendment' && quoteLine.Add_on_Level__c!=null && quoteLine.Line_Type__c != null && quoteLine.Add_on_Level__c=='RCDM Add-On' && quoteLine.Line_Type__c=='New' && quoteLine.SBQQ__RequiredBy__c!=null && quoteLine.SBQQ__RequiredBy__r!=null && quoteLine.SBQQ__RequiredBy__r.SBQQ__Product__r!=null && quoteLine.SBQQ__RequiredBy__r.SBQQ__Product__r.Category__c!=null && quoteLine.SBQQ__RequiredBy__r.SBQQ__Product__r.Category__c=='Hardware'){
                            varRCDMAddOnPresent=true;
                            if(quoteLine.SubscribedAssetNames__c){
                                varSubcribedAssetPresent=true;
                            } else {
                                varSubcribedAssetPresent=false;
                            }
                            
                            if(quote.SBQQ__Type__c=='Renewal' && ((quoteLine.SBQQ__RequiredBy__r!=null && quoteLine.SBQQ__RequiredBy__r.SBQQ__Product__r!=null && quoteLine.SBQQ__RequiredBy__r.SBQQ__Product__r.Category__c!=null && quoteLine.SBQQ__RequiredBy__r.SBQQ__Product__r.Category__c=='Hardware') || (quoteLine.SBQQSC__RenewedContractLine__r!=null && quoteLine.SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r!=null && quoteLine.SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Category__c!=null && quoteLine.SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Category__c=='Hardware' && quote.Polaris_Conversion__c == false))){
                                varRCDMAddOnPresent=true;
                                if(quoteLine.SubscribedAssetNames__c){
                                    varSubcribedAssetPresent=true;
                                } else {
                                    varSubcribedAssetPresent=false;
                                }
                            }
                            
                            if(varRCDMAddOnPresent && !(varSubcribedAssetPresent)){
                                raiseSubscriptionAssetError=true;
                                break;
                            }
                        }
                        if(raiseSubscriptionAssetError){
                            isVerified=false;
                            component.set("v.content","Quote line is missing subscribed asset.");
                            //alert("Quote line is missing subscribed asset.");
                        }
                    }
                }
            }
        }*/
        // GLCR-82 - End - Commented As per business confirmation
        //PS Project validation on Amendment Quote related to PS Configure
        // GLCR-82 - Start - Commented As per business confirmation
        /*if(isVerified) {
            if(quote.SBQQ__Type__c == 'Amendment' || quote.SBQQ__Type__c == 'Renewal') {
                var isWrapperPresent = false;
                var isOtherSkUExists = false;
                var psWrapperCount = 0;
                var result = quotelinequeryresult;
                var quoteLinesrecords = quotelinequeryresult;
                if(quoteLinesrecords != null && quoteLinesrecords.length > 0){
                    for( var i = 0; i < quoteLinesrecords.length; i++) {
                        var quoteLine = quoteLinesrecords[i];
                        //Added Hybrid PS condition by Sumedha for RWD-206
                        if(quoteLine.SBQQ__ProductCode__c == 'PS-WRAPPER' || quoteLine.SBQQ__ProductCode__c == 'Hybrid Professional Services') {
                            isWrapperPresent = true;
                            psWrapperCount = psWrapperCount + 1;
                        }
                        //Added Hybrid PS condition by Sumedha for RWD-206
                        if((quoteLine.SBQQ__ProductCode__c == 'RBK-PS-CNSLT-RMOT' || quoteLine.SBQQ__ProductCode__c ==
                           'RBK-PS-CNSLT-ONST' || quoteLine.SBQQ__ProductCode__c == 'RBK-PS-RES' || quoteLine
                           .SBQQ__ProductCode__c == 'RBK-PS-RCDM-INST') || 
                           (quoteLine.SBQQ__ProductCode__c == 'RA-PS-CON-RMOT' || quoteLine.SBQQ__ProductCode__c ==
                            'RA-PS-CON-ONST' || quoteLine.SBQQ__ProductCode__c == 'RA-PS-RES' || quoteLine
                            .SBQQ__ProductCode__c == 'RA-PS-RINT')) {
                            isOtherSkUExists = true;
                        }
                    }
                }
                if(isWrapperPresent == true && isOtherSkUExists == false) {
                    isVerified = false;
                    component.set("v.content","Please edit lines and delete/reconfigure PS Wrapper as it does not contain any product.");
                    //alert("Please edit lines and delete/reconfigure PS Wrapper as it does not contain any product.");
                }
                if(psWrapperCount > 1) {
                    isVerified = false;
                    component.set("v.content","Only One PS Wrapper can exist per quote, Please Edit lines and delete one");
                    //alert("Only One PS Wrapper can exist per quote, Please Edit lines and delete one");
                }
            }
        }*/
        // GLCR-82 - End - Commented As per business confirmation
        //EGN-19 && EGN 63
        // GLCR-82 - Start - Commented As per business confirmation
        /*var isOldSKUPresent = false;
        if(isVerified) {
            var result = quotelinequeryresult;
            var quoteLinesrecords = quotelinequeryresult;
            if(quoteLinesrecords != null && quoteLinesrecords.length > 0){
                for(var i = 0; i < quoteLinesrecords.length; i++) {
                    var quoteLine = quoteLinesrecords[i];
                    if(quoteLine.SBQQ__ProductCode__c == 'RBK-INSTALL' || quoteLine.SBQQ__ProductCode__c == 'RBK-CONSULT') {
                        isOldSKUPresent = true;
                        break;
                    }
                }
            }
            if(isOldSKUPresent == true && (quote.Opportunity_Stage__c == '4 Business Justification' ||
                                           quote.Opportunity_Stage__c == '5 Negotiate & Close' ||
                                           quote.Opportunity_Stage__c == '6 PO With Channel')) {
                component.set("v.content","Warning:-\n\nRBK-INSTALL or RBK-CONSULT are no longer in use. Please replace them with New SKU");
                //alert("Warning:-\n\nRBK-INSTALL or RBK-CONSULT are no longer in use. Please replace them with New SKU");
            }
            if(isOldSKUPresent == true && quote.Opportunity_Stage__c == '3 Technical Validation' && (
                quote.ApprovalStatus__c == 'Pending' || quotec.ApprovalStatus__c ==
                'Approved')) {
                component.set("v.content","Warning:-\n\nRBK-INSTALL or RBK-CONSULT are no longer in use. Please replace them with New SKU");
                //alert("Warning:-\n\nRBK-INSTALL or RBK-CONSULT are no longer in use. Please replace them with New SKU");
            }
        }*/ //EGN-19,63 ENDS
        // GLCR-82 - End - Commented As per business confirmation
        //SF 11279 : To throw validation when renewal quote's Opportunity or Account is not L3 eligible.
        // GLCR-82 - Start - Commented As per business confirmation
        /*if(isVerified){
            if(quote.SBQQ__Type__c == 'Renewal' && quote.Is_Selected_Partners_Customers_for_L3__c == false){
                
                var errorMsg = false;
                var quoteLinesrecords = component.get("v.quoteLineItemsRecds");
                if(quoteLinesrecords != null && quoteLinesrecords.length > 0){
                    if(quoteLinesrecords!=null && quoteLinesrecords!=undefined){
                        for (i = 0; i < quoteLinesrecords.length; i++) {
                        var quoteLine = quoteLinesrecords[i];
                        if(quoteLine.SBQQ__Product__r.Support_Type__c != null && quoteLine.SBQQ__Product__r.Support_Type__c.includes("L3")){
                            showmssg = true;
                            break;
                        }
                        }
                        if(showmssg){
                            isVerified = false;
                             component.set("v.content","Opportunity is not eligible for L3 support.Please ensure the Partner or Distributor is an eligible RASP.");
                            //alert('Opportunity is not eligible for L3 support.Please ensure the Partner or Distributor is an eligible RASP.');
                        }
                    }
                }
            }
        }*/
        // GLCR-82 - End - Commented As per business confirmation
        //SF-6993
        // GLCR-82 - Start - Commented As per business confirmation
        // Uncommented below logic for CPQKTLO-5031. 
        if(isVerified) {
            
            var quoteLinesrecords = component.get("v.quoteLineItemsRecds");
            if(quoteLinesrecords != null && quoteLinesrecords.length > 0) {
                for(var i = 0; i < quoteLinesrecords.length; i++) {
                    var quoteLine = quoteLinesrecords[i];
                    var todaysDate =new Date(quote.Todays_Date__c).getTime();
                    var EOLDate =new Date(quoteLine.EOL_Date__c).getTime();
                    var qtExpirationDate =new Date(quote.Expiration_Date__c).getTime();
                    // console.log('EOLDate'+EOLDate);
                    // console.log('todaysDate'+todaysDate);
                    //Added for CPQ22-4990 by Madhura
                    if(!quoteLine.SBQQ__Optional__c && !quoteLine.SBQQ__Existing__c){ 
                       if(( quoteLine.EOL_Product_Status__c != undefined && quoteLine.EOL_Product_Status__c != null && 
                        quoteLine.EOL_Product_Status__c == 'Past Expiration'
                        && (quoteLine.Disposition_Reason__c == 'Renewing' || quoteLine.Disposition_Reason__c == 'None') && ((quote.RWD_Deal_Ops_Exception__c == undefined || quote.RWD_Deal_Ops_Exception__c == null || quote.RWD_Deal_Ops_Exception__c == '') || (quote.RWD_Deal_Ops_Exception__c != null && !quote.RWD_Deal_Ops_Exception__c.includes('IT Quoting Exceptions')))
                        ) || (quoteLine.EOL_Date__c!= undefined && quoteLine.EOL_Date__c!=null && (
                            (EOLDate <= todaysDate && quoteLine.Quote_Line_Type__c == 'New' ) || 
                            (quoteLine.Quote_Line_Type__c == 'Renewal' && quoteLine.Disposition_Reason__c == 'Renewing' && (EOLDate <= qtExpirationDate && EOLDate < todaysDate) )))
                          ) {
                        isVerified = false;
                        var validationMessage = $A.get("$Label.c.SubscriptionTermBeyondEOLDate");
                        component.set("v.content",validationMessage);
                        //component.set("v.content","The subscription term extends beyond the End of Support Date for one or more products. Please adjust the End Date for any subscription products to be before the EOL Final Renewal Date.");
                        //alert(
                        //    "The End Date or Term for one or more lines is beyond the product or appliance’s End of Maintenance Support Date. Please update the term or end date to be on or before the product or appliance’s End of Maintenance Support (EOL Final Renewal) Date");
                        break;
                        }
                    }
                    if(!quoteLine.SBQQ__Group__c && quoteLine.SBQQ__Quote__r.SBQQ__Type__c == 'Renewal+Expansion'){
                        isVerified = false;
                        var validationMessage = $A.get("$Label.c.R_EQuotesWithZeroQLGroup");
                        component.set("v.content",validationMessage);
                        //component.set("v.content","This R+E quote is invalid as there are zero quote line groups.");
                        break;
                    }
                }
            }
        }
        // GLCR-82 - End - Commented As per business confirmation
        // Uncommented above logic for CPQKTLO-5031. 
            //POLARIS story : RWD 73
            if(isVerified){
            var quoteLinesrecords = component.get("v.quoteLineItemsRecds");
            if(quoteLinesrecords != null && quoteLinesrecords.length > 0) {
            for(var i = 0; i < quoteLinesrecords.length; i++) {
            var quoteLine = quoteLinesrecords[i];
            if(quoteLine.SBQQ__Source__c != null && quoteLine.SBQQ__ProductCode__c.includes("TPH")){
            if(quoteLine.TPH_Models_Gen__c == null || quoteLine.TPH_OEM__c == null ||
            quoteLine.TPH_Drive_Size__c == null || quoteLine.TPH_Quantity__c == null){
            isVerified = false;
            //alert(
            //"This is Cloned Quote. Please reconfigure to populate TPH_OEM,TPH_Quantity,TPH_DriveSize,TPH_Model before submit for an approval");
            component.set("v.content","This is Cloned Quote. Please reconfigure to populate TPH_OEM,TPH_Quantity,TPH_DriveSize,TPH_Model before submit for an approval");
            break;
            }
            } 
            }
            }
            }
            //Sprint 69 : CPQ22-342
        if(isVerified){
           var quoteLinesrecords = component.get("v.quoteLineItemsRecds");
            console.log('quoteLinesrecords',quoteLinesrecords.length);
			var ListandLicenselabel = $A.get("$Label.c.List_and_License_Validation_Message");
			var Licenselabel = $A.get("$Label.c.License_Type_Validation_Message");
			var Listlabel = $A.get("$Label.c.List_Price_Validation_Message");
            if(quoteLinesrecords != null && quoteLinesrecords.length > 0) {
                for(var i = 0; i < quoteLinesrecords.length; i++) {
                    var quoteLine = quoteLinesrecords[i];
                    if(quoteLine.SBQQ__Product__r.SBQQ__ExcludeFromOpportunity__c == false && quoteLine.SBQQ__Optional__c == false){
                        //CPQ22-4992 Starts
                        if(quoteLine.Quote_Line_Type__c == 'New' && quoteLine.Product_Type__c == 'Add-On Node' && quoteLine.Licensing_Model__c == null){
                            isVerified = false;
                            component.set("v.content",Licenselabel);
                            break;
                        }
                        //CPQ22-4992 ENds

                        //GLCR-82
			if ((quote.SBQQ__Type__c == 'Quote') && ((quote.SBQQ__Type__c == 'Amendment' || quote.SBQQ__Type__c == 'Renewal') && quoteLine.SBQQ__Existing__c == false && quoteLine.SBQQ__EffectiveQuantity__c != 0)) {
                                                              
                            console.log('Inside New Quote');
                            if(quoteLine.SBQQ__Product__r.Is_Attributes_Blank__c == null){
                                if((quoteLine.SBQQ__ListPrice__c == 0 || quoteLine.SBQQ__ListTotal__c == 0 || quoteLine.SBQQ__ProratedListPrice__c == 0 )&& 
									quoteLine.Licensing_Model__c == null){
									isVerified = false;
									component.set("v.content",ListandLicenselabel);
									break;	
                                    //Bypassed below validation for ScaleUtility
                                }else if((quoteLine.SBQQ__ListPrice__c == null || quoteLine.SBQQ__ListPrice__c == 0 ||
                                          quoteLine.SBQQ__ProratedListPrice__c == null || quoteLine.SBQQ__ProratedListPrice__c == 0 ||
                                        quoteLine.SBQQ__ListTotal__c == null || quoteLine.SBQQ__ListTotal__c == 0) && ((quoteLine.Scale_Utility_Product__c == false && quote.SBQQ__Type__c == 'Quote') || quote.SBQQ__Type__c == 'Amendment' || quote.SBQQ__Type__c == 'Renewal')) {//GLCR-82
                                    isVerified = false;
									component.set("v.content",Listlabel);
									break;
									}else if(quoteLine.Licensing_Model__c == null){
									isVerified = false;
									component.set("v.content",Licenselabel);
									break;	
									}
                                }else if(quoteLine.SBQQ__Product__r.Is_Attributes_Blank__c == 'List Price'){
                                    if(quoteLine.Licensing_Model__c == null){
                                        isVerified = false;
                                      component.set("v.content",Licenselabel);
                                        break;
										}
                                    }else if(quoteLine.SBQQ__Product__r.Is_Attributes_Blank__c == 'License Type'){
                                        if(quoteLine.SBQQ__ListPrice__c == null || quoteLine.SBQQ__ListPrice__c == 0 ||
                                           quoteLine.SBQQ__ProratedListPrice__c == null || quoteLine.SBQQ__ProratedListPrice__c == 0 ||
                                           quoteLine.SBQQ__ListTotal__c == null || quoteLine.SBQQ__ListTotal__c == 0){
                                            isVerified = false;
                                           component.set("v.content",Listlabel);
                                            break;	
                                        }
                                    }
                               }
					   }
                }
            }
        }
	 //RWD-1460 starts
        // GLCR-82 - Start - Commented As per business confirmation
        /*if(isVerified){
            if(quote.Is_RWD_Polaris_Quote__c == true){
                var quoteLinesrecords = quotelinequeryresult;
                if(quoteLinesrecords!=null && quoteLinesrecords!=undefined){
                    for (var i = 0; i < quoteLinesrecords.length; i++) {
                        var quoteLine = quoteLinesrecords[i];
                        if((quoteLine.SBQQ__Discount__c != null && quoteLine.SBQQ__Discount__c < 0) ||
                           (quoteLine.SBQQ__AdditionalDiscountAmount__c != null && quoteLine.SBQQ__AdditionalDiscountAmount__c < 0)){
                            isVerified = false;    
                            component.set("v.content","This Quote has negative discounts. Please provide discounts in positive numbers and then submit for approval");
                                break;
                            }
                        }
                    }
                }
        }*///RWD-1460 ends
        // GLCR-82 - End - Commented As per business confirmation
//2821 starts	
	    if (isVerified) {
    if (quote.SBQQ__Type__c != null) {
                
                var entRecords = [];   
                //Added for FY25SR-1255 - This is to filter the records as per the existing query 
                entitlementQueryResult.forEach(ent => {
            if (ent.Product__c && ent.Order_Service_Item__c) {
                if ((ent.Product__r.Ipt__c === 'V1 RCDM' || ent.Product__r.Ipt__c === 'V1 RCDM Support') &&
                    ent.Type != 'Evaluation' && ent.Type != 'RSC' &&
                    ent.Order_Service_Item__r.Order.Type != 'POC' && ent.Order_Service_Item__r.Order.Order_Sub_Type__c != 'POC' &&
                    !ent.Name.includes('Evaluation')) {
                        entRecords.push(ent);
                    }
                    }
                
                });             
                var hasRCDM = false;
                var validForRCDM = false;
                var showalert = false;
				var showQuantityAlert = false;
				var showReqByAlert = false;
                var everyRCDMHasParent = false;
				var matchRCDMParentCount = false;
                var validConversion = false;
        var createdDate = new Date(quote.CreatedDate).getTime();
        var startDate = new Date(quote.SBQQ__StartDate__c).getTime();
                var quoteRangeStart = new Date('08/15/2022').getTime();
                var quoteRangeEnd = new Date(quote.SBQQ__Account__r.RCDMT_EOL_Date__c).getTime(); //CPQ22 --3874
                var quoteDate = new Date(quote.RCDMT_EOL_Date__c).getTime();
                var setQLHybridIds = new Set();
 		var RCDMBeyonddate = false;
		var renewalRcdmt = false;
                var neewRcdmt = false;
                var setRscpRCDMT = new Set();
                var setRscRCDMT = new Set();
                var etmArea = quote.ETM_Area__c;
                var rscpCount = quote.RSCP_count__c;
                var isRSCPeligible = quote.RWD_Eligible_LA_DA_Products_RSCP__c;
                var RscpException = false;
                var nonFedRSCP = false;
                 //added for RCDMT dates mismatch
        if (isRSCPeligible && etmArea != 'AMER-FED' && rscpCount > 0) {
                    nonFedRSCP = true;
                }

        //CPQ22-5854 added quoteRangeEnd and quoteDate check
        if (quoteRangeEnd && quoteDate && quote.RCDMCount__c > 0 && quoteRangeEnd != quoteDate && !nonFedRSCP) {
                   var errorMessage = $A.get("$Label.c.RCDMT_EOL_date_mismatch"); 
            component.set("v.content", errorMessage);
                   isVerified = false;

                }
        if (quoteLinesrecords != null && quoteLinesrecords != undefined) {
                    for (var i = 0; i < quoteLinesrecords.length; i++) {
			    validConversion = false;
                        var quoteLine = quoteLinesrecords[i];
                var startDateQL = new Date(quoteLine.SBQQ__StartDate__c).getTime();
						
			    //Check for valid conversion lines
                        /*if(quoteLine.SBQQ__Product__r.Eligible_for_RCDM_T__c == true){
                            if(quoteLine.Quote_Line_Type__c == 'Renewal' && quoteLine.Disposition_Reason__c == 'Renewing' &&  quoteLine.SBQQSC__RenewedContractLine__c != null && quoteLine.SBQQ__Product__r.Product_Level__c != null && quoteLine.SBQQSC__RenewedContractLine__r.Product2Id != null && quoteLine.SBQQSC__RenewedContractLine__r.Product2.Product_Level__c == null){
								validConversion = true;
                            console.log('validConversion '+validConversion);
                        	}
                          }commenting for CPQ22-4204 */
						
                        if (
                        (quoteRangeEnd != null &&
                        startDateQL < quoteRangeEnd &&
                        quoteLine.Quote_Line_Type__c == 'Renewal' &&
                        quoteLine.Disposition_Reason__c == 'Renewing')
                        && quoteLine.SBQQ__Product__r.Eligible_for_RCDM_T__c == true
                          ) { 
							setQLHybridIds.add(quoteLine.Id);
						
                            
                            
                        console.log('validConversion '+validConversion);
			    if(quoteRangeEnd!= null && startDateQL > quoteRangeEnd && quoteLine.Quote_Line_Type__c == 'New' && quoteLine.SBQQ__ProductCode__c == 'RS-BT-RCDM-T' ){
                                                 console.log('inside bigger Dates ');
                                                RCDMBeyonddate = true;
				   
                                                    }	
							
                    }
					var countRCDMT = 0;
					var setQLHybridIds2 = new Set(); 
            console.log('> R+E validForRCDM: ' + validForRCDM);
                    for (i = 0; i < quoteLinesrecords.length; i++) {
                        var quoteLine = quoteLinesrecords[i];
                if (quoteLine.SBQQ__ProductCode__c == 'RS-BT-RCDM-T' && (quoteLine.SBQQ__RequiredBy__c == null || quoteLine.SBQQ__RequiredBy__c == undefined)) {
								showReqByAlert = true;
							}
							
							
                console.log('quoteLine.SBQQ__RequiredBy__c ' + quoteLine.SBQQ__RequiredBy__c);
                console.log('quoteLine.SBQQ__ProductCode__c ' + quoteLine.SBQQ__ProductCode__c);
                if (quoteLine.SBQQ__RequiredBy__c != null && quoteLine.SBQQ__RequiredBy__c != undefined) {
						//	console.log('quoteLine.SBQQ__RequiredBy__r.Quote_Line_Type__c '+quoteLine.SBQQ__RequiredBy__r.Quote_Line_Type__c);
						//	console.log('quoteLine.SBQQ__RequiredBy__r.Disposition_Reason__c '+quoteLine.SBQQ__RequiredBy__r.Disposition_Reason__c);	
						}
						
                if (quoteLine.SBQQ__ProductCode__c == 'RS-BT-RCDM-T' && quoteLine.SBQQ__RequiredBy__c != null && ((quoteLine.SBQQ__RequiredBy__r.Quote_Line_Type__c == 'New') || (quoteLine.SBQQ__RequiredBy__r.Quote_Line_Type__c == 'Renewal' && quoteLine.SBQQ__RequiredBy__r.Disposition_Reason__c == 'Renewing'))) {
							//countRCDMT = countRCDMT+1;
							setQLHybridIds2.add(quoteLine.SBQQ__RequiredBy__c);
                    if (quoteLine.SBQQ__ProductCode__c == 'RS-BT-RCDM-T' && quoteLine.SBQQ__Quantity__c != quoteLine.SBQQ__RequiredBy__r.SBQQ__Quantity__c) {
                        showQuantityAlert = true;
							}
                    if (quoteLine.SBQQ__RequiredBy__r.SBQQ__ProductCode__c && quoteLine.SBQQ__RequiredBy__r.SBQQ__ProductCode__c.includes("PB-EDG") && quoteLine.SBQQ__RequiredBy__r.SBQQ__Quantity__c && quoteLine.SBQQ__Quantity__c == (quoteLine.SBQQ__RequiredBy__r.SBQQ__Quantity__c * 1000)) {
                        showQuantityAlert = false;
							}
						}
                if (quoteLine.SBQQ__ProductCode__c == 'RS-BT-RCDM-T' && quoteLine.SBQQ__RequiredBy__c != null && quoteLine.SBQQ__RequiredBy__c != undefined) {
                    if (quoteLine.SBQQ__RequiredBy__r.Quote_Line_Type__c == 'Renewal') {
                                renewalRcdmt = true;
                        console.log('renewalRcdmt' + renewalRcdmt);
                    } else if (quoteLine.SBQQ__RequiredBy__r.Quote_Line_Type__c == 'New') {
                        neewRcdmt = true;
                        console.log('neewRcdmt' + neewRcdmt);
                            }
                        }
                        
                if (etmArea != 'AMER-FED' && quoteLine.SBQQ__RequiredBy__c != null && quoteLine.SBQQ__ProductCode__c == 'RS-BT-RCDM-T' && quote.RWD_Eligible_LA_DA_Products_RSCP__c == true && quoteLine.Ary_Product_Code__c != 'Disposed' && quoteLine.SBQQ__RequiredBy__r.SBQQ__Optional__c == false && quoteLine.SBQQ__RequiredBy__r.Quote_Line_Type__c == 'New') { //CPQ22-5010
                    if (quoteLine.SBQQ__RequiredBy__r.SBQQ__ProductCode__c != null && quoteLine.SBQQ__RequiredBy__r.SBQQ__ProductCode__c.includes("RSCP")) {
                        console.log('req code:' + quoteLine.SBQQ__RequiredBy__r.SBQQ__ProductCode__c);
                                setRscpRCDMT.add(quoteLine.Id);
                                
                    } else {
                                console.log('insdie RSC');
                                setRscRCDMT.add(quoteLine.Id);
                            }
                    }
                    }
            if (setRscpRCDMT.size > 0 && setRscRCDMT.size > 0) {
                RscpException = true;
                        }
            if (setQLHybridIds.size == setQLHybridIds2.size) {
						if (setQLHybridIds.size != 0 && setQLHybridIds2.size != 0) everyRCDMHasParent = true;
						 
            } else if (setQLHybridIds.size != setQLHybridIds2.size) {
						if (setQLHybridIds.size != 0 && setQLHybridIds2.size != 0) matchRCDMParentCount = true; 
                if (setQLHybridIds.size != setQLHybridIds2.size) matchRCDMParentCount = true;
					}

                    //CPQ22-5854 added etmArea check and comments
                    /** 
                     * If AMER FED
                     * If Quote Type = Renewal, Quote Line Start Date < RCDM T EOL Date AND Eligible for RCDM T = True AND Account is not fully transitioned AND there are RCDM T lines AND there are Entitlements AND Quote is not a Scale Utility Quote AND there is no exception for removal of 0$ On Prem SKU
                     * OR
                     * If Quote Type = Renewal+Expansion, Quote Create Date is between Quote Line Start Date and RCDM-T EOL Date AND Eligible for RCDM T = True AND Account is not fully transitioned AND there are RCDM T lines AND there are Entitlements AND Quote is not a Scale Utility Quote AND there is no exception for removal of 0$ On Prem SKU
                     */
                    if (
                    etmArea == 'AMER-FED' &&
                    quote.SBQQ__Type__c == 'Renewal' &&
                    startDate < quoteRangeEnd &&
                    quote.Eligible_for_RCDM_T__c == true &&
                    quote.Is_Customer_Fully_Transitioned__c == false
                ) {
                        console.log('Here is the value>>>');
                            validForRCDM = true;
                        }
					
					
					
                    console.log('> validForRCDM: ',validForRCDM);
                    console.log('> everyRCDMHasParent : ',everyRCDMHasParent);
                    console.log('> matchRCDMParentCount : ',matchRCDMParentCount);
                        if(RscpException==true){
                             var errorMessage ="RSC and RSC-P cannot co-exist on the same Quote.  Please remove one or the other.  If there is a need for both products, please quote them separately.";
                                 console.log('> errorMessage : ',errorMessage);
                            component.set("v.content",errorMessage);
                            isVerified = false;
                        }
            if (showReqByAlert == true) {
						//var errorMessage = "RDCM-T SKU cannot be added as a standalone product. Please select the RCDM-T under RSC License";
						  var errorMessage = "One or more RCDM-T lines is not associated with any license. Please return to the quote line editor and remove any standalone RCDM-T lines which are not linked to a specific license. Please refer to this doc for more detailed steps on how to resolve this error: https://docs.google.com/document/d/1LMZyp-Z69PZWFKLZYyjcM_PinisP4GDfxl8qzNEr07I/edit?usp=sharing";
                component.set("v.content", errorMessage);
                        isVerified = false;
					}
            if (RCDMBeyonddate == true) {
                        var errorMessage = "Too much RCDM-T has been quoted. Please remove any standalone RCDM-T lines as well click the wrench next to each license to remove the RCDM-T line for each license. Please refer to this doc for more detailed steps on how to resolve this error: https://docs.google.com/document/d/1LMZyp-Z69PZWFKLZYyjcM_PinisP4GDfxl8qzNEr07I/edit?usp=sharing";
                component.set("v.content", errorMessage);
                        isVerified = false; // added by madhura for CPQ22-3995

                    }		
            /*if (validForRCDM == false && (everyRCDMHasParent == true || matchRCDMParentCount == true)) {
                        //var errorMessage = "Please remove RCDM-T to proceed.";
                          var errorMessage = "Too much RCDM-T has been quoted. Please remove any standalone RCDM-T lines as well click the wrench next to each license to automatically reconfigure the RCDM-T line for each license. Please refer to this doc for more detailed steps on how to resolve this error: https://docs.google.com/document/d/1LMZyp-Z69PZWFKLZYyjcM_PinisP4GDfxl8qzNEr07I/edit?usp=sharing";
                component.set("v.content", errorMessage);
                        isVerified = false;
            } else if (validForRCDM == true && everyRCDMHasParent == false) {
                        //var errorMessage = "Please add RCDM-T to proceed.";
						
                if (setQLHybridIds2.size > setQLHybridIds.size) {
							var errorMessage = "Too much RCDM-T has been quoted. Please remove any standalone RCDM-T lines as well click the wrench next to each license to automatically reconfigure the RCDM-T line for each license. Please refer to this doc for more detailed steps on how to resolve this error: https://docs.google.com/document/d/1LMZyp-Z69PZWFKLZYyjcM_PinisP4GDfxl8qzNEr07I/edit?usp=sharing";
                } else if (setQLHybridIds2.size < setQLHybridIds.size) {
							var errorMessage = "One or more licenses are missing RCDM-T. Please click the wrench next to each license to reconfigure the bundle and RCDM-T will be automatically added. Please refer to this doc for more detailed steps on how to resolve this error: https://docs.google.com/document/d/1LMZyp-Z69PZWFKLZYyjcM_PinisP4GDfxl8qzNEr07I/edit?usp=sharing";
						}
                component.set("v.content", errorMessage);
                        isVerified = false;
                    } 
				*/
            if (showQuantityAlert == true) {
						var errorMessage = "Missing or insufficient quantity of RCDM-T. Please add more RCDM-T to the quote.";
                component.set("v.content", errorMessage);
                        isVerified = false;
					}
                }
            }
        }
        }
        var countASE = 0;
    	var countCEMPAC = 0;
        // 2821 Ends
	    // CPQ22-3496 starts here - Mandate Arroyo_Subsumed_Old_Contract_Line_Items__c.
		if(isVerified){
			 console.log('Inside 3496');
			  var result = quotelinequeryresult;
              var quoteLinesrecords = quotelinequeryresult;
              var showalert = false;
              var custlabel = $A.get("$Label.c.Disable_Arroyo_Subsumed_Old_Contract_Line_check");
             console.log('custlabel',custlabel);
			if(quoteLinesrecords!=null && quoteLinesrecords!=undefined){  
                
                for(var i = 0; i < quoteLinesrecords.length; i++){
					var quoteLine = quoteLinesrecords[i];
                    console.log('ary family---',quoteLine.Ary_Product_Family__c);
                    if(quoteLine.Ary_Product_Family__c == 'ASE_New' || quoteLine.Ary_Product_Family__c == 'ASE_Renewal'){
                        countASE += quoteLine.SBQQ__Quantity__c;
                    }
                    console.log('test---',quoteLine.Ary_Product_Code__c.includes('RA-CEM-PA_New'));
                    console.log('ary code---',quoteLine.Ary_Product_Code__c);
                    if(['RA-PAC-PP_New', 'RA-PAC-PP_Renewal', 'RA-CEM-PA_New', 'RA-CEM-PA_Renewal', 'RA-CEM-PP_New', 'RA-CEM-PP_Renewal'].includes(quoteLine.Ary_Product_Code__c)) {
                        countCEMPAC = quoteLine.SBQQ__Quantity__c;
                    }
                    console.log('countASE',countASE);
                    console.log('countCEMPAC',countCEMPAC);
                    console.log('Arroyo_Subsumed_Old_Contract_Line_Items__c ',quoteLine.Arroyo_Subsumed_Old_Contract_Line_Items__c);
					console.log('SKU',quoteLine.SBQQ__ProductCode__c);
					if(custlabel == 'No' && quoteLine.SBQQ__SubscriptionPricing__c != null && quote.SBQQ__Type__c != 'Quote' &&
                    ((quote.RWD_Deal_Ops_Exception__c == undefined || quote.RWD_Deal_Ops_Exception__c == null || quote.RWD_Deal_Ops_Exception__c == '') || (quote.RWD_Deal_Ops_Exception__c != null && !quote.RWD_Deal_Ops_Exception__c.includes('Subsumed Old Contract Line Items Validation Exception'))) && 
                    (quoteLine.Arroyo_Subsumed_Old_Contract_Line_Items__c == null || quoteLine.Arroyo_Subsumed_Old_Contract_Line_Items__c == '') && quoteLine.SBQQ__RenewedAsset__c == null &&
                    (quoteLine.Quote_Line_Type__c == 'Renewal' || quoteLine.Special_Program__c == 'Refresh' || quoteLine.Special_Program__c == 'Conversion' || quoteLine.Special_Program__c == 'Replaced')){
						showalert = true;
					}					
				}
                 console.log('showalert ',showalert);
			}
			if(showalert){
				var errorMessage = "Subsumed Old Contract Line Items field is blank. Please mark given quote as Primary to populate this field value and then submit quote for approval. Please contact dealops, if you still find Subsumed Old Contract Line Items filed is blank.";
                component.set("v.content",errorMessage);
                isVerified = false;
			}
		}
		// CPQ22-3496 ends here - Mandate Arroyo_Subsumed_Old_Contract_Line_Items__c.
	
//CPQ22-4200 Start
/*
 if(isVerified) {
	 var quote = component.get("v.quoteRec");
	 if(ScaleExistingUser == true && quote.Scale_Eligible__c == true && ((quote.RWD_Deal_Ops_Exception__c == undefined || quote.RWD_Deal_Ops_Exception__c == null || quote.RWD_Deal_Ops_Exception__c == '') || (quote.RWD_Deal_Ops_Exception__c != null && !quote.RWD_Deal_Ops_Exception__c.includes('Quoting RSC/RSC-P/RSC-G Skus on Scale Account')))){
		var quoteLinesrecords = quotelinequeryresult;
        var showalert = false;
		console.log('Inside CPQ22-4200 Function');
		for(var i = 0; i < quoteLinesrecords.length; i++){
			var quoteLine = quoteLinesrecords[i];
				
            if(quoteLine.Quote_Line_Type__c != 'Renewal' && quoteLine.SBQQ__Optional__c ==false && quoteLine.SBQQ__Product__r.Restrict_Quoting_For__c != null && quoteLine.SBQQ__Product__r.Restrict_Quoting_For__c.includes('Scale')) {
				showalert = true;	
                    console.log('after execution showalert',showalert);
				}
			}
	 }
		if(showalert){
                     isVerified = false;
        var errorMessage = $A.get("$Label.c.Scale_RSC_Validation_Message");
                     component.set("v.content",errorMessage);
                  }	 
 }
 */
//CPQ22-4200 End
	
	//CPQ22-3658 Starts
    //CPQ22-4688 upgrade on conditions starts
        if(isVerified) {
			var validLength = true;
			var hasJustification = true;
			var hasOldSKUs = false;
            if(quote.SBQQ__Type__c != null) {
                var quoteLinesrecords = quotelinequeryresult;
				var oppCloseDate = new Date('01/31/2022').getTime();
            var dFlBrched =quote.Discount_Floor_Breached__c; 
            var msgval = $A.get("$Label.c.BusinessJustification_Validation");  
            if(quoteLinesrecords!=null && quoteLinesrecords!=undefined) {
					if(quote.Discount_Justification__c) {
						if(quote.Discount_Justification__c.length < 20){
						validLength = false;
						}
                } else {//CPQ22-4688 - added else
                    for (let quoteLine of quoteLinesrecords) {
						if(quoteLine.SKU_Type__c == 'Old') {
							hasOldSKUs = true;
						}
					}
                    for (let quoteLine of quoteLinesrecords) {
                        if(quote.SBQQ__Type__c == 'Quote' || quote.SBQQ__Type__c == 'Amendment' || quote.SBQQ__Type__c =='Renewal+Expansion') { // Case 4
                            hasJustification = false;
                        } else if(quoteLine.DiscJustiReq__c) { //case 1
                            hasJustification = false;
                        } else if(quote.Is_Refreshed_Identifier__c && quote.RWD_Opportunity_Close_Date__c > oppCloseDate && hasOldSKUs && quoteLine.Quote_Line_Type__c == 'Renewal' && quoteLine.Disposition_Reason__c == 'Renewing') { //Case 2
                            hasJustification = false;
                        } else if(dFlBrched && dFlBrched > 0) { //Case 3
							hasJustification = false;
						}
					}
                }
            }
            if(!validLength) {
                component.set("v.content",$A.get("$Label.c.Business_Justification_Error_Message"));
                isVerified = false; 
            } 
            //CPQ22-4124 Start
            if(!hasJustification) {
                isVerified = false; 
                component.set("v.showbusinesserr",true); 
                component.set("v.businessVali",msgval); 
            } 
            //CPQ22-4124 End
            }
        }//CPQ22-3658 Ends
    //CPQ22-4688 upgrade on conditions ends
	    
	//CPQ22-2393 Starts
        
        if(isVerified) {
            if(quote.SBQQ__Type__c != null) {
                var countV1Lines = 0;
                var countV2Lines = 0;
                var quoteLinesrecords = quotelinequeryresult;
                if(quoteLinesrecords!=null && quoteLinesrecords!=undefined){
                    console.log('> Imside IF : ');
                    for (var i = 0; i < quoteLinesrecords.length; i++) {
                        var quoteLine = quoteLinesrecords[i];
                        console.log('> QL Type: '+quoteLine.SKU_Type__c);
			if(!quoteLine.SBQQ__Product__r.X0__c){ //ARY-1019
                        if(quoteLine.SKU_Type__c == 'Old') {
                            countV1Lines = countV1Lines + 1;
                        } 
                        if(quoteLine.SKU_Type__c == 'New') {
                            countV2Lines = countV2Lines + 1;
				}
			}
                    }
                    console.log('> countV2Lines: '+countV2Lines);
                    console.log('> countV1Lines: '+countV1Lines);
                    if(countV1Lines > 0 && countV2Lines > 0) {
                        //alert("The “Renewal + Expansion” quote must have renewal and new lines for submitting the quote for approval.");
                        var errorMessage = "The Old and New SKUs cannot be quotes together.";
                        component.set("v.content",errorMessage);
                        isVerified = false;
                    }
                }
            }
        } //CPQ22-2393 Ends    
         
        if(isVerified) {
            console.log('quote.SBQQ__Type__c',quote.SBQQ__Type__c)
              if(quote.SBQQ__Type__c== 'Renewal+Expansion'){
                  console.log('inside m');
                  var result = quotelinequeryresult;
                  var quoteLinesrecords = quotelinequeryresult;
                  var showalert = false;
                  console.log('res>>',quoteLinesrecords);
                   if(quoteLinesrecords!=null && quoteLinesrecords!=undefined){
                          for (var i = 0; i < quoteLinesrecords.length; i++) {
                              var quoteLine = quoteLinesrecords[i];
                              console.log('here in for');
                              if(quoteLine.Quote_Line_Type__c == 'Renewal' && quoteLine.SBQQ__Group__r.Name == 'Renewal Quote' && quoteLine.SBQQ__SubscriptionPricing__c == 'Fixed Price' && (quoteLine.Disposition_Reason__c == 'None' || quoteLine.Disposition_Reason__c == '' || quoteLine.Disposition_Reason__c == null)){
                                 showalert = true;
                                  console.log('here in if');
                                 // break;  
                              }
                              
                          }
                       if(showalert){
                           isVerified = false;
                           console.log('here in if');
                           component.set("v.content","Populate disposition reason before submitting for Approval!!");
                        }
                   }
              }
        }

        //CPQ22-3953 Starts 
        if (isVerified) { 
            if (quote.SBQQ__Type__c != null) { 
                var quoteLinesrecords = quotelinequeryresult; 
                if (quoteLinesrecords != null && quoteLinesrecords != undefined) { 
                    for (var i = 0; i < quoteLinesrecords.length; i++) { 
                        var quoteLine = quoteLinesrecords[i]; 
 
                        if (quoteLine.Quote_Line_Type__c == 'Renewal' && quoteLine.Disposition_Reason__c == 'Renewing' &&  quoteLine.SBQQSC__RenewedContractLine__c != null && (quoteLine.SBQQ__EndDate__c == null || quoteLine.SBQQ__EndDate__c == '')) { 
                            var errorMessage = "Renewal QLIs must not have an empty End Date and it is mandatory for this field to be populated."; 
                            component.set("v.content", errorMessage); 
                            isVerified = false; 
                            console.log('MS 3953 QLI: ' + quoteLine.SBQQ__ProductCode__c); 
                        } 
                    } 
                }   
            } 
        } 
        //CPQ22-3953 Ends 

        //CPQ22-6026 Starts
        if (isVerified) {
            var quoteLinesrecords = quotelinequeryresult;
			if(quoteLinesrecords != undefined && quoteLinesrecords != null){
			var qlRepCount = [];
            for (var i = 0; i < quoteLinesrecords.length; i++) {
                    var quoteLine = quoteLinesrecords[i];
                    if(quoteLine.Special_Program__c != undefined &&  quoteLine.Special_Program__c != null &&
                       quoteLine.Prepayment_Credit__c != undefined && quoteLine.Prepayment_Credit__c != null && quoteLine.Prepayment_Credit__c > 0){
                       qlRepCount.push(quoteLine.Id);
                    }                              
            	}
            }
            var oppValid = component.get("v.disableOppValid");
            if(quote.SBQQ__Type__c == 'Renewal+Expansion' && oppValid == false && quote.SBQQ__Primary__c != undefined && 
               quote.SBQQ__Primary__c == true && quote.Credit_Calculation_Start_Date__c != null && quote.SBQQ__Opportunity2__r.CloseDate != null && 
               quote.SBQQ__Opportunity2__r.CloseDate > quote.Credit_Calculation_Start_Date__c && 
               qlRepCount != undefined && qlRepCount.length > 0){
                    component.set("v.content",$A.get("$Label.c.Primary_Quote_Opportunity_Closed_Date"));
                    isVerified = false;
            }
        }	
        //CPQ22-6026 End

        //FY25SR-1873 Starts 
        if (isVerified) { 
                var quoteLinesrecords = quotelinequeryresult; 
                if (quoteLinesrecords != null && quoteLinesrecords != undefined) { 
                    for (var i = 0; i < quoteLinesrecords.length; i++) { 
                        var quoteLine = quoteLinesrecords[i]; 
						if(quoteLine.Replacement_Details__c != null && quoteLine.Quote_Line_Type__c == 'Renewal' && quoteLine.Disposition_Reason__c == 'Renewing'){
						console.log('inside approval button ');
                            var quantitySum = 0; 
							if(quoteLine.SBQQSC__RenewedContractLine__c != null && quoteLine.SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__c != null){
								quantitySum +=  (quoteLine.Atlassian_Quantity__c != null ? parseInt(quoteLine.Atlassian_Quantity__c) : 0);
								quantitySum +=  (quoteLine.Salesforce_Quantity__c != null ? parseInt(quoteLine.Salesforce_Quantity__c) : 0);
								quantitySum +=  (quoteLine.Rubrik_Hosted_M365_Quantity__c != null ? parseInt(quoteLine.Rubrik_Hosted_M365_Quantity__c) : 0);
								quantitySum +=  (quoteLine.Dynamics_Quantity__c != null ? parseInt(quoteLine.Dynamics_Quantity__c) : 0);
								}
                            console.log('quantitySum111 ',quantitySum, '2222 ',quoteLine.SBQQ__Quantity__c);
							if(parseInt(quantitySum) > 0 && parseInt(quoteLine.SBQQ__Quantity__c) != null && parseInt(quoteLine.SBQQ__Quantity__c) != parseInt(quantitySum)){
								var errorMessage = "Sum of Atlassian_Quantity__c, Salesforce_Quantity__c, Rubrik_Hosted_M365_Quantity__c and Dynamics_Quantity__c for "+quoteLine.Name+" should match the partia used"; 
								component.set("v.content", errorMessage); 
								isVerified = false; 
							}
						}   
					}
				}				 	 
		} 
		//FY25SR-1873 Ends


	//SF-37153 starts
        if(isVerified) {
            var result = quotelinequeryresult;
            var quoteLinesrecords = quotelinequeryresult;
            var showalert = false;
		var showDatealert = false;
            var supportAssets = [];
            var assetsUnique = [];
            if(quoteLinesrecords!=null && quoteLinesrecords!=undefined){
                for (var i = 0; i < quoteLinesrecords.length; i++) {
                    var quoteLine = quoteLinesrecords[i];
			
			if(quote.SBQQ__ExpirationDate__c > quoteLine.PRE_Promo_Expiration_Date__c && quoteLine.Promo_Code__c == 'Proactive Promo') {
                        showDatealert = true;
                        break;
                    }
                    if(quoteLine.Quote_Line_Type__c == 'Renewal' && quoteLine.Product_Type__c == 'HW Support' && quoteLine.SubscribedAssetNames__c && 
                    (quoteLine.Disposition_Reason__c == 'Renewing' || quoteLine.Disposition_Reason__c == 'None' || quoteLine.Disposition_Reason__c == '')
                    ){
                        supportAssets.push(quoteLine.SubscribedAssetNames__c);
                    }
                }
                if (supportAssets != null && supportAssets != undefined) {
                    for (var i = 0; i < supportAssets.length; i++) { 
                        var strToCompare = supportAssets[i];
                    	strToCompare = strToCompare.trim();
                        if (strToCompare == '' || strToCompare == null || strToCompare == undefined) continue;
            
                        if (strToCompare != null && strToCompare != undefined) {
                            if (assetsUnique != null && assetsUnique != undefined && assetsUnique.includes(strToCompare)) {
                                showalert = true;
                                break;
                            }
                            assetsUnique.push(strToCompare);
                        }
                    }
                }
                if(showalert){
                    isVerified = false;
                    component.set("v.content","Same Assets are present in more than one HW Support. Please contact Admin for assistance");
                }
		    if(showDatealert){
                    isVerified = false;
                    component.set("v.content","Quote expiration date can't be after that of promo date.");
                }
            } 
        }
        //SF-37153 ends
        //added for CPQ22-3399 start
        if(isVerified) {
            if(quote.OpportunitySubType__c == 'CSAT' && !quote.Discounted_Units_due_to_CSAT_or_Sizing__c )
            {
                console.log('**CSATTTT**');
                component.set("v.content","This is a CSAT quote. Please check the \"Discounted Units due to CSAT or Sizing\" checkbox in the \"CSAT Reason Section\" of the quote and populate the required CSAT fields.");

            }
        }
        //added for CPQ22-3399 end
      //CPQ22_3309 Start
        if(isVerified) {
             if(quote.Eligible_for_Onsite_Consulting__c==false){
                  //var result = quotelinequeryresult;
                  var quoteLinesrecords = quotelinequeryresult;
                  var showalert = false;
                  console.log('res>>',quoteLinesrecords);
                   if(quoteLinesrecords!=null && quoteLinesrecords!=undefined){
                          for (var i = 0; i < quoteLinesrecords.length; i++) {
                              var quoteLine = quoteLinesrecords[i];
                              console.log('here in for');
                              if(quoteLine.SBQQ__ProductCode__c =='RA-PS-CON-ONST' ){
                                 showalert = true;
                                  console.log('Online consultling 1');                                  
                              }                              
                          }
                       if(showalert){
                           isVerified = false;
                           console.log('Online consultling 2');
                           component.set("v.content","Please approve the sku’s at account level ( LA products), before processing the quote");
                        }
                   }
              }
        }
        //CPQ22_3309 End
	    
        if (isVerified) {
            var quoteLines = quotelinequeryresult;

            if (!!quoteLines) {
                const aspenCount = quoteLines.filter((ql) => {
                    return ql.Check_of_ASPEN_Hardware__c == true;
                }).length,
                    polarisCount = quoteLines.filter((ql) => {
                        return ql.Check_of_POLARIS_Hardware__c == true;
                    }).length;

                if (aspenCount > 0 && polarisCount > 0) {
                    var errorMessage = 'Mixing of Aspen and Non Aspen SKUs is not allowed.';
                    component.set('v.content', errorMessage);
                    isVerified = false;
                }
            }
        }
        var approveQuote = false;
        var reqApproval = false;
        if(isVerified) {
            if(quote.SBQQ__Type__c == 'Renewal+Expansion') {
                var countNewLines = 0;
                var countRenewalLines = 0;
                var quoteLinesrecords = quotelinequeryresult;
                var cliList = [];
                var entitlementRecords = [];
                if(quoteLinesrecords!=null && quoteLinesrecords!=undefined){
                    for (var i = 0; i < quoteLinesrecords.length; i++) {
                        var quoteLine = quoteLinesrecords[i];
                        if(quoteLine.Line_Type__c == 'New' && quoteLine.SBQQ__ProductCode__c !='RS-BT-RCDM-T') {
                            countNewLines = countNewLines + 1;
                        } else if(quoteLine.Line_Type__c == 'Renewal') {
                            countRenewalLines = countRenewalLines + 1;
                        }
                    
                        if(quoteLine.Product_Subtype__c == 'FEDRAMP' && quoteLine.Special_Program__c == 'Replaced'){
                            if(((quote.RWD_Sales_Rep_Exception__c != null && quote.RWD_Sales_Rep_Exception__c.includes('25% Premium RSC-G Replacement')) && (Math.round(quoteLine.SBQQ__NetTotal__c) < Math.round(quoteLine.Target_NetTotal__c)))){
                                reqApproval = true;
                                //console.log('MS reqApproval : ',reqApproval);
                            }
                            if(
                            ((quote.RWD_Sales_Rep_Exception__c != null && quote.RWD_Sales_Rep_Exception__c.includes('25% Premium RSC-G Replacement'))  && (Math.round(quoteLine.SBQQ__NetTotal__c) >= Math.round(quoteLine.Target_NetTotal__c)))
                            ){
                                approveQuote =true; //RSCG-59
                            }
                        }
                    }
                    approveQuote = reqApproval ? false : approveQuote;
                    //Added by Madhura CPQ22-5293
                    if(approveQuote== true){
                        component.set("v.ApproveQuote",approveQuote);
                        
                    }
                }
                if(countNewLines == 0 &&  countRenewalLines > 0) { // modified for CPQ22-4596 Madhura
                    //alert("The “Renewal + Expansion” quote must have renewal and new lines for submitting the quote for approval.");
                    isVerified = false;
                    var errorMessage = "The quote contains only renewal lines. If there are no new lines to be ordered please reach out to the renewal rep.";
                                component.set("v.content",errorMessage);
                }
            }
        }
        //FY25SR-1216 && FY25SR-1076
        console.log('isVerified---- ', isVerified);
        if(isVerified) { // || quote.SBQQ__Type__c === 'Renewal'
            let hasAccess = component.get("v.showSMSPage");
              console.log('hasAccess1 ', hasAccess); 
            // debugger;
            if(!hasAccess) {
                console.log('hasAccess ', hasAccess);  
            if(quote.SBQQ__Type__c === 'Renewal+Expansion') {
                var quoteLinesrecords = quotelinequeryresult;
                var cliList = [];
                var entitlementRecords = [];
                if(quoteLinesrecords){
                    for (var i = 0; i < quoteLinesrecords.length; i++) {
                        var quoteLine = quoteLinesrecords[i];
                        if(quoteLine.Arroyo_Subsumed_Old_Contract_Line_Items__c != null && quoteLine.Disposition_Reason__c != null) {
                            quoteLine.Arroyo_Subsumed_Old_Contract_Line_Items__c.split(',').forEach(cli => {
                                cliList.push(cli);
                            });
                        }
                    }
                }
                var cpqDispositionResult = component.get("v.cpqDispositionQLs");
                if(cpqDispositionResult) {
                    cpqDispositionResult.forEach(disposition => {
                        if(disposition.Arroyo_Subsumed_Old_Contract_Line_Items__c != null && disposition.Disposition_Reason__c != null) {
                         disposition.Arroyo_Subsumed_Old_Contract_Line_Items__c.split(',').forEach(cli => {
                             cliList.push(cli);
                         });
                        } 
                     });
                }
                var next_365_days = component.get("v.next_365_days");
                var last_90_days = component.get("v.last_90_days");
                    console.log('test----- ',entitlementQueryResult);
                entitlementQueryResult.forEach(ent => {
                        var todayDate = new Date(quote.CreatedDate); //Added for FY25SR
                        console.log('todayDate is ',todayDate);
                    var last90Days = helper.addDays(todayDate, last_90_days*(-1));
                        console.log('last90Days is ', last90Days);
                    var next1year = helper.addDays(todayDate, next_365_days);
                        console.log('next1year is ', next1year);            
                    var endDate = new Date(ent.EndDate);
                    var scQuotePresent = (ent.ServiceContractId && ent.ServiceContract.SBQQSC__Quote__c!=null && ent.ServiceContract.SBQQSC__Quote__c!= undefined) ? true : false;
					var scOppPresent = (ent.ServiceContractId && ent.ServiceContract.SBQQSC__Opportunity__c!=null && ent.ServiceContract.SBQQSC__Opportunity__c!=undefined) ? true: false;
                    if(endDate >= last90Days && endDate <= next1year) {
     
                            console.log('check1', scQuotePresent);
                            console.log('check2', scOppPresent);
                            
                        if(ent.Product__c) {
                                if(ent.Product__r.Replacement_Category__c != null && ent.Entitlement_Status__c != 'Terminated' && ent.Renewal_Category__c != 'Refreshed' 
                                && (ent.Order_Service_Item__c != null && ent.Order_Service_Item__r.OrderId != null && ent.Order_Service_Item__r.Order.Type === 'Revenue') 
                                && ent.Type === 'Phone Support' 
                                && ((ent.Renewal_Category__c == null && ent.ContractLineItemId != null && ent.ContractLineItem.SBQQSC__RenewalQuantity__c > 0) 
                                    || (ent.Renewal_Category__c === 'Renewed' && ent.Status === 'Active') 
                                    || (ent.Renewal_Category__c === 'Refreshed' && ent.Product__r.Product_Type__c != 'HW Support') 
                                    || (ent.Renewal_Category__c === 'MIXEDPARTIAL')) 
                                && ent.Product__r.SBQQ__SubscriptionType__c === 'Renewable'
                                && ((scQuotePresent && ent.ServiceContract.GPL_Deal__c !== 'true' && ent.ServiceContract.SBQQSC__Quote__r.Is_Scale_Utility_Quote__c == false) 
									|| ( !scQuotePresent && scOppPresent && !['GC Offer','GC Renewal','GC OnDemand','MSP'].includes(ent.ServiceContract.SBQQSC__Opportunity__c.Opportunity_Sub_Type__c)))) {                        
                        if((cliList == null && cliList.length < 1) || !cliList.includes(ent.ContractLineItemId)) {
                            var entLinks = ent.Entitlement_Links__r;
                                     console.log('entLinks ',entLinks);
                                    if (entLinks && entLinks.length > 0) {
                                        entLinks.forEach(function(link) {
                                         if (link.Renewed_Entitlement__r && link.Renewed_Entitlement__r.EndDate) {
                                            var inactiveEndDate = new Date(link.Renewed_Entitlement__r.EndDate);
                                            if(inactiveEndDate >= last90Days && inactiveEndDate <= next1year){
                            entitlementRecords.push(ent.Id);
                        }
                    }
                                        });
                        }
                                 else{
                                    entitlementRecords.push(ent.Id);
                                  }
                        
                    }
                                  }
                                 }
                                }
                });
                if(entitlementRecords != null && entitlementRecords.length > 0) {
                        console.log('#666 '+JSON.stringify(entitlementRecords));
                    isVerified = false;
                    var errorMessage = $A.get("$Label.c.Verbiage_Disposition_Reason_Missing"); 
                    component.set("v.content",errorMessage);
                }
            }
        } 
        } 
        //MS CPQ22-4256
        if(isVerified) {
            var showalert = false;
            var showASEalert = false;
            var quoteLinesrecords = quotelinequeryresult;
            if(quoteLinesrecords!=null && quoteLinesrecords!=undefined){
                for (var i = 0; i < quoteLinesrecords.length; i++) {
                    var quoteLine = quoteLinesrecords[i];
                    console.log('line type ', quoteLine.Quote_Line_Type__c);
                    console.log('countASE--- ', countASE);
                    console.log('countCEMPAC--- ', countCEMPAC);
                    console.log('family--- ', quoteLine.SBQQ__ProductFamily__c);
                    console.log('rbrk includes ', quote.RBRK_NotSummaryVarCustomRuleId__c.includes('FS'));
                    if(quoteLine.SBQQ__ProductFamily__c == 'ASE' && (quoteLine.Quote_Line_Type__c == 'New' || (quoteLine.Quote_Line_Type__c == 'Renewal' && quoteLine.Disposition_Reason__c == 'Renewing')) && countASE > 0 && countCEMPAC <= 0 && quote.RBRK_NotSummaryVarCustomRuleId__c.includes('FS')
                             && ((quote.RWD_Deal_Ops_Exception__c == undefined || quote.RWD_Deal_Ops_Exception__c == null || quote.RWD_Deal_Ops_Exception__c == '') || (quote.RWD_Deal_Ops_Exception__c != null && !quote.RWD_Deal_Ops_Exception__c.includes('IT Quoting Exceptions')))){
                       console.log('inside if--- ', showASEalert);
                       showASEalert = true;
                    }
                    if(quoteLine.SBQQ__ProductCode__c.includes('NRD') && (quoteLine.Quote_Line_Type__c == 'New' || quoteLine.Quote_Line_Type__c == 'Existing' || (quoteLine.Quote_Line_Type__c == 'Renewal' && quoteLine.Disposition_Reason__c == 'Renewing'))){
                        if(quoteLine.SubscribedAssetNames__c != null){
                            var asts = quoteLine.SubscribedAssetNames__c.split(",");
                            var astCount = asts.length;
                            if(quoteLine.SBQQ__Quantity__c != astCount){
                                showalert = true;
                            }
                        } else if(quoteLine.SBQQ__RequiredBy__c != null && quoteLine.SBQQ__RequiredBy__c != undefined && quoteLine.SBQQ__RequiredBy__r.Ary_Product_Type__c == 'Hardware_New' && quoteLine.SBQQ__Quantity__c != quoteLine.SBQQ__RequiredBy__r.SBQQ__Quantity__c){
                            showalert = true;
                        }
                    }
                }
                if(showalert){
                    isVerified = false;
                    var errorMessage = "NRD Quantity does not match the quantity of the appliances quoted. Please update the quantities to match.";
                    component.set("v.content",errorMessage);
                 }
                if(showASEalert){
                    isVerified = false;
                    console.log('showASEalert---- ',showASEalert);
                    var errorMessage = "RA-ASE-PP/-PA cannot be sold as standalone.";
                    component.set("v.content",errorMessage);
                }
            }
        }
        //MS CPQ22-4256

        //CPQ22-3378--start
	    if(isVerified){
            //component.set("v.content",'testing validation');
            var action = component.get('c.validateSubsAssets');
            console.log('ACTION >> ', action);
            var dispo = component.get("v.cpqDispositionQLs") || [];
			console.log('validate assets>>');
             var errmsg;
             //var quoteLinesrecords = component.get("v.quoteLineItemsRecds");
            action.setParams({
            quotelineRecs: component.get("v.quoteLineItemsRecds") || [],
            dispositionLines: component.get("v.cpqDispositionQLs") || []
            });
            action.setCallback(this,function(response){
                console.log('response'+response.getState());
               // if(response.getState() === "SUCCESS"){
                    if(response.getReturnValue()!= null){
                     errmsg = response.getReturnValue(); 
                     console.log('errmsg>>'+errmsg);
                     component.set("v.content",response.getReturnValue());
                     isVerified = false;
                     console.log('isVerified inside'+isVerified);
                    }
           //}
            });
            console.log('show val 1'+component.get("v.content"));
              if(component.get("v.content")!= ''  ){
			//isVerified = false;               
            }
            $A.enqueueAction(action);
            if(errmsg!= null && errmsg!= '' ){
            isVerified = false;
            }
            console.log('show val '+component.get("v.content"));
           
            
        }
         console.log('isVerified'+isVerified);
	    //CPQ22-3378--end
	    //CPQ22-3866 Start
        /*
       if(isVerified) {
           if(quote.ETM_Area__c== 'AMER-FED' && ((quote.RWD_Deal_Ops_Exception__c == undefined || quote.RWD_Deal_Ops_Exception__c == null || quote.RWD_Deal_Ops_Exception__c == '') || (quote.RWD_Deal_Ops_Exception__c != null && !quote.RWD_Deal_Ops_Exception__c.includes('AMER-FED Account quoting RSC')))) {
            var quoteLinesrecords = quotelinequeryresult;
            var showalert = false;
            if(quoteLinesrecords!=null && quoteLinesrecords!=undefined){
                    for (var i = 0; i < quoteLinesrecords.length; i++) {
                        var quoteLine = quoteLinesrecords[i];
                        if((quoteLine.Product_Level__c == 'Hybrid Software' || quoteLine.Product_Level__c == 'SaaS Software Addon' || quoteLine.Product_Level__c == 'Standalone Software Addon') &&
                                quoteLine.Product_Type__c != 'RZTDP' && quoteLine.SBQQ__Optional__c ==false
                              && quoteLine.Product_Subtype__c != 'Ondemand Sub Reserve' && quoteLine.Product_Subtype__c != 'Ondemand Above Reserve' && quoteLine.Product_Subtype__c != 'Scale MSP' 
                              && quoteLine.Product_Subtype__c != 'On Demand' && quoteLine.Product_Subtype__c != 'FEDRAMP' && quoteLine.Product_Subtype__c !='E1000' && quoteLine.Product_Type__c != 'NAS' && (!quoteLine.SBQQSC__RenewedContractLine__c || !quoteLine.SBQQSC__RenewedContractLine__r.AMER_FED_Exception__c))
                        {
                            showalert = true; 
                            break;
                        }
                        
                    }
                 if(showalert){
                     isVerified = false;
                     var errorMessage = "US FED Accounts are not eligible to buy RSC / other SaaS products that are not FedRAMP certified, please remove this product from the quote and select either RSCP or RSCG instead. If RSC / other SaaS products are required, please contact Deal Ops.";
                     component.set("v.content",errorMessage);
                  }
             }
        }
       }
        */

        //MS CPQ22-6146 Starts
        if(isVerified){
            const lines = Array.isArray(quotelinequeryresult) ? quotelinequeryresult : [];
            if (!lines.length) return;
            
            if (!quote.Opportunity_Program__c && !!lines) {
                const spCount = lines.filter((ql) => {
                    return ql.Special_Program__c != undefined &&  ql.Special_Program__c != null;
                }).length;

                if (spCount > 0) {
                    var errorMessage = 'Opportunity Program is blank for this replacement quote. Please contact Deal Ops to populate a Special Program.';
                    component.set('v.content', errorMessage);
                    isVerified = false;
                }
            }
            
            if(isVerified){
                const allowedDispositions = new Set(['Converted', 'Refreshed', 'Upgraded', 'Replaced']);
                const renewedCliIds = new Set(
                    lines
                        .filter(ql =>
                            ql &&
                            ql.Quote_Line_Type__c === 'Renewal' &&
                            ql.Disposition_Reason__c &&
                            allowedDispositions.has(ql.Disposition_Reason__c) &&
                            ql.SBQQSC__RenewedContractLine__c
                        )
                        .map(ql => String(ql.SBQQSC__RenewedContractLine__c).trim())
                );

                if (renewedCliIds != null && renewedCliIds.size > 0) { 

                const hasViolation = lines.some(ql => {
                    const skipFor = ['HW Support', 'Hardware'];
                    if (!ql || ql.Quote_Line_Type__c !== 'New' || skipFor.includes(ql.Product_Type__c)) return false;
                    const subsumed = ql.Arroyo_Subsumed_Old_Contract_Line_Items__c;
                    const sp = ql.Special_Program__c;
                    if (!subsumed || (sp !== null && sp !== undefined && sp !== '')) return false;

                    return String(subsumed)
                        .split(',')
                        .map(id => String(id || '').trim())
                        .some(id => id && renewedCliIds.has(id));
                });

                if (hasViolation) {
                    var errorMessage = 'New Replacement Line(s) does not contain a "Special Program" please contact Deal Ops to populate a Special Program.';
                    component.set('v.content', errorMessage);
                    isVerified = false;
                }
            }
            }
        }
        //MS CPQ22-6146 Ends
        
	   //CPQ22-3975 Starts

	   if(isVerified) {
        //Case 1: HW Without SW - If Quote Line Type = New AND Deal Ops Exception = "HW Without SW" , If RequiredBy == null AND Product = Hardware, then check for fields and then error.
        //Case 2: SW without HW - If Quote Line Type = New AND Deal Ops Exception = "SW Without HW" , If RequiredBy != null AND Product = Hardware AND QuoteLine.Optional = TRUE, then check for fields and then error.
        //Case 3: SW without HW - If Quote Line Type = New AND Deal Ops Exception = "SW Without HW" , If RequiredBy != null AND Product = Hardware AND QuoteLine.Optional = False, store it in a list. If any RSC line is not present in this list then check for fields and then error.
        
        var quoteLinesrecords = quotelinequeryresult;
        var showalertforHWWOSW = false;
        var showalertforSWWOHW = false;
        var rscSKUswithHW = new Map();
        var allrscSKU = [];
        var skuAll = new Set();
        var HWwithQty = new Map();
        var disable = $A.get("$Label.c.DisableFieldsExcQuoting");
        //CPQ22-5991 Starts - consider Quote's Distributor Name if present, else consider Opportunity's Distributor Name
        var distiName = (quote && (quote.SBQQ__Distributor__c != null && quote.SBQQ__Distributor__r.Name ) ? quote.SBQQ__Distributor__r.Name  : 
        (quote && quote.Distributor_s_Name__c != null) ? quote.Distributor_s_Name__c : '');
        var isMktPlace = distiName != null ? distiName.toLowerCase().includes('marketplace'.toLowerCase()) : false; 
        //CPQ22-5991 Ends
        if(disable == 'false') {
            
            if(quoteLinesrecords!=null && quoteLinesrecords!=undefined){
                
                for (var i = 0; i < quoteLinesrecords.length; i++) {
                    
                    var quoteLine = quoteLinesrecords[i];
                    //If New Quote Line and Deal Ops Exception given, then only proceed.
                    //replaced RWD_Deal_Ops_Exception__c with Quoting_Desk_Exception__c for SF-72381
                    if (quoteLine.Quote_Line_Type__c == 'New' && quote.Quoting_Desk_Exception__c != null && quote.ProcessType__c != 'Aspen'){ 
                        //Case 1: Check for Quoting Exception - HW without SW. In such cases, check for the mandatory fields for Quoting Exception - HW without SW.
                            if (quote.Quoting_Desk_Exception__c.includes('Quoting Exception - HW without SW') && quoteLine.SBQQ__RequiredBy__c == null && 
                                !isMktPlace && //MS CPQ22-4361 //CPQ22-5991 Added isMktPlace
                                (quoteLine.Product_Type__c == 'Hardware' || quoteLine.Product_Type__c == 'Add-On Node')) {
                            if (quoteLine.Licensing_Model__c == null || quoteLine.Licensing_Model__c == undefined ) {
                                showalertforHWWOSW = true;
                                break;
                            }
                        }
                        
                        //Case 2: Quoting Exception - SW without HW - If Quote Line Type = New AND Deal Ops Exception = "Quoting Exception - SW without HW" , If RequiredBy != null AND Product = Hardware AND QuoteLine.Optional = TRUE, then check for fields and then error.
                        //Change for SF-72381
                        if (quote.Quoting_Desk_Exception__c.includes('Quoting Exception - SW without HW') 
                             && !(quoteLine.Quote_Line_Type__c == 'New' && (quoteLine.Special_Program__c == null || quoteLine.Special_Program__c == undefined )) // MS CPQ22-5144Bypass for New Sale
                            ) {
                            //Get All RSCs present in the Quote 
                            if(!quoteLine.SBQQ__Product__r.IsHardwareNotRequiredForHybridLicense__c) {
                                allrscSKU.push({value:quoteLine, key:quoteLine.Id});
                            } 
                            //Get All RSC Lines associated with HW, where Optional = false. This will give the true HWs associated with the SW.
                            if (quoteLine.SBQQ__RequiredBy__c != null && 
                                (quoteLine.Product_Type__c == 'Hardware' || quoteLine.Product_Type__c == 'Add-On Node') && 
                               !quoteLine.SBQQ__Optional__c && !quoteLine.SBQQ__Existing__c
                               ) {
                                rscSKUswithHW[quoteLine.SBQQ__RequiredBy__c] = quoteLine;
                            }
                            //showalertforSWWOHW = true for All Hardware which has Optional = true and Required By has details blank.
                            if (quoteLine.SBQQ__RequiredBy__c != null && 
                                    !isMktPlace && //MS CPQ22-4361 //CPQ22-5991 Added isMktPlace
                               (quoteLine.Product_Type__c == 'Hardware' || quoteLine.Product_Type__c == 'Add-On Node') && 
                                (quoteLine.SBQQ__Optional__c || quoteLine.SBQQ__Existing__c) && 
                                ((quoteLine.SBQQ__RequiredBy__r.Arroyo_Subsumed_Old_Contract_Line_Items__c == null || quoteLine.SBQQ__RequiredBy__r.Arroyo_Subsumed_Old_Contract_Line_Items__c == undefined ) || 
                                 (quoteLine.SBQQ__RequiredBy__r.Subscribed_Asset_Name__c == null || quoteLine.SBQQ__RequiredBy__r.Subscribed_Asset_Name__c == undefined) || 
                                 (quoteLine.SBQQ__RequiredBy__r.SubscribedAssetNames__c == null || quoteLine.SBQQ__RequiredBy__r.SubscribedAssetNames__c == undefined))) {
                                showalertforSWWOHW = true;
                            }
                            
                            //showalertforSWWOHW = true for All HW Support which has Required By as Optional = true and has details blank on itself.
                            if (((quoteLine.SBQQ__RequiredBy__c == null && quoteLine.Product_Type__c == 'HW Support') || 
                                (quoteLine.SBQQ__RequiredBy__c != null && 
                                 (quoteLine.SBQQ__RequiredBy__r.Product_Type__c == 'Hardware' || quoteLine.SBQQ__RequiredBy__r.Product_Type__c == 'Add-On Node') && 
                                quoteLine.Product_Type__c == 'HW Support' && (quoteLine.SBQQ__RequiredBy__r.SBQQ__Optional__c || quoteLine.SBQQ__RequiredBy__r.SBQQ__Existing__c))
                               ) && 
                                    !isMktPlace && //MS CPQ22-4361 //CPQ22-5991 Added isMktPlace
                               ((quoteLine.Arroyo_Subsumed_Old_Contract_Line_Items__c == null || quoteLine.Arroyo_Subsumed_Old_Contract_Line_Items__c == undefined ) || 
                                (quoteLine.Subscribed_Asset_Name__c == null || quoteLine.Subscribed_Asset_Name__c == undefined) || 
                                (quoteLine.SubscribedAssetNames__c == null || quoteLine.SubscribedAssetNames__c == undefined)
                               )) {
                                showalertforSWWOHW = true;
                                console.log('showalertforSWWOHW2n'+showalertforSWWOHW);
                            }

                            //CPQ22-4680 starts//
                            if((quoteLine.SBQQ__Product__c != null && quoteLine.SBQQ__Product__r.Restrict_Quoting_For__c != null && quoteLine.SBQQ__Product__r.Restrict_Quoting_For__c.includes('Bypass SW Without HW Validation')) ||
                               (quoteLine.SBQQ__RequiredBy__c != null && 
                               ((quoteLine.SBQQ__RequiredBy__r.SBQQ__Product__c != null && quoteLine.SBQQ__RequiredBy__r.SBQQ__Product__r.Restrict_Quoting_For__c != null && quoteLine.SBQQ__RequiredBy__r.SBQQ__Product__r.Restrict_Quoting_For__c.includes('Bypass SW Without HW Validation')) ||
                               (quoteLine.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c != null && quoteLine.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__c != null && quoteLine.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Restrict_Quoting_For__c != null && quoteLine.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Restrict_Quoting_For__c.includes('Bypass SW Without HW Validation'))))){
                                skuAll.add(quoteLine.Id);
                                showalertforSWWOHW = false;
                                console.log('showalertforSWWOHWlast'+showalertforSWWOHW);
                            }
                           //CPQ22-4680 ends//
                        }
                    }
                }
                
                var mapLength = Object.keys(allrscSKU).length;
                if (mapLength > 0) { 
                    allrscSKU.forEach(function(value, key) {
                        var quoteLineNew = allrscSKU[key].value; 
                        var IdKey = String(allrscSKU[key].value.Id);
                        //Check if the RSC is associated with HW which is not marked as Optional
                        if (rscSKUswithHW[IdKey] != null && rscSKUswithHW[IdKey] != undefined ) {
                            console.log('Correct RSC-',rscSKUswithHW[IdKey]);
                        }
                        else {
                            //CPQ22-4680 Starts//
                            if(skuAll.has(IdKey)){
                                console.log('found key');
                            }else{
                            //CPQ22-4680 Ends//
                            //If the RSC is not associated with HW and if the details are blank, then throw error
                                if (!isMktPlace && ( //MS CPQ22-4361 //CPQ22-5991 Added isMktPlace
                                    (quoteLineNew.SBQQ__RequiredBy__c != null && ((quoteLineNew.SBQQ__RequiredBy__r.Arroyo_Subsumed_Old_Contract_Line_Items__c == null || quoteLineNew.SBQQ__RequiredBy__r.Arroyo_Subsumed_Old_Contract_Line_Items__c == undefined ) || 
                                                                              (quoteLineNew.SBQQ__RequiredBy__r.Subscribed_Asset_Name__c == null || quoteLineNew.SBQQ__RequiredBy__r.Subscribed_Asset_Name__c == undefined) || 
                                                                              (quoteLineNew.SBQQ__RequiredBy__r.SubscribedAssetNames__c == null || quoteLineNew.SBQQ__RequiredBy__r.SubscribedAssetNames__c == undefined))) ||
                                ((quoteLineNew.Arroyo_Subsumed_Old_Contract_Line_Items__c == null || quoteLineNew.Arroyo_Subsumed_Old_Contract_Line_Items__c == undefined ) || 
                                 (quoteLineNew.Subscribed_Asset_Name__c == null || quoteLineNew.Subscribed_Asset_Name__c == undefined) || 
                                 (quoteLineNew.SubscribedAssetNames__c == null || quoteLineNew.SubscribedAssetNames__c == undefined)
                                )) 
                               ) {
                                showalertforSWWOHW = true;
                            }
                        }
                        }
                    });
                }
            }
            
            if(showalertforHWWOSW || showalertforSWWOHW){
                isVerified = false;  
                //component.set("v.content",$A.get("$Label.c.ExceptionQuoting_ErrorMessageHW"));
                component.set("v.showDetailsScreen",true);
            }
        }
        
    }
    //CPQ22-3975 Ends 

    if(isVerified) {
        if(quote.ETM_Area__c!= 'AMER-FED') {
            var quoteLinesrecords = quotelinequeryresult;
            var showalert = false;
            var showmsg = false;
                    var errorMessage = "Only US FED Accounts are eligible to buy RSCP, please remove RSCP and select RSC instead. If RSCP is required, please request access via the “RSC-P Exception Request” form";
            if(quoteLinesrecords!=null && quoteLinesrecords!=undefined){
            for (var i = 0; i < quoteLinesrecords.length; i++) {
            var quoteLine = quoteLinesrecords[i];
            if(quoteLine.Product_Level__c == 'OnPrem' && quoteLine.SBQQ__Product__r.X0__c == false && quoteLine.Product_Subtype__c != 'LOD Addon'
                    && quoteLine.Product_Type__c != 'PMC' && quoteLine.SBQQ__Optional__c ==false)
            {
                                if(RSCPExistingUser == true){  //Existing RSCP customer
                                    if(quote.RWD_Eligible_LA_DA_Products_RSCP__c == false){
                                    showalert = true;
                                    break;  
                                    }  
                                }
                                else //new RSCP customer
                                {
                                    if(quote.RWD_Eligible_LA_DA_Products_RSCP__c == false){
                                    showalert = true;
                                    break;  
                                    }
                                    /*else  //Rubrik Light Administrator=00e1W000000zKYuQAM,Deal Operations=00e6f000001J04d
                                    {
                                        if(ProfileName!='Rubrik Light Administrator' && ProfileName!='Deal Operations' && (quoteLine.Product_Type__c=='Business Edition' || quoteLine.Product_Type__c=='Enterprise Edition')){
                                        errorMessage='Non-FED Accounts can only quote FE RSCP products, to quote BE/EE please contact deal ops.';
                showalert = true;
                break;  
                }
                }Commented as part of CPQ22-6262 */
                }
            }
                            }
                        }
                if(showalert){
                    isVerified = false;
                    component.set("v.content",errorMessage);
                    }
            }
            }//end
                
            //MS CPQ22-3092 Starts 
        var trdUpSN = component.get("v.quoteRec").Trade_Up_Serial_Numbers__c; 
        if(isVerified && trdUpSN) { 
            var action = component.get('c.checkInvalidTradeUp'); 
            component.set("v.showGenericSpinner", true); 
            console.log('Inside invalidate check function'); 
            var errmsg; 
            action.setParams({ 
                "strgOfAssets" : component.get("v.quoteRec").Trade_Up_Serial_Numbers__c 
            }); 
            action.setCallback(this,function(response){ 
                if(response.getReturnValue()!= null){ 
                    errmsg = response.getReturnValue();  
                    console.log('errmsg>> '+errmsg); 
                    isVerified = false; 
                    component.set("v.showGenericSpinner", false); 
                    component.set("v.content",response.getReturnValue()); //MS PopUp Message 
                    //component.set("v.inValidate",true); //MS PopUp Message 
                } 
            }); 
            component.set("v.showGenericSpinner", false);//Khushboo 
            console.log('MS TradeUp MSg >>'+component.get("v.content")); 
            if(errmsg != null && errmsg != ''){ 
                isVerified = false; 
                console.log('MS TradeUp MSg >>'+component.get("v.content")); 
                console.log('MS TradeUp isVerified >>'+isVerified); 
            } 
            console.log('MS TradeUp isVerified outside if >>'+isVerified); 
            $A.enqueueAction(action); 
        } 
        //MS CPQ22-3092 Ends 
	    
        
        //MS CPQ22-6091 Starts
	    if(isVerified){
            var action = component.get('c.quoteValidateAPI');

            var valMsg;
             action.setParams({
                 quoteId: quote.Id
			});               
            action.setCallback(this,function(response){
                if(response.getReturnValue() != null){
                    valMsg = response.getReturnValue(); 
                    component.set("v.content",response.getReturnValue());
                    isVerified = false;
                }
            });

            $A.enqueueAction(action);
            if(valMsg!= null && valMsg!= '' ){
                isVerified = false;
            }
        }
        //MS CPQ22-6091 Ends
	    
      //CPQ22-3866 End
        if(isVerified) {
            var quoteLinesrecords = quotelinequeryresult;
            if(quote.ApprovalStatus__c == 'Pending' || quote.ApprovalStatus__c == 'Approved') {
                component.set("v.content","You cannot submit Approved/Pending Quote");
                //alert('You cannot submit Approved/Pending Quote');
               
            }
            else {
                //GLCR-82 - Start - Commented As per business confirmation
                /*var dJust = escape(quote.Discount_Justification__c);
                var dFlBrched =quote.Discount_Floor_Breached__c;
                if(dFlBrched > 0 && (dJust == undefined || dJust == 'undefined' || dJust.length <= 0)) {
                    component.set("v.content","Please provide Business Justification");
                    //alert("Please provide Business Justification");
                }
                else {*/
                //GLCR-82 - End - Commented As per business confirmation
                    var accRecds = component.get("v.accRecds");
                    if(accRecds[0] && accRecds[0].EULA_revision_Required__c == true && quote.Is_Refreshed_Identifier__c) {
                        component.set("v.content","Legal amendment needed. Please reach out to the legal team for more information");
                        //alert(" Legal amendment needed. Please reach out to the legal team for more information");
                    }else if (component.get("v.content") == '') {
                        var quoterecord = [];
                        var action=component.get('c.getQuoteRecord');
                        action.setParams({
                            QuoteId:quote.Id,
                        })
				        action.setCallback(this,function(response){
				        var responseValue=response.getReturnValue();
            			console.log('##responseValue',responseValue);
                        // component.set("v.quoteList",responseValue);     
                        quoterecord = responseValue;
                        console.log('##quoterecord',quoterecord);
                        if(quoterecord[0]['SBQQ__Uncalculated__c']){
                            
                           component.set("v.content",$A.get("$Label.c.Recalculation_Message"));
                            
                        }else{
                            console.log('isVerified submit'+isVerified);
                                if(isVerified){
                                    isVerified = helper.showAlertMsg(component, event, helper, isVerified, quote, quoteLinesrecords, cliRcrds);
                                }
                            if(isVerified){
                                console.log('ProcessCalled');
								debugger;
                                
                                ////CPQ22-5846 starts
                                //helper.processExceptions(component,true)
                                let alertExceptionMessage = component.get("v.alertExceptionMessage");
                                if(Array.isArray(alertExceptionMessage) && alertExceptionMessage.length > 0){
                                    alertExceptionMessage=alertExceptionMessage.join(';')
                                }else{
                                    alertExceptionMessage="";
                                    this.updateExceptionsOnQuote(component,alertExceptionMessage)
                        .then(function() {
                                        console.log('A');alertExceptionMessage
                            helper.submitQuoteRec(component, event, helper,approveQuote);
                                        console.log('B');
                       })
                        .catch(function(error) {
                            console.error(error);
                        });
                            }
                                //CPQ22-5846 Ends
                                
                            }
                        }
                       	},'SUCCESS');
                        $A.enqueueAction(action);
                        //helper.gotoURL(component, "/apex/SubmitQuote?Id="+quote.Id);
                        // window.location = "/apex/SubmitQuote?Id="+quote.Id;
                    }
                //} GLCR-82 - Commented As per business confirmation. part of above commented else block
            }
        }
        //Added for Arroyo-Starts
        if(isVerified && !(quote.RWD_Sales_Rep_Exception__c != null && quote.RWD_Sales_Rep_Exception__c.includes('25% Premium RSC-G Replacement'))) {
            if(quote.SBQQ__Type__c == 'Renewal+Expansion' || quote.SBQQ__Type__c == 'Renewal')
            {
                console.log('**Ary**');
                var action=component.get('c.callArroyoQueuableMethod');
                action.setParams({QuoteId:quote.Id})
                $A.enqueueAction(action);
            }
        }

        //CPQ22-2840 validate Sales Comp Category
        if (isVerified){
            let errorMessage;
            for (let quoteLine of quotelinequeryresult){
                if (quoteLine.SBQQ__Product__r.Sales_Comp_Category__c && quoteLine.SBQQ__Product__r.Sales_Comp_Category__c != quoteLine.Sales_Comp_Category__c){
                    errorMessage = $A.get("$Label.c.Error_SCC_Mismatch");
                    break;
                }
                else if(!quoteLine.Wrapper_Line__c && (quoteLine.Quote_Line_Type__c == 'New' || quoteLine.Quote_Line_Type__c == 'Renewal') 
                    && !quoteLine.SBQQ__Product__r.Sales_Comp_Category__c && quoteLine.SBQQ__Product__r.Product_Master_Id__c){
                    errorMessage = $A.get("$Label.c.Error_SCC_Missing");
                    break;
                }
            }
            if (errorMessage){
                isVerified = false;
                component.set("v.content", errorMessage);
            }
        }
        if (isVerified) {
            let errorMessage;
            for (let quoteLine of quotelinequeryresult) {
                if (
                     (quote.SBQQ__Type__c === "Quote" ||
                     (quote.SBQQ__Type__c === "Renewal+Expansion" && 
                      (quoteLine.Quote_Line_Type__c === "New" || 
                       (quoteLine.Quote_Line_Type__c === "Renewal" && quoteLine.SBQQ__Quantity__c > 0 &&
                        (!["Disposition Quote", "Do NOT Show on DOC"].includes(quoteLine.QuoteLine_Group_Name__c) || 
                         quoteLine.SBQQ__Optional__c !== true)))) ||
                     (quote.SBQQ__Type__c === "Renewal" && quoteLine.Quote_Line_Type__c === "Renewal" && quoteLine.SBQQ__Quantity__c > 0) ||
                     (quote.SBQQ__Type__c === "Amendment" && quoteLine.Quote_Line_Type__c === "New"))
                    &&(quoteLine.Product_Level__c == null && quoteLine.Wrapper_Line__c == false)
                ) {
                    errorMessage = $A.get("$Label.c.V1_Sku_Error");
                    break;
                }
            }
                if (errorMessage){
                    isVerified = false;
                    component.set("v.content", errorMessage);
                }
        }
    },
    
    submitQuoteRec : function(component, event, helper, approveQuote) {
        try{
		var action = component.get("c.onSubmitLtng");
        var quote = component.get("v.quoteRec");
        component.set("v.showGenericSpinner", true);
        action.setParams({
            "quote": quote,
            "markApproved": approveQuote
        });
        action.setCallback(this, function(response){
            console.log(response.getState());
            console.log(response.getReturnValue());
            if (response.getState() === "ERROR") {
                component.set("v.showGenericSpinner", false);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && ( errors[0].message || errors[0].pageErrors)) {
                        component.set("v.content",errors[0].message + errors[0].pageErrors);
                    	//helper.showToast(component, event, helper, errors[0].message + errors[0].pageErrors , 'error');
                    }
                    return;
                }
            }
            var response = response.getReturnValue();
            //If block for SF-28881
            if(response == "calculation in progress"){
                component.set("v.showGenericSpinner", false);
                component.set("v.content",$A.get("$Label.c.Recalculation_Message"));
                
                return;
            }
            else{
            if(response == "" )
                helper.refreshFocusedTab(component, event, helper)
            else
                component.set("v.content",response);
            
            component.set("v.showGenericSpinner", false);
            }
        });
        $A.enqueueAction(action);
    }
      catch(e) {
    console.error('Error in evalLogic:', e.message);
    console.error(e.stack);    
    console.log({ expr, condMap });
    return false;
  }
                        
	},
    refreshFocusedTab : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.refreshTab({
                      tabId: focusedTabId,
                      includeAllSubtabs: true
             });
        })
        .catch(function(error) {
            location.reload();
            console.log(error);
        });
    },
    //FY25SR-1745-start
    getLUDets : function(component, event, helper) {
        var action = component.get('c.getLowerAndUpperBound');
        var lb;
        var ub;
		action.setCallback(this,function(response){
            if(response.getState() === "SUCCESS" && response.getReturnValue()!= null){
                lb = response.getReturnValue().LowerBoundM__c;
                ub = response.getReturnValue().UpperBoundM__c;
                component.set("v.lowerBound", lb);
                component.set("v.upperBound", ub);
            }
        });
        $A.enqueueAction(action);
    },
    //FY25SR-1745-Ends
    executeQuery : function(component, event, helper, query, attributeName) {
		
        //FY26WL-230 call non cacheable method for quote and quoteline queries
        var action;
        if (attributeName == 'quoteRec' || attributeName == 'quoteLineItemsRecds'){
            action = component.get("c.executeQueryNew");
        }
        else {
            action = component.get("c.executeQuery");
        }
        
        action.setParams({
            "theQuery": query
        });
        
        action.setCallback(this, function(response) {
            
            var state = response.getState();
            
            if(state == "SUCCESS" && component.isValid()){
                var queryResult = response.getReturnValue();
                //FY25SR-1745 Starts
                var lb = component.get("v.lowerBound");
                var ub = component.get("v.upperBound");
                if (lb == undefined || ub == undefined) {
                    helper.getLUDets(component, event, helper);
                }
                console.log('Dates--',lb,'--',ub);
                //FY25SR-1745 Ends
                if(attributeName == 'quoteRec'){
                    component.set("v."+attributeName, queryResult[0]);
                    var accQuery = "Select Id,EULA_revision_Required__c from Account where Id =\'"+ component.get("v.quoteRec").SBQQ__Account__c + '\'';
         			helper.executeQuery(component, event, helper, accQuery, 'accRecds');
                }
                else{
                    component.set("v."+attributeName, queryResult);
                }
                
                if(attributeName == 'accRecds'){
				var quote = component.get("v.quoteRec");
                //FY25SR-1216 && FY25SR-1076 - start
				var cpqDispositionQuery = 'SELECT Id, Arroyo_Subsumed_Old_Contract_Line_Items__c, Disposition_Reason__c, Quantity__c, Replacement_Detail__c, RenewedContractLine__c from CPQ_Disposition_Quote_Line__c WHERE Quote__c =\'' +quote.Id +'\'';				
                helper.executeQuery(component, event, helper, cpqDispositionQuery, 'cpqDispositionQLs');
                //FY25SR-1216 && FY25SR-1076 - end
				var quoteAccount = component.get("v.quoteRec").SBQQ__Account__c;
				var itProdTypeNew = ('V1 RCDM', 'V1 RCDM Support');
				var orderType = 'POC';
				var orderSubType = 'POC';
				var entitlementProductName = 'Evaluation';
                //FY25SR-1216 && FY25SR-1076 - start
                var today = new Date();
                var quoteDate = new Date(quote.CreatedDate); // Get current date
                // Convert the date to a string in ISO format (which includes time info)
                var last_three_months = quoteDate.setMonth(quoteDate.getMonth() - lb); // Subtract 3 months - FY25SR-1745 Changed to metadata
                var last_90_days =  parseInt((today - last_three_months)/(1000 * 3600 * 24));
                component.set('v.last_90_days',last_90_days);
                var quoteDate2 = new Date(quote.CreatedDate); // Get current date
                var next_twelve_months = quoteDate2.setMonth(quoteDate2.getMonth() + ub); // FY25SR-1745 Changed to metadata 
                var next_365_days =  parseInt((next_twelve_months - today)/(1000 * 3600 * 24));
                component.set('v.next_365_days',next_365_days);
                let entitlementFields = ['Product__r.Replacement_Category__c', 'Entitlement_Status__c', 'Renewal_Category__c', 'ContractLineItem.SBQQSC__RenewalQuantity__c', 'Status', 'ServiceContractId', 'ServiceContract.GPL_Deal__c', 'ServiceContract.SBQQSC__Quote__c','ServiceContract.SBQQSC__Opportunity__c', 'ServiceContract.SBQQSC__Opportunity__r.Opportunity_Sub_Type__c', 'ServiceContract.SBQQSC__Quote__r.Is_Scale_Utility_Quote__c', 'ContractLineItem.Licensing_Model__c', 'Product__r.SBQQ__SubscriptionType__c' , 'Order_Service_Item__r.OrderId'];
                //FY25SR-1216 && FY25SR-1076 - end && FY25SR-2298
				var entitlementQuery = 'SELECT Id, AccountId, Product__c, Order_Service_Item__c, Product__r.productcode, Product__r.Ipt__c, Type, Order_Service_Item__r.Order.Type, Order_Service_Item__r.Order.Order_Sub_Type__c, Name, ContractLineItemId, EndDate, ' + entitlementFields.join(',')
                    + ' ,(Select id, Renewed_Entitlement__r.EndDate,Renewed_Entitlement__r.Renewal_Category__c,Renewed_Entitlement__r.Status from Entitlement_Links__r where Renewed_Entitlement__r.Status =\'Inactive\' and Previous_Entitlement__r.Status =\'Active\')'   
                    + ' From Entitlement WHERE AccountId =\'' 
                    + component.get("v.quoteRec").SBQQ__Account__c
                    + '\' AND (((Product__r.Ipt__c = \'V1 RCDM\' OR Product__r.Ipt__c = \'V1 RCDM Support\') AND Type != \'Evaluation\' AND Type != \'RSC\' AND Order_Service_Item__r.Order.Type != \''
                    + orderType+'\' AND Order_Service_Item__r.Order.Order_Sub_Type__c != \''
                    + orderSubType+'\' AND (NOT Name like \'%'+entitlementProductName+ '%\')) OR (EndDate >= LAST_N_DAYS:'+last_90_days
                    + ' AND EndDate <= NEXT_N_DAYS:'+next_365_days +'))';				
                    console.log('entitlementQuery ',entitlementQuery);
				helper.executeQuery(component, event, helper, entitlementQuery, 'entitlementRecords');
                }
                
                if(attributeName == 'entitlementRecords'){
					helper.processData(component, event, helper); 
                }
            } 
            else{ 
                console.error("fail:" + response.getError()[0].message); 
                var toastEvent = $A.get("e.force:showToast");
    		toastEvent.setParams({
        		"title": "Error",
                        "duration": 10000,
                        "type": "error",
        		"message": "Something went wrong in your org: " + response.getError()[0].message
    		});
    		toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
            }
        });
        $A.enqueueAction(action);
    },
    //CPQ22-4863
    showAlertMsg : function(component, event, helper, isVerified, quote, quoteLinesrecords, CLIRecords) {
        // debugger;
        if(isVerified) {
            let errorMessages = [];
            var isActive_PAC_CLI = false;
            var isExprining_PAC_CLI = false;
            var isActive_CEM_CLI = false;
            var isExprining_CEM_CLI = false;
            var isActive_CES_CLI = false;
            var isExprining_CES_CLI = false;
            var quote_Threshold = 0;
            var isExistingRSCCustomer = false;
            var hasRSCSkuinQuote = false;
            var isICP_ICR_sku = false;
            if(quote.SBQQ__NetAmount__c != null && quote.SBQQ__SubscriptionTerm__c != null) {
                quote_Threshold = (quote.SBQQ__NetAmount__c/quote.SBQQ__SubscriptionTerm__c)*12;
            }
            if(CLIRecords) {
                for(let cli of CLIRecords) {
                    if(cli.Status_Product_Code__c) {
                    if(cli.Status_Product_Code__c.includes('Expiring') 
                        && (cli.Status_Product_Code__c == 'Expiring-RA-PAC-PP' || cli.Status_Product_Code__c == 'Expiring-RA-PAC-PA'
                        || cli.Status_Product_Code__c.includes('RBK-SVC-PROACTIVE') || cli.Status_Product_Code__c.includes('RBK-SVC-ENTERPRISE'))
                    ) {
                            isExprining_PAC_CLI = true;
                        }
                    if(cli.Status_Product_Code__c.includes('ACTIVE') 
                        && (cli.Status_Product_Code__c == 'ACTIVE-RA-PAC-PP' || cli.Status_Product_Code__c == 'ACTIVE-RA-PAC-PA'
                        || cli.Status_Product_Code__c.includes('RBK-SVC-PROACTIVE') || cli.Status_Product_Code__c.includes('RBK-SVC-ENTERPRISE'))) {
                            isActive_PAC_CLI = true;
                        }
                    if(cli.Status_Product_Code__c.includes('Expiring') 
                        && (cli.Status_Product_Code__c == 'Expiring-RA-CEM-PA' || cli.Status_Product_Code__c == 'Expiring-RA-CEM-PP'
                     || cli.Status_Product_Code__c.includes('RBK-SVC-CEM'))) {
                            isExprining_CEM_CLI = true;
                        }
                    if(cli.Status_Product_Code__c.includes('ACTIVE')
                        && (cli.Status_Product_Code__c == 'ACTIVE-RA-CEM-PA' || cli.Status_Product_Code__c == 'ACTIVE-RA-CEM-PP'
                    || cli.Status_Product_Code__c.includes('RBK-SVC-CEM'))) {
                          isActive_CEM_CLI = true;
                    }
                    if(cli.Status_Product_Code__c == 'Expiring-RA-CES-PA' || cli.Status_Product_Code__c == 'Expiring-RA-CES-PP') {
                        isExprining_CES_CLI = true;
                    }
                    if(cli.Status_Product_Code__c == 'ACTIVE-RA-CES-PA' || cli.Status_Product_Code__c == 'ACTIVE-RA-CES-PP') {
                        isActive_CES_CLI = true;
                    }
                    //ITNPI-1696
                    if(cli.Status == 'Active' && 
                        (cli.Family_and_ProductLevel__c == 'Rubrik LicenceHybrid Software' || cli.Family_and_ProductLevel__c == 'Rubrik ScaleHybrid Software' || 
                         cli.Family_and_ProductLevel__c == 'Third Party LicenseHybrid Software' || cli.Family_and_ProductLevel__c == 'Third Party LicenseOnPrem' ||
                         cli.Family_and_ProductLevel__c == 'Rubrik LicenceOnPrem' || cli.Status_Product_Code__c.includes('EDG') || cli.Type_of_Entitlement__c == 'GO'
                        )
                    ){
                        isExistingRSCCustomer = true;

                    }
            }
            }
            }
            
            if((isExprining_PAC_CLI || (quote.QuoteApprovalCategory__c != null && quote.QuoteApprovalCategory__c.includes('PAC'))) && quote_Threshold > 2000000 && isActive_PAC_CLI == false) {
                errorMessages.push($A.get("$Label.c.PAC_Deal_Size_Alert_Msg"));
                component.set("v.alertMessage", errorMessages);
                component.set("v.isApproval", true);
                isVerified = false;
            }
            if((isExprining_CEM_CLI || (quote.QuoteApprovalCategory__c != null && quote.QuoteApprovalCategory__c.includes('CEM'))) && quote_Threshold <= 2000000 && quote_Threshold > 1000000 && isActive_CEM_CLI == false) {
                errorMessages.push($A.get("$Label.c.CEM_deal_size_alert_Msg"));
                component.set("v.alertMessage", errorMessages);
                component.set("v.isApproval", true);
                isVerified = false;
            }
            if((isExprining_CES_CLI || (quote.QuoteApprovalCategory__c != null &&  quote.QuoteApprovalCategory__c.includes('CES'))) && quote_Threshold <= 1000000 && quote_Threshold > 500000 && isActive_CES_CLI == false) {
                errorMessages.push($A.get("$Label.c.CES_Deal_size_alert_Msg"));
                component.set("v.alertMessage", errorMessages);
                component.set("v.isApproval", true);
                isVerified = false;
            }
            //CPQ22-4796 PS Quote recommendations
            if (quoteLinesrecords){
                let errorMap = {};
				let isRSCP= false;
				let isRSC= false;
				let isFE_BE = false;
				let isEE_EPE = false;
				let isNCD= false;
				let isM365= false;
				let isUCL= false;
				let isSoftwareSKU= false;
				var totalACVQLs = 0;
				var totalExpACVQLs = 0;
                let isTPH = false; // CPQ22-5297
                
                for (let qli of quoteLinesrecords){
                    if (qli.Quote_Line_Type__c == 'New'){
                        totalACVQLs += qli.ACV__c == undefined ? 0 : Number(qli.ACV__c);					
                        totalExpACVQLs += qli.ExpACV__c ==  undefined ? 0 : Number(qli.ExpACV__c);	
                        isRSCP   =  qli.Product_Level__c == 'OnPrem' && qli.SBQQ__Product__r.Bundle_Features__c && qli.SBQQ__Product__r.Bundle_Features__c.includes('OnPrem CDM');
                        isRSC    =  qli.Product_Level__c == 'Hybrid Software' && qli.SBQQ__Product__r.Bundle_Features__c && qli.SBQQ__Product__r.Bundle_Features__c.includes('Hybrid RCDM');
                        isFE_BE  =  isFE_BE == true ?  isFE_BE : (isRSCP || isRSC) && (qli.Edition__c == 'Foundation Edition' || qli.Edition__c == 'Business Edition');
                        isEE_EPE =  isEE_EPE == true ? isEE_EPE : (isRSCP || isRSC) && (qli.Edition__c == 'Enterprise Edition' || qli.Edition__c == 'Proactive Edition');
                        isNCD    =  isNCD == true ? isNCD : qli.Product_Level__c && qli.Product_Type__c == 'NAS Cloud Direct';
                        isM365   =  isM365 == true ? isM365 : qli.Product_Level__c && ['M365H', 'Hybrid M365H', 'M365' , 'FED M365', 'Hybrid M365'].includes(qli.Product_Type__c);
                        isUCL    = isUCL == true ? isUCL : qli.Product_Level__c && qli.Product_Type__c == 'UCL';
                    isTPH = isTPH == true ? isTPH : qli.Product_Level__c && qli.SBQQ__ProductFamily__c == 'Third Party License' && qli.SBQQ__Product__r.Bundle_Features__c && (qli.SBQQ__Product__r.Bundle_Features__c.includes('Hybrid RCDM') ||  qli.SBQQ__Product__r.Bundle_Features__c.includes('OnPrem CDM'));//CPQ22-5297
					
                        isSoftwareSKU = isSoftwareSKU == true ? isSoftwareSKU : ['OnPrem','Hybrid Software','SaaS Software Addon','Standalone Software Addon'].includes(qli.Product_Level__c);
                    }
                    isICP_ICR_sku = isICP_ICR_sku == true ? isICP_ICR_sku : qli.Product_Type__c == 'Identity Cyber posture' || qli.Product_Type__c == 'Identity Cyber recovery';
                    if(qli.Family_And_PL_and_Not_Disposed__c == 'Rubrik LicenceHybrid Software' || qli.Family_And_PL_and_Not_Disposed__c == 'Rubrik ScaleHybrid Software' ||
                       qli.Family_And_PL_and_Not_Disposed__c == 'Third Party LicenseHybrid Software' || qli.Family_And_PL_and_Not_Disposed__c == 'Rubrik LicenceOnPrem' || 
                       qli.Family_And_PL_and_Not_Disposed__c =='Third Party LicenseOnPrem' || qli.SBQQ__ProductCode__c.includes('EDG')
                    ){
                        hasRSCSkuinQuote = true;
                    }
                }
                 //Suggest Accelerators for non-Majors/non-strategic deals under 75k ACV
                 
                 if (((quote.SBQQ__Type__c == 'Quote' && totalACVQLs < 75000) || (quote.SBQQ__Type__c == 'Renewal+Expansion' && totalExpACVQLs < 75000)) && (!quote.ETM_Area__c || !quote.ETM_Area__c.toLowerCase().includes('strategic'))){
                    if (isEE_EPE && !errorMap[0]){
                        let err = $A.get("$Label.c.PS_Alert_1");
                        errorMessages = errorMessages.concat(err.split(';'));
                        errorMap[0] = true;
                    }
                    else if (isFE_BE && !errorMap[1]){
                        let err = $A.get("$Label.c.PS_Alert_2");
                        errorMessages = errorMessages.concat(err.split(';'));
                        errorMap[1] = true;
                    }
                    if (isNCD && !errorMap[2]){
                        let err = $A.get("$Label.c.PS_Alert_3");
                        errorMessages.push(err);
                        errorMap[2] = true;
                    }
                    if (isM365 && !errorMap[3]){
                        let err = $A.get("$Label.c.PS_Alert_4");
                        errorMessages.push(err);
                        errorMap[3] = true;
                    }
                    if (isUCL && !errorMap[4]){
                        let err = $A.get("$Label.c.PS_Alert_5");
                        errorMessages.push(err);
                        errorMap[4] = true;
                    }
                }
                
                //Suggest Healthcheck / EE Accelerator for existing customer expansions
                if (quote.Opportunity_Type__c == 'Existing Customer' && (!quote.ETM_Area__c || !quote.ETM_Area__c.toLowerCase().includes('strategic')) && ['Quote', 'Renewal+Expansion'].includes(quote.SBQQ__Type__c)
                    && (isFE_BE || isEE_EPE || isUCL) && !errorMap[5]){
                    let err = $A.get("$Label.c.PS_Alert_6");
                    errorMessages = errorMessages.concat(err.split(';'));
                    errorMap[5] = true;
                }
                
                //Suggest Consulting be 10%+ of ACV for all new deals over 75k
                if (quote.Opportunity_Type__c == 'New Customer' && totalACVQLs > 75000 && quote.SBQQ__Type__c == 'Quote'){
                    if ((isFE_BE || isEE_EPE) && !errorMap[6]){
                        let err = $A.get("$Label.c.PS_Alert_7");
                        errorMessages.push(err);
                        errorMap[6] = true;
                    }
                    if (isM365 && !errorMap[7]){
                        let err = $A.get("$Label.c.PS_Alert_8");
                        errorMessages.push(err);
                        errorMap[7] = true;
                    }
                    if (isSoftwareSKU && !errorMap[8]){
                        let err = $A.get("$Label.c.PS_Alert_9");
                        errorMessages = errorMessages.concat(err.split(';'));
                        errorMap[8] = true;
                    }
                }
                //CPQ22-5297 Custom Alert for TPH deals
				if(isTPH && !errorMap[9]) {
                     let err = $A.get("$Label.c.TPH_Custom_Alert");
					 errorMessages.push(err);
                     errorMap[9] = true;
				} // Ends CPQ22-5297

                if (errorMessages.length){
                    isVerified = false;
                    component.set("v.alertMessage", errorMessages);
                	component.set("v.isApproval", true);
                }
            }
            if(isExistingRSCCustomer == false && hasRSCSkuinQuote == false && isICP_ICR_sku == true) {
                component.set("v.alertMessage", errorMessages);
                component.set("v.isApproval", true);
                isVerified = false;
            }
        }
        let alertExceptionMessage = component.get("v.alertExceptionMessage");
        if(Array.isArray(alertExceptionMessage) && alertExceptionMessage.length > 0){
			component.set("v.isApproval", true);
		}
        return isVerified;
    },
    //FY25SR-1216 && FY25SR-1076
    addDays:function(date, days) {
        const newDate = new Date(date);
        newDate.setDate(date.getDate() + days);
        return newDate;
    },
    //FYSR25-1460 //CPQ22-6026
    handleBusinesLogicSetting : function(component, event, helper){
        var action = component.get("c.getBusinessLogicSetting");
        console.log('assign hasAccess111 ');
        action.setCallback(this, function(response){
            var state = response.getState();
            var userSetting = response.getReturnValue();
            if(state == "SUCCESS" ) {
                if(userSetting['Replacement'] == true){
                    component.set("v.showSMSPage", false);
                }else{
                    component.set("v.showSMSPage", true);
                }
                if(userSetting['OpportunityValidation'] == true){
                    component.set("v.disableOppValid", true);
                }else{
                    component.set("v.disableOppValid", false);
                }
            }else {
                console.log("Failed with state: ", state);
            }
        });
        $A.enqueueAction(action);
    },
    //CPQ22-6026
	// CPQ22-5801
  processExceptions: function(component, isUpdate) {
        return new Promise((resolve, reject) => {
        try {
        var quote           = component.get("v.quoteRec")               || {};
        var lines           = component.get("v.quoteLineItemsRecds") || [];
        var assets           = component.get("v.assetRecords") || [];
            var condRecs = component.get("v.ruleConditions") || []; // each record is one product-rule record
        var excpvaluesarray = [];

            // Build maps: ruleLogic[rn] => logic string, ruleConds[rn] => array of condition objects,
            // exceptionsMap[rn] => exception string
            var ruleLogic = {}, ruleConds = {}, exceptionsMap = {};

            // 1) Parse rule JSONs and SV JSONs from condRecs; merge SV defs across all rules
            var mergedSVDefs = [];
        condRecs.forEach(function(r) {
                // Parse Rule JSON safely (wrapper object containing RBRKLogic__c, Conditions, etc.)
                var ruleJson = null;
                if (r.RuleJSON__c) {
                    try {
                        ruleJson = JSON.parse(r.RuleJSON__c);
                    } catch (e) {
                        // fallback to using fields directly if JSON is malformed
                        console.warn('Failed to parse RuleJSON__c for rule:', r.RBRKRuleName__c, e);
                        ruleJson = null;
                    }
                }

                // Rule name - prefer JSON authoritative name if present, else use record field
                var rn = (ruleJson && ruleJson.RBRKRuleName__c) ? ruleJson.RBRKRuleName__c : (r.RBRKRuleName__c || 'Unknown Rule');

                // Logic - prefer JSON, then record field, then empty
                ruleLogic[rn] = (ruleJson && ruleJson.RBRKLogic__c) ? ruleJson.RBRKLogic__c : (r.RBRKLogic__c || '');

                // Exceptions - prefer JSON, then record field, else empty
                exceptionsMap[rn] = (ruleJson && ruleJson.RBRKQuoteExceptions__c) ? ruleJson.RBRKQuoteExceptions__c : (r.RBRKQuoteExceptions__c || '');

                // Conditions array - prefer JSON.Conditions if array, else try to build from record-level fields (compat)
                var condArray = [];
                if (ruleJson && Array.isArray(ruleJson.Conditions)) {
                    condArray = ruleJson.Conditions;
                } else {
                    // If old shape (each cond was a separate SObject row) then condRecs may already be condition-level,
                    // but in your new design each condRecs is a rule-level record. So when no JSON present, fallback:
                    // try to get condition fields from the record itself as single condition
                    if (r.RBRKIndex__c || r.RBRKTestedObject__c || r.RBRKTestedField__c || r.RBRKTestVariable__c) {
                        condArray = [{
                            'RBRKIndex__c': r.RBRKIndex__c,
                            'RBRKTestedObject__c': r.RBRKTestedObject__c,
                            'RBRKTestedField__c': r.RBRKTestedField__c,
                            'RBRKTestVariable__c': r.RBRKTestVariable__c,
                            'VariableName__c': r.VariableName__c,
                            'RBRKFilterType__c': r.RBRKFilterType__c,
                            'RBRKFilterValue__c': r.RBRKFilterValue__c,
                            'RBRKOperator__c': r.RBRKOperator__c
                        }];
                    } else {
                        condArray = [];
                    }
                }

                ruleConds[rn] = condArray;

                // Merge SV JSON defs for buildSummaryVars
                if (r.RuleSVJSON__c) {
                    try {
                        var svArr = JSON.parse(r.RuleSVJSON__c);
                        if (Array.isArray(svArr) && svArr.length > 0) {
                            // push all SV defs (they should be objects with fields your buildSummaryVars expects)
                            mergedSVDefs.push.apply(mergedSVDefs, svArr);
                        }
                    } catch (e) {
                        console.warn('Failed to parse RuleSVJSON__c for rule:', rn, e);
                    }
                }
        });
  
            // 2) Compute all summary variables once using merged defs
            // If no defs found, mergedSVDefs will be [] and buildSummaryVars should return {}
            var summaryVars = this.buildSummaryVars(quote, lines, mergedSVDefs, assets);
            console.log('Merged SV defs count:', mergedSVDefs.length, ' summaryVars:', summaryVars);

            // 3) Iterate rules (ruleLogic keys) and evaluate
        for (const ruleIx in ruleLogic) {
                const logicStr = ruleLogic[ruleIx] || '';
                const condList = ruleConds[ruleIx] || [];
                const exceptionsStr = exceptionsMap[ruleIx] || '';
          let ruleFires  = false;
        
                // If there are no conditions for this rule, skip
                if (!Array.isArray(condList) || condList.length === 0) {
                    continue;
                }

                // Evaluate condition set for each quote line (and assets if considered as lines combined earlier)
          for (let i = 0; i < lines.length; i++) {
            const qli = lines[i];
        
                    // build this line’s condition-match map (keys: "1","2","3", ...)
            const condMatchesForLine = {};

                condList.forEach((c) => {
                    if (!c) return;

                    // RBRK index must exist
                    const idxKey = c.RBRKIndex__c != null
                        ? String(c.RBRKIndex__c)   // logic expressions are string-based
                        : null;

                    if (!idxKey) {
                        console.warn('Condition missing RBRKIndex__c', c);
                        return;
                    }

                    try {
                        condMatchesForLine[idxKey] =
                            this.evalLeaf(c, qli, summaryVars, quote);
                    } catch (e) {
                        console.error(
                            'Error evaluating leaf for rule:',
                            ruleIx,
                            'RBRKIndex__c:',
                            idxKey,
                            e
                        );
                        condMatchesForLine[idxKey] = false;
                    }
                });


                    console.log('ruleIx', ruleIx, 'condMatchesForLine', condMatchesForLine);

                    // evaluate global boolean expression for this line
                    let linePasses = false;
                    try {
                        linePasses = this.evalGlobal(logicStr, condMatchesForLine);
                    } catch (e) {
                        console.error('Error evaluating global logic for rule:', ruleIx, logicStr, e);
                        linePasses = false;
                    }

            if (linePasses) {
              ruleFires = true;
                        break; // no need to check other lines for this rule
            }
          }
        
                if (ruleFires && exceptionsStr) {
                    // add exception value only if not already present
                    if (!excpvaluesarray.includes(exceptionsStr)) {
                        excpvaluesarray.push(exceptionsStr);
          }
        }
            }

            // existing extra checks (Trade Up and Scale Utility) — preserved as-is
            lines.forEach(function(Item) {
                try {
                    if (Item.SBQQ__Product__r && Item.SBQQ__Product__r.Tradeup_Pattern__c && Item.Trade_Up_Discount__c != null &&
                        typeof Item.SBQQ__Product__r.Tradeup_Pattern__c === 'string' &&
                        Item.SBQQ__Product__r.Tradeup_Pattern__c.includes('Sales Rep Exception')) {
                        if (!excpvaluesarray.includes('Trade Up - FE - Exceptions')) {
                        excpvaluesarray.push('Trade Up - FE - Exceptions');
                    }
                    }
                } catch (e) {
                    console.warn('Error in trade-up check for line', Item, e);
                }

                try {
            if (Item.Product_Payment_Option__c !== 'Monthly' &&
      (
        Item.Scale_Utility_Product_Identifier__c === 'M365 RSV SU' ||
        Item.Scale_Utility_Product_RSV_OND__c === 'RSV' ||
        Item.Scale_Utility_Product_Identifier__c === 'SU FUE' ||
        Item.Scale_Utility_Product_Identifier__c === 'SU FUP' ||
        Item.Scale_Utility_Product_Identifier__c === 'SU EUP' ||
        Item.Scale_Utility_Product_Identifier__c === 'SU FUB' ||
        Item.Scale_Utility_Product_Identifier__c === 'SU BUE' ||
        Item.Scale_Utility_Product_Identifier__c === 'SU BUP' ||
        Item.Scale_Utility_Product_Identifier__c === 'SU FUC' ||
        Item.Scale_Utility_Product_Identifier__c === 'SU EUC' ||
        Item.Scale_Utility_Product_Identifier__c === 'SU PUD' ||
        Item.Scale_Utility_Product_Identifier__c === 'SU RUP'
      )
    	) {
                var val = 'Scale Utility Payment Option Exception';
       if (!excpvaluesarray.includes(val)) excpvaluesarray.push(val);
                    }
			if((Item.SBQQ__ProductCode__c ==='RA-PS-RINT') && Item.SBQQ__Quantity__c != quote.Count_of_Rubrik_Install_For_THP__c && quote.Count_of_Rubrik_Install_For_THP__c>0){
            var val2 = 'Quantity Exception - PS Imaging';
       if (!excpvaluesarray.includes(val2)) excpvaluesarray.push(val2);
        }
        if (quote.SBQQ__Type__c === 'Quote' && Item.Line_Type__c === 'New') {
        let subsAssetNames = [];
        if (Item.SubscribedAssetNames__c) {
        subsAssetNames = Item.SubscribedAssetNames__c.split(',');
        }
        const countOfAssets = subsAssetNames.length;
        if (
        Item.Product_Subtype__c === 'GO CNV' &&
        Item.SBQQ__EffectiveQuantity__c !== countOfAssets
        ) {
           var val4 = '# of Assets match with Qty Exception';
        if (!excpvaluesarray.includes(val4)) excpvaluesarray.push(val4);
        }
             }
        if (Item.Quantity_TB__c != null && Item.Total_Usable_Capacity__c != null && quote.OpportunitySubType__c.includes('GC')) {
        var prc = Item.Quantity_TB__c / Item.Total_Usable_Capacity__c;
		//console.log('prc',prc);
        var mth;
        if (Item.SBQQ__SegmentLabel__c != null) {
            mth = Item.SBQQ__SegmentLabel__c.replace('Month ', '');
			//console.log('mth',mth);
        }
        if (((mth >= 1 && mth <= 3 && prc < 0.15) 
        || (mth >= 4 && mth <= 6 && prc < 0.35) 
        || (mth >= 7 && mth <= 9 && prc < 0.50) 
        || (mth >= 10 && mth <= 12 && prc < 0.75))) {
            var val3 = 'Scale Utility Ramp Exception';
        if (!excpvaluesarray.includes(val3)) excpvaluesarray.push(val3);
        }
    	}
        if(Item.Account_s_Entitlement__c && Item.SBQQ__Quantity__c>Item.Account_s_Entitlement__r.Quantity__c){
            var val5 = 'Bypass UG SKU Linked Entitlement Qty Validation';
        if (!excpvaluesarray.includes(val5)) excpvaluesarray.push(val5);
        } 
                } catch (e) {
                    console.warn('Error in scale-utility check for line', Item, e);
    }		
                });
		
        var multiPicklistStr = excpvaluesarray.join(";");
            console.log('multiPicklistStr: ' + multiPicklistStr);

            // Set UI states if exceptions found
            if (excpvaluesarray && excpvaluesarray.length > 0) {
            component.set("v.alertExceptionMessage", excpvaluesarray);
                var exceptionTitle = $A.get("$Label.c.Exception_Message");
                component.set("v.exceptionTitle", exceptionTitle);
            component.set("v.isException", true);
        }

            // Update Quote if required
            if (isUpdate) {
                this.updateExceptionsOnQuote(component, multiPicklistStr)
            }

        } catch (err) {
            console.error('Error in processExceptions:', err);
            reject(err);
        }
        });
},

    //CPQ22-5846 starts
    updateExceptionsOnQuote : function (component,multiPicklistStr){
        return new Promise((resolve, reject) => {
        var action = component.get("c.processExcpValues");
        action.setParams({
            valuesStr: multiPicklistStr,
            recordId:  component.get("v.recordId")
        });
            action.setCallback(this, function (response) {
                if (response.getState() === "SUCCESS") {
        var updatedQuote = response.getReturnValue();
                    if (updatedQuote) { component.set("v.quoteRec", updatedQuote); }
        resolve();
                    debugger;
      } else {
        var err = response.getError();
        reject(err);
      }
    });
        $A.enqueueAction(action);
        });
    },
    //CPQ22-5846 Ends
    evalGlobal: function(expr, condMatches) {
        expr = (expr || "").trim();
    
        while (expr.startsWith("(") && expr.endsWith(")")) {
            var depth = 0, matched = false;
            for (var i = 0; i < expr.length; i++) {
                var ch = expr.charAt(i);
                if (ch === "(") depth++;
                else if (ch === ")") {
                    depth--;
                    if (depth === 0) {
                        matched = (i === expr.length - 1);
                        break;
                    }
                }
            }
            if (matched) expr = expr.substring(1, expr.length - 1).trim();
            else break;
        }

        // OR logic
        var orParts = this.splitTopLevel(expr, "OR");
        if (orParts.length > 1) {
            return orParts.some(function(p) {
                return this.evalGlobal(p, condMatches);
            }, this);
        }

        // AND logic
        var andParts = this.splitTopLevel(expr, "AND");
        if (andParts.length > 1) {
            return andParts.every(function(p) {
                return this.evalGlobal(p, condMatches);
            }, this);
        }

        return !!condMatches[expr.trim()];
    },

    splitTopLevel: function(expr, operator) {
        expr = (expr || "").trim();
        var parts = [], depth = 0, start = 0;
        var opToken = " " + operator + " ";
        var opLen = opToken.length;
    
        for (var i = 0; i < expr.length; i++) {
            var ch = expr.charAt(i);
            if (ch === "(") { depth++; continue; }
            if (ch === ")") { depth--; continue; }
    
            if (depth === 0 && i <= expr.length - opLen && expr.substr(i, opLen) === opToken) {
                parts.push(expr.substring(start, i).trim());
                i += opLen - 1;
                start = i + 1;
            }
        }
        parts.push(expr.substring(start).trim());
        return parts;
    },

    evalLeaf: function(cond, qli, summaryVars,quote) {       
      var source = (cond.RBRKTestedObject__c === 'Quote') ? quote : qli;
        		console.log('field',quote.Check_for_ER_UA_DA__c);
        var rawactual = (cond.RBRKTestVariable__c != null && cond.RBRKTestVariable__c !== "")
      ? summaryVars[cond.RBRKTestVariable__c]
      : source[cond.RBRKTestedField__c];
        var actual = ('' + rawactual).toLowerCase().trim();
                     console.log('actual',actual);
    	var Val = (cond.RBRKFilterType__c === 'Variable') ? summaryVars[cond.VariableName__c ] : cond.RBRKFilterValue__c;
        var rawVal = ('' + Val).toLowerCase();
        var valList = String(rawVal).split(",").map(function(v){ return v.trim(); });
             console.log('valList',valList);
 		const op = (cond.RBRKOperator__c || '').toLowerCase().trim();
        switch (op) {
          case 'equals':
            return valList.includes(actual);
        
          case 'not equals':
            return !valList.includes(actual);
        
          case 'less than':
            return Number(actual) < Number(rawVal);
        
          case 'less or equals':
            return Number(actual) <= Number(rawVal);
        
          case 'greater than':
            return Number(actual) > Number(rawVal);
        
          case 'greater or equals':
            return Number(actual) >= Number(rawVal);
        
          case 'starts with':
            return typeof actual === 'string' && actual.startsWith(rawVal);
        
          case 'ends with':
            return typeof actual === 'string' && actual.endsWith(rawVal);
        
          case 'contains':
            return typeof actual === 'string' && actual.includes(rawVal);
        
          default:
            console.warn('Unknown operator', cond.RBRKOperator__c);
            return false;
        }

    },

       buildSummaryVars: function(quote, lines, defs,assets) {
            var summary     = {};
            var idToVarName = {};
        
            defs.sort(function(a, b) {
                var aHas = (a.RBRK_CompositeOperator__c || '').toLowerCase().trim() ? 1 : 0;
                var bHas = (b.RBRK_CompositeOperator__c || '').toLowerCase().trim() ? 1 : 0;
                return aHas - bHas;
            });
        
            defs.forEach(function(def) {
                idToVarName[def.RBRK_SVUniqueId__c] = def.RBRK_SVUniqueId__c;
        
                var varName      = def.RBRK_SVUniqueId__c,
                    target       = def.RBRK_TargetObject__c,
                    filterField  = def.RBRK_FilterField__c,
                    filterValue  = def.RBRK_FilterValue__c,
                    operator     = def.RBRK_Operator__c,
                    aggFn        = def.RBRK_AggregateFunction__c,
                    aggField     = def.RBRK_AggregateField__c;
        
              var sourceRecords =
            target === 'Quote' ? (quote ? [quote] : []) :
            target === 'Quote Line' ? [].concat(lines || [], assets || []).filter(Boolean) :
            target === 'Asset' ? [].concat(assets || []).filter(Boolean) :
            [];
                var filterValues  = (filterValue||'').split(',').map(v=>v.trim());
                var filtered      = sourceRecords.filter(function(rec) {
                    var actual = rec[filterField];
                    switch ((operator||'').toLowerCase().trim()) {
                       case 'equals':     return filterValues.includes(String(actual));
						case 'not equals': return !filterValues.includes(String(actual));
                        case 'contains':          return typeof actual==='string' && filterValues.some(v=>actual.includes(v));
                        case 'starts with':       return typeof actual==='string' && filterValues.some(v=>actual.startsWith(v));
                        case 'ends with':         return typeof actual==='string' && filterValues.some(v=>actual.endsWith(v));
                        case 'greater than':      return actual > filterValues[0];
                        case 'less than':         return actual < filterValues[0];
                        case 'greater or equals': return actual >= filterValues[0];
                        case 'less or equals':    return actual <= filterValues[0];
                        default:                  return false;
                    }
                });
                var result;
                switch ((aggFn||'').toLowerCase()) {
                    case 'count':
                        result = filtered.length;
                        break;
                    case 'sum':
                        result = filtered.reduce((s,r)=>s + (parseFloat(r[aggField])||0), 0);
                        break;
                    case 'min':
                        result = Math.min(...filtered.map(r=>parseFloat(r[aggField])||Infinity));
                        break;
                    case 'max':
                        result = Math.max(...filtered.map(r=>parseFloat(r[aggField])||-Infinity));
                        break;
                    default:
                        result = null;
                }
        
                summary[varName] = result;
            });
        
            defs.forEach(def => {
                var varName     = def.RBRK_SVUniqueId__c,
                    compOpRaw   = def.RBRK_CompositeOperator__c,
                    compVarKey  = def.RBRK_CombineWith__c,
                    compValLit  = def.RBRK_CompositeValueElement__c,
                    compOp      = (compOpRaw||'').toLowerCase().trim();
        
                if (!compOp) return;
        
                var baseNum  = Number(summary[varName]||0),
                    operand  = compVarKey
                      ? Number(summary[idToVarName[compVarKey]]||0)
                      : Number(compValLit||0);
        
                switch (compOp) {
                    case 'add':
                        summary[varName] = baseNum + operand;
                        break;
                    case 'subtract':
                        summary[varName] = baseNum - operand;
                        break;
                    case 'multiply':
                        summary[varName] = baseNum * operand;
                        break;
                    case 'divide':
                        summary[varName] = operand !== 0 ? baseNum / operand : null;
                        break;
                }
            });
        
            return summary;
        }

})