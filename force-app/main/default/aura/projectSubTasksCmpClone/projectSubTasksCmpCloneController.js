({
    doInit : function(component, event, helper) {
        var curr = new Date; // get current date
        var timezoneDiff = curr.getTimezoneOffset();
        curr.setMinutes(curr.getMinutes() - timezoneDiff);
        var first = curr.getDate() - curr.getDay(); // First day is the day of the month - the day of the week
        var last = first + 6; // last day is the first day + 6

        var firstday = new Date(curr.setDate(first));
        firstday.setMinutes(firstday.getMinutes() - timezoneDiff);
        var lastday = new Date(curr.setDate(last));
        lastday.setMinutes(lastday.getMinutes() - timezoneDiff);
        
        if(first < 0){
            lastday = new Date(lastday.setMonth(lastday.getMonth()+1));
        }
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
        /* To set Previous and Next buttons */
        var date = new Date(), y = date.getFullYear(), m = date.getMonth();
        var firstDayMonth = new Date(y, m, 1);
        var lastDayMonth = new Date(y, m + 1, 0);
        component.set("v.firstDayMonth",firstDayMonth);
        component.set("v.lastDayMonth",lastDayMonth);
        /* Previous */
        var firstdayweek = date.getDate() - date.getDay();
        var firstdayweekDay = new Date();
        firstdayweekDay.setDate(firstdayweekDay.getDate()- firstdayweek);
        var lastmonth = m-1;
        if((firstdayweekDay.getMonth() == lastmonth && firstdayweek > 1) || firstdayweek == 1){
            component.set("v.disablePrev",true);
        }else{
            component.set("v.disablePrev",false);
        }

        var lastdayweekDay = new Date();
        lastdayweekDay.setDate(lastdayweekDay.getDate()- firstdayweek);
        lastdayweekDay.setDate(lastdayweekDay.getDate()+6);

        var nextmonth = m+1;
        var lastDayMonth = component.get("v.lastDayMonth");
        if(lastdayweekDay == lastDayMonth || (lastdayweekDay.getMonth() == nextmonth)){
            component.set("v.disableNext",true);
        }else{
            component.set("v.disableNext",false);
        }
        /* Next */
        component.set("v.currentMonth",m);
        /* To set Previous and Next buttons */
    },
    handleSave : function(component, event, helper) {
        helper.helpersave(component, event, helper);
    },
    handleNext : function(component, event, helper) {
        component.set("v.Message","");
        var firstday = component.get("v.firstday");
        var lastday = component.get("v.lastday");
        var newfirst = new Date(firstday);
        var newlast = new Date(lastday);
        newfirst.setDate(newfirst.getDate()+7);
        newlast.setDate(newlast.getDate()+7);
        
        var  m = component.get("v.currentMonth");
        var lastDayMonth = component.get("v.lastDayMonth");
        var lastmonth = m-1;
        var nextmonth = m+1;
        
        var lastdayweekDay = newlast;
        if((lastdayweekDay.getDate() == lastDayMonth.getDate() && lastdayweekDay.getMonth() == lastDayMonth.getMonth())  || (lastdayweekDay.getMonth() == nextmonth)){
            component.set("v.disableNext",true);
            component.set("v.disablePrev",false);
        }else{
            component.set("v.disableNext",false);
            component.set("v.disablePrev",false);
        }        
        
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
        var firstday = component.get("v.firstday");
        var lastday = component.get("v.lastday");
        var newfirst = new Date(firstday);
        var newlast = new Date(lastday);
        newfirst.setDate(newfirst.getDate()-7);
        newlast.setDate(newlast.getDate()-7);
        
        var  m = component.get("v.currentMonth");
        var lastmonth = m-1;
        var nextmonth = m+1;
        var firstdayweekDay = newfirst;
        if((firstdayweekDay.getMonth() == lastmonth && firstdayweekDay.getDate() > 1) || firstdayweekDay.getDate() === 1){
            component.set("v.disablePrev",true);
            component.set("v.disableNext",false);
        }else{
            component.set("v.disablePrev",false);
            component.set("v.disableNext",false);
        }       
        
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
                        if(!$A.util.isUndefinedOrNull(mainList[i].innerWrapperList[j].psoList[k].Hours_Spent__c) && (mainList[i].innerWrapperList[j].psoList[k].Hours_Spent__c) !== '')
                            totalhr = totalhr+parseInt(mainList[i].innerWrapperList[j].psoList[k].Hours_Spent__c);
                    }
                    mainList[i].innerWrapperList[j].totalhours = totalhr.toString();
                }
            }
        } 
        component.set("v.subtasksWrapperList",mainList);
    },
    section : function(component, event, helper) {
        var secId = event.currentTarget.dataset.index;  
        component.set("v.initialAllopen",false);
        component.set("v.openSecId",secId); 
    },
    callfromParent : function(component, event, helper) {
        //var ProjectId = event.getParam("ProjectId");
        component.set("v.Message","");
        //component.set("v.projId",ProjectId);
        component.set("v.initialAllopen",true);
        helper.setDates(component, event, helper);
    },
    saveAndSubmit: function(component, event, helper) {
        var msg ='Are you sure you would like to save and submit your timecard for Approval';
        if (!confirm(msg)) {
            console.log('No');
            return false;
        } else {
            //alert('Yes');
            console.log('button--'+event.getSource().get("v.name"));
            component.set("v.buttonClicked",event.getSource().get("v.name"));
            component.commentValidationMethod(component, event, helper);
            //Write your confirmed logic
        }
        
    }, 
    commentValidation : function(component, event, helper) {
        console.log('buttonclicked  2222--'+component.get("v.buttonClicked"));
        component.set("v.Message","");
        var commentsBlankError = false;
        var notesBlank = false;
        //buttonclicked = component.get("v.buttonClicked") == 'saveandsubmit'?'saveandsubmit':'save';
        var mainList = component.get("v.subtasksWrapperList");
        for(var i=0;i<mainList.length;i++){
            if(commentsBlankError) {
                break;
            }
            for(var j=0;j<mainList[i].innerWrapperList.length;j++){
                notesBlank = false;
                
                if($A.util.isEmpty(mainList[i].innerWrapperList[j].notes)) {
                    notesBlank = true;
                    var hoursBlank = false;
                    for(var k=0;k<mainList[i].innerWrapperList[j].psoList.length;k++){
                        if(!$A.util.isUndefinedOrNull(mainList[i].innerWrapperList[j].psoList[k].Hours_Spent__c) 
                           && (mainList[i].innerWrapperList[j].psoList[k].Hours_Spent__c).length >0 ) {
                            hoursBlank = true;
                            break;
                        }
                    }
                    if(notesBlank && hoursBlank) {
                        commentsBlankError = true;
                        break;
                    }
                }	
                
            }
        }
        if(commentsBlankError) {
            component.set("v.Message","Comments are Mandatory for each sub task");
        } else {
            helper.helpersave(component, event, helper, component.get("v.buttonClicked"));
        }
    }
})