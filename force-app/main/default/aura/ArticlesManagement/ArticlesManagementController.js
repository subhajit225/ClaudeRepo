({
    doInit : function(component, event, helper) {
  
      var  selectedValue  =  component.find("dropDown").get("v.value");
        component.set('v.selectedValue',selectedValue);
        var action = component.get('c.getAllData');
        action.setParams({
            "articleStatus":'Draft'
        });
        component.set('v.truthy',true);
        //processing callback
        action.setCallback(this,function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set('v.columns', [{label: 'Article Number', fieldName: 'ArticleNumber'},{label: 'Knowledge Article', fieldName: 'KnowledgeArticleId'},
                                            {label: 'Software Version', fieldName: 'SoftwareVersion'},{label: 'Created By', fieldName: 'CreatedByName'},
                                            {label: 'Title', fieldName: 'Title'},{label: 'Publish Status', fieldName: 'PublishStatus'},
                                            {label: 'Created Date', fieldName: 'CreatedDate'},{label: 'Summary', fieldName: 'Summary'},{label: 'Last Modified Date', fieldName: 'LastModifiedDate'}]);
                component.set('v.ListOfArticles',result.kavsList);
                component.set('v.dataCategories',result.categoriesList);
                component.set('v.softwareVersions',result.softwaresList);
                component.set('v.truthy',false);
            }
            else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
    },
    handleChange : function(component, event, helper) {
        component.set('v.truthy',true);
        
        var selectedOptionValue = event.getParam("value");
        component.set('v.selectedValue',selectedOptionValue);
        var action = component.get('c.getArticles1');
        action.setParams({
            "articleStatus":selectedOptionValue
        });
        //processing callback
        action.setCallback(this,function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.find('articlesTable').set('v.selectedRows',[]);
                component.set('v.selectedArticles',[]);
                component.set('v.ListOfArticles',result);
                component.set('v.truthy',false);
            }
            else {
                console.log("Failed with state: " + state);
            }
        });
        //sending request
        $A.enqueueAction(action);                                    
    },
    
    handleKeyUp: function (component, evt) {
        var isEnterKey = evt.keyCode === 13;
        var queryTerm = component.find('enter-search').get('v.value');
        var selectedOptionValue = component.find('dropDown').get('v.value');
        if (isEnterKey) {
            if(queryTerm.trim() != ''){
                component.set('v.truthy',true);
                var action = component.get('c.searchArticle');
                action.setParams({
                    "articleNumber" : queryTerm,
                    "articleStatus" : selectedOptionValue
                });
                //processing callback
                action.setCallback(this,function(response){
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        var result = response.getReturnValue();
                        component.set('v.ListOfArticles',result);
                        component.set('v.truthy',false);
                    }
                    else {
                        console.log("Failed with state: " + state);
                    }
                });
                //sending request
                $A.enqueueAction(action);
            } 
            else{
                component.set('v.showError',true);
                setTimeout(function(){ component.set('v.showError',false); }, 3000); 
            }
        }
    },
    // Use above method to handle this 
    onChangeSearch : function(component, event, helper){
        var queryTerm = component.find('enter-search').get('v.value');
        var selectedOptionValue = component.find('dropDown').get('v.value');
        if(queryTerm == ''){
            var action = component.get('c.getArticles1');
            action.setParams({
                "articleStatus":selectedOptionValue
            });
            component.set('v.truthy',true);
            //processing callback
            action.setCallback(this,function(response){
                var state = response.getState();
                if (state === "SUCCESS") {
                    var result = response.getReturnValue();
                    component.set('v.ListOfArticles',result);
                    component.set('v.truthy',false);
                }
                else {
                    console.log("Failed with state: " + state);
                }
            });
            //sending request
            $A.enqueueAction(action);
        }
    },
    getSelectedRows : function(component, event, helper){
        let lines = [];
        lines = component.find('articlesTable').getSelectedRows();
        if(lines.length >= 20){
            
            var toastEvent = $A.get("e.force:showToast");
            
          toastEvent.setParams({
                "title": "Info!",
                "message": "You can only select max 20 rows.",
                "duration": 10000
            });
            toastEvent.fire();
            
            helper.vfPageAlert(component, event, 'You cannot select more than 20 rows');
          
        }
        component.set('v.selectedArticles',lines);
        
    },
    setStatusItems : function(component, event, helper){
        var statusOptions = component.get("v.statusMenuOpt");
        var showingArticle = component.find('dropDown').get('v.value');
        var arr = [];
        statusOptions.forEach(function(option){
            if(option.value != showingArticle){
                arr.push(option); 
            }
        });
        component.set('v.statusMenuItems',arr);
    },
    changeStatus : function(component, event, helper){
        var showArticle = component.find('dropDown').get('v.value');
        var changeStatusTo = event.getParam("value");
        var getSelectedArticles = component.get('v.selectedArticles');
        var selectedArticles = [];
        if(getSelectedArticles.length > 0){
            component.set('v.truthy',true);
            getSelectedArticles.forEach(function(article){
                if(article.PublishStatus == 'Draft' && changeStatusTo == 'Archived'){
                    component.set('v.truthy',false);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "message": "You can't change status from draft to archived.",
                        "duration": 10000
                    });
                    toastEvent.fire();
                    
                    helper.vfPageAlert(component, event,'You cannot change status from draft to archived.');
                   
                }
                else{
                    selectedArticles.push(article);
                }
            });
            if(selectedArticles.length > 0){
                var statusAction = component.get('c.changeStatus1');
                statusAction.setParams({
                    "selectedArticles" : selectedArticles,
                    "changeStatusTo" : changeStatusTo,
                    "showArticle" : showArticle
                });
                //processing callback
                statusAction.setCallback(this,function(response){
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        var result = response.getReturnValue();
                        if(result.errorMsg!=null){
                            component.set('v.ListOfArticles',result.kavsList);
                            component.find('articlesTable').set('v.selectedRows',result.toSelecteKavIds);
                            component.set('v.truthy',false);
                            if(result.publishedArticles.length>0){
                                var toastEvent1 = $A.get("e.force:showToast");
                                toastEvent1.setParams({
                                    "title": "Success!",
                                    "message": 'Status changed successfully for article(s) '+result.publishedArticles,
                                    "duration": 10000
                                });
                                toastEvent1.fire();
                                helper.vfPageAlert(component, event, 'Status changed successfully for article(s)');
                            }
                            var toastEvent2 = $A.get("e.force:showToast");
                            var erroralert= result.errorMsg;
                            toastEvent2.setParams({
                                "title": "Error!",
                                "message": result.errorMsg,
                                "duration": 10000
                            });
                            toastEvent2.fire();
                               helper.vfPageAlert(component, event, erroralert);
                        }
                        else{
                            component.find('articlesTable').set('v.selectedRows',[]);
                            component.set('v.selectedArticles',[]);
                            component.set('v.ListOfArticles',result.kavsList);
                            component.set('v.truthy',false);
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "title": "Success!",
                                "message": "Status was changed successfully."
                            });
                            toastEvent.fire();
                              helper.vfPageAlert(component, event, 'Status was changed successfully.');
                        }
                    }
                    else {
                        console.log("Failed with state: " + state);
                    }
                });
                //sending request
                $A.enqueueAction(statusAction);
            }
        }
        else{
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "Please select an article."
            });
            toastEvent.fire();
            helper.vfPageAlert(component, event, 'Please select an article.');
        }
    },
    changeSoftVer : function(component, event, helper){
        var showArticle = component.find('dropDown').get('v.value');
        var changeSoftTo = event.getParam("value");
        var getSelectedArticles = component.get('v.selectedArticles');
        var selectedArticles = [];
        var removeArticles = [];
        var isvalid = true;
        if(getSelectedArticles.length > 0){
            component.set('v.truthy',true);
            getSelectedArticles.forEach(function(article){
                if(article.SoftwareVersion != changeSoftTo) {
                    selectedArticles.push(article);
                }
                else{
                    removeArticles.push(article.ArticleNumber);
                }
            });
            if(removeArticles.length > 0){
                component.set('v.truthy',false);
                var toastEvent = $A.get("e.force:showToast");
                var alerstr="Please remove article(s) "+removeArticles+" beacuse "+changeSoftTo+" is already set.";
                toastEvent.setParams({
                    "title": "Error!",
                    "message": "Please remove article(s) "+removeArticles+" beacuse "+changeSoftTo+" is already set.",
                    "duration": 10000
                });
                toastEvent.fire();
                 helper.vfPageAlert(component, event, alerstr);
            }
            else{
                var action = component.get('c.setSoftwareVersion');
                action.setParams({
                    "selectedArticles" : selectedArticles,
                    "changeSoftTo" : changeSoftTo,
                    "showArticle" : showArticle
                });
                //processing callback
                action.setCallback(this,function(response){
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        var result = response.getReturnValue();
                        component.find('articlesTable').set('v.selectedRows',[]);
                        component.set('v.selectedArticles',[]);
                        component.set('v.ListOfArticles',result);
                        component.set('v.truthy',false);
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Success!",
                            "message": "Software version was changed successfully."
                        });
                        toastEvent.fire();
                          helper.vfPageAlert(component, event, 'Software version was changed successfully.');
                    }
                    else {
                        console.log("Failed with state: " + state);
                    }
                });
                //sending request
                $A.enqueueAction(action);
            }
        }
        else{
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "Please select an article."
            });
            toastEvent.fire();
            helper.vfPageAlert(component, event, 'Please select an article.');
        }
    },
    
    openModel: function(component, event, helper) {
        var selectedArticles = component.get('v.selectedArticles');
        if(selectedArticles.length != 0){
            // for Display Model,set the "isOpen" attribute to "true"
            component.set("v.isOpen", true);
        }else{
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "Please select an article."
            });
            toastEvent.fire();
            helper.vfPageAlert(component, event, 'Please select an article.');
        }
    },
    
    closeModel: function(component, event, helper) {
        // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
        component.set("v.isOpen", false);
    },
    
    save: function(component, event, helper) {
        component.set("v.isOpen", false);
        component.set('v.truthy',true);
        var showArticle = component.find('dropDown').get('v.value');
        var changeCategoryTo = component.find('categoryListBox').get('v.value');
        var selectedArticles = component.get('v.selectedArticles');
        var articlesReadyForChange = [];
        var isValidForChange = true;
        selectedArticles.forEach(function(article){
            var existingCategory = article.categoryList;
            var existingCategoryArray = [];
            // iterate backwards ensuring that length is an UInt32
            for (var i = existingCategory.length >>> 0; i--;) { 
                existingCategoryArray[i] = existingCategory[i];
            }
            var preExistingCateg = [];
            changeCategoryTo.forEach(function(category){
                if(existingCategoryArray.includes(category)){
                    preExistingCateg.push(category);
                }
            });
            if(preExistingCateg.length == 0){
                var possibleForCategorys = 8 - article.categoryCount;
                if(changeCategoryTo.length > possibleForCategorys){
                    isValidForChange = false;
                    component.set('v.truthy',false);
                    var assignableCategories = changeCategoryTo.length - possibleForCategorys;
                    var toastEvent = $A.get("e.force:showToast");
                    var message=(possibleForCategorys == 0) ? "Only 8 categories can be assigned. Please remove article "+article.ArticleNumber+" beacause 8 already assigned" : "Only 8 categories can be assigned. Please remove article "+article.ArticleNumber+" Or remove "+assignableCategories+" categorie(s)";
                    toastEvent.setParams({
                        "title": "Error!",
                        "message": (possibleForCategorys == 0) ? "Only 8 categories can be assigned. Please remove article "+article.ArticleNumber+" beacause 8 already assigned" : "Only 8 categories can be assigned. Please remove article "+article.ArticleNumber+" Or remove "+assignableCategories+" categorie(s)",
                        "duration": 10000	
                    });
                    toastEvent.fire();
                    helper.vfPageAlert(component, event, message);
                }
                else{
                    articlesReadyForChange.push(article);
                }
            }
            else{
                isValidForChange = false;
                component.set('v.truthy',false);
                var toastEvent = $A.get("e.force:showToast");
                var alertstr="Categorie(s) "+preExistingCateg+" already exist for article "+article.ArticleNumber;
                toastEvent.setParams({
                    "title": "Error!",
                    "message": "Categorie(s) "+preExistingCateg+" already exist for article "+article.ArticleNumber,
                    "duration": 10000	
                });
                toastEvent.fire();
                 helper.vfPageAlert(component, event, alertstr);
            }
        });
        if(isValidForChange){
            var action = component.get('c.changeCategory1');
            action.setParams({
                "selectedArticles" : articlesReadyForChange,
                "changeCategoryTo" : changeCategoryTo,
                "showArticle" : showArticle
            });
            //processing callback
            action.setCallback(this,function(response){
                var state = response.getState();
                if (state === "SUCCESS") {
                    var result = response.getReturnValue();
                    component.find('articlesTable').set('v.selectedRows',[]);
                    component.set('v.selectedArticles',[]);
                    component.set('v.ListOfArticles',result);
                    component.set('v.truthy',false);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "message": "Category was changed successfully."
                    });
                    toastEvent.fire();
                      helper.vfPageAlert(component, event, 'Category was changed successfully.');
                }
                else {
                    console.log("Failed with state: " + state);
                }
            });
            //sending request
            $A.enqueueAction(action);
        }
    }
})