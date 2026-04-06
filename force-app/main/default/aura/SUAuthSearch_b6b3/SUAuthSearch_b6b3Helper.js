({
    redirectFunc: function(component, SearchQuery, eventHit, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "isredirect": false,
            "url": component.get("v.currentCommunityURL") + "?searchString=" + encodeURIComponent(SearchQuery)
        });
        urlEvent.fire();
        if (eventHit === 'suggest') {
            helper.fillSearchBoxEventFire(helper);
        }
    },
    fillSearchBoxEventFire: function(helper) {
        var SearchQuery = helper.getURLParameter('searchString');
        var searchBoxEvent = $A.get("e.su_vf_console:fillSearchBox");
        searchBoxEvent.setParams({ "searchString": SearchQuery });
        searchBoxEvent.fire();
    },
    filtersPopupFunc: function(component, event, helper) {

        var resultIndex = event.target.id;
        var aggregationsData = component.get("v.aggregationsData");
        if (resultIndex) {
            aggregationsData[resultIndex].isCollapsed = !aggregationsData[resultIndex].isCollapsed;
            component.set("v.aggregationsData", aggregationsData);
        } else {
            for (var i = 0; i < aggregationsData.length; i++) {
                aggregationsData[i].isCollapsed = false;
            }
            component.set("v.aggregationsData", aggregationsData);
        }

    },

    sortByName: function(component, field) {
        field.sort(function(a, b) {
            if (typeof a.displayName == "string" || typeof a.Contentname == "string") {
                if (a.displayName && b.displayName) {
                    var textA = a.displayName.toUpperCase();
                    var textB = b.displayName.toUpperCase();
                } else {
                    var textA = a.Contentname.toUpperCase();
                    var textB = b.Contentname.toUpperCase();
                }
                return (textA < textB) ? -1 : (textA > textB) ? 1 : 0;
            } else {
                if (a.displayName && b.displayName) {
                    return parseFloat(a.displayName) - parseFloat(b.displayName);
                } else {
                    return parseFloat(a.Contentname) - parseFloat(b.Contentname);
                }
            }
        });
    },
    sortByDesc: function(component, field) {
        field.sort(function(a, b) {
            if (typeof a.value == "number") {
                if (a.value) {
                    return parseFloat(a.value) - parseFloat(b.value);
                } else {
                    return parseFloat(a.value) - parseFloat(b.value);
                }
            }
        });
    },
    sortByAsc: function(component, field) {
        field.sort(function(a, b) {
            if (typeof a.value == "number") {
                if (a.value) {
                    return parseFloat(b.value) - parseFloat(a.value);
                } else {
                    return parseFloat(b.value) - parseFloat(a.value);
                }
            }
        });
    },
    refineButtonpressFunc: function(component, event, helper) {
        var pageSize = component.get("v.pageSizeAdvFiltr");
        component.set("v.pageSize", pageSize);

        component.set("v.pageNum", "1");
        if (component.get("v.exactPhrase") == "" || component.get("v.withOneOrMore") == "" || component.get("v.withoutTheWords") == "") {
            component.set("v.advanceSearchEnabled", false);
        } else{
            component.set("v.advanceSearchEnabled", true);
        }
 

        //window.location.hash = encodeURIComponent("pageNum=1&sortBy="+component.get("v.sortByCheck")+"&orderBy=desc&resultsPerPage="+component.get("v.pageSize")+"&exactPhrase="+decodeURIComponent(component.get("v.exactPhrase"))+"&withOneOrMore="+decodeURIComponent(component.get("v.withOneOrMore"))+"&withoutTheWords="+decodeURIComponent(component.get("v.withoutTheWords"))+"&selectedType="+helper.getURLParameter('selectedType')+"&contentSources="+helper.getURLParameter('contentSources')+"&active="+helper.getURLParameter('active'));
        //window.location.hash = encodeURIComponent("pageNum=1&sortBy="+component.get("v.sortByCheck")+"&orderBy=desc&resultsPerPage="+component.get("v.pageSize")+"&exactPhrase="+encodeURIComponent(component.get("v.exactPhrase"))+"&withOneOrMore="+encodeURIComponent(component.get("v.withOneOrMore"))+"&withoutTheWords="+encodeURIComponent(component.get("v.withoutTheWords"))+"&selectedType="+encodeURIComponent(helper.getURLParameter('selectedType')));
        if(component.get("v.customSettingsFilled") && component.get("v.Bearer")) {
			window.location.hash = encodeURIComponent("searchString="+encodeURIComponent(helper.getURLParameter("searchString"))+"&pageNum=1&sortBy="+component.get("v.sortByCheck")+"&orderBy=desc&resultsPerPage="+component.get("v.pageSize")+"&pageSizeAdv="+component.get("v.pageSizeAdvFiltr")+"&exactPhrase="+encodeURIComponent(component.get("v.exactPhrase"))+"&withOneOrMore="+encodeURIComponent(component.get("v.withOneOrMore"))+"&withoutTheWords="+encodeURIComponent(component.get("v.withoutTheWords"))+"&selectedType="+encodeURIComponent(helper.getURLParameter('selectedType')));
        	helper.getValue(component, 'search' , 'true', helper);
        }
    },
    updateResultsPerPage: function(component, event, helper) {
        var pageSize = component.get("v.pageSizeAdvFiltr");
        component.set("v.pageSize", pageSize);
        component.set("v.pageNum", "1");
        if(component.get("v.customSettingsFilled") && component.get("v.Bearer")) {
			window.location.hash = encodeURIComponent("searchString="+encodeURIComponent(helper.getURLParameter("searchString"))+"&pageNum=1&sortBy="+component.get("v.sortByCheck")+"&orderBy=desc&resultsPerPage="+component.get("v.pageSize")+"&pageSizeAdv="+component.get("v.pageSizeAdvFiltr")+"&exactPhrase="+encodeURIComponent(component.get("v.exactPhrase"))+"&withOneOrMore="+encodeURIComponent(component.get("v.withOneOrMore"))+"&withoutTheWords="+encodeURIComponent(component.get("v.withoutTheWords"))+"&selectedType="+encodeURIComponent(helper.getURLParameter('selectedType')));
        	helper.getValue(component, 'pagesize' , 'true', helper);
        }
    },
    clientSettingsFunc: function(component, event, searchQuery, helper) {
        var action = component.get("c.getCommunityCustomSettings");
        var permission = ''
        action.setParams({
            "authParams": {
                "permission": permission
            }
        });
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var result = response.getReturnValue();
                if (result.isCustomSettingFilled) {
                    component.set("v.endPoint", result.endPoint);
                    component.set("v.uid", result.uid);
                    component.set("v.currentCommunityURL", result.currentCommURL);
                    component.set("v.customSettingErrorMessage", "");
                    component.set("v.commBaseURL", result.commBaseURL);
                    component.set("v.Bearer", result.token);
                    component.set("v.customSettingsFilled", result.isCustomSettingFilled);
                    component.set("v.selectedTypeFilter", localStorage.getItem("selectedFilter") || "");
                    component.set("v.pageNum", "1");
                    component.set("v.searchString", searchQuery);
                    if (component.get("v.customSettingsFilled") && component.get("v.Bearer")) {
                        var c = JSON.parse(localStorage.getItem('theme' + component.get("v.uid")));
                        if (c) {
                            component.set("v.toggleDisplayKeys[0].hideEye", c.hideTitle);
                            component.set("v.toggleDisplayKeys[1].hideEye", c.hideSummary);
                            component.set("v.toggleDisplayKeys[3].hideEye", c.hideMetadata);
                            component.set("v.toggleDisplayKeys[2].hideEye", c.hideUrl);
                            component.set("v.toggleDisplayKeys[4].hideEye", c.hideIcon);
                            component.set("v.toggleDisplayKeys[5].hideEye", c.hideTag);
                            component.set("v.filterToRight", c.filters);
                            if (c.activeTabIndex != 'all' && c.activeTabIndex != undefined) {
                                component.set("v.active", c.defaultTab.indexOf('merged_') > -1 ? c.defaultTab : c.activeTabIndex);
                                component.set("v.defaultTab", c.defaultTab.indexOf('merged_') > -1 ? c.defaultTab : c.activeTabIndex);
                                component.set("v.activeMergedChild", c.defaultTab.indexOf('merged_') > -1 ? c.activeMergedChild : '');
                                var filterValue = '[{"type":"_index","filter":["' + c.activeTabIndex + '"]}]';
                                component.set("v.selectedTypeFilter", filterValue);
                            }

                            if (c.hideTitle == true) {
                                component.get("v.hiddenKeys").push("Title");
                            }
                            if (c.hideSummary == true) {
                                component.get("v.hiddenKeys").push("Summary");
                            }
                            if (c.hideMetadata == true) {
                                component.get("v.hiddenKeys").push("Metadata");
                            }
                            if (c.hideUrl == true) {
                                component.get("v.hiddenKeys").push("Url");
                            }
                            if (c.hideIcon == true) {
                                component.get("v.hiddenKeys").push("Icon");
                            }
                            if (c.hideTag == true) {
                                component.get("v.hiddenKeys").push("Tag");
                            }
                        }
                        component.set("v.caller", false);
                        component.set("v.setFlag", true);
                        helper.getValue(component, 'search', 'true', helper);
                    }
                } else {
                    component.set("v.customSettingErrorMessage", 'Please configure your SearchUnify and try again.');
                }
            } else {
                $A.log("Errors", response.getState());
            }
        });
        $A.enqueueAction(action);
    },

    getAdv: function(component, event) {
       	const xhr = new XMLHttpRequest();
        let searchString =component.get("v.searchString");
        if(searchString.toLowerCase().indexOf('rbk') != -1){
            searchString = searchString.replace(/[0-9*]/g, '');
        }
        component.set("v.noResultAdvertisement", false);
        const url = component.get("v.endPoint") + "/admin/searchClient/readAdHTML/" + component.get("v.uid") + "?phrase=" + searchString;
        xhr.open('GET', url, true);
        xhr.onload = function() {
            if (this.status === 200) {
                const response = JSON.parse(this.responseText).htmlString;
                component.set("v.advertisement", response);
                if(response){
                    component.set("v.noResultAdvertisement", true);
                }
            }
        };
        xhr.send();
    },

    getSearchExp: function(component, event) {
        if(typeof component.get("v.endPoint")!= 'undefined'){
            var xmlHttp = new XMLHttpRequest();
            const url = component.get("v.endPoint")+ "/pageRating/getPageRatingData";
            xmlHttp.open( "POST", url, true );
            xmlHttp.setRequestHeader("Accept", "application/json");
            xmlHttp.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
            xmlHttp.send('uid='+component.get("v.uid"));
            xmlHttp.onreadystatechange = function () {
                if (xmlHttp.readyState === 4) {
                    if (xmlHttp.status === 200) {
                        var feedbackResponse = JSON.parse(xmlHttp.response);
                        var searchFeedback = JSON.parse(feedbackResponse.searchFeedback);
                        component.set("v.getFeedbackResData", searchFeedback); 
                        component.set("v.responseSearchFeedbackData", searchFeedback)
                        // regexResult = helper.regexMatch(component, event, helper, regexResult);
                        // if(regexResult.found == 1){
                        //    var regexData = JSON.parse(xmlHttp.response);
                        //    regexData = helper.instanceRegexMatch(component, event, helper, regexData);
                        //    if(regexData.found == 1){
                        //        component.set("v.suResponseValues",  true);
                        //    }
                        // }
                    }
                }
            }
        }
    },

    goToTopFunc: function(component, event) {
        document.body.scrollTop = 0;
        document.documentElement.scrollTop = 0;
    },
    getURLParameter: function(param) {
        var m = window;
        // var s = m.document.URL;
        var s = m.location.href; //Change for IE/Edge
        var result;
        let str = s;

        if(window.location.hash != "") {
            str = s.slice(0, s.indexOf(window.location.hash));
        }

        /*if(param == "searchString"){

            result = decodeURIComponent((new RegExp('[?|&]' + param + '=' + '([^&;]+?)(&|#|;|$)').exec(str) || [, ""])[1].replace(/\+/g, '%20'))
        }
        else*/
            result = decodeURIComponent((new RegExp('[#|s?|&]' + param + '=' + '([^&;]+?)(&|#|;|$)').exec(decodeURIComponent(s)) || [, ""])[1].replace(/\+/g, '%20'))

        return result;
    },
    doInitialization: function(component, event, helper) {
        var searchQuery = '';
        var sortings = [{
                "method_name": "Relevance",
                "value": "_score"
            },
            {
                "method_name": "Created Date",
                "value": "post_time"
            }
        ];
        component.set("v.sortByValues", sortings);
        var filterValue = '[{"type":"_index","filter":c.activeTabIndex}]';
        component.set("v.selectedTypeFilter", "");
        var toggleKeys = [{ 'key': 'Title', 'hideEye': false }, { 'key': 'Summary', 'hideEye': false }, { 'key': 'Url', 'hideEye': false }, { 'key': 'Metadata', 'hideEye': false }, { 'key': 'Icon', 'hideEye': false }, { 'key': 'Tag', 'hideEye': false }];
        component.set("v.toggleDisplayKeys", toggleKeys);
        component.set("v.defaultPageSize", component.get("v.pageSize"));
        component.set("v.selectedTypeFilter", "");
        component.set("v.bookmarkSearches", JSON.parse(localStorage.getItem('bookmark_searches_' + component.get("v.uid")) || "[]"));
        searchQuery = helper.getURLParameter('searchString');
        if (searchQuery != null && searchQuery != undefined) {
            component.set("v.searchString", searchQuery);
            component.set("v.pageNum", "1");

            /*if (helper.getURLParameter("flag") == 1) {
                helper.clientSettingsFunc(component, event, searchQuery, helper);
                component.set("v.caller", true);
            } else {*/
                component.set("v.setFlag", true);
                helper.fillSearchBoxEventFire(helper);
            // }
        } else {
            component.set("v.totalResults", 0);
            component.set("v.errorMessage", "Please enter a valid search term.");
        }

        document.addEventListener('mousedown', function(e) {
            helper.runScriptMethodFunc(component, e, helper);
        });
        document.addEventListener('scroll', function(e) {

            if (window.pageYOffset > 100) {

                component.set("v.showScroll", true);
            } else

                component.set("v.showScroll", false);
        });
        component.set("v.componentLoaded", true);
    },
    searchSuggestFunc: function(component, event, helper) {
        var searchQuery = event.target.text;
        if (searchQuery != null && searchQuery != '' && searchQuery != undefined) {
            searchQuery = searchQuery.trim();
        }
        helper.redirectFunc(component, searchQuery, 'suggest', helper);
    },
    sortCallFunc: function(component, event, helper) {
        if(component.find('mySelect')) {
            var sortByValue = component.find('mySelect').get('v.value');
        } else {
             sortByValue = helper.getURLParameter('sortBy') != "" ? helper.getURLParameter('sortBy') : "_score";  
        }
        component.set("v.sortByCheck", sortByValue);

        component.set("v.pageNum", "1");
        if (component.get("v.customSettingsFilled") && component.get("v.Bearer"))
            helper.getValue(component, 'sortBy', 'true', helper);
    },

    searchTipsToggleFunc: function(component, event, helper) {

        let flag = component.get("v.searchTipsTab");

        let element = document.getElementsByClassName("su__right-sidebar")[0];

        if (flag) {

            if (element.classList.contains("su__search-tip-toggle")) {

                element.classList.remove("su__search-tip-toggle");

                document.body.classList.remove('su__overflow-hidden');
            } else {

                helper.viewMoreToggleFunc(component, event, helper);

                element.classList.add("su__search-tip-toggle");

                document.body.classList.add('su__overflow-hidden');
            }

        } else {
            element.classList.remove("su__search-tip-toggle");

            document.body.classList.remove('su__overflow-hidden');
        }

        component.set("v.searchTipsTab", false);

    },
    viewMoreToggleFunc: function(component, event, helper) {

        let flag = component.get("v.viewMoreTab");

        let element = document.getElementsByClassName('su__viewMore')[0];

        if (flag) {

            if (element.classList.contains('su__top-toggle')) {

                element.classList.remove('su__top-toggle');

                document.body.classList.remove('su__overflow-hidden');

            } else {
                element.classList.add('su__top-toggle');

                document.body.classList.add('su__overflow-hidden');
            }

        } else {
            element.classList.remove('su__top-toggle');

            document.body.classList.remove('su__overflow-hidden');
        }

        component.set("v.viewMoreTab", false);
    },
    bookmarkList_toggleFunc: function(component, event, helper) {

        let flag = component.get("v.bookmarkTab");

        component.set("v.viewConfirmPopup", false);

        component.set("v.viewSavePopup", false);

        component.set("v.bookmark_list", !component.get("v.bookmark_list"));

        if (flag) {

            if (document.body.classList.contains('su__overflow-hidden')) {

                document.body.classList.remove('su__overflow-hidden');
            } else {

                helper.viewMoreToggleFunc(component, event, helper);

                document.body.classList.add('su__overflow-hidden');

            }
        } else {
            document.body.classList.remove('su__overflow-hidden');

            component.set("v.bookmark_list", false);

        }

        component.set("v.bookmarkTab", false);

    },
    collapseFiltersFunc: function(component, event, helper) {
        var currentId = event.target.id;
        var childId = currentId.split('_icon')[0];
        var facetIcon = childId.split('-')[1];
        var divTocollapse = document.getElementById(childId);
        var openIcon = document.getElementById(childId + '_toggleIconOn');
        var closeIcon = document.getElementById(childId + '_toggleIconOff');
        var searchIcon = document.getElementsByClassName('facetIcon-'+facetIcon)[0].parentElement;
        if (divTocollapse.classList.contains('in')) {
            openIcon.classList.remove('su_displayBlock');
            openIcon.classList.add('su_displayHide');
            closeIcon.classList.remove('su_displayHide');
            closeIcon.classList.add('su_displayBlock');
            searchIcon.classList.add('su__d-none');
            searchIcon.classList.remove('su__d-block')
            divTocollapse.classList.remove('in');
        } else {
            closeIcon.classList.remove('su_displayBlock');
            closeIcon.classList.add('su_displayHide');
            openIcon.classList.remove('su_displayHide');
            openIcon.classList.add('su_displayBlock');
            searchIcon.classList.remove('su__d-none');
            searchIcon.classList.add('su__d-block');
            divTocollapse.classList.add('in');
        }
    },
    collapseVersionsFunc: function (component, event, helper) {
        var currentId = event.target.id;
            if(currentId.includes('_toggleIcon')){
                var childId = currentId.split('_toggleIcon')[0];
            }
            else if(currentId.includes('_overlay')) {
                var childId = currentId.split('_overlay')[0];
            } else {
                var childId = currentId.split('_icon')[0];
            }
            
            var overlayId = document.getElementById(childId+'_overlay');
            var divTocollapse = document.getElementById(childId);
             var openIcon = document.getElementById(childId + '_toggleIcon');
            if (divTocollapse.classList.contains('in')) {
                divTocollapse.classList.remove('in');
                overlayId.classList.remove('in');
                openIcon.classList.remove('su_displayBlock');
                openIcon.classList.add('su_displayHide');
    
            } else {
                divTocollapse.classList.add('in');
                overlayId.classList.add('in');
                openIcon.classList.remove('su_displayHide');
                openIcon.classList.add('su_displayBlock');
            }
    },
    collapseShowHide: function(component, event, helper) {
        var translation = component.get("v.translationObj");
        var showLess = 'Show less';
        var showMore = 'Show more';
        if (translation[window.localStorage.getItem("language")]) {
            if (translation[window.localStorage.getItem("language")].mapping[showLess]) {
                showLess = translation[window.localStorage.getItem("language")].mapping[showLess];
            }
            if (translation[window.localStorage.getItem("language")].mapping[showMore]) {
                showMore = translation[window.localStorage.getItem("language")].mapping[showMore];
            }
        }
        var id = event.target.id;
        var slittedId = id.split('_showMore')[0];
        var data = document.getElementById(slittedId);
        if (data.classList.contains('su_nonExpanded')) {
            data.classList.remove('su_nonExpanded');
            document.getElementById(id).innerHTML = showLess+'<span class="su__position-absolute su__showless-icon">&#171;</span>';
        } else {
            data.classList.add('su_nonExpanded');
            document.getElementById(id).innerHTML = showMore+'<span class="su__position-absolute su__showmore-icon">»</span>';
        }
    },
    typeSelectFunc: function (component, event, helper, flag, itemRemoved) {
        if(!flag){
           
    
            var value = document.getElementById(event.target.id).checked;

            var clickedFilter = {};
            clickedFilter["Contentname"]= event.target.name,
            clickedFilter["immediateParent"]= event.target.min,
            clickedFilter["parent"]= event.target.step || event.target.getAttribute('data-item'),
            clickedFilter["level"]= event.target.max
            clickedFilter["checked"]= document.getElementById(event.target.id).checked;
            clickedFilter["label"]= event.target.getAttribute('data-label');
            clickedFilter["name"]= event.target.getAttribute('data-name');
            clickedFilter["path"]= event.target.getAttribute('data-path');
            clickedFilter['sortMethod'] = event.target.getAttribute('data-sort'); 
            
        }
        else {
            var clickedFilter = itemRemoved;
            // document.getElementById(clickedFilter.parent+'_checkType_'+clickedFilter.Contentname).checked = flag == 2 ? clickedFilter.checked : false;
        }
        if(!component.get("v.filterSortingLoading")) {
            component.set("v.pageNum", '1');
            component.set("v.fromPage",1);
        }
    
        var setArray = component.get("v.aggregationsData") || [];
        var currentFilterOrder = setArray.find(function (f) { if (f.key == clickedFilter.parent) return f; })
        component.set("v.currentClickedOrder", currentFilterOrder);
        
        
        var aggregations = JSON.parse(component.get("v.selectedTypeFilter") || "[]");
            
        var obj = {
                "childName":clickedFilter.Contentname,
                "level":clickedFilter.level,
            };
        if (clickedFilter.level!=1)
                obj.path = clickedFilter.path || [];
    
        // if aggregations empty
        if(!aggregations.length && clickedFilter.Contentname == undefined){
            aggregations.push({
                "type": clickedFilter.parent,
                "sort": clickedFilter.sortMethod
            })
        }
        else if(!aggregations.length && clickedFilter.Contentname.indexOf('merged_') == -1){
            clickedFilter.parent && (clickedFilter.parent.indexOf('_nested') > 0 || clickedFilter.parent.indexOf('_navigation') > 0)?
            aggregations.push({
                "type":clickedFilter.parent,
                "filter":[],
                "children":[obj]
            }) :
            aggregations.push({
                "type":clickedFilter.parent,
                "filter":[clickedFilter.Contentname]
            })
        }
        else { //if aggregations exist
            let index = -1;
            aggregations.some(function(facet, i) { if (facet.type == clickedFilter.parent) { index = i; return true; } } );
            //if facet present in aggregations
            if(index >= 0){
                //if nested
                if(clickedFilter.parent.indexOf('_nested') > 0 || clickedFilter.parent.indexOf('_navigation') > 0){
                    var childrenArr = aggregations[index].children || [];
                    if (clickedFilter.checked){
                        childrenArr.forEach( function(filter, i) {
                            if (filter.path && filter.path.indexOf(clickedFilter.Contentname) >= 0){
                                childrenArr[i] = {};
                            }
                        })
                        childrenArr.push(obj);
                        aggregations[index].sort && !aggregations[index].filter ? aggregations[index].filter = [] : null;
                    }
                    else {
                        if(aggregations[index].sort && clickedFilter.Contentname == undefined){
                            aggregations[index].sort = clickedFilter.sortMethod;
                        } else if(aggregations[index].children && !aggregations[index].sort && clickedFilter.Contentname == undefined){
                            aggregations[index].sort = clickedFilter.sortMethod;
                        } else{
                            if(clickedFilter.level == 1) {
                                aggregations[index].children = [];
                                childrenArr = [];
                            }
                            else {
                                //remove all parent of unchecked filter
                                var filtersInAggr = childrenArr.filter( function(filter,i){
                                    if ((clickedFilter.Contentname == filter.childName) || (clickedFilter.path && clickedFilter.path.indexOf(filter.childName) >= 0) || (filter.path && filter.path.indexOf(clickedFilter.Contentname) > -1)){
                                        childrenArr[i] = {};
                                    }
                                    return Object.keys(childrenArr[i]).length !== 0
                                })
                                filtersInAggr = filtersInAggr.map(function(f){return f.childName});
                                var currentFilterOrder = component.get("v.currentClickedOrder"); 
                                helper.traverseTheTree(helper, currentFilterOrder.values, clickedFilter, clickedFilter.path, filtersInAggr, childrenArr);
                            }
                        }
                    }
                    if(clickedFilter.Contentname){
                        childrenArr = childrenArr.filter(function(value) { if(Object.keys(value).length !== 0) return value;});
                        aggregations[index].children = childrenArr;
                    }
                }
                else if(clickedFilter.Contentname && clickedFilter.Contentname.indexOf('merged_') > -1){
                    aggregations[index].filter = clickedFilter.checked && (!aggregations[index].filter || !aggregations[index].filter.length) ? [] : aggregations[index].filter;
                    helper.mergeFilterClicked(clickedFilter, aggregations[index].filter, component.get("v.currentClickedOrder").values);
                }
                else if (clickedFilter.Contentname && !aggregations[index].filter){
                    aggregations[index].filter = [clickedFilter.Contentname];
                }
                else {
                    //if filter already in aggregations
                    if(aggregations[index].sort && clickedFilter.Contentname == undefined){
                        aggregations[index].sort = clickedFilter.sortMethod;
                    }
                    else if(aggregations[index].filter && !aggregations[index].sort && clickedFilter.Contentname == undefined){
                        aggregations[index].sort = clickedFilter.sortMethod;
                    }
                    else if ( aggregations[index].filter.indexOf(clickedFilter.Contentname) > -1 ){
                        aggregations[index].filter.splice(aggregations[index].filter.indexOf(clickedFilter.Contentname),1);
                    }
                    else {
                        aggregations[index].filter.push(clickedFilter.Contentname);
                    }
    
                }
    
            }
            else {
                if(clickedFilter.Contentname == undefined){
                    aggregations.push({
                        "type": clickedFilter.parent,
                        "sort": clickedFilter.sortMethod
                    })
                }
                else if(clickedFilter.Contentname.indexOf('merged_') > -1){
                    var filter = [];
                    helper.mergeFilterClicked(clickedFilter, filter, component.get("v.currentClickedOrder").values);
                    aggregations.push({
                        "type":clickedFilter.parent,
                        "filter":filter
                    });
                }else{
                clickedFilter.parent && (clickedFilter.parent.indexOf('_nested') > 0 || clickedFilter.parent.indexOf('_navigation') > 0)?
                aggregations.push({
                    "type":clickedFilter.parent,
                    "filter":[],
                    "children":[obj]
                }) :
                aggregations.push({
                    "type":clickedFilter.parent,
                    "filter":[clickedFilter.Contentname]
                })
            }
            }
        }
        
        //remove empty aggregations
        aggregations = aggregations.filter(function (facet){
            if(!facet.sort) {
                if ((facet.filter && !facet.filter.length) && (!facet.children || facet.children && !facet.children.length)) {
                    return false
                }
            } else {
                if ((facet.filter && !facet.filter.length) && (!facet.children || facet.children && !facet.children.length)) {
                    delete facet.filter || facet.children
                }
            }
            return true
        })
        //radio button created date changes
        aggregations.map(function(item){
            if(item && (item.type === "post_time" || item.type.includes('CreatedDate'))){
                if(item.filter.length > 1) {
                    item.filter.splice(0,1);
                }
            }
            if (item.children && !item.children.length) {
                delete item.children;
                if (!item.filter.length) {
                    delete item.filter
                }
            }
        })
        component.set("v.selectedTypeFilter", JSON.stringify(aggregations));
        var currentFilterOrder = setArray.find(function (f) { if (f.key == clickedFilter.parent) return f; })
        component.set('v.filterOrder', currentFilterOrder.order);
        component.set("v.currentClickedOrder", currentFilterOrder);
        helper.getValue(component, 'filterCheck', 'true', helper);
    },
    traverseTheTree: function(helper, childArray, clickedFilter, path, filtersInAggr, childrenArr){
        for(var i=0; i < childArray.length; i++){
            var filter = childArray[i];
            if (filter.Contentname == path[0]){
                filter.selected = false;
                if (path.length > 1){
                    helper.traverseTheTree(helper, filter.childArray, clickedFilter, path.splice(1, path.length), filtersInAggr, childrenArr);
                }
                //else {
                    filter.childArray.forEach(function(child) {
                        if (clickedFilter.Contentname == child.Contentname) {child.selected == false;}
                        if (clickedFilter.Contentname != child.Contentname && child.selected == true && filtersInAggr.indexOf(child.Contentname) == -1){
                            childrenArr.push({
                                "childName":child.Contentname,
                                "level":child.level.toString(),
                                "path":child.path
                            });
                        }
                    })
                //}
            }
        }
    },    
    mergeFilterClicked: function(clickedFilter, aggrFilter, childArray){
        childArray.some(function (child){
            if(child.Contentname == clickedFilter.Contentname){
                if (child.childArray){
                    child.childArray.forEach(function(f){
                        if (clickedFilter.checked){
    						if(aggrFilter.indexOf(f.Contentname) == -1) {
                                aggrFilter.push(f.Contentname);  
                            }                            
                        }
                        else {
                            if(aggrFilter.indexOf(f.Contentname) > -1) {
                                aggrFilter.splice(aggrFilter.indexOf(f.Contentname), 1);
                            }
                        }
                    })
                }
            }
        })
	},
    asArray: function(component, comp) {
        if (Array.isArray(comp)) return comp;
        else return comp ? [comp] : [];
    },
    pageFunc: function(component, event, helper) {
        var currentPage = parseInt(event.target.id);
        component.set("v.pageNum", "" + currentPage);
        if (component.get("v.customSettingsFilled") && component.get("v.Bearer"))
            helper.getValue(component, 'pageChange', 'true', helper);
    },
    nextPageFunc: function(component, event, helper) {
        var currentPage = parseInt(component.get("v.pageNum")) + 1;
        component.set("v.pageNum", "" + currentPage);
        if (component.get("v.customSettingsFilled") && component.get("v.Bearer"))
            helper.getValue(component, 'pageChange', 'true', helper);
    },
    modalviewFunc: function(component, event, helper) {
        if (document.getElementsByClassName("su__left-sidebar")[0]) {
            document.getElementsByClassName("su__left-sidebar")[0].classList.add("su__fillter-toggle");
            document.getElementsByTagName("body")[0].classList.add("su__overflow-hidden");
            component.set("v.isMobile",true);
        }
    },
    FilterModalviewFunc: function(component, event, helper) {
        if (component.get('v.topFiltersLayoutDiv')) {
            document.getElementsByClassName("su__left-sidebar-layout-2")[0].classList.add("su__fillter-toggle");
            document.getElementsByClassName("su__topFilters-overlay")[0].classList.add("su__viewMore-block");
        } else {
            document.getElementsByClassName("su__left-sidebar-layout-2")[0].classList.remove("su__fillter-toggle");
            document.getElementsByClassName("su__topFilters-overlay")[0].classList.remove("su__viewMore-block");
        }
    },
    dismiss_modalFunc: function(component, event, helper) {
        component.set("v.isMobile",false); 
        if (document.getElementsByClassName("su__left-sidebar")[0]) {
            document.getElementsByClassName("su__left-sidebar")[0].classList.remove("su__fillter-toggle");       
        }
        if (document.getElementsByClassName("su__left-sidebar-layout-2")[0] || document.getElementsByClassName("su__topFilters-overlay")[0]) {
            document.getElementsByClassName("su__left-sidebar-layout-2")[0].classList.remove("su__fillter-toggle");
            document.getElementsByClassName("su__topFilters-overlay")[0].classList.remove("su__viewMore-block");
        }
        document.getElementsByClassName("su__right-sidebar")[0].classList.remove("su__search-tip-toggle");
        document.getElementsByClassName("su__viewMore")[0].classList.remove("su__top-toggle");
        document.getElementsByTagName("body")[0].classList.remove("su__overflow-hidden");
        component.set("v.topFiltersLayoutDiv", false);
        component.set("v.showFilterLargeDiv", false);
    },
    toggleSearchTipsFunc: function(component, event, helper) {
        document.getElementsByClassName("su__right-sidebar")[0].classList.add("su__search-tip-toggle");
        document.getElementsByTagName("body")[0].classList.add("su__overflow-hidden");
        component.set("v.topFiltersLayoutDiv", false);
        component.set("v.showFilterLargeDiv", false);
    },
    runScriptMethodFunc: function (component, event, helper) {
        if(event.target.classList){
            if(event.target.classList[0] === 'su-recommend-title'){
            return;
               }   
            }
        if(helper.getURLParameter('searchString') != "" || helper.getURLParameter('exactPhrase') != ""){
            var target;
            if (event.target.closest('a') || event.target.closest('span')){
                target = event.target.closest('a') ||  event.target.closest('span');
                var data_Id = target.getAttribute("data-id") || "";
                var data_type = target.getAttribute("data-type") || "";
                var data_index = target.getAttribute("data-index") || "";
                var data_rank = target.getAttribute("data-rank") || "";
                var data_url = target.getAttribute("data-url") || "";
                var data_sub = target.getAttribute("data-sub") || "";
                var data_autotuned = target.getAttribute("data-autotuned") || false;
                var data_trackAnalytics = target.getAttribute("data-trackAnalytics") || [];
                if (data_rank != '') {
                    data_rank = (+data_rank) + 1;
                }
                var childCmp = component.find("SuAnalytics");
                // var auramethodResult = childCmp.analytics("search", { "searchString": component.get("v.searchString"),"conversion": [{
                //     rank: data_rank,
                //     url: data_url,
                //     subject: data_sub,
                //     es_id:data_index +"/"+ data_type + "/" + encodeURIComponent(data_Id)
                // }]});
                var auramethodResult;
                if (target.getAttribute("data-auto") && target.getAttribute("data-auto") == "true") {
                    // auramethodResult = childCmp.analytics("search", { "searchString": component.get("v.searchString"),"conversion": [{
                    //     rank: data_rank,
                    //     url: data_url,
                    //     subject: data_sub,
                    //     es_id:data_index +"/"+ data_type + "/" + encodeURIComponent(data_Id)
                    // }]});
                } else {
                    if(data_Id != "" && data_sub != ""){
                    auramethodResult = childCmp.analytics("conversion", { "searchString": component.get("v.searchString"),
                        pageSize: component.get("v.pageSize"),
                        page_no: component.get("v.pageNum"),
                        rank: data_rank,
                        convUrl: data_url,
                        convSub: data_sub.substring(0, 300),
                        id: data_Id,
                        index: data_index,
                        type: data_type,
                        autoTuned: data_autotuned ? data_autotuned : false,
                        sc_analytics_fields: data_trackAnalytics 

                    });
                 }
                }
            }
        }
    },
    searchResultFunc: function(component, event, helper) {
        var params = event.getParam('arguments');
        var result;
        if (params && params !== undefined) {
            result = params.data;
        } else {
            result = component.get("v.advanceFilterData");
        }
        var totalResult = String(params.pageResult);
        if (result !== undefined && result !== null) {
            var finalJson = '[';
            var totalAggr = '';
            for (var i = 0; i < result.length; i++) {
                if (result[i].valueFilter !== '' && result[i].valueFilter !== undefined && result[i].valueFilter !== 'undefined') {
                    totalAggr += '{"type":"' + result[i].sourceType + '","filter":["' + result[i].valueFilter + '"]},';
                }
            }
            totalAggr = totalAggr.slice(0, totalAggr.length - 1);
            finalJson = finalJson + totalAggr + ']';
            if (finalJson != '') {
                component.set('v.selectedTypeFilter', finalJson);
            }
            if (totalResult !== undefined && totalResult !== '' && totalResult !== 'undefined') {
                component.set('v.pageSize', totalResult);
            }
        }
        if (component.get("v.customSettingsFilled") && component.get("v.Bearer"))
            helper.getValue(component, 'test', 'true', helper);
    },
    setNames: function(component, result, setArray) {
        var mapSource = {};
        let minSummaryLength = component.get("v.searchSummaryLength");
        for (var i = 0; i < result.result.hits.length; i++) {
            result.result.hits[i].highlight.SummaryLength = result.result.hits[i].highlight.SummaryToDisplay.join('#');
            result.result.hits[i].highlight.ShortSummary = result.result.hits[i].highlight.SummaryToDisplay.join('#').substring(0, minSummaryLength).split('#');
            result.result.hits[i].highlight.SummaryDisplay = result.result.hits[i].highlight.SummaryToDisplay.join('#').split("#");
            result.result.hits[i].objDisplayName = mapSource[result.result.hits[i].objName];
        }
        for (var i = 0; i < result.result.hits.length; i++) {
            if (result.result.hits[i].metadata) {
                for (var j = 0; j < result.result.hits[i].metadata.length; j++) {
                    for (var k in result.result.hits[i].metadata[j]) {
                        if (result.result.hits[i].metadata[j][k] == "Tag") {
                            result.result.hits[i].metadata[j].valueString = "";
                            result.result.hits[i].metadata[j].valueString = result.result.hits[i].metadata[j]["value"].join(", ").substring(0, 200);
                        }
                    }
                }
            }
        }
    },
    knowledgeGraph: function(component, response) {
        var flag = false;
        try {
            if (response.metaGraph && Object.keys(response.metaGraph).length > 0) {
                flag = true;
            }
            component.set("v.metaStatus", flag);
            if (flag) {
                var meta = {};
                meta.metaFields = [];
                meta.metaFields = response.metaGraph.metaFields;
                for (var i = 0; i < meta.metaFields.length; i++) {
                    for (var k in meta.metaFields[i]) {
                        if (k == "value") {
                            meta.metaFields[i][k] = meta.metaFields[i][k] ? meta.metaFields[i][k].toString().substring(0, 200) : '';
                        }
                    }
                }
                meta.metaTitle = response.metaGraph.title ? response.metaGraph.title.toString().substring(0, 200) : '';
                meta.metaImg = response.metaGraph.img;
                meta.metaDescription = response.metaGraph.description ? response.metaGraph.description.toString().substring(0, 250) : '';
                meta.metaLink = response.metaGraph.link;
                meta.metaSubtitle = response.metaGraph.subtitle ? response.metaGraph.subtitle.toString().substring(0, 200) : '';
                component.set("v.meta_data", meta);
            }
        } catch (exception) {
            console.log(exception);
        }
        try {
            flag = false;
            if (response.relatedTiles && response.relatedTiles.length > 0) {
                flag = true;
            }
            component.set("v.relatedTilesStatus", flag);
            component.set("v.relatedTiles", response.relatedTiles);
        } catch (exception) {
            console.log(exception);
        }
    },
    featureSnippet: function(component, response) {
        component.set("v.featureSnippet", response.featuredSnippetResult);
    },
    similarSearchSuggestion: function(component, response) {
        try {
            component.set("v.similarSearchSuggestions", response.similarSearches ? response.similarSearches : null);
        } catch (exception) {
            console.log(exception);
        }
    },
    getValue: function(component, searchType, runLoader, helper) {
        if(helper.getURLParameter('bookmark')) {
            searchType = helper.getURLParameter('bookmark') ? helper.getURLParameter('bookmark') : searchType;
        }
        if(!component.get("v.refresh") || (component.get("v.refresh") && !component.get("v.setFlag"))){
            var actionBach = window;
            var c = JSON.parse(localStorage.getItem('theme' + component.get("v.uid")));
            document.body.style.position = 'relative';
            document.body.style['overflow-y'] = 'unset';

            if (searchType == 'search') {
                component.set("v.pageNum", "1");
                if (component.find('mySelect')) {
                    var sortByValue = component.find('mySelect').get('v.value');
                    component.set("v.sortByCheck", helper.getURLParameter('sortBy') != "" ? helper.getURLParameter('sortBy') : "_score");
                }
                else {
                    sortByValue = helper.getURLParameter('sortBy') != "" ? helper.getURLParameter('sortBy') : "_score";
                  
                     component.set("v.sortByCheck", sortByValue);

                     //    component.set("v.sortByCheck", helper.getURLParameter('sortBy') != "" ? helper.getURLParameter('sortBy') : "");
                }
                component.set("v.pageSize", helper.getURLParameter('resultsPerPage') != "" ? helper.getURLParameter('resultsPerPage') : component.get("v.defaultPageSize"));
                if (!component.get("v.setFlag") || component.get("v.setFlag") && !c) {
                    if(!component.get("v.resetFilters")) {
                        component.set("v.selectedTypeFilter", helper.getURLParameter('selectedType') != "" ? helper.getURLParameter('selectedType') : "");
                    }
                }
                var previousDymString = helper.getURLParameter('dym') ? helper.getURLParameter('dym') : "undefined" ;
            }
            if (searchType == 'bookmark') {
                component.set("v.pageNum", helper.getURLParameter('pageNum') != "" ? helper.getURLParameter('pageNum') : "1");
                if (component.find('mySelect')) {
                    var sortByValue = component.find('mySelect').get('v.value');
                    component.set("v.sortByCheck", helper.getURLParameter('sortBy') != "" ? helper.getURLParameter('sortBy') : sortByValue);
                }
                component.set("v.pageSize", helper.getURLParameter('resultsPerPage') != "" ? helper.getURLParameter('resultsPerPage') : component.get("v.defaultPageSize"));
                if (!component.get("v.setFlag") || component.get("v.setFlag") && !c) {
                    component.set("v.selectedTypeFilter", helper.getURLParameter('selectedType') != "" ? helper.getURLParameter('selectedType') : "");
                }
                var previousDymString = helper.getURLParameter('dym') ? helper.getURLParameter('dym') : "undefined" ;
            }

            if (searchType != 'clearFilter' && searchType != 'advanceFilterCheck') {
              if(!component.get("v.refresh"))
                component.set("v.pageNum", helper.getURLParameter('pageNum') != "" ? helper.getURLParameter('pageNum') : "1");
                component.set("v.pageSizeAdvFiltr", helper.getURLParameter('pageSizeAdv') != "" ? helper.getURLParameter('pageSizeAdv') : "10");
                component.set("v.exactPhrase", helper.getURLParameter('exactPhrase') != "" ? helper.getURLParameter('exactPhrase') : "");
                component.set("v.withOneOrMore", helper.getURLParameter('withOneOrMore') != "" ? helper.getURLParameter('withOneOrMore') : "");
                component.set("v.withoutTheWords", helper.getURLParameter('withoutTheWords') != "" ? helper.getURLParameter('withoutTheWords') : "");
                if (component.get("v.exactPhrase") != "" || component.get("v.withOneOrMore") != "" || component.get("v.withoutTheWords") != "") {
                    component.set("v.advanceSearchEnabled", true);
                }
            }
            
            component.set('v.refresh', true);
            if (component.get("v.setFlag")) {
                if (c) {
                    if (c.activeTabIndex != 'all' && c.activeTabIndex != undefined) {
                        component.set("v.active", c.defaultTab.indexOf('merged_') > -1 ? c.defaultTab : c.activeTabIndex);
                        component.set("v.activeTabType",c.activeTabType);
                        component.set("v.defaultTab", c.defaultTab.indexOf('merged_') > -1 ? c.defaultTab : c.activeTabIndex);
                        component.set("v.activeMergedChild", c.defaultTab.indexOf('merged_') > -1 ? c.activeMergedChild : '');
                        var selectedFacet = (helper.getURLParameter('selectedType') != ""  ? helper.getURLParameter('selectedType') : "");
                        var facetData = [{
                            "type": c.activeTabType,
                            "filter": c.activeTabIndex.indexOf('merged_') > -1 ? [...c.activeTabValue] : [c.activeTabIndex]
                        }]
                        var filterValue = JSON.stringify(facetData);
                        if(selectedFacet != '' && JSON.parse(selectedFacet)[0].type != "_index"){
                            var selectedParams = JSON.parse(selectedFacet).concat(JSON.parse(filterValue));
                        }
                        else{
                            var selectedParams = (JSON.parse(filterValue || selectedFacet));
                        }
                        component.set("v.selectedTypeFilter", JSON.stringify(selectedParams));
                    }
                    else{
                        var selectedFacet = (helper.getURLParameter('selectedType') != "" ? helper.getURLParameter('selectedType') : "");
                        component.set("v.selectedTypeFilter", selectedFacet);
                    }
                }
                else {
                    var selectedFacet = (helper.getURLParameter('selectedType') != "" ? helper.getURLParameter('selectedType') : "");
                    component.set("v.selectedTypeFilter", selectedFacet);
                }
            }
            
            var bodyCom = component.find('dvSpinner3');
            var analyticsCmp = component.find("SuAnalytics");
            var sid = analyticsCmp.analytics('_gz_taid', '');
            var cookie = analyticsCmp.analytics('_gz_sid', '');
            $A.util.removeClass(bodyCom, 'su_disSpiner');
            var startTime = new Date();
            if (runLoader == 'true') {
                if(!component.get("v.filterSortingLoading")) {
                    component.set("v.loadingResult", 0);
                }
            }
            var indexEnabled = component.get("v.contentSourceTab");
            var filterOrderPriority = component.get('v.filterOrder');
            var previousResultAggregation = component.get('v.originalAggregationsData');
            var searchText = '';
            var originalQuery = '';
            searchText = helper.getURLParameter('searchString');
            originalQuery = searchText.trim();
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
            component.set("v.searchString", searchText);
            if (searchText != '') {
                searchText = searchText.trim();
            }
            var filterData = component.get("v.selectedTypeFilter");
            var arr = [];
            var filterSelect = {
                "Contentname": filterData && JSON.parse(filterData).length != 0 && JSON.parse(filterData)[0].filter ? JSON.parse(filterData)[0].filter[0] : null,
                "checked": true
            }
            if(filterData.length != 0 && filterSelect.Contentname && filterSelect.Contentname.indexOf("merged_") > -1){
                helper.mergeFilterClicked(filterSelect, arr, component.get("v.aggregationsData")[0].values);
                var data = JSON.parse(filterData);
                data[0].filter = arr;
                filterData = JSON.stringify(data);
            }
            if(filterData) {
                component.set("v.selectedTypeFilter", filterData);
            } 
            var pageNum = component.get("v.pageNum");
            var currentPageNumber = Number(pageNum);
            var pageSize = component.get("v.pageSize");

            var currentClickedOrder = component.get("v.currentClickedOrder");

            var tempClientFilters = JSON.parse(JSON.stringify(previousResultAggregation));

            component.set('v.bookmark_list', false);
            component.set('v.viewSavePopup', false);
            component.set('v.viewConfirmPopup', false);

            if(filterData && JSON.parse(filterData) && JSON.parse(filterData).length){
                component.set("v.multiVersion", false)
            } else {
                component.set("v.multiVersion", true)
            }
            let isSmartFacets = component.get("v.isSmartFacets");
            let smartAggLength = component.get("v.smartAggregations")
           
            let filterSmart = filterData.length == 0 ? filterData : JSON.parse(filterData);
            if(localStorage.getItem("AutoLearning") == null || localStorage.getItem("AutoLearning") == undefined){
              localStorage.setItem("AutoLearning", true);  
            }
            let localSmart = localStorage.getItem("AutoLearning") === 'false' ? false : true;
            component.set("v.isAutoLearning", localSmart);
            var sendSmartFacets = (analyticsCmp.analytics('smartFacets', '') == "" ||  analyticsCmp.analytics('smartFacets', '') == "true") && filterSmart.length == 0 && localSmart && isSmartFacets;
            component.set("v.isSmartFacets", sendSmartFacets);
            
            
            let smartApplyChanges = component.get("v.isSmartHidden");
            if(smartApplyChanges){
              sendSmartFacets = smartApplyChanges
              component.set("v.isSmartFacets", smartApplyChanges); 
            }
           // let smartFacetBanner = JSON.parse(helper.getURLParameter('smartFacets') || component.get("v.isSmartFacets"));
           // sendSmartFacets = smartFacetBanner;
            
            var setArray = [];
            var data = JSON.stringify({
                "searchString": searchText,
                "from": ((pageNum - 1) * pageSize),
                "pageNum": parseInt(pageNum),
                "pageNo": parseInt(pageNum),
                "sortby": component.get("v.sortByCheck"),
                "orderBy": "desc",
                "resultsPerPage": parseInt(pageSize),
                "exactPhrase": component.get("v.exactPhrase"),
                "withOneOrMore": component.get("v.withOneOrMore"),
                "withoutTheWords": component.get("v.withoutTheWords"),
                "aggregations": filterData ? JSON.parse(filterData): [],
                "referrer": document.referrer,
                "recommendResult": "",
                "indexEnabled": indexEnabled,
                "sid": sid + '$Enter$',
                "cookie": cookie,
                "uid": component.get("v.uid"),
                "language":localStorage.getItem('language') || 'en',
                "versionResults": component.get("v.multiVersion"),
                "smartFacets": component.get("v.isSmartFacets")
            });

            let query = JSON.parse(data);
            query.pageSizeAdv = component.get("v.pageSizeAdvFiltr");
            component.set("v.query", query);

            var xmlHttp = new XMLHttpRequest();
            var url = component.get("v.endPoint") + "/search/SUSearchResults";
            xmlHttp.withCredentials = true;
            xmlHttp.open("POST", url, true);
            xmlHttp.setRequestHeader("Accept", "application/json");
            xmlHttp.setRequestHeader('Authorization', 'bearer ' + component.get('v.Bearer'));
            xmlHttp.setRequestHeader('Content-Type', 'application/json');

            xmlHttp.send(data);
            xmlHttp.onreadystatechange = function() {
                if (xmlHttp.readyState === 4) {
                    if (xmlHttp.status === 200) {
                        var actionBachHref = actionBach.document.URL;
                       var result = JSON.parse(xmlHttp.response);
                        if (result.statusCode != 402) {
                            var total = result.result.total;
                            if (result.statusCode == 200 || result.statusCode == 400) {
                                component.set("v.resetFilters", false);
                                if(result.searchClientSettings.languageManager == 1) {
                                    component.set("v.showLanguageDropdown", true);
                                } else {
                                    component.set("v.showLanguageDropdown", false);
                                }
                                if(result.searchClientSettings.ViewedResults == 1) {
                                    component.set("v.showViewedResults", true);
                                } else {
                                    component.set("v.showViewedResults", false);
                                }
                                if(result.searchClientSettings && result.searchClientSettings.userFeedbackEnabled && result.searchClientSettings.userFeedbackEnabled.conversionExp == true) {
                                    helper.getSearchExp(component, event);
                                    component.set("v.searchPageFeedback", true);
                                } else {
                                    component.set("v.searchPageFeedback", false);
                                }
                                if(result.searchClientSettings && result.searchClientSettings.userFeedbackEnabled && result.searchClientSettings.userFeedbackEnabled.searchExp == true) {
                                    helper.getSearchExp(component, event);
                                    component.set("v.searchFeedback", true);
                                } else {
                                    component.set("v.searchFeedback", false);
                                }
                                result.searchClientSettings.preview ? component.set("v.preview", true):component.set("v.preview", false)
                                result.searchClientSettings.hideAllContentSources ? component.set("v.allContentHideFacets", true):component.set("v.allContentHideFacets", false)
                                result.searchClientSettings.contentTag ? component.set("v.contentTag", true):component.set("v.contentTag", false)
                                result.searchClientSettings.showMore ? component.set("v.showSummary", true):component.set("v.showSummary", false)
                                result.searchClientSettings.smartFacets ? component.set("v.isSmartFacetsAdmin", true):component.set("v.isSmartFacetsAdmin", false)
                                result.searchClientSettings.hiddenFacet && result.searchClientSettings.hiddenFacet.length ? component.set("v.hideFacetAdmin", true) : component.set("v.hideFacetAdmin", false)
                                component.set("v.totalResults", total);
                                var endTime = new Date();
                                var Seconds_from_T1_to_T2 = (endTime.getTime() - startTime.getTime()) / 1000;
                                var seconds_Between_Dates = Math.abs(Seconds_from_T1_to_T2);
                                var aggrData = result.aggregationsArray
                                var testing = result.aggregationsArray.forEach(function (child) {
                                    var myTest = child.values.map(function (ele) {
                                        ele.ContentnameFrontend = helper.htmlDecode(ele.Contentname)
                                    })
                                })
                                var smartAggregations = result.smartAggregations;
                                component.set("v.smartAggregations", smartAggregations);
                                setArray = aggrData;
                                component.set("v.searchSummaryLength",result.searchClientSettings.minSummaryLength);
                                var suggestData = '';
                                component.set("v.suggestData", "");
                                if(result.merged_facets && result.merged_facets.length) {
                                    component.set("v.mergedArray", JSON.parse(result.merged_facets) || '[]');
                                }
                                if (component.get("v.mergedArray")) {
                                    Array.from(component.get("v.mergedArray")).forEach(function (o) {
                                        helper.mergeFilters(component, o, setArray, helper);
                                    });
                                }
                                var c = JSON.parse(localStorage.getItem('theme' + component.get("v.uid")));
                                if (c) {
                                    if (c["hiddenFacets"]) {
                                        setArray.forEach(function(child) {
                                            if (c.hiddenFacets.includes(child.label)) {
                                                child.hide = true;
                                                child.hideEye = true;
                                            } else {
                                                child.hide = false;
                                                child.hideEye = false;
                                            }
                                        })
                                    } else {
                                        setArray.forEach(function(child) {
                                            child.hide = false;
                                            child.hideEye = false;
                                        })
                                    }
                                    if (c.hideTitle == true) {
                                        component.get("v.hiddenKeys").push("Title");
                                    }
                                    if (c.hideSummary == true) {
                                        component.get("v.hiddenKeys").push("Summary");
                                    }
                                    if (c.hideMetadata == true) {
                                        component.get("v.hiddenKeys").push("Metadata");
                                    }
                                    if (c.hideUrl == true) {
                                        component.get("v.hiddenKeys").push("Url");
                                    }
                                    if (c.hideIcon == true) {
                                        component.get("v.hiddenKeys").push("Icon");
                                    }
                                    if (c.hideTag == true) {
                                        component.get("v.hiddenKeys").push("Tag");
                                    }
                                }
                                JSON.parse(filterData || '[]').some(function (f){
                                    if(f.type == '_index' && f.filter){
                                        component.set('v.active' , f.filter[0]);
                                    } else if(f.type == '_type' && aggrData[0].key !== '_index' && f.filter) {
                                        component.set('v.active' , f.filter[0]);
                                    }
                                });
                                if(component.get('v.hideFacetAdmin') == true && component.get('v.active') == 'all' && setArray){
                                    setArray.forEach((item) =>{
                                        if(result.searchClientSettings.hiddenFacet){
                                            item.hideFacetAdmin = result.searchClientSettings.hiddenFacet.indexOf(item.key) >= 0;
                                        }
                                    })
                                    component.set('v.aggregationsData', setArray );
                                }
                                if (setArray && setArray.length) {
                                    let arrayToCheck = setArray.filter((item, index) => index > 0 && item.values.length != 0);
                                    
                                    if(arrayToCheck.length == 0) {
                                        component.set("v.novaluesForResult", true);
                                    } else {
                                        component.set("v.novaluesForResult", false);
                                    }
                                }
                                Promise.all([helper.setNames(component, result, setArray),
                                    helper.setResults(component, result), 
                                    helper.setFilters(component, setArray), 
                                    helper.setPagination(component, helper, currentPageNumber, pageSize, pageNum),
                                    helper.setStickyFacets(component,helper, setArray)]
                                ).then(function(values) {
                                    if(!component.get("v.filterSortingLoading")) {
                                        component.set("v.loadingResult", 1);
                                    }
                                    component.set("v.filterSortingLoading", false);
                                });
                                
                                //knowledgeGraph
                                helper.knowledgeGraph(component, result);
                                component.set("v.knowledgeGraphResponseRecorded", false);
                                //featureSnippet
                                if (result.featuredSnippetResult) {
                                    helper.featureSnippet(component, result);
                                } else {
                                    component.set("v.featureSnippet", undefined);
                                }
                                component.set("v.featuredResponseRecorded", false);
                                helper.similarSearchSuggestion(component, result);
                                if(result.searchClientSettings.advertisements){
                                    helper.getAdv(component, event);
                                }
                                result.searchClientSettings.recommendations ? component.set("v.getRecommendations", true):component.set("v.getRecommendations", false)
                                var searchResult = result.result.searchQuery;
                                if (result.suggest.simple_phrase.length > 0) {
                                    if (result.suggest.simple_phrase[0].options && result.suggest.simple_phrase[0].options.length > 0) {
                                        suggestData = result.suggest.simple_phrase[0].options[0].text;
                                        component.set("v.suggestData", suggestData);
                                    }
                                }
                                if (document.referrer != actionBachHref) {

                                    component.set("v.totalResults", total);

                                    var emptyArr = [];
                                    var isFreshSearch = false;
                                    if (searchType == "search" || searchType == "bookmark") {
                                        isFreshSearch = true;
                                        if(component.get("v.resetType")){
                                            isFreshSearch = false;
                                            component.set("v.resetType", false);
                                        }
                                    }
                                    var filterAggregations = component.get("v.selectedTypeFilter") ? JSON.parse(component.get("v.selectedTypeFilter")) : component.get("v.selectedTypeFilter");
                                    if(filterAggregations.length) {
                                        var filterAggregations = filterAggregations.filter(function(filter, index) {
                                            if(filter.filter) {
                                                return filterAggregations[index];
                                            } else {
                                                return false;
                                            }
                                        })
                                    }
                                    if(!component.get("v.filterSortingLoading")) {
                                        var auramethodResult = analyticsCmp.analytics('search', { searchString: originalQuery ? originalQuery : component.get("v.exactPhrase") ? component.get("v.exactPhrase") : '', "result_count": component.get("v.totalResults"), page_no: component.get("v.pageNum"), "platformId": component.get("v.uid"), "filter": filterAggregations, "isFreshSearch" : isFreshSearch,
                                            "exactPhrase": component.get("v.exactPhrase"),
                                            "withOneOrMore": component.get("v.withOneOrMore"),
                                            "withoutTheWords": component.get("v.withoutTheWords"),
                                            "dym":previousDymString,
                                            "responseTime": seconds_Between_Dates
                                        });
                                    }

                                }
                                aggrData.filter(function(o) {
                                    if (o.key.indexOf('_nested') > -1 || o.key.indexOf('_navigation') > -1) {
                                        o.values.forEach(function(l) {
                                            if (l.childArray && l.childArray.length) {
                                                let parent = [];
                                                parent.push(l.Contentname);
                                                helper.addPathName(component, parent, l.childArray, helper);
                                            }
                                        });
                                    }

                                });
                            
                                component.set('v.bookmarkSearches', JSON.parse(localStorage.getItem('bookmark_searches_' + component.get("v.uid")) || "[]"));
                                var c = JSON.parse(localStorage.getItem('theme' + component.get("v.uid")));
                                if (c) {
                                    component.set("v.toggleDisplayKeys[0].hideEye", c.hideTitle);
                                    component.set("v.toggleDisplayKeys[1].hideEye", c.hideSummary);
                                    component.set("v.toggleDisplayKeys[3].hideEye", c.hideMetadata);
                                    component.set("v.toggleDisplayKeys[2].hideEye", c.hideUrl);
                                    component.set("v.toggleDisplayKeys[4].hideEye", c.hideIcon);
                                    component.set("v.toggleDisplayKeys[5].hideEye", c.hideTag);

                                if(component.get('v.emptyResponseAggregations')){
                                    if (c["hiddenFacets"]) {
                                        component.get('v.emptyResponseAggregations').forEach(function(child) {
                                            if (c.hiddenFacets.includes(child.label)) {
                                                child.hide = true;
                                                child.hideEye = true;
                                            } else {
                                                child.hide = false;
                                                child.hideEye = false;
                                            }
                                        })
                                    } else {
                                        component.get('v.emptyResponseAggregations').forEach(function(child) {
                                            child.hide = false;
                                            child.hideEye = false;
                                        })
                                    }
                                }

                                }
                            
                            	if(component.get("v.isSmartFacets")){
                                    if(smartAggregations){
                                        smartAggregations.length && smartAggregations.forEach(function (outer){
                                          aggrData.forEach(function (inner){
                                              if (inner.key == outer.key) {
                                                  inner.hide = false;
                                              }
                                          });
                                    });
                                    component.set("v.aggregationsData", aggrData);
                                    }
                            	}
                                if(component.get('v.aggregationsData')[0].key == '' && component.get('v.selectedTypeFilter') !== ''){ 
                  		let hiddenCsTab = JSON.parse(component.get('v.selectedTypeFilter'));
                                    if(hiddenCsTab && hiddenCsTab[0] && hiddenCsTab[0].type === "_index"){
                                        hiddenCsTab.splice(0,1);
                                    }         
                                    filterData  = JSON.parse(filterData);
                                    if(filterData && filterData[0] && filterData[0].type === "_index"){
                                        filterData.splice(0,1);
                                    }
                                    filterData  = JSON.stringify(filterData);
                                    component.set('v.selectedTypeFilter',JSON.stringify(hiddenCsTab));
                                    window.location.hash = encodeURIComponent("searchString=" + encodeURIComponent(component.get("v.searchString")) + "&pageNum=1&sortBy=" + component.get("v.sortByCheck") + "&orderBy=desc&resultsPerPage=" + component.get("v.pageSize") + "&pageSizeAdv=" + component.get("v.pageSizeAdvFiltr") + "&exactPhrase=" + encodeURIComponent(component.get("v.exactPhrase")) + "&withOneOrMore=" + encodeURIComponent(component.get("v.withOneOrMore")) + "&withoutTheWords=" + encodeURIComponent(component.get("v.withoutTheWords")) + "&selectedType=" + encodeURIComponent(JSON.stringify(component.get('v.selectedTypeFilter'))));
             					   }
                            
                                if (JSON.parse(component.get("v.selectedTypeFilter") || "[]").length || component.get("v.exactPhrase") != "" || component.get("v.withOneOrMore") != "" || component.get("v.withoutTheWords") != "") {

                                    if(component.get("v.selectedTypeFilter") == "" || component.get("v.exactPhrase") != "" || component.get("v.withOneOrMore") != "" || component.get("v.withoutTheWords") != "") {
                                        component.set('v.showClearFiltersButton', true);
                                    } else {
                                        for (let i = 0; i < JSON.parse(component.get("v.selectedTypeFilter")).length; i++) {
                                            if(JSON.parse(component.get("v.selectedTypeFilter"))[i].filter || JSON.parse(component.get("v.selectedTypeFilter"))[i].children || component.get("v.exactPhrase") != "" || component.get("v.withOneOrMore") != "" || component.get("v.withoutTheWords") != "") {
                                                component.set('v.showClearFiltersButton', true);
                                            } else {
                                                component.set('v.showClearFiltersButton', false);
                                            }
                                        }
                                    }
                                } else {

                                    component.set('v.showClearFiltersButton', false);
                                }
                                if (c) {
                                    component.set("v.hideTitle", c.hideTitle);
                                    component.set("v.hideSummary", c.hideSummary);
                                    component.set("v.hideMetadata", c.hideMetadata);
                                    component.set("v.hideUrl", c.hideUrl);
                                    component.set("v.hideIcon", c.hideIcon);
                                    component.set("v.hideTag", c.hideTag);
                                    if (c.activeTabIndex) {
                                        component.set("v.activeTabIndex", c.activeTabIndex);
                                    }
                                    if (c.activeTabOrder) {
                                        component.set("v.activeTabOrder", c.activeTabOrder);
                                    }
                                    if (c.accessKeyValue) {
                                        component.set("v.accessKeyValue", c.accessKeyValue);
                                    }
                                } else {
                                    if(!component.get("v.setFlag")) {
                                        component.set("v.values", []);

                                        if(component.get('v.emptyResponseAggregations')){
                                            component.get('v.emptyResponseAggregations').forEach(function(child) {
                                                child.hide = false;
                                                child.hideEye = false;
                                            })


                                            component.get('v.emptyResponseAggregations').forEach(function(item) {
                                                if(item.values.length) {
                                                    let obj = { label: item.label, hideEye: item.hideEye, count: item.values.length };
                                                    let arr = component.get("v.values");
                                                    arr.push(obj);
                                                    component.set("v.values", arr);
                                                }
                                            })
                                        }
                                    }
                                }
                                component.set("v.totalResults", total);

                                if (c && c.facetsOrder.length) {
                                    var xyz = component.get("v.aggregationsData");
                                    xyz.forEach(function(d) {
                                        (c.facetsOrder).forEach(function(o) {
                                            if (d.label == o.value.label) {
                                                d.index = o.indexVal;
                                            }

                                        })
                                    })

                                    xyz.sort(function (a, b) {
                                        //if(a.index == b.index) return 0;
                                        if (a.index == undefined) return 1;
                                        if (b.index == undefined) return -1;

                                        if (a.index < b.index)
                                            return -1;
                                        if (a.index > b.index)
                                            return 1;
                                        return 0;
                                    });

                                    component.set("v.aggregationsData", xyz);
                                    component.set("v.applyChanges", false);
                                }
                                
                                 if(component.get("v.isSmartFacets")){
                                    let isSmartSelected = component.get("v.smartAggregations");
                                    if(isSmartSelected){
                                        var alreadySelected =  aggrData.filter(function(element) {(
                                        element.values.length && element.values.some(function(subElement) {return subElement.selected}))});
                                      
                                        var smartSelected = [];
                                        alreadySelected && alreadySelected.length && alreadySelected.forEach(function(item) {
                                          var s_type = item.key
                                          var s_Contentname = item.values.filter(function(sel) {return sel.selected}).map(function(obj) {return obj.Contentname});
                                          smartSelected.push({
                                            'type': s_type,
                                            'filter': [...new Set(s_Contentname)]
                                          });
                                        });
                                        component.set("v.selectedTypeFilter", JSON.stringify(smartSelected)) 
                                        filterData = JSON.stringify(smartSelected);
                                     	let newQuery = JSON.parse(data);
                                     	newQuery["aggregations"] = smartSelected;
                                     	component.set('v.query', newQuery);
                                        component.set('v.showClearFiltersButton', true);
                                 	}
                                }

                                component.set("v.originalAggregationsData", setArray);

                                component.set("v.resultImgUrl", result.icon);

                                component.set("v.searchResultTime", seconds_Between_Dates);

                                if (total == 0) {
                                    if (document.referrer != actionBachHref) {
                                        var emptyArr = [];
                                    }
                                    component.set("v.totalResults", total);
                                    var noResultMsg = component.get("v.noSearchResultFoundMsg");
                                    if (noResultMsg !== undefined) {
                                        component.set("v.errorMessage", noResultMsg);
                                    } else {
                                        component.set("v.errorMessage", "Sorry, no results found.");
                                    }

                                    if (JSON.parse(component.get("v.selectedTypeFilter") || "[]").length || component.get("v.exactPhrase") != "" || component.get("v.withOneOrMore") != "" || component.get("v.withoutTheWords") != "") {

                                        if(component.get("v.selectedTypeFilter") == "" || component.get("v.exactPhrase") != "" || component.get("v.withOneOrMore") != "" || component.get("v.withoutTheWords") != "") {
                                            component.set('v.showClearFiltersButton', true);
                                        } else {
                                            for (let i = 0; i < JSON.parse(component.get("v.selectedTypeFilter")).length; i++) {
                                                if(JSON.parse(component.get("v.selectedTypeFilter"))[i].filter || JSON.parse(component.get("v.selectedTypeFilter"))[i].children || component.get("v.exactPhrase") != "" || component.get("v.withOneOrMore") != "" || component.get("v.withoutTheWords") != "") {
                                                    component.set('v.showClearFiltersButton', true);
                                                } else {
                                                    component.set('v.showClearFiltersButton', false);
                                                }
                                            }
                                        }

                                    } else {

                                        component.set('v.showClearFiltersButton', false);
                                    }
                                }

                                window.location.hash = encodeURIComponent("searchString=" + encodeURIComponent(searchText) + "&pageNum=" + pageNum + "&sortBy=" + component.get("v.sortByCheck") + "&orderBy=desc&resultsPerPage=" + pageSize + "&pageSizeAdv=" + component.get("v.pageSizeAdvFiltr") + "&exactPhrase=" + encodeURIComponent(component.get("v.exactPhrase")) + "&withOneOrMore=" + encodeURIComponent(component.get("v.withOneOrMore")) + "&withoutTheWords=" + encodeURIComponent(component.get("v.withoutTheWords")) + "&selectedType=" + encodeURIComponent(filterData)+"&smartFacets="+encodeURIComponent(component.get("v.isSmartFacets")));
                                if (component.find('dvSpinner3')) {
                                    $A.util.addClass(component.find('dvSpinner3'), 'su_disSpiner');
                                }

                                if(!component.get("v.filterSortingLoading")) {
                                    component.set("v.loadingResult", 1);
                                }
                                component.set("v.filterSortingLoading", false);
                                // var aggregationsData = component.get("v.aggregationsData");
                                // if(aggregationsData) {
                                //     for (var i = 0; i < aggregationsData.length; i++) {
                                //         if(aggregationsData[i].key != "post_time") {
                                //             aggregationsData[i].descending = true;
                                //         }
                                //     }
                                // }
                                // component.set("v.aggregationsData", aggregationsData);
                            }
                            // if(result.statusCode == 400) {
                            //     component.set("v.setFlag", false);
                            //     var noResultMsg = component.get("v.noSearchResultFoundMsg");
                            //     if (noResultMsg !== undefined) {
                            //         component.set("v.errorMessage", noResultMsg);
                            //     } else {
                            //         component.set("v.errorMessage", "Sorry, no results found.");
                            //     }
                            //      component.set("v.loadingResult", 1);
                            // }
                        } else {
                            if (result.statusCode == 402) {
                                window.location.hash = encodeURIComponent("searchString=" + encodeURIComponent(searchText) + "&pageNum=" + pageNum + "&sortBy=" + component.get("v.sortByCheck") + "&orderBy=desc&resultsPerPage=" + pageSize + "&pageSizeAdv=" + component.get("v.pageSizeAdvFiltr") + "&exactPhrase=" + encodeURIComponent(component.get("v.exactPhrase")) + "&withOneOrMore=" + encodeURIComponent(component.get("v.withOneOrMore")) + "&withoutTheWords=" + encodeURIComponent(component.get("v.withoutTheWords")) + "&selectedType=" + encodeURIComponent(filterData) + "&flag=1");
                                location.reload();
                            }
                        }
                    }
                }
            }
        }
    },
    emptySearchCall: function(component, helper, data) {
        var data = JSON.stringify({
            "searchString": "",
            "orderBy": "desc",
            "referrer": document.referrer,
            "uid": component.get("v.uid"),
        });
    
        let query = JSON.parse(data);
        query.pageSizeAdv = component.get("v.pageSizeAdvFiltr");
    
        var xmlHttp = new XMLHttpRequest();
        var url = component.get("v.endPoint") + "/search/SUSearchResults";
        xmlHttp.withCredentials = true;
        xmlHttp.open("POST", url, true);
        xmlHttp.setRequestHeader("Accept", "application/json");
        xmlHttp.setRequestHeader('Authorization', 'bearer ' + component.get('v.Bearer'));
        xmlHttp.setRequestHeader('Content-Type', 'application/json');
        xmlHttp.send(data);
        xmlHttp.onreadystatechange = function () {
            if (xmlHttp.readyState === 4) {
                if (xmlHttp.status === 200) {
                    var result = JSON.parse(xmlHttp.response);
                    if (result.statusCode != 402) {
                        component.set('v.values', JSON.parse(JSON.stringify(result.aggregationsArray)));
                        component.set('v.emptyResponseAggregations', result.aggregationsArray);
                        var setArray = result.aggregationsArray;
                        if(result.merged_facets && result.merged_facets.length) {
                            component.set("v.mergedArray", JSON.parse(result.merged_facets) || '[]');
                        }
                        if (component.get("v.mergedArray")) {
                            Array.from(component.get("v.mergedArray")).forEach(function (o) {
                                helper.mergeFilters(component, o, setArray, helper);
                            });
                        }
                        component.set('v.filtersArray', result.aggregationsArray[0]);
                        var c = JSON.parse(localStorage.getItem('theme' + component.get("v.uid")));
                        var hideEyeArray = component.get('v.values');
                        if(c) {
                            if (c["hiddenFacets"]) {
                                hideEyeArray.forEach(function(child) {
                                    if (c.hiddenFacets.includes(child.label)) {
                                        child.hideEye = true;
                                    } else {
                                        child.hideEye = false;
                                    }
                                })
                            }
    
                            component.set('v.values', hideEyeArray);
    
                            var sortArr = component.get("v.values");
                            sortArr.forEach(function(d) {
                                (c.facetsOrder).forEach(function(o) {
                                    if (d.label == o.value.label) {
                                        d.index = o.indexVal;
                                    }
                                })
                            });
    
                            sortArr.sort(function(a, b) {
                                return parseFloat(a.index) - parseFloat(b.index);
                            });

                            component.set("v.defaultTab", c.defaultTab.indexOf('merged_') > -1 ? c.defaultTab :c.activeTabIndex);
                            component.set("v.activeMergedChild", c.defaultTab.indexOf('merged_') > -1 ? c.activeMergedChild : '');
    
                            component.set('v.values', sortArr);
                        }
                        
                        if(component.get("v.isSmartFacets")){
                            let isSmartSelected = component.get("v.smartAggregations");
                            if(isSmartSelected){
                                hideEyeArray = component.get("v.values");
                                component.get("v.smartAggregations").forEach(function (outer){
                                    hideEyeArray.forEach(function (inner){
                                        if (inner.key == outer.key) {
                                            inner.smartHidden = true;
                                        }
                                    });
                               });                                
                            } 
                            component.set('v.values', hideEyeArray); 

                        }

                        component.set("v.customize", false);
                        component.set("v.customizeDiv", !component.get("v.customizeDiv"))
                        if (!component.get("v.customizeDiv")) {
                            component.set("v.valuesBackup", JSON.parse(JSON.stringify(component.get("v.values"))));
                        }
                    }
                    else if (result.statusCode == 402) {
                        window.location.hash = window.location.hash + "&flag=1";
                        location.reload();
                    }
                }
            }
        }
    },

    checkChildArray:function(tempValues, childArray, name,helper) {
        childArray.forEach(function (y){
            if (y.selected) {
                y.pathString = JSON.stringify(y.path);
                y.sticky_name = name + " > " + (y.displayName || y.Contentname);
                tempValues.push(y);
            }
            if (y.childArray) {
                helper.checkChildArray(tempValues, y.childArray, name + " > " + (y.displayName || y.Contentname),helper);
            }
        });
    },
    nestedParentFilter: function(helper, currentValue, key) {
        var thisObject = {};
        currentValue.some(function(f) {
            if (f.Contentname == key) {
                thisObject = f;
                return true;
            } else if (f.childArray && f.childArray.length) {
                thisObject = helper.nestedParentFilter(helper, f.childArray, key);
            	if (Object.keys(thisObject).length) return true;
            }
        })
        return thisObject;
    },

    childArrayCheckbox : function (helper, parent, childArray, value, uniqueRows, renderResponse, tempValues, name) {
        childArray.forEach(function(c) {

            c.checked = value;
            if(uniqueRows && uniqueRows.length) {
                let index = -1;
                Array.from(uniqueRows).some(function(f, i) { if (f.parent == c.parent && f.Contentname == c.Contentname) { index = i; return true; } });
                if (index !== -1) { uniqueRows[index] = {}; }
            }

            if(renderResponse){ if(value) c.sticky_name = name + " > " + (c.displayName || c.Contentname); tempValues.push(c); }

            else{ if(document.getElementById(parent+'_checkType_'+c.Contentname)) document.getElementById(parent+'_checkType_'+c.Contentname).checked = value;  }

            if(c.childArray){

                helper.childArrayCheckbox(helper, parent, c.childArray, value, uniqueRows, renderResponse, tempValues, name + " > " + (c.displayName || c.Contentname));

            }

        });
    },
    addClasses: function(component, event, helper) {
        if (!document.getElementsByClassName('su__css-scope-layout-2')[0] || !document.getElementsByClassName('su__css-scope-layout-3')[0]) {
            if (document.getElementById('filtersSec')) {
                document.getElementById('filtersSec').classList.add('filtersToRight');
                document.getElementById('resultsSec').classList.add('filtersToLeft');
            }
        }
    },

    removeClasses: function(component, event, helper) {
        if (!document.getElementsByClassName('su__css-scope-layout-2')[0] || !document.getElementsByClassName('su__css-scope-layout-3')[0]) {
            if (document.getElementById('filtersSec')) {
                document.getElementById('filtersSec').classList.remove('filtersToRight');
                document.getElementById('resultsSec').classList.remove('filtersToLeft');
            }
        }

    },

    appendTempClientFilters: function(component, helper, setArray, filterData, tempClientFilters) {
        setArray.map(function(f, i) {
            let selectedFilter = JSON.parse(filterData || '[]').filter(function(t) { return t.type == f.key && t.type != '_index' })[0];

            let mergedfilters = Array.from(component.get("v.mergedArray")).filter(function(o) { return (o.facetName == f.key); });
            let filterList = mergedfilters.filter(function(o) {
                let array = o.filterList.filter(function(element) { if (selectedFilter && selectedFilter.filter) { return selectedFilter.filter.indexOf(element) > -1; } });
                if (array.length > 0) {
                    selectedFilter.filter.push('merged_' + o.filterNewName);
                    return array;
                }
            });


            if (selectedFilter) {
                let childArr = [];
                if (selectedFilter.children) {
                    childArr = selectedFilter.children.map(function(f) { return f.childName });
                }
                selectedFilter = selectedFilter.filter.concat(childArr);

                for (var key in selectedFilter) {
                    var found = false;
                    let merged_index = -1;
                    f.values.filter(function(x, i) {
                        if ((x.contentName || x.Contentname).toString() === selectedFilter[key].toString()) {
                            found = true;
                            merged_index = i;
                            return found;
                        }
                    })
                    if (!found) {
                        f.values.some(function(s) {
                            if (s.childArray) {
                                found = helper.checkChildArrayValue(helper, s.childArray, selectedFilter[key]);
                                if (found) return found;
                            }
                        })
                    }
                    if (!found) {
                        tempClientFilters.map(function(m) {
                            if (f.key === m.key) {
                                m.values.map(function(z) {
                                    if ((z.contentName || z.Contentname).toString() === selectedFilter[key].toString()) {
                                        z.value = 0;
                                        if (z.Contentname.indexOf('merged_') > -1 && z.childArray) {
                                            let children = z.childArray.filter(function(h) {
                                                if (selectedFilter.indexOf(h.Contentname) > -1) {
                                                    h.value = 0;
                                                    return true;
                                                }
                                            });
                                            z.childArray = children || [];
                                        }
                                        f.values.push(z);
                                    } else if (z.childArray && !f.values.length) {
                                        z.value = 0;
                                        helper.setChildArrayValue(helper, z.childArray);
                                        f.values.push(z);
                                    }
                                })
                            }
                        })
                    } else if (selectedFilter[key].indexOf('merged_') > -1 && merged_index > -1) {
                        helper.updateMergeFilter(selectedFilter[key], filterList, f, selectedFilter, merged_index, tempClientFilters);
                    }
                }
            }
        })
    },
    setChildArrayValue: function(helper, childArray) {
        childArray.forEach(function(f) {
            f.value = 0;
            if (f.childArray) {
                helper.setChildArrayValue(helper, f.childArray);
            }
            f.value = f.checked ? 0 : f.value;
        })
    },
    updateMergeFilter: function(key, filterList, f, selectedFilter, merged_index, tempClientFilters) {
        let t = [];
        t = filterList.filter(function(j) {
            if (key == 'merged_' + j.filterNewName)
                return true;
        });
        let children = f.values[merged_index].childArray.map(function(g) { return g.Contentname });
        selectedFilter.forEach(function(p) {
            if (children.indexOf(p) == -1 && t.length && t[0].filterList.indexOf(p) > -1 && selectedFilter.indexOf(p)) {
                tempClientFilters.map(function(m) {
                    if (f.key === m.key) {
                        m.values.filter(function(o) {
                            if (o.Contentname == key) {
                                let i = -1;
                                o.childArray.some(function(u, index) { if (u.Contentname == p) { i = index; return true; } });
                                if (i > -1) {
                                    o.childArray[i].value = 0;
                                    f.values[merged_index].childArray.push(o.childArray[i]);
                                }
                            }
                        })
                    }
                })
            }
        })
    },
    checkChildArrayValue: function(helper, childArray, key, values) {
        for (var k in childArray) {
            let z = childArray[k];
            if ((z.contentName || z.Contentname).toString() === key.toString()) {


                return true
            } else if (z.childArray && z.childArray.length) {
                let t = helper.checkChildArrayValue(helper, z.childArray, key, values);
                if (t) return t;
            }
        }
    },

    pushSelected : function (helper, childArray, key, values){

        for (var k in childArray) {
            let z = childArray[k];
            if ((z.contentName || z.Contentname).toString() === key.toString()) {
                z.value = 0;
                if (z.childArray && z.childArray.length) {
                    helper.setChildArrayValue(helper, z.childArray);
                }
                return true;
            } else if (z.childArray) {
                let t = helper.pushSelected(helper, z.childArray, key, values);
                if (t) {
                    z.value = 0;
                    return t;
                }
            }
        }
    },
    removeBookmarksList: function(component, deleteList, helper) {

        let uid = component.get("v.uid");

        for (var j = 0; j < deleteList.length; j++) {

            let item = deleteList[j];

            let a = JSON.parse(localStorage.getItem('bookmark_searches_' + uid) || '[]');

            let index = -1;

            for (var i = 0; i < a.length; i++) {

                if (a[i].title == item.title && a[i].href == item.href) {

                    index = i;

                    break;
                }
            }
            if (index > -1) a.splice(index, 1);

            localStorage.setItem("bookmark_searches_" + uid, JSON.stringify(a));
        }


        let c = JSON.parse(localStorage.getItem('bookmark_searches_' + uid) || "[]");

        component.set("v.bookmarkSearches", c);
        document.getElementsByClassName("su__bookinput-h")[0].style.background = "#F9FAFC";
    },
    addPathName: function(component, parent, childArray, helper) {

        childArray.forEach(function(o) {
            o.path = JSON.parse(JSON.stringify(parent));
            if (o.childArray && o.childArray.length) {
                let p = JSON.parse(JSON.stringify(parent));
                p.push(o.Contentname)
                helper.addPathName(component, p, o.childArray, helper);
            }
        });
    },
    setPagination: function(component, helper, currentPageNumber, pageSize, pageNum){
        return new Promise(function(resolve, reject){
            var fromPage = currentPageNumber != 1 ? ((currentPageNumber - 1) * Number(pageSize)) + 1 : currentPageNumber;
            var toPage = currentPageNumber != 1 ? ((currentPageNumber - 1) * Number(pageSize)) + Number(pageSize) : Number(pageSize);
            var total = component.get("v.totalResults");
            if (total < toPage) {
                toPage = total;
            }
            var pagination = [];
            var totalNumberOfPages = Math.ceil(total / pageSize);
            var index;
            if (currentPageNumber <= 4) {
                for (index = currentPageNumber - 3; index < currentPageNumber; index += 1) {
                    if (index <= 0) {
                        continue;
                    }
                    pagination.push(index);
                }
                pagination.push(currentPageNumber);
                var jIndex;
                for (jIndex = currentPageNumber + 1; jIndex <= 7; jIndex += 1) {
                    if (jIndex >= totalNumberOfPages + 1) {
                        break;
                    }
                    pagination.push(jIndex);
                }
            } else if (currentPageNumber >= 4 && currentPageNumber < totalNumberOfPages - 3) {
                for (index = currentPageNumber - 3; index < currentPageNumber; index += 1) {
                    if (index <= 0) {
                        continue;
                    }
                    pagination.push(index);
                }
                pagination.push(currentPageNumber);
                for (var jindex = currentPageNumber + 1; jindex <= currentPageNumber + 3; jindex += 1) {
                    if (jindex > totalNumberOfPages) {
                        break;
                    }
                    pagination.push(jindex);
                }
            } else {
                var tempNum;
                if (currentPageNumber == (totalNumberOfPages - 3)) {
                    tempNum = 3;
                }
                if (currentPageNumber == (totalNumberOfPages - 2)) {
                    tempNum = 4;
                }
                if (currentPageNumber == (totalNumberOfPages - 1)) {
                    tempNum = 5;
                }
                if (currentPageNumber == totalNumberOfPages) {
                    tempNum = 6;
                }
                for (index = currentPageNumber - tempNum; index < currentPageNumber; index += 1) {
                    if (index <= 0) {
                        continue;
                    }
                    pagination.push(index);
                }
                pagination.push(currentPageNumber);
                var jindex;
                for (jindex = currentPageNumber + 1; jindex <= totalNumberOfPages + 2; jindex += 1) {
                    if (jindex > totalNumberOfPages) {
                        break;
                    }
                    pagination.push(jindex);
                }
                
            }
            
            component.set("v.lastPage", "" + totalNumberOfPages);
            component.set("v.paginationList", pagination);
            component.set("v.pageNum", pageNum);
            component.set("v.fromPage", fromPage);    
            component.set("v.toPage", toPage);
            resolve();
        })
        
    },
    setResults: function(component, result){
        return new Promise(function(resolve, reject){
            if(result.searchClientSettings.preview){
                for (var i = 0; i < result.result.hits.length; i++) {
                    if(result.result.hits[i].href.toLowerCase().includes('youtube.com') || (result.result.hits[i].href.toLowerCase().includes('vimeo.com') && /^\d+$/.test(result.result.hits[i].href.split('.com/')[1])) || result.result.hits[i].href.includes(window.location.origin)){
                        result.result.hits[i].showPreview = true;
                    }
                    else{
                        result.result.hits[i].showPreview = false;
                    }
                }              
            }
            resolve(component.set("v.responseListData", result.result.hits));
        });
    },
    setFilters: function(component, setArray){
        return new Promise(function(resolve, reject){
            component.set("v.aggregationsData", setArray);
            component.set("v.setFlag", false);
            resolve();
        })
    },
    setStickyFacets: function(component,helper, setArray){
        return new Promise(function(resolve, reject){
            var stickyArray= JSON.parse (JSON.stringify(setArray));
            var selectedStickyFilter = stickyArray.filter(function (x) {
                x.tempValues = [];
                if (x.key == '_index' && component.get('v.active') != 'all') {
                    x.sticky_label = "Tab";
                    x.values.map(function (o) {
                        if (o.Contentname == component.get('v.active') || (o.merged && o.selected)) {
                            o.sticky_name = o.displayName;
                            x.tempValues.push(o)
                        }
                        if (o.childArray && (x.order !=0 || (!o.merged || (o.merged && o.showChild != 0)) )) {
                            helper.checkChildArray(x.tempValues, o.childArray, (o.displayName || o.Contentname),helper);
                        }
                    });
                }
                if (x.key != '_index' ){
                    x.values.map(function (f) {
                        if (f.selected) x.tempValues.push(f);
                        if (f.childArray && (x.order !=0 || (!f.merged || (f.merged && f.showChild != 0)))) {
                            helper.checkChildArray(x.tempValues, f.childArray, (f.displayName || f.Contentname),helper);
                        }
                    })
                }
                
                if (x.tempValues.length) {
                    x.values = JSON.parse(JSON.stringify(x.tempValues || []));
                    delete x.tempValues;
                    return x;
                }
            });

            var exactPhrase = component.get("v.exactPhrase");
            var withOneOrMore = component.get("v.withOneOrMore");
            var withoutTheWords = component.get("v.withoutTheWords");
            exactPhrase ? selectedStickyFilter.unshift({ "key": 'exactPhrase', "label": "With the exact phrase", "values": [{ "selected": true, "Contentname": exactPhrase }] }) : '';
            withOneOrMore ? selectedStickyFilter.unshift({ "key": 'withOneOrMore', "label": "With one or more words", "values": [{ "selected": true, "Contentname": withOneOrMore }] }) : '';
            withoutTheWords ? selectedStickyFilter.unshift({ "key": 'withoutTheWords', "label": "Without the words", "values": [{ "selected": true, "Contentname": withoutTheWords }] }) : '';
            var stickyFilter_label = selectedStickyFilter.map(function (c) { return c.label });
            component.set("v.exactPhrase", exactPhrase);
            component.set("v.withOneOrMore", withOneOrMore);
            component.set("v.withoutTheWords", withoutTheWords);

            var stickyFilter_label = selectedStickyFilter.map(function(c) { return c.label });
            component.set("v.stickyFilter_label", stickyFilter_label);
            component.set("v.activeSticky", stickyFilter_label[0]);
            component.set("v.selectedStickyFilter", selectedStickyFilter);
            resolve();
        })  
    },                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
    mergeFilters: function(component, h, aggrData, helper, isSearched) {
        let k = -1;
        let existingIndex = -1;
        aggrData.some(function(f, i) { if (f.key == h.facetName) { k = i; return true; } });
        if (k == -1) return;
        let exists = aggrData.length > 0 ? aggrData[k].values.filter(function(f,i) { if( f.Contentname == 'merged_'+h.filterNewName) { existingIndex = i; return true;} }) : [];
        let children = exists.length ? aggrData[k].values[existingIndex].childArray.map(function(f){return f.Contentname}) : [];
        if (isSearched) {
            let filtersToAdd = component.get("v.aggregationsData").filter(function(f) {return f.key == h.facetName})[0].values.find(function (n) { return n.Contentname == 'merged_' + h.filterNewName});
            if (filtersToAdd)
            filtersToAdd.childArray.forEach(function(filter) {
                if(children.indexOf(filter.Contentname) == -1) {
                    aggrData[k].values.push(filter);
                }
            })
        }
        h.filterList = h.filterList.map(function(filter) { return decodeURIComponent(filter)});
        let l = k > -1 ? aggrData[k].values.filter(function(f) { return h.filterList.indexOf(f.Contentname) > -1 && children.indexOf(f.Contentname) == -1 }) : [];
        let v = 0;
        l.forEach(function(f) {
            v += f.value;
        });

        if (l.length) {
            let place = aggrData[k].values.length;
            aggrData[k].merged = true;
            let childArray = [];
            let s = JSON.parse(JSON.stringify(l[0]));
            l.forEach(function(f) {
                let index = -1;
                aggrData[k].values.some(function(d, i) { if (d.Contentname == f.Contentname) { index = i; return true; } });
                childArray.push(aggrData[k].values[index]);
                if (index < place) place = index;
                let regex = new RegExp(".*" + component.get("v.pagingAggregation") + ".*", 'gi');
                if ( (index > -1 && !isSearched) || (isSearched && !regex.test(aggrData[k].values[index].Contentname))) aggrData[k].values.splice(index, 1);
            });

            childArray.forEach(function(f) { f.immediateParent = 'merged_' + h.filterNewName;
            f.level = 2;
            f.parent = h.facetName;
            f.childName = f.Contentname; });
            let exists = aggrData[k].values.filter(function(f,i) { if( f.Contentname == 'merged_'+h.filterNewName) { existingIndex = i; return true;}  });
            if (existingIndex == -1) {
                s.displayName = h.filterNewName;
                s.Contentname = 'merged_' + h.filterNewName;
                s.Contentname_short = h.filterNewName;
                s.displayNameFrontend=h.filterNewName;
                s.value = isSearched ? null : v;
                s.merged = true;
                s.showChild = h.showChild;
                s.selected = false;
                s.filterList = h.filterList;
                s.indeterminate = false;
                s.childArray = JSON.parse(JSON.stringify(childArray));
                var aggregations=JSON.parse(component.get("v.selectedTypeFilter") || '[]');
                if (aggregations.length != 0) {
                    let index = -1;
                    aggregations.some(function (facet, i) { if (facet.type == h.facetName) { index = i; return true; } });
                    if (index >= 0) {
                        var filtersInAggr;
                        let existingChildren = l.map(function(c) { return c.Contentname} )
                        if (aggregations[index] && aggregations[index].filter && aggregations[index].filter.length) {
                            filtersInAggr = aggregations[index].filter.filter(function (ele) {
                                return existingChildren.indexOf(ele) > -1
                            })
                            if (filtersInAggr.length == existingChildren.length){
                                s.selected = true;
                            } else if(filtersInAggr.length) {
                                s.indeterminate =  true;
                            }
                        }
                    }
                }
                aggrData[k].values.splice(place, 0, s);
                aggrData[k].values = aggrData[k].sort && aggrData[k].sort != 'custom' ? helper.sortMergeFacetFunc(component, aggrData[k].values, aggrData[k].sort) : aggrData[k].values;
            }
            else {
                aggrData[k].values[existingIndex].value += v;
                aggrData[k].values[existingIndex].childArray = aggrData[k].values[existingIndex].childArray.concat(childArray);
            }
        }
        //console.log(Array.from(component.get("v.mergedArray")));
    },
    htmlDecode: function (input) {

        var e = document.createElement('div');
        e.innerHTML = input;
        return e.childNodes.length === 0 ? "" : e.childNodes[0].nodeValue;
    },
    sortMergeFacetFunc: function(component, filters, sort){
        let sortBy = sort.split('_')[0];
        let orderBy = sort.split('_')[1];
        if (sortBy === 'term') filters = filters.sort(function(a, b) { 
            return ( (a.displayNameFrontend || a.ContentnameFrontend) > (b.displayNameFrontend || b.ContentnameFrontend)
                ? 1
                : (a.displayNameFrontend || a.ContentnameFrontend) < (b.displayNameFrontend || b.ContentnameFrontend)
                    ? -1
                    : 0
                )          
        })
        if (sortBy === 'count') filters = filters.sort(function(a, b) {return a.value - b.value});
        if (orderBy === 'desc') filters = filters.reverse();
        let arr = [];
        return(filters.filter(function(f) {
            if (f.selected) return f; 
            arr.push(f);
        }).concat(arr));
    },
    clickSearchSuggestion: function(component, event, helper, suggestionValue) {
        window.location.hash = encodeURIComponent("searchString=" + encodeURIComponent(suggestionValue) + "&pageNum=1&sortBy=" + component.get("v.sortByCheck") + "&orderBy=desc&resultsPerPage=" + component.get("v.pageSize") + "&pageSizeAdv=" + component.get("v.pageSizeAdvFiltr") + "&exactPhrase=" + encodeURIComponent(component.get("v.exactPhrase")) + "&withOneOrMore=" + encodeURIComponent(component.get("v.withOneOrMore")) + "&withoutTheWords=" + encodeURIComponent(component.get("v.withoutTheWords")) + "&selectedType=" + encodeURIComponent(helper.getURLParameter('selectedType')));
        component.set("v.searchString", suggestionValue);
        var searchBoxEvent = $A.get("e.su_vf_console:fillSearchBox");
        searchBoxEvent.setParams({ "searchString": suggestionValue });
        helper.goToTopFunc(component, event, helper);
        searchBoxEvent.fire();
    },
    disableSmartFacets: function(component, event, helper){
       component.set("v.isSmartFacets", false);
       component.set("v.isSmartHidden", false);
       document.cookie = "smartFacets=false; expires=Thu, 01 Jan 9999 00:00:00 UTC; path=/;";             
    },                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
    dymClickHelper: function(component, event, helper, dymClickedString) {
        var previousDymString = component.get("v.searchString");
        window.location.hash = encodeURIComponent("searchString=" + encodeURIComponent(dymClickedString) + "&pageNum=1&sortBy=" + component.get("v.sortByCheck") + "&orderBy=desc&resultsPerPage=" + component.get("v.pageSize") + "&pageSizeAdv=" + component.get("v.pageSizeAdvFiltr") + "&exactPhrase=" + encodeURIComponent(component.get("v.exactPhrase")) + "&withOneOrMore=" + encodeURIComponent(component.get("v.withOneOrMore")) + "&withoutTheWords=" + encodeURIComponent(component.get("v.withoutTheWords")) + "&selectedType=" + encodeURIComponent(helper.getURLParameter('selectedType')) + "&dym=" + encodeURIComponent(previousDymString));
        component.set("v.searchString", dymClickedString);
        var searchBoxEvent = $A.get("e.su_vf_console:fillSearchBox");
        searchBoxEvent.setParams({ "searchString": dymClickedString });
        searchBoxEvent.fire();
    },
    searchFilterSuggestions: function(component, key, searchStringFilter, event, helper) {
        var pagingAggregation;
        var filterData = component.get("v.selectedTypeFilter");
        var aggregationsData = component.get("v.aggregationsData");
        var dropdownField = document.getElementById('collapseExample-'+key);
        pagingAggregation = {"field": key, "keyword": searchStringFilter};
        let searchKeywords = [pagingAggregation.keyword];
        let mergedArray = component.get('v.mergedArray');
        const found = mergedArray.filter(function(f) { return f.facetName === key && f.filterNewName.toLowerCase().indexOf(pagingAggregation.keyword.toLowerCase()) > -1});
        searchKeywords = found ? searchKeywords.concat(...found.map(function (f) { return f.filterList})) : searchKeywords;
        pagingAggregation.merged = found && found.length ? true : false;
        if (pagingAggregation.merged) {
            pagingAggregation.mergedKeywords = searchKeywords;
        }
        component.set("v.pagingAggregation",pagingAggregation);
        var pageSize = component.get("v.pageSize");
        let aggregationsBck,newIndex,aggregationCheck = [];
               
        if(filterData){
            aggregationsBck = JSON.parse(filterData);
            aggregationsBck.forEach(function (filterSearch, i) {
                if(filterSearch.type === key){
                    aggregationsBck.splice(i, 1);
                }
            })
    	    component.set("v.multiVersion", false)
        } else {
            component.set("v.multiVersion", true)
        }
        aggregationsData.some(function(f, i){ if(f.key == key) {newIndex = i; return true;}});

        var analyticsCmp = component.find("SuAnalytics");
        var data = JSON.stringify({
            "searchString": component.get("v.searchString"),
            "from": ((component.get("v.pageNum") - 1) * component.get("v.pageSize")),
            "pageNum": parseInt(component.get("v.pageNum")),
            "pageNo": parseInt(component.get("v.pageNum")),
            "sortby": component.get("v.sortByCheck"),
            "orderBy": "desc",
            "resultsPerPage": parseInt(pageSize),
            "exactPhrase": component.get("v.exactPhrase"),
            "withOneOrMore": component.get("v.withOneOrMore"),
            "withoutTheWords": component.get("v.withoutTheWords"),
            "aggregations": aggregationsBck,
            "referrer": document.referrer,
            "recommendResult": "",
            "indexEnabled": component.get("v.contentSourceTab"),
            "sid": analyticsCmp.analytics('_gz_taid', '') + '$Enter$',
            "cookie": analyticsCmp.analytics('_gz_sid', ''),
            "uid": component.get("v.uid"), 
            "language":localStorage.getItem('language') || 'en',
            "pagingAggregation": component.get("v.pagingAggregation"),
            "versionResults": component.get("v.multiVersion")
        });
        
        if (searchStringFilter) {        
            var xmlHttp = new XMLHttpRequest();
            var url = component.get("v.endPoint") + "/search/SUSearchResults";
            xmlHttp.withCredentials = true;
            xmlHttp.open("POST", url, true);
            xmlHttp.setRequestHeader("Accept", "application/json");
            xmlHttp.setRequestHeader('Authorization', 'bearer ' + component.get('v.Bearer'));
            xmlHttp.setRequestHeader('Content-Type', 'application/json');

            xmlHttp.send(data);
            xmlHttp.onreadystatechange = function() {
                if (xmlHttp.readyState === 4) {
                    if (xmlHttp.status === 200) {
                        var result = JSON.parse(xmlHttp.response);                       
                        if (result.statusCode != 402) {
                            if (result.statusCode == 200) {
                                if(result.aggregationsArray.length){
                                    
                                    found.forEach(function (f) {
                                        helper.mergeFilters(component, f, result.aggregationsArray, helper, true);
                                    })
                                    result.aggregationsArray.forEach(function (filter) {
                                        if (filter.key === key) {
                                            let aggregationsSent;
                                            if(filterData) {
                                                aggregationsSent = JSON.parse(filterData || '[]').find(function(f) { return f.type == key});
                                            }
                                            if(filter.values.length > 0){
                                                filter.values = filter.values.filter(function(u) {
                                                    const facet_Regex = new RegExp(".*" + searchStringFilter + ".*", 'gi');
                                                    return  facet_Regex.test(u.Contentname)
                                                });
                                                aggregationsData[newIndex].values.some(function(value){
                                                    if(value.selected === true){
                                                        aggregationCheck.push(value.Contentname);
                                                    }
                                                    if(value.childArray) {
                                                        if(value.childArray.length > 0) {
                                                            value.childArray.forEach(function (f, i) {
                                                                if(f.selected === true){
                                                                    aggregationCheck.push(f.Contentname);
                                                                }
                                                            })
                                                        }       
                                                    }
                                                })
                                                aggregationsData[newIndex].filterSuggest = "result";
                                                aggregationsData[newIndex].filterSuggestions = filter.values;
                                                aggregationsData[newIndex].values.some(function(filterValue){
                                                    filter.values.some(function(value){
                                                        aggregationCheck.some(function(f){
                                                            if(value.Contentname === f){
                                                                value.selected = true;
                                                            }
                                                        })
                                                        value.selected = aggregationsSent && aggregationsSent.filter && aggregationsSent.filter.indexOf(value.Contentname) > -1 ? true : value.selected;
                                                        if (value.childArray && aggregationsSent && aggregationsSent.filter)
                                                            helper.checkSelected(component, value.childArray, aggregationsSent, helper);
                                                        if(value.Contentname === filterValue.Contentname){
                                                            if(filterValue.checked){
                                                                value.checked = true;
                                                            }
                                                        }
                                                    })                                                    
                                                })
                                                dropdownField.parentNode.classList.add('su__filter-suggest');
                                            } else {
                                                aggregationsData[newIndex].filterSuggest = "no-result";
                                                aggregationsData[newIndex].filterSuggestions = [];
                                                dropdownField.parentNode.classList.remove('su__filter-suggest');
                                            }
                                            component.set("v.aggregationsData",aggregationsData);
                                        }
                                    });
                                }
                                else{
                                    aggregationsData.forEach(function(filter, i) {
                                        filter.filterSuggest = "no-result";
                                        filter.filterSuggestions = [];
                                                 
                                    });
                                }
                            component.set("v.aggregationsData",aggregationsData);
                            }
                        }
                    }
                }
            }
        }
        else{
            aggregationsData[newIndex].filterSuggest = 'result'
            event.target.classList.add('su__search-facet-input');
            event.target.classList.remove('su__search-facet-empty');
            dropdownField.parentNode.classList.add('su__filter-suggest');
            component.set("v.aggregationsData",aggregationsData);
        }
    },
    checkSelected: function(component, childArray, aggregationsSent, helper) {
        childArray.forEach(function (f) {
            f.selected = aggregationsSent.filter.indexOf(f.Contentname) > -1 ? true :false;
            if (f.childArray) helper.checkSelected(component, f.childArray, aggregationsSent, helper);
            return
        })
    },
    typeFacetSelectFunc: function(component, event, helper){
        var aggregationsData = component.get("v.aggregationsData");
        var filterSelect = event.target.step;
        var filterTargetName = event.target.name;
        var filterValue = {};
        let mergedArray = component.get('v.mergedArray');
        let mergeExist = false;
        let flag = 0;
        let item = {};
        let value = JSON.parse(event.target.parentElement.parentElement.children[2].children[0].innerHTML);
        let search;
        
        aggregationsData.forEach(function(filter) {
            if (filter.key === filterSelect) {
                
                let index = -1;       
                mergedArray.some(function(filter, i){ if (filter.filterNewName.trim().indexOf(filterValue.Contentname) > -1) {index = i; return true;}});
                if (index > -1 && mergedArray[index].filterList.indexOf(filterTargetName) > -1) {
                    filterValue.Contentname = filterTargetName;
                    filterValue.value = value;
                    filterValue.parent = filterSelect;
                    filterValue.immediateParent = 'merged_' + mergedArray[index].filterNewName;                  
					filterValue.checked = true;
            		flag = 2;
                    item = filterValue;
                    search = 'facetSearch';
                }
                filter.values.some(function(name, i){
                    if(name.Contentname === filterTargetName){
                        filterValue = name;
                        filter.values.splice(i, 1);                                                                               
                        if(name.childArray){
                            name.childArray.forEach(function (filter){
                                if(filter.Contentname.indexOf(filterTargetName) > -1){
                                    mergeExist = true;
                                }
                            })
                        } 
                    }
                })
                            
                if(!filterValue.key){
                    for (var i = 0; i < filter.filterSuggestions.length; i++) {
                        if(filter.filterSuggestions[i].Contentname === filterTargetName){
                            filterValue = filter.filterSuggestions[i]; 
                        }                                     
                    }
                }
				filter.filterSuggestions = [];
                if(!mergeExist){
                 	filter.values.unshift(filterValue);   
                }
            }                
        });
        component.set("v.aggregationsData",aggregationsData);                                            
        var inputSearch = document.getElementById(filterSelect+'-facetSearch');
        inputSearch.value = '';
        var searchFacetInput = document.getElementById('searchFacetDiv-facetIcon-'+filterSelect);
        searchFacetInput.classList.remove('su__flex-vcenter');
        searchFacetInput.classList.add('su__d-none');
        var searchIcon = document.getElementById('facetSearchIcon-facetIcon-'+filterSelect);
        var showMore = document.getElementById('show-more-facetIcon-'+filterSelect);
        searchIcon.classList.add('su__d-block');
        searchIcon.classList.remove('su__d-none');
        showMore.classList.add('su__d-block');
        showMore.classList.remove('su__d-none');
        helper.typeSelectFunc(component, event, helper, flag, item, search);
    },
    searchFiltersFunc: function(component, event, helper){
        var searchFacetClass = event.target.classList[0];
        var searchFacetInput = document.getElementById('searchFacetDiv-'+searchFacetClass);
        var showMore = document.getElementById('show-more-'+searchFacetClass);
        var closeIcon = document.getElementById('facetCloseIcon-'+searchFacetClass);
        var input = document.getElementById('su__search-facet-input-'+searchFacetClass.split('-')[1]);
        event.target.classList.remove('su__d-block');
        event.target.classList.add('su__d-none');
        // showMore.classList.remove('su__show-more');
        showMore.classList.remove('su__flex-vcenter');
        showMore.classList.add('su__d-none');
        searchFacetInput.classList.remove('su__d-none');
        searchFacetInput.classList.add('su__flex-vcenter');
        input.focus();
        input.value = '';
        closeIcon.classList.remove('su__d-none')
        closeIcon.classList.add('su__d-inline-block');
        component.set('v.searchFacet', searchFacetClass.split('-')[1]);
    },
   	filterCloseFunc: function(component, event, helper){
        var searchFacetClass = event.target.classList[0];
        var searchFacetInput = document.getElementById('searchFacetDiv-'+searchFacetClass);
        var searchText = document.getElementsByName('searchFacetDiv-'+searchFacetClass);
        var showMore = document.getElementById('show-more-'+searchFacetClass);
        var searchIcon = document.getElementById('facetSearchIcon-'+searchFacetClass);
        var aggregationsData = component.get("v.aggregationsData");
        var filterSelect = searchFacetClass.split('-')[1];
        event.target.classList.remove('su__flex-vcenter');
        event.target.classList.add('su__d-none');
        showMore.classList.add('su__flex-vcenter');
        showMore.classList.remove('su__d-none');
        searchFacetInput.classList.remove('su__flex-vcenter');
        searchFacetInput.classList.add('su__d-none');
        searchText[0].value = '';
        searchIcon.classList.add('su__d-block');
        searchIcon.classList.remove('su__d-none');
        aggregationsData.forEach(function(filter) {
            if(filter.key === filterSelect){
                delete filter.filterSuggestions;
                delete filter.filterSuggest;
            }
        }) 
        component.set("v.aggregationsData",aggregationsData); 
    },
    mouseleftFunc: function (component, event) {
        var filterSelect = component.get('v.searchFacet');
        var searchFacetInput = document.getElementById('searchFacetDiv-facetIcon-'+filterSelect);
        var searchIcon = document.getElementById('facetSearchIcon-facetIcon-'+filterSelect);
        var showMore = document.getElementById('show-more-facetIcon-'+filterSelect);
        var input = document.getElementById('su__search-facet-input-'+filterSelect);
        setTimeout(function () {
            document.getElementById('su_searchUnifyContainer1').onclick = function(e) {
                if(e.target !== document.getElementById(filterSelect) && e.target !== document.getElementById(filterSelect+'-facetSearch') && e.target !== searchIcon && e.target !== showMore && e.target !== input) {
                    var aggregationsData = component.get("v.aggregationsData");
                    aggregationsData.forEach(function(filter) {
                        if(filter.key === filterSelect){
                            filter.filterSuggestions = [];
                        }
                    })                 
                    input.value = '';       
                    input.classList.remove('su__search-facet-empty');
                    input.classList.add('su__search-facet-input');             
                    searchFacetInput.classList.remove('su__flex-vcenter');
                    searchFacetInput.classList.add('su__d-none');
                    searchIcon.classList.add('su__d-block');
                    searchIcon.classList.remove('su__d-none');
                    showMore.classList.add('su__flex-vcenter');
                    showMore.classList.remove('su__d-none');
                    component.set("v.aggregationsData",aggregationsData); 
                }
            }
        }, 300);
        
    },
    resultPreviewFunc: function(component, event, helper) {
        if (event.target.closest('span')){
            helper.runScriptMethodFunc(component, event, helper);
            var href = event.target.getAttribute("data-href") || "";
            var title = event.target.getAttribute("data-title") || "";
            if(!title){
                title=href;
            }
          	var label = event.target.getAttribute("data-label") || "";
           	if (href.toLowerCase().includes('youtube.com')) {
                href= href.replace('watch?v=', 'embed/');
            }
            else if (href.toLowerCase().includes('vimeo.com')) {
                href= ('https://player.vimeo.com/video/' + href.split('.com/')[1]);
            }
            component.set("v.previewSource", href);
           	component.set("v.previewTitle", title);
           	component.set("v.previewLabel", label);
            document.getElementsByClassName("su__iframe-modal-view")[0].classList.add("su__preview-toggle");
            document.getElementsByTagName("body")[0].classList.add("su__overflow-hidden");
        }
  },
  dismissPreviewFunc: function(component, event, helper) {
    component.set("v.previewSource", ''); 
     component.set("v.previewTitle", '');
     component.set("v.previewLabel", '');
    if (document.getElementsByClassName("su__iframe-modal-view")[0]) {
        document.getElementsByClassName("su__iframe-modal-view")[0].classList.remove("su__preview-toggle");
    }
    if (document.getElementsByClassName("su__left-sidebar-layout-2")[0] || document.getElementsByClassName("su__topFilters-overlay")[0]) {
        document.getElementsByClassName("su__left-sidebar-layout-2")[0].classList.remove("su__fillter-toggle");
        document.getElementsByClassName("su__topFilters-overlay")[0].classList.remove("su__viewMore-block");
    }
    document.getElementsByTagName("body")[0].classList.remove("su__overflow-hidden");
    component.set("v.topFiltersLayoutDiv", false);
    component.set("v.showFilterLargeDiv", false);
    document.getElementsByClassName('su__iframe-src')[0].setAttribute("src",'');
}, 
    buttonClick : function(component, event, helper) {
        var clicked = event.target;
        var rowIndex = clicked.getAttribute("data-index");
        component.set("v.feedbackRatingVal", rowIndex);
        if(document.getElementsByClassName('su__ratingicon').length != 0) {
            component.set('v.isButtonActive',false);
            for(var a = 0; a < document.getElementsByClassName('su__ratingicon').length; a++){
                document.getElementsByClassName('su__ratingicon')[a].classList.remove('su__emoji-active');
                document.getElementsByClassName('su__ratingicon')[a].classList.remove('su__star-yellow');    
            }
            for(var i=0;i<rowIndex; i++){
                document.getElementsByClassName('su__ratingicon')[i].classList.add('su__emoji-active');
                document.getElementsByClassName('su__ratingicon')[i].classList.add('su__star-yellow');    
            }
        }
        component.set('v.isButtonActive',false);
    },                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
        submitFeedback: function(component, event) {                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
            var feedbackAreaVal = component.find("feedbacktxArea") ? component.find("feedbacktxArea").get("v.value") : '';
        // var feedbackEmailVal = component.get("v.currentCommunityEmail");
            var inputboxTxtEmailVal = component.get("v.setCurrentEmail") || component.find("feedbackEmail") ? component.find("feedbackEmail").get("v.value")  : '';
        // var feedbackTxtVal = component.find("feedbacktextInput");
            var feedbackRateVal = component.get("v.feedbackRatingVal");
            var childCmp = component.find("SuAnalytics");
            var searchStringVal = component.get("v.searchString");
            var objToSend = {
                referer: document.referrer, 
                uid: component.get("v.uid"),
                window_url: window.location.href || '', 
                feedback: feedbackAreaVal || '',
                rating: feedbackRateVal || '',
                text_entered: searchStringVal || '',
                reported_by:  inputboxTxtEmailVal || '',
            };
            if (!component.get("v.pageFeedback")) {
                objToSend["conversion_url"] = component.get("v.feedbackConvObj").href;
                objToSend["conversion_title"] = component.get("v.feedbackConvObj").title;
                objToSend["conversion_position"] = +component.get("v.clickedTitleVal") + +1;
                objToSend["pageSize"] = component.get("v.pageSize") || '';
                objToSend["page_no"] = component.get("v.pageNum") || '';
            }
            childCmp.analytics("searchfeedback", objToSend);
            component.set("v.pageFeedback",false);
            component.set("v.emailShowhide", true);
            component.set('v.isButtonActive',true);
        },  
})