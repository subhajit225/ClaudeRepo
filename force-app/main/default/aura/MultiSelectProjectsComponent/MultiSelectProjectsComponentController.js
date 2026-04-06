({
    doinit:function(component, event, helper) { 
        helper.setPickListName(component, component.get("v.selectedOptions"));    
    },
    
    onRender : function(component, event, helper) {
        if(!component.get("v.initializationCompleted")){
            var alreadySelected = false;
            //Attaching document listener to detect clicks
            component.getElement().addEventListener("click", function(event){ 
                    var checkReadOnly = component.get("v.ShowDropdown");

                if(checkReadOnly == true){
                     alreadySelected = true;
                }
                 if(alreadySelected == false){
                    
                    //handle click component
                helper.handleClick(component, event, 'component');
                    //Document listner to detect click outside multi select component 
                    //helper.handleClick(component, event, 'document');
                }
            });
             document.addEventListener("click", function(event){
                 if(alreadySelected == false){
                helper.handleClick(component, event, 'document');
                 } 
            });
            //Marking initializationCompleted property true
             if(alreadySelected == false){
            	component.set("v.initializationCompleted", true);
                 //Set picklist name
                helper.setPickListName(component, component.get("v.selectedOptions"));

             }
            
            
        }
    },
    
    //This function will be called when input box value change
    onInputChange : function(component, event, helper) {
        //get input box's value
        var inputText = event.target.value;
        //Filter options
        helper.filterDropDownValues(component, inputText);
    },
    
    //This will clear any current filters in place
    onClearClick : function(component, event, helper) {
        //clear filter input box
        component.getElement().querySelector('#ms-filter-input').value = '';
        //reset filter
        helper.resetAllFilters(component);
    },
     OnCloseToast:function(component, event, helper) {
        $A.util.removeClass(component.find('errorDiv'), 'slds-hide');
        $A.util.addClass(component.find('errorDiv'), 'slds-hide');
        
        
    },
       handleConfirmDialogYes : function(component, event, helper) {
        console.log('Yes');
        component.set('v.showConfirmDialog', false);
      // helper.onOptionClick(component,component.get('v.option'));
       helper.onOptionClick2(component,component.get('v.option'));
    },
     
    handleConfirmDialogNo : function(component, event, helper) {
        console.log('No');
        component.set('v.showConfirmDialog', false);
        
    }, 
    
})