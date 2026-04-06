({
    queryOrders: function (component, filterCondition, callback) {
        // var query = "SELECT Id, OrderNumber, SBQQ__Quote__c, Order_Status__c, Order_Sub_Type__c, Actual_Order_Ship_Date__c, Have_Polaris_Products__c, OpportunityId, Is_RWD_Polaris_Quote__c, (SELECT Id, OrderItemNumber, Product_Name__c, Product2.Product_Type__c, Product2.Product_Level__c, Product2.Family, Product2.Bundle_Features__c, Product2.License_Type__c, Product2.Product_Subtype__c  ,SBQQ__SegmentIndex__c, Product2.MSP_Std_Actual__c, SBQQ__QuoteLine__c FROM OrderItems) FROM Order WHERE " + filterCondition + " = LAST_N_DAYS:60";
        var query = "SELECT Id, OrderNumber, Type, SBQQ__Quote__c, Order_Status__c, Order_Sub_Type__c, Actual_Order_Ship_Date__c, Have_Polaris_Products__c, OpportunityId, Is_RWD_Polaris_Quote__c, Opportunity.Opportunity_Sub_Type__c, SBQQ__Quote__r.OpportunitySubType__c, (SELECT Id, OrderItemNumber, Product_Name__c, Product2.Product_Type__c, Product2.Product_Level__c, Product2.Family, Product2.Bundle_Features__c, Product2.License_Type__c,Product2.Product_Subtype__c, SBQQ__SegmentIndex__c, Product2.MSP_Std_Actual__c, SBQQ__QuoteLine__c FROM OrderItems) FROM Order WHERE " + filterCondition + " = LAST_N_DAYS:10"; 
        // var query = "SELECT Id, OrderNumber, SBQQ__Quote__c, Order_Status__c, Order_Sub_Type__c, Actual_Order_Ship_Date__c, Have_Polaris_Products__c, OpportunityId, Is_RWD_Polaris_Quote__c, (SELECT Id, OrderItemNumber, Product_Name__c, Product2.Product_Type__c, Product2.Product_Level__c, Product2.Family, Product2.Bundle_Features__c, Product2.License_Type__c, Product2.Product_Subtype__c  ,SBQQ__SegmentIndex__c, Product2.MSP_Std_Actual__c, SBQQ__QuoteLine__c FROM OrderItems) FROM Order LIMIT 100";
        var toggleValue = filterCondition;
        var action = component.get("c.executeQuery");
        action.setParams({
            "theQuery": query
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var responseValue = response.getReturnValue();
                console.log("responseValue:", responseValue);
                // var orderIds = '';
                var orderIds = [];
                var quoteIds = [];
                var opptyIds = [];
                for (var i in responseValue) {
                    orderIds.push(responseValue[i].Id);
                    if (responseValue[i].SBQQ__Quote__c != undefined) {
                        quoteIds.push(responseValue[i].SBQQ__Quote__c);
                    }
                    if (responseValue[i].OpportunityId != undefined) {
                        opptyIds.push(responseValue[i].OpportunityId);
                    }
                }
                console.log('quoteIds:>>' + quoteIds);
                console.log('opptyIds:>>' + opptyIds);
                callback(responseValue, orderIds, quoteIds, opptyIds, toggleValue);
            }
        });
        $A.enqueueAction(action);
    },

    collection: function (component, helper, responseValue, toggleValue) {
        var oiIds = [];
        for (var i in responseValue) {
            for (var j in responseValue[i].OrderItems) {
                oiIds.push(responseValue[i].OrderItems[j].Id);
            }
        }
        var quoteIds = component.get("v.quoteId");
        var opptyIds = component.get("v.opptyId");
        console.log('quoteIds is' + quoteIds);
        console.log('opptyIds is' + opptyIds);

        var queryQuoteWithQLIs = 'Select Id,(select Id,SBQQ__Product__r.name from SBQQ__LineItems__r ) from SBQQ__Quote__c where ID IN  (\'' + quoteIds.join('\',\'') + '\')';
        var queryOpptyWithLines = 'Select Id,SBQQ__PrimaryQuote__c,(select Id,product2.name from OpportunityLineItems) from opportunity  where SBQQ__PrimaryQuote__c IN  (\'' + quoteIds.join('\',\'') + '\')';
        var entOI = 'Select Id, Name, Order_Product_Name__c, Order_Service_Item__r.Id, Order_Service_Item__r.OrderItemNumber, (SELECT Id FROM Scale_Entitlements__r) From Entitlement Where Order_Service_Item__r.Id IN (\'' + oiIds.join('\',\'') + '\')';
        var qliOppProdsOIs = 'SELECT Id, Name, SBQQ__Quote__r.SBQQ__Opportunity2__c, SBQQ__Product__r.ProductCode, (SELECT Id, product2.name FROM SBQQ__OrderProducts__r), (Select Id, Product2.Name from SBQQ__OpportunityProducts__r) FROM SBQQ__QuoteLine__c Where SBQQ__Quote__r.SBQQ__Opportunity2__c IN (\'' + opptyIds.join('\',\'') + '\')';
        var quoteIds = [];

        var action = component.get("c.executeAllQuery");
        action.setParams({
            "theQuery": {
                "theQuoteQuery": queryQuoteWithQLIs,
                "theOpptyQuery": queryOpptyWithLines,
                "theEntOI": entOI,
                "theqliOppProdsOIs": qliOppProdsOIs
            }
        });
        action.setCallback(this, function (allResponse) {
            var state = allResponse.getState();
            if (state === 'SUCCESS') {
                var alldata = allResponse.getReturnValue();
                console.log('alldata new val: ', JSON.stringify(alldata.theqliOppProdsOIs));
                helper.validation(component, helper, responseValue, alldata, toggleValue);
            }
        });
        $A.enqueueAction(action);
    },

    validation: function (component, helper, responseValue, allData, toggleValue) {
        console.log('allData in Validation method : ', allData);
        var quoteDt = {};
        var opptyDt = {};
        var entOIMap = new Map();
        var lstOrdersDisplay = [];
        var qliOppProdsOIsMap = new Map();

        opptyDt = component.get("v.opptyData");
        quoteDt = component.get("v.quoteData");
        console.log('all Data >>> ' + JSON.stringify(allData));

        if (allData.hasOwnProperty('theQuoteQuery')) {
            for (var key in allData.theQuoteQuery) {
                console.log('Id is  ' + JSON.stringify(allData.theQuoteQuery[key].Id));
                quoteDt[allData.theQuoteQuery[key].Id] = allData.theQuoteQuery[key].SBQQ__LineItems__r;
            }
        }
        if (allData.hasOwnProperty('theOpptyQuery')) {
            for (var key in allData.theOpptyQuery) {
                opptyDt[allData.theOpptyQuery[key].SBQQ__PrimaryQuote__c] = allData.theOpptyQuery[key].OpportunityLineItems;
                // console.log('opptyDt[allData.theOpptyQuery[key].SBQQ__PrimaryQuote__c]: ',opptyDt[allData.theOpptyQuery[key].SBQQ__PrimaryQuote__c].length);
            }
        }
        if (allData.hasOwnProperty('theEntOI')) {
            for (var key in allData.theEntOI) {
                entOIMap.set(allData.theEntOI[key].Order_Service_Item__c, allData.theEntOI[key]);
                console.log('entOIMap Values check: ' + JSON.stringify(entOIMap.get(allData.theEntOI[key].Order_Service_Item__c)));
            }
        }
        if (allData.hasOwnProperty('theqliOppProdsOIs')) {
            for (var key in allData.theqliOppProdsOIs) {
                console.log('theqliOppProdsOIs key: ', key, 'Value: ', allData.theqliOppProdsOIs[key]);
                qliOppProdsOIsMap.set(allData.theqliOppProdsOIs[key].SBQQ__Quote__r.SBQQ__Opportunity2__c, allData.theqliOppProdsOIs[key]);
            }
        }
        console.log('quoteDt : ', JSON.stringify(quoteDt));
        console.log('opptyDt : ', JSON.stringify(opptyDt));

        for (var i in responseValue) {
            var hasPolProdMissing = false;
            var temp = { order: '', orderError: [] };
            temp.order = responseValue[i];
            var orderErrList = [];
            var hasErr = false;

            // Product mismatch validation 
            if (qliOppProdsOIsMap.get(responseValue[i].OpportunityId)) {

                var oProdSize = qliOppProdsOIsMap.get(responseValue[i].OpportunityId).SBQQ__OrderProducts__r == undefined ? 0 : qliOppProdsOIsMap.get(responseValue[i].OpportunityId).SBQQ__OrderProducts__r.length;
                var oppProdSize = qliOppProdsOIsMap.get(responseValue[i].OpportunityId).SBQQ__OpportunityProducts__r == undefined ? 0 : qliOppProdsOIsMap.get(responseValue[i].OpportunityId).SBQQ__OpportunityProducts__r.length;
                console.log('oProdSize: ' + oProdSize, 'oppProdSize: ' + oppProdSize);

                if (oppProdSize > 0 && oProdSize == 0) {
                    var tempRecord = qliOppProdsOIsMap.get(responseValue[i].OpportunityId);
                    var newtemp = { Name: '', type: '', objRecord: tempRecord };
                    newtemp.Name = 'Product is missing';
                    orderErrList.push(newtemp);
                }
            }

            var myArrayOIs = responseValue[i].OrderItems;
            var myArrayOrderItems = [];
            console.log('hasPolProdMissing 1: '+hasPolProdMissing);
            for (var j in myArrayOIs) {
                console.log('hasPolProdMissing 2: '+hasPolProdMissing+ 'OI #: '+myArrayOIs[j].OrderItemNumber);
                // Validation for Polaris product 
                if (!hasPolProdMissing && (!responseValue[i].Have_Polaris_Products__c) && (responseValue[i].Order_Sub_Type__c != 'MSP Overage' && (myArrayOIs[j].Product2.Product_Type__c == 'EDGE' ||
                    (!responseValue[i].Is_RWD_Polaris_Quote__c &&
                        ((myArrayOIs[j].Product2.Family == 'POLARIS' ||
                            (myArrayOIs[j].Product2.Bundle_Features__c != null &&
                                (myArrayOIs[j].Product2.Bundle_Features__c.includes('Polaris') ||
                                    myArrayOIs[j].Product2.Bundle_Features__c.includes('Cloud Native Protection') ||
                                    myArrayOIs[j].Product2.Bundle_Features__c.includes('SAP HANA'))) ||
                            (myArrayOIs[j].Product2.License_Type__c == 'Perpetual' && myArrayOIs[j].Product2.Product_Type__c == 'RCDM')))
                    ) ||
                    (responseValue[i].Is_RWD_Polaris_Quote__c &&
                        (myArrayOIs[j].Product2.Product_Level__c == 'Hybrid Software' || (myArrayOIs[j].Product2.Product_Level__c == 'OnPrem' && (myArrayOIs[j].Product2.Product_Type__c == 'Foundation Edition' || myArrayOIs[j].Product2.Product_Type__c == 'Enterprise Edition' || myArrayOIs[j].Product2.Product_Type__c == 'Business Edition') && myArrayOIs[j].Product2.Product_Subtype__c == null) || myArrayOIs[j].Product2.Product_Level__c == 'SaaS Software Addon' ||
                            myArrayOIs[j].Product2.Product_Level__c == 'Standalone Software Addon' || myArrayOIs[j].Product2.Product_Level__c == 'LOD Software' ||
                            myArrayOIs[j].Product2.Product_Type__c == 'On Prem CDM')))
                )) {
                    console.log('OI#>> '+myArrayOIs[j].OrderItemNumber+ 
                                ' Is RWD Polaris Quote c: '+responseValue[i].Is_RWD_Polaris_Quote__c+ 
                                ' Product2.Product_Level__c: '+myArrayOIs[j].Product2.Product_Level__c+
                                ' Product2.Product_Type__c: '+myArrayOIs[j].Product2.Product_Type__c+
                                ' Product2.product_subtype__c: '+ myArrayOIs[j].Product2.Product_Subtype__c);
      
                    hasPolProdMissing = true;
                }

                var tempOI = { orderItem: '', orderItemError: [] };
                tempOI.orderItem = myArrayOIs[j];
                var oiErr = [];
                const THIRD_PARTY_HARDWARE = new Set(['DELL', 'UCS', 'HPE']);

                // Validation for Manufacturing Entitlement
                if (toggleValue === 'Actual_Order_Ship_Date__c' && ((myArrayOIs[j].Product2.Product_Type__c == '3rd Party Hardware' && THIRD_PARTY_HARDWARE.has(myArrayOIs[j].Product2.Family)) ||
                    ((myArrayOIs[j].Product2.Product_Type__c == 'RCDM' || myArrayOIs[j].Product2.Product_Level__c == 'Hybrid Software' || (myArrayOIs[j].Product2.Product_Level__c == 'OnPrem' || $A.util.isEmpty(myArrayOIs[j].Product2.Product_Level__c))) && myArrayOIs[j].Product2.Family == 'Rubrik Scale') || (myArrayOIs[j].Product2.Family == 'Third Party License') ||
                    (myArrayOIs[j].Product2.Product_Type__c == 'MSP' && myArrayOIs[j].Product2.Family == 'RCDM' && myArrayOIs[j].SBQQ__SegmentIndex__c == 1 && myArrayOIs[j].Product2.MSP_Std_Actual__c != 'MSP Actual & Overage')) && (!entOIMap.has(myArrayOIs[j].Id))) {
                    oiErr.push('Manufacturing Entitlement is Missing');
                }

                // Validation for linked asstes missing.
                console.log('entOIMap values: ', JSON.stringify([...entOIMap]));
                if (toggleValue === 'Actual_Order_Ship_Date__c' && responseValue[i].Type == 'Revenue' && (((myArrayOIs[j].Product2.Product_Level__c == 'LOD Software' || myArrayOIs[j].Product2.Product_Level__c == 'Hybrid Software' || (myArrayOIs[j].Product2.Product_Level__c == 'OnPrem' && (myArrayOIs[j].Product2.Product_Type__c == 'Foundation Edition' || myArrayOIs[j].Product2.Product_Type__c == 'Business Edition' || myArrayOIs[j].Product2.Product_Type__c == 'Enterprise Edition'))) && responseValue[i].Is_RWD_Polaris_Quote__c == true)) && (entOIMap.get(myArrayOIs[j].Id) && entOIMap.get(myArrayOIs[j].Id).Scale_Entitlements__r == undefined)) {
                    console.log('inside new condition: ');
                    var newtemp = {objRecord: entOIMap.get(myArrayOIs[j].Id)};
                    oiErr.push(newtemp);
                }

                if (oiErr.length > 0) hasErr = true;

                tempOI.orderItemError = oiErr;
                console.log('order item full', tempOI);
                myArrayOrderItems.push(tempOI);
            }
            console.log('hasPolProdMissing 3: '+hasPolProdMissing);
            // Polarish missing error adding for order  
            if (hasPolProdMissing) {
                var newtemp = { Name: 'Have Polaris Product is False', type: 'This order has polaris products but Have_Polaris_Products__c is False' };
                // newtemp.Name = 'Have Polaris Product is False';
                // newtemp.type = 'This order has polaris products but Have_Polaris_Products__c is False';
                orderErrList.push(newtemp)
            }

            // Opportunity subType and Quote subType Error
            var opptySubType = responseValue[i].Opportunity && responseValue[i].Opportunity.Opportunity_Sub_Type__c ? responseValue[i].Opportunity.Opportunity_Sub_Type__c : 'none';
            var quoteSubType = responseValue[i].SBQQ__Quote__r && responseValue[i].SBQQ__Quote__r.OpportunitySubType__c ? responseValue[i].SBQQ__Quote__r.OpportunitySubType__c : 'none';

            if (opptySubType == 'Renewal' && quoteSubType != 'Renewal') {
                var newtemp = { Name: 'Quote - Opportunity Subtype Mismatch', type: 'Quote Subtype - '+quoteSubType+ '\n Opportunity Subtype - '+opptySubType };
                orderErrList.push(newtemp);
            }

            if (orderErrList.length > 0) hasErr = true;

            temp.orderError = orderErrList;
            var tempFullDetails = { Order: '', OrderItems: [], hasError: hasErr };
            tempFullDetails.Order = temp;
            tempFullDetails.OrderItems = myArrayOrderItems;
            lstOrdersDisplay.push(tempFullDetails);
        }
        console.log('lstOrdersDisplay: ', lstOrdersDisplay);
        component.set("v.lstErroredOrders", lstOrdersDisplay);
    }
})