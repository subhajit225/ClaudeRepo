import { LightningElement, api, track } from 'lwc';
import { registerListener, unregisterListener, fireEvent } from 'c/authsupubsub_b6b3_13';
import { NavigationMixin } from 'lightning/navigation';
export default class SU_AuthSearchDataSection extends NavigationMixin(LightningElement) {

    @api failText;
    @api emptySearchString;
    @api totalResults;
    @api gptContext;
    @api gptLinks;
    @api pageNum;
    @api gptActive
    @api endPointPagination;
    @api showPagination;
    @api  paginationList;
    @api resultsectioncontainer;
    @api latesturlval;
    @api counter;
    @api aggregationsdata;
    @api totalPages;
    @api searchresultime;
    @api showAdvertisement;
    firstStickyLabel;
    filterValueOne = [];
    firstStickyLabel1 = false;
    @api totalresults;
    showfirstFacet = false;
    @api pagenum;
    @track clearAllClass = "su__clear-filters-btn  su__cursor  font-12 su__font-bold su__p-0  su__loading-view su__color-lblue"
    eventSortType = '';
    previousIndexVal = '';
    @api knowledgeGraph;
    @api knowledgeGraphMetaGraph;
    @api knowledgeGraphRelatedTiles;
    @api metaGraph;
    @api relatedTiles;
    @api knowledgeGraphResponseRecorded;
    @api featuredResponseRecorded;
    @api endPoint;
    @api hasWildcardSearch;
    @api uid;
    @api searchString;
    @api searchConversionFeedback;
    @api currentUserEmail;
    @track activeView = 'listView';
    @api listview;
    @track result;
    advFilterDatavalues = [];
    @api recordId;
    requiredStickyFacet = [];
    @api showFilter1 = false;
    @api previewSrcVal = '';
    @api typeofContentForPreview = '';
    @api previewSourceLabel = '';
    showAllFilters;
    showClearFiltersButton;
    showAllButton = false;
    disableButton = true;
    listofStickyFacet = [];
    sourceArr = [{
        "key": "all_Content",
        "values": "All Content"
    }];
    showArrowIcon = false;
    listofStickyFacet1 = [];
    listofStickyFacetType = [];
    @track active;
    @track tabSelected;
    ffirstStickyLabel = [];
    prevIndex = '';
    @api correctspell;
    @api index;
    @track responselistdata = [];
    @api similiarSearchData;
    gridElement = "width:100%;border-radius: 5px; margin-left: 1px; margin-top: 1px; margin-right: 1px;";
    gridElementAlignment = 'display:flex;align-items:center';
    gridElementMetaData = 'su__meta-date su__word-break su__pt-1 su__loading-view';
    @api
    set responseListData(value) {
        if (value) {
            this.responselistdata = JSON.parse(JSON.stringify(value));
        }
    };
    get responseListData() {
        return this.responselistdata;
    }
    @api loading = '';
    viewAllStickyButton = false;
    @api selectedStickyFilter;
    @api summaryCollapsible;
    @api mergedresults;
    @track stickyFacets;
    @api sortByCheck;
    @track DataLoaded = false;
    @api translationObject;
    @api tabsfilter;
    @api similarSearches;
    @track recommendationsEnable;
    @api searchQueryData;
    @api featureSnippet;
    @api featureSnippetData;
    @api hideTitle;
    @api hideUrl;
    @api hideSummary;
    @api hideMetadata;
    @api hideIcon;
    @api hideTag;
    @api noResultFound;
    @api pageSize;
    titleClickedValue = '';
    @api searchFeedbackResponseData;
    @api pageRatingCustomizationData;
    @api pageRatingInstanceData;
    @api isSearchConversion;
    showConversionButton = false;
    @api showHideDidYouMean
    @api bearer;
    @api isDeviceMobile;

    @api
    set getRecommendationsEnable(v){
        this.recommendationsEnable = v;
    }
    get getRecommendationsEnable(){
        return this.recommendationsEnable;
    }
    get showClearFiltersButton1() {
        return (this.selectedStickyFilter && this.selectedStickyFilter.length) || !this.totalresults ? true : false;
    }

    get showhideTotalResultsText(){
        return (this.showHideDidYouMean || this.hasWildcardSearch)
    }

    get showRecommendationDivClass() {
        if (this.knowledgeGraph) {
            return '';
        }
        return this.recommendationsEnable ? 'slds-grid slds-wrap su__recommended-articles-width' : '';
    }

