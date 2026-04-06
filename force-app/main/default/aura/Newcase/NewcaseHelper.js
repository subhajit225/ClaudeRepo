({
    HelperFieldChange: function(component, event) {
        var FieldChangeCheck=component.get('v.FieldChangeCheck');
        if(!FieldChangeCheck){
            component.set('v.FieldChangeCheck',true);

            window.addEventListener("beforeunload", function (e) {
                var oncasesubmit=component.get('v.OnCaseSubmit');

                if(oncasesubmit){
                    var confirmationMessage = 'It looks like you have been editing something. '
                    + 'If you leave before saving, your changes will be lost.';

                    (e || window.event).returnValue = confirmationMessage; //Gecko + IE
                    return confirmationMessage;
                }
            });

        }
    },
    HelpercreateCase: function(component, event, helper) {
        var sub = component.find("sub");
        var value = sub.get("v.value");
        if (!$A.util.isEmpty(value)) {
            $A.util.addClass(bodyCom, 'disSpiner');
            sub.set("v.errors",  [{message:" Please fill the required field "}]);
            sub.focus();
        } else {
            sub.set("v.errors", null)
        }
           if (!$A.util.isEmpty(value )) {
     //   this.upsertCase(component, component.get("v.newCase"), function(a) {
         //   component.set("v.caseObj", a.getReturnValue());

           // window.location.replace("https://supfullsb-rubrik.cs14.force.com/CustomerSupport/s/uploadfile?id=");
          //  component.set("v.casesObject", a.getReturnValue());
           // console.log('a caseId 43 ====',component.get("v.casesObject").Id);
           // window.location.replace("https://supfullsb-rubrik.cs14.force.com/CustomerSupport/s/uploadfile?id="+component.get("v.casesObject").Id);
       // });
                    }
    },

    upsertCase : function(component, Case, callback) {
        var action = component.get("c.saveCase");
        action.setParams({
            "ca": Case
        });
        if (callback) {
            action.setCallback(this, callback);
        }
        $A.enqueueAction(action);

    },

    checkValidation : function(component, helper, isAttachment ) {
        let hasError = false;

        hasError = this.validateData(component);

        if(hasError){
            component.set("v.toggleSpinner", false);
        }
        else{
            let str1 = Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1);
            let str2 = Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1);
            let str3 = Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1);
            let str4 = Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1);
            let str5 = Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1);
            let str6 = Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1);
            let str7 = Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1);
            var caseUid = str1+ str2+'-'+str3+'-'+str4+'-'+str5+str6+str7;
            var CaseIs = component.get("v.newCase");

            CaseIs.su_vf_console__SearchUnify_Session_Id__c  = caseUid;
            CaseIs.RecordTypeId = '0126f0000014VBQ';

            var action = component.get("c.saveCase");
            action.setParams({
                "ca": CaseIs
            });
            action.setCallback(this, function(response){

                if(response.getState()== "SUCCESS"){
                    var result=response.getReturnValue();
                    /* SU CODE for component */

                    
                    var conversionData = component.get("v.conversionData");
                    var analyticsCmp = component.find("SuAnalytics");
                    if(component.get("v.conversionString") != component.get("v.newCase.Subject") || !component.get("v.conversion"))
                        var auramethodResult = analyticsCmp.analytics('search',{conversionString : conversionData.searchString, searchString: conversionData.searchString,"result_count":conversionData.result_count,page_no: "1","platformId":conversionData.platformId,"filter": conversionData.filter});
                    var auramethodResult = analyticsCmp.analytics('caseCreated',{'caseUid': caseUid});
                    /* SU CODE for component */
                    component.set('v.FieldChangeCheck',false);
                    var url = '';
                    if(isAttachment){
                        url = '/uploadfile?id='+result.Id+'&casenumber='+result.CaseNumber;
                    }else{
                        url = '/viewcase?id='+result.Id;
                    }
                    
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": url
                    });
                    urlEvent.fire();

                }else{
                    console.log('error===' , response.getError());

                }
            });
            $A.enqueueAction(action);
        }
    },
    validateData : function(component){
        /**
        * The following custom validations are put in place inspite of making the fields required on the markup because
        * the form is submitted from the button outside the recordEditForm which doesn't execute the standard validations
        */

        let device = component.get("v.isPhone");

		//Subject field validation
        var sub = device == 'PHONE' ? component.find("sub2") : component.find("sub");
        var value = sub.get("v.value");
        let hasError = false;
        if ($A.util.isEmpty(value)) {
            //component.set("v.toggleSpinner", false);
            sub.focus();
            hasError= true;
        } else {
            //type.set("v.errors", null);
        }

        //Type Field Validation
        var type = device == 'PHONE' ? component.find("caseType2") : component.find("caseType");
        var typevalue = type.get("v.value");
        if ($A.util.isEmpty(typevalue)) {
            //component.set("v.toggleSpinner", false);
            //type.set("v.errors",  [{message:" Please fill the required field "}]);
            type.focus();
             hasError= true;
        }

        //Product Line Field Validation
        var productLine = device == 'PHONE' ? component.find("platform2") : component.find("platform");
        var productLinevalue = type.get("v.value");
        if ($A.util.isEmpty(productLinevalue)) {
            //component.set("v.toggleSpinner", false);
            //productLine.set("v.errors",  [{message:" Please fill the required field "}]);
            productLine.focus();
            hasError= true;
        }

        //Functional Area Field Validation
        var area = device == 'PHONE' ? component.find("productArea2") : component.find("productArea");
        var areavalue = type.get("v.value");
        if ($A.util.isEmpty(areavalue)) {
            //component.set("v.toggleSpinner", false);
            //area.set("v.errors",  [{message:" Please fill the required field "}]);
            area.focus();
            hasError= true;
        }

        //Component Field Validation
        var caseComp = device == 'PHONE' ? component.find("caseComp2") : component.find("caseComp");
        var caseCompValue = type.get("v.value");
        if ($A.util.isEmpty(caseCompValue)) {
            //component.set("v.toggleSpinner", false);
            //area.set("v.errors",  [{message:" Please fill the required field "}]);
            caseComp.focus();
            hasError= true;
        }

        //Priority Field Validation
        var priority = device == 'PHONE' ? component.find("priority2") : component.find("priority");
        var priorityvalue = priority.get("v.value");
        if ($A.util.isEmpty(priorityvalue)) {
            //component.set("v.toggleSpinner", false);
            //priority.set("v.errors",  [{message:" Please fill the required field "}]);
            priority.focus();
             hasError= true;
        }

        //Contact Field Validation
        var con = device == 'PHONE' ? component.find("contactMethod2") : component.find("contactMethod");
        var convalue = con.get("v.value");
        if ($A.util.isEmpty(convalue)) {
            //component.set("v.toggleSpinner", false);
            //con.set("v.errors",  [{message:" Please fill the required field "}]);
            con.focus();
             hasError= true;
        }

        //Description Validation
        var desc = device == 'PHONE' ? component.find("desc2") : component.find("desc");
        var descvalue = desc.get("v.value");
        if ($A.util.isEmpty(descvalue)) {
            //component.set("v.toggleSpinner", false);
            //desc.set("v.errors",  [{message:" Please fill the required field "}]);
            desc.focus();
             hasError= true;
        }
        return hasError;
    }
})