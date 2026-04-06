({ 
	//Comments
    handlesaveOrder : function(component, event, helper) {     
        var fieldMapping = {
            'Shipping Street' : component.get("v.sObjectInfoClone.ShippingStreet"),
            'Shipping PostalCode' : component.get("v.sObjectInfoClone.ShippingPostalCode"),
            'Shipping City' : component.get("v.sObjectInfoClone.ShippingCity"),
            'Shipping Country' : component.get("v.sObjectInfoClone.ShippingCountryCode"),
            'Shipping State' : component.get("v.sObjectInfoClone.ShippingStateCode"),
            'Ship To Contact Name' : component.get("v.sObjectInfoClone.ShipToContactName__c"),
            'Po Date' : component.get("v.sObjectInfoClone.PoDate"),
            'PO Number' : component.get("v.sObjectInfoClone.PoNumber"),
            'End User PO Number' : component.get("v.sObjectInfoClone.End_User_PO__c"),
            'Shipping Carrier' : component.get("v.sObjectInfoClone.Shipping_Carrier__c"),
            'Payment Term' : component.get("v.sObjectInfoClone.Payment_Terms__c"),
            'Ship To Name' : component.get("v.sObjectInfoClone.Ship_To_Name__c"),
            'Service Level' : component.get("v.sObjectInfoClone.Service_Level__c"),
            'Bill To Name' : component.get("v.sObjectInfoClone.Bill_To_Name__c"),
            'Shipping Term' : component.get("v.sObjectInfoClone.Shipping_Method__c"),
            'Ship To Email' : component.get("v.sObjectInfoClone.Ship_to_Email__c")
        };
        
        console.log('testShipping'+ fieldMapping);
        
        var missingField = [];
        var missingfieldsName;
        for(var field in fieldMapping) {
            if($A.util.isEmpty(fieldMapping[field]) && field != 'Shipping State' ) {
                missingField.push(field);
                
            }else if($A.util.isEmpty(fieldMapping[field]) && field == 'Shipping State' &&
                     (fieldMapping['Shipping Country'] == 'US' || fieldMapping['Shipping Country'] == 'CA')  ){
                missingField.push(field);
            }
        }
        if( $A.util.isEmpty(component.get("v.sObjectInfoClone.Ship_To_Phone_Number__c")) && component.get("v.sObjectInfoClone.Have_Hardware_Products__c")){
            missingField.push('Ship to Phone Number');
        }
         
        if($A.util.isEmpty(component.get("v.sObjectInfoClone.Shipping_Account_Number__c")) && component.get("v.sObjectInfoClone.Shipping_Carrier__c") != 'No Shipping Required'){
        	missingField.push('Shipping Account #');
        }
        
        if(component.get("v.sObjectInfoClone.Auto_Manual_Split__c") == 'Manual' && $A.util.isEmpty(component.get("v.sObjectInfoClone.Reason_For_Split__c"))){
            missingField.push('Reason For Split');
        }
        
        missingfieldsName = missingField.join(', ');
		console.log('missingField'+ missingField); 

        const d2 = new Date(component.get("v.sObjectInfoClone.CreatedDate"));
        const d1 = new Date();
        const diffMs = d1.getTime() - d2.getTime();
        const diffMins = Math.floor((diffMs / 1000) / 60);
        console.log(diffMins)

        var orderSplitType = component.get("v.sObjectInfoClone.Order_Split_Type__c");
        console.log('orderSplitType'+ orderSplitType);
        let sobjectrec = component.get("v.sObjectInfoClone");
        if(diffMins < 15 && !$A.util.isEmpty(orderSplitType) && orderSplitType != "Not needed" && orderSplitType != "Split Completed"){
            component.set("v.content","Please wait for sometime as Order is not splitted yet."); 
            component.set("v.showcancel",true);
        }else if(component.get("v.OrderInternalStage") == 'Required'){
            component.set("v.content","Please click on “link order” to complete order validation"); 
            component.set("v.showcancel",true);
        }else if( !component.get("v.isBillToNameSame")){ 
            component.set("v.content","Mismatch in PO and order bill to name"); 
            component.set("v.showcancel",true);    
        }else if(!component.get("v.isOrderAndPOAmountSame")){ 
            component.set("v.content","PO/Order Pricing Mismatch"); 
            component.set("v.showcancel",true);
        }else if((['Shipped', 'Order Accepted' ].includes(sobjectrec.Status) && sobjectrec.Order_Status__c != 'On Hold')
            || ['Shipped', 'Order Accepted', 'Returned'].includes(sobjectrec.Order_Status__c)){ 
            component.set("v.content","Order is already submitted."); 
            component.set("v.showcancel",true);
        }else if(component.get("v.sObjectInfoClone.Is_CPQ_Price_Book__c") && component.get("v.sObjectInfoClone.SBQQ__PriceCalcStatus__c") !== 'Completed' && component.get("v.sObjectInfoClone.SBQQ__PriceCalcStatus__c") !== 'Not Needed') { 
            component.set("v.showcancel",true);
            component.set("v.content","You can submit only orders with completed price calculations."); 
        } else  if((component.get("v.sObjectInfoClone.Type") == 'Revenue') && !$A.util.isEmpty(missingfieldsName)){ 
            component.set("v.showcancel",true);
            component.set("v.content","Please make sure "+missingfieldsName+" filled in."); 
        }else if(component.get("v.isAdditionalTermFlag") && component.get("v.orderObjInfo.Stage_PO__c") != null){
            component.set("v.content","Additional Terms Agreement Confirmation is required for the Order"); 
            component.set("v.showcancel",true);  
        }else if(sobjectrec.Type == 'Revenue' 
            && sobjectrec.Order_Sub_Type__c == 'Renewal'
            && ((sobjectrec.OpportunityId != null && sobjectrec.Opportunity.Opportunity_Sub_Type__c != sobjectrec.Order_Sub_Type__c)
            || sobjectrec.OpportunityId == null)){
            component.set("v.showcancel",true);
            component.set("v.content","Opportunity sub-type mismatch with Order. Please tag the correct opportunity"); 
        }else if(sobjectrec.Type == 'Revenue' 
            && sobjectrec.Have_Hardware_Products__c 
            && sobjectrec.Shipping_Carrier__c == 'No Shipping Required'){
            component.set("v.showcancel",true);
            component.set("v.content","Order contains a hardware product, 'No shipping required' is an invalid shipping carrier and the order cannot be submitted.");
        }
        else{
            var alertedOut = false;
            var isListTotal = false;
            var isPriceMismatch = false;	
            var orderProdNumber = [];
            var isFedrampProd = false;
            var isNonFedrampProd = false;
            var isRCDMTWithEOL = false;
            var hasRcdmSku = false;
            var paymentTermOnQuote;
            var paymentTermOnBillToName;
            var paymentTermOnOrder = component.get("v.sObjectInfoClone.Payment_Terms__c");
            if(!$A.util.isEmpty(component.get("v.sObjectInfoClone.Quote_RCDM_T_EOL_Date__c")) && 
                component.get("v.sObjectInfoClone.Quote_RCDM_T_EOL_Date__c") < $A.localizationService.formatDate(new Date(), "YYYY-MM-DD") &&
                component.get("v.sObjectInfoClone.Type") == 'Revenue' &&
                $A.util.isEmpty(component.get("v.sObjectInfoClone.Order_Sub_Type__c"))){
                    isRCDMTWithEOL = true;
                   
                }
            if(!$A.util.isEmpty(component.get("v.orderObjInfo.SBQQ__Quote__c")))
              paymentTermOnQuote = component.get("v.orderObjInfo.SBQQ__Quote__r.SBQQ__PaymentTerms__c");
            
            if(!$A.util.isEmpty(component.get("v.orderObjInfo.Bill_To_Name__c")))
              paymentTermOnBillToName = component.get("v.orderObjInfo.Bill_To_Name__r.Payment_Term__c");
    

            component.set("v.sObjectInfoClone.Credit_Check_Failure_Reason__c",'NA');
            component.set("v.sObjectInfoClone.Credit_Limit__c",null);
            component.set("v.sObjectInfoClone.Customer_Balance__c",null);
            if(!$A.util.isEmpty(component.get("v.sObjectInfoOrderItem"))){
            if (!$A.util.isEmpty(component.get("v.sObjectInfoClone.Type")) && component.get("v.sObjectInfoClone.Type") == 'Revenue' && 
                $A.util.isEmpty(component.get("v.sObjectInfoClone.Order_Sub_Type__c")) && $A.util.isEmpty(component.get("v.sObjectInfoClone.SBQQ__Quote__c"))) {
                
                        var orderItemRecords = component.get("v.sObjectInfoOrderItem");
                        console.log('::orderItemRecords::',orderItemRecords);
                        if (!$A.util.isEmpty(orderItemRecords)) {
                            for(var i=0; i< orderItemRecords.length; i++){
                                var listTotal = orderItemRecords[i].List_Total__c;
                                if($A.util.isEmpty(listTotal)) {
                                    
                                    isListTotal = true;
                                    break;
                                    
                                }
                                
                            }
                            
                    }
                    //helper.callAlertedOutFalse(component, event, helper,alertedOut);
                
            }
            if (!$A.util.isEmpty(component.get("v.sObjectInfoClone.Type")) && component.get("v.sObjectInfoClone.Type") != 'RMA') {
                        var orderItemRecords = component.get("v.sObjectInfoOrderItem");
                        console.log(orderItemRecords);
                        if (!$A.util.isEmpty(orderItemRecords)) {
                            
                            
                            if(orderItemRecords.length > 0 && orderItemRecords[0].SBQQ__QuoteLine__r != null){
                                console.log('--------orderItemRecords expiration date --------',orderItemRecords[0].SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__ExpirationDate__c);
                                //var TodayDate = (new Date().toLocaleDateString('en-CA')).substring(0,10);                                
                               // let intlDateObj = new Intl.DateTimeFormat('en-CA',{timeZone: 'America/Los_Angeles' });
                                //let TodayDate = intlDateObj.format(new Date());
                                let chicago_datetime_str = new Date().toLocaleString("en-US", { timeZone: "America/Los_Angeles" });

                                // create new Date object
                                let date_chicago = new Date(chicago_datetime_str);
                                
                                // year as (YYYY) format
                                let year = date_chicago.getFullYear();
                                
                                // month as (MM) format
                                let month = ("0" + (date_chicago.getMonth() + 1)).slice(-2);
                                
                                // date as (DD) format
                                let date = ("0" + date_chicago.getDate()).slice(-2);
                                
                                // date time in YYYY-MM-DD format
                                let TodayDate = year + "-" + month + "-" + date;
                               
				    var isExpired = orderItemRecords[0].SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__ExpirationDate__c < TodayDate ? true : false;
                                console.log('--------is Expired --------',isExpired);
                                if(isExpired == true && component.get("v.sObjectInfoClone.Opportunity.StageName") != '7 Closed Won'){
                                    alertedOut = true;
                                    component.set("v.content",'The Quote is expired.');
                                    component.set("v.showcancel",true);
                                }
                            }
				var mapqli = component.get("v.mapqli");
				var allQli = component.get("v.allQli");
				console.log('all mapqli in handlesaveOrder ' + JSON.stringify(mapqli));
				console.log('allQli in handlesaveOrder' + JSON.stringify(allQli));
				var byPassOrder = $A.get("$Label.c.By_Pass_Stage_PO_Validation");
				var currentOrderNumber =  component.get("v.sObjectInfoClone.SBQQ__Quote__r.Name");
				var quoteType = component.get("v.sObjectInfoClone.SBQQ__Quote__r.SBQQ__Type__c");
	
                            for(var i=0; i< orderItemRecords.length; i++){
					if(!byPassOrder.includes(currentOrderNumber) && quoteType!='Amendment'){
				if(((orderItemRecords[i].Product2.Family == 'EDGE' && orderItemRecords[i].Product2.Eligible_for_RCDM_T__c) || orderItemRecords[i].Product2.Product_Level__c  == 'LOD Software' || orderItemRecords[i].Product2.Product_Level__c  == 'Hybrid Software' || 
				(orderItemRecords[i].Product2.Product_Level__c == 'OnPrem' && (orderItemRecords[i].Product2.Product_Type__c == 'Foundation Edition' || orderItemRecords[i].Product2.Product_Type__c == 'Business Edition' || orderItemRecords[i].Product2.Product_Type__c == 'Enterprise Edition') && orderItemRecords[i].Product2.product_subtype__c == null))){
				var correctRCDMLine = mapqli[orderItemRecords[i].SBQQ__QuoteLine__c];
				if(!allQli.includes(correctRCDMLine) && correctRCDMLine!=undefined && !isRCDMTWithEOL){
				alertedOut = true;
				component.set("v.content","Quantity of  "+ orderItemRecords[i].Product2.Name +"  should  exactly match with RCDM-T <a target=_blank href=\"/lightning/r/OrderItem/" + orderItemRecords[i].Id+"/view\"> within same order / PO</a>"); 

				// component.set("v.content","Software sku "+ orderItemRecords[i].Product2.Name +" with linenumber " + orderItemRecords[i].OrderItemNumber +" doesnot have equivalent Line " + orderItemRecords[i].Product2.Name); 

				//  component.set("v.content","There is no matching RCDM Line For support sku "+ orderItemRecords[i].Product2.Name +"With OrderItemNumber"+orderItemRecords[i].OrderItemNumber); 
				component.set("v.showcancel",true);
				break;
				}
				//licencequantity +=orderItemRecords[i].Quantity;
				}
				console.log('orderlines log is ' + JSON.stringify(orderItemRecords[i]));
				if(orderItemRecords[i].Product2.Name == component.get("v.rcdmattr") && (orderItemRecords[i].SBQQ__RequiredBy__c!=null && (!allQli.includes(orderItemRecords[i].SBQQ__RequiredBy__r.SBQQ__QuoteLine__c) ||
                    (((!orderItemRecords[i].SBQQ__RequiredBy__r.Product2.Name.includes('-PB-EDG-') && orderItemRecords[i].Quantity!=orderItemRecords[i].SBQQ__RequiredBy__r.Quantity) ||  (orderItemRecords[i].SBQQ__RequiredBy__r.Product2.Name.includes('-PB-EDG-') && orderItemRecords[i].Quantity != (orderItemRecords[i].SBQQ__RequiredBy__r.Quantity)*1000)  ) && allQli.includes(orderItemRecords[i].SBQQ__RequiredBy__r.SBQQ__QuoteLine__c))) 
					&& mapqli[orderItemRecords[i].SBQQ__RequiredBy__r.SBQQ__QuoteLine__c]!=undefined && mapqli[orderItemRecords[i].SBQQ__RequiredBy__r.SBQQ__QuoteLine__c] == orderItemRecords[i].SBQQ__QuoteLine__c)){
				console.log('rcdm logic for required by');
				alertedOut = true;
				component.set("v.content","Quantity of  "+ orderItemRecords[i].SBQQ__RequiredBy__r.Product2.Name +"  should  exactly match with RCDM-T <a target=_blank href=\"/lightning/r/OrderItem/" + orderItemRecords[i].SBQQ__RequiredBy__c+"/view\"> within same order / PO</a>"); 

				//     component.set("v.content","Quantity of  "+ orderItemRecords[i].SBQQ__RequiredBy__r.Product2.Name +"  should exactly match with RCDM-T <a target=_blank href=\"/" + orderItemRecords[i].Id+"\"> within same order / PO</a>"); 

				//component.set("v.content","Software sku "+ orderItemRecords[i].SBQQ__RequiredBy__r.Product2.Name +" with linenumber " + orderItemRecords[i].SBQQ__RequiredBy__r.OrderItemNumber +" quantity doesnot matched with " + orderItemRecords[i].Product2.Name); 
				component.set("v.showcancel",true);
				break;

				}



				if(orderItemRecords[i].Product2.Name == component.get("v.rcdmattr") && (orderItemRecords[i].SBQQ__RequiredBy__c==null && orderItemRecords[i].SBQQ__QuoteLine__r.SBQQ__RequiredBy__c!=null)){
				//console.log('parent quote line is ' + orderItemRecords[i].SBQQ__RequiredBy__r.SBQQ__QuoteLine__c);
				alertedOut = true;
				component.set("v.content","There is no matching software support sku for "+orderItemRecords[i].Product2.Name); 
				component.set("v.showcancel",true);
				break;


				}
				} 
    
                                var subPrice = orderItemRecords[i].Product2.SBQQ__SubscriptionPricing__c;  
                                var subTerm = orderItemRecords[i].SBQQ__SubscriptionTerm__c;
                                var startDate = orderItemRecords[i].Support_Start_Date__c;
                                var endDate = orderItemRecords[i].Support_End_Date__c;
                                var orderProd = orderItemRecords[i].Product2;
                                var qliReqByProdCode = orderItemRecords[i].SBQQ__QuoteLine__c ? orderItemRecords[i].SBQQ__QuoteLine__r.Required_By_Product_Code__c: null;
                                var oiReqByProdCode = orderItemRecords[i].Required_by_Product_Code__c
                                var oiQLIPOSKU;
                                if(orderItemRecords[i].SBQQ__QuoteLine__r && orderItemRecords[i].SBQQ__QuoteLine__r.SBQQ__ProductOption__r && orderItemRecords[i].SBQQ__QuoteLine__r.SBQQ__ProductOption__r.SBQQ__ConfiguredSKU__r){
                                    oiQLIPOSKU = orderItemRecords[i].SBQQ__QuoteLine__r.SBQQ__ProductOption__r.SBQQ__ConfiguredSKU__r;
                                }

                                if (!$A.util.isEmpty(subPrice) && $A.util.isEmpty(subTerm) && component.get("v.sObjectInfoClone.Type") != 'POC' && component.get("v.sObjectInfoClone.Order_Sub_Type__c")!='MSP Overage') {
                                    alertedOut = true;
                                    component.set("v.content","Subscription Term must be stamped on Order product in order to submit Order"); 
                                    component.set("v.showcancel",true);
                                    break;
                                } else if (
                                    (component.get("v.sObjectInfoClone.ManualFulfilment__c") == false && (component.get("v.sObjectInfoClone.is_Amendment_Order__c") == true || component.get("v.sObjectInfoClone.Order_Sub_Type__c") == 'Renewal') && orderItemRecords[i].SerialNumber__c == null) &&
                                    (
                                        !component.get("v.sObjectInfoClone.Is_RWD_Polaris_Quote__c") || 
                                        (component.get("v.sObjectInfoClone.Is_RWD_Polaris_Quote__c") &&
                                         (
                                             ( orderProd.Product_Level__c =='Hybrid Software' && (orderProd.Product_Subtype__c == 'SaaS Cloud' || orderProd.Product_Type__c=='Complete Edition'|| orderProd.Product_Type__c=='Complete Edition Elite' || orderProd.Product_Type__c=='Complete Edition Pro')) ||
                                             (orderProd.Product_Level__c == 'OnPrem' && (orderProd.Product_Type__c =='Foundation Edition' || orderProd.Product_Type__c =='Business Edition' || orderProd.Product_Type__c =='Enterprise Edition' ) && orderProd.Product_Subtype__c == null) ||
                                             (orderProd.Product_Level__c == 'LOD Software')
                                         ) && !(orderProd.Family == 'Third Party License' || !$A.util.isEmpty(orderItemRecords[i].TPH_OEM__c) || !$A.util.isEmpty(orderItemRecords[i].TPH_Models_Gen__c)) //PRDOPS26-393
                                        )
                                    )&&
                                    (   
                                        (oiReqByProdCode == undefined || oiReqByProdCode == null || $A.util.isEmpty(oiReqByProdCode))
                                        ||
                                        (
                                            qliReqByProdCode != undefined && qliReqByProdCode != null && !$A.util.isEmpty(qliReqByProdCode)

                                        || 
                                            (
                                                (qliReqByProdCode == undefined || qliReqByProdCode == null || $A.util.isEmpty(qliReqByProdCode))
                                                &&(oiQLIPOSKU != null  && oiQLIPOSKU != undefined && !$A.util.isEmpty(oiQLIPOSKU)) 
                                                &&(
                                                    oiQLIPOSKU.Product_Type__c != 'Add-On Node' 
                                                    || (oiQLIPOSKU.Appliance_Model__c == null || $A.util.isEmpty(oiQLIPOSKU.Appliance_Model__c))
                                                    || oiQLIPOSKU.Item_Type__c == 'Serialized Inventory Item'
                                                )
                                            )
                                        )
                                    )
                                ){
                                    alertedOut = true;
                                    component.set("v.content","Serial Number must be stamped on Order product in order to submit Renewal/Amendment Order"); 
                                    component.set("v.showcancel",true);
                                    break;
                                } else if (component.get("v.sObjectInfoClone.ManualFulfilment__c") == false && (component.get("v.sObjectInfoClone.Order_Sub_Type__c") == 'Renewal' || (component.get("v.sObjectInfoClone.Order_Sub_Type__c") == 'Amendment' && component.get("v.iscoterm") == true)) && orderProd.Product_Type__c !='Reinstate Fee' && (startDate == null || endDate == null)) {
                                    alertedOut = true;
                                    component.set("v.content","Start and End date can not be blanked for Renewal/Amendment orders"); 
                                    component.set("v.showcancel",true);
                                    break;
                                } else if(!$A.util.isEmpty(orderItemRecords[i].SBQQ__QuoteLine__c) &&	
                                          !$A.util.isEmpty(orderItemRecords[i].SBQQ__QuoteLine__r.SBQQ__NetPrice__c) &&	
					   orderItemRecords[i].Product2.Product_Type__c != 'Edition Upgrade' &&
					   orderItemRecords[i].Product2.Product_Subtype__c != 'Scale MSP' &&
                                          !$A.util.isEmpty(orderItemRecords[i].Sales_Price__c) &&	
                                          Math.abs(Math.round(orderItemRecords[i].SBQQ__QuoteLine__r.SBQQ__NetPrice__c) - Math.round(orderItemRecords[i].Sales_Price__c)) > 0) {	
                        	
                                    isPriceMismatch = true;	
                                    orderProdNumber.push(orderItemRecords[i].SBQQ__QuoteLine__r.Name);       	
                        	
                                }	
                                	
                            } 
			
				
				
                    }
                    //helper.callAlertedOutFalse(component, event, helper,alertedOut);
                 }
            if (!$A.util.isEmpty(component.get("v.sObjectInfoClone.Type")) && component.get("v.sObjectInfoClone.Type") == 'RMA') {
                
                        var orderItemRecords = component.get("v.sObjectInfoOrderItem");
                        console.log(orderItemRecords);
                        if (!$A.util.isEmpty(orderItemRecords)) {
                            for (var i = 0; i < orderItemRecords.length; i++) {
                                var OIUnitPrice = parseInt(orderItemRecords[i].UnitPrice);
                                if(OIUnitPrice > 0){
                                    alertedOut = true;
                                    component.set("v.content","RMA order should always be $0 ");
                                    component.set("v.showcancel",true);
                                    break;
                                }
                            }
                        }
                    
                    //helper.callAlertedOutFalse(component, event, helper,alertedOut);
                    }

            var orderItemRecords = component.get("v.sObjectInfoOrderItem");
            for (var i = 0; i < orderItemRecords.length; i++) {

                if(component.get("v.rcdmattr") == orderItemRecords[i].Product2.Name ){
                    hasRcdmSku= true
                }
                if(isRCDMTWithEOL && hasRcdmSku){
                     break;
                }

                if (!isFedrampProd && (orderItemRecords[i].Product2.Product_Level__c == 'LOD Software' ||
                orderItemRecords[i].Product2.Product_Level__c == 'Hybrid Software' ||
                (orderItemRecords[i].Product2.Product_Level__c == 'OnPrem' && orderItemRecords[i].Product2.Product_Subtype__c == null &&
                    (orderItemRecords[i].Product2.Product_Type__c == 'Foundation Edition' ||
                        orderItemRecords[i].Product2.Product_Type__c == 'Business Edition' ||
                        orderItemRecords[i].Product2.Product_Type__c == 'Enterprise Edition'))) && orderItemRecords[i].Product2.Product_Subtype__c == 'FEDRAMP'){
                    console.log('isFedrampProd - ProductCode: '+orderItemRecords[i].Product2.ProductCode);        
                    isFedrampProd = true;
                }
                if (!isNonFedrampProd && (orderItemRecords[i].Product2.Product_Level__c == 'LOD Software' ||
                    orderItemRecords[i].Product2.Product_Level__c == 'Hybrid Software' ||
                    (orderItemRecords[i].Product2.Product_Level__c == 'OnPrem' && orderItemRecords[i].Product2.Product_Subtype__c == null &&
                        (orderItemRecords[i].Product2.Product_Type__c == 'Foundation Edition' ||
                            orderItemRecords[i].Product2.Product_Type__c == 'Business Edition' ||
                            orderItemRecords[i].Product2.Product_Type__c == 'Enterprise Edition'))) && orderItemRecords[i].Product2.Product_Subtype__c != 'FEDRAMP') {
                    console.log('isNonFedrampProd - ProductCode: '+orderItemRecords[i].Product2.ProductCode);                                        
                    isNonFedrampProd = true;

                }
                if (isFedrampProd && isNonFedrampProd){
                    break;
                }
            }
 
            if (isFedrampProd && isNonFedrampProd){
            alertedOut = true;
            component.set("v.showcancel", true);
            component.set("v.content", "You can not submit this Order as It has RSC-G Product along with the other License Product.");
            }
            if (paymentTermOnQuote != paymentTermOnOrder && paymentTermOnBillToName != paymentTermOnOrder
            ){
                alertedOut = true;
                component.set("v.showcancel", true);
                component.set("v.content", "You can not submit this Order as Payment terms do not match the quote/Distributor");
            }
                

            if(isRCDMTWithEOL && hasRcdmSku){
                alertedOut = true;
                component.set("v.showcancel", true);
                var rcdmError = 'RCDM-T EOL Date is in the past on this order, please remove the line prior to booking this order';
                 
                component.set("v.content", rcdmError);
                 var holdCode = $A.util.isEmpty(component.get("v.sObjectInfoClone.Hold_Code__c")) ? 'OM Internal Review' : !$A.util.isEmpty(component.get("v.sObjectInfoClone.Hold_Code__c")) && component.get("v.sObjectInfoClone.Hold_Code__c").includes("OM Internal Review") ? component.get("v.sObjectInfoClone.Hold_Code__c") : component.get("v.sObjectInfoClone.Hold_Code__c")+';'+'OM Internal Review';
                 var HoldNotes = $A.util.isEmpty(component.get("v.sObjectInfoClone.Change_Needed_Reason_Other__c")) ? rcdmError : !$A.util.isEmpty(component.get("v.sObjectInfoClone.Change_Needed_Reason_Other__c")) && component.get("v.sObjectInfoClone.Change_Needed_Reason_Other__c").includes(rcdmError) ? component.get("v.sObjectInfoClone.Change_Needed_Reason_Other__c") : component.get("v.sObjectInfoClone.Change_Needed_Reason_Other__c")+','+rcdmError  ;
                 var memoField = $A.util.isEmpty(component.get("v.sObjectInfoClone.Memo__c")) ? rcdmError : !$A.util.isEmpty(component.get("v.sObjectInfoClone.Memo__c")) && component.get("v.sObjectInfoClone.Memo__c").includes(rcdmError) ? component.get("v.sObjectInfoClone.Memo__c") : component.get("v.sObjectInfoClone.Memo__c")+','+rcdmError  ;
                 if(!$A.util.isEmpty(memoField)){
                    component.set("v.sObjectInfoClone.Memo__c", memoField);
                 }
                 if(!$A.util.isEmpty(holdCode)){
                  component.set("v.sObjectInfoClone.Hold_Code__c", holdCode);
                  }	
                  component.set("v.sObjectInfoClone.Order_Status__c",'On Hold');
                  if(!$A.util.isEmpty(HoldNotes)){
                  component.set("v.sObjectInfoClone.Change_Needed_Reason_Other__c",HoldNotes.substring(0, 255));
                  }
                  component.set("v.showok",true); 
            }
  

            helper.callAlertedOutFalse(component, event, helper,alertedOut, isListTotal, isPriceMismatch, orderProdNumber);
        } 
    }    
        
},
/*
* `ScaleUtil`ityValidation is method to call all the validation when there is manual Split For GC Offer
* As there can be mismatch between orderlines so we need to validate it and then send to Netsuite
* Ticket is CSU-62
*/
ScaleUtilityValidation : function(component,event, helper){
        if (!$A.util.isEmpty(component.get("v.sObjectInfoClone.Type")) && component.get("v.sObjectInfoClone.Type") != 'RMA') {
            var alertedOut = false;
            
            var orderItemRecords = component.get("v.sObjectInfoOrderItem");
            var currentOrderNumber =  component.get("v.sObjectInfoClone.SBQQ__Quote__r.Name");
            
            var byPassOrder = $A.get("$Label.c.By_Pass_Stage_PO_Validation");
            var mapOfLicenceWithAllLinesSU = component.get("v.mapOfLicenceWithAllLinesSU");             
            var mapOfHrdwareWithAccessoriesAndLines = component.get("v.mapOfHrdwareWithAccessoriesAndLines");
            var collectAllParentChildOnQuote = component.get("v.collectAllParentChildOnQuote");
            console.log('collectAllParentChildOnQuote >>>>> ' + JSON.stringify(collectAllParentChildOnQuote));
            var allQli = component.get("v.allQli");
            var orderSubType = component.get("v.sObjectInfoClone.Order_Sub_Type__c");
	    var ordertype = component.get("v.sObjectInfoClone.SBQQ__Quote__r.SBQQ__Type__c");

            
            /*
	     * Bypass the validation  of checking the parent RSVX for OND,RSV segments,Hw Support Lines
      	     * when doing manual split for SU GC Offer Amendment    
	     */
            for(var i=0; i< orderItemRecords.length; i++){
                if(!byPassOrder.includes(currentOrderNumber) && orderSubType== 'GC Offer' && orderItemRecords[i].Program__c !='v1v2' && ordertype!='Amendment'){
                    if(orderItemRecords[i].Product2.Product_Subtype__c == 'Scale MSP' && orderItemRecords[i].Product2.License_Category__c == null){
                        if(orderItemRecords[i].SBQQ__QuoteLine__r.SBQQ__Quantity__c!=orderItemRecords[i].Quantity){
                            alertedOut = true;
                            component.set("v.content","Lines "+ orderItemRecords[i].Product2.Name +"  should Match With Its Parent Line <a target=_blank href=\"/lightning/r/OrderItem/" + orderItemRecords[i].Id+"/view\"> within same order</a>"); 
                            component.set("v.showcancel",true);
                            break;  
                        }
                        var originalCollection = collectAllParentChildOnQuote[orderItemRecords[i].SBQQ__QuoteLine__c];
                        var rsvlines = originalCollection.RSV;
                        var hardwareLines = originalCollection.Hardware;
                        var onDemandLines = originalCollection.OnDemand;
                        var HwSupport = originalCollection.HwSupport;
                        var accessories = originalCollection.Accessory;
                        console.log('accessories i s#### ' + accessories);
                        console.log('accessories length is #### ' + accessories.length);
                        if(accessories.length > 0){
                            console.log('checking accessory length');
                            var  accessoriescheck = accessories.every(elem => allQli.includes(elem));
                            if(!accessoriescheck && orderItemRecords[i].SBQQ__QuoteLine__r.SBQQ__Quote__r.ProcessType__c!='Aspen'){
                                alertedOut = true;
                                component.set("v.content","Lines "+ orderItemRecords[i].Product2.Name +"  Doesnot Contain accessories <a target=_blank href=\"/lightning/r/OrderItem/" + orderItemRecords[i].Id+"/view\"> within same order</a>"); 
                                component.set("v.showcancel",true);
                                break; 
                            }
                            
                        }
                        
                        
                        if(HwSupport.length > 0){
                            const hwSupportCheck = HwSupport.every(elem => allQli.includes(elem));
                            if(!hwSupportCheck){
                                alertedOut = true;
                                component.set("v.content","Lines "+ orderItemRecords[i].Product2.Name +"  Doesnot Contain HwSupport Lines <a target=_blank href=\"/lightning/r/OrderItem/" + orderItemRecords[i].Id+"/view\"> within same order</a>"); 
                                component.set("v.showcancel",true);
                                break; 
                            }
                            
                        }
                        
                        if(onDemandLines.length > 0){
                            const onDMatch = onDemandLines.every(elem => allQli.includes(elem));
                            if(!onDMatch){
                                alertedOut = true;
                                component.set("v.content","Lines "+ orderItemRecords[i].Product2.Name +"  should Match With Its Parent Line <a target=_blank href=\"/lightning/r/OrderItem/" + orderItemRecords[i].Id+"/view\"> within same order</a>"); 
                                component.set("v.showcancel",true);
                                break; 
                            }
                            
                        }
                        
                        
                        if(rsvlines.length > 0){
                            const checkForRSV = rsvlines.every(elem => allQli.includes(elem));
                            if(!checkForRSV){
                                alertedOut = true;
                                component.set("v.content","Lines "+ orderItemRecords[i].Product2.Name +"  Doesnot Have Mathching Rsv Lines <a target=_blank href=\"/lightning/r/OrderItem/" + orderItemRecords[i].Id+"/view\"> within same order</a>"); 
                                component.set("v.showcancel",true);
                                break; 
                            }	
                        }
                        if(orderItemRecords[i].SBQQ__QuoteLine__r.SBQQ__Quote__r.ProcessType__c!='Aspen'){
                            console.log('hardwareLines lines length ' + hardwareLines.length);
                            if(hardwareLines.length > 0 ){
                                const checkForHradware = hardwareLines.every(elem => allQli.includes(elem));
                                if(!checkForHradware){
                                    alertedOut = true;
                                    component.set("v.content","Lines "+ orderItemRecords[i].Product2.Name +"  Doesnot have Matching Hardware Lines <a target=_blank href=\"/lightning/r/OrderItem/" + orderItemRecords[i].Id+"/view\"> within same order</a>"); 
                                    component.set("v.showcancel",true);
                                    break;
                                }  
                            }
                            
                        }
                    }
                    console.log('next item');  
                    console.log('orderItemRecords is ' + JSON.stringify(orderItemRecords[i]));
                    console.log('orderItemRecords[i].Product2.Product_Subtype__c' + orderItemRecords[i].Product2.Product_Subtype__c);
                    console.log('orderItemRecords[i].Product2.License_Category__c' + orderItemRecords[i].Product2.License_Category__c);
                    
                    
                    
                    
                    
                    var hardwareLine = (orderItemRecords[i].SBQQ__QuoteLine__r.SBQQ__Quote__r.ProcessType__c!='Aspen' && orderItemRecords[i].Product2.Product_Level__c == 'Hardware' && (orderItemRecords[i].Product2.Product_Type__c == 'Add-On Node' || orderItemRecords[i].Product2.Product_Type__c == 'Hardware'));
		/*
		* Bypass the validation of checking the parent line for RSV and OND line
  		* when submitting order of SU GC Offer Amendment  
		*/
		    var rsvAndOndLine = (orderItemRecords[i].Product2.Product_Subtype__c!=undefined && (orderItemRecords[i].Product2.Product_Subtype__c == 'Scale MSP' || orderItemRecords[i].Product2.Product_Subtype__c == 'On Demand') && orderItemRecords[i].Product2.License_Category__c == 'SaaS' && orderItemRecords[i].Order.is_Amendment_Order__c == false);
                    console.log('RSVOnDLine is ###### ' + rsvAndOndLine);
                    console.log('allQli is ###### ' +  JSON.stringify(allQli));
                    if(orderItemRecords[i].Product2.Product_Subtype__c == 'On Demand' &&  orderItemRecords[i].Product2.License_Category__c == 'SaaS'){
                        console.log('quote line on order is  ' + orderItemRecords[i].Product2.Name);
                        
                        console.log('quote line on order is  ' + orderItemRecords[i].SBQQ__QuoteLine__c);
                        
                        console.log('check parent for ond line ' + mapOfLicenceWithAllLinesSU[orderItemRecords[i].SBQQ__QuoteLine__c]);
                        console.log('check if includes ' + !allQli.includes(mapOfLicenceWithAllLinesSU[orderItemRecords[i].SBQQ__QuoteLine__c]))                                                                                          
                        
                    }                    
                    if((hardwareLine || rsvAndOndLine) && !allQli.includes(mapOfLicenceWithAllLinesSU[orderItemRecords[i].SBQQ__QuoteLine__c])){
                        console.log('rsvAndOndLine and hw  logic');
                        
                        console.log('Product Name is ' + JSON.stringify(orderItemRecords[i]));
                        alertedOut = true;
                        component.set("v.content","Lines "+ orderItemRecords[i].Product2.Name +"  should Match With Its Parent Line <a target=_blank href=\"/lightning/r/OrderItem/" + orderItemRecords[i].Id+"/view\"> within same order</a>"); 
                        component.set("v.showcancel",true);
                        break;
                    }
                    
                    
                    
                    
                    
                    var hwSupport = (orderItemRecords[i].Product2.Product_Level__c == 'Support' && orderItemRecords[i].Product2.Product_Type__c == 'HW Support');
                    var checkParentHardwareWhenNonAspen = (orderItemRecords[i].SBQQ__QuoteLine__r.SBQQ__Quote__r.ProcessType__c!='Aspen' && !allQli.includes( mapOfHrdwareWithAccessoriesAndLines[orderItemRecords[i].SBQQ__QuoteLine__c]));
                    var checkLicenceFoSupport =    (!allQli.includes(mapOfLicenceWithAllLinesSU[orderItemRecords[i].SBQQ__QuoteLine__c]));
                    
                    if(hwSupport){
                        console.log('orderItemRecords[i].Product2.Name for HW Support is ' + orderItemRecords[i].Product2.Name);
                        if(checkParentHardwareWhenNonAspen){
                            alertedOut = true;
                            component.set("v.content","Lines "+ orderItemRecords[i].Product2.Name +"  should Match With Its Parent Hardware Line <a target=_blank href=\"/lightning/r/OrderItem/" + orderItemRecords[i].Id+"/view\"> within same order</a>"); 
                            component.set("v.showcancel",true);
                            break;
                        }
                        
                        if(checkLicenceFoSupport){
                            alertedOut = true;
                            component.set("v.content","Lines "+ orderItemRecords[i].Product2.Name +"  should Match With Its Parent Licence Line <a target=_blank href=\"/lightning/r/OrderItem/" + orderItemRecords[i].Id+"/view\"> within same order</a>"); 
                            component.set("v.showcancel",true);
                            break;
                        }
                        
                        
                        
                    }
                    /*  if(((() || (orderItemRecords[i].SBQQ__QuoteLine__r.SBQQ__Quote__r.ProcessType__c!='Aspen' && !allQli.includes( mapOfHrdwareWithAccessoriesAndLines[orderItemRecords[i].SBQQ__QuoteLine__c])) ) &&
                        !allQli.includes(mapOfLicenceWithAllLinesSU[orderItemRecords[i].SBQQ__QuoteLine__c]) &&
                        (orderItemRecords[i].SBQQ__QuoteLine__r.SBQQ__Quote__r.ProcessType__c!='Aspen' && !allQli.includes( mapOfHrdwareWithAccessoriesAndLines[orderItemRecords[i].SBQQ__QuoteLine__c]))  )){
                        console.log('HW support logic');
                        
                        alertedOut = true;
                        component.set("v.content","Lines "+ orderItemRecords[i].Product2.Name +"  should Match With Its Parent Line <a target=_blank href=\"/lightning/r/OrderItem/" + orderItemRecords[i].Id+"/view\"> within same order</a>"); 
                        component.set("v.showcancel",true);
                        break;
                    }*/
                    
                    
                    if((orderItemRecords[i].Product2.Product_Level__c == 'Hardware' && orderItemRecords[i].Product2.License_Category__c == 'Accessories' &&
                        !allQli.includes(mapOfLicenceWithAllLinesSU[orderItemRecords[i].SBQQ__QuoteLine__c]) &&
                        !allQli.includes( mapOfHrdwareWithAccessoriesAndLines[orderItemRecords[i].SBQQ__QuoteLine__c]) && 
                        orderItemRecords[i].SBQQ__QuoteLine__r.SBQQ__Quote__r.ProcessType__c!='Aspen')){
                        console.log('HW accessories logic');
                        
                        alertedOut = true;
                        component.set("v.content","Lines "+ orderItemRecords[i].Product2.Name +"  should Match With Its Parent Line <a target=_blank href=\"/lightning/r/OrderItem/" + orderItemRecords[i].Id+"/view\"> within same order</a>"); 
                        component.set("v.showcancel",true);
                        break;  
                        
                    }
                    
                }
            }
        }
    },	
    
	//GTCA-19
    callAlertedOutFalse : function(component, event, helper,alertedOut, isListTotal, isPriceMismatch, orderProdNumber){
        var crsdReturnHoldCodeString = this.evaluateCRSDStatus(component);

        if (alertedOut == false) {
            var holdCodeToRetain= '';
            var holdCodeToShow= '';
            let orderRec =  component.get("v.orderObjInfo");
            if(orderRec.Type == 'Revenue' && orderRec.NetSuite_Order__c != null && orderRec.Order_Status__c == 'On Hold'){
                component.set("v.content",$A.get("$Label.c.Confirm_Order_Submit_Message"));
                component.set("v.sObjectInfoClone.Hold_Code__c", null);
                component.set("v.sObjectInfoClone.Order_Status__c","Order Accepted");
                component.set("v.showcancel",true);
                component.set("v.showok",true);   
                return;     
            }
            if (!$A.util.isEmpty(component.get("v.sObjectInfoClone.Hold_Code__c")) && (component.get("v.sObjectInfoClone.Hold_Code__c").includes('Contingency with order') > 0  )) {
            	holdCodeToRetain='Contingency with order';
                holdCodeToShow= 'Contingency with order';
            }
            if(!$A.util.isEmpty(component.get("v.sObjectInfoClone.Hold_Code__c")) && (component.get("v.sObjectInfoClone.Hold_Code__c").includes('Denied Party List') > 0  )) {
                holdCodeToRetain = (holdCodeToRetain == '') ? 'Denied Party List' : holdCodeToRetain+ ';Denied Party List' ;
                holdCodeToShow =  (holdCodeToShow == '') ? 'Denied Party List' : holdCodeToShow +' and Denied Party List' ;
            }
            //end PRDOPS21-47 & end PRDOPS21-34
            if (!$A.util.isEmpty(component.get("v.sObjectInfoClone.Hold_Code__c"))  && (component.get("v.sObjectInfoClone.Hold_Code__c") == 'Contingency with order' || component.get("v.sObjectInfoClone.Hold_Code__c") =='Denied Party List')) {
                component.set("v.content","You can not submit order with Hold Code " + holdCodeToShow +"."); 
                component.set("v.showcancel",true);
            } else if (!$A.util.isEmpty(component.get("v.sObjectInfoClone.Hold_Code__c")) && (component.get("v.sObjectInfoClone.Hold_Code__c").includes('Contingency with order') > 0 || component.get("v.sObjectInfoClone.Hold_Code__c").includes('Denied Party List') > 0 )) {
                component.set("v.content","Are you sure you want to submit this order? This will clear all existing hold codes except "+ holdCodeToShow +", which needs to be removed manually and order needs re-submission.");
                component.set("v.sObjectInfoClone.Hold_Code__c", holdCodeToRetain);
                component.set("v.sObjectInfoClone.Order_Status__c",'On Hold');
                component.set("v.showcancel",true);
                component.set("v.showok",true);    
            } else if ((component.get("v.sObjectInfoClone.OpportunityId") == null || component.get("v.sObjectInfoClone.SBQQ__Quote__c") == null) && component.get("v.sObjectInfoClone.Type") == 'Revenue' && component.get("v.sObjectInfoClone.Order_Sub_Type__c") != 'GC OnDemand' && component.get("v.sObjectInfoClone.Order_Sub_Type__c") != 'MSP Overage') {	
                component.set("v.content","You can not submit the order when Opportunity/Quote is missing");
                component.set("v.showcancel",true);               	
            } else if(isListTotal == true && component.get("v.sObjectInfoClone.Hold_Code__c") != 'Missing List / Extended Price') {
                
                component.set("v.content",'Order is updating...');
                component.set("v.sObjectInfoClone.Hold_Code__c",'Missing List / Extended Price');
                component.set("v.sObjectInfoClone.Order_Status__c",'On Hold');
                this.serversidesave(component, event, helper, component.get("v.sObjectInfoClone"));                  
    
                                    
            }else if (isPriceMismatch == true) {	
             		
                component.set("v.content",'Mismatch of quoteline and orderItem net unit price for OrderItem');	
                component.set("v.sObjectInfoClone.Hold_Code__c",'OM Internal Review');	
                component.set("v.sObjectInfoClone.Order_Status__c",'On Hold');	
                component.set("v.sObjectInfoClone.Change_Needed_Reason_Other__c",'Mismatch of quoteline and orderItem net unit price for '+orderProdNumber);	
                this.serversidesave(component, event, helper, component.get("v.sObjectInfoClone"));                  	
    	
            }else if (crsdReturnHoldCodeString!=null) {

                const HOLD_CODE_CONFIGS = {
                    'CRSD after renewal start date': {
                        message: 'The CRSD is after the earliest start date of renewal. Do you want to book it ?',
                        holdCode: 'CRSD after renewal start date'
                    },
                    'CRSD is in future quarter': {
                        message: 'The CRSD is outside of current quarter. Do you want to book?',
                        holdCode: 'CRSD is in future quarter'
                    }
                };
                console.log('crsdReturnHoldCodeString >>>> ' + crsdReturnHoldCodeString);
                const config = HOLD_CODE_CONFIGS[crsdReturnHoldCodeString];
                if (config) {
                    component.set("v.content", config.message);
                    const existingHoldCode = component.get("v.sObjectInfoClone.Hold_Code__c");
                    console.log('existingHoldCode >>>> ' + existingHoldCode);
                    if (existingHoldCode != null && existingHoldCode.includes(config.holdCode)) {
                        component.set("v.sObjectInfoClone.Hold_Code__c", null);
                        component.set("v.sObjectInfoClone.Internal_Order_Stage__c", 'Pending Validation');
                        component.set("v.sObjectInfoClone.Order_Status__c",'Pending');

                    } else {
                        component.set("v.sObjectInfoClone.Hold_Code__c", config.holdCode);
                        component.set("v.sObjectInfoClone.Change_Needed_Reason_Other__c", config.holdCode);
                   }
                    component.set("v.showok", true);
                    component.set("v.showcancel", true);
                }

            }else if(component.get("v.isAdditionalTermFlag") && component.get("v.orderObjInfo.Stage_PO__c") == null){
                const term = "Missing Distributor Acceptance of Addl Quote Terms";
                let holdCode = component.get("v.sObjectInfoClone.Hold_Code__c");
                if ($A.util.isEmpty(holdCode)) {
                    holdCode = term;
                } else if (!holdCode.includes(term)) {
                    holdCode += ';' + term;
                }
                component.set("v.content",$A.get("$Label.c.Distributor_Additional_Quote_Terms"));
                component.set("v.sObjectInfoClone.Hold_Code__c", holdCode);
                component.set("v.sObjectInfoClone.Order_Status__c",'On Hold');
                component.set("v.showcancel",true);
                component.set("v.showok",true);

            }else if (!$A.util.isEmpty(component.get("v.sObjectInfoClone.Hold_Code__c")) && isPriceMismatch != true ) {
                component.set("v.content","Are you sure you want to submit this order? This will clear all existing hold codes currently applied to the order.");
                if(component.get("v.sObjectInfoClone.Type")=='RMA' || component.get("v.sObjectInfoClone.Type")=='Revenue' || component.get("v.sObjectInfoClone.Type")=='POC'){
                    component.set("v.sObjectInfoClone.Order_Status__c",'Pending');
                }
                component.set("v.sObjectInfoClone.Hold_Code__c",null);
                component.set("v.sObjectInfoClone.Internal_Order_Stage__c",'Pending Validation');
                component.set("v.showcancel",true);
                component.set("v.showok",true); 
                if(component.get("v.sObjectInfoClone.Type") == 'Revenue' && !$A.util.isEmpty(component.get("v.sObjectInfoClone.Line_Types__c")) && (component.get("v.sObjectInfoClone.Line_Types__c").includes('Upgrade') > 0 || component.get("v.sObjectInfoClone.Line_Types__c").includes('Conversion') > 0 )) {
                    component.set("v.submitPhantomOrder",true); 
                }
              
            } else {
                component.set("v.content","Do you really want to Submit this Order?");
                component.set("v.sObjectInfoClone.Internal_Order_Stage__c",'Pending Validation');
                component.set("v.showcancel",true);
                component.set("v.showok",true); 
                if(component.get("v.sObjectInfoClone.Type") == 'Revenue' && !$A.util.isEmpty(component.get("v.sObjectInfoClone.Line_Types__c")) && (component.get("v.sObjectInfoClone.Line_Types__c").includes('Upgrade') > 0 || component.get("v.sObjectInfoClone.Line_Types__c").includes('Conversion') > 0 )) {
                    
                    component.set("v.submitPhantomOrder",true); 
                    
                }
            }
        } 
    },
 serversidesave : function(component, event, helper, sobjectrec){
    component.set("v.spinner", true); 
    var action = component.get("c.saveOrderRecord");
    var actionItemsList = [];
    if (component.get("v.submitPhantomOrder") && sobjectrec.Associated_Order_Numbers__c != null) {
        actionItemsList.push('SubmitPhantomOrder');
    }
    action.setParams({ orderRec : sobjectrec, actionItems : actionItemsList});
    action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === "ERROR") {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Cannot update the record",
                "duration": 10000,
                "type": "error",
                "message": response.getReturnValue()
            });
            toastEvent.fire(); 
            $A.get("e.force:closeQuickAction").fire(); 
        }else if (state === "SUCCESS"){
            component.set("v.spinner", false); 
            var str = response.getReturnValue();
                if(str.includes('Exception occurred')){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Cannot update the record",
                                "duration": 10000,
                                "type": "error",
                        "message": response.getReturnValue()
                    });
                    toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();  
                }
                else{

            		helper.gotoRec(component,component.get("v.sObjectInfoClone.Id"));
                    
                }
        }
        
    });
    // Send action off to be executed
    $A.enqueueAction(action);
    },
    getAllOrdersJS : function(component, event, helper){
	var distiname =  $A.get("$Label.c.Shipping_Distributor_Name");
	var distitype = 'PO PDF';
	var linename = 'SHIPPING';
	var queryforPoItems = '';
	var queryForQuoteLines = ''; 
    var queryPOIs;

    
	if(component.get("v.sObjectInfoClone.Stage_PO__c")!=null )
	queryforPoItems =  'SELECT Id,Stage_PO__r.TotalAmount__c,ProductCode__c,UnitPrice__c,Stage_PO__c,Stage_PO__r.EDI_DISTI_ID__c,Stage_PO__r.Distributor_Name__c  FROM PO_Item_Stage__c WHERE ProductCode__c = \''+linename+'\' AND  Stage_PO__r.Distributor_Name__c = \''+distiname+'\' AND Stage_PO__r.EDI_DISTI_ID__c = \''+distitype+'\' AND  Stage_PO__c = \''+component.get("v.sObjectInfoClone.Stage_PO__c")+'\'';
    
		if(component.get("v.sObjectInfoClone.SBQQ__Quote__c")!=null )
    queryForQuoteLines =  'SELECT Id,SBQQ__Product__r.Product_Subtype__c,SBQQ__Product__r.License_Category__c  ,SBQQ__Product__r.Product_Level__c ,SBQQ__Product__r.Product_Type__c, SBQQ__Product__r.Name,SBQQ__RequiredBy__c,SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,SBQQ__Quote__r.SBQQ__Opportunity2__c,SBQQ__Quote__r.SBQQ__Opportunity2__r.Opportunity_Sub_Type__c,SBQQ__Quantity__c,SBQQ__NetTotal__c,Wrapper_Line__c,SBQQ__Optional__c,SBQQ__Existing__c,SBQQ__EffectiveQuantity__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = \''+component.get("v.sObjectInfoClone.SBQQ__Quote__c")+'\'';
    
	    
    var query= 'SELECT Internal_Order_Stage__c,Status,Order_Status__c,Is_RWD_Polaris_Quote__c,SBQQ__Quote__c,SBQQ__Quote__r.Co_Term__c,Stage_PO__c,Stage_PO__r.EDI_DISTI_ID__c,Stage_PO__r.Distributor_Name__c, Stage_PO__r.Bill_To_Name__c,Bill_To_Name__c,Stage_PO__r.TotalAmount__c,TotalAmount, Change_Needed_Reason_Other__c,Additional_Terms_Agreement_Confirmed__c,Additional_Terms_Agreement_Required__c,Type,SBQQ__Quote__r.SBQQ__PaymentTerms__c,Bill_To_Name__r.Payment_Term__c,NetSuite_Order__c, (SELECT id,List_Total__c,Quantity, Sales_Price__c, UnitPrice,SBQQ__QuoteLine__r.Product_Code__c,Product2.Name ,Product2.Product_Subtype__c ,Product2.Product_Type__c , SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__ExpirationDate__c,SBQQ__QuoteLine__r.SBQQ__Quantity__c, SBQQ__QuoteLine__r.SBQQ__Quote__r.ProcessType__c,   Order.Type,Order.Order_Sub_Type__c,OrderId,OrderItemNumber, SerialNumber__c,SBQQ__QuoteLine__c, SBQQ__QuoteLine__r.SBQQ__Product__c,SBQQ__QuoteLine__r.SBQQ__RequiredBy__c,SBQQ__QuoteLine__r.SBQQ__Product__r.Name,SBQQ__QuoteLine__r.Subscribed_Asset_Name__c,Product2.Product_Level__c,Product2.Family,Product2.License_Type__c,SBQQ__SubscriptionTerm__c,product2.SBQQ__SubscriptionPricing__c, Support_Start_Date__c, Support_End_Date__c, SBQQ__QuoteLine__r.SBQQ__NetPrice__c, SBQQ__QuoteLine__r.Name,SBQQ__RequiredBy__c,SBQQ__RequiredBy__r.SBQQ__QuoteLine__c,SBQQ__RequiredBy__r.Quantity,SBQQ__RequiredBy__r.product2.name,SBQQ__RequiredBy__r.OrderitemNumber,SBQQ__QuoteLine__r.SBQQ__ProductOption__r.SBQQ__ConfiguredSKU__r.Product_Type__c,SBQQ__QuoteLine__r.SBQQ__ProductOption__r.SBQQ__ConfiguredSKU__r.Appliance_Model__c,SBQQ__QuoteLine__r.SBQQ__ProductOption__r.SBQQ__ConfiguredSKU__r.Item_Type__c,SBQQ__QuoteLine__r.Required_By_Product_Code__c,Required_by_Product_Code__c,Order.Sell_to_Partner__c,Product2.License_Category__c,Order.Sell_to_Partner__r.Name,Product2.Eligible_for_RCDM_T__c,TotalPrice,Program__c,Order.is_Amendment_Order__c, TPH_Models_Gen__c,TPH_OEM__c  from Orderitems  ORDER BY Support_Start_Date__c ASC NULLS LAST) FROM Order WHERE OpportunityId = \''+component.get("v.sObjectInfoClone.OpportunityId")+'\'';
    if(component.get("v.sObjectInfoClone.SBQQ__Quote__c" ))
       query = query+ ' OR SBQQ__Quote__c = \''+component.get("v.sObjectInfoClone.SBQQ__Quote__c")+'\'';

    if(!component.get("v.sObjectInfoClone.OpportunityId") )
    query= 'SELECT Internal_Order_Stage__c,Is_RWD_Polaris_Quote__c,Stage_PO__c, SBQQ__Quote__c,SBQQ__Quote__r.Co_Term__c,Stage_PO__r.EDI_DISTI_ID__c,Stage_PO__r.Distributor_Name__c,Stage_PO__r.Bill_To_Name__c,Bill_To_Name__c,Stage_PO__r.TotalAmount__c,TotalAmount, Change_Needed_Reason_Other__c,Additional_Terms_Agreement_Confirmed__c,Additional_Terms_Agreement_Required__c,Type, NetSuite_Order__c, Order_Status__c, (SELECT id,List_Total__c,Quantity, Sales_Price__c,product2.Product_Subtype__c,product2.License_Category__c, UnitPrice,SBQQ__QuoteLine__r.SBQQ__Quantity__c,SBQQ__QuoteLine__r.Product_Code__c,Product2.Name  ,Product2.Product_Type__c , SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__ExpirationDate__c,Order.Type,Order.Order_Sub_Type__c,OrderId,OrderItemNumber, SerialNumber__c,SBQQ__QuoteLine__c,SBQQ__QuoteLine__r.SBQQ__Product__c,SBQQ__QuoteLine__r.SBQQ__RequiredBy__c,SBQQ__QuoteLine__r.SBQQ__Product__r.Name,SBQQ__QuoteLine__r.SBQQ__Quote__r.ProcessType__c,  SBQQ__QuoteLine__r.Subscribed_Asset_Name__c,Product2.Product_Level__c,Product2.Family,Product2.License_Type__c,SBQQ__SubscriptionTerm__c,product2.SBQQ__SubscriptionPricing__c, Support_Start_Date__c, Support_End_Date__c, SBQQ__QuoteLine__r.SBQQ__NetPrice__c, SBQQ__QuoteLine__r.Name,SBQQ__RequiredBy__c,SBQQ__RequiredBy__r.SBQQ__QuoteLine__c,SBQQ__RequiredBy__r.Quantity,SBQQ__RequiredBy__r.product2.name,SBQQ__RequiredBy__r.OrderitemNumber,SBQQ__QuoteLine__r.SBQQ__ProductOption__r.SBQQ__ConfiguredSKU__r.Product_Type__c,SBQQ__QuoteLine__r.SBQQ__ProductOption__r.SBQQ__ConfiguredSKU__r.Appliance_Model__c,SBQQ__QuoteLine__r.SBQQ__ProductOption__r.SBQQ__ConfiguredSKU__r.Item_Type__c, SBQQ__QuoteLine__r.Required_By_Product_Code__c,Required_by_Product_Code__c, Order.Sell_to_Partner__r.Name, Product2.Eligible_for_RCDM_T__c,Program__c,Order.is_Amendment_Order__c,TPH_Models_Gen__c,TPH_OEM__c  from Orderitems ORDER BY Support_Start_Date__c ASC NULLS LAST) FROM Order WHERE id = \''+component.get("v.sObjectInfoClone.Id")+'\'';

    if(component.get("v.sObjectInfoClone.SBQQ__Quote__c") != null && component.get("v.sObjectInfoClone.SBQQ__Quote__c") != undefined){
        queryPOIs = 'SELECT Id,Quantity__c,UnitPrice__c,Quote_Line__c,Stage_PO__r.Bill_To_Name__c,Product__r.Product_Payment_Option__c From PO_Item_Stage__c Where Stage_PO__r.Quote__c = \''+component.get("v.sObjectInfoClone.SBQQ__Quote__c")+'\' AND (Stage_PO__r.PO_Validation_Status__c = \'Success\' OR Stage_PO__r.PO_Validation_Status__c = \'Success - 855 Sent\' OR Stage_PO__r.PO_Validation_Status__c = \'Order Accepted - 855 Sent\' OR Stage_PO__r.PO_Validation_Status__c = \'Order Accepted\') AND Stage_PO__r.PO_Internal_Validation_Status__c = \'Success\'';
    }
    var queryOrderControlMdt = 'Select Id,Value__c From Order_control__mdt Where DeveloperName = \'Disable_Quantity_And_Price_Validation\' LIMIT 1';
    var queryDistiMappingMdt = 'Select Id,Sfdc_Id__c, Po_Disti_Type__c From Sfdc_Disti_Mapping__mdt where Po_Disti_Type__c = \'INGRAM\'';
        
        var action = component.get("c.executeAllQuery");     
        
        action.setParams({
           "theQuery": {
                "orderwithorderitems": query,
                "poitems": queryforPoItems,
		"quotelines" : queryForQuoteLines,
        "queryPOIs" : queryPOIs,
        "queryOrderControlMdt" : queryOrderControlMdt,
        "queryDistiMappingMdt" : queryDistiMappingMdt
  
            }
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") { 
                var OrderInternalStage;
                var isBillToNameSame = true;
                var isOrderAndPOAmountSame = true;
                var allOrders = response.getReturnValue();
                var isAdditionalTermFlag = false;
                var orderItemRecord = [];
                var stagePo = '';
		var coterm = false;
		var stagePOAmount = 0.0;
                var orderAmount = 0.0;
                var differenceAmount = 0;
    		var thresholdAmount = component.get("v.thresholdAmount");
            var quotelines;
            var polines;
            var DisableQuantityAndPriceValidation;
		if(allOrders.hasOwnProperty('orderwithorderitems')){
            
	    	let newvalues = allOrders.orderwithorderitems;
            newvalues.forEach(function(ord) {
                component.set("v.orderObjInfo", ord);
		//Added for PRDOPS24-841 
                if(ord.Id == component.get("v.sObjectInfoClone.Id")){
                   component.set("v.sObjectInfoClone.Order_Status__c",ord.Order_Status__c);
                   component.set("v.sObjectInfoClone.Status",ord.Status); 
                 }
                
                if(ord.Id == component.get("v.sObjectInfoClone.Id") && ord.Stage_PO__c != null && stagePo != null && stagePo != undefined){
                    stagePo = ord.Stage_PO__c;      
                }
                if(ord.Type == 'Revenue' && !ord.Additional_Terms_Agreement_Confirmed__c && ord.Additional_Terms_Agreement_Required__c){
                    isAdditionalTermFlag = true;
                }
            });

                newvalues.forEach(function(ord) { 
                    
                    if(ord.Id ==  component.get("v.sObjectInfoClone.Id")) {
			let orderLines = ord.OrderItems;
			var allQli = [];    
			orderLines.forEach(function(oli) {
			allQli.push(oli.SBQQ__QuoteLine__c); 
			});                    
			component.set("v.allQli",allQli)

                        orderItemRecord = ord.OrderItems;
                        if(ord.Stage_PO__c != null && ord.Stage_PO__r.Bill_To_Name__c != ord.Bill_To_Name__c ) {
                            isBillToNameSame = false;
                        }
                    }
                    if(ord.Id == component.get("v.sObjectInfoClone.Id") && ord.Stage_PO__c != null && stagePo != null && stagePo != undefined){
                        stagePo = ord.Stage_PO__c;      
                        stagePOAmount = ord.Stage_PO__r.TotalAmount__c;                        
                    }
		    
		   if(ord.SBQQ__Quote__c!=null && ord.SBQQ__Quote__r.Co_Term__c == true){
			    coterm = true;
		     }		
			
		   
			
			
                    if(ord.Stage_PO__c != null && stagePo == ord.Stage_PO__c){
                        orderAmount += ord.TotalAmount;
                    }
                    if(ord.Is_RWD_Polaris_Quote__c == true && ord.Internal_Order_Stage__c == 'Required' && OrderInternalStage != 'Required') {
                        OrderInternalStage = 'Required';
                        return false;
                    }
                    
                });

                differenceAmount = (stagePOAmount-orderAmount)<0? (stagePOAmount-orderAmount) * -1 : (stagePOAmount-orderAmount);
                
                if(stagePOAmount != orderAmount && (differenceAmount > thresholdAmount)) {
                        isOrderAndPOAmountSame = false;
                }
                component.set("v.sObjectInfoOrderItem", orderItemRecord);
                component.set("v.isBillToNameSame", isBillToNameSame);
		component.set("v.iscoterm", coterm);
    		component.set("v.isOrderAndPOAmountSame", isOrderAndPOAmountSame);
                component.set("v.OrderInternalStage", OrderInternalStage);
                component.set("v.isAdditionalTermFlag", isAdditionalTermFlag);

		}
		if(allOrders.hasOwnProperty('poitems')){
		let poitems = allOrders.poitems;
		if(poitems.length > 0){
		console.log('check the flag' + component.get("v.isOrderAndPOAmountSame"));
		console.log('data is #### ' + JSON.stringify(poitems));    
		var stagepoamount = poitems[0].Stage_PO__r.TotalAmount__c -poitems[0].UnitPrice__c;
		console.log('stagepoamount is #### ' + stagepoamount);
		var ordamount = component.get("v.sObjectInfoClone").TotalAmount;
		console.log('ordamount #### ' + JSON.stringify(ordamount));
		if(stagepoamount==ordamount){
		console.log('amount is same');
		component.set("v.isOrderAndPOAmountSame",true);
		}
		}


		}
		if(allOrders.hasOwnProperty('quotelines')){
		quotelines = allOrders.quotelines;
		var mpatest = component.get("v.mapqli");
		var mapOfLicenceWithAllLinesSU = component.get("v.mapOfLicenceWithAllLinesSU");
		var mapOfHrdwareWithAccessoriesAndLines = component.get("v.mapOfHrdwareWithAccessoriesAndLines");
		var allChildOfRSVXLineJsonPrepare = {};
		var collectAllParentChildOnQuote = component.get("v.collectAllParentChildOnQuote");
	
		quotelines.forEach(function(qli) {

		if(qli.SBQQ__Product__r.Name == component.get("v.rcdmattr")){
		mpatest[qli.SBQQ__RequiredBy__c] = qli.Id;
		}
		/*
  		* Setting the Variables From Quote and Quote Line 
    		* and maintain parent child relationship in variables 
      		* between OND,RSV,RSVX and Hardware Support as part of CSU-62- Prashant
  		*/
		if(qli.SBQQ__Quote__r.SBQQ__Opportunity2__r.Opportunity_Sub_Type__c == 'GC Offer'){
                    var rsv = (qli.SBQQ__Product__r.Product_Subtype__c == 'Scale MSP' && qli.SBQQ__Product__r.License_Category__c == 'SaaS');
                    var ond = (qli.SBQQ__Product__r.Product_Subtype__c == 'On Demand' && qli.SBQQ__Product__r.License_Category__c == 'SaaS');
                    var hardwareLine = (qli.SBQQ__Product__r.Product_Level__c == 'Hardware' && (qli.SBQQ__Product__r.Product_Type__c == 'Add-On Node' || qli.SBQQ__Product__r.Product_Type__c == 'Hardware'));
                    var hwSupport = (qli.SBQQ__Product__r.Product_Level__c == 'Support'  && qli.SBQQ__Product__r.Product_Type__c == 'HW Support');
                    var accessory =  (qli.SBQQ__Product__r.Product_Level__c == 'Hardware' && qli.SBQQ__Product__r.Product_Type__c == 'Accessories');   
                    //SBQQ__Product__r.Product_Subtype__c,SBQQ__Product__r.License_Category__c 
                    if(qli.SBQQ__RequiredBy__c!=null && (rsv || ond ||  hardwareLine)){
                        // if(ond){
                        if(!allChildOfRSVXLineJsonPrepare.hasOwnProperty(qli.SBQQ__RequiredBy__c)){
                            allChildOfRSVXLineJsonPrepare[qli.SBQQ__RequiredBy__c] = {};
                            allChildOfRSVXLineJsonPrepare[qli.SBQQ__RequiredBy__c]['OnDemand'] = [];
                            allChildOfRSVXLineJsonPrepare[qli.SBQQ__RequiredBy__c]['RSV'] = [];
                            allChildOfRSVXLineJsonPrepare[qli.SBQQ__RequiredBy__c]['Hardware'] = [];
                            allChildOfRSVXLineJsonPrepare[qli.SBQQ__RequiredBy__c]['HwSupport'] = [];
                            allChildOfRSVXLineJsonPrepare[qli.SBQQ__RequiredBy__c]['Accessory'] = [];
                        }
                        if(ond){
                            allChildOfRSVXLineJsonPrepare[qli.SBQQ__RequiredBy__c]['OnDemand'].push(qli.Id);
                        }

                        if(rsv){
                            allChildOfRSVXLineJsonPrepare[qli.SBQQ__RequiredBy__c]['RSV'].push(qli.Id);
                        }


                        if(hardwareLine){
                            allChildOfRSVXLineJsonPrepare[qli.SBQQ__RequiredBy__c]['Hardware'].push(qli.Id);

                        }


                        //}
                        console.log('RSV and RSVX logic is completed');
                        mapOfLicenceWithAllLinesSU[qli.Id] = qli.SBQQ__RequiredBy__c;
                    }


                    if(qli.SBQQ__RequiredBy__c!=null && (hwSupport || accessory)){
                        console.log('check for accessory and hwsupport logic');
                        if(!allChildOfRSVXLineJsonPrepare.hasOwnProperty(qli.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c)){
                            allChildOfRSVXLineJsonPrepare[qli.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c] = {};
                            allChildOfRSVXLineJsonPrepare[qli.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c]['OnDemand'] = [];
                            allChildOfRSVXLineJsonPrepare[qli.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c]['RSV'] = [];
                            allChildOfRSVXLineJsonPrepare[qli.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c]['Hardware'] = [];
                            allChildOfRSVXLineJsonPrepare[qli.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c]['HwSupport'] = [];
                            allChildOfRSVXLineJsonPrepare[qli.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c]['Accessory'] = [];
                        }
                        // console.log('Qli  for Hw sku ' + JSON.stringify(qli));

                        if(hwSupport){
                            allChildOfRSVXLineJsonPrepare[qli.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c]['HwSupport'].push(qli.Id);
                        }

                        if(accessory){
                            console.log('accessory logic');
                            allChildOfRSVXLineJsonPrepare[qli.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c]['Accessory'].push(qli.Id);
                        }

                        if(qli.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c!=null)
                            mapOfLicenceWithAllLinesSU[qli.Id] = qli.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c;
                        mapOfHrdwareWithAccessoriesAndLines[qli.Id] = qli.SBQQ__RequiredBy__c;
                    }

                } 

			
		}); 
		component.set("v.mapqli",mpatest);
		console.log('map is ' + JSON.stringify(mpatest));
		component.set("v.mapOfLicenceWithAllLinesSU",mapOfLicenceWithAllLinesSU);
		component.set("v.collectAllParentChildOnQuote",allChildOfRSVXLineJsonPrepare);
		component.set("v.mapOfHrdwareWithAccessoriesAndLines",mapOfHrdwareWithAccessoriesAndLines);
	

		}
        if(allOrders.hasOwnProperty('queryPOIs')){
            polines = allOrders.queryPOIs;
        }
        if(allOrders.hasOwnProperty('queryOrderControlMdt')){
            DisableQuantityAndPriceValidation = allOrders.queryOrderControlMdt[0].Value__c;
        }      

                helper.handlesaveOrder(component, event, helper);
		helper.ScaleUtilityValidation(component, event, helper); // CSU-62-Prashant
        let orderSubType = component.get("v.sObjectInfoClone.Order_Sub_Type__c");
        if(!JSON.parse(DisableQuantityAndPriceValidation.toLowerCase()) && orderSubType !='GC Offer' && orderSubType != 'MSP Overage'){
            helper.validateLineItemsQuantAndPrice(component,quotelines,polines, allOrders.orderwithorderitems, allOrders.queryDistiMappingMdt);
        }
    
            }else{
                var errors = response.getError();
                if(errors){
                    if(errors[0] && errors[0].message) {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "duration": 10000,
                            "type": "error",
                            "message": errors[0].message
                        });
                        toastEvent.fire();
                    }                       
                }                  
            }
        });
        $A.enqueueAction(action);
    },


         getYearQuarterInteger : function(dateValue) {
        if (!dateValue) {
            return null; // Handle null or undefined date values
        }
        
        let dateObj = new Date(dateValue);
        let month = dateObj.getMonth() + 1; // getMonth() returns 0-11
        let year = dateObj.getFullYear();
        let quarterNum;
        
        if (month >= 2 && month <= 4) {
            quarterNum = 1;
        } else if (month >= 5 && month <= 7) {
            quarterNum = 2;
        } else if (month >= 8 && month <= 10) {
            quarterNum = 3;
        }else { // month == 11 || 12 || 1
            quarterNum = 4;
            if (month == 1) {
                year -= 1; // January belongs to previous fiscal year
            }
        }   
        return (year * 10) + quarterNum;
    },

         evaluateCRSDStatus: function(component) {
    // Get current date in Pacific Time (Los Angeles)
    let pacificTimeString = new Date().toLocaleString("en-US", { timeZone: "America/Los_Angeles" });
    let pacificDate = new Date(pacificTimeString);

    // Format today's date as YYYY-MM-DD
    let currentYear = pacificDate.getFullYear();
    let currentMonth = ("0" + (pacificDate.getMonth() + 1)).slice(-2);
    let currentDay = ("0" + pacificDate.getDate()).slice(-2);
    let todayFormatted = `${currentYear}-${currentMonth}-${currentDay}`;

    // Retrieve data from component
    let customerRequiredShipDate = component.get("v.sObjectInfoClone.customer_required_ship_date__c");
    let orderSubType = component.get("v.sObjectInfoClone.Order_Sub_Type__c");
    let orderItemList = component.get("v.sObjectInfoOrderItem");

    // Validate inputs and compare CRSD to renewal start date
    if (
        customerRequiredShipDate &&
        orderItemList.length > 0 &&
        orderItemList[0].Support_Start_Date__c &&
        (orderSubType === "Renewal" || orderSubType === "GC Renewal") &&
        customerRequiredShipDate > orderItemList[0].Support_Start_Date__c
    ) {
        return "CRSD after renewal start date";

    } else if (
        customerRequiredShipDate &&
        this.getYearQuarterInteger(customerRequiredShipDate) > this.getYearQuarterInteger(todayFormatted)
    ) {
        return "CRSD is in future quarter";

    } else {
        return null;
    }
},

    getThresholdAmount : function(component, event, helper){
        var recordName = 'Threshold_Value';
        var recordRcdm = 'RS_BT_RCDM_T';
        var query= 'SELECT id,Threshold_Value__c,DeveloperName FROM EDI_Pricing_Difference_Threshold__mdt WHERE DeveloperName = \''+recordName+'\'';
        var queryrcdm = 'SELECT id,DeveloperName,Product_Name__c FROM X0_RCDM_Dates__mdt WHERE DeveloperName = \''+recordRcdm+'\'';
        var action = component.get("c.executeAllQuery");        
        action.setParams({
                            "theQuery": {
                    "threshhold": query,
                    "rcdm": queryrcdm
                }

           // "theQuery": query
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {                
                var thresholdAmount = 0;
                var allRecords = response.getReturnValue();
                console.log('all records ' + JSON.stringify(allRecords));
                if(allRecords.hasOwnProperty('threshhold')){

				let values = allRecords.threshhold;
                 console.log('values are ####' + JSON.stringify(values));   
					values.forEach(function(record) {
                    thresholdAmount = record.Threshold_Value__c;
                });
                component.set("v.thresholdAmount", thresholdAmount); 
                this.getAllOrdersJS(component, event, helper); 
                }
                
                if(allRecords.hasOwnProperty('rcdm')){
                    var rcdmvar = allRecords.rcdm;
                    console.log('prod name is #### ' + rcdmvar[0].Product_Name__c);
                    component.set("v.rcdmattr",rcdmvar[0].Product_Name__c);

                    console.log('all records in rcdm logic  ' + JSON.stringify(allRecords.rcdm));

                }
                
                }else{
                var errors = response.getError();
                if(errors){
                    if(errors[0] && errors[0].message) {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "duration": 10000,
                            "type": "error",
                            "message": errors[0].message
                        });
                        toastEvent.fire();
                    }                       
                }                  
            }
            });
        $A.enqueueAction(action);
    },

    gotoRec : function(component, recId){
        $A.get("e.force:closeQuickAction").fire();
        var workspaceAPI = component.find("workspace");
        workspaceAPI.isConsoleNavigation().then(function(isConsole) {
            if (isConsole) {
                var workspaceAPI = component.find("workspace");
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    var focusedTabId = response.tabId;
                    workspaceAPI.refreshTab({
                        tabId: focusedTabId
                    });
                })
                .catch(function(error) {
                    $A.get('e.force:refreshView').fire();
                });
                
            } else {
                $A.get('e.force:refreshView').fire();
            }
        })
        .catch(function(error) {
            $A.get('e.force:refreshView').fire();
        });
        
    },
    validateLineItemsQuantAndPrice: function(component, quotelines, polines, allOrderWithOrderItems, DistiMappingMdt) {
        var qlisOIMap = new Map();
        var qliPOIsMap = new Map();
        var orderItems = [];
        var threshold = component.get("v.thresholdAmount");
        var distiMetadataMap = new Map();  
        var isRCDM_Eol_Past=false;
        
        if(!$A.util.isEmpty(component.get("v.sObjectInfoClone.Quote_RCDM_T_EOL_Date__c")) && 
            component.get("v.sObjectInfoClone.Quote_RCDM_T_EOL_Date__c") < $A.localizationService.formatDate(new Date(), "YYYY-MM-DD") &&
            component.get("v.sObjectInfoClone.Type") == 'Revenue' &&
            $A.util.isEmpty(component.get("v.sObjectInfoClone.Order_Sub_Type__c"))){
            isRCDM_Eol_Past= true;
        }

        if(Array.isArray(allOrderWithOrderItems) && allOrderWithOrderItems.length > 0) {
            allOrderWithOrderItems.forEach(function(ord) {
                let orderLines = ord.OrderItems;
                orderLines.forEach(function(oli) {
                    orderItems.push(oli); 
                });     
            })
        }
        if(Array.isArray(DistiMappingMdt) && DistiMappingMdt.length > 0) {
            for (let i of DistiMappingMdt) {
                if(i.Sfdc_Id__c != undefined){
                    distiMetadataMap.set(i.Sfdc_Id__c,i);
                }
            }
        }
        if(Array.isArray(orderItems) && orderItems.length > 0) {
            for (let item of orderItems) {
                if (item.SBQQ__QuoteLine__c !== undefined) {
                    let key = item.SBQQ__QuoteLine__c;
                    if (!qlisOIMap.has(key)) {
                        qlisOIMap.set(key, { quantity: item.Quantity, totalPrice: item.TotalPrice });
                    } else {
                        let existingItem = qlisOIMap.get(key);
                        existingItem.quantity += item.Quantity;
                        existingItem.totalPrice += item.TotalPrice;
                        qlisOIMap.set(key, { quantity: existingItem.quantity, totalPrice: existingItem.totalPrice });
                    }
                }
            }
        }
        if(Array.isArray(polines) && polines.length > 0) {
            for (let line of polines) {
                let billtoName = '';

                if(line && line.Stage_PO__r && line.Stage_PO__r.Bill_To_Name__c){
                    billtoName = line.Stage_PO__r.Bill_To_Name__c;
                }
                if (line.Quote_Line__c !== undefined) {
                    let key = line.Quote_Line__c;
                    let byPassValidation = false;

                    if(distiMetadataMap.has(billtoName) && line && line.Product__r && line.Product__r.Product_Payment_Option__c && line.Product__r.Product_Payment_Option__c == 'Annual'){
                        byPassValidation = true;
                    }
                    if (!qliPOIsMap.has(key)) {
                        qliPOIsMap.set(key, { quantity: line.Quantity__c, totalPrice: line.UnitPrice__c * line.Quantity__c, byPassVal: byPassValidation});
                    } else {
                        let existingLine = qliPOIsMap.get(key);
                        existingLine.quantity += line.Quantity__c;
                        existingLine.totalPrice += line.UnitPrice__c * line.Quantity__c;
                        qliPOIsMap.set(key, { quantity: existingLine.quantity, totalPrice: existingLine.totalPrice, byPassVal: byPassValidation});
                    }
                }
            }
        }
        if(Array.isArray(quotelines) && quotelines.length > 0){    
            for(let i of quotelines){
                
                var errorMsg = [];
                var errormessage;
                var OIQuantity = (qlisOIMap.has(i.Id) ? qlisOIMap.get(i.Id).quantity : 0);
                var OITotalPrice = (qlisOIMap.has(i.Id) ? qlisOIMap.get(i.Id).totalPrice : 0);
                var POIQuantity = (qliPOIsMap.has(i.Id) ? qliPOIsMap.get(i.Id).quantity : 0);
                var POITotalPrice = (qliPOIsMap.has(i.Id) ? qliPOIsMap.get(i.Id).totalPrice : 0);
                var byPassVal = false;
                
                

                if(qliPOIsMap.has(i.Id)) {
                    byPassVal = qliPOIsMap.get(i.Id).byPassVal;
                }

                if(((i.Wrapper_Line__c != undefined && i.Wrapper_Line__c) || (i.SBQQ__Optional__c != undefined && i.SBQQ__Optional__c)) || (i.SBQQ__Existing__c != undefined && i.SBQQ__Existing__c && i.SBQQ__EffectiveQuantity__c != undefined && i.SBQQ__EffectiveQuantity__c == 0)) continue;
                if(i.SBQQ__Quantity__c && (OIQuantity != i.SBQQ__Quantity__c || (!byPassVal && qliPOIsMap.size > 0 && OIQuantity != POIQuantity)) && (!isRCDM_Eol_Past || (isRCDM_Eol_Past && i.SBQQ__Product__r.Name != component.get("v.rcdmattr") ))){

                    errorMsg.push('Quantity mismatch at the line level');
                }           
                if((i.SBQQ__NetTotal__c) && (Math.abs(OITotalPrice - i.SBQQ__NetTotal__c) >= threshold || (qliPOIsMap.size > 0 && Math.abs(OITotalPrice - POITotalPrice) >= threshold))){
                    errorMsg.push('Price mismatch at the line level');
                }
                errormessage = errorMsg.join(', ');
                if(!$A.util.isEmpty(errormessage)){
                    console.log('### i.Id',i.Id);
                    console.log('### OIQuantity',OIQuantity);
                    console.log('### OITotalPrice',OITotalPrice);
                    console.log('### POIQuantity',POIQuantity);
                    console.log('### POITotalPrice',POITotalPrice);
                    console.log('### i.SBQQ__Quantity__c',i.SBQQ__Quantity__c);
                    console.log('### i.SBQQ__NetTotal__c',i.SBQQ__NetTotal__c);
                    component.set("v.content",errormessage); 
                    component.set("v.showcancel",true);
                }
            }
        }
    }
})