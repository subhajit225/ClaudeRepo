({
    doInitFunc : function(component, event, helper) {
       helper.getCustomSettingValue(component, event);
    },
    getCustomSettingValue: function(component, event){
        var action = component.get("c.getCommunityCustomSettings");
        action.setCallback(this, function(response) {
            if (component.isValid() && response.getState() == "SUCCESS") {
                var result= response.getReturnValue();
                if(result.isCustomSettingFilled){
                    component.set("v.endPoint",result.endPoint);
                    component.set("v.uid",result.uid);
                    component.set("v.currentCommunityURL",result.currentCommURL);
                    component.set("v.customSettingErrorMessage","");
                    if(result.userEmail != null && result.userEmail != ''){
                        component.set("v.currentUserEmail",result.userEmail);
                    }
                }else{
                    component.set("v.customSettingErrorMessage",'Please configure your SearchUnify and try again.');
                }
            }
            else {
                console.log("Failed with state: " + response.getState());
            }
        });
        $A.enqueueAction(action);
    },
    getURLParameter : function(param) {
        var m = window;
        var s = m.document.URL;
        console.log('url Param',s);
        var result=decodeURIComponent((new RegExp('[?|&]' + param + '=' + '([^&;]+?)(&|#|;|$)').exec(s)||[,""])[1].replace(/\+/g, '%20'));
        console.log('result',result);
        return result;
    },
    redirectFunc : function(component, SearchQuery,helper){
      	var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "isredirect": false,
            "url": component.get("v.currentCommunityURL") + "?searchString=" + encodeURIComponent(SearchQuery)+"&filter="+encodeURIComponent('{ "sourceType": "_type",  "valueFilter": "idea",  "order": "1"}')
        });
        urlEvent.fire();
        helper.fillSearchBoxEventFire(component, event,helper);
    },
    fillSearchBoxEventFire : function(component, event,helper){
        var SearchQuery = helper.getURLParameter('searchString');
        var searchBoxEvent = $A.get("e.SU_Ltng:fillSearchBox");
        searchBoxEvent.setParams({"searchString": SearchQuery});
        searchBoxEvent.fire();
    },
    searchButtonPressFunc: function(component, event,helper) {
        var SearchQuery = component.get("v.searchString");
        if(SearchQuery != null && SearchQuery != '' && SearchQuery != undefined){
            SearchQuery = SearchQuery.trim();
        }
        document.getElementById('su-suggestions').classList.add('su-hidePanel');
        helper.redirectFunc(component,SearchQuery,helper);
    },
    enterKeySearchFunc : function(component, event, helper) {
        var SearchQuery = component.get("v.searchString");
        if(SearchQuery != null && SearchQuery != '' && SearchQuery != undefined){
            SearchQuery = SearchQuery.trim();
        }
        if(event.getParams().domEvent.keyCode == 13){
            document.getElementById('su-suggestions').classList.add('su-hidePanel');
            helper.redirectFunc(component,SearchQuery,helper);
        }else{
            var delayCounter = component.get("v.delayCounter");
            if(delayCounter == 0){
                if(!$A.util.isEmpty("v.autosuggestList") && document.getElementById('autosuggestElement') !== null && document.getElementById('autosuggestElement') !== undefined){
                    document.getElementById('su-suggestions').classList.remove('su-hidePanel');
                    document.getElementById('autosuggestElement').style.display ='block';
                }
                component.set("v.delayCounter",1);
                window.setTimeout(
                    $A.getCallback(function() {
                        SearchQuery = component.get("v.searchString");
                        SearchQuery = SearchQuery.trim();
                        if(SearchQuery != ''){
                            helper.autosearchFunc(component,'autosuggestion','false', helper);
                        }
                        component.set("v.delayCounter",0);
                    }), 200);
            }
            
        }
        
    },
    mouseleftFunc: function(component, event){
        setTimeout(function(){
            if(document.getElementById('autosuggestElement') !== null && document.getElementById('autosuggestElement') !== undefined){
                document.getElementById('autosuggestElement').style.display ='none';
                component.set("v.autosuggestList",[]);
            }
        }, 500);
    },
    fillSearchboxFunc: function(component, event,helper){
        var valueToBeFilled = event.currentTarget.id;
        component.set("v.searchString",valueToBeFilled);
        helper.searchButtonPressFunc(component,event,helper);
    },
    autosearchFunc : function(component, searchType, runLoader, helper) {
        var resultPerSize = "10";
        var aggrValue = "[]";
        resultPerSize = component.get("v.pagesize");
        if(resultPerSize === 'undefined' || resultPerSize === undefined){resultPerSize = '10';} //default handling
        var sourceType = component.get("v.advanceFilterData");
        var sourceValue = component.get("v.advanceFilterValue");
        var filterData;
        aggrValue = component.get("v.aggregation");
        if(searchType === 'autosuggestion' && sourceType !== "" && sourceValue !== "" ){
            filterData = {"sourceType":sourceType,"valueFilter":sourceValue};
            helper.createAggregationFilter(component,filterData);
            aggrValue = component.get("v.aggregation");
        }
        var searchText = component.get("v.searchString");
        var EmailregexSlash = '\\\\';
        var regexSlash = new RegExp("\\\\", 'g');
        searchText = searchText.replace(regexSlash, EmailregexSlash);
        var Emailregex = '\\"';
        var regex = new RegExp('\"', 'g');
        console.log(aggrValue);

        console.log(JSON.parse(aggrValue));
        searchText = searchText.replace(regex,Emailregex);
        var action = component.get("c.SearchResults");
        action.setParams({
            "searchParams":{
                "searchString"	: searchText,
                "pageNum" : "1",
                "sortBy" : "_score",
                "orderBy" : "desc",
                "resultsPerPage" : resultPerSize,
                "selectedType" : aggrValue,
                "referrer": "",
                "exactPhrase": "",
                "withOneOrMore": "",
                "withoutTheWords": "",
                "recommendResult": "",
                "indexEnabled": false,
                "sid":""
            }
        });
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var result= response.getReturnValue();
                if(!$A.util.isEmpty(result) && !$A.util.isEmpty(result.result)){
                    var total = result.result.total;
                    component.set("v.totalResults",total);  
                    result.result.hits = result.result.hits.map(d=>{
                        if(d.metadata){
                            d.metadata.map(m=>{
                                if(m.key == 'Category' && m.value.length>=2){
                                    d.pfamily = m.value[1]
                                } 
                                return m;
                            })
                        }
                        return d;
                    });
                    component.set("v.autosuggestList",result.result.hits);
                }
            }
            else{
                $A.log("Errors", response.getState());
            }
        });
        $A.enqueueAction(action);
    },
    createAggregationFilter : function(component,result){
        if(result !==  undefined && result !== null) {            
            if(result.searchString !== undefined && component.get("v.searchString").length !== 0){
                component.set("v.searchString", result.searchString);
            }
            var sourceType = result.sourceType;
            var valueType = result.valueFilter;
            var totalResult = String(result.pageSize);
            if((sourceType !== undefined && valueType !== undefined) && (sourceType !== '' && valueType !== '')){
                var sourceFilter = sourceType.split(';');
                var valueFilter = valueType.split(';');
                var finalJson = '[';
                var totalAggr = '';
                for(var i=0; i<sourceFilter.length; i++){
                    if(valueFilter[i] != '' && valueFilter[i] != undefined && valueFilter[i] != 'undefined'){
                        var secondFilterChild = valueFilter[i].split('|');
                        if(secondFilterChild.length > 0){
                            var childValue = '';
                            totalAggr += '{"type":"'+sourceFilter[i]+'","filter":[';
                            for(var j=0; j<secondFilterChild.length; j++){
                                childValue += '"'+secondFilterChild[j]+'",';
                            }
                            childValue = childValue.slice(0,childValue.length-1);
                            totalAggr += childValue+']},';
                        }else
                            totalAggr += '{"type":"'+sourceFilter[i]+'","filter":["'+valueFilter[i]+'"]},';
                    }
                }
                
                totalAggr = totalAggr.slice(0, totalAggr.length -1);
                finalJson = finalJson+totalAggr+']';
                if(finalJson != ''){
                    component.set('v.aggregation', finalJson);
                }
            }
            if(totalResult != undefined && totalResult != ''){
                component.set("v.pagesize", totalResult);
            }
        }     
    }
})