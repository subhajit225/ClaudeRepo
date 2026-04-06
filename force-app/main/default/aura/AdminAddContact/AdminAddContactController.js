({
    doInit : function(component, event, helper) {
        component.set("v.ContList", component.get("v.ContListNew"));
    },
    
    savecontact1: function(component, event, helper) {
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
            if (state === "SUCCESS") {
            }
        });
        $A.enqueueAction(action2);*/
    },
    
    addRow: function(component, event, helper) {
        try {
            /*
            const ContList = component.get("v.ContList");
            //Add New Account Record 
            ContList.push({
                'firstName':'',
                'lastName':'',
                'email':'',
                'title': '',
                'phone':'',
                'hasError':false
            });
            component.set("v.ContList", ContList);*/
            var compEvents = $A.get("e.c:AdminContactEvent");// getting the Instance of event
            compEvents.fire();
            
        }
        catch(err) {
        }
    },
    
    removeRow: function(component, event, helper) {
        //Get the Contact list
        var ContList = component.get("v.ContList");
        //Get the target object
        var selectedItem = event.getSource().get("v.title");
        //Get the selected item index
        var index = selectedItem;
        ContList.splice(index, 1);
        component.set("v.ContList", ContList);
    },
    oncheck: function(component, event, helper) {
        
        var crntarget = event.getSource().get('v.checked');
        component.set("v.isChecked", crntarget);
    },
    checkError: function(component, event, helper) {
        var contList=component.get("v.ContList");
        for(var i=0;i<contList.length;i++){
            contList[i].errorMessage='';
        }
        component.set("v.ContList",contList);
    },
})