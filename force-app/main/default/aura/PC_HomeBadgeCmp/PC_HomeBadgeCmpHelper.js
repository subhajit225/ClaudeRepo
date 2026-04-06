({
    /*
     * Load the form.
     */
    doInit : function(component, event,helper) {
        helper.getDealRegCount(component, event,helper);
    },
    
    /*
     * Get the Record Type ID.
     */
    getDealRegCount : function(component, event,helper) {
        var params = [];
        helper.callServer(component, "c.getDealRegCount",null,function(response){
            if(!$A.util.isEmpty(response)){
                if(response.dealsRegBadges){
                    component.set("v.dealsRegBadges",response.dealsRegBadges);
                }
                if(response.trainingBadges){
                    component.set("v.trainingBadges",response.trainingBadges); 
                }
                if(response.marketingBadges){
                    component.set("v.marketingBadges",response.marketingBadges);
                }
            }
        },false);
    } ,
})