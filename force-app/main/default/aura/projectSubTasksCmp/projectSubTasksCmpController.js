({
	doInit : function(component, event, helper) {
        component.set("v.disableNext",true);
        component.set("v.counter",3);
        var curr = new Date; // get current date
        var first = curr.getDate() - curr.getDay(); // First day is the day of the month - the day of the week
        var last = first + 6; // last day is the first day + 6
        
        var firstday = new Date(curr.setDate(first));
        var lastday = new Date(curr.setDate(last));
        component.set("v.firstday",firstday);
        component.set("v.lastday",lastday);
        var datearr = [];
        for(var i=0; i<7; i++){
            var date1 = new Date(firstday);
            date1.setDate(date1.getDate()+i);
            var datestr = date1.getMonth()+1;
            datestr = datestr+'/'+date1.getDate();
            datearr.push(datestr);
        }

        component.set("v.datearr",datearr);
        helper.helperdoInit(component, event,firstday,lastday);
	},
    handleSave : function(component, event, helper) {
        helper.helpersave(component, event, helper);
	},
    handleNext : function(component, event, helper) {
        component.set("v.Message","");
        var counter = component.get("v.counter");
        counter++;
        component.set("v.counter",counter);
        component.set("v.disablePrev",false);
        if(counter >=3){
            component.set("v.disableNext",true);
        }
        var firstday = component.get("v.firstday");
        var lastday = component.get("v.lastday");
        var newfirst = new Date(firstday);
        var newlast = new Date(lastday);
        newfirst.setDate(newfirst.getDate()+7);
        newlast.setDate(newlast.getDate()+7);
        component.set("v.firstday",newfirst);
        component.set("v.lastday",newlast);
        var datearr = [];
        for(var i=0; i<7; i++){
            var date1 = new Date(newfirst);
            date1.setDate(date1.getDate()+i);
            var datestr = date1.getMonth()+1;
            datestr = datestr+'/'+date1.getDate();
            datearr.push(datestr);
        }

        component.set("v.datearr",datearr);
        helper.helperdoInit(component, event,newfirst,newlast);
	},
    handlePrevious : function(component, event, helper) {
        component.set("v.Message","");
        var counter = component.get("v.counter");
        counter--;
        component.set("v.counter",counter);
        component.set("v.disableNext",false);
        if(counter ==1){
            component.set("v.disablePrev",true);
        }
        var firstday = component.get("v.firstday");
        var lastday = component.get("v.lastday");
        var newfirst = new Date(firstday);
        var newlast = new Date(lastday);
        newfirst.setDate(newfirst.getDate()-7);
        newlast.setDate(newlast.getDate()-7);
        component.set("v.firstday",newfirst);
        component.set("v.lastday",newlast);
        var datearr = [];
        for(var i=0; i<7; i++){
            var date1 = new Date(newfirst);
            date1.setDate(date1.getDate()+i);
            var datestr = date1.getMonth()+1;
            datestr = datestr+'/'+date1.getDate();
            datearr.push(datestr);
        }
       
        component.set("v.datearr",datearr);
        helper.helperdoInit(component, event,newfirst,newlast);
	},
    handleCancel : function(component, event, helper) {
        helper.setDates(component, event, helper);
    },
    valuechanged : function(component, event, helper) {
        component.set("v.changed",true);
        component.set("v.Message","");
        var totalhr = 0;
        var mainList = component.get("v.subtasksWrapperList");
        if(mainList != null && mainList.length > 0){
            for(var i=0;i<mainList.length;i++){
                for(var j=0;j<mainList[i].innerWrapperList.length;j++){
                    totalhr = 0;
                    for(var k=0;k<mainList[i].innerWrapperList[j].psoList.length;k++){
                        if(!$A.util.isUndefinedOrNull(mainList[i].innerWrapperList[j].psoList[k].Hours_Spent__c))
                            totalhr = totalhr+parseInt(mainList[i].innerWrapperList[j].psoList[k].Hours_Spent__c);
                    }
                    mainList[i].innerWrapperList[j].totalhours = totalhr.toString();
                }
            }
        }
 		component.set("v.subtasksWrapperList",mainList);
    },
    section : function(component, event, helper) {
        console.log(event);
        var secId = event.currentTarget.dataset.index;
        console.log(secId);
        component.set("v.initialAllopen",false);
        component.set("v.openSecId",secId); 
    },
    callfromParent : function(component, event, helper) {
        var ProjectId = event.getParam("ProjectId");
        console.log('calling from parent '+ProjectId);
        component.set("v.Message","");
        component.set("v.projId",ProjectId);
        component.set("v.initialAllopen",true);
        helper.setDates(component, event, helper);
    }
})