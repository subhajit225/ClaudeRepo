({
    doInit : function( component, event, helper ) {
        helper.doInitStartHelper(component);
    },   

    //search option in picklist
    filterOptions : function( component, event, helper ) {
        if( !$A.util.isEmpty(component.get('v.searchString')) ) {
            helper.filterOptionsDataHelper(component);
        } else {
            $A.util.removeClass(component.find('resultsDiv'),'slds-is-open');
        }
    },
    
    // option selected
    selectItem : function( component, event, helper ) {
        if(!$A.util.isEmpty(event.currentTarget.id)) {
            helper.selectOptionHelper(component, event);
        }
    },
    
    showOptions : function( component, event, helper ) {
        var disabled = component.get("v.disabled");
        if(!disabled) {
            component.set("v.message", '');
            component.set('v.searchString', '');
            var options = component.get("v.options");
            if (component.get("v.parsed") == false) {
                JSON.parse(options).forEach( function(element,index) {
                	element.isVisible = true;
            	});
                component.set("v.options", JSON.parse(options));
            	component.set("v.parsed", true);
            }
            else {
                options.forEach( function(element,index) {
                	element.isVisible = true;
            	});
                component.set("v.options", options);
            	component.set("v.parsed", true);
                
            }
            if(!$A.util.isEmpty(component.get('v.options'))) {
                $A.util.addClass(component.find('resultsDiv'),'slds-is-open');
            } 
        }
    },
    
    // To remove the selected item.
    closePill : function( component, event, helper ){
        helper.removeOptionPillHelper(component, event);
    },
    
    // To close the dropdown if clicked outside the dropdown.
    handleBlur : function( component, event, helper ){
        helper.handleBlurHelper(component, event);
    },
    hide : function(component,event,helper){
        //component.set('v.options','');
        component.set('v.value','');
        component.set('v.searchString','');
        var myEvent = $A.get("e.c:SendDataToVFPage");
            myEvent.setParams({
                selectedSKU: component.get("v.value"),
                currentRecId: component.get("v.qlInScope"),
                assetName: component.get("v.assetInScope"),
                sectionName: component.get("v.sectionName")
            });
            myEvent.fire();
        console.log('Event fired-');
    }
})