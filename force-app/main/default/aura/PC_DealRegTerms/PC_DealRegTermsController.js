({
    //PRIT-340 start
    doInit : function(component, event, helper){
        var objId = component.get('v.objectId');
        var objName = component.get('v.objectName');
        //console.log('-objId->' + objId);
        //console.log('-objName->'+ objName);
    },
    //PRIT-340 end
	handleClick : function(component, event, helper) {
        var pageName = event.getSource().get("v.value");
        var url= "/" + pageName;
        //PRIT-340 start
        var objId = component.get('v.objectId');
        var objName = component.get('v.objectName');
        if(objId != null && objName != null){
            if(pageName == 'dealreglist'){
                url = "/" + 'lead-dashboard';
            }else{
                url = url +'?objectId='+objId+'&objectName='+objName;
            }
        }
        //PRIT-340 end
		helper.gotoURL(component, event, url);
	}
})