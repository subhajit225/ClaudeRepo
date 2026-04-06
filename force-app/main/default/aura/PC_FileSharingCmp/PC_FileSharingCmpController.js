({
         doInit : function(component, event, helper) {
    
            component.find("FileSharingRecordCreator").getNewRecord(
                "File_Sharing__c", // sObject type (entityAPIName)
                null,      // recordTypeId
                false,     // skip cache?
                $A.getCallback(function() {
                    var rec = component.get("v.newfileSharing");
                    var error = component.get("v.newfileSharingError");
                    if(error || (rec === null)) {
                        console.log("Error initializing record template: " + error);
                    }
                    else {
                        console.log("Record template initialized: " + rec.sobjectType);
                    }
                    if(!$A.util.isEmpty(component.get("v.recordId"))){
                       var action = component.get("c.getFSRecord");
                        action.setParams({
                            "recId": component.get("v.recordId")
                        });
                        
                        action.setCallback(this, function(response) { 
                            var saveResult = response.getState();
                            if(response.getState() === "SUCCESS") { 
                                var result = response.getReturnValue();
                                if(!$A.util.isEmpty(result))
                                    component.set("v.simplefileSharing",result[0]);
                                }
                        }); 
                        $A.enqueueAction(action);  
                    }
                })
            );
             
             if(!$A.util.isEmpty(component.get("v.recordId"))){
               
                var action1 = component.get("c.getAccNames");
                action1.setParams({
                    "recId": component.get("v.recordId")
                });
                
                action1.setCallback(this, function(response) { 
                    var saveResult = response.getState();
                    if(response.getState() === "SUCCESS") { 
                        var result = response.getReturnValue();
                        if(!$A.util.isEmpty(result))
        					component.set("v.selectedAccountRecords",result);
                        }
                }); 
                
                 var action2 = component.get("c.getCPNames");
                action2.setParams({
                    "recId": component.get("v.recordId")
                });
                
                action2.setCallback(this, function(response) { 
                    var saveResult = response.getState();
                    if(response.getState() === "SUCCESS") { 
                        var result = response.getReturnValue();
       					if(!$A.util.isEmpty(result))
        					component.set("v.selectedChannelProgramRecords",result);
                        }
                }); 
                                 
                var action3 = component.get("c.getCPLNames");
                action3.setParams({
                    "recId": component.get("v.recordId")
                });
                
                action3.setCallback(this, function(response) { 
                    var saveResult = response.getState();
                    if(response.getState() === "SUCCESS") { 
                        var result = response.getReturnValue();
        				if(!$A.util.isEmpty(result))
        					component.set("v.selectedChannelProgramLevelRecords",result);
                        }
                });
             	
                
             	$A.enqueueAction(action1);  
                $A.enqueueAction(action2);
                $A.enqueueAction(action3); 
              }
            
         },
        
        channelProgramOnChange : function (component, event, helper) {
          var arr = component.get("v.selectedChannelProgramRecords");
          var progName = '';
          arr.forEach(function(item) {
              progName = progName +item.Name+';';
          })
           component.set("v.selectedProgramNames",progName); 
           component.set("v.selectedChannelProgramLevelRecords",[]); 
        },
        handleCheck : function(component, event, helper) {
            console.log(component.get("v.checkboxValue"));       
        },
        handleSaveForm : function(component, event, helper) {
          console.log(component.get("v.simplefileSharing.Active__c"));
            console.log(component.get("v.selectedAccountRecords"));
            console.log(component.get("v.selectedChannelProgramRecords"));
            console.log(component.get("v.selectedChannelProgramLevelRecords"));
            helper.saveRecord(component, event,helper); 

        },
    	handleCancel  : function(component, event, helper) {
            if($A.util.isEmpty(component.get("v.recordId"))){
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                  "url": "/lightning/o/File_Sharing__c/list?filterName=All"
                });
                urlEvent.fire();
            }else{
            	helper.gotoRec(component,component.get("v.recordId"));
            }
        },
    })