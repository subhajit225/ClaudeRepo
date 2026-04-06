({
    /* This method calls backend apex method which fetches records that needs to be shown on table. 
       This is invoked via getMoreOnScroll function.
    */
    getRecordsHelper : function(component, event) {
        return new Promise($A.getCallback(function(resolve, reject) {
        var action = component.get("c.getRecords");
        console.log('in helper');
        var data = component.get("v.drList");
        var dataSize;
        var lastId;
        if(component.get("v.sortedBy") == 'linkName'){
            component.set("v.sortedBy", "Name");
        }
        if(component.get("v.sortedBy") == 'CreatedByName'){
            component.set("v.sortedBy", "Created_by_Contact__r.Name");
        }
        if(component.get("v.sortedBy") == 'reseller'){
            component.set("v.sortedBy", "Partner_Lookup__r.Name");
        } 
        if(component.get('v.flag')  == true){
            component.set('v.flag', false);
            if(component.get("v.drList") != null){
                var dataSize = component.get("v.drList").length;
                if(dataSize > 0 ){
                    component.set("v.sortedByValue", data[dataSize - 1][component.get("v.sortedBy")]);
                }
            } 
            console.log(component.get("v.sortedByValue"));
            action.setParams({"searchText" : component.get("v.searchText"),
                              "returnFields" : component.get("v.returnFieldsinQuery"),
                              "objType" : component.get("v.objTypeinQuery"),
                              "pageSize" : parseInt(component.get("v.pageSize")),
                              "fieldapiName" : component.get("v.sortedBy"),
                              "sortedDirection" : component.get("v.sortedDirection"),
                              "sortedByValue":component.get("v.sortedByValue"),
                              "IdSet" : component.get("v.IdSet")
                             });
           
            action.setCallback(this, function(a) {
                component.set('v.flag', true);
                resolve(a.getReturnValue());
                
            });
            $A.enqueueAction(action);
        }
            
        }));
           
    },
    /* This method is invoked on component load used for fetching records from backend and also initializes scroll event listener for table */
    initData : function (component, event,helper,callFrom) {
        var action = component.get("c.getRecords");
        var self = this;
        component.set('v.flag', false);
        if(component.get("v.sortedBy") == 'linkName'){
                 component.set("v.sortedBy", "Name");
        }
        if(component.get("v.sortedBy") == 'CreatedByName'){
            component.set("v.sortedBy", "Created_by_Contact__r.Name");
        }
        if(component.get("v.sortedBy") == 'reseller'){
            component.set("v.sortedBy", "Partner_Lookup__r.Name");
        }
        console.log('component.get("v.IdSet")'+component.get("v.IdSet"));
        action.setParams({"searchText" : component.get("v.searchText"),
                          "returnFields" : component.get("v.returnFieldsinQuery"),
                          "objType" : component.get("v.objTypeinQuery"),
                          "pageSize" : parseInt(component.get("v.pageSize")),
                          "fieldapiName" : component.get("v.sortedBy"),
                          "sortedDirection" : component.get("v.sortedDirection"),
                          "sortedByValue":component.get("v.sortedByValue"),
                          "IdSet" : component.get("v.IdSet"),
                          "startDate" : component.get("v.startDate"),
                          "endDate" : component.get("v.endDate"),
                          "accIds" : component.get("v.accIds")
                         });
        action.setCallback(this,function(response){
            console.log(response.getState());
            if(response.getState() == "SUCCESS"){
                var path = window.location.href;
                var pathname = helper.pathToSet(component);
                var records = response.getReturnValue();
                records.forEach(function(record){
                    record.linkName = pathname+'/s/dealregdetail?recordId='+record.Id+'&recordName='+record.Name;
                    if("Partner_Lookup__r" in record){
                        record.reseller = record.Partner_Lookup__r.Name;
                    }
                    if("Distributor__r" in record){
                        record.Distributor_Name = record.Distributor__r.Name;
                    }
                    /* Commented as part of PRIT24-780
                    if(record.Registration_Type__c == 'PSNL' && record.Deal_Registration_Status__c == 'Approved'){
                        record.SPIFF_Eligible = true;
                    }else{
                        record.SPIFF_Eligible = false;
                    } */
                    var idarr = component.get("v.IdSet");
                    idarr.push(record.Id);
                    component.set("v.IdSet",idarr);
                }); 
                if(component.get("v.sortedBy") == 'Name'){
                 	component.set("v.sortedBy", "linkName");
            	}
                if(component.get("v.sortedBy") == 'CreatedByName'){
                    component.set("v.sortedBy","Created_by_Contact__r.Name");
                }
                if(component.get("v.sortedBy") == 'reseller'){
                    component.set("v.sortedBy","Partner_Lookup__r.Name");
                }
                if(records.length == 0){
                    component.set("v.disableExportButton",true);
                }else if(records.length > 0){
                    component.set("v.disableExportButton",false);
                }
                component.set('v.drList', records);
                console.log(component.get('v.drList'));
                component.set('v.flag', true);
                if(callFrom == 'doInit'){
                    var action1 = component.get("c.getTotalRecords");
                    action1.setParams({
                        "objType" : component.get("v.objTypeinQuery")
                    });
                    action1.setCallback(this,function(response){
                        if(response.getState() == "SUCCESS"){
                            component.set("v.totalSize",response.getReturnValue());
                            console.log('@@ totalSize '+component.get("v.totalSize"));
                            component.set("v.loadTable",true);
                           
                            var device = $A.get("$Browser.formFactor");
        					if( device == 'DESKTOP'){
                            	//document.getElementById("myDIV").addEventListener("dblclick", getMoreOnScroll);
                               // document.getElementById("myDIV").addEventListener("wheel", getMoreOnScroll);
                                window.addEventListener("scroll", getMoreOnScroll);
                            }else if( device == 'PHONE' || device == 'TABLET' ){
                                document.getElementById("myDIV").addEventListener("touchmove", getMoreOnScroll);
                                //document.getElementById("myDIV").addEventListener('touchend', getMoreOnScroll); 
                            }
                            if((component.get('v.drList') != null && component.get('v.drList').length == component.get('v.totalSize')) || component.get('v.totalSize') == 0){
                            	component.set("v.loadMoreStatus","No more data to show");
                                var device = $A.get("$Browser.formFactor");
        						if(device == 'DESKTOP'){
                                    window.removeEventListener("scroll", getMoreOnScroll);
                                }else if( device == 'PHONE' || device == 'TABLET' ){
                                     document.getElementById("myDIV").removeEventListener("touchmove", getMoreOnScroll);
                                }
                            }else{
                                if(component.get('v.drList') != null && component.get('v.drList').length < component.get('v.pageSize')){
                              		component.set("v.loadMoreStatus","No more data to show");
                                }else{
                                	component.set("v.loadMoreStatus","");
                                }
                            }
                            
                        }
                    });
                    $A.enqueueAction(action1);  
                }else{
                     if((component.get('v.drList') != null && component.get('v.drList').length == component.get('v.totalSize')) || component.get('v.totalSize') == 0){
                         component.set("v.loadMoreStatus","No more data to show");
                         /*var device = $A.get("$Browser.formFactor");
                         if(device == 'DESKTOP'){
                             window.removeEventListener("scroll", getMoreOnScroll);
                         }else if( device == 'PHONE' || device == 'TABLET' ){
                             document.getElementById("myDIV").removeEventListener("touchmove", getMoreOnScroll);
                         }*/
                     }else{
                         if(component.get('v.drList') != null && component.get('v.drList').length < component.get('v.pageSize')){
                             component.set("v.loadMoreStatus","No more data to show");
                         }else{
                             component.set("v.loadMoreStatus","");
                         }
                     }
                }
            }
        });
        $A.enqueueAction(action);
        
        var previousPosition = 0;
        /*This method contains callback of getRecordsHelper helper method. 
        This function is invoked when there is scroll down event is fired on window */
        function getMoreOnScroll(event) {
            var currentPosition = 0;
            var device = $A.get("$Browser.formFactor");
            //console.log(event	);
           
           // console.log(event.path[2].screen.availHeight);
           // alert(document.documentElement.scrollHeight-document.documentElement.clientHeight);
           // alert('scroll '+window.scrollY);
           // if(event.path[7].scrollY > event.path[7].screen.availHeight){
            //alert('@@  scrollY   '+event.path[7].scrollY);
           // alert(event.offsetHeight + event.scrollTop == event.scrollHeight);
                //alert('@@  clientHeight '+document.documentElement.clientHeight);
                // alert('@@  scrollY   '+event.path[7].scrollY);
                 //alert(event.path[7].scrollY-document.documentElement.clientHeight);
            //alert(document.documentElement.scrollHeight-event.path[7].scrollY);
           // }
          /*  if(event != null && event.path.length > 1){
                for(var i=0;i<event.path.length;i++){
                    if(!$A.util.isUndefined(event.path[i].scrollY) && !$A.util.isUndefined(event.path[i].screen.availHeight) && event.path[i].scrollY > event.path[i].screen.availHeight && ((device == 'DESKTOP' && document.documentElement.scrollHeight - document.documentElement.clientHeight <= event.path[i].scrollY)) || (device == 'PHONE' || device == 'TABLET')){
                    	currentPosition = event.path[i].scrollY;
                    }
                }
            }*/
           
             //window.innerHeight+ window.scrollY) >= document.body.offsetHeight
            if(!$A.util.isUndefined(window.scrollY)){
               // if((window.innerHeight+ window.scrollY+20) >= document.body.offsetHeight){
                if((device == 'DESKTOP' && document.documentElement.scrollHeight - document.documentElement.clientHeight <= window.scrollY+200) || ((device == 'PHONE' || device == 'TABLET') )){
                    currentPosition = window.scrollY;
                   
                }
            }
            if(currentPosition > previousPosition){
                 if(component.get('v.flag') ==  true && component.get('v.drList') != null && component.get('v.drList').length < component.get('v.totalSize')){           
                    helper.getRecordsHelper(component, event).then($A.getCallback(function (data) {
                        var records = data;
                        if(data != null && data.length > 0){
							var pathname = helper.pathToSet(component);
                            records.forEach(function(record){
                                record.linkName = pathname+'/s/dealregdetail?recordId='+record.Id+'&recordName='+record.Name;
                                if("Partner_Lookup__r" in record){
                                    record.reseller = record.Partner_Lookup__r.Name;
                                }
                                if("Distributor__r" in record){
                                    record.Distributor_Name = record.Distributor__r.Name;
                                }
                                /* Commented as part of PRIT24-780
                                if(record.Registration_Type__c == 'PSNL' && record.Deal_Registration_Status__c == 'Approved'){
                                    record.SPIFF_Eligible = true;
                                }else{
                                    record.SPIFF_Eligible = false;
                                }*/
                                var idarr = component.get("v.IdSet");
                                idarr.push(record.Id);
                                component.set("v.IdSet",idarr);
                            });
                            if(component.get("v.sortedBy") == 'Name'){
                                component.set("v.sortedBy", "linkName");
                            }
                            var currentData = component.get('v.drList');
                            var newData = currentData.concat(records);
                            component.set('v.drList', newData);
                            if((component.get('v.drList') != null && component.get('v.drList').length == component.get('v.totalSize')) || component.get('v.totalSize') == 0){
                                component.set("v.loadMoreStatus","No more data to show");
                            }else{
                                if(component.get('v.drList') != null && component.get('v.drList').length < component.get('v.pageSize')){
                                 	component.set("v.loadMoreStatus","No more data to show");
                                }else{
                                	component.set("v.loadMoreStatus","");
                                }
                            }
                                                      
                        }else{
                            component.set("v.loadMoreStatus","No more data to show");
                        }
                        
                           component.set('v.flag', true);
                    }));
                    
                } 
            }
            previousPosition = currentPosition;
        }
    },
    
    //PRIT24-489 - start
    getFiscalYearData : function(component, event, helper){
        var action = component.get('c.getFiscalYearData');
        action.setCallback(this,function(response){
            if(response.getState() == "SUCCESS"){
                var data = response.getReturnValue();
                component.set('v.fiscalYearData',data);
                var options = [];
                for(var i=0; i<data.length; i++){
                    
                    options.push({label:data[i].Name, value: data[i].Name});
                }
                console.log('options->'+JSON.stringify(options));
                component.set("v.fiscalYearOptions",options);
            }
        });
        $A.enqueueAction(action);
    },
    //PRIT24-489 - end
       
    /* Used for Navigation to New record creation page of Deal Registration */
    gotoURL : function (component, event, url) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": url,
            "isredirect": false
        });
        urlEvent.fire();
    },
    
    /* This method is used for capturing Community name */
    pathToSet : function (component) {
        var path = window.location.href;
        var pathname = '';
        if(path.indexOf('.com') > 0){
            var patharr1 = path.split('.com');
            if(patharr1[1].indexOf('/s/') > 0){
                var patharr2 = patharr1[1].split('/s/');
                if (typeof patharr2[0] !== 'undefined'){
                	pathname = patharr2[0];
                }
            }
        }
        return pathname;
    },

    convertArrayToCSV : function(component,objectRecords){
        var csvStringResult, counter, keys, columnDivider, lineDivider;
        if(objectRecords == null || !objectRecords.length){
            return;
        }
        columnDivider = ',';
        lineDivider = '\n';
        var userRec = component.get("v.userRecord");
        //PRIT24-584
        if(userRec.Contact.Account.Type.includes("Distributor")){
            keys = ['Company__c','Name','Registration_Type__c','Opportunity__c','Opp_Deal_Registration_Type__c','Deal_Registration_Status__c','Deal_Reg_Submitted_Date__c','Approval_Timestamp__c','Deal_Registration_Expiration__c','Partner_Rep__c','SPIFF_Eligible','reseller','Created_By_Name__c'];
        }else{
            //Removed SPIFF_Eligible as part of PRIT24-780
            keys = ['Company__c','Name','Registration_Type__c','Opportunity__c','Opp_Deal_Registration_Type__c','Deal_Registration_Status__c','Deal_Reg_Submitted_Date__c','Approval_Timestamp__c','Deal_Registration_Expiration__c','Distributor_Name','Created_By_Name__c'];
        }

        csvStringResult = '';
        csvStringResult += keys.join(columnDivider);
        csvStringResult += lineDivider;

        for(var i=0;i<objectRecords.length; i++){
            counter = 0;
            for(var sTempKey in keys){
                var skey = keys[sTempKey];
                if(counter > 0){
                    csvStringResult += columnDivider;
                }
                csvStringResult += '"'+objectRecords[i][skey]+'"';
                counter++;
            }
            csvStringResult += lineDivider;
        }
        return csvStringResult;
    },

    getAllDealsRegistrationForExport : function(component, event, helper){
        var action = component.get("c.getRecords");
        action.setParams({"searchText" : component.get("v.searchText"),
                          "returnFields" : component.get("v.returnFieldsinQuery"),
                          "objType" : component.get("v.objTypeinQuery"),
                          "pageSize" : parseInt(50000),
                          "fieldapiName" : "Name",
                          "sortedDirection" : component.get("v.sortedDirection"),
                          "sortedByValue":component.get("v.sortedByValue"),
                          "IdSet" : component.get("v.IdSet")
                         });
        action.setCallback(this,function(response){
            if(response.getState() == "SUCCESS"){
                var records = response.getReturnValue();
                if(records.length > 0){
                    records.forEach(function(record){
                        if("Partner_Lookup__r" in record){
                            record.reseller = record.Partner_Lookup__r.Name;
                        }
                        if("Distributor__r" in record){
                            record.Distributor_Name = record.Distributor__r.Name;
                        }
                        /* Commented as part of PRIT24-780
                        if(record.Registration_Type__c == 'PSNL' && record.Deal_Registration_Status__c == 'Approved'){
                            record.SPIFF_Eligible = true;
                        }else{
                            record.SPIFF_Eligible = false;
                        }*/
                    });
                    component.set("v.dealRegList",records);
                }
            }
        });
        $A.enqueueAction(action);
    },

    checkPartnerType : function(component, event, helper){
        var action = component.get("c.getPartnerType");
        action.setCallback(this,function(response){
            if(response.getState() == "SUCCESS"){
                var userRec = response.getReturnValue();
                if(userRec != null){
                    component.set("v.userRecord",userRec);
                    if(userRec.Contact.Account.Type.includes("Distributor")){
                        component.set('v.col', [
                            {label: 'End User', fieldName: 'Company__c', type: 'text', sortable : true, cellAttributes: { class: 'custom-column'}},
                            {label: 'Deal Registration Number', fieldName: 'linkName', type: 'url', sortable : true, typeAttributes: {label: { fieldName: 'Name' }, target: '_self'},initialWidth : 150, cellAttributes: { class: 'custom-column deep-blue-child'}},
                            {label: 'Registration Type', fieldName : 'Registration_Type__c', type: 'text', sortable : true, cellAttributes: { class: 'custom-column'}},
                            {label: 'Status', fieldName: 'Deal_Registration_Status__c', type: 'text', sortable : true, cellAttributes: { class: 'custom-column'}},
                            {label: 'Submitted Date', fieldName: 'Deal_Reg_Submitted_Date__c', type: 'date', sortable : true, cellAttributes: { class: 'custom-column'}},
                            {label: 'Approval Date', fieldName: 'Approval_Timestamp__c', type: 'date', sortable : true, cellAttributes: { class: 'custom-column'}},
                            {label: 'Expiration Date', fieldName: 'Deal_Registration_Expiration__c', type: 'date', sortable : true, cellAttributes: { class: 'custom-column'}},
                            {label: 'Partner Rep', fieldName: 'Partner_Rep__c', type: 'text', sortable : true, cellAttributes: { class: 'custom-column'}},
                            // {label: 'PSNL SPIFF Eligible', fieldName: 'SPIFF_Eligible', type: 'boolean', sortable : false, cellAttributes: { class: 'custom-column'}},
                            {label: 'Reseller', fieldName: 'Partner__c', type: 'text', sortable : true, cellAttributes: { class: 'custom-column'}},
                            {label: 'Submitted By', fieldName: 'Created_By_Name__c', type: 'text', sortable : true, cellAttributes: { class: 'custom-column'}},
                            {label: 'Oppty ID', fieldName: 'Opportunity__c', type: 'text', sortable : true, cellAttributes: { class: 'custom-column'}},
                            {label: 'Deal Initiated Type', fieldName: 'Opp_Deal_Registration_Type__c', type: 'text', sortable : true, cellAttributes: { class: 'custom-column'}}
                        ]);
                    }else{
                        component.set('v.col', [
                            {label: 'End User', fieldName: 'Company__c', type: 'text', sortable : true, cellAttributes: { class: 'custom-column'}},
                            {label: 'Deal Registration Number', fieldName: 'linkName', type: 'url', sortable : true, typeAttributes: {label: { fieldName: 'Name' }, target: '_self'},initialWidth : 150, cellAttributes: { class: 'custom-column deep-blue-child'}},
                            {label: 'Registration Type', fieldName : 'Registration_Type__c', type: 'text', sortable : true, cellAttributes: { class: 'custom-column'}},
                            {label: 'Status', fieldName: 'Deal_Registration_Status__c', type: 'text', sortable : true, cellAttributes: { class: 'custom-column'}},
                            {label: 'Submitted Date', fieldName: 'Deal_Reg_Submitted_Date__c', type: 'date', sortable : true, cellAttributes: { class: 'custom-column'}},
                            {label: 'Approval Date', fieldName: 'Approval_Timestamp__c', type: 'date', sortable : true, cellAttributes: { class: 'custom-column'}},
                            {label: 'Expiration Date', fieldName: 'Deal_Registration_Expiration__c', type: 'date', sortable : true, cellAttributes: { class: 'custom-column'}},
                            // {label: 'PSNL SPIFF Eligible', fieldName: 'SPIFF_Eligible', type: 'boolean', sortable : false, cellAttributes: { class: 'custom-column'}},
                            {label: 'Distributor', fieldName: 'Distributor_Name', type: 'text', sortable : true, cellAttributes: { class: 'custom-column'}},
                            {label: 'Submitted By', fieldName: 'Created_By_Name__c', type: 'text', sortable : true, cellAttributes: { class: 'custom-column'}},
                        	{label: 'Oppty ID', fieldName: 'Opportunity__c', type: 'text', sortable : true, cellAttributes: { class: 'custom-column'}},
                            {label: 'Deal Initiated Type', fieldName: 'Opp_Deal_Registration_Type__c', type: 'text', sortable : true, cellAttributes: { class: 'custom-column'}}
                        ]);
                    }
                }
            }
        });
        $A.enqueueAction(action);
    }
})