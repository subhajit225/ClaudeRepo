({
    init : function(component, event, helper) {
        helper.fillColoumn(component);
    },
    Sorttable : function(component, event, helper) {
        var fieldName = event.target.name;
        var sortDirection = event.target.id;
        if(sortDirection == component.get("v.sortedDirection")){
            sortDirection = 'asc';
        }
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        helper.sortData(component, fieldName, sortDirection);
    },
     
    updateUser: function(component, event, helper) {
        /*  var myAttri = component.find("newUserForm");
        //call apex class method
        var action2 = component.get('c.createContact');
        action2.setParams({
            firstName:myAttri[0].get("v.value"),
            lastName:myAttri[1].get("v.value"),
            email:myAttri[2].get("v.value"),
            title:myAttri[3].get("v.value"),
            phone:myAttri[4].get("v.value")
        });
        action2.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            $A.get("e.force:refreshView").fire();
            console.log('response.getState();'+state);
            if (state === "SUCCESS") {
            }
        });
        $A.enqueueAction(action2);*/
     },
    
})