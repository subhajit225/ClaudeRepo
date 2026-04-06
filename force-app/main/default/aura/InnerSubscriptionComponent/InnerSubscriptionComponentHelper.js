({
    DelRecord : function(component, event, helper ) {
        console.log('enter--') ;
        var recId =event.currentTarget.dataset.index;
        console.log('recId===' , recId);
        var action = component.get("c.DelRecord");
        action.setParams({
            delRec	: recId
        });
        action.setCallback(this, function(response){
            var result= response.getReturnValue();
           
            $A.get('e.force:refreshView').fire();
        });
        
        $A.enqueueAction(action);      
    },
})