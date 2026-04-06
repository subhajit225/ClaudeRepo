({
    doInitFunc: function (component, event, helper) {
        var translation = window.scConfigObj.language;
        if (translation[window.localStorage.getItem("language")]) {
            component.set('v.directionText', translation[window.localStorage.getItem("language")].type);
        }
        component.set("v.translationObj", JSON.parse(translation));
        helper.translationFunc(component, event, helper);
        helper.getCustomSettingValue(component, event, helper);
    },
    translationFunc: function(component, event, helper) {
        var translation = component.get("v.translationObj")[0];
        var lang = window.localStorage.getItem("language") || 'en';
        var langSource = window.localStorage.getItem("languagePriority");
        if(!langSource || langSource === 'config'){
            lang = translation['config'].defaultLanguage["code"] || 'en';
        }
        var arrayLang = {};
        if (translation[lang]) {
            for (var key in translation[lang].mapping) {
                let newKey = key;
                //if(customWords.indexOf(key) >= 0)
                newKey = key.replace(new RegExp(/[/\W|_/]/gi), '_')
                arrayLang[newKey] = translation[lang].mapping[key];

            }
        }
        component.set("v.finalLang", arrayLang);
    },
    getCustomSettingValue: function (component, event, helper) {
        var action = component.get("c.getCommunityCustomSettings");
        var permission = '';
        action.setParams({
            "authParams": {
                "permission": permission
            }
        });
        action.setCallback(this, function (response) {
            if (component.isValid() && response.getState() == "SUCCESS") {
                var result = response.getReturnValue();
                if (result.isCustomSettingFilled) {
                    component.set("v.endPoint", result.endPoint);
                    component.set("v.uid", result.uid);
		            component.set("v.Bearer",result.token);
                    component.set("v.currentCommunityURL", result.currentCommURL);
                    component.set("v.customSettingErrorMessage", "");
                    component.set("v.searchString", helper.getURLParameter('searchString') || '');
                    if(result.UserType == "Guest" || result.UserType == undefined){
                        result.userEmail = '';
                    }
                    if (result.userEmail != null && result.userEmail != '') {
                        component.set("v.currentUserEmail", result.userEmail);
                    }
                    let searchPageUrl = window.location.href.split('#')[0].split('?')[0] == component.get('v.currentCommunityURL') ? true : false
                    if (!searchPageUrl) component.set("v.redirectThroughUrl", true);
                    component.set("v.customSettingsFilled", result.isCustomSettingFilled);
		    helper.getValueFunc(component, event, helper);
                } else {
                    component.set("v.customSettingErrorMessage", 'Please configure your SearchUnify and try again.');
                }
            }
            else {
                console.log("Failed with state: " + response.getState());
            }
        });
        $A.enqueueAction(action);
    },
    getURLParameter: function (param) {
        var m = window;
        var s = m.document.URL;
        //var result=decodeURIComponent((new RegExp('[?|&]' + param + '=' + '([^&;#]+?)(&|#|;|$)').exec(s)||[,""])[1].replace(/\+/g, '%20'));
        var result = decodeURIComponent((new RegExp('[?|&|#]' + param + '=' + '([^&;#]+?)(&|#|;|$)').exec(decodeURIComponent(s)) || [, ""])[1].replace(/\+/g, '%20'));
        return result;
    },
    redirectFunc: function (component, SearchQuery, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        
        var url;
        var agg;
        component.set("v.buttonPress", true);
        if(component.get("v.firstLoad") == 1  || component.get("v.redirectThroughUrl")) {
            if(window.location.hash == ""){
                window.location.hash = encodeURIComponent("searchString="+encodeURIComponent(SearchQuery)+"&pageNum="+helper.getURLParameter("pageNum")+"&sortBy="+helper.getURLParameter("sortBy")+"&orderBy=desc&resultsPerPage="+helper.getURLParameter("resultsPerPage")+"&pageSizeAdv="+helper.getURLParameter("pageSizeAdv")+"&exactPhrase="+encodeURIComponent(helper.getURLParameter('exactPhrase'))+"&withOneOrMore="+encodeURIComponent(helper.getURLParameter('withOneOrMore'))+"&withoutTheWords="+encodeURIComponent(helper.getURLParameter('withoutTheWords'))+"&selectedType="+encodeURIComponent(component.get('v.aggregation'))+"&smartFacets="+encodeURIComponent(component.get("v.isSmartFacets")));
            }
            url = component.get("v.currentCommunityURL") + window.location.hash+encodeURIComponent("&flag=0");
        }
        else            
        	window.location.hash = encodeURIComponent("searchString="+encodeURIComponent(SearchQuery)+"&pageNum="+helper.getURLParameter("pageNum")+"&sortBy="+helper.getURLParameter("sortBy")+"&orderBy=desc&resultsPerPage="+helper.getURLParameter("resultsPerPage")+"&pageSizeAdv="+helper.getURLParameter("pageSizeAdv")+"&exactPhrase="+encodeURIComponent(helper.getURLParameter('exactPhrase'))+"&withOneOrMore="+encodeURIComponent(helper.getURLParameter('withOneOrMore'))+"&withoutTheWords="+encodeURIComponent(helper.getURLParameter('withoutTheWords'))+"&selectedType="+encodeURIComponent(helper.getURLParameter('selectedType'))+"&smartFacets="+encodeURIComponent(component.get("v.isSmartFacets")));
        
        if (url == window.location.href) {
            $A.get('e.force:refreshView').fire();
        } else if (component.get("v.firstLoad") == 1  || component.get("v.redirectThroughUrl")){
            component.set("v.firstLoad", 0);
            urlEvent.setParams({
                "isredirect": false,
                "url": url
            });
            urlEvent.fire();
        } 
        else {
            window.location.hash = encodeURIComponent("searchString="+encodeURIComponent(SearchQuery)+"&pageNum="+helper.getURLParameter("pageNum")+"&sortBy="+helper.getURLParameter("sortBy")+"&orderBy=desc&resultsPerPage="+helper.getURLParameter("resultsPerPage")+"&pageSizeAdv="+helper.getURLParameter("pageSizeAdv")+"&exactPhrase="+encodeURIComponent(helper.getURLParameter('exactPhrase'))+"&withOneOrMore="+encodeURIComponent(helper.getURLParameter('withOneOrMore'))+"&withoutTheWords="+encodeURIComponent(helper.getURLParameter('withoutTheWords'))+"&selectedType="+encodeURIComponent(helper.getURLParameter('selectedType')));
            
        }
        
        //helper.fillSearchBoxEventFire(component, event, helper);

    },
    fillSearchBoxEventFire: function (component, event, helper) {
        var SearchQuery = helper.getURLParameter('searchString');
        var searchBoxEvent = $A.get("e.su_vf_console:fillSearchBox");
        searchBoxEvent.setParams({ "searchString": SearchQuery });
        searchBoxEvent.fire();
    },
    searchButtonPressFunc: function (component, event, helper) {
        var SearchQuery = component.get("v.searchString");
        if (SearchQuery != null && SearchQuery != '' && SearchQuery != undefined) {
            SearchQuery = SearchQuery.trim();
            if (SearchQuery.length > 1) {
                document.getElementById('su-suggestions').classList.add('su-hidePanel');
                clearTimeout(component.get('v.timer'));
                helper.redirectFunc(component, SearchQuery, helper);
            }
            else{
                 var toastEvent = $A.get("e.force:showToast");
                         toastEvent.setParams({
                                "message": "You must enter at least 2 characters to search",
                                "type": 'warning'
                          });
                          toastEvent.fire();
               }
        }
        else{
            var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                               "message": "You must enter at least 2 characters to search",
                               "type": 'warning'
                         });
                         toastEvent.fire();
       }
    },
    enterKeySearchFunc: function (component, event, helper) {
        component.set("v.smartFacetClick", false);
        var SearchQuery = component.get("v.searchString");
        if (SearchQuery != null && SearchQuery != '' && SearchQuery != undefined) {
            SearchQuery = SearchQuery.trim();
        }
        if (SearchQuery.length > 1) {
            if (event.getParams().domEvent.keyCode == 13) {
                if(document.getElementById('su-suggestions')) {
                	document.getElementById('su-suggestions').classList.add('su-hidePanel');    
                }
                clearTimeout(component.get('v.timer'));
                helper.redirectFunc(component, SearchQuery, helper);
            } else if(event.getParams().domEvent.keyCode != 37 && event.getParams().domEvent.keyCode != 38 && event.getParams().domEvent.keyCode != 39 && event.getParams().domEvent.keyCode != 40) {
                var currentString = component.get("v.searchString");
                component.set("v.currentString", currentString);
                component.set("v.linkToOpen",null);
                var delayCounter = component.get("v.delayCounter");
                var timer = component.get('v.timer');
                component.set("v.buttonPress", false);
                clearTimeout(timer);
                if (delayCounter == 0) {
                    component.set("v.delayCounter", 1);
                    timer = window.setTimeout(
                        $A.getCallback(function () {
                            SearchQuery = component.get("v.searchString");
                            SearchQuery = SearchQuery.trim();
                            if ( SearchQuery != '' && component.get("v.customSettingsFilled") && component.get("v.Bearer")) {
                                helper.autosearchFunc(component, 'autosuggestion', 'false', helper);
                            }
                            clearTimeout(timer);
                            component.set('v.timer', null);
                            //component.set("v.delayCounter",0);
                        }), 600);
    				component.set("v.index",-1)
                    component.set('v.timer', timer);
                    component.set("v.delayCounter", 0);
                }
            } else{
                if(event.getParams().domEvent.keyCode == 40 || event.getParams().domEvent.keyCode == 38){
                    let length = document.getElementsByClassName("su-autoSuggest-element").length;
                    let index = component.get("v.index");
                    if(index>-1 && index<length){
                        document.getElementsByClassName("su-autoSuggest-element")[index].classList.remove('selected');
                    }
                    if((event.getParams().domEvent.keyCode == 40 && index < length) || (event.getParams().domEvent.keyCode == 38 && index >-1)){
                        event.getParams().domEvent.keyCode == 40 ? index++ : index--;
                        component.set('v.index',index);
                        if(document.getElementsByClassName("su-autoSuggest-element")[index]){
                        	document.getElementsByClassName("su-autoSuggest-element")[index].focus();
                            if(component.find('searchBoxInput')){
                            setTimeout(function() {
                                           component.find('searchBoxInput').focus(); 
                                }, 10) 
                            }
                        } 
                        if(document.getElementsByClassName("su-autoSuggest-element") && document.getElementsByClassName("su-autoSuggest-element")[index]) {
                            document.getElementsByClassName("su-autoSuggest-element")[index].classList.add('selected');
                        }
                        var newSearchQuery = document.getElementsByClassName("su-autoSuggest-element")[index].getElementsByTagName("span")[0].id
                        component.set("v.linkToOpen", document.getElementsByClassName("su-autoSuggest-element")[index].getElementsByTagName("span")[0].getAttribute('data-url'));
                        if (!component.get("v.isEnableTitleRedirect") || !component.get("v.linkToOpen"))
                        	component.set("v.searchString",newSearchQuery);
                        var target = document.getElementsByClassName("su-autoSuggest-element")[index].getElementsByTagName("span")[0];
                        var dataObj = {};
                        
                        document.getElementById("autosuggestElement").scrollTop = document.querySelector(".su-autoSuggest-element.selected").offsetTop + document.querySelector(".su-autoSuggest-element.selected").offsetHeight -document.getElementById("autosuggestElement").offsetHeight;
                        
                        dataObj.data_Id = target.getAttribute("data-id") || "";
                        dataObj.data_type = target.getAttribute("data-type") || "";
                        dataObj.data_index = target.getAttribute("data-index") || "";
                        dataObj.data_rank = target.getAttribute("data-rank") || "";
                        dataObj.data_url = target.getAttribute("data-url") || "";
                        dataObj.data_sub = target.getAttribute("data-subject") || "";
                        dataObj.result_count = target.getAttribute("data-Count") || 0;
                        dataObj.data_trackAnalytics = target.getAttribute("data-trackAnalytics") || [];
                        component.set('v.dataObj', dataObj);
                    }
                }
            }
        } else {
            if (event.getParams().domEvent.keyCode == 13) {
            var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "message": "You must enter at least 2 characters to search",
                        "type": 'warning'
                    });
                    toastEvent.fire();
            } 
        }
    },
    mouseleftFunc: function (component, event) {
        setTimeout(function () {
            let smartLength = component.get("v.smartAggregations");
            
            if(smartLength && smartLength.length && component.get("v.smartFacetClick")){
                return;
            } else if(document.getElementById('autosuggestElement') !== null && document.getElementById('autosuggestElement') !== undefined) {
                //document.getElementById('autosuggestElement').style.display = 'none';
                component.set("v.autosuggestList", []);
                component.set("v.recommendedSearches", []);
                //if(document.getElementById('autosuggestAutoElement') !== null && document.getElementById('autosuggestAutoElement') !== undefined){
                //    document.getElementById('autosuggestAutoElement').style.display = 'none';
                //}
            }
            
        }, 500);
    },
    fillSearchboxFunc: function (component, event, helper) {
        var valueToBeFilled = event.currentTarget.id;
        component.set("v.searchString", valueToBeFilled);
        let searchPageUrl = window.location.href.split('#')[0].split('?')[0] == component.get('v.currentCommunityURL') ? true : false
        if (!searchPageUrl) component.set("v.redirectThroughUrl", true);
        else component.set("v.redirectThroughUrl", false);
        helper.searchButtonPressFunc(component, event, helper);
        helper.fillSearchBoxEventFire(component, event, helper);
    },
    autosearchFunc: function (component, searchType, runLoader, helper) {
        var resultPerSize = '10';
        var aggrValue = "[]";
        // resultPerSize = component.get("v.pagesize");
        if (resultPerSize === 'undefined' || resultPerSize === undefined) { resultPerSize = '10'; } //default handling
        var sourceType = component.get("v.advanceFilterData");
        var sourceValue = component.get("v.advanceFilterValue");
        var filterData;
        if (searchType === 'autosuggestion' && sourceType !== "" && sourceValue !== "") {
            filterData = { "sourceType": sourceType, "valueFilter": sourceValue };
            helper.createAggregationFilter(component, helper, filterData, 1);
            aggrValue = component.get("v.aggregation");
        }
        var searchText = component.get("v.searchString");
        var EmailregexSlash = '\\\\';
        var regexSlash = new RegExp("\\\\", 'g');
        searchText = searchText.replace(regexSlash, EmailregexSlash);
        var Emailregex = '\\"';
        var re = new RegExp("^[\'\"][^\"]*[\"\']$");
        if (!re.test(searchText)) {
            if (searchText[0] != '#') {
                var regex = new RegExp('\"', 'g');
                searchText = searchText.replace(regex, Emailregex);
            }
        }
        var analyticsCmp = component.find("SuAnalytics");
        var sid = analyticsCmp.analytics('_gz_taid', '');
        
        let smartFacetFromSearch = JSON.parse(helper.getURLParameter('smartFacets') || "false");
       		component.set("v.isSmartFacets", smartFacetFromSearch);
        
        //let filterSmart = helper.getURLParameter('selectedType') ? JSON.parse(helper.getURLParameter('selectedType')) : JSON.parse(aggrValue);
        let sendSmartFacets = (analyticsCmp.analytics('smartFacets', '') == "" ||  analyticsCmp.analytics('smartFacets', '') == "true") && localStorage.getItem("AutoLearning") == "true";  
        //&& localSmart && smartFacetFromSearch;
            component.set("v.isSmartFacets", sendSmartFacets);
        
        var data = JSON.stringify({
                "searchString": searchText,
                "from": ((1-1) * resultPerSize),
                "pageNum": 1,
                "sortby": "_score",
                "orderBy": "desc",
                "resultsPerPage": parseInt(resultPerSize),
                "aggregations": helper.getURLParameter('selectedType') ? JSON.parse(helper.getURLParameter('selectedType')) : JSON.parse(aggrValue),
                "referrer": "",
                "exactPhrase": helper.getURLParameter('exactPhrase'),
                "withOneOrMore": helper.getURLParameter('withOneOrMore'),
                "withoutTheWords": helper.getURLParameter('withoutTheWords'),
                "recommendResult": "",
                "indexEnabled": false,
                "sid": sid,
                "uid": component.get("v.uid"),
                "language":localStorage.getItem('language') || 'en',
                "autocomplete": true,
            	"smartFacets": component.get("v.isSmartFacets")
            });
         var xmlHttp = new XMLHttpRequest();
        var url = component.get("v.endPoint")+"/search/SUSearchResults";
        xmlHttp.withCredentials = true;
    	xmlHttp.open( "POST", url, true );
        xmlHttp.setRequestHeader("Accept", "application/json");
        xmlHttp.setRequestHeader('Authorization','bearer ' + component.get('v.Bearer') );
	    xmlHttp.setRequestHeader('Content-Type', 'application/json');
		
	    xmlHttp.send(data);
        xmlHttp.onreadystatechange = function () {
    		if (xmlHttp.readyState === 4) {
    	    	if (xmlHttp.status === 200) {
		        var result = JSON.parse(xmlHttp.response);
                    if(result.statusCode != 402){
                        if(result.searchClientSettings.ViewedResults == 1) {
                            component.set("v.showViewedResults", true);
                        } else {
                            component.set("v.showViewedResults", false);
                        }
                        var total = result.result.total;
                        component.set("v.totalResults", total);
                        if (searchType === 'autosuggestion' && !component.get("v.buttonPress")) {
                            component.set("v.autosuggestList", result.result.hits);
                            component.set("v.recommendedSearches", result.recentSearchHistory);
                            let autoSuggestionResuts=JSON.parse(JSON.stringify(component.get("v.autosuggestList")));
                           if(autoSuggestionResuts.length){
                            component.set("v.showMetadata",true)
                            autoSuggestionResuts.forEach(function(item){ 
                                item.autosuggestData.forEach(function(a){
                                    if(a.key=='Description'){
                                      component.set("v.showResultbody",true)  
                                    }
                                })
                            })
                           }
                            component.set("v.smartAggregations", result.smartAggregations)
                            let smartAggSlice  = JSON.parse(JSON.stringify(component.get("v.smartAggregations")));
                                if(smartAggSlice && smartAggSlice.length){
                                    smartAggSlice.forEach(function(s){
                                        if(s.values.length > 3) {
                                            s.values = s.values.slice(0, 3)
                                        }
                                    });
                                    component.set("v.smartAggregations", smartAggSlice);
                                }                                    
                            if (!$A.util.isEmpty("v.autosuggestList") && document.getElementById('autosuggestElement') !== null && document.getElementById('autosuggestElement') !== undefined) {
                                document.getElementById('su-suggestions').classList.remove('su-hidePanel');
                                document.getElementById('autosuggestElement').style.display = 'block';
                                if(document.getElementById('autosuggestAutoElement') !== null && document.getElementById('autosuggestAutoElement') !== undefined){
                                    document.getElementById('autosuggestAutoElement').style.display = 'block';
                                }
                            }
                        }
                    }else{
                        if(result.statusCode == 402)
                        helper.resetValue(component, helper);
                    }
                }
            }
        }
    },
    createAggregationFilter: function (component, helper, result) {
        if (result !== undefined && result !== null) {
            if (result.searchString !== undefined && component.get("v.searchString").length !== 0) {
                component.set("v.searchString", result.searchString);
            }
            var sourceType = result.sourceType;
            var valueType = result.valueFilter;
            var totalResult = String(result.pageSize);
            if ((sourceType !== undefined && valueType !== undefined) && (sourceType !== '' && valueType !== '')) {
                var sourceFilter = sourceType.split(';');
                var valueFilter = valueType.split(';');
                var finalJson = '[';
                var totalAggr = '';
                for (var i = 0; i < sourceFilter.length; i++) {
                    if (valueFilter[i] != '' && valueFilter[i] != undefined && valueFilter[i] != 'undefined') {
                        var secondFilterChild = valueFilter[i].split('|');
                        if (secondFilterChild.length > 0) {
                            var childValue = '';
                            totalAggr += '{"type":"' + sourceFilter[i] + '","filter":[';
                            for (var j = 0; j < secondFilterChild.length; j++) {
                                childValue += '"' + secondFilterChild[j] + '",';
                            }
                            childValue = childValue.slice(0, childValue.length - 1);
                            totalAggr += childValue + ']},';
                        } else
                            totalAggr += '{"type":"' + sourceFilter[i] + '","filter":["' + valueFilter[i] + '"]},';
                    }
                }

                totalAggr = totalAggr.slice(0, totalAggr.length - 1);
                finalJson = finalJson + totalAggr + ']';
                if (finalJson != '') {
                    component.set('v.aggregation', finalJson);
                }
            }
            if (totalResult != undefined && totalResult != '') {
                component.set("v.pagesize", totalResult);
            }
        }
    },
    
    getValueFunc : function (component, event, helper) {
        	var myEvent = component.getEvent("getValue");
            var myEvent = $A.get("e.su_vf_console:SUComponentEvent");
            let obj = {"searchString": component.get("v.searchString"),
                       "endPoint" : component.get("v.endPoint"),
                       "uid" : component.get("v.uid"),
                       "Bearer" : component.get("v.Bearer"),
                       "customSettingsFilled" : component.get("v.customSettingsFilled"),
                       "currentCommunityURL" : component.get("v.currentCommunityURL"),
                       "currentUserEmail" : component.get("v.currentUserEmail"),
                       "customSettingErrorMessage" : component.get("v.customSettingErrorMessage"),
                       "commBaseURL" : component.get("v.commBaseURL"),
                      }

            myEvent.setParams({"searchObject" : obj});
	    if(!component.get("v.redirectThroughUrl"))
            	myEvent.fire();
    },
    resetValue: function (component, helper) {
        var action = component.get("c.getCommunityCustomSettings");
        var permission = '';
        action.setParams({
            "authParams": {
                "permission": permission
            }
        });
        action.setCallback(this, function (response) {
            if (component.isValid() && response.getState() == "SUCCESS") {
                var result = response.getReturnValue();
                if (result.isCustomSettingFilled) {
                    component.set("v.endPoint", result.endPoint);
                    component.set("v.uid", result.uid);
		            component.set("v.Bearer",result.token);
                    component.set("v.currentCommunityURL", result.currentCommURL);
                    component.set("v.customSettingErrorMessage", "");
                    //component.set("v.searchString", helper.getURLParameter('searchString') || '');
                    if(result.UserType == "Guest" || result.UserType == undefined){
                        result.userEmail = '';
                    }
                    if (result.userEmail != null && result.userEmail != '') {
                        component.set("v.currentUserEmail", result.userEmail);
                    }
                    component.set("v.customSettingsFilled", result.isCustomSettingFilled);
                    var SearchQuery = component.get("v.searchString") || '';
                    SearchQuery = SearchQuery.trim();
                    if ( SearchQuery != '' )
                    	helper.autosearchFunc(component, 'autosuggestion', 'false', helper);
                } else {
                    component.set("v.customSettingErrorMessage", 'Please configure your SearchUnify and try again.');
                }
            }
            else {
                console.log("Failed with state: " + response.getState());
            }
        });
        $A.enqueueAction(action);
    }
})