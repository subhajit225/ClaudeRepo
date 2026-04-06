({
	onchangevalue : function(component, event, helper) {
		var baseUrl = helper.fetchBaseUrl(component , event);
		var taskRec = component.get('v.pstask');
		if(taskRec.Task_Status__c == 'Open' && !taskRec.Special_Handling_Instructions__c && taskRec.Task_Type__c == 'Migration'){
		    var vfOrigin = baseUrl; 
		    window.postMessage('refresh', vfOrigin);
		}
	},
	onUpdateInstructions : function(component, event, helper) {
		var baseUrl = helper.fetchBaseUrl(component , event);
		var taskRec = component.get('v.pstask');
		if(taskRec.Task_Status__c == 'Open' && taskRec.Task_Type__c == 'Migration'){
		    var vfOrigin = baseUrl; 
		    window.postMessage('refresh', vfOrigin);
		}
	}
})