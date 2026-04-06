({
	helperMethod : function() {

    },
    searchRecordsBySearchPhrase : function(component, event, helper) {
        let lst = [];
        let allData = component.get("v.allContacts");
        let searchPhrase = component.get("v.searchPhrase");
        let newlist = [];

        if (searchPhrase && searchPhrase.length > 0) {
            searchPhrase = searchPhrase.toLowerCase();

            for (let i = 0; i < allData.length; i++) {
                if (allData[i].con.FirstName != null && allData[i].con.FirstName.toLowerCase().includes(searchPhrase)) {
                    newlist.push(allData[i]);
                } else if (allData[i].con.LastName.toLowerCase().includes(searchPhrase)) {
                    newlist.push(allData[i]);
                } else if (allData[i].con.Email.toLowerCase().includes(searchPhrase)) {
                    newlist.push(allData[i]);
                }
            }
            component.set("v.Conlist", newlist);
            var afterresult = component.get("v.Conlist");
        }
     },

    fieldValue: function(object, fieldPath) {
        var result = object;
        fieldPath.forEach(function(field) {
            if(result) {
                result = result[field];
            }
        });
        return result;
    },
    sortHelper : function(component, event, sortFieldName){
        //alert('Test--2')
        var currentDir = component.get("v.arrowDirection");

        if (currentDir == 'arrowdown') {
            // set the arrowDirection attribute for conditionally rendred arrow sign
            component.set("v.arrowDirection", 'arrowup');
            // set the isAsc flag to true for sort in Assending order.
            component.set("v.isAsc", true);
        } else {
            component.set("v.arrowDirection", 'arrowdown');
            component.set("v.isAsc", false);
        }
        // call the onLoad function for call server side method with pass sortFieldName
        this.onLoad(component, event, sortFieldName);

    },
    onLoad : function(component, event, sortField)
    {
        var action = component.get("c.fetchContact");
        action.setParams({
            'sortField': sortField,
            'isAsc': component.get("v.isAsc"),
            'CaseId':component.get("v.CaseId")
        });
        action.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            if (state === "SUCCESS") {
                //set response value in Conlist attribute on component.
               component.set("v.Conlist",response.getReturnValue());
		
	}
        });
        $A.enqueueAction(action);
    }
})