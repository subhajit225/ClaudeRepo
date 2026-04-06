({
    rerender: function(component, helper) {
        if(component.get("v.initialAllopen") == false){
        	helper.openSection(component);
        }
        return this.superRerender()
    },

})