({
	 doInit : function(component, event, helper) {  
        
		var pageReference = window.location.href;
        console.log('pageReference =',pageReference);
        var url = new URL(pageReference);
        var projectId = url.searchParams.get("projectId");
        component.set("v.projectId", projectId);
        console.log('projectId =',projectId);
        
       var action = component.get("c.getPsTask");
        action.setParams({ 
            "Projid": projectId,
        });
    	action.setCallback(this, function(response){
        	var state = response.getState();
        	if (component.isValid() && state === "SUCCESS") {
				console.log('return = ',response.getReturnValue());
            	component.set("v.data",response.getReturnValue());
                var resultArr = response.getReturnValue();
                console.log(resultArr);
        	}
        });
    	$A.enqueueAction(action);
         
       	var action1 = component.get("c.getAllPsSubTask");
        var totalSubTaskIds = []; 
        action1.setParams({ 
            "Projid": projectId,
        });
    	action1.setCallback(this, function(response){
        	var state = response.getState();
        	if (component.isValid() && state === "SUCCESS") {
				console.log('return = ',response.getReturnValue());
            	component.set("v.TotalsubTaskResults",response.getReturnValue());
                if(response.getReturnValue() != null && response.getReturnValue().length > 0){
                    for(var i=0;i<response.getReturnValue().length;i++){
                        totalSubTaskIds.push(response.getReturnValue()[i].Id);
                    }
                    component.set("v.totalSubTaskIds",totalSubTaskIds);
                }
        	}
        });
    	$A.enqueueAction(action1);  
		
	},
    
    updateColumnSorting: function (cmp, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    },
    
    makeSelection: function(component, event, helper) {
		if(JSON.stringify(component.get("v.selectedLookUpRecords")) === '[]' ||
           JSON.stringify(component.get("v.selection")) === '[]'){
			component.set("v.messageString", "Please select both User and Subtask entries!");
            component.set("v.Message", true);
            component.set("v.isSuccess", false);
			console.log('Inside this block');
            return ;
        }
        console.log('selected Rows',JSON.stringify(component.get("v.selection")));
        console.log('selectedLookUpRecords = ',JSON.stringify(component.get("v.selectedLookUpRecords")));
        var selectedUserId = [];
        component.get("v.selectedLookUpRecords").forEach(function(row){
            selectedUserId.push(row.Id);
        });
		console.log('selectedUserId =',selectedUserId );
        var action = component.get("c.assignSubtasks");
        action.setParams({ 
            "userid": JSON.stringify(selectedUserId),
            "selectedsubtaskid" : JSON.stringify(component.get("v.selection"))
        });
    	action.setCallback(this, function(response){
            console.log('in click item');
            var state = response.getState();
			if (state === "SUCCESS") {
				var resultData = response.getReturnValue();
                component.set("v.Message", true);
                component.set("v.isSuccess", true);
                component.set("v.messageString", 'Users are assigned to Subtasks successfully');
                window.location.href="/"+new URL(window.location.href).searchParams.get("projectId");
                        
                setTimeout(function(){
                	$A.get("e.force:closeQuickAction").fire(); 
                }, 2000);
                        
			}
            else {
				component.set("v.messageString", "Error occured while saving! Please try again");
                component.set("v.Message", true);
                component.set("v.isSuccess", false);
            }
		});
		$A.enqueueAction(action);
    },
    cancel : function(component, event, helper){
        window.location.href='/'+component.get("v.projectId");
    },
     section  : function(component,event,helper){
        var recId = event.target.getAttribute("data-recId");
        component.set("v.selectedtaskId",recId);
        console.log('recId '+recId); 
        var index = parseInt(event.target.getAttribute("data-index"));
        var btn = document.getElementsByClassName(event.target.getAttribute("data-index"));
        if(btn != null){
            for(var i=0;i<btn.length;i++){
                if(btn[i] != null && btn[i].style.display == 'block'){
                   btn[i].style.display = 'none';
               }else if(btn[i] != null && btn[i].style.display == 'none'){
                   btn[i].style.display = 'block';
               }
            }
        }
        var prevIndex = component.get("v.prevrowIndex");
        if(prevIndex !== "" && prevIndex !== index){
            var btn1 = document.getElementsByClassName(prevIndex);
            if(btn1 != null){
                for(var i=0;i<btn1.length;i++){
                    if(btn1[i] != null && btn1[i].style.display == 'block'){
                       btn1[i].style.display = 'none';
                   }else if(btn1[i] != null && btn1[i].style.display == 'none'){
                       btn1[i].style.display = 'block';
                   }
                }
            }
        }
        
        if(index === component.get("v.rowIndex")){
             component.set("v.rowIndex", "");
             component.set("v.prevrowIndex","");
        }else{
            component.set("v.rowIndex", index);
            component.set("v.prevrowIndex",index);
			helper.getSubTasksHelper(component, event, helper);
            
            window.setTimeout(
            $A.getCallback(function() {
                var resultArr = component.get("v.subTaskResults");
                var selectedIdsList = component.get("v.selection");
                console.log(selectedIdsList);
                for(var i = 0; i < resultArr.length; i++){
                    if(selectedIdsList != null && selectedIdsList.includes(resultArr[i].Id)){
                        resultArr[i].Selected = true;
                    }
                }
                component.set("v.subTaskResults",resultArr);
            }), 1000
        );

        
        }
    },
    handleSelect : function(component,event,helper){
       // console.log(event);
        var subTaskResults = component.get("v.subTaskResults");
        var selectedIdsList = component.get("v.selection");
        for(var i =0;i<subTaskResults.length;i++){
            if(!selectedIdsList.includes(subTaskResults[i].Id) && subTaskResults[i].Selected){
                selectedIdsList.push(subTaskResults[i].Id);
            }else if(selectedIdsList.includes(subTaskResults[i].Id) && !subTaskResults[i].Selected){
                var ele = selectedIdsList.indexOf(subTaskResults[i].Id);
                if (ele > -1) {
                  selectedIdsList.splice(ele, 1);
                }
            }
        }
        console.log(selectedIdsList);
        component.set("v.selection",selectedIdsList);

    },
    handleSelectAllInner : function(component,event,helper){
        var checkboxVal = event.getSource().get("v.value");
        var checkname = event.getSource().get("v.name");
        var subTaskResults = component.get("v.subTaskResults");
        var innerchecksArr = component.find("checkId");
        var selectedIdsList = component.get("v.selection");
        if(innerchecksArr != null ){
             for(var i = 0; i < innerchecksArr.length; i++){
                 innerchecksArr[i].set("v.value",checkboxVal);
             }
             if(innerchecksArr[0] == undefined){
                innerchecksArr.set("v.value",checkboxVal);
             }
        }
        for(var i =0;i<subTaskResults.length;i++){
            subTaskResults[i].Selected = checkboxVal;
            if(!selectedIdsList.includes(subTaskResults[i].Id) && checkboxVal){
                selectedIdsList.push(subTaskResults[i].Id);
            }else if(selectedIdsList.includes(subTaskResults[i].Id) && !checkboxVal){
                var ele = selectedIdsList.indexOf(subTaskResults[i].Id);
                if (ele > -1) {
                  selectedIdsList.splice(ele, 1);
                }
            }
        }
        console.log(selectedIdsList);
        component.set("v.selection",selectedIdsList);
        component.set("v.subTaskResults",subTaskResults);
    },
    handlesuperSelectAll : function(component,event,helper){
        var checkboxVal = event.getSource().get("v.value");
        var totalSubs = component.get("v.TotalsubTaskResults");
        var subTaskResults = component.get("v.subTaskResults");
        var mainTasks = component.get("v.data");
        var selectedIdsList = component.get("v.selection");
        
        for(var i=0;i<mainTasks.length;i++){
            mainTasks[i].selectAll = checkboxVal;
        }
		for(var i=0;i<subTaskResults.length;i++){
            subTaskResults[i].Selected = checkboxVal;
        }
        for(var i=0;i<totalSubs.length;i++){
            if(!selectedIdsList.includes(totalSubs[i].Id) && checkboxVal){
                selectedIdsList.push(totalSubs[i].Id);
            }
            if(selectedIdsList.includes(totalSubs[i].Id) && !checkboxVal){
                var ele = selectedIdsList.indexOf(totalSubs[i].Id);
                if (ele > -1) {
                  selectedIdsList.splice(ele, 1);
                }
            }
        }
        console.log(selectedIdsList);
        component.set("v.selection",selectedIdsList);
        component.set("v.data",mainTasks);
        component.set("v.subTaskResults",subTaskResults);
    }
})