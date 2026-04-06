({
    doInit: function (component, event, helper) {
        var currdate = new Date();
        var yr = currdate.getFullYear();
        var month = currdate.getMonth() + 1;
        var date = currdate.getDate();
        if (month < 10) {
            month = '0' + month;
        }
        if (date < 10) {
            date = '0' + date;
        }
        var textDate = yr + '-' + month + '-' + date;
        component.set("v.Activity_Start_Date__c", textDate);
        component.set("v.Activity_End_Date__c", textDate);
        helper.doInit(component, event, helper);

    },
    handleSaveForm: function (component, event, helper) {
        var isValidForm = true;
        var currdate = new Date();
        if (!$A.util.isEmpty(component.get("v.Activity_Start_Date__c"))) {
            var startDate = component.get("v.Activity_Start_Date__c");
            var temp = startDate.split('-');
            var month = parseInt(temp[1]) - 1;
            var start = new Date();
            start.setFullYear(temp[0], month, temp[2]);
            if (start < currdate) {
                isValidForm = false;
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": "Error",
                    "message": "Activity Start Date cannot be earlier than today",
                    "type": "error"
                });
                resultsToast.fire();
            }
        }
        if (!$A.util.isEmpty(component.get("v.Activity_Start_Date__c")) && !$A.util.isEmpty(component.get("v.Activity_End_Date__c")) && component.get("v.Activity_Start_Date__c") > component.get("v.Activity_End_Date__c")) {
            isValidForm = false;
            var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "title": "Error",
                "message": "Activity Start Date cannot be after Activity End Date",
                "type": "error"
            });
            resultsToast.fire();
        }
        helper.savePF(component, event, helper, isValidForm);
    },
    //prit26-11
    onActivityChange: function (component, event, helper){
        
        var activityType = component.find('Activity').get('v.value');
        let list = component.get("v.requiredFields");
        if(activityType == 'Dedicated Resource'){
            component.set("v.showDedicatedResourceSection", true);
            list.push('Dedicated_Resource_Name__c');
            list.push('Job_Title__c');
            list.push('Measurements_of_Success_Q1__c');
            list.push('Measurements_of_Success_Q2__c');
            list.push('Measurements_of_Success_Q3__c');
            list.push('Measurements_of_Success_Q4__c');
            component.set('v.requiredFields',list);
        }else{
            component.set("v.showDedicatedResourceSection", false);
            let fieldsToRemove = [
                'Dedicated_Resource_Name__c',
                'Job_Title__c',
                'Measurements_of_Success_Q1__c',
                'Measurements_of_Success_Q2__c',
                'Measurements_of_Success_Q3__c',
                'Measurements_of_Success_Q4__c'
            ];
            let list = component.get('v.requiredFields') || [];
            list = list.filter(field => !fieldsToRemove.includes(field));
            component.set('v.requiredFields', list);
        }
        console.log('-->'+component.get('v.requiredFields'));
    },
    //prit26-11
    handleUploadFinished: function (component, event) {
        // Get the list of uploaded files
        var uploadedFiles = event.getParam("files");
        console.log(JSON.stringify(uploadedFiles));
        if (uploadedFiles && uploadedFiles.length > 0) {
            var documentIds = component.get("v.docIds");
            var documentNames = component.get("v.docNames");
            var tempDocNames = [];
            uploadedFiles.forEach(file => {
                documentIds.push(file.documentId);
                tempDocNames.push(file.name);
            });
            component.set("v.docIds", documentIds);
            component.set("v.showDocNames", true);
            if (documentNames !== '') {
                component.set("v.docNames", documentNames + ',' + tempDocNames.join());
            } else {
                component.set("v.docNames", tempDocNames.join());
            }
        }
    }
})