    get dataSearchedResultWidthClass() {
        return this.knowledgeGraph ? 'SearchResultWidthClass' : '';
    }

    get searchedResultTilesWidth() {
        return this.knowledgeGraph ? 'dataVal resultDataSection-MinHeight searchedResultTilesWidth' : 'dataVal resultDataSection-MinHeight';
    }

    get recommendAndSimiliarSearchFlex() {
        return this.knowledgeGraph ? '' : 'su__Recommended_flex';
    }

    // Code Added for preview End
    clearFilterForSlider1(event) {
        fireEvent(null, 'clearAllFilters', null);
        fireEvent(null, 'clearAdvanceFilters', null);
        fireEvent(null, 'tabClicked', event);
    }
    tabClicked(event) {
        fireEvent(null, 'tabClicked', event);
    }

    connectedCallback() {
        this.searchFeedbackResponseData = JSON.parse(JSON.stringify(this.searchFeedbackResponseData))
        registerListener("checkType", this.checkDataFromSearchSection, this);
        registerListener("showclearfilterbtn", this.searchBtn, this);
        registerListener("advsearchstickyfltr", this.stickyFilterData, this);
        registerListener("removeAllPreviousFacets", this.removeAllFacets, this);
        //registerListener("showFilterData", this.showFilterDataMethod, this);
        registerListener("sendstickytodatasection", this.sendStickyFromAdvSearch, this);
        registerListener("showclearfilter", this.showClearFilterValue, this);
        registerListener("sendtodatasection", this.dataFromFilterSection, this);
        registerListener("clearFilterDataEvent", this.handleClearFilterDataEvent, this);
        registerListener("dataSectionView", this.dataSectionView, this);
    }

    disconnectedCallback() {
        unregisterListener("checkType", this.checkDataFromSearchSection, this);
        unregisterListener("showclearfilterbtn", this.searchBtn, this);
        unregisterListener("advsearchstickyfltr", this.stickyFilterData, this);
        unregisterListener("removeAllPreviousFacets", this.removeAllFacets, this);
        //unregisterListener("showFilterData", this.showFilterDataMethod, this);
        unregisterListener("sendstickytodatasection", this.sendStickyFromAdvSearch, this);
        unregisterListener("showclearfilter", this.showClearFilterValue, this);
        unregisterListener("sendtodatasection", this.dataFromFilterSection, this);
        unregisterListener("clearFilterDataEvent", this.handleClearFilterDataEvent, this);
        unregisterListener("dataSectionView", this.dataSectionView, this);
    }

    /**
     * This function executes when user clicks on three dots svg and listening the event in search feedback component
     * @param event contaning information of clicked search url
     */

    decodeHTMLEntities(input) {
        const entities = {
            '&amp;': '&',
            '&lt;': '<',
            '&gt;': '>',
            '&quot;': '"',
            '&apos;': "'",
            '&#39;': "'",
        };

        // Use a regular expression to match and replace all entities in the input
        let decodedString = input.replace(/(&[a-z]+;)/g, (match) => {
            return entities[match] || match;
        });

        // Remove backslashes from the decoded string
        decodedString = decodedString.replace(/\\/g, '');

        return decodedString;
    }

    feedbackOnResult(event) {
        const { href, title } = event.currentTarget.dataset
        let removedBackSlash = this.decodeHTMLEntities(title);
        const eventData = {
            href: href,
            title: removedBackSlash,
            titleClickedValue: this.titleClickedValue // Include the additional property
        };
        fireEvent(null, "openConversionModal", eventData);
    }
    /**
     * This function executes when user clicks on search results provided search conversion feedback is enabled from admin
     * @param event : event contains details of clicked search result index
     */
    getSelectedTitle(event) {
        if (this.searchConversionFeedback === true) {
            const id = event.currentTarget.dataset.rating;
            this.responselistdata = this.responselistdata.map((item, index) => {
                if (index === Number(id)) {
                    item.isConversionSelected = true; // Update the property directly
                    this.titleClickedValue = Number(id);
                }
                return item;
            });
            this.showConversionButton = true;
        }
    }


