({
    doInit: function(cmp,event,helper){
        try{
            var action = cmp.get("c.getNewArticles");
            action.setCallback(this, function(response){
                console.log('@@@@@  ',response.getReturnValue());
                cmp.set("v.kavList", response.getReturnValue());
                helper.sortData(cmp);
                var action2 = cmp.get("c.getRankedSolutions");
                action2.setCallback(this, function(response2){
                    console.log('####### pop  ',response2.getReturnValue());
                    cmp.set("v.kavList1", response2.getReturnValue());
                    helper.sortDataForPopular(cmp);
                });
                
                $A.enqueueAction(action2);
            });
            $A.enqueueAction(action);
            
            
        }
        catch(err) {
          console.log("Error:  " , err.message );  
        }
    }
})