({ 
    doInitStartHelper : function(component) {
        $A.util.toggleClass(component.find('resultsDiv'),'slds-is-open');
        var value = component.get('v.value');
        if( !$A.util.isEmpty(value)) {
            var searchString;
            var count = 0; 
            var options = component.get('v.options');
            options.forEach( function(element, index) {
                if(element.value == value) {
                        searchString = element.label;
                    }
                });
            component.set('v.searchString', searchString);
            component.set('v.options', options);
        }
    },  
    
    filterOptionsDataHelper : function(component) {
        component.set("v.message", '');
        var searchText = component.get('v.searchString');
        var options = component.get("v.options");
        var minChar = component.get('v.minChar');
        if(searchText.length >= minChar) {
            var flag = true;
            options.forEach( function(element,index) {
                if(element.label.toLowerCase().trim().startsWith(searchText.toLowerCase().trim())) {
                    element.isVisible = true;
                    flag = false;
                } else {
                    element.isVisible = false;
                }
            });
            component.set("v.options",options);
            if(flag) {
                component.set("v.message", "No results found for '" + searchText + "'");
            }
        }
        $A.util.addClass(component.find('resultsDiv'),'slds-is-open');
    },
    
    selectOptionHelper : function(component, event) {
        var options = component.get('v.options');
        var searchString = component.get('v.searchString');
        var value;
        var count = 0;
        options.forEach( function(element, index) {
            if(element.value === event.currentTarget.id) {
                value = element.value;
                searchString = element.label;
            }
        });
        component.set('v.value', value);
        component.set('v.options', options);
        var myEvent = $A.get("e.c:SendDataToVFPage");
            myEvent.setParams({
                selectedSKU: value,
                currentRecId: component.get("v.qlInScope"),
                assetName: component.get("v.assetInScope"),
                sectionName: component.get("v.sectionName")
            });
            myEvent.fire();
        component.set('v.searchString', searchString);
        $A.util.removeClass(component.find('resultsDiv'),'slds-is-open');
    },
    
    removeOptionPillHelper : function(component, event) {
        var value = event.getSource().get('v.name');
        var count = 0;
        var options = component.get("v.options");
        component.set("v.options", options);
    },
    
    handleBlurHelper : function(component, event) {
        var selectedValue = component.get('v.value');
        var previousLabel;
        var count = 0;
        var options = component.get("v.options");
        var optionSelected = false;
        options.forEach( function(element, index) {
            if(element.value === selectedValue) {
                previousLabel = element.label;
                optionSelected = true;
                console.log('Inside selected');
            }
        });
        if (optionSelected == true) {
            component.set('v.searchString', previousLabel);
        } else {
            component.set('v.searchString', '');
        }
        
        $A.util.removeClass(component.find('resultsDiv'),'slds-is-open');
    }
})