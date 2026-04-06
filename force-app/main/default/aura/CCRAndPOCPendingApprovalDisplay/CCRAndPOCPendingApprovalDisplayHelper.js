({
	getTableData : function(component, event) {
        this.showSpinner(component);
        component.set("v.ErrorMsg","");
		var action = component.get("c.getCCRAndPOCPendingApprovalList");
        var selectedObjval = component.get("v.selectedObjValue");
        console.log("selectedObjval @@"+selectedObjval);
        action.setParams({ selectedObj : selectedObjval});
		action.setCallback(this, function(response){
            this.hideSpinner(component);
			var state = response.getState();
            console.log("STate " + state);
			if(state === "SUCCESS") {
				//console.log(response.getReturnValue()+"State @@" + JSON.stringify(response.getReturnValue()));
				console.log(response.getReturnValue()+"State @@");
				component.set('v.AllAccountList',response.getReturnValue());
				var recordsPerPage = component.get("v.RecordsPerPage");
				
				var totalRecords = 	(response.getReturnValue() == null) ? 0 : response.getReturnValue().length;
				component.set('v.TotalRecords', totalRecords);
				/*if(totalRecords > 0 ) {
					var totalPages = ((totalRecords % recordsPerPage) == 0 ? (totalRecords / recordsPerPage) : Math.ceil(totalRecords / recordsPerPage) );
					console.log("totalPages@@"+totalPages);
					component.set('v.TotalPages',totalPages);
				}*/
				this.onRecordsPerPagechange(component, event)
			} else if(state === "ERROR") {
				var errors = response.getError();
                if (errors) {
					console.log("Error message: " + errors[0].message);
					component.set("v.ErrorMsg","Error :"+errors[0].message);
				}
			}
		})

		$A.enqueueAction(action);
	},
    
    onRecordsPerPagechange : function(component, event) {
		var paginationList = [];
		var AllAccountList = component.get("v.AllAccountList");
        var totalRecords1 = component.get('v.TotalRecords');
		if( AllAccountList != null && totalRecords1 > 0) {
			var pageSize = component.get("v.RecordsPerPage");
			console.log("@@"+AllAccountList.length);
			/*if(AllAccountList.length < pageSize) {
				pageSize = AllAccountList.length;
			}*/
            var totalRecords = component.get('v.TotalRecords');
            if(totalRecords > 0 ) {
                var totalPages = ((totalRecords % pageSize) == 0 ? (totalRecords / pageSize) : Math.ceil(totalRecords / pageSize) );
                console.log("totalPages@@"+totalPages);
                component.set('v.TotalPages',totalPages);
            }
			console.log("pageSize@@"+pageSize);
			var currentPageNumber = component.get("v.CurrentPageNumber");
			var recordStartIndex = ((currentPageNumber - 1)* pageSize);
			var recordLastIndex = parseInt(recordStartIndex) + parseInt(pageSize);
			if(recordLastIndex > AllAccountList.length) {
                console.log('@@@recordLastIndex @@'+recordLastIndex);
				recordLastIndex = AllAccountList.length;
                console.log('@@@recordLastIndex @@'+recordLastIndex);
			}
			console.log("currentPageNumber@@"+currentPageNumber);
			console.log("recordStartIndex@@"+recordStartIndex);
			console.log("recordLastIndex@@"+recordLastIndex);
			for(var i = recordStartIndex; i < recordLastIndex; i++){
				
				paginationList.push(AllAccountList[i]);
			}
			console.log("PageAccountList@@"+paginationList.length);
			component.set('v.PageAccountList',paginationList);
            
		} else {
			component.set("v.ErrorMsg","No records returned!");
		}
       
	},

	setDataTableColumns : function(component, event) {
        
        //Options for objet select list
        var opts = [
          { value: "All", label: "All" },
          { value: "POC__c", label: "POC" },
          { value: "CCR__c", label: "CCR" }
        ];
        
        component.set("v.options", opts);
		component.set('v.columns', [
            
            {label: 'Action', fieldName: 'reassignLink', type: 'url', typeAttributes: { 
                label: {
                    fieldName: 'reassignLabel'
                },
                target: '_blank'
            }, sortable : false},
            {label: 'Action', fieldName: 'approveRejectLink', type: 'url', typeAttributes: { 
                label: {
                    fieldName: 'actionLabel'
                },
                target: '_blank'
            }, sortable : false},
            {label: 'Record Link', fieldName: 'RecordLink', type: 'url', typeAttributes: { 
                label: {
                    fieldName: 'RecordName'
                },
                target: '_blank'
            }, sortable : false},
            {label: 'Status', fieldName: 'Status', type: 'text', sortable : false},
            {label: 'RecordObject', fieldName: 'RecordObject', type: 'text', sortable : false},
			/*{label: 'Assigned To Name', fieldName: 'AssignedToName', type: 'text', sortable : false},*/
            {label: 'Approver Name', fieldName: 'ApproverName', type: 'text', sortable : false},
            {label: 'CreatedDate', fieldName: 'CreatedDate', type: 'text', sortable : false},
        ]);
        
        
	},
    
	onClickFirst : function(component, event) {
	   if(component.get('v.CurrentPageNumber') != 1 ) {
		  component.set('v.CurrentPageNumber',1);
		  console.log("Clicked First@@");
		  this.onRecordsPerPagechange(component, event);
	   }		
       
    },
	
    onClickNext : function(component, event) {
        if(component.get('v.TotalPages') > 1 
			&& component.get('v.CurrentPageNumber') != component.get('v.TotalPages') ) {
				console.log("Clicked Next@@");
		  var nextPageNum = component.get('v.CurrentPageNumber') + 1;
		  component.set('v.CurrentPageNumber', nextPageNum);
		  this.onRecordsPerPagechange(component, event);
	   }
    },
	
	
    onClickPrev : function(component, event) {
		if(component.get('v.CurrentPageNumber') != 1 ) {
			var nextPageNum = component.get('v.CurrentPageNumber') - 1;
			component.set('v.CurrentPageNumber', nextPageNum);
			console.log("Clicked Prev@@");
			this.onRecordsPerPagechange(component, event);
		 }	
    },
	
    onClickLast : function(component, event) {
		if(component.get('v.TotalPages') > 1 
			&& component.get('v.CurrentPageNumber') != component.get('v.TotalPages') ) {
				console.log("Clicked Last@@");
		  component.set('v.CurrentPageNumber', component.get('v.TotalPages'));
		  this.onRecordsPerPagechange(component, event);
	   }
	},
    
    showSpinner: function(component) {
		var spinnerMain =  component.find("Spinner");
		$A.util.removeClass(spinnerMain, "slds-hide");
	},
 
	hideSpinner : function(component) {
		var spinnerMain =  component.find("Spinner");
		$A.util.addClass(spinnerMain, "slds-hide");
	},
	 
})