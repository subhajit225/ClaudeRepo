({
    /* Search event handler which captures value of searched text */
    handlesearchEvent :  function(component, event, helper) {
        var searchEventVal = event.getParam("searchText");
        component.set("v.searchText",searchEventVal);
        component.set("v.drList", []);
        component.set("v.IdSet",[]); 
        component.set("v.sortedByValue",null);
        
        helper.initData(component, event, helper,'');
    },
    
    /* This method is inoked at load of the component. Used for setting columns and fetching records from backend */
    doInit : function(component, event, helper) {
        helper.checkPartnerType(component, event, helper);
        helper.initData(component, event, helper,'doInit');
        helper.getAllDealsRegistrationForExport(component, event, helper);
        //PRIT24-489 - start
        helper.getFiscalYearData(component, event, helper);
        //PRIT24-489 - end
    },
    /* When a field is sorted. It invokes this method which captured field api name of sorted field and its direction*/
     handleColumnSorting : function(component, event, helper) {
		var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
         component.set("v.sortedBy", fieldName);
         if(fieldName == 'linkName'){
             component.set("v.sortedBy", "Name");
         }
        component.set("v.sortedDirection", sortDirection);
        console.log('@@ fieldName '+fieldName+' sortDirection '+sortDirection);  
        component.set("v.drList", []);
        component.set("v.IdSet",[]); 
        component.set("v.sortedByValue",null);
        helper.initData(component, event, helper,'');
	},
    
    /* Navigates to New record creation page of Deal registration */
    openNewDealReg : function (component, event, helper) {
        helper.gotoURL(component, event, "/dealregnew");
    },

    /*Export to Excel*/
    handleExportClick : function (component, event, helper){
        var dealsList = component.get("v.dealRegList");
        if(dealsList != null && dealsList.length > 0){
            var dealsToExport = helper.convertArrayToCSV(component,dealsList);
            if(dealsToExport == null){
                return;
            }
            var hiddenElement = document.createElement('a');
            hiddenElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(dealsToExport);
            hiddenElement.target = '_self';
            hiddenElement.download = 'exportData.csv';
            document.body.appendChild(hiddenElement);
            hiddenElement.click();
        }
    },
    
    //PRIT24-489 - start
    handleFiscalYearChange : function(component, event, helper){
        var selectedOptionValue = event.getParam("value");
        var fiscalData = component.get('v.fiscalYearData');
        for(var i=0; i<fiscalData.length; i++){
            if(fiscalData[i].Name == selectedOptionValue){
                component.set("v.startDate",fiscalData[i].StartDate);
                component.set("v.endDate",fiscalData[i].EndDate);
            }
        }
        component.set("v.IdSet",[]);
        helper.initData(component, event, helper, 'handleFiscalYearChange');
    },
    
    handleAccountFilter : function(component, event, helper){
        var eventValues = event.mp;
        var accIds = [];
        console.log('event map->'+eventValues.length);
        for(let key in eventValues){
            console.log('value->'+eventValues[key]);
            accIds[key] = eventValues[key];
        }
        component.set("v.accIds",accIds);
        component.set("v.IdSet",[]);
        helper.initData(component, event, helper, 'handleAccountFilter');
    },
    handleReset : function(component, event, helper){
        component.set("v.fiscalYear",'');
        component.set("v.accIds",[]);
        component.set("v.searchText",'');
        component.find("accountHierarchy").reset();
        component.set("v.startDate",'');
        component.set("v.endDate",'');
        component.set("v.IdSet",[]);
        
        helper.initData(component, event, helper, 'handleReset');
    },
    //PRIT24-489 - end
    /* Commented as part of PRIT24-780 
    handleSPIFFClaimClick : function(component, event, helper){
        let navService = component.find("navService");
        let pageReference = {
            type: "comm__namedPage",
            attributes: {
                pageName: 'incentives'
            }
        }
        navService.navigate(pageReference);
    } */
})