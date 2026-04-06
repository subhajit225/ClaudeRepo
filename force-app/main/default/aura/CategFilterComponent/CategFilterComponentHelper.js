({
getCategValue : function(component,selected) {
     console.log('enter--') ;
        var custNo = component.get("v.custNo");
        var action = component.get("c.getAllCategoryGroups");   
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('state==' , state );
            if (state === "SUCCESS") {                
                var custs = [];
                var conts = response.getReturnValue();
                var clickedCateg = component.get("v.clickedCateg");

                console.log('dddd==' , conts);
                for ( var key in conts ) {
                    custs.push({value:conts[key], key:key});
                    if( conts[key] == clickedCateg){
                        component.set("v.parentCategory",key);
                    }
                }
                component.set("v.categList", custs);
                
            } 
        });           
        $A.enqueueAction(action); 
    }
   
})