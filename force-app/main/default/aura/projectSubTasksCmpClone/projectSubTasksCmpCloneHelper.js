({
	helperdoInit : function(component,event,firstday,lastday) {
        component.set("v.notes","");
		var action = component.get("c.getsubtasksList");
        action.setParams({ projId : component.get("v.projId"),
                          startdate : firstday,
                          enddate : lastday});
         action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
                component.set("v.subtasksWrapperList",response.getReturnValue());
                console.log(response.getReturnValue());
            }else if (state === "ERROR") {
                 var errors = response.getError();
				 if (errors) {
                     if (errors[0] && errors[0].message) {
						alert(errors[0].message);
                     }
                 }
            }
         });
        $A.enqueueAction(action);

	},
    helpersave : function(component,event,helper, buttonclicked) {
        var action = component.get("c.savePSOtime");
        console.log(component.get("v.subtasksWrapperList"));
        console.log('buttonclicked--'+buttonclicked);
        var temp = component.get("v.subtasksWrapperList");
        action.setParams({ saveList : JSON.stringify(component.get("v.subtasksWrapperList")), buttonClicked: buttonclicked  });
         action.setCallback(this, function(response) {
            component.set("v.initialAllopen",true);  
			var state = response.getState();
			if (state === "SUCCESS") {
                var retResponse = response.getReturnValue();
                console.log('retResponse=='+retResponse);
                if(retResponse == 'SUCCESS') {
                    component.set("v.isSuccess",true);
                	component.set("v.Message","Time entry saved");
                    component.set("v.refreshParent","callchild");
                    helper.helperdoInit(component,event,component.get("v.firstday"),component.get("v.lastday"));
                }
                else {
                    component.set("v.isSuccess",false); 
					component.set("v.Message",retResponse);
                }
                component.set("v.changed",false);
            }else if (state === "ERROR") {
                var retResponse = response.getReturnValue();
                console.log('retResponse=='+retResponse);
                 var errors = response.getError();
				 if (errors) {
                     if (errors[0] && errors[0].message) {
                         component.set("v.isSuccess",false); 
						 component.set("v.Message",errors[0].message);
                     }
                 }
            }
             
         });
        $A.enqueueAction(action);
    },
    openSection : function(component, event, helper){
        console.log('in helper');
        var secId = component.get("v.openSecId");
        console.log(secId);
        if(secId != null && secId != ''){
            var index = parseInt(secId);
            var subtasksWrapperList = component.get("v.subtasksWrapperList");
            if(subtasksWrapperList != null && subtasksWrapperList.length > 0){
                console.log(subtasksWrapperList[secId].innerWrapperList.length);
                var innerchildlength = subtasksWrapperList[secId].innerWrapperList.length;
                for(var i=0;i<innerchildlength;i++){
                    var trId = secId+'-'+i;
                    console.log(trId);
                    var eachtr = document.getElementById(trId);
                    if(eachtr.style.display == 'none'){
                   		 eachtr.style.display = '';
                    }else{
                        eachtr.style.display = 'none';
                    }
                }  
            }
        }
       component.set("v.openSecId",'');
       var btn = document.getElementsByClassName(secId);
        if(btn != null){
           for(var i=0;i<btn.length;i++) {
               if(btn[i] != null && btn[i].style.display == 'block'){
                   btn[i].style.display = 'none';
               }else if(btn[i] != null && btn[i].style.display == 'none'){
                   btn[i].style.display = 'block';
               }
           }
        }
  
    },
    setDates : function(component, event, helper) {
      
        var curr = new Date; // get current date
        var first = curr.getDate() - curr.getDay(); // First day is the day of the month - the day of the week
        var last = first + 6; // last day is the first day + 6
        
        var firstday = new Date(curr.setDate(first));
        var lastday = new Date(curr.setDate(last));
        component.set("v.firstday",firstday);
        component.set("v.lastday",lastday);
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
        /* Previous */
        /* Next */
        var lastdayweekDay = new Date();
        lastdayweekDay.setDate(lastdayweekDay.getDate()- firstdayweek);
        lastdayweekDay.setDate(lastdayweekDay.getDate()+6);
        var nextmonth = m+1;
        if(lastdayweekDay == lastDayMonth || (lastdayweekDay.getMonth() == nextmonth)){
            component.set("v.disableNext",true);
        }else{
            component.set("v.disableNext",false);
        }
        /* Next */
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
    }
})