({
    //This function will close all multi-select drop down on the page
    closeAllDropDown: function() {
        
        //Close drop down by removing slds class
        Array.from(document.querySelectorAll('#ms-picklist-dropdown')).forEach(function(node){
            node.classList.remove('slds-is-open');
        });
    },
    
    //This function will be called on drop down button click
    onDropDownClick: function(dropDownDiv) {
        
        //Getting classlist from component
        var classList = Array.from(dropDownDiv.classList);
        if(!classList.includes("slds-is-open")){
            //First close all drp down
            this.closeAllDropDown();
            //Open dropdown by adding slds class
            dropDownDiv.classList.add('slds-is-open');
        } else{
            //Close all drp down
            this.closeAllDropDown();
        }
    },
    
    //This function will handle clicks on within and outside the component
    handleClick: function(component, event, where) {
        
        //getting target element of mouse click
        var tempElement = event.target;
        var outsideComponent = true;
        //click indicator
        //1. Drop-Down is clicked
        //2. Option item within dropdown is clicked
        //3. Clicked outside drop-down
        //4. loop through all parent element
        while(tempElement){
            if(tempElement.id === 'ms-list-item'){
                //2. Handle logic when picklist option is clicked
                //Handling option click in helper function
                if(where === 'component'){
                    this.onOptionClick(component, event.target);
                    component.set('v.option', event.target);   
                    //  component.set('v.showConfirmDialog', true);
                }
                
                outsideComponent = false;
                break;
            } else if(tempElement.id === 'ms-dropdown-items'){
                //3. Clicked somewher within dropdown which does not need to be handled
                //Break the loop here
                outsideComponent = false;
                break;
            } else if(tempElement.id === 'ms-picklist-dropdown'){
                //1. Handle logic when dropdown is clicked
                if(where === 'component'){
                    this.onDropDownClick(tempElement);
                }
                outsideComponent = false;
                break;
            }
            
            //get parent node
            tempElement = tempElement.parentNode;
        }
        
        if(outsideComponent){
            this.closeAllDropDown();
        }
    },
    
    //This function will be used to filter options based on input box value
    rebuildPicklist: function(component) {
        
        var allSelectElements = component.getElement().querySelectorAll("li");
        Array.from(allSelectElements).forEach(function(node){
            node.classList.remove('slds-is-selected');
        });
    },
    
    //this function will be used to filter options based on input box value
    filterDropDownValues: function(component, inputText) {
        
        var allSelectElements = component.getElement().querySelectorAll("li");
        Array.from(allSelectElements).forEach(function(node){
            if(!inputText){
                node.style.display = "block";
            }
            else if(node.dataset.name.toString().toLowerCase().indexOf(inputText.toString().trim().toLowerCase()) != -1){
                node.style.display = "block";
            } else{
                node.style.display = "none";
            }
        }); 
    },
    
    //This function clear the filters
    resetAllFilters : function(component) {
        
        this.filterDropDownValues(component, '');
    },
    
    //This function will set text on picklist
    setPickListName : function(component, selectedOptions) {
        
        //Set drop-down name based on selected value
        if(selectedOptions.length < 1){
            component.set("v.selectedLabel", component.get("v.msname"));
            
            
        } else {
            component.set("v.selectedLabel", selectedOptions.length+' project selected');
            
        } 
    },  
    
    /*This function will be called when an option is clicked from the drop down*/
    onOptionClick: function(component, ddOption) {
        //get clicked option id-name pair
        
        var arrayObj = component.get("v.arraList");
        
        var clickedValue = {
            "Id":ddOption.closest("li").getAttribute('data-recId'),
            "Name":ddOption.closest("li").getAttribute('data-name')
            
        };
        
        //Get all selected options
        var selectedOptions = component.get("v.selectedOptions");
        
        //Boolean to indicate if value is alredy present
        
        var alreadySelected = false;
        
        //Looping through all selected option to check if clicked value is already present
        
        selectedOptions.forEach((option,index) => {
            
            if(option.Id === clickedValue.Id){
            
            //Clicked value already present in the set
            //Toast Message start
            
            /*  component.set("v.errorMessage", 'You can\'t unselect a project');
            $A.util.removeClass(component.find('errorDiv'), 'slds-hide');
            window.setTimeout($A.getCallback(function() {
            $A.util.addClass(component.find('errorDiv'), 'slds-hide');
        }), 300000000); */
            
              component.set('v.showConfirmDialog', true);
            
          //  selectedOptions.splice(index, 1);
          //  arrayObj.splice(index, 1);
            //Toast Message End
            
            //remove check mark for the list item
           // ddOption.closest("li").classList.remove('slds-is-selected');
            
            //Make already selected variable true
            alreadySelected = true;
            
        }
                                
                                
                                });
        
        
        //If not already selected, add the element to the list
        if(!alreadySelected){
            // if(confirm('You will lose all unsaved changes. So before selecting a new project, make sure you have saved your time sheet.')){  
            
            selectedOptions.push(clickedValue);
            arrayObj.push(clickedValue.Id);
            //Add check mark for the list item
            ddOption.closest("li").classList.add('slds-is-selected');
            //  }
        }
        
        //Set picklist label
        this.setPickListName(component, selectedOptions);
        var compnentEvent = component.getEvent("SelectChange1"); 
        compnentEvent.setParams({
            "values" : arrayObj
        });  
        
        compnentEvent.fire();
        
    }, 
    onOptionClick2: function(component, ddOption) {
        //get clicked option id-name pair
        
        var arrayObj = component.get("v.arraList");
        
        var clickedValue = {
            "Id":ddOption.closest("li").getAttribute('data-recId'),
            "Name":ddOption.closest("li").getAttribute('data-name')
            
        };
        
        //Get all selected options
        var selectedOptions = component.get("v.selectedOptions");
        
        //Boolean to indicate if value is alredy present
        
        var alreadySelected = false;
        
        //Looping through all selected option to check if clicked value is already present
        
        selectedOptions.forEach((option,index) => {
            
            if(option.Id === clickedValue.Id){
            
            //Clicked value already present in the set
            //Toast Message start
            
            /*  component.set("v.errorMessage", 'You can\'t unselect a project');
            $A.util.removeClass(component.find('errorDiv'), 'slds-hide');
            window.setTimeout($A.getCallback(function() {
            $A.util.addClass(component.find('errorDiv'), 'slds-hide');
        }), 300000000); */
            
          //  component.set('v.showConfirmDialog', true);
            
            selectedOptions.splice(index, 1);
            arrayObj.splice(index, 1);
            //Toast Message End
            
            //remove check mark for the list item
            ddOption.closest("li").classList.remove('slds-is-selected');
            
            //Make already selected variable true
            alreadySelected = true;
            //     
        }
                                
                                });
        
        //If not already selected, add the element to the list
 
        
        //Set picklist label
        this.setPickListName(component, selectedOptions);
        var compnentEvent = component.getEvent("SelectChange1"); 
        compnentEvent.setParams({
            "values" : arrayObj
        });  
        
        compnentEvent.fire();
        
    }, 
    
    onPageLoadOption: function(component, testData) {
        //get clicked option id-name pair
        alert('I should not see this');
        component.set("v.CheckCondition",false);
        var arrayObj = component.get("v.arraList");
        var selectedOptions = [];
        for(var i=0;i<testData.length;i++){
            var clickedValue = {
                "Id":testData[i].project.Id,
                "Name":testData[i].project.Name
            };
            //Get all selected options 
            //If not already selected, add the element to the list
            selectedOptions.push(clickedValue);
            arrayObj.push(clickedValue.Id);  
        }
        //Set picklist label
        this.setPickListName(component, selectedOptions);
    },
    
    
    
})