({
	doInit : function(component, event, helper) {
        component.set("v.isLoading", true);
	helper.getRunningProf(component);
        helper.setupTableForSaas(component);
        helper.setupTableForGo(component);
        helper.setupTableForLoD(component);
        helper.setupTableForRSCG(component);
        helper.setupTableForSSG(component); 
        helper.setupTableForLoDRscG(component);
        component.set("v.buttonsDisabled", true);
	//CPQ22-3773 Starts
	var DsaasValidation = $A.get("$Label.c.DSaaS_NCD_Validation");
        var DsaasSKUs = $A.get("$Label.c.DSaaS_NCD_SKUs");
        component.set("v.dsaasValidation", DsaasValidation);   
        component.set("v.dsaasSKUs", DsaasSKUs);
        //CPQ22-3773 Ends 
    },    
    getValueFromApplicationEvent : function(component, event) {
        component.set("v.buttonsDisabled", true);
        var ShowResultValue = event.getParam("selectedSKU");
       	var bundleRecordId = event.getParam("currentRecId");
        var assetRecordName = event.getParam("assetName");
        var sectionName = event.getParam("sectionName");
        var orgKey = sectionName+':'+bundleRecordId;
        component.set("v.selectedSKU",ShowResultValue);
        component.set("v.selectedRecordId",bundleRecordId);
        component.set("v.selectedAsset",assetRecordName);
        console.log('ShowResultValue',ShowResultValue,'-',bundleRecordId,'-',assetRecordName);
        if (bundleRecordId != undefined && bundleRecordId != undefined  != '' && bundleRecordId != undefined != null) {
           //CPQ22-4168 --Madhura
	    var newMap = component.get("v.mapOfBundleIdvsAssetIds");
            let aMapp = component.get("v.mapTocheckDup");
            let orgval = component.get("v.mapTogetOrgVal");
            if(ShowResultValue== '' || ShowResultValue == null || ShowResultValue== undefined){
                console.log('inside hre',JSON.stringify(aMapp));
                if(aMapp.hasOwnProperty(sectionName)){
                    var arrayMapKeys = aMapp[sectionName];
                    for (var i = 0; i < JSON.stringify(arrayMapKeys).length; i++) {
                        if(arrayMapKeys[i] === bundleRecordId){
                            aMapp[sectionName].splice(i, i);
                            if(i == 0){
                                delete aMapp[sectionName];
                            }
                             
                        }
                    }                
            }
                if(orgval.hasOwnProperty(orgKey)){
                   delete orgval[orgKey];
                    console.log('show mapp org',JSON.stringify(orgval));
                }
            }else{
                    // console.log('show mapp NEW MAP dupp',JSON.stringify(aMapp));
                     aMapp[sectionName] = aMapp[sectionName] || [];
                if(!aMapp[sectionName].includes(bundleRecordId)){
                     aMapp[sectionName].push(bundleRecordId);
                     console.log('show mapp NEW MAP dupp',JSON.stringify(aMapp));
                }
                orgval[orgKey] = ShowResultValue
               console.log('show ORGmap',JSON.stringify(orgval));
                
            }
           
            
          // Added by Madhura for duplicates
            if(!newMap.hasOwnProperty(bundleRecordId) || newMap[bundleRecordId] != null || (ShowResultValue== '' || ShowResultValue == null || ShowResultValue == undefined)){
              newMap[bundleRecordId]  = ShowResultValue;
                console.log('here>>'+component.get("v.dupflag"));
            }
            if( (ShowResultValue== '' || ShowResultValue == null || ShowResultValue == undefined)){
                for(var key in orgval){
                    console.log('key',key);
                    if(key.includes(bundleRecordId)){
                        var value = orgval[key];
                        console.log('here is the value>',value);
                        newMap[bundleRecordId]  = value;
                    }
                }
            }
            component.set("v.mapTogetOrgVal",orgval);
            component.set("v.mapTocheckDup",aMapp);
            component.set("v.mapOfBundleIdvsAssetIds", newMap);
            component.set("v.buttonsDisabled", false);
        }
        else if (assetRecordName != undefined && assetRecordName != '' && assetRecordName != null && ShowResultValue != '') {
            var newMap = component.get("v.mapOfBundleIdvsAssetIds");
            newMap[assetRecordName] = ShowResultValue;
            component.set("v.mapOfBundleIdvsAssetIds", newMap);
            component.set("v.buttonsDisabled", false);
        }
        var valueMap = component.get("v.mapOfBundleIdvsAssetIds");
        if ((Object.keys(valueMap).length == 1 && valueMap[component.get("v.selectedRecordId")] == '') || Object.keys(valueMap).length == 0) {
            component.set("v.buttonsDisabled", true);
        }
        else {
        	component.set("v.buttonsDisabled", false);
        }
    },
    newReplaceSKUs : function(component, event, helper) {
        console.log('called Replace');
        //Madhura Start
           console.log('showon init ',JSON.stringify(component.get("v.mapTocheckDup")));
      
        let aMap = Object.assign({}, component.get("v.mapTocheckDup"));
        let  cloneMap = Object.assign({}, component.get("v.mapTocheckDup"));
        var valueIds = [];
         for(var key in aMap){
              var arrayMapKeys = [];
        console.log('key : '+ key+ 'Map value: ', JSON.stringify(aMap[key]));
             arrayMapKeys = aMap[key];
         console.log('vals ', JSON.stringify(arrayMapKeys));
          if(cloneMap.hasOwnProperty(key)){
                     console.log('key : '+key);
                      delete cloneMap[key];
                 }
             for (var i = 0; i < JSON.stringify(arrayMapKeys).length; i++) {
                     console.log('values : '+JSON.stringify(arrayMapKeys[i]));
                 console.log('key>> : '+key);
                 
                 if(Object.keys(cloneMap).length > 0){
                     
                     for(var key in cloneMap){
                         if(JSON.stringify(cloneMap[key]).includes(JSON.stringify(arrayMapKeys[i]))){
                             console.log("FATTTTT JAAAA");
                             component.set("v.dupflag", true);
                             component.set("v.isLoading", false);
                         }  
                         
                     }
                 }
             }
    }
         
        if( component.get("v.dupflag") == true){
            component.set("v.isLoading", false);
            component.set("v.showdup", true);
        }
        //Madhura End
        
	//CPQ22-3773 Starts
        if(component.get("v.showdup")!= true){
        helper.showToastEvent(component);
        if(!component.get("v.isModalOpen")) {
            component.set("v.isLoading", true);
           helper.createReplaceSKUs(component, event, helper);
    	}
        }
    },
    closeValidationModel:function(component,event,helper){
        
        component.set("v.isModalOpen", false);
        component.set("v.isLoading", true);
        helper.createReplaceSKUs(component, event, helper);
    },
	//CPQ22-3773 Ends
	closeDuplicteError:function(component,event,helper){
         component.set("v.showdup", false);
         component.set("v.dupflag", false);
      
    },
    closeEditMode: function(component, event, helper) {
        helper.navigateToQLEScreen(component);
    }
})