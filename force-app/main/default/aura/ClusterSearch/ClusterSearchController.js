({
    init : function(component, event, helper) {
        var url_string = window.location.href;
        var url = new URL(url_string);
        var searchString = url.searchParams.get("search");
        console.log(searchString);
        component.set("v.searchKeyword",searchString);
        helper.SearchHelper(component, event);
    },
    
    Search: function(component, event, helper) {
        var searchField = component.find('searchField');
        var isValueMissing = searchField.get('v.validity').valueMissing;
        // if value is missing show error message and focus on field
        if(isValueMissing) {
            searchField.showHelpMessageIfInvalid();
            searchField.focus();
        }else{
          // else call helper function 
            helper.SearchHelper(component, event);
        }
    },
})