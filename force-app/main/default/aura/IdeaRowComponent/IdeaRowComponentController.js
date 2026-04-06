({
    handleLike : function(component, event, helper){
        console.log('test==' , event.getSource().getLocalId());
        var currentId = component.get("v.idea").oneidea.Id;
        var type = event.getSource().getLocalId();
        var action = component.get("c.addVote");
        action.setParams({
            parentId : currentId,
            type : type,
            zoneId:component.get("v.commId")
        });
        action.setCallback(component, function(response) {
            var result = response.getReturnValue();
            // console.log('res---' , result);
            component.set("v.idea",result[0]);
        });
        $A.enqueueAction(action);
    }
})