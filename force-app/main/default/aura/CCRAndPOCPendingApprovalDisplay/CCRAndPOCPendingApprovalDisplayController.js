({
	getCcrPocRecords : function(component, event, helper) {
        
        helper.setDataTableColumns(component, event);
		helper.getTableData(component, event);
        //helper.onchange(component, event, helper);
	},
    
    getSelectedObjRecords : function(component, event, helper) {
		helper.getTableData(component, event);
        //helper.onchange(component, event, helper);
	},
    onChange : function(component, event, helper) {
        helper.onRecordsPerPagechange(component, event);
    },
    
    onClickFirst : function(component, event, helper) {
        helper.onClickFirst(component, event);
    },
   
    onClickNext : function(component, event, helper) {
        helper.onClickNext(component, event);
    },
    
    onClickPrev : function(component, event, helper) {
        helper.onClickPrev(component, event);
    },
    
    onClickLast : function(component, event, helper) {
        helper.onClickLast(component, event);
    },
    
   
})