    get activeScViewClass() {
        if (this.activeView === 'listView') {
            return 'su__d-flex  su__flex-wrap su__mobile-view-class '
        } else if (this.activeView === 'gridView') {
            return 'su__d-flex su__flex-wrap su__grid-contentView su__mobile-view-class-grid'
        }
    }
    get previewClassGrid(){
        if (this.activeView === 'listView') {
            return 'su__d-none'
        } else if (this.activeView === 'gridView') {
            return ''
        }
    }
    get previewClassList(){
        if (this.activeView === 'listView') {
            return 'su__pt-4px'
        } else if (this.activeView === 'gridView') {
            return 'su__d-none'
        }
    }
    get mergeVersionClassGrid(){
        if (this.activeView === 'listView') {
            return 'su__d-none'
        } else if (this.activeView === 'gridView') {
            return 'su__ml-auto'
        }
    }
    get mergeVersionClassList(){
        if (this.activeView === 'listView') {
            return ''
        } else if (this.activeView === 'gridView') {
            return 'su__d-none'
        }
    }
    
    get mainClass(){
        if (this.activeView === 'listView') {
            return "su__d-flex su__flex-vcenter su__ml-1 su__space_between su__mr-list-rtl"
        } else if (this.activeView === 'gridView') {
            return "su__d-flex su_new-flex su__flex-vcenter"
        }
    }


    dataSectionView(view) {
        this.gridElement = view.mainDivClass;
        this.gridElementAlignment = view.divtextAlignment;
        this.gridElementMetaData = view.gridElementMetaData;
        this.activeView = view.suActiveView;
    }

    //clear filter
    handleClearFilterDataEvent(event) {
        this.listofStickyFacet = [];
        this.listofStickyFacet1 = [];
        var selectedTab = 'all_Content';
        this.sourceArr.splice(0, 1, {
            "key": "all_Content",
            "values": "All Content"
        });

        if (this.previousIndexVal != '' && this.template.querySelector(`[data-name=' ${this.previousIndexVal}']`)) {
            this.template.querySelector(`[data-name=' ${this.previousIndexVal}']`).classList.remove("active-type");
            this.previousIndexVal = selectedTab;
        }
        if (this.template.querySelector(`[data-name='${selectedTab}']`))
            this.template.querySelector(`[data-name='${selectedTab}']`).classList.add("active-type")
        fireEvent(null, 'clearStickyFilter', null);
    }

    dataFromFilterSection(data) {
        this.listofStickyFacet = [];
        this.listofStickyFacet1 = [];
        this.listofStickyFacet = data.arr_StickyData;
        this.listofStickyFacetType = data.arr_StickyData1;
        this.listofStickyFacet1 = data.arr_StickyData;

    }

    showClearFilterValue() {
        this.showFilter1 = true;
    }

    sendStickyFromAdvSearch(data) {
        for (let i = 0; i < data.length; i++) {
            for (let j = 0; j < this.listofStickyFacet.length; j++) {
                if (this.listofStickyFacet[j].label == data[i].label) {
                    this.listofStickyFacet[j].values = data[i].values;
                    break;
                }
            }
            var check = false;
            for (let k = 0; k < this.listofStickyFacet.length; k++) {
                if (this.listofStickyFacet[k].label == data[i].label) {
                    check = true;
                    break;
                }
            }
            if (!check) {
                this.listofStickyFacet.push(data[i]);
            }
        }

        this.listofStickyFacet1 = [];
        this.listofStickyFacet1.push(this.listofStickyFacet[0]);


    }
    // showFilterDataMethod(data) {
    //     this.showFilter1 = data.showFilter,
    //         this.showFilter1 = true;
    //     this.selectedStickyFilter1 = data.
    //     this.requiredStickyFacet = (this.selectedStickyFilter1);
    //     this.filterValueOne.push(data[0]);
    // }
    stickyFilterData(data) {
        this.ffirstStickyLabel = [];
        this.firstStickyLabel = data;
        this.ffirstStickyLabel.push(data[0]);
        if (this.firstStickyLabel.length > 0) {
            this.firstStickyLabel1 = true;
        }
        if (data.length > 1) {
            this.viewAll = true;
        }
        this.showAllFilters = data;

    }
    searchBtn(d) {
        this.showClearFiltersButton = d;
    }

    checkDataFromSearchSection(event) {
        this.eventSortType = event;
    }

