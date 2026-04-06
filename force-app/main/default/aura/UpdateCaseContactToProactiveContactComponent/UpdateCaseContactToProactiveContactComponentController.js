({
    onInit : function(component, event, helper) {
        var timezone = component.get("v.timezone");
        var businessHours = component.get("v.businessHours");
        var workingDays = component.get("v.workingDays");
        //var caseCreatedDate = new Date(component.get("v.caseRecord.Resolved_Date_Time__c"));
        var caseCreatedDate = new Date(component.get("v.caseRecord.CreatedDate"));
        console.log('timeZone===',timezone);
        console.log('businessHours===',businessHours);
        console.log('workingDays===',workingDays);
        console.log('caseCreatedDate===',caseCreatedDate);

        var fromTime = (parseInt(businessHours.substring(0, 2)) * 60) + parseInt(businessHours.substring(3, 5));
        console.log('fromTime==',fromTime);

        var toTime = (parseInt(businessHours.substring(6, 8)) * 60) + parseInt(businessHours.substring(9, 11));
        console.log('toTime==',toTime);

        var createdDate = new Date(caseCreatedDate.toLocaleString("en-US", {timeZone: timezone}));
        console.log('createdDate===',createdDate);
        var createdTimeString = (createdDate.toTimeString()).substring(0, 5);
        console.log('createdTimeString===',createdTimeString);
        var createdTime = (parseInt(createdTimeString.substring(0, 2)) * 60) + parseInt(createdTimeString.substring(3, 5));
        console.log('createdTime==',createdTime);

        var days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
        var createdDay = days[caseCreatedDate.getDay()];
        console.log('createdDay==',createdDay);
        console.log('workingDays[0]===',workingDays);
        console.log('workingDays[0].indexOf(createdDay)===',workingDays.indexOf(createdDay));
        console.log('fromTime < createdTime===',fromTime < createdTime);
        console.log('createdTime < toTime===',createdTime < toTime);

        if(workingDays.indexOf(createdDay) > -1 && fromTime < createdTime && createdTime < toTime){
            component.set("v.withinBusinessHours", true);
        }
        else {
            component.set("v.withinBusinessHours", false);
        }
        var navigate = component.get("v.navigateFlow");
        navigate("NEXT");
    }
})