({
    doInit: function(cmp){
        try{
            var action = cmp.get("c.getfeeds");
            action.setParams({'topicId':cmp.get("v.recordId")});
            action.setCallback(this, function(response){
                console.log('@@@@@  ',response.getReturnValue());
                cmp.set("v.topicList", response.getReturnValue());
            });
            $A.enqueueAction(action);
        }
        catch(err) {
          console.log("Error:  " , err.message );  
        }
    }
})