    renderedCallback() {
        this.DataLoaded = true;
        var selectedTab = '';
        if (this.sourceArr) {
            selectedTab = this.sourceArr[0].key;
        } else {
            selectedTab = 'all_Content';
        }
        if (this.aggregationsdata && this.aggregationsdata.length) {
            if (this.aggregationsdata && this.aggregationsdata.length && this.aggregationsdata[0].values && this.aggregationsdata[0].values.find(f => f.selected)) {
                var selectedTabObj = this.aggregationsdata[0].values.find(f => f.selected);
                selectedTab = selectedTabObj.Contentname;
            } else selectedTab = 'all_Content';
            if (this.previousIndexVal && this.template.querySelector(`[data-name='${this.previousIndexVal}']`))
                this.template.querySelector(`[data-name='${this.previousIndexVal}']`).classList.remove("active-type");
            this.previousIndexVal = selectedTab;
            if (this.template.querySelector(`[data-name='${selectedTab}']`)) {
                this.template.querySelector(`[data-name='${selectedTab}']`).classList.add("active-type")
            }
        }
        if (this.selectedStickyFilter && this.selectedStickyFilter.length) {
            this.stickyFacets = true;

        } else {
            this.stickyFacets = false;


        }

    }
    openPreviewModal(event) {
        fireEvent(null, 'openPreviewModal', event)
    }

    // This method is used to toggle show and hide of filter data
    handleInsideFilters(event) {
        this.index = event.currentTarget.dataset.rank;
        if (this.prevIndex != this.index) {
            this.responselistdata.forEach((value) => {
                if (value && value.showMR) {
                    value.showMR = false;
                    value.showMRClass = 'version-field';
                }
            })
            this.prevIndex = this.index;
        }
        this.responselistdata[this.index].showMR = !this.responselistdata[this.index].showMR;
        if (this.responselistdata[this.index].showMRClass != 'version-field su__active-Filter-color') {
            this.responselistdata[this.index].showMRClass = 'version-field su__active-Filter-color';
        } else {
            this.responselistdata[this.index].showMRClass = 'version-field';
        }
    }

    mergeResultOutsideClick() {
        this.responselistdata.forEach((value) => {
            if (value && value.showMR) {
                value.showMR = false;
                value.showMRClass = 'version-field';
            }
        })
    }


    removeAllFacets() {
        this.firstStickyLabel1 = false;
    }

    removeFromSearch(e) {
        var newArr = [];
        for (let i = 0; i < this.advFilterDatavalues.length; i++) {
            if (this.advFilterDatavalues[i].label == e.target.dataset.name) {
                continue;
            }
            newArr.push(this.advFilterDatavalues[i]);
        }
        if (newArr.length == 0) {
            this.firstStickyLabel1 = false;
            this.showClearFiltersButton = false;
            this.show = false;
            this.showFilter1 = false;
            this.advFilterDatavalues = [];
            this.showfirstFacet = false;
        }
        fireEvent(null, 'removeadvsearchfilter', newArr)
    }

    getAllStickyFacets() {
        fireEvent(null, 'viewAllStickyButton', { show: this.viewAllStickyButton });
        let message = "header";
        fireEvent(null, 'headerSUData', message);
    }
    runScriptMethod(e) {
        fireEvent(null, 'trackAnalytics', {
            type: 'conversion', objToSend: {
                index: e.currentTarget.dataset.index,
                type: e.currentTarget.dataset.type,
                id: e.currentTarget.dataset.recordid,
                rank: parseInt(e.currentTarget.dataset.rank) + 1,
                convUrl: e.currentTarget.dataset.url,
                convSub: e.currentTarget.dataset.sub || e.currentTarget.dataset.url,
                autoTuned: e.currentTarget.dataset.autotuned ? e.currentTarget.dataset.autotuned : false,
                sc_analytics_fields: e.currentTarget.dataset.track?e.currentTarget.dataset.track:[]
            }
        });
    }
    collapseSummary(event) {
        let collapse = event.target.dataset.collapse;
        let index = event.target.dataset.index;

        this.responselistdata[index].showLess = parseInt(collapse) ? false : true;
        if (this.responselistdata[index].showLess) {
            this.responselistdata[index].showMore = false;
        }
        this.responselistdata[index].showMore = parseInt(collapse) ? true : false;
        if (this.responselistdata[index].showMore) {
            this.responselistdata[index].showLess = false;
        }
    }

    handleMouseLeaveMetaData(event) {
        if (this.template.querySelector(`[data-id='${event.target.dataset.id}']`)) {
            this.template.querySelector(`[data-id='${event.target.dataset.id}']`).classList.remove('su__metaData-block');
        }
    }

    handleMouseEnterMetaData(event) {
        if (this.template.querySelector(`[data-id='${event.target.dataset.id}']`)) {
            this.template.querySelector(`[data-id='${event.target.dataset.id}']`).classList.add('su__metaData-block');
        }
    }
}