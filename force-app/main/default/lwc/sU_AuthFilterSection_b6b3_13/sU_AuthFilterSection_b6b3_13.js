import { LightningElement, track, api } from 'lwc';
import { registerListener, unregisterListener, fireEvent, mergeFilters } from 'c/authsupubsub_b6b3_13';
export default class SU_AuthFilterSection extends LightningElement {

    @api showFilter;
    @api finalLang;
    @track filterSortingLoading;
    @api selectedTypeFilter;
    @api showClearFiltersButton = false;
    @api bearer;
    @track defaultFilterCollapseCheckUp_Arrow ='arrow-position su__d-block su__cursor';
    @track defaultFilterCollapseCheckDown_Arrow= 'arrow-position su__d-none su__cursor'
    @api uid;
    @api loading;
    @api endPoint;
    @api searchQuery;
    @api showmobilefiltersection;
    @track aggregationsData = [];
    @track facetdrop = "su__search-facet-drop";
    @api translationObject;
    @api gototopcontainer;
    @api collapseSearchFilters = false;
    @api defaultFilterCollapse;
    @api
    set mergedArray(value) {
        if(value) {
            this.mergedArrayReceived = JSON.parse(JSON.stringify(value)) || [];
        }
    };
    get mergedArray() { return this.mergedArrayReceived; }
    @api
    set aggregationsDataIn(value) {
        if (value) {
            this.aggregationsData = JSON.parse(JSON.stringify(value));
        }   
        this.aggregationsData.forEach(facet => {
            facet &&  facet.values.forEach(f => {
                if(f.immediateParent) {
                    f.encodedContentname = encodeURI(f.immediateParent + '_' + f.Contentname);
                }
            });
            setTimeout(() => {
                if (facet && facet.key != "_index" && this.defaultFilterCollapse && this.template.querySelector(`div[data-id='${facet.key}']`)) {
                    this.template.querySelector(`div[data-id='${facet.key}']`).parentElement.nextElementSibling.classList.add('showPanel');
                }
            }, 10);
        });
        
    };
    get aggregationsDataIn() {
        return this.aggregationsData;
    }
    arr_StickyData = [];
    arr_StickyData1 = [];
    //defaultFilterCollapse = false;
    filtersSortingCheck = false;
    showAllStickyFacets = false;
    showFilterOrStickyLabel = 'Filters';
    currentClickedOrder;
    searchFacetIndexVal = '';
    get showFilterOrSticky() {
        return this.showFilter || this.showAllStickyFacets;
    }

    connectedCallback() {
        registerListener("clearStickyFilter", this.handleClearStickyFilter, this);
        registerListener('nestedFilter', this.typeSelectEvent, this);
    }

    disconnectedCallback() {
        unregisterListener("clearStickyFilter", this.handleClearStickyFilter, this);
        unregisterListener('nestedFilter', this.typeSelectEvent, this);
    }

    renderedCallback() {
        this.aggregationsData.forEach(facet => {
            facet && facet.values.forEach(f => {
                const currentId = f.collapseExampleID;
                const childId = currentId && currentId.split('_icon')[0];
                if (childId) {
                    const divTocollapse = this.template.querySelector(`[data-id="${childId}"]`);
                    const closeIcon = this.template.querySelector(`[data-id="${childId + '_toggleIconOn'}"]`);
                    const openIcon = this.template.querySelector(`[data-id="${childId + '_toggleIconOff'}"]`);
                    if (f.open && closeIcon && openIcon && divTocollapse) {
                        closeIcon.classList.remove('su__d-block');
                        closeIcon.classList.add('su__d-none');
                        openIcon.classList.remove('su__d-none');
                        openIcon.classList.add('su__d-block');
                        divTocollapse.classList.add('child-filters-block');
                        divTocollapse.classList.remove('su__d-none');
                        divTocollapse.classList.add('in');
                    } else if (divTocollapse && divTocollapse.classList && openIcon && closeIcon) {
                        openIcon.classList.remove('su__d-block');
                        openIcon.classList.add('su__d-none');
                        closeIcon.classList.remove('su__d-none');
                        closeIcon.classList.add('su__d-block');
                        divTocollapse.classList.remove('child-filters-block');
                        divTocollapse.classList.add('su__d-none');
                        divTocollapse.classList.remove('in');
                    }
                }
                if (!this.template.querySelector('[data-econtentname="' + f.encodedContentname + '"]')) return;
                this.template.querySelector('[data-econtentname="' + f.encodedContentname + '"]').checked = f.selected;
                if ((facet.key.slice(-7) != '_nested' && facet.key.slice(-11) != '_navigation') && f.indeterminate)
                    this.template.querySelector('[data-econtentname="' + f.encodedContentname + '"]').classList.add('indeterminate');
                else
                    this.template.querySelector('[data-econtentname="' + f.encodedContentname + '"]').classList.remove('indeterminate');
            })
        });
    }

    typeSelectEvent(data) {
        this.headerCheckoxChanged(null, true, data.filter)
    }
    handleClearStickyFilter() {
        this.arr_StickyData = [];
        this.arr_StickyData1 = [];
    }
    //Method is called when click on dropdown
    filtersPopup(event) {
        var resultIndex = event.currentTarget.dataset.id;
        if (resultIndex) {
            var filter_isCollapsed = event.currentTarget.nextSibling;
            if (filter_isCollapsed && filter_isCollapsed.classList.contains('visibilityHidden')) {
                filter_isCollapsed.classList.remove("visibilityHidden", "su__position-absolute");
                filter_isCollapsed.classList.add("su__sort-filter", "su__position-absolute", "su__bg-white", "su__zindex-2", "su__shadow", "filter_isCollapsed");
                this.template.querySelectorAll('.su__backdrop').forEach(f => f.classList.remove('su__d-none'));
            } else {
                this.template.querySelectorAll('.filter_isCollapsed').forEach(element => {
                    if (element && element.classList.contains('filter_isCollapsed')) {
                        element.classList.remove("su__sort-filter", "su__position-absolute", "su__bg-white", "su__zindex-2", "su__shadow", "filter_isCollapsed");
                        element.classList.add("visibilityHidden", "su__position-absolute");
                    }
                });
                this.template.querySelectorAll('.su__backdrop').forEach(f => f.classList.add('su__d-none'));
            }
        } else {
            this.template.querySelectorAll('.filter_isCollapsed').forEach(element => {
                if (element && element.classList.contains('filter_isCollapsed')) {
                    element.classList.remove("su__sort-filter", "su__position-absolute", "su__bg-white", "su__zindex-2", "su__shadow", "filter_isCollapsed");
                    element.classList.add("visibilityHidden", "su__position-absolute");
                }
            });

        }
    }

    // This method is used to toggle show and hide of filter data
    handleInsideFilters(event) {
        var filterId = event.currentTarget.dataset.id;
        if(this.template.querySelector(`div[data-id='${filterId}']`)) {
            this.template.querySelector(`div[data-id='${filterId}']`).classList.toggle("su__active-Filter-color");
            this.template.querySelector(`div[data-id='${filterId}']`).parentElement.nextElementSibling.classList.toggle('showPanel');
        }
    }

    closePopup(event) {
        this.template.querySelectorAll('.filter_isCollapsed').forEach(element => {
            if (element && element.classList.contains('filter_isCollapsed')) {
                element.classList.remove("su__sort-filter", "su__position-absolute", "su__bg-white", "su__zindex-2", "su__shadow", "filter_isCollapsed");
                element.classList.add("visibilityHidden", "su__position-absolute");
            }
        });
        this.template.querySelectorAll('.su__backdrop').forEach(f => f.classList.add('su__d-none'));
    }
    goToTopContainerFunc() {
        if (this.gototopcontainer) {
            this.gototopcontainer.scrollIntoView();
        }
    }

    //This method is useed to show more data
    showMore(event) {
        if (this.finalLang) {
            if (this.finalLang.showLess) {
                showLess = this.finalLang.showLess;
            }
            if (this.finalLang.showMore) {
                showMore = this.finalLang.showMore;
            }
        }
        var id = event.currentTarget.dataset.id;
        var slittedId = id.split('_showMore')[0];
        var data = this.template.querySelector(`div[data-id='${slittedId}']`);
        if (data && data.classList.contains('su__nonExpanded')) {
            data.classList.remove('su__nonExpanded');
            data.classList.add('su__Expanded');
        } else if (data) {
            data.classList.add('su__nonExpanded');
            data.classList.remove('su__Expanded');
        }
    }

    //This method is used to sort filters
    filterSorting(event) {
        this.filterSortingLoading = true;
        var index = Number(event.target.getAttribute('data-id'));
        var element = event.currentTarget && event.currentTarget.parentElement && event.currentTarget.parentElement.parentElement;
        if (element && element.classList.contains('filter_isCollapsed')) {
            element.classList.remove("su__sort-filter", "su__position-absolute", "su__bg-white", "su__zindex-2", "su__shadow", "filter_isCollapsed");
            element.classList.add("visibilityHidden", "su__position-absolute");
            element.nextSibling.classList.remove("su__bg-overlay", "su__overlay", "su__isCollapsed");
        }

        let flag = 0;
        let item = {};
        this.headerCheckoxChanged(event, flag, item);
        if (this.template.querySelectorAll('.su__backdrop')) {
            this.template.querySelectorAll('.su__backdrop').forEach(f => f.classList.add('su__d-none'));
        }

    }

    //this method is called when we select any filter value
    headerCheckoxChanged(event, flag, itemRemoved) {
        fireEvent(null, "disableSmartFacets", false);
        if (!flag) {
            if (event.currentTarget.checked) {
                this.showClearFiltersButton = true;
            }
            var clickedFilter = {};
            clickedFilter["Contentname"] = event.target.name,
            clickedFilter["immediateParent"] = event.currentTarget.dataset.min,
            clickedFilter["parent"] = event.currentTarget.dataset.step || event.currentTarget.dataset.item,
            clickedFilter["level"] = event.currentTarget.dataset.max
            clickedFilter["checked"] = event.currentTarget.checked;
            clickedFilter["label"] = event.currentTarget.dataset.label;
            clickedFilter["name"] = event.currentTarget.dataset.name;
            clickedFilter["path"] = event.currentTarget.dataset.path;
            clickedFilter['sortMethod'] = event.currentTarget.dataset.sort;
            event.currentTarget.checked = false;
            event.currentTarget.blur();
        }
        else {
            var clickedFilter = itemRemoved;
        }

        this.pageNum = 1;
        this.from = 0;
        var currentClickedOrderIndex = this.aggregationsData && this.aggregationsData.findIndex((f) => f.key == clickedFilter.parent);
        this.selectedTypeFilter = this.selectedTypeFilter.replace(/^"(.*)"$/, '$1')
        var aggregations = JSON.parse(this.selectedTypeFilter || "[]"); //need to check from where is this coming selectedTypeFilter
        var obj = {
            "childName": clickedFilter.Contentname,
            "level": clickedFilter.level,
        };
        if (clickedFilter.level != 1)
            obj.path = clickedFilter.path || [];
        if (aggregations && !aggregations.length && clickedFilter.Contentname == undefined) {
            aggregations.push({
                "type": clickedFilter.parent,
                "sort": clickedFilter.sortMethod
            })
        }
        else if (aggregations && !aggregations.length && clickedFilter.Contentname.indexOf('merged_') == -1) {
            clickedFilter.parent && (clickedFilter.parent.slice(-7) == '_nested' || clickedFilter.parent.slice(-11) == '_navigation') ?
                aggregations.push({
                    "type": clickedFilter.parent,
                    "filter": [],
                    "children": [obj]
                }) :
                aggregations.push({
                    "type": clickedFilter.parent,
                    "filter": [clickedFilter.Contentname]
                })
        }
        else { //if aggregations exist
            let index = -1;
            aggregations.some(function (facet, i) { if (facet && facet.type == clickedFilter.parent) { index = i; return true; } });
            if (index >= 0) {
                if (clickedFilter.parent.slice(-7) == '_nested' || clickedFilter.parent.slice(-11) == '_navigation') {
                    var childrenArr = aggregations[index].children || [];
                    if (clickedFilter.checked) {
                        childrenArr.forEach(function (filter, i) {
                            if (filter.path && filter.path.indexOf(filter.Contentname) >= 0) {
                                childrenArr[i] = {};
                            }
                        })
                        childrenArr.push(obj);
                        aggregations[index].sort && !aggregations[index].filter ? aggregations[index].filter = [] : null;
                    }
                    else {
                        if (aggregations[index].sort && clickedFilter.Contentname == undefined) {
                            aggregations[index].sort = clickedFilter.sortMethod;
                        } else if (aggregations[index].children && !aggregations[index].sort && clickedFilter.Contentname == undefined) {
                            aggregations[index].sort = clickedFilter.sortMethod;
                        } else {
                            // if (clickedFilter.level == 1) {
                            //     aggregations[index].children = [];
                            //     childrenArr = [];
                            // }
                            // else {
                                var filtersInAggr = childrenArr.filter(function (filter, i) {
                                    if ((clickedFilter.Contentname == filter.childName) || (clickedFilter.path && clickedFilter.path.indexOf(filter.childName) >= 0) || (filter.path && filter.path.indexOf(clickedFilter.Contentname) > -1)) {
                                        childrenArr[i] = {};
                                    }
                                    return Object.keys(childrenArr[i]).length !== 0
                                })
                                filtersInAggr = filtersInAggr.map(function (f) { return f.childName });
                                this.traverseTheTree(this.aggregationsData[currentClickedOrderIndex].values, clickedFilter, clickedFilter.path, filtersInAggr, childrenArr);
                            //  }
                        }
                    }
                    if (clickedFilter.Contentname) {
                        childrenArr = childrenArr.filter(function (value) { if (Object.keys(value).length !== 0) return value; });
                        aggregations[index].children = childrenArr;
                    }
                }
                else if (clickedFilter.Contentname && clickedFilter.Contentname.indexOf('merged_') > -1) {

                    aggregations[index].filter = clickedFilter.checked && (!aggregations[index].filter || !aggregations[index].filter.length) ? [] : aggregations[index].filter;
                    this.mergeFilterClicked(clickedFilter, aggregations[index].filter, this.aggregationsData[currentClickedOrderIndex].values);
                }
                else if (clickedFilter.Contentname && !aggregations[index].filter) {
                    aggregations[index].filter = [clickedFilter.Contentname];
                }
                else {
                    if (aggregations[index].sort && clickedFilter.Contentname == undefined) {
                        aggregations[index].sort = clickedFilter.sortMethod;
                    }
                    else if (aggregations[index].filter && !aggregations[index].sort && clickedFilter.Contentname == undefined) {
                        aggregations[index].sort = clickedFilter.sortMethod;
                    }
                    else if (aggregations[index].filter.indexOf(clickedFilter.Contentname) > -1) {
                        aggregations[index].filter.splice(aggregations[index].filter.indexOf(clickedFilter.Contentname), 1);
                    }
                    else {
                        aggregations[index].filter.push(clickedFilter.Contentname);
                    }
                }
            }
            else {
                if (clickedFilter.Contentname == undefined) {
                    aggregations.push({
                        "type": clickedFilter.parent,
                        "sort": clickedFilter.sortMethod
                    })
                }
                else if (clickedFilter.Contentname.indexOf('merged_') > -1) {
                    var filter = [];
                    this.mergeFilterClicked(clickedFilter, filter, this.aggregationsData[currentClickedOrderIndex].values)
                    aggregations.push({
                        "type": clickedFilter.parent,
                        "filter": filter
                    });
                } else {
                    clickedFilter.parent && (clickedFilter.parent.slice(-7) == '_nested' || clickedFilter.parent.slice(-11) == '_navigation') ?
                        aggregations.push({
                            "type": clickedFilter.parent,
                            "filter": [],
                            "children": [obj]
                        }) :
                        aggregations.push({
                            "type": clickedFilter.parent,
                            "filter": [clickedFilter.Contentname]
                        })
                }
            }
        }
        
        aggregations = aggregations.filter(function (facet) {
            if (facet &&!facet.sort) {
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
        aggregations.map(function (item) {
            if (item && item.type && (item.type === "post_time" || item.type.includes('CreatedDate'))) {
                if (item.filter && item.filter.length > 1) {
                    item.filter.splice(0, 1);
                }
            }
            if (item.children && !item.children.length) {
                delete item.children;
                if (item.filter && !item.filter.length) {
                    delete item.filter
                }
            }
        })

        this.selectedTypeFilter = JSON.stringify(aggregations);
        var currentFilterOrder = this.aggregationsData && this.aggregationsData.find(function (f) { if (f.key == clickedFilter.parent) return f; })
        this.filterOrder = currentFilterOrder.order;
        fireEvent(null, 'getSearchResults', { aggregations: JSON.stringify(aggregations), filterSorting: this.filterSortingLoading, filterChecked: 'filterClicked' });
        
        if (this.searchFacetIndexVal) {
            this.template.querySelector('div[data-index="' + this.searchFacetIndexVal + '"]').classList.add('su__d-none');
            let showmorefacetIcon = this.aggregationsData[this.searchFacetIndexVal].showmorefacetIcon;
            this.template.querySelector('div[data-id="' + showmorefacetIcon + '"]').classList.remove('su__d-none');
            let facetIconId = this.aggregationsData[this.searchFacetIndexVal].facetIconId;
            var searchText = this.template.querySelector('input[name="' + facetIconId + '"]');
            searchText.value = '';
            this.searchFacetIndexVal = '';
        }
    }

    traverseTheTree(childArray, clickedFilter, path, filtersInAggr, childrenArr) {
        for (var i = 0; i < childArray.length; i++) {
            if (path) {
                if (childArray[i] && childArray[i].Contentname && childArray[i].Contentname == path[0]) {
                    if (path.length > 1) {
                        this.traverseTheTree(childArray[i].childArray, clickedFilter, path.slice(1, path.length), filtersInAggr, childrenArr);
                    }
                    childArray[i].childArray.forEach(function (child) {
                        if (clickedFilter.Contentname == child.Contentname) { child.selected == false; }
                        if (clickedFilter.Contentname != child.Contentname
                            && child.selected == true
                            && filtersInAggr.indexOf(child.Contentname) == -1
                            && path.indexOf(child.Contentname) == -1) {
                            childrenArr.push({
                                "childName": child.Contentname,
                                "level": child.level.toString(),
                                "path": child.path
                            });
                        }
                    })
                }
            }
        }
    }

    mergeFilterClicked(clickedFilter, aggrFilter, childArray) {
        childArray.some(function (child) {
            if (child.Contentname == clickedFilter.Contentname) {
                if (child.childArray) {
                    child.childArray.forEach(function (f) {
                        if (clickedFilter.checked) {
                            if (aggrFilter.indexOf(f.Contentname) == -1) {
                                aggrFilter.push(f.Contentname);
                            }
                        }
                        else {
                            if (aggrFilter.indexOf(f.Contentname) > -1) {
                                aggrFilter.splice(aggrFilter.indexOf(f.Contentname), 1);
                            }
                        }
                    })
                }
            }
        })
    }

    clearFilterForSlider(event) {
        this.handleFilterBox(event);
        fireEvent(null, "clearFilterDataEvent", null);
        fireEvent(null, "clearFilterSecEvent", null);
        fireEvent(null, 'clearAdvanceFilters', null);
        fireEvent(null, 'clearAllFilters', null);
    }

    handleFilterBox(event) {
        let showResultBtn = event.target.dataset.id
        if (showResultBtn && showResultBtn === 'showresults') {
            this.goToTopContainerFunc();
        }
        var divblock = this.template.querySelector('[data-id="divblockTest"]');
        if (divblock) {
            this.showFilter = false;
            this.showAllStickyFacets = false;
        }
        fireEvent(null, 'filterClosed', null);
    }

    hideMobileFilterFunc() {
        fireEvent(null, 'hideMobileFilter', null);
    }

    collapseFilters(event) {
        var currentId = event.currentTarget.dataset.id;
        var childId = currentId.split('_icon')[0];
        var divTocollapse = this.template.querySelector(`[data-id="${childId}"]`);
        var closeIcon = this.template.querySelector(`[data-id="${childId + '_toggleIconOn'}"]`);
        var openIcon = this.template.querySelector(`[data-id="${childId + '_toggleIconOff'}"]`);
        //need to add this  // var searchIcon = this.template.querySelector(`[data-id="${'facetIcon-'+facetIcon}"]`)[0].parentElement;//document.getElementsByClassName('facetIcon-'+facetIcon)[0].parentElement;
        if (divTocollapse && divTocollapse.classList.contains('in') && closeIcon && openIcon) {
            openIcon.classList.remove('su__d-block');
            openIcon.classList.add('su__d-none');
            closeIcon.classList.remove('su__d-none');
            closeIcon.classList.add('su__d-block');
            divTocollapse.classList.remove('child-filters-block');
            divTocollapse.classList.remove('in');
            divTocollapse.classList.add('su__d-none');

        } else if (closeIcon && openIcon && divTocollapse) {
            closeIcon.classList.remove('su__d-block');
            closeIcon.classList.add('su__d-none');
            openIcon.classList.remove('su__d-none');
            openIcon.classList.add('su__d-block');
            divTocollapse.classList.add('child-filters-block');
            divTocollapse.classList.add('in');
            divTocollapse.classList.remove('su__d-none');
        }
    }

    filterSortingPopup() {
        this.filtersSortingCheck = true;
    }

    searchFilters(event) {
        var searchFacetIndex = event.currentTarget.dataset.index;
        this.facetdrop = "su__d-none"
        let showmorefacetIcon = this.aggregationsData[searchFacetIndex].showmorefacetIcon;
        if (this.searchFacetIndexVal != '' && this.searchFacetIndexVal != searchFacetIndex) {
            let searchFacetIndexData = this.template.querySelector('div[data-index="' + this.searchFacetIndexVal + '"]');
            if(searchFacetIndexData){
                searchFacetIndexData.classList.add('su__d-none')
            }
            let showmorefacetIconOld = this.aggregationsData[this.searchFacetIndexVal].showmorefacetIcon;
            let  showmorefacetIconOldClass = this.template.querySelector('div[data-id="' + showmorefacetIconOld + '"]');
            if(showmorefacetIconOldClass){
                this.template.querySelector('div[data-id="' + showmorefacetIconOld + '"]').classList.remove('su__d-none');
            }
            let searchFacetClass = this.aggregationsData[this.searchFacetIndexVal].facetFilterClass &&  this.aggregationsData[this.searchFacetIndexVal].facetFilterClass.split(' ')[0];
            let searchFacetInput = this.template.querySelector('div[data-id="searchFacetDiv-' + searchFacetClass + '"]');
            if(searchFacetInput && searchFacetInput.classList){
                searchFacetInput.classList.add('su__d-none');
            }
        }
        this.searchFacetIndexVal = searchFacetIndex;
        let searchFacetClass = this.aggregationsData[searchFacetIndex].facetFilterClass && this.aggregationsData[searchFacetIndex].facetFilterClass.split(' ')[0];
        if (searchFacetClass) {
            let searchFacetInput = this.template.querySelector('div[data-id="searchFacetDiv-' + searchFacetClass + '"]');
            if(searchFacetInput && searchFacetInput.classList){
                searchFacetInput.classList.remove('su__d-none');
            }
            let searchFacetIndexData = this.template.querySelector('div[data-index="' + searchFacetIndex + '"]')
            if(searchFacetIndexData && searchFacetIndex && searchFacetIndexData.classList){
                searchFacetIndexData.classList.remove('su__d-none');
            }
            // this.template.querySelector('div[data-index="' + searchFacetIndex + '"]').classList.remove('su__d-none');
        }
        this.template.querySelector('div[data-id="' + showmorefacetIcon + '"]').classList.add('su__d-none');
    }

    searchFilterController(event) {
        event.preventDefault();
        var key = event.target.parentNode.dataset.id.split("-")[0];
        var searchStringFilter = event.target.parentNode.children[1].value;
        this.searchFilterSuggestions(key, searchStringFilter, event);
    }

    searchFilterSuggestions(key, searchStringFilter, event) {
        var self = this;
        var pagingAggregation;
        var filterData = this.selectedTypeFilter;
        try {
            var aggregationsData = JSON.parse(JSON.stringify(this.aggregationsData));
        } catch (error) {
            console.log('[error]', error);
        }
        var dropdownField = this.template.querySelector('div[data-id="collapseExample-' + key + '"]');
        pagingAggregation = { "field": key, "keyword": searchStringFilter };
        this.pagingAggregation = pagingAggregation;
        let aggregationCheck = [];
        let searchKeywords = [pagingAggregation.keyword];
        const found = this.mergedArrayReceived ? this.mergedArrayReceived.filter(function (f) { return f.facetName === key && f.filterNewName.toLowerCase().indexOf(pagingAggregation.keyword.toLowerCase()) > -1 }) : [];
        let foundArray = [];
        found ? found.filter(function (f) { foundArray = foundArray.concat(f.filterList); return; }) : [];
        searchKeywords = searchKeywords.concat(foundArray);
        pagingAggregation.merged = found && found.length ? true : false;
        if (pagingAggregation.merged) {
            pagingAggregation.mergedKeywords = searchKeywords;
        }
        var data = JSON.stringify({
            ...this.searchQuery,
            "sid": window._gr_utility_functions.getCookie("_gz_taid"),
            "pagingAggregation": this.pagingAggregation,
            "mergeSources": false,
            "versionResults": false
        });

        if (searchStringFilter) {
            var xmlHttp = new XMLHttpRequest();
            var url = this.endPoint + "/search/SUSearchResults";
            xmlHttp.withCredentials = true;
            xmlHttp.open("POST", url, true);
            xmlHttp.setRequestHeader("Accept", "application/json");
            xmlHttp.setRequestHeader('Authorization', 'bearer ' + this.bearer);
            xmlHttp.setRequestHeader('Content-Type', 'application/json');

            xmlHttp.send(data);
            xmlHttp.onreadystatechange = function () {
                if (xmlHttp.readyState === 4) {
                    if (xmlHttp.status === 200) {
                        var result = JSON.parse(xmlHttp.response);
                        if (result.statusCode != 402) {
                            if (result.statusCode == 200) {
                                found.forEach(function (f) {
                                    mergeFilters(f, result.aggregationsArray, true, self);
                                })
                                if (result.aggregationsArray && result.aggregationsArray.length) {
                                    result.aggregationsArray.forEach(function (filter, index) {
                                        if (filter.key === key) {
                                            function altFind(arr, callback) {
                                                for (var i = 0; i < arr.length; i++) {
                                                    var match = callback(arr[i]);
                                                    if (match) {
                                                        return arr[i];
                                                    }
                                                }
                                            }

                                            let indexValue = aggregationsData.findIndex((obj)=> obj.key === key );

                                            let aggregationsSent = altFind(filterData, function (f) {
                                                return f.type == key;
                                            })

                                            if (filter.values && filter.values.length > 0) {
                                                filter.values = filter.values.filter(function (u) {
                                                    const facet_Regex = new RegExp(".*" + searchStringFilter + ".*", 'gi');
                                                    return facet_Regex.test(u.Contentname)
                                                });
                                                aggregationsData[indexValue].values.some(function (value) {
                                                    if (value.selected === true) {
                                                        aggregationCheck.push(value.Contentname);
                                                    }
                                                    if (value.childArray) {
                                                        if (value.childArray.length > 0) {
                                                            value.childArray.forEach(function (f, i) {
                                                                if (f.selected === true) {
                                                                    aggregationCheck.push(f.Contentname);
                                                                }
                                                            })
                                                        }
                                                    }
                                                })

                                                filter.values.forEach(function (filter) {
                                                    aggregationCheck.some(function (value) {
                                                        if (filter.Contentname === value) {
                                                            filter.selected = true;
                                                        }
                                                    })
                                                    filter.ContentnameFrontend = self.decodeHTMLString(filter.Contentname);
                                                    filter.selected = aggregationsSent && aggregationsSent.filter && aggregationsSent.filter.indexOf(filter.Contentname) > -1 ? true : filter.selected;
                                                    if (filter.childArray && aggregationsSent && aggregationsSent.filter)
                                                        checkSelected(filter.childArray, aggregationsSent);
                                                    filter.filterSuggestItemId = filter.parent + '_checkType_facet' + filter.Contentname;
                                                });
                                                aggregationsData[indexValue].filterSuggestions = [];
                                                aggregationsData[indexValue].filterSuggestions = filter.values;
                                                if (dropdownField && dropdownField.parentElement && dropdownField.parentElement.classList) {
                                                    dropdownField.parentElement.classList.add('su__filter-suggest');
                                                }
                                            } else {
                                                aggregationsData[indexValue].filterSuggestions = [];
                                                dropdownField && dropdownField.parentElement && dropdownField.parentElement.classList.remove('su__filter-suggest');
                                            }
                                            aggregationsData[indexValue].suggestionLength = aggregationsData[indexValue].filterSuggestions && aggregationsData[indexValue].filterSuggestions.length > 0
                                                ? true
                                                : false;
                                            if ( aggregationsData[indexValue] && aggregationsData[indexValue].suggestionLength) {
                                                self.facetdrop = "su__search-facet-drop";
                                                aggregationsData[indexValue].filterSuggestClass = 'su__search-facet-input su__loading-view'
                                            } else {
                                                self.facetdrop = "su__d-none"
                                                aggregationsData[indexValue].filterSuggestClass = 'su__search-facet-input-not su__loading-view'

                                            }

                                            self.aggregationsData = [];
                                            self.aggregationsData = aggregationsData;
                                        }
                                    });
                                }
                                else {
                                    aggregationsData.forEach(function (filter, i) {
                                        filter.filterSuggestions = [];
                                    });
                                }
                                self.aggregationsData = [];
                                self.aggregationsData = aggregationsData;
                            }
                        } else {
                            if (result.statusCode == 402) {
                                location.reload();
                            }
                        }
                    }
                }
            }
        }
    }

    checkSelected(childArray, aggregationsSent) {
        childArray.forEach(function (f) {
            f.selected = aggregationsSent.filter.indexOf(f.Contentname) > -1 ? true : false;
            if (f.childArray) checkSelected(f.childArray, aggregationsSent);
            return
        })
    }

    decodeHTMLString(encodedStr) {
        var parser = new DOMParser;
        var dom = parser.parseFromString(
            '<!doctype html><body>' + encodedStr,
            'text/html');
        return (dom.body.textContent);
    }

    mouseleft(event) {
        this.facetdrop = "su__d-none"
        let facetFilteredData = event.target.dataset.index;
        this.aggregationsData[facetFilteredData].filterSuggestions = [];
    }

    filterClose(event) {
        var searchFacetClass = event.target.classList.value.split(' ').filter(e => e.indexOf("facetIcon-") > -1)[0];
        var searchFacetInput = this.template.querySelector('div[data-id="searchFacetDiv-' + searchFacetClass + '"]');
        var searchText = this.template.querySelector('input[name="searchFacetDiv-' + searchFacetClass + '"]');
        var showMore = this.template.querySelector('div[data-id="show-more-' + searchFacetClass + '"]');
        var searchIcon = this.template.querySelector('lightning-button-icon[data-id="facetSearchIcon-' + searchFacetClass + '"]');

        var aggregationsDataBackup = this.aggregationsData;
        var filterSelect = searchFacetClass.split('-')[1];
        if (showMore) {
            showMore.classList.add('su__show-more');
            showMore.classList.toggle('su__d-none');
        }
        if (searchFacetInput) {
            searchFacetInput.classList.remove('su__flex-vcenter');
            searchFacetInput.classList.toggle('su__d-none');
        }

        searchText.value = '';
        if (searchIcon) {
            searchIcon.classList.add('su__d-block');
            searchIcon.classList.toggle('su__d-none');
        }
        if (aggregationsDataBackup && aggregationsDataBackup.length) {
            aggregationsDataBackup.forEach(function (filter) {
                if (filter.key === filterSelect) {
                    filter.filterSuggestions ? delete filter.filterSuggestions : '';
                    filter.filterSuggest ? delete filter.filterSuggest : '';
                }
            });
            this.aggregationsData = [];
            this.aggregationsData = aggregationsDataBackup;
        }
        if (this.template.querySelector('div[data-index="' + this.searchFacetIndexVal + '"]')) {
            this.template.querySelector('div[data-index="' + this.searchFacetIndexVal + '"]').classList.add('su__d-none');
        }
        this.searchFacetIndexVal = '';
    }
}