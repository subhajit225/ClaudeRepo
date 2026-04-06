({
    selectRecord : function(component, event, helper){      
        //console.log('accounts222'+component.get("v.selectedAccountRecords").length);
        // get the selected record from list 
        console.log('Reusable Lookup Componet selectRecord') ;
        var getSelectRecord = component.get("v.oRecord");
        // call the event   
        var compEvent = component.getEvent("oSelectedRecordEvent");
        // set the Selected sObject Record to the event attribute.  
        compEvent.setParams({"recordByEvent" : getSelectRecord });  
        // fire the event  
        compEvent.fire();
    },
})