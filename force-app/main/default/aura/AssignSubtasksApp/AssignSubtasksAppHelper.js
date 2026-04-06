({
	sortData: function (cmp, fieldName, sortDirection) {
        var data = cmp.get("v.subTaskResults");
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse));
        cmp.set("v.subTaskResults", data);
    },
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
            function(x) {return x[field]};
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },
    getSubTasksHelper : function(component, event, helper){
        var action = component.get("c.getPsSubTask");
        action.setParams({ 
            "TaskId": component.get("v.selectedtaskId"),
            "subTaskIds": component.get("v.totalSubTaskIds")
        });
    	action.setCallback(this, function(response){
        	console.log('in click item');
        	var state = response.getState();
        	if (component.isValid() && state === "SUCCESS") {
				console.log('return = ',response.getReturnValue());
                var resultArr = response.getReturnValue();
                console.log(resultArr);
                component.set("v.subTaskResults",resultArr);
        	}
         
    	});
         
    	$A.enqueueAction(action);
    },

})