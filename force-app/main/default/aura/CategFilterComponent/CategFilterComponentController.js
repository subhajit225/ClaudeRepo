({
    doInit : function(component, event, helper) {
        helper.getCategValue(component);
    },
    
    changeCateg : function(component, event, helper){
        var  category = event.target.id; 
       var cat = category;
        console.log('cat---' , cat);
        var typeClicked = document.getElementById(category);
        if(!$A.util.isEmpty(typeClicked)){
            typeClicked.classList.add('activeImages')
            typeClicked.classList.remove('icons')
            
        }
        component.set("v.Selectedcategory", cat);
        var categlistevent = $A.get("e.c:CategFilterEvent");
        categlistevent.setParams({
            "CategFilter" : cat
        });
        categlistevent.fire();
    },
    
    
})