import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { registerListener, unregisterAllListeners,unregisterListener, fireEvent, mergeFilters, updateTranslation, translationObject, scriptsLoaded, getCommunitySettings,getURLParameter } from 'c/authsupubsub_b6b3_13';

export default class SU_AuthSearchClientLWCContainer extends NavigationMixin(LightningElement) {
    advSearchFilter = [];
    mergeResults;
    @api failText;
    @api emptySearchString;
    @track gptLinks = [];
    @track gptActive = false;
    @track visibilityCitations;
    @track titleToShow;
    @track smartFacetsAdmin;
    @track smartFacets = true;
    @track isAutoLearning;
    @track smartAggregations = [];
    @track selectedTypeFilterForSmart;
    @track mergeSourcesTypeIndex;
    @track showModal = false;
    @track sourceFacet = true;
    @track currentLanguageSelected = 'English'
    @track defaultLang = 'en';
    @track showPagination;
    @track endPointPagination;
    @track tabsFilter;
    @track goToTopContainer;
    @track resultTime;
    @api pageSize;
    @api searchString;
    @api noResultsMsg;
    @api allAreHidden;
    @api collapseSearchFilters;
    @api showContentSourceTab;
    @api displayListView;
    @api collapsSummary;
    @track pageNum = 1;
    @api multiVersion = false;
    defaultlanguage;
    @track searchQuery;
    @track endPoint = '';
    @track bearer = '';
    suResultsLoader = false;
    @track currentCommunityURL;
    customSettingErrorMessage = '';
    @track commBaseURL;
    customSettingsFilled;
    selectedTypeFilter = [];
    @track toggleDisplayKeys = [{ 'key': 'Title', 'hideEye': false }, { 'key': 'Summary', 'hideEye': false }, { 'key': 'Url', 'hideEye': false }, { 'key': 'Metadata', 'hideEye': false }, { 'key': 'Icon', 'hideEye': false }, { 'key': 'Tag', 'hideEye': false }];;
    @track filterToRight;
    @track defaultTab = 'all';
    @track filterValue;
    @track hiddenKeys;
    @track setFlag;
    @track sortByCheck = '_score';
    @track exactPhrase = '';
    @track withOneOrMore = '';
    @track withoutTheWords = '';
    withWildcardSearch = '';
    @track sessionToggleValue;
    @track refresh;
    @track defaultPageSize = 10;
    counter = 1;
    @track buttonHovered;
    @track tabSelected;
    @track pageSizeAdvFiltr = 10;
    @track advanceSearchEnabled;
    @track filterSortingLoading;
    @track loadingResult;
    @track filterOrder;
    @track originalAggregationsData;
    @api aggregationsData;
    @track currentClickedOrder;
    @track bookmark_list = false;
    @track viewSavePopup;
    @track viewConfirmPopup;
    @track preview;
    @track contentTag;
    @track correctspell;
    @track showSummary;
    @track mergedArray;
    @track add_bookmark;
    @track hasWildcardSearch;
    @api bookmarkSearches;
    @track disableButton;
    @track save_bookmark;
    @track bookmarkName;
    @track responseListData = [];
    @track similiarSearchData = [];
    responseListDataBackup = [];
    @track listview;
    @track hideIcon;
    @track resultSectionContainer;
    @track showLanguageDropdown = false;
    @track showViewedResults = 'su__h-100';
    @track translationObj = {};
    @track selectedLanguages;
    @track previewSource;
    @track previewTitle;
    @track previewLabel;
    @track showAdvertisement = false;
    @track isModalOpen = false;
    @track noBookmarkSaved = false;
    @track getRecommendationsEnable;
    @track showClearFiltersButton = false;
    @track selectedStickyFilter = [];
    @track totalPages;
    @track allContentHideFacet = false;
    summaryCollapsible = false;
    hiddenFacet = false;
    maxLength = 100;
    hideFacetsValues = {};
    @track languageEnabled = 0;
    @track urlOpensInNewTab;
    @api setArray;
    searchResultTime;
    @track paginationList;
    showPageSize = false;
    @track showPageClass;
    result = {};
    @track activeTabIndex;
    activeTab = 'all';
    @track tabIndex = false;
    @track viewAll = false;
    @track showFilter = false;
    @api firstStickyLabel = [];
    @track fullWidth = false;
    @track resizeclass = 'su__d-block';
    @track resizeclassFilter = 'su__d-block su__w-25 ';
    value = 'SortByRelevance';
    @api index;
    active = 'all'
    @api activeFilter;
    @api aggData;
    pagingAggregation;
    @track key;
    @track searchFilterString;
    @track suggestionLength = false
    @track bookmark_clicked = false;
    @track bookmark_queryPassed;
    @track isBookmarkExist = false;
    @track showBookMark = false;
    @api gridDisplay = false;
    @api langToast;
    @track showButtonsDiv = false;
    @api noResultMsg;
    currentUserEmail;
    loading;
    checkHere = false;
    advancedSearchSelected = false;
    @track smartAggregationsBackup;
    onFilterButtonClick = true;
    isFreshSearch = -1;
    resultCountReturned;
    hideDataSection = false;
    @api mergeResultHits;
    @track isWildCardEnabled;
    maincontainerwidth;
    firstLoad = true;
    searchFeedbackEnabled = false;
    searchConversionFeedback = false;
    pageRatingFeedback = false;
    @api previewModalVal = false;
    @api previewSrcVal = '';
    @api typeofContentForPreview = '';
    @api previewSourceLabel = '';
    translationObject;
    @api latestUrlVal = '';
    @track similarSearches = false;
    @track searchQueryData;
    @track noResultFound = false;
    @track knowledgeGraph = false;
    @track knowledgeGraphMetaGraph = false;
    @track knowledgeGraphRelatedTiles = false;
    @track metaGraph = [];
    @track relatedTiles = [];
    @track knowledgeGraphResponseRecorded = false;
    @track featureSnippet;
    @track featureSnippetData;
    @track featuredResponseRecorded = false;
    @track hideTitle = false;
    @track hideUrl = false;
    @track hideSummary = false;
    @track hideMetadata = false;
    @track hideIcon = false;
    @track hideTag = false
    @track hiddenKeyArray = [];
    @api activelistview;
    @track autoSuggestionActive = false;
    @track showMobileFilterSection = false;
    @track showScroll = false;
    // feedback data variables 
    pageRatingInstanceData = '';
    pageRatingCustomizationData = '';
    searchFeedbackResponseData = '';
    isSearchFeedback = false;
    isPageRating = false;
    isSearchConversion = false;
    feedbackPosition = 'Center';
    userTypeCheck = '';
    showFeedbackModal = false;
    isSubmitButtonActive = true;
    showCitationModal = false;
    posXCitationModal;
    posYCitationModal;
    citationUrl = '';
    isDeviceMobile;
    isDeviceIpad;
    isDeviceDesktop;
    @track diamondPositionX;
    @track diamondPositionY;
    @api noSearchResultFoundMsg;
    @api defaultFilterCollapse;
    @track clearAllClass = "su__clear-filters-btn su__cursor  font-12 su__font-bold su__mb-2 su__pl-4  su__loading-view su__color-lblue"


    errorCallback(error, stack) {
        this.loading = '';
        console.log("[error], [stack]", error, stack);
    }

    get eventClass() {
        return 'su__searchUnifyContainer su__h-100 ';
    }

    get loadingState(){
        return this.loading === 'su__loading'
    }
    
    get showClearFiltersButton1() {
        return ((this.selectedStickyFilter && this.selectedStickyFilter.length) ||  this.selectedTypeFilter != '[]' && this.selectedTypeFilter != "" )  ? true : false;
        
    }

    get dataSectionClass(){
        return this.fullWidth ?  'dataSectionClassWithoutFilter' : 'dataSectionClass';
    }

    renderedCallback() {
        window.addEventListener('resize', this.resizeCheck.bind(this));
        this.resizeCheck();
        this.sessionToggleValue = window.sessionStorage.getItem('sessionToggle');
        let suContainer = this.template.querySelector('div.su__searchUnifyContainer');
        if (this.defaultlanguage == 'ar') {
            suContainer.classList.add("su__rtl");
        } else {
            suContainer.classList.remove("su__rtl");
        }
        if (this.sessionToggleValue === '1' || this.sessionToggleValue === 'true') {
            this.isWildCardEnabled = true;
            this.hasWildcardSearch = true
        } else {
            this.isWildCardEnabled = false;
            this.hasWildcardSearch = false

        }
        if (this.totalResults > 10) {
            this.showPagination = true
        } else {
            this.showPagination = false
        }

        if (this.firstLoad && this.template.querySelector('div.su__searchUnifyContainer') && this.template.querySelector('div.su__searchUnifyContainer').clientWidth > 0) {
            this.firstLoad = false;
        }
        this.goToTopContainer = this.template.querySelector('[data-id="searchUnifyContainer"]');
        if (this.template.querySelector('[data-id="searchUnifyContainerResultSection"]')) {
            this.resultSectionContainer = this.template.querySelector('[data-id="searchUnifyContainerResultSection"]');
        }
        this.hiddenKeys = this.toggleDisplayKeys;
    }
    resizeCheck = () => {
        clearTimeout(this.timeout);
        this.timeout = setTimeout(() => {
            this.mobileViewFunc();
        }, 10);
    }
    mobileViewFunc() {
        let e = this.template.querySelector('div.su__searchUnifyContainer');
        let maincontainerwidth;
        if (e) {
            maincontainerwidth = e.clientWidth;
        }
        if (maincontainerwidth && maincontainerwidth < 600) {
            fireEvent(null, 'activemobileview', true);
        }
    }
    fullWidthResults = () => {
        try{
            let filterAggData = this.aggregationsData && JSON.parse(JSON.stringify(this.aggregationsData.slice(1)));
            var checkHideShow;
            filterAggData = filterAggData.filter(obj => obj.values.length != 0);
            if(filterAggData.length > 0){
                checkHideShow = filterAggData.every(obj => obj.hideEye);
            }
            if ((this.active == 'all' || (Array.isArray(this.active) && !this.active.length)) && this.hideAllContentSources || checkHideShow || filterAggData.length === 0) {
                this.fullWidth = true;
            } else {
                this.fullWidth = false
            }
        }   catch(error){
            console.error('[error]', error);
        }
    }
    openPreviewModal(event) {
        document.body.style.overflow = 'hidden';
        this.typeofContentForPreview = event.currentTarget.dataset.title || event.currentTarget.dataset.value;
        this.previewSrcVal = this.modifyUrlForPreview(event.currentTarget.dataset.value);
        this.previewSourceLabel = event.currentTarget.dataset && event.currentTarget.dataset.tag;
        this.previewModalVal = true;
        if(this.searchString && this.searchString.trim() !== ''){
            fireEvent(null, 'trackAnalytics', {
                type: 'conversion', objToSend: {
                    index: event.currentTarget.dataset.index,
                    type: event.currentTarget.dataset.type,
                    id: event.currentTarget.dataset.recordid,
                    rank: parseInt(event.currentTarget.dataset.rank) + 1,
                    convUrl: event.currentTarget.dataset.url,
                    convSub: event.currentTarget.dataset.sub || event.currentTarget.dataset.url,
                    autoTuned: event.currentTarget.dataset.autotuned ? event.currentTarget.dataset.autotuned : false,
                    sc_analytics_fields: event.currentTarget.dataset.track?event.currentTarget.dataset.track:[]
                }
            });
        }
        
    }
    
    closePreviewModal() {
        this.previewModalVal = false;
        this.previewSrcVal = '';
        this.typeofContentForPreview = '';
        document.body.style.overflow = 'unset';
    }
   
    modifyUrlForPreview(url) {
        if (url.toLowerCase().includes('youtube.com')) {
            return url.replace('watch?v=', 'embed/')
        }
        else if (url.toLowerCase().includes('vimeo.com')) {
            return 'https://player.vimeo.com/video/' + url.split('.com/')[1];
        }
        else { return url }
    }

    get firrstFilterLength() {
        if (this.firstStickyLabel.length > 0) {
            return true;
        }
        else {
            return false
        }
    }

    clearFilterForSlider1(event) {
        this.active = 'all';
        this.clearAllFilters();
        fireEvent(null, 'clearAdvanceFilters', null);
        this.selectedTypeFilter = '[]';
        this.tabClickedMethod();
        
    }

    get showHideDidYouMean() {
        return this.correctspell && this.correctspell != 0 ? true : false;
    }

    correctSpelling() {
        fireEvent(null, 'setsearchstring', this.correctspell);
        fireEvent(null, 'searchPage', { searchString: this.correctspell, isFreshSearch: -1 });
    };
    /**
     * The fxn checks for type of device and returns boolean value
     */
    checkForDevice(){
            this.isDeviceMobile = 320 <= window.innerWidth && window.innerWidth <= 767,
            this.isDeviceIpad= 768 <= window.innerWidth && window.innerWidth <= 1024,
            this.isDeviceDesktop= window.innerWidth >= 1025
    }

    async connectedCallback() {
        this.loadScriptStyle = await scriptsLoaded();
        this.getCommunityCustomSettings = await getCommunitySettings();
        this.setCommunityCustomSettings(this.getCommunityCustomSettings);
        if (window.scConfiguration.language) {
            var selectedLanguages = JSON.parse(window.scConfiguration.language).config;
            this.currentLanguageSelected = selectedLanguages;
            this.defaultlanguage = selectedLanguages['defaultLanguage'] && selectedLanguages['defaultLanguage'].code;
            updateTranslation(window.scConfiguration.language || {},this.defaultlanguage);
            this.translationObject = translationObject;
                if(getURLParameter('sortBy') != ""){
                this.sortByCheck = getURLParameter('sortBy');
                }else{
                this.sortByCheck = window.scConfiguration.default_results_sorting ? window.scConfiguration.default_results_sorting.sortPreference.default : '_score'
                }
        }

        window.addEventListener('scroll', this.handleScroll.bind(this));
        this.pageSize === "" ? this.pageSize = 10 : this.pageSize;
        this.bookmarkSearches = JSON.parse(localStorage.getItem('bookmark_searches_' + this.uid) || "[]");
        if (this.bookmarkSearches.length > 0) {
            this.isBookmarkExist = true;
            this.showBookMark = true;
        } else {
            this.isBookmarkExist = false
            this.showBookMark = false;
        }
        this.checkForDevice()
        registerListener('getSearchResults', this.getData, this);
        registerListener('checkType', this.checkTypeFromSUSortBy, this);
        registerListener('searchPage', this.handleSearchPageEvent, this);
        registerListener('advancePagination', this.handleAdvanceSearch, this);
        registerListener('selectchange', this.selectChangeMethod, this);
        registerListener('paginationClicked', this.paginationClicked, this);
        registerListener('languageselected', this.langSelecetedMethod, this);
        registerListener('tabClickedMethod', this.tabClickedMethod, this);
        registerListener('savetolocal', this.saveToLocalMethod, this);
        registerListener('bookmarklistrequired', this.sendBookmarkList, this);
        registerListener('removefromlocalstorage', this.removefromlocal, this);
        registerListener('advfilterclicked', this.showClearFilterMethod, this);
        registerListener('savedbookmarkclicked', this.savedBmarkClicked, this);
        registerListener('clearFilterSecEvent', this.handleClearFilterSecEvent, this);
        registerListener('headerSUData', this.handleDataFromSU, this);
        registerListener('removeStickyFacetEvent', this.handleRemoveStickyFacetEvent, this);
        registerListener('trackAnalytics', this.handleTrackAnalytics, this);
        registerListener('clearAllFilters', this.clearAllFilters, this);
        registerListener('stringChangedFromBanner', this.stringChangedFromBanner, this);
        registerListener('filterClosed', this.filterClosed, this);
        registerListener('openPreviewModal', this.openPreviewModal, this);
        registerListener('getShowHideSearchResult', this.getShowHideSearchResult, this);
        registerListener('setResetCustomizeAggData', this.setResetCustomizeAggData, this);
        registerListener('facetPreference', this.facetPreference, this);
        registerListener('showMobileFilter', this.showMobileFilterFunc, this);
        registerListener('hideMobileFilter', this.closeMobileFilterFunc, this);
        registerListener('wildcardEnabled', this.wildCardFromAdvanceSearch, this);
        registerListener('disableSmartFacets', this.disableSmartFacets, this);
        registerListener('removeWildcardSearch', this.removeWildcardSearch, this);
        registerListener('selectedCsTab', this.selectedCsTabName, this);
        registerListener('openCitation', this.openCitationModal, this);
    }
    openCitationModal(data){
        this.showCitationModal = data.objToSend.showCitationModal;
        this.posXCitationModal = data.objToSend.posX;
        this.posYCitationModal = data.objToSend.posY;
        this.citationUrl = data.objToSend.href;
        this.diamondPositionX = data.objToSend.diamondPositionX;
        this.diamondPositionY = data.objToSend.diamondPositionY;
        if(!this.isDeviceMobile){
         this.visibilityCitations = data.objToSend.visibility;
         this.buttonHovered = data.objToSend.event
        }
        
        
    }
        
    setCommunityCustomSettings(result) {
        if (result && result.isCustomSettingFilled) {
            this.endPoint = result.endPoint;
            this.bearer = result.token;
            this.uid = result.uid;
            if(result.userEmail === ''){
                this.userTypeCheck = "Guest";
            } else if (result.userEmail != null && result.userEmail != '') {
                this.currentUserEmail = result.userEmail;
                this.userTypeCheck = '';
            }
            this.getCommunityCustomSettings2(this.bearer);
        } else {
            this.customSettingsFilled = result.isCustomSettingFilled;
            this.customSettingErrorMessage = result.customSettingErrorMessage;
        }
    }

    selectedCsTabName(name){
        this.active = name;
        this.fullWidthResults();
     }
    showMobileFilterFunc() {
        this.showMobileFilterSection = true;
    }
    closeMobileFilterFunc() {
        document.body.style.overflow = 'unset';
        document.body.style['overflow-y'] = "unset";
        this.showMobileFilterSection = false;
    }
    facetPreference(data) {
        this.aggregationsData = data.aggregationsData;
        this.active = data.activeTab;
        this.getData(data, "facetPreference");
    }
    wildCardFromAdvanceSearch(val) {
        this.hasWildcardSearch = val
        this.isWildCardEnabled = val
    }
    setResetCustomizeAggData(data) {
        this.active = data.active;
        this.defaultTab = data.defaultTab;
        this.hideTitle = data.hideTitle;
        this.hideUrl = data.hideUrl;
        this.hideSummary = data.hideSummary;
        this.hideMetadata = data.hideMetadata;
        this.hideIcon = data.hideIcon;
        this.hideTag = data.hideTag;
        this.selectedTypeFilter = data.selectedTypeFilter;
        this.getData(data, 'facetPreference');
    }
    getShowHideSearchResult(data) {
        this.hideTitle = data.hideTitle;
        this.hideUrl = data.hideUrl;
        this.hideSummary = data.hideSummary;
        this.hideMetadata = data.hideMetadata;
        this.hideIcon = data.hideIcon;
        this.hideTag = data.hideTag;
    }
    
    removeWildcardSearch() {
        this.isWildCardEnabled = false;
        this.hasWildcardSearch = false;
        window.sessionStorage.setItem('sessionToggle', this.hasWildcardSearch);
        this.withWildcardSearch = ''
        if (this.searchString.startsWith('#')) {
            this.searchString = this.searchString.substring(1);
        }
        this.getData('removewildcard', 'search')
    }
    
    handleScroll() {
        // Function to be called when scrolling occurs
        if (window.pageYOffset > 100) {
            this.showScroll = true;
        } else {
            this.showScroll = false;
        }
    }
    
    disconnectedCallback() {
        window.removeEventListener('scroll', this.handleScroll);
        fireEvent(null, 'setsearchstring', '');
        unregisterAllListeners();
    }

    filterClosed(event) {
        this.hideDataSection = false;
    }
    
    handleTrackAnalytics(event) {
        if (event.type == 'search') {
            if (!event.objToSend) {
                event.objToSend = { 
                    'searchString': this.searchString ? 
                        (this.isWildCardEnabled && !this.searchString.startsWith('#') ? '#' + this.searchString : this.searchString) 
                        : this.exactPhrase 
                }
            }
            event.objToSend = {
                ...event.objToSend,
                responseTime: this.searchResultTime,
                isFreshSearch: this.isFreshSearch == -1 ? true : false,
                result_count: this.resultCountReturned,
                filter: this.searchQuery.aggregations,
                default_search: this.default_search,
                exactPhrase: this.exactPhrase,
                withOneOrMore: this.withOneOrMore,
                withoutTheWords: this.withoutTheWords,
                withWildcardSearch: this.withWildcardSearch,
                page_no: this.pageNum
            }
            this.isFreshSearch = false;
        }
        if (event.type == 'conversion') {
            event.objToSend.pageSize = this.pageSize;
            event.objToSend.page_no = this.pageNum;
        }
        window.gza(event.type, event.objToSend);
    }

    clearAllFilters(event) {
        this.exactPhrase = '';
        this.withOneOrMore = '';
        this.withoutTheWords = '';
        this.active = 'all';

        if (this.isWildCardEnabled && this.totalResults) {
            this.withWildcardSearch = this.searchString;
        }
    }

    handleRemoveStickyFacetEvent(event) {
        let removed = false;
        this.from = 0;
        this.pageNum = 1;
        if (event.label == "With the exact phrase" || event.label == "With one or more words" || event.label == "Without the words" || event.type == "withWildcardSearch") {
            this.exactPhrase = event.label == "With the exact phrase" ? '' : this.exactPhrase;
            this.withOneOrMore = event.label == "With one or more words" ? '' : this.withOneOrMore;
            this.withoutTheWords = event.label == "Without the words" ? '' : this.withoutTheWords;
            if (this.exactPhrase == "" && this.withOneOrMore == "" && this.withoutTheWords == "" && this.withWildcardSearch == "") {
                this.advanceSearchEnabled = false
            }
            if (event.type == "withWildcardSearch") {
                this.isWildCardEnabled = false;
            }
            this.isFreshSearch = -1;
            this.getData(null, 'advanceFilterCheck');
        } else {
            if (event.type == '_index') {
                this.selectedTypeFilter = "";
                this.active = 'all';
                removed = true;
            } else if (event.type == '_type' && this.setArray[0].key !== '_index' && this.setArray[0].key !== '') {
                this.selectedTypeFilter = "";
                this.active = 'all';
                removed = true;
            }
            if (removed && (!event.immediateParent || !event.immediateParent.indexOf('merged') > -1)) {
                this.getData(null, 'filterCheck');
            } else {
                this.selectedTypeFilter = JSON.parse(JSON.stringify(this.selectedTypeFilter));
                var sr = {};
                sr["Contentname"] = event.contentname;
                sr["immediateParent"] = event.immediateParent;
                sr["parent"] = event.type;
                sr["level"] = event.level;
                sr["checkedProp"] = false;
                sr["checked"] = false;
                sr["path"] = event.path;
                fireEvent(null, 'nestedFilter', { filter: sr });
            }
        }
    }
    //handling clear filter section
    handleClearFilterSecEvent() {
        this.selectedTypeFilter = '';
        this.from = 0;
        this.pageNum = 1;
        this.counter = 1;
        this.viewAll = false;
        this.suggestionLength = false;
        this.exactPhrase = '';
        this.withOneOrMore = '';
        this.withoutTheWords = '';
        this.advanceSearchEnabled = false;
        this.getData(null, 'clearFilter');
        this.active = "all";
    }
    handleUtilitySlider() {
        this.showFilter = true;
        if (this.template.querySelector('[data-id="filterBlock"]')) {
            this.template.querySelector('[data-id="filterBlock"]').classList.remove('filterDiv');
        }
    }
    
    savedBmarkClicked(event) {
        var query = event.target.getAttribute("data-query");
        query = JSON.parse(query);
        if (query.withWildcardSearch && query.withWildcardSearch.length && query.searchString.startsWith('#')) {
            query.searchString = query.searchString.substring(1);
            this.isWildCardEnabled = true;
            window.sessionStorage.setItem('sessionToggle', this.isWildCardEnabled)
            this.hasWildcardSearch = true
        }
        fireEvent(null, 'setsearchstring', query.searchString);
        var footerDataObj = {
            "pageNo": query.pageNo,
            "resultsPerPage": query.resultsPerPage
        };
        fireEvent(null, 'sendpaginationdata', footerDataObj);
        var sendToDataSection = {
            "pageNo": query.pageNo,
            "aggregations": query.aggregations
        }
        fireEvent(null, 'sendtodatasection', sendToDataSection);
        var sendToSortData = {
            "sortby": query.sortby
        }
        fireEvent(null, 'sendsortdata', sendToSortData);
        var advSearchObj = {
            "exactPhrase": query.exactPhrase,
            "withOneOrMore": query.withOneOrMore,
            "withoutTheWords": query.withoutTheWords
        }
        fireEvent(null, 'advsearchdata', advSearchObj);
        fireEvent(null, 'languagedata', query.language);
        // let query = event.target.getAttribute("data-query");
        let endpointer = event.target.getAttribute("data-endpoint");
        let total = event.target.getAttribute("data-totalresults");
        // var query = JSON.parse(query);
        this.bookmark_clicked = true;
        this.bookmark_list = false;
        fireEvent(null, 'closesavedbmark', false);;
        document.body.style.position = 'relative';
        document.body.classList.remove('su__overflow-hidden');
        this.searchString = query.searchString;
        this.sortByCheck = query.sortby;
        this.exactPhrase = query.exactPhrase;
        this.withOneOrMore = query.withOneOrMore;
        this.withoutTheWords = query.withoutTheWords;
        this.withWildcardSearch = query.withWildcardSearch;
        this.from = query.from;
        this.pageSize = query.resultsPerPage;
        this.pageSizeAdvFiltr = query.resultsPerPage;
        // this.selectedTypeFilter = JSON.stringify(query.aggregations);
        this.totalResults = total;
        this.counter = event.target.getAttribute("data-counter");
        this.paginationList = JSON.parse(event.target.getAttribute("data-pagelist"));
        this.endPointPagination = endpointer;
        this.pageNum = query.pageNum;
        this.selectedTypeFilter = query.aggregations;
        this.isFreshSearch = -1;
        this.getData(null, 'bookmarkSearch');
        this.noBookmarkSaved = false
        this.disableSmartFacets(false)
    }
    showClearFilterMethod(d) {
        this.showClearFiltersButton = d;
        fireEvent(null, 'showclearfilterbtn', this.showClearFiltersButton);
    }
    handleDataFromSU(event) {
        let dataToBeSentToHeaderSUComponent = {
            showClearFiltersButton: this.showClearFiltersButton,
            aggregationsData: this.aggregationsData,
            selectedStickyFilter: this.selectedStickyFilter,
            showFilter: this.showFilter,
            tabsFilter: this.tabsFilter,
            bookmarkList: this.bookmarkSearches
        }
        fireEvent(null, 'dataFromContainer', dataToBeSentToHeaderSUComponent);
    }
    removefromlocal(data) {
        this.removeBookmarksList(data);
        fireEvent(null, 'bmarkslist', this.bookmarkSearches);
        fireEvent(null, 'sendBookmarkListOnSave', this.bookmarkSearches);
    }
    sendBookmarkList(e) {
        fireEvent(null, 'transssferlist', this.bookmarkSearches);
        fireEvent(null, 'sendBookmarkListOnSave', this.bookmarkSearches);
    }
    saveToLocalMethod(data) {
        this.bookmarkName = data;
        this.saveToLocal(data);
    }
    tabClickedMethod(data) {
        this.active = data && data.selectedCs;
        this.disableSmartFacets(false);
        this.from = 0;
        this.pageNum = 1;
        this.counter = 1;
        this.selectedTypeFilter = data ?  JSON.stringify(data.filterValueData): '[]'
        if(this.selectedTypeFilter === '[]'){
            this.active = 'all';
        }
        this.getData(null, null);
        this.goToTopFunc();
    }
    
    langSelecetedMethod(data) {
        this.translationObject = {}
        if (data) {
            this.defaultlanguage = data.defaultLang
            updateTranslation(window.scConfiguration.language, this.defaultlanguage);
            this.translationObject = JSON.parse(JSON.stringify(translationObject));
        }
    }

    paginationClicked(event) {
        this.endPointPagination = event.endpointpagination;
        this.pageNum = event.pagenum;
        this.counter = event.counter;
        this.from = ((this.pageNum - 1) * this.pageSize);
        this.getData(null, 'pageChange');
        this.goToTopFunc();
    }
  
    selectChangeMethod(event) {
        this.pageSizeAdvFiltr = event.pagesizeadvfiltr;
        this.pageSize = event.pagesize;
        this.pageNum = event.pageNum;
        this.counter = 1;
        this.from = ((this.pageNum - 1) * this.pageSize);
        this.getData(null, 'pageChange');
        this.goToTopFunc();
    }
   
    // When Slider Button left to search  is clicked
    handleUtilitySlider() {
        if (this.onFilterButtonClick) {
            this.onFilterButtonClick = false;
            this.template.querySelector('[data-id="filterBlock"]').classList.remove('filterDiv');
        }
        else {
            this.onFilterButtonClick = true;
            this.template.querySelector('[data-id="filterBlock"]').classList.add('filterDiv');
            this.template.querySelector('[data-id="filterBlock"]').classList.remove('su__h-100');
        }
    }
    checkTypeFromSUSortBy(event) {
        this.sortByCheck = event;
        this.from = 0;
        this.pageNum = 1;
        this.counter = 1;
        this.getData(null, 'sortBy');
    }
    handleAdvanceSearch(event) {
        this.firstStickyLabel = [];
        this.from = 0;
        this.pageNum = 1;
        this.counter = 1;
        this.exactPhrase = event.exactPhrase;
        this.withOneOrMore = event.withOneOrMore;
        this.withoutTheWords = event.withoutTheWords;
        this.isFreshSearch = -1;
        this.withWildcardSearch = event.withWildcardSearch;
        this.isWildCardEnabled = event.isWildCardEnabledfromas;
        if (this.isWildCardEnabled) {
            this.searchString = event.withWildcardSearch
        }
        // add into sticky facets
        if (this.exactPhrase) { this.firstStickyLabel.push({ "key": "exact Phrase", "value": this.exactPhrase }); }
        if (this.withOneOrMore) {
            this.firstStickyLabel.push({ "key": "with One Or More", "value": this.withOneOrMore });
        }
        if (this.withoutTheWords) { this.firstStickyLabel.push({ "key": "without The Words", "value": this.withoutTheWords }); }
        if (this.withWildcardSearch) {
            this.firstStickyLabel.push({ "key": "With the wildcard search", "value": this.withWildcardSearch });
            this.isWildCardEnabled = true;
        }
        // Sticky label from adb search
        this.advSearchFilter = this.firstStickyLabel;
        fireEvent(null, 'advsearchstickyfltr', this.advSearchFilter);
        this.getData(null, 'pageChange');
    }
    
    handleSearchPageEvent(obj) {
        if ((obj.isFreshSearch == -1 && obj.searchString && obj.searchString.length)
            || (obj.isFreshSearch != -1)) {
            this.autoSuggestionActive = obj.autoSuggestionActive
            this.searchString = obj.searchString;
            this.isFreshSearch = obj.isFreshSearch == -1 ? obj.isFreshSearch : this.isFreshSearch;
            this.from = 0;
            this.pageNum = 1;
            this.counter = 1;
            this.getData(null, 'pageChange');
            this.goToTopFunc();
        }
    }
   
    disableSmartFacets(e) {
        this.smartFacets = e
        document.cookie = "smartFacets=false; expires=Thu, 01 Jan 9999 00:00:00 UTC; path=/;";
    }
    saveToLocal(event) {
        var a = JSON.parse(localStorage.getItem('bookmark_searches_' + this.uid) || "[]");
        a.push({
            title: this.bookmarkName,
            href: JSON.stringify(this.searchQuery),
            counter: this.counter,
            endpoint: this.endPointPagination,
            totalresults: this.totalResults,
            pagelist: JSON.stringify(this.paginationList)
        });
        localStorage.setItem("bookmark_searches_" + this.uid, JSON.stringify(a));
        this.bookmarkSearches = a;
        if (this.bookmarkSearches.length > 0) {
            this.showBookMark = true
            this.isBookmarkExist = true;
        }
        else {
            this.showBookMark = false
            this.isBookmarkExist = false;
        }
        this.bookmarkName = "";
        this.viewSavePopup = false;
        this.disableButton = true;
        this.isModalOpen = false;
        this.handleDataFromSU();
        fireEvent(null, 'sendBookmarkListOnSave', this.bookmarkSearches);
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
        if (this.aggregationsData != undefined) {
            let themeProperties = JSON.parse(localStorage.getItem("theme" + this.searchQueryData.uid));
            themeProperties['aggregationdata'] = childArray;
            localStorage.setItem("theme" + this.searchQueryData.uid, JSON.stringify(themeProperties));
        }
    }
    removeBookmarksList(deleteList) {
        for (var j = 0; j < deleteList.length; j++) {
            let item = deleteList[j];
            let a = JSON.parse(localStorage.getItem('bookmark_searches_' + this.uid) || '[]');
            let index = -1;
            for (var i = 0; i < a.length; i++) {
                if (a[i].title == item.title && a[i].href == item.href) {
                    index = i;
                    break;
                }
            }
            if (index > -1) a.splice(index, 1);
            localStorage.setItem("bookmark_searches_" + this.uid, JSON.stringify(a));
        }
        let c = JSON.parse(localStorage.getItem('bookmark_searches_' + this.uid) || "[]");
        let checkboxes = this.template.querySelectorAll('[data-id="checkbox"]')
        for (i = 0; i < checkboxes.length; i++) {
            if (checkboxes[i].checked) {
                checkboxes[i].checked = false;
            }
        }
        this.bookmarkSearches = c;
        if (this.bookmarkSearches.length > 0) {
            this.showBookMark = true;
            this.isBookmarkExist = true;
        }
        else {
            this.showBookMark = false;
            this.isBookmarkExist = false;
        }
        this.handleDataFromSU();
    }

    getData(argument, searchType) {
        this.loading = 'su__loading';
        if (argument &&  argument!== 'removewildcard') {
            argument.aggregations = argument.aggregations && argument.aggregations.replace(/\\\"/g, '"') || '';
            this.selectedTypeFilter = argument.aggregations && argument.aggregations.replace(/\\\"/g, '"') || '';
        }
        if (searchType === 'search') {
            this.searchString = getURLParameter('searchString') != "" ? getURLParameter('searchString') : this.searchString;
            fireEvent(null, 'setsearchstring', this.searchString);
            this.pageNum = getURLParameter('pageNum') != "" ? getURLParameter('pageNum') : "1";
            this.exactPhrase = getURLParameter('exactPhrase') != "" ? getURLParameter('exactPhrase') : "";
            this.withOneOrMore = getURLParameter('withOneOrMore') != "" ? getURLParameter('withOneOrMore') : "";
            this.withoutTheWords = getURLParameter('withoutTheWords') != "" ? getURLParameter('withoutTheWords') : "";
            if (argument === 'removewildcard') {
                this.withWildcardSearch = ''
            } else {
                this.withWildcardSearch = getURLParameter('withWildcardSearch') != "" ? getURLParameter('withWildcardSearch') : "";
            }
            this.sortByCheck = getURLParameter('sortBy') != "" ? getURLParameter('sortBy') : window.scConfiguration.default_results_sorting ? window.scConfiguration.default_results_sorting.sortPreference.default : '_score';
            this.selectedTypeFilter = getURLParameter('selectedType') != "" ? getURLParameter('selectedType') : '';
            this.pageSize = getURLParameter('resultsPerPage') != "" ? getURLParameter('resultsPerPage') : this.pageSize;
            this.from = this.from == undefined ? (this.pageNum - 1) * this.pageSize : this.from;
        } else if(searchType == 'facetPreference') {
            this.selectedTypeFilter = (argument.aggregations && argument.aggregations.replace(/\\\"/g, '"') || argument.selectedTypeFilter &&  argument.selectedTypeFilter.replace(/\\\"/g, '"') ) || '';
            this.from = 0;
            this.pageNum = 1;
            this.counter = 1;
        }
        this.selectedTypeFilter = argument && argument.aggregations ? argument.aggregations : this.selectedTypeFilter;
        this.filterSorting = argument && argument.filterSorting ? argument.filterSorting : false;
        searchType = argument ? 'search' : searchType;
        this.from = argument && argument.filterChecked ? 0 : this.from;
        this.pageNum = argument && argument.filterChecked ? 1 : this.pageNum;
        this.counter = argument && argument.filterChecked ? 1 : this.counter;
        var runLoader = '';
        if (!this.searchString || this.searchString == "") {
            this.isFreshSearch = -1;
            this.default_search = true;
        } else this.default_search = false;
        if (getURLParameter('bookmark')) {
            searchType = getURLParameter('bookmark') ? getURLParameter('bookmark') : searchType;
        }
        if (!this.refresh || this.refresh && !this.setFlag) {
            var c = localStorage.getItem('theme' + this.uid) && JSON.parse(localStorage.getItem('theme' + this.uid));
            document.body.style['overflow-y'] = 'unset';
            if (searchType == 'bookmarkSearch') {
                this.pageNum = this.pageNum ? this.pageNum : getURLParameter('pageNum') != "" ? getURLParameter('pageNum') : "1";
                this.pageSize = this.pageSize ? this.pageSize : getURLParameter('resultsPerPage') != "" ? getURLParameter('resultsPerPage') : this.defaultPageSize;
                this.from = this.from ? this.from : this.from == undefined ? (this.pageNum - 1) * this.pageSize : this.from;
                // if (!this.setFlag || this.setFlag && !c) {
                //     this.selectedTypeFilter = getURLParameter('selectedType') != "" ? getURLParameter('selectedType') : "";
                // }
                // var previousDymString = getURLParameter('dym') ? getURLParameter('dym') : "undefined";
            }
            this.refresh = true;
            if (this.setFlag) {
                if (c) {
                    if (c.activeTabIndex != 'all' && c.activeTabIndex != undefined) {
                        this.active = c.activeTabIndex;
                        this.defaultTab = c.activeTabIndex;
                        var facetData = [{
                            "type": c.activeTabType,
                            "filter": [c.activeTabIndex.indexOf('merged_') > -1 ? c.activeTabValue : c.activeTabIndex]
                        }]
                        this.selectedTypeFilter = JSON.stringify(facetData);
                        }
                }
            }
            var startTime = new Date();
            if (runLoader == 'true') {
                if (!this.filterSortingLoading) {
                    this.loadingResult = 0;
                }
            }
            var searchText = '';
            var originalQuery = '';
            searchText = this.searchString;
            if (searchText != "" && searchText != null) {
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
            }
            this.searchString = searchText;
            if (searchText !== "" && searchText != null) {
                searchText = searchText.trim();
            }
            if (this.smartAggregationsBackup && this.smartAggregationsBackup.length && this.smartFacets) {
                let smartAggParsed = JSON.parse(JSON.stringify(this.smartAggregationsBackup))
                let selectedValues = [];
                for (let i = 0; i < smartAggParsed.length; i++) {
                    const element = smartAggParsed[i];
                    if (element.values && Array.isArray(element.values)) {

                        let selectedElements = element.values.filter(value => value.selected);
                        selectedValues.push(...selectedElements);

                    }

                }
                let tempSelectedTypeFilters = JSON.parse(this.selectedTypeFilter);
                for (let i = 0; i < tempSelectedTypeFilters.length; i++) {
                    const filter = tempSelectedTypeFilters[i];
                    const matchingValues = filter.filter.filter(value =>
                        selectedValues.some(element => element.Contentname === value)
                    );
                    if (matchingValues.length > 1) {

                        filter.filter = filter.filter.filter(value => !matchingValues.includes(value));
                    } else if (filter.filter.length === 1 && selectedValues.some(element => element.Contentname === filter.filter[0])) {
                        this.selectedTypeFilter = "";
                        break;
                    }


                    return this.selectedTypeFilter;
                }
            }

            var filterData = [];
            if (this.checkHere) {
                filterData = this.aggregationsData;
                this.checkHere = false;
            } else {
                filterData = this.selectedTypeFilter;
            }
            var arr = [];
            filterData = typeof filterData == 'string' ? filterData : JSON.stringify(filterData);
            this.selectedTypeFilter = typeof this.selectedTypeFilter == 'string' ? this.selectedTypeFilter : JSON.stringify(this.selectedTypeFilter);
            let jsonString = filterData;
            if (jsonString && jsonString.startsWith('"') && jsonString.endsWith('"')) {
                filterData = jsonString.slice(1, -1); // Remove the outer double quotes
            }
            var filterSelect = {
                "Contentname": filterData && JSON.parse(filterData).length != 0 && JSON.parse(filterData)[0].filter ? JSON.parse(filterData)[0].filter[0] : null,
                "checked": true
            }
            if (filterData && filterData.length != 0 && filterSelect.Contentname && filterSelect.Contentname.indexOf("merged_") > -1) {
                if (this.aggregationsData == undefined) {
                    let mergeFilteraggregationsData = []; // Initialize as an empty array
                    mergeFilteraggregationsData[0] = {}; // Initialize the first element as an empty object
                    mergeFilteraggregationsData[0].values = c['aggregationdata'];
                    this.mergeFilterClicked(filterSelect, arr, mergeFilteraggregationsData[0].values);
                } else {
                    this.mergeFilterClicked(filterSelect, arr, this.aggregationsData[0].values);
                }
                var data = JSON.parse(filterData);
                data[0].filter = arr;
                if (c) {
                    this.selectedTypeFilter = `[{"type": "${c.activeTabType}", "filter": ["${data[0].filter.join('","')}"]}]`;
                } else {
                    this.selectedTypeFilter = `[{"type": "${c.activeTabType}", "filter": ["${data[0].filter.join('","')}"]}]`;
                }
                if (this.checkHere) {
                    filterData = this.aggregationsData;
                    this.checkHere = false;
                } else {
                    filterData = JSON.stringify(data);
                }
            }
            this.bookmark_list = false;
            this.viewSavePopup = false;
            this.viewConfirmPopup = false;

            try {
                if (filterData && JSON.parse(filterData).length != 0) {
                    this.multiVersion = false;
                } else {
                    this.multiVersion = true;
                }
            } catch (error) {
                console.log('[error]', error);
            };
            let isSmartFacets = this.smartFacets;
            let filterSmart = filterData.length == 0 ? filterData : JSON.parse(filterData);
            if (localStorage.getItem("AutoLearning") == null || localStorage.getItem("AutoLearning") == undefined) {
                localStorage.setItem("AutoLearning", true);
            }
            let localSmart = localStorage.getItem("AutoLearning") === 'false' ? false : true;
            this.isAutoLearning = localSmart;

            let sendSmartFacet;
            try {
                sendSmartFacet = ( window._gr_utility_functions && window._gr_utility_functions.getCookie("smartFacets") == "" || window._gr_utility_functions && window._gr_utility_functions.getCookie("smartFacets") == "true") && filterSmart.length == 0 && localSmart && isSmartFacets;
            } catch (error) {
                console.log('[error]', error);
            }

            this.smartFacets = sendSmartFacet;
            var data = JSON.stringify({
                "searchString": this.searchString.trim(),
                "from": this.from || 0,
                "pageNum": parseInt(this.pageNum),
                "pageNo": parseInt(this.pageNum),
                "sortby": this.sortByCheck,
                "orderBy": 'desc',
                "resultsPerPage": parseInt(this.pageSize),
                "exactPhrase": this.exactPhrase,
                "withOneOrMore": this.withOneOrMore,
                "withoutTheWords": this.withoutTheWords,
                "withWildcardSearch": this.withWildcardSearch,
                "aggregations": filterData ? JSON.parse(filterData) : [],
                "referrer": document.referrer,
                "recommendResult": "",
                "sid": window._gr_utility_functions.getCookie("_gz_taid")+ "$Enter$",
                "smartFacets": this.smartFacets,
                "cookie": '',
                "uid": this.uid,
                "language": localStorage.getItem('language') || 'en',
                "versionResults": this.multiVersion,
                "mergeSources": this.multiVersion,
            });
            let query = JSON.parse(data);
            this.searchQueryData = query;
            if (this.isWildCardEnabled) {
                this.withWildcardSearch = this.searchString;
                query.searchString = this.searchString;
                let hashExists = query.searchString.charAt(0)
                if (hashExists === '#') {
                    query.searchString = searchText
                } else {
                    query.searchString = '#' + searchText;
                }
                data = JSON.stringify(query);
            }
            this.searchQuery = query;
            var xmlHttp = new XMLHttpRequest();
            var url = this.endPoint + "/search/SUSearchResults";
            xmlHttp.withCredentials = true;
            xmlHttp.open("POST", url, true);
            xmlHttp.setRequestHeader("Accept", "application/json");
            xmlHttp.setRequestHeader('Authorization', 'bearer ' + this.bearer);
            xmlHttp.setRequestHeader('Content-Type', 'application/json');
            xmlHttp.send(data);
            xmlHttp.onreadystatechange = () => {
                if (xmlHttp.readyState === 4) {
                    if (xmlHttp.status === 200) {
                        var result = JSON.parse(xmlHttp.response);
                        if (result.statusCode != 402) {
                            var total = result.result.total;
                            if (result.statusCode == 200 || result.statusCode == 400) {
                                this.mergeResultHits = result.result.hits;
                                this.loading = '';
                                if (this.exactPhrase !== "" || this.withOneOrMore !== "" || this.withoutTheWords !== "" || this.withWildcardSearch != "") {
                                    this.advancedSearchSelected = true;
                                } else {
                                    this.advancedSearchSelected = false;
                                }
                                this.getRecommendationsEnable = result.searchClientSettings.recommendations ? true : false;
                                result.searchClientSettings.preview ? this.preview = true : this.preview = false
                                result.searchClientSettings.contentTag ? this.contentTag = true : this.contentTag = false;
                                result.searchClientSettings.showMore ? this.showSummary = true : this.showSummary = false;
                                if (result.searchClientSettings.hideAllContentSources && this.aggregationsData && this.aggregationsData.length && ( filterData && JSON.parse(filterData))) {
                                    let selectedFilters = JSON.parse(filterData);
                                    this.allContentHideFacet = selectedFilters.filter(f => f.type == this.aggregationsData[0].key).length ? false : true;
                                } else this.allContentHideFacet = result.searchClientSettings.hideAllContentSources || false;
                                this.summaryCollapsible = result.searchClientSettings.showMore ? true : false;
                                this.maxlength = result.searchClientSettings.minSummaryLength;
                                this.languageEnabled = result.searchClientSettings.languageManager;
                                this.showViewedResults = result.searchClientSettings.ViewedResults == 1 ? 'su__viewed-results su__h-100' : 'su__h-100';
                                this.hiddenFacet = result.searchClientSettings.hiddenFacet && result.searchClientSettings.hiddenFacet.length != 0 ? true : false;
                                this.mergeResults = result.searchClientSettings.mergeSources ? true : false;
                                this.titleToShow = result.searchClientSettings.mergeSourcesTypeIndex ? true : false;
                                this.similarSearches = result.searchClientSettings.similarSearch && result.similarSearches && result.similarSearches.length != 0 ? true : false;
                                // This code checks for configuration if end user feedback is enabled
                                this.searchFeedbackEnabled =result.searchClientSettings && result.searchClientSettings.userFeedbackEnabled && result.searchClientSettings.userFeedbackEnabled.searchExp ? true : false;
                                this.searchConversionFeedback = result.searchClientSettings && result.searchClientSettings.userFeedbackEnabled && result.searchClientSettings.userFeedbackEnabled.conversionExp ? true : false;
                                this.pageRatingFeedback = result.searchClientSettings && result.searchClientSettings.userFeedbackEnabled && result.searchClientSettings.userFeedbackEnabled.contentSearchExp ? true : false;
                                this.hideAllContentSources = result.searchClientSettings && result.searchClientSettings.hideAllContentSources? result.searchClientSettings.hideAllContentSources: false;
                                this.gptContext = result.searchClientSettings && result.searchClientSettings.gptConfig && result.searchClientSettings.gptConfig.gptContext; 
                                this.gptActive = result.searchClientSettings && result.searchClientSettings.gptConfig && result.searchClientSettings.gptConfig.gptActive; 
                                this.gptLinks = result.searchClientSettings && result.searchClientSettings.gptConfig && result.searchClientSettings.gptConfig.gptLinks; 
                                fireEvent(null, 'searchCallMade', true );
                                if (this.searchFeedbackEnabled === true || this.searchConversionFeedback === true ) {
                                    this.showFeedbackModal = true;
                                }
                                // end user feedback configuration check ends
                                this.smartFacetsAdmin = result.searchClientSettings.smartFacets ? true : false;
                                if ((result.metaGraph && Object.keys(result.metaGraph).length > 0) || (result.relatedTiles && result.relatedTiles.length > 0)) {
                                    this.knowledgeGraph = true;
                                    this.knowledgeGraphMetaGraph = result.metaGraph && Object.keys(result.metaGraph).length > 0 ? true : false;
                                    this.knowledgeGraphRelatedTiles = result.relatedTiles && result.relatedTiles.length > 0 ? true : false;
                                    this.metaGraph = this.knowledgeGraphMetaGraph ? result.metaGraph : [];
                                    this.relatedTiles = this.knowledgeGraphRelatedTiles ? result.relatedTiles : [];
                                    this.knowledgeGraphResponseRecorded = false;
                                    fireEvent(null, 'knowledgeGraphMetaGraphDatafunc', this.knowledgeGraphResponseRecorded);
                                } else {
                                    this.knowledgeGraph = false;
                                }
                                if (result.featuredSnippetResult) {
                                    this.featureSnippet = result.featuredSnippetResult ? true : false;
                                    this.featureSnippetData = this.featureSnippet ? result.featuredSnippetResult : {};
                                    this.featuredResponseRecorded = false;
                                    fireEvent(null, 'featuredResponseRecordedDatafunc', this.featuredResponseRecorded);
                                    let hideRatingIconsVal = true;
                                    fireEvent(null, 'hideRatingIconsfunc', hideRatingIconsVal);
                                }
                                try {
                                    if (this.mergeResults && JSON.parse(data).mergeSources) {
                                        this.resultsInAllContentSources = true;
                                        this.mergeSourcesTypeIndex = this.titleToShow ? true : false;
                                    } else {
                                        this.resultsInAllContentSources = false;
                                    }
                                } catch (error) {
                                    console.log('[error]', error);
                                }
                                this.hideFacetsValues = {};
                                if (this.hiddenFacet) {
                                    this.hideFacetsValues = {
                                        hiddenFacet: this.hiddenFacet,
                                        values: result.searchClientSettings.hiddenFacet
                                    }
                                }
                                try {
                                    this.correctspell = result.suggest && result.suggest.simple_phrase[0] && result.suggest.simple_phrase[0].options  && result.suggest.simple_phrase[0].options.length && result.suggest.simple_phrase[0].options[0].text;
                                } catch (error) {
                                    console.log('[error]', error);
                                }
                                if (result.searchClientSettings.advertisements) {
                                    this.showAdvertisement = true;
                                    fireEvent(null, 'getAdvertisement', this.searchString);
                                }
                                this.totalResults = total;
                                var endTime = new Date();
                                var Seconds_from_T1_to_T2 = (endTime.getTime() - startTime.getTime()) / 1000;
                                var seconds_Between_Dates = Math.abs(Seconds_from_T1_to_T2);
                                this.searchResultTime = seconds_Between_Dates;
                                this.resultTime = this.searchResultTime;
                                this.resultCountReturned = result.result.hits.length;
                                if (!this.filterSorting && !this.autoSuggestionActive){
                                    (this.searchString || this.exactPhrase) && this.handleTrackAnalytics({ type: 'search' });
                                } 
                                this.autoSuggestionActive = false;
                                var aggrData = result.aggregationsArray;
                                if (this.smartFacetsAdmin && this.smartFacets) {
                                    this.smartAggregations = result.smartAggregations;
                                    if (result.smartAggregations && result.smartAggregations.length) {
                                        this.selectedTypeFilter = result.smartAggregations.reduce((result, smartItem) => {
                                            smartItem.values.forEach(filterItem => {
                                                if(filterItem && filterItem.selected){
                                                const existingTypeIndex = result.findIndex(item => item.type === filterItem.parent);
                                                if (existingTypeIndex !== -1) {
                                                    const filterNameIndex = result[existingTypeIndex].filter.indexOf(filterItem.Contentname);
                                                    if (filterNameIndex === -1) {
                                                        result[existingTypeIndex].filter.push(filterItem.Contentname);
                                                    }
                                                } else {
                                                    result.push({
                                                        type: filterItem.parent,
                                                        filter: [filterItem.Contentname],
                                                    });
                                                }
                                            }

                                            });
                                            return result;
                                        }, []);
                                       this.smartAggregationsBackup = result.smartAggregations;
                                    }
                                }
                                
                                try {
                                    if (result.merged_facets && JSON.parse(result.merged_facets).length) {
                                        this.mergedArray = JSON.parse(result.merged_facets || '[]');
                                        let self = this;
                                        this.mergedArray.forEach(function (o) {
                                            mergeFilters(o, aggrData, false, self);
                                        });
                                    }
                                } catch (error) {
                                    console.log('[error]', error);
                                }
                                
                                // All Content hide Filters
                                var found = false;
                                if (this.hideFacetsValues && this.hideFacetsValues.hiddenFacet) {
                                    aggrData.forEach((agg, index) => { 
                                        if (aggrData[0].values && aggrData[0].values.length !== 0) {
                                            aggrData[0].values.forEach(elemet => {
                                                if (elemet.selected) {
                                                    found = true;
                                                }else if(agg.merged && elemet.childSelected){
                                                    elemet.childArray.forEach(item=>{
                                                        if (item.selected) {
                                                            found = true;
                                                        }
                                                    })
                                                }
                                            });
                                        }
                                        if (!found) {
                                            this.hideFacetsValues.values.forEach(val => {
                                                if (agg.key == val) {
                                                    Object.assign(aggrData[index], { 'values': [] });
                                                }
                                            });
                                        }
                                    });
                                }
                                let hiddenAggLength = aggrData.filter((f, index) => index != 0 || !f.values || !f.values.length)
                                if (this.hideFacetsValues && this.hideFacetsValues.hiddenFacet && (this.active == 'all' || (Array.isArray(this.active) && !this.active.length))) {
                                    if (hiddenAggLength.length == this.hideFacetsValues.values.length) {
                                        this.allAreHidden = true;
                                    }
                                }
                                else {
                                    this.allAreHidden = false;
                                }
                                this.setArray = aggrData;
                                this.searchSummaryLength = result.searchClientSettings.minSummaryLength;
                                this.suggestData = "";
                                var c = localStorage.getItem('theme' + this.uid) && JSON.parse(localStorage.getItem('theme' + this.uid));
                                if (c) {
                                    if (c["hiddenFacets"]) {
                                        this.setArray.forEach(function (child) {
                                            if (c.hiddenFacets.includes(child.label)) {
                                                child.hide = true;
                                                child.hideEye = true;
                                            } else {
                                                child.hide = false;
                                                child.hideEye = false;
                                            }
                                        })
                                    } else {
                                        this.setArray.forEach(function (child) {
                                            child.hide = false;
                                            child.hideEye = false;
                                        })
                                    }

                                    if (c && c.facetsOrder && c.facetsOrder.length) {
                                        var xyz = this.setArray
                                        this.setArray.forEach(function (d) {
                                            (c.facetsOrder).forEach(function (o) {
                                                if (d.label == o.value.label) {
                                                    d.index = o.indexVal;
                                                }

                                            })
                                        })

                                        this.setArray.sort(function (a, b) {
                                            if (a.index == undefined) return 1;
                                            if (b.index == undefined) return -1;

                                            if (a.index < b.index)
                                                return -1;
                                            if (a.index > b.index)
                                                return 1;
                                            return 0;
                                        });

                                    }
                                }
                                if (result.result.hits && result.result.hits.length) {
                                    this.manipulateSearchHits(result.result.hits, result.searchClientSettings)
                                    this.responseListData = result.result.hits;
                                }

                                if (result && this.similarSearches) {
                                    this.similiarSearchData = result.similarSearches;
                                }

                                if (this.totalResults == 0) {
                                    this.loading = '';
                                     this.noResultFound = true;
                                    if (this.noSearchResultFoundMsg !== undefined) {
                                        this.noResultMsg = this.noSearchResultFoundMsg;
                                    } else {
                                        this.noResultMsg = "Sorry, no results found.";
                                    }
                                } else {
                                    this.noResultFound = false;
                                }

                                this.setStickyFacets(this.setArray);
                                this.setFilters(this.setArray);
                                this.setClearFilters();
                                this.setPagination(this.pageSize, this.pageNum);
                                this.handleDataFromSU();
                                this.fullWidthResults();
                                this.setFlag = false;
                                if (!filterData || !filterData.length) fireEvent(null, "clearFilterDataEvent", null);
                                this.suResultsLoader = true;
                                window.location.hash = "searchString=" + encodeURIComponent(this.searchString.trim()) + "&pageNum=" + this.pageNum + "&sortBy=" + this.sortByCheck + "&orderBy=desc&resultsPerPage=" + this.pageSize + "&exactPhrase=" + encodeURIComponent(this.exactPhrase) + "&withOneOrMore=" + encodeURIComponent(this.withOneOrMore) + "&withoutTheWords=" + encodeURIComponent(this.withoutTheWords) + "&withWildcardSearch=" + encodeURIComponent(this.withWildcardSearch) + "&selectedType=" + encodeURIComponent(this.selectedTypeFilter);
                            }
                        } else {
                            if (result.statusCode === 402) {
                                this.loading = '';
                                location.reload();
                            }
                        }
                }
            };
        }
    }
}
    manipulateSearchHits(hits, searchClientSettings) {
        for (var i = 0; i < hits.length; i++) {
            if (hits[i].highlight.TitleToDisplay[0] == null || hits[i].highlight.TitleToDisplay[0] == '') {
                Object.assign(hits[i], { 'highlightTitleToDisplay': true });
            } else {
                Object.assign(hits[i], { 'highlightTitleToDisplay': false });
            }
            if (hits[i].highlight.TitleToDisplayString[0]) {
                Object.assign(hits[i], { 'highlightTitleToDisplayString': hits[i].highlight.TitleToDisplayString[0] });
            } else {
                Object.assign(hits[i], { 'highlightTitleToDisplayString': null });
            }
            if (hits[i]._id != null) {
                Object.assign(hits[i], { 'dataHitscollapseVersionIconID': 'collapseVersion-2-' + hits[i]._id + '_icon' });
                Object.assign(hits[i], { 'dataHitscollapseVersionToggleIconID': 'collapseVersion-2-' + hits[i]._id + '_toggleIcon' });
                Object.assign(hits[i], { 'collapseVersionDataId': 'collapseVersion-2-' + hits[i]._id });
                Object.assign(hits[i], { 'collapseVersionOverlayId': 'collapseVersion-2-' + hits[i]._id + '_overlay' });
            }
            else {
                Object.assign(hits[i], { 'dataHitscollapseVersionIconID': null });
                Object.assign(hits[i], { 'dataHitscollapseVersionToggleIconID': null });
                Object.assign(hits[i], { 'collapseVersionDataId': 'collapseVersion-2-' + hits[i]._id });
                Object.assign(hits[i], { 'collapseVersionOverlayId': 'collapseVersion-2-' + result[i]._id } + '_overlay');
            }
            if (this.summaryCollapsible && hits[i].highlight.SummaryToDisplay.join('').length > (this.maxlength + hits[i].highlight.SummaryToDisplay.length * 5)) {
                hits[i].showMore = true;
                hits[i].highlight.SummaryToDisplayMax = hits[i].highlight.SummaryToDisplay.join('#').split('#');
                hits[i].highlight.SummaryToDisplay = hits[i].highlight.SummaryToDisplay.join('#').substring(0, this.maxlength).split('#');
            } else hits[i].showMore = false;

            if (hits[i].icon) {
                Object.assign(hits[i], { 'iconPresent': true });
            } else {
                Object.assign(hits[i], { 'iconPresent': false });
            }
            if (hits[i].bypass_filter) {
                hits[i].autotuned = false;
            }
            if (hits[i].autotuned) {
                Object.assign(hits[i], { 'autotuned': true });
            } else {
                Object.assign(hits[i], { 'autotuned': false });
            }
            if (hits[i] && hits[i].hits) {
                Object.assign(hits[i], { 'showMR': false });
                Object.assign(hits[i], { 'showMRClass': 'version-field' });
                if (hits[i].hits) {
                    Object.assign(hits[i], { 'multipleVersions': true });
                } else {
                    Object.assign(hits[i], { 'multipleVersions': false });
                }
            }
            if (searchClientSettings.preview && (hits[i].href.toLowerCase().includes('youtube.com') || (hits[i].href.toLowerCase().includes('vimeo.com') && /^\d+$/.test(hits[i].href.split('.com/')[1])) || hits[i].href.includes(window.location.origin)))
                hits[i].showPreview = true;
            else hits[i].showPreview = false;

            if (hits[i].metadata && hits[i].metadata.length) {
                hits[i].metadata.sort((a, b) => {
                    return a.value[0].length - b.value[0].length;
                })
                for (let j = 0; j < hits[i].metadata.length; j++) {
           
                    if (hits[i].metadata[j].value.length && (hits[i].metadata[j].value[0] === "" || hits[i].metadata[j].value[0].length === 0)) {
                        hits[i].metadata[j]['noMetadataValue'] = true;
                    } else {
                        hits[i].metadata[j]['noMetadataValue'] = false;
                    }
                }
            }
            if(this.mergeSourcesTypeIndex && hits[i]) {
                Object.assign(hits[i], { 'indexORobject': hits[i].sourceLabel });
            } else {
                Object.assign(hits[i], { 'indexORobject': hits[i].objLabel });
            }
            if (hits[i] && hits[i].hits && hits[i].hits.length != 0) {
                this.manipulateSearchHits(hits[i].hits, searchClientSettings);
            }
        }
    }
    
    setFilters(setArray) {
        var self = this;
        var filterValue = [{ "displayName": "All Content", "Contentname": "all", "immediateParent": "_all" }];
        this.tabsFilter = filterValue.concat((setArray && setArray.length && setArray[0].values) || []);
        this.aggregationsData = setArray;
        this.aggregationsData = this.aggregationsData.filter(function (facet) {
            if (!facet.values || !facet.values.length || facet.hideEye) {
                facet.hasValues = false;
                return true;
            };
            facet.hasValues = true;
            if (self.searchFilterString != "") {
                if (facet.key == self.key) {
                    var filterValues = [];
                    if (facet.values.length > 0) {
                        for (var j = 0; j < facet.values.length; j++) {
                            if (facet.values[j].Contentname.includes(self.searchFilterString)) {
                                filterValues.push(facet.values[j]);
                            }
                        }
                    }
                    Object.assign(facet, { 'filterSuggest': "result" });
                    Object.assign(facet, { 'filterSuggestions': filterValues });
                    if (facet.values.length > 0) {
                        Object.assign(facet, { 'suggestionLength': true });
                        self.suggestionLength = true;
                    }
                }
            }
            else if (self.searchFilterString == "" && self.key != "") {
                Object.assign(facet, { 'filterSuggest': "no-result" });
                Object.assign(facet, { 'filterSuggestions': [] });
                Object.assign(facet, { 'suggestionLength': false });
                self.suggestionLength = false;

            }
            if (facet.key != 'post_time' && facet.key != 'CreatedDate' && facet.label != 'Created Date') {
                Object.assign(facet, { 'post_Time_Enable': true });
            } else {
                Object.assign(facet, { 'post_Time_Enable': false });
            }
            if (facet.label == 'Sources') {
                Object.assign(facet, { 'enable_Custom_Sort': true });
            } else {
                Object.assign(facet, { 'enable_Custom_Sort': false });
            }
            if (facet.label == 'Created Date') {
                Object.assign(facet, { 'enable_Created_Date': true });
            } else {
                Object.assign(facet, { 'enable_Created_Date': false });
            }
            if (facet.sort == 'custom') {
                Object.assign(facet, { 'customSortingClass': 'font-12 su__color-black su__px-3 su__py-2 su__cursor su__bg-gray-hover su__filters-sort-active' });
            } else {
                Object.assign(facet, { 'customSortingClass': 'font-12 su__color-black su__px-3 su__py-2 su__cursor su__bg-gray-hover' });
            }
            if (facet.sort == 'term_asc') {
                Object.assign(facet, { 'term_ascSortingClass': 'font-12 su__color-black su__px-3 su__py-2 su__cursor su__bg-gray-hover su__filters-sort-active' });
            } else {
                Object.assign(facet, { 'term_ascSortingClass': 'font-12 su__color-black su__px-3 su__py-2 su__cursor su__bg-gray-hover' });
            }
            if (facet.sort == 'term_desc') {
                Object.assign(facet, { 'term_descSortingClass': 'font-12 su__color-black su__px-3 su__py-2 su__cursor su__bg-gray-hover su__filters-sort-active' });
            } else {
                Object.assign(facet, { 'term_descSortingClass': 'font-12 su__color-black su__px-3 su__py-2 su__cursor su__bg-gray-hover' });
            }
            if (facet.sort == 'count_desc') {
                Object.assign(facet, { 'count_descSortingClass': 'font-12 su__color-black su__px-3 su__py-2 su__cursor su__bg-gray-hover su__filters-sort-active' });
            } else {
                Object.assign(facet, { 'count_descSortingClass': 'font-12 su__color-black su__px-3 su__py-2 su__cursor su__bg-gray-hover' });
            }
            if (facet.sort == 'count_asc') {
                Object.assign(facet, { 'count_ascSortingClass': 'font-12 su__color-black su__px-3 su__py-2 su__cursor su__bg-gray-hover su__filters-sort-active' });
            } else {
                Object.assign(facet, { 'count_ascSortingClass': 'font-12 su__color-black su__px-3 su__py-2 su__cursor su__bg-gray-hover' });
            }
            Object.assign(facet, { 'collapseExampleID': 'collapseExample-' + facet.key + '_icon' });
            Object.assign(facet, { 'collapseExampletoggleIconID': 'collapseExample-' + facet.key + '_toggleIconOn' });
            Object.assign(facet, { 'collapseExampletoggleIconOffID': 'collapseExample-' + facet.key + '_toggleIconOff' });
            Object.assign(facet, { 'collapseExampleEmptyID': 'collapseExample-' + facet.key });
            Object.assign(facet, { 'filterisCollapsed': 'visibilityHidden su__position-absolute ' });
            Object.assign(facet, { 'isCollapsed': 'su__d-none' });
            Object.assign(facet, { 'expanded_Id': facet.key + '_filter_' + facet.order });
            Object.assign(facet, { 'filterSortingLoad': '' });
            Object.assign(facet, { 'filterNonExpanded': facet.values.length > 9 ? 'su__nonExpanded su__filter-content-row su__py-2' : 'su__Expanded su__filter-content-row su__py-1' });
            if (facet.values.length > 9) {
                Object.assign(facet, { 'filtersMoreThan9': true });
            } else {
                Object.assign(facet, { 'filtersMoreThan9': false });
            }
            if(facet.values.length > 9 ||  facet.merged){
                Object.assign(facet, { 'showSearchIcon': true }); 
            }else{
                Object.assign(facet, { 'showSearchIcon': false }); 
            }
            Object.assign(facet, { 'showmorefacetIcon': 'show-more-facetIcon-' + facet.key });
            if (facet.values.length > 9) {
                Object.assign(facet, { 'filtervalues': true });
            } else {
                Object.assign(facet, { 'filtervalues': false });
            }
            Object.assign(facet, { 'showMoreOrder': facet.key + '_filter_' + facet.order + '_showMore' });
            if (facet.key != '_type') {
                Object.assign(facet, { 'keytype': true });
            } else {
                Object.assign(facet, { 'keytype': false });
            }
            Object.assign(facet, { 'select': false });
            Object.assign(facet, { 'facetIconId': 'searchFacetDiv-facetIcon-' + facet.key });
            Object.assign(facet, { 'facetSearchId': facet.key + '-facetSearch' });
            Object.assign(facet, { 'facetSearchInput': 'su__search-facet-input-' + facet.key })
            Object.assign(facet, { 'facetIconClass': 'facetIcon-' + facet.key + ' su__position-absolute su__facet-close-icon su__cursor' });
            Object.assign(facet, { 'facetCloseId': 'facetCloseIcon-facetIcon-' + facet.key });
            Object.assign(facet, { 'filterSuggestItemClass': 'su__toggle-input su__position-absolute su__cursor checkType_' + facet.order })
            Object.assign(facet, { 'filterSuggestLabelClass': 'su__toggle-label su__d-inline-flex su__cursor su__loading-view-border su__' + facet.key });
            Object.assign(facet, { 'facetFilterId': 'facetSearchIcon-facetIcon-' + facet.key });
            Object.assign(facet, { 'facetFilterClass': 'facetIcon-' + facet.key + ' su__d-block su__facet-search-icon' })
            Object.assign(facet, { 'filterSuggestClass': 'su__search-facet-input su__loading-view' });
            facet.values.forEach(function (filter) {
                if (filter.value == 0) {
                    Object.assign(filter, { 'disabledValue': 'disabled' });
                } else {
                    Object.assign(filter, { 'disabledValue': 'yes' });
                }
                if (filter.displayName != null) {
                    Object.assign(filter, { 'titleName': filter.displayName });
                } else if (filter.Contentname != null) {
                    Object.assign(filter, { 'titleName': filter.Contentname });
                    Object.assign(filter, { 'displayNameNOTAvailable': true });
                }
                if (filter.childArray) {
                    Object.assign(filter, { 'collapseExampleID': 'collapseExample-' + facet.key + '_' + filter.Contentname + '_icon' });
                    Object.assign(filter, { 'collapseExampletoggleIconID': 'collapseExample-' + facet.key + '_' + filter.Contentname + '_toggleIconOn' });
                    Object.assign(filter, { 'collapseExampletoggleIconOffID': 'collapseExample-' + facet.key + '_' + filter.Contentname + '_toggleIconOff' });
                    Object.assign(filter, { 'collapseExampleEmptyID': 'collapseExample-' + facet.key + '_' + filter.Contentname });
                    filter.showChild = filter.childArray.length && !filter.merged ? 1 : filter.showChild;
                }
                Object.assign(filter, { 'uniqueId': facet.key + '_' + filter.Contentname });

            });
            return facet;
        });
        this.setFlag = false;
    }

    getCommunityCustomSettings2(bearer) {
        var searchQuery = '';
        if (bearer) {
            this.customSettingsFilled = true;
            this.selectedTypeFilter = localStorage.getItem("selectedFilter") || "";
            this.bookmarkSearches = JSON.parse(localStorage.getItem('bookmark_searches_' + this.uid) || "[]");
            if (this.bookmarkSearches.length > 0) {
                this.showBookMark = true
                this.isBookmarkExist = true
            }
            else {
                this.showBookMark = false
                this.isBookmarkExist = false
            }
            this.pageNum = 1;
            this.counter = 1;
            this.searchString = searchQuery;
            if (this.customSettingsFilled && this.bearer) {
                var c = localStorage.getItem('theme' + this.uid) && JSON.parse(localStorage.getItem('theme' + this.uid));
                if (c != null) {
                    this.filterToRight = c.filters;
                    if (c.activeTabIndex != 'all' && c.activeTabIndex != undefined) {
                        this.active = c.activeTabIndex;
                        this.defaultTab = c.activeTabIndex;
                        var filterValue = '[{"type":"' + c.activeTabType + '","filter":["' + c.activeTabIndex + '"]}]';
                        this.selectedTypeFilter = filterValue;
                    }
                    if (c.hideTitle == true) {
                        this.hiddenKeyArray.push('Title');
                        this.hideTitle = true;
                    }
                    if (c.hideSummary == true) {
                        this.hiddenKeyArray.push("Summary");
                        this.hideSummary = true
                    }
                    if (c.hideMetadata == true) {
                        this.hiddenKeyArray.push("Metadata");
                        this.hideMetadata = true
                    }
                    if (c.hideUrl == true) {
                        this.hiddenKeyArray.push("Url");
                        this.hideUrl = true
                    }
                    if (c.hideIcon == true) {
                        this.hiddenKeyArray.push("Icon");
                        this.hideIcon = true
                    }
                    if (c.hideTag == true) {
                        this.hiddenKeyArray.push("Tag");
                        this.hideTag = true
                    }
                }
                this.setFlag = true;
                this.getData(null, 'search');
            }
        }
    }


    setClearFilters() {
        this.selectedTypeFilter = typeof this.selectedTypeFilter == 'string' ? this.selectedTypeFilter : JSON.stringify(this.selectedTypeFilter);
        if (JSON.parse(this.selectedTypeFilter || "[]").length || this.exactPhrase != "" || this.withOneOrMore != "" || this.withoutTheWords != "") {
            for (let i = 0; i < (this.selectedTypeFilter && JSON.parse(this.selectedTypeFilter).length); i++) {
                if (JSON.parse(this.selectedTypeFilter)[i].filter || JSON.parse(this.selectedTypeFilter)[i].children || this.exactPhrase != "" || this.withOneOrMore != "" || this.withoutTheWords != "" || this.withWildcardSearch != "") {
                    this.showClearFiltersButton = true;
                } else {
                    this.showClearFiltersButton = false;
                }
            }
        } else {
            this.showClearFiltersButton = false;
        }
    }
   
    setStickyFacets(setArray) {
        let self = this;
        return new Promise(function (resolve, reject) {
            var stickyArray = JSON.parse(JSON.stringify(setArray));
            var selectedStickyFilter = stickyArray.filter(function (x) {
                x.tempValues = [];
                if (x.key == '_index') {
                    x.values.map(function (o) {
                        if (o.selected) {
                            o.sticky_name = o.displayName;
                            x.sticky_label = "Tab";
                            x.tempValues.push(o)
                        }
                    });
                }
                x.values.map(function (f) {
                    if (f.selected && f.parent != '_index' && !x.hideEye) {
                        f.sticky_name = f.displayName || f.Contentname;
                        x.tempValues.push(f);
                    }
                    if (f.childArray && !x.hideEye && (x.order != 0 || (!f.merged || (f.merged && f.showChild != 0)))) {
                        self.checkChildArray(x.tempValues, f.childArray, (f.displayName || f.Contentname));
                    }
                })

                if (x.tempValues.length) {
                    x.values = JSON.parse(JSON.stringify(x.tempValues || []));
                    delete x.tempValues;
                    return x;
                }
            });

            var exactPhrase = self.exactPhrase;
            var withOneOrMore = self.withOneOrMore;
            var withoutTheWords = self.withoutTheWords;
            var withWildcardSearch = self.withWildcardSearch;
            if (withWildcardSearch && withWildcardSearch.length) {
                self.hasWildcardSearch = true;
            } else {
                self.hasWildcardSearch = false
            }
            exactPhrase ? selectedStickyFilter.unshift({ "key": 'exactPhrase', "label": "With the exact phrase", "values": [{ "selected": true, "Contentname": exactPhrase, "sticky_name": exactPhrase }] }) : '';
            withOneOrMore ? selectedStickyFilter.unshift({ "key": 'withOneOrMore', "label": "With one or more words", "values": [{ "selected": true, "Contentname": withOneOrMore, "sticky_name": withOneOrMore }] }) : '';
            withoutTheWords ? selectedStickyFilter.unshift({ "key": 'withoutTheWords', "label": "Without the words", "values": [{ "selected": true, "Contentname": withoutTheWords, "sticky_name": withoutTheWords }] }) : '';
            var stickyFilter_label = selectedStickyFilter.map(function (c) { return c.label });
            self.exactPhrase = exactPhrase;
            self.withOneOrMore = withOneOrMore;
            self.withoutTheWords = withoutTheWords;
            self.withWildcardSearch = withWildcardSearch;

            var stickyFilter_label = selectedStickyFilter.map(function (c) { return c.label });
            self.stickyFilter_label = stickyFilter_label;
            self.activeSticky = stickyFilter_label[0];
            self.selectedStickyFilter = selectedStickyFilter;
            self.stickyClass = selectedStickyFilter.length > 2, 'su__selectedFilter-collapse', '';
            resolve();
        })
    }
    checkChildArray(tempValues, childArray, name) {
        let self = this;
        childArray.forEach(function (y) {
            if (y.selected) {
                y.pathString = JSON.stringify(y.path);
                y.sticky_name = name + " > " + (y.displayName || y.Contentname);
                tempValues.push(y);
            }
            if (y.childArray) {
                self.checkChildArray(tempValues, y.childArray, name + " > " + (y.displayName || y.Contentname));
            }
        });
    }
    
    setPagination(pageSize, pageNum) {
        var pageNumber = parseInt(pageNum);
        var total = this.totalResults;
        this.totalPages = Math.ceil(total / pageSize);
        var pageList = [];
        if (this.totalResults == 0) {
            pageList.push(pageNumber - (pageNumber - this.counter), (pageNumber + 1) - (pageNumber - this.counter), (pageNumber + 2) - (pageNumber - this.counter), (pageNumber + 3) - (pageNumber - this.counter))
            this.paginationList = pageList;
        }
        if (this.totalPages > 0) {
            if (this.totalPages <= 4) {
                var counter = 1;
                for (; counter <= this.totalPages; counter++) {
                    pageList.push(counter);
                }
                this.paginationList = pageList;
            }
            else {
                if (this.counter == pageNumber) {
                    for (var i = pageNumber; i <= this.totalPages; i++) {
                        if (i == pageNumber + 4) {
                            this.endPointPagination = i - 1;
                            break;
                        }
                        if ((i) == this.totalPages) {
                            pageList.push(i);
                            this.endPointPagination = this.totalPages;
                            break;
                        }
                        pageList.push(i);
                    }
                    this.paginationList = pageList;
                } else {
                    if (this.endPointPagination === undefined) {
                      if (pageNumber === this.totalPages) {
                        if (this.totalPages >= 4) {
                          this.counter = this.totalPages - 2;
                        } else {
                          this.counter = 1;
                        }
                       this.updatePageList(this.counter, this.totalPages , pageNumber , pageList);
                        return;
                       } else if (pageNumber === this.totalPages - 1 || pageNumber === this.totalPages - 2) {
                        this.counter = pageNumber - 1;
                      this.updatePageList(this.counter, this.totalPages , pageNumber , pageList);
                        return;
                      } else {
                        this.counter = pageNumber;
                      }
                      if (this.counter == pageNumber) {
                        for (var i = pageNumber; i <= this.totalPages; i++) {
                          if (i == pageNumber + 4) {
                            this.endPointPagination = i - 1;
                            break;
                          }
                                if ((i) == this.totalPages) {
                            pageList.push(i);
                            this.endPointPagination = this.totalPages;
                            break;
                          }
                          pageList.push(i);
                        }
                        this.paginationList = pageList;
                      }
                    } else {
                        if (pageNumber - (pageNumber - this.counter) == this.endPointPagination) {
                        pageList.push(pageNumber - (pageNumber - this.counter));
                        }
                        else if ((pageNumber + 1) - (pageNumber - this.counter) == this.endPointPagination) {
                            pageList.push(pageNumber - (pageNumber - this.counter), (pageNumber + 1) - (pageNumber - this.counter))

                        }
                        else if ((pageNumber + 2) - (pageNumber - this.counter) == this.endPointPagination) {
                            pageList.push(pageNumber - (pageNumber - this.counter), (pageNumber + 1) - (pageNumber - this.counter), (pageNumber + 2) - (pageNumber - this.counter))
                        }
                        else if ((pageNumber + 3) - (pageNumber - this.counter) == this.endPointPagination) {
                            pageList.push(pageNumber - (pageNumber - this.counter), (pageNumber + 1) - (pageNumber - this.counter), (pageNumber + 2) - (pageNumber - this.counter), (pageNumber + 3) - (pageNumber - this.counter))
                      }
                    }
                    this.paginationList = pageList;
                }
                if (pageNumber == this.counter + 4) {
                    this.counter = pageNumber;
                }
            }
        }
        this.disableEnableActions(pageNumber);
    }

      updatePageList (start, end , pageNumber , pageList) {
        for (let i = start; i <= end; i++) {
            if (i === pageNumber + 4) {
                this.endPointPagination = i - 1;
                break;
            }
            if (i === this.totalPages) {
                pageList.push(i);
                this.endPointPagination = this.totalPages;
                break;
            }
            pageList.push(i);
        }
        this.paginationList = pageList;
    };
    disableEnableActions(pageNumber) {
        let buttons = this.template.querySelectorAll('[data-id="paginationButton"]');
        buttons.forEach(bun => {
            if (bun.value == pageNumber) {
                bun.style = "background:#0070d2;color:#fff";

            } else {
                bun.style = "background:white;color:#808080";
            }
        });
    }
    toggleResultsPerPage() {
        this.showPageSize = !this.showPageSize;
        this.showPageClass = this.showPageSize ? 'su__d-md-block' : 'visibilityHidden';
    }
    
    goToTopFunc() {
        var goToTop = this.template.querySelector('[data-id="searchUnifyContainer"]');
        if (goToTop) {
            window.scrollTo({
                top: 0,
                behavior: 'smooth'
            });
        }
    }
    // Mobile View Saved Bookmark Toogle
    toggleSavedBookmark() {
        fireEvent(null, 'toggleSavedBookmark', false);
    }
    // Mobile View Open New Bookmark Toggle
    starClicked() {
        fireEvent(null, 'starclickedbookmark', true);
    }
    // Mobile View Toggle Adavance Search
    toggleExpandAdvanceSearch() {
        fireEvent(null, 'toggleExpandAdvanceSearch', null);
    }
    // Mobile View Toggle Search Tips
    toggleSearchTips() {
        fireEvent(null, 'toggleSearchTipsFunc', null);
    }
    
    stringChangedFromBanner(searchString) {
        this.searchString = searchString.trim();
        if (this.isWildCardEnabled) {
            this.withWildcardSearch = this.searchString
        }
    }
    /**
     * The function opens the feedback modal
     */
    openFeedbackModal(){
        fireEvent(null,'openFeedbackModal',null)
    }
}