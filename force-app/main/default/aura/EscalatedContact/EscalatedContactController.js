({
    doinit : function(component, event, helper) {
        component.set("v.mycolumns",[
            {fieldName : "Name",label :  "Name"},
            {fieldName : "Title",label :  "Role"},
            {fieldName : "Email",label :  "Email"},
            {fieldName : "Phone",label :  "Phone"}
        ]);
	},
    removeContact : function(component, event, helper){
        var list = component.get("v.contacts");
        var primaryContacts = component.get("v.primaryContacts");
        var index  = event.getSource().get("v.value");
        var contact = list[index];
        list.splice(index,1);
        component.set("v.contacts",list);
        if(!!primaryContacts && primaryContacts.length > 0){
            for(var i in primaryContacts){
                if(contact.Id == primaryContacts[i].con.Id){
                    primaryContacts[i].isSelected = false;
                }
            }
        }
    }
})