({
	getArticles : function(component, event,offSetCount,selectedOption) {
		/* var action = component.get('c.getAllData');
        action.setParams({
            "articleStatus":selectedOption,
            "intOffSet": offSetCount
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
        $A.enqueueAction(action);  */
	},
    
    vfPageAlert:function(component, event, alertString){
       
          var appEvent = $A.get("e.c:MaxSelectionEvent");
               appEvent.setParams({ "myParam" : alertString });
               appEvent.fire();
    
    }
     
})