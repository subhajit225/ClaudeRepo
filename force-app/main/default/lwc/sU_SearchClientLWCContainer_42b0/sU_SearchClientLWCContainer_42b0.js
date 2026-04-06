import { LightningElement, api, wire, track } from 'lwc';
import sendEmail from '@salesforce/apex/su_vf_console.SUVFConsoleController.sendEmail';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import caseNumber from '@salesforce/schema/Case.CaseNumber';
import caseSubject from '@salesforce/schema/Case.Subject';
import { CurrentPageReference } from 'lightning/navigation';
import checkArticle from '@salesforce/apex/su_vf_console.SUVFConsoleController.checkArticle';
import UserId from '@salesforce/user/Id';
import { registerListener, fireEvent, mergeFilters, updateTranslation, translationObject, scriptsLoaded, getCommunitySettingsConsole, makeSearchCall } from 'c/supubsub';

export default class SU_SearchClientLWCContainer extends NavigationMixin(LightningElement) {
    previousCaseId;
    isUtility = false;
    advSearchFilter = [];
    //pic = pinIcon;
    @track gptActive = false;
    @api height;
    @api failText;
    @track visibilityCitations;
    @track buttonHovered;
    @api emptySearchString;
    @api utilityWidth = 0;
    @api utilityHeight;
    @api utilityTop = 0;
    @api recordIddFromUtility;
    @api isCaseInBgFromUtilityForAh;
    @track isCaseInBgforAh;
    @track caseIdForAh;
    @track currentCaseNumberForAh;
    @api isUtilityAH;
    suComponentHeight;
    previous = '';
    areScriptsLoaded;
    wiredRecordData;
    @api caseSubjectInUtilityBar;
    mergeResults;
    @track titleToShow;
    @track mergeSourcesTypeIndex;
    @api casePreSelectedValues; // to get field values from SUConsoleLWC for utility bar
    @track showModal = false;
    @track JWTToken;
    @track currentLanguageSelected = 'English'
    @track defaultLang = 'en';
    @track currentCaseSubject;
    @track currentUserId = UserId;
    @track showPagination;
    @track containerRightCoordinate;
    @track tabsFilter;
    @track default_search;
    @track currentCaseNumber;
    @track goToTopContainer;
    @track resultTime;
    @track pageSize = 10;
    defaultlanguage;
    @track bigScreen = false;
    @track pageNum = 1;
    @track contentSourceTab = true;
    @track searchQuery;
    s3EndPoint ;
    @track endPoint = '';
    @track bearer = '';
    @track uid ;
    @track searchUidAH ;
    @track searchUidRA ;
    @track linkSharingOptions = [];
    suResultsLoader = true;
    @track customSettingErrorMessage;
    @track customSettingsFilled;
    @track selectedTypeFilter;
    @track defaultTab;
    @track filterValue;
    @track setFlag;
    @track sortByCheck = '_score';//@@@@@
    @track exactPhrase = ''; //@@@@@
    @track withOneOrMore = '';//@@@@@@
    @track withoutTheWords = '';//@@@@@
    withWildcardSearch = '';
    @track defaultPageSize = 10;
    @track advanceSearchEnabled;
    @track filterSortingLoading;
    @track loadingResult;
    @track filterOrder;
    @track currentClickedOrder;
    @track viewSavePopup;
    @track preview;
    @track contentTag;
    @track showSummary;
    @track mergedArray = [];
    mergedArrayStr;
    @track hasWildcardSearch;
    @track disableButton;
    @track bookmarkName;
    @track responseListData = [];
    @track resultSectionContainer ;
    @track showViewedResults = 'su__h-100';
    @track translationObj = {};
    @track languageSelectedByUser;
    @track directionText;
    @track selectedLanguages;
    @track isModalOpen = false;
    @track noBookmarkSaved = false;
    @track showClearFiltersButton = false;
    @track selectedStickyFilter = [];
    @track totalPages;
    @track allContentHideFacet = false;
    summaryCollapsible = false;
    hiddenFacet = false;
    hideFacetsValues = '';
    @track languageEnabled = 0;
    @track caseSelection;
    @track showCaseNumber;
    @track urlOpensInNewTab;
    searchResultTime;
    result2 = {};
    @track active = 'all_content';
    activeTab = 'all_Content';
    @track viewAll = false;
    @track showFilter = false;
    @track dataSectionClass = "";
    @track fullWidth = true;
    @track resizeclass = 'su__d-none';
    @track resizeclassFilter = 'su__d-none';
    value = 'SortByRelevance';
    @api index;
    valueChildTab = '';
    pagingAggregation;
    @track key;
    @track noGpt = false;
    @track checkCaseEmpty = false;
    @track searchFilterString;
    @track suggestionLength = false
    @track bookmark_clicked = false;
    @track isBookmarkExist = false;
    @track showBookMark = false;
    @track sentimentEmojiUrl ='';
    @track loadAgentHelper = true;
    @api showArticle;
    @track resultperpageForAutocomplete;
    currentUserEmail;
    loading;
    checkHere = false;
    firstLoadContainer = true;
    advancedSearchSelected = false;
    showAgentHelperTab = false;
    openAhDefault = false;
    isAgentHelperEnabled = false;
    agentHelperConfiguration;
    onFilterButtonClick = true;
    eventCode;
    containerXCoordinate;
    isFreshSearch = -1;
    resultCountReturned;
    hideDataSection = false;
    customHeight;
    @api caseUtilitySub;
    @track caseIdExists;
    previouscaseUtilitySub = '';
    maincontainerwidth;
    firstLoad = true;
    @track isWildCardEnabled ;
    translationObject;
    _searchString;
    _counter = 1;
    _bookmarkSearches;
    _endPointPagination;
    _caseSubjectVal;
    _aggregationsData;
    _multiVersion = false;
    _paginationList;
    _allAreHidden;
    _noResultMsg;
    _mergeResultHits;
    _recordId;
    _setArray;
    @track showCitationModal = false;
    @track posXCitationModal;
    @track  posYCitationModal;
    @track citationUrl = '';
    @track diamondPositionX;
    @track diamondPositionY;

    _firstStickyLabel = [];
    myCustomFields = [caseNumber, caseSubject]; // array to store all case fields that need to be queried
    myCustomSettings; // object that stores all custom settings of console
    preSelectedFilters; // object that stores all preSelected field values
    @api searchStringFromBanner = '' ;
    errorCallback(error, stack) {
        console.log("-----------error-----------stack-----------", error, stack);
    }
    openAgentHelper() {
        this.loadAgentHelper = true;
        this.showAgentHelperTab = true;
    }
    showSearchConsole() {
        this.showAgentHelperTab = false;
    }
    @api
    get setArray() {
        return this._setArray;
    }

    set setArray(value) {
        this._setArray = value;
    }
    @api
    get firstStickyLabel() {
        return this._firstStickyLabel;
    }

    set firstStickyLabel(value) {
        this._firstStickyLabel = value;
    }
    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        this._recordId = value;
    }
    @api
    get mergeResultHits() {
        return this._mergeResultHits;
    }

    set mergeResultHits(value) {
        this._mergeResultHits = value;
    }
    @api
    get noResultMsg() {
        return this._noResultMsg;
    }

    set noResultMsg(value) {
        this._noResultMsg = value;
    }
    @api
    get allAreHidden() {
        return this._allAreHidden;
    }

    set allAreHidden(value) {
        this._allAreHidden = value;
    }
    @api
    get paginationList() {
        return this._paginationList;
    }

    set paginationList(value) {
        this._paginationList = value;
    }
    @api
    get multiVersion() {
        return this._multiVersion;
    }

    set multiVersion(value) {
        this._multiVersion = value;
    }
    @api
    get aggregationsData() {
        return this._aggregationsData;
    }

    set aggregationsData(value) {
        this._aggregationsData = value;
    }
    @api
    get caseSubjectVal() {
        return this._caseSubjectVal;
    }

    set caseSubjectVal(value) {
        this._caseSubjectVal = value;
    }
    @api
    get endPointPagination() {
        return this._endPointPagination;
    }

    set endPointPagination(value) {
        this._endPointPagination = value;
    }
    @api
    get bookmarkSearches() {
        return this._bookmarkSearches;
    }

    set bookmarkSearches(value) {
        this._bookmarkSearches = value;
    }
    @api
    get searchString() {
        return this._searchString;
    }

    set searchString(value) {
        this._searchString = value;
    }
    @api
    get counter() {
        return this._counter;
    }

    set counter(value) {
        this._counter = value;
    }

    get hoverDiv() {
        if (this.loading !== '' && this.caseSubjectInUtilityBar) {
            return 'su__d-none'
        }
            return 'su__hover-div'

    }
    get loaderClasses() {
        if (this.firstLoadContainer && this.suResultsLoader && this.caseSubjectInUtilityBar) {
            return 'su__spinner-main su__w-100 su__h-100vh  su__position-absolute'
        } 
            return 'su__spinner-main su__w-100 su__h-100  su__position-absolute'
    }
    get componentStyleLoad() {
        if (this.firstLoadContainer && !this.caseSubjectInUtilityBar) {
            return this.height ? `height:${this.height}px; z-index: 96;` : 'height:600px; z-index: 96;';
        }
        return 'z-index: 96;';
    }

    get componentStyle() {
        return this.height ? `height:${this.height}px;` : 'height:100%';
    }
    get Style(){
        return `height:100%`;
    }
    get activeCaseNumber() {
        return this.currentCaseNumber && this.showCaseNumber ? true : false;
    }
    get eventClass() {
        return 'su__searchUnifyContainer su__h-100 su__' + this.eventCode;
    }

    get showSuLoader() {
        return this.suResultsLoader && !this.showAgentHelperTab;
    }

    
    renderedCallback() {
        const outerVariable = this.template.querySelector(".suContainer");
        if(outerVariable) this.suComponentHeight = outerVariable.clientHeight;
        else console.log("didnt got the element");

        if(this.isCaseInBgforAh !== this.isCaseInBgFromUtilityForAh){
            this.isCaseInBgforAh = this.isCaseInBgFromUtilityForAh;
            if(!this.isCaseInBgforAh){
                this.currentCaseNumberForAh = '';
            }
            if(this.template.querySelector('c-s-u_-Agent-Iq')) {
                this.loadAgentHelper = false;
                setTimeout(()=>{
                this.loadAgentHelper = true;
                },100);
            }
        }
        if(this.caseIdForAh !== this.recordIddFromUtility){
            this.caseIdForAh = this.recordIddFromUtility;
            if(this.template.querySelector('c-s-u_-Agent-Iq')) {
                this.loadAgentHelper = false;
                setTimeout(()=>{
                this.loadAgentHelper = true;
                },100);
            }
        }
        window.addEventListener('resize', this.resizeCheck.bind(this));
        this.resizeCheck();
        this.caseIdExists = this.currentCaseNumber ? true : false;
        if (this.totalResults > 10) {
            this.showPagination = true
        } else {
            this.showPagination = false
        }
        let suContainer = this.template.querySelector('div.su__searchUnifyContainer');
        if(suContainer){
            if (this.defaultlanguage === 'ar') {
                suContainer.classList.add("su__rtl");
            } else {
                suContainer.classList.remove("su__rtl");
            }
        }
        if (this.template.querySelector('.suContainer')) {
            this.containerXCoordinate = this.template.querySelector('.suContainer').getBoundingClientRect().x;
            this.containerRightCoordinate = this.template.querySelector('.suContainer').getBoundingClientRect().right;
        }
        if (this.previouscaseUtilitySub !== this.caseUtilitySub) {
            this._searchString = this.caseUtilitySub;
            this.previouscaseUtilitySub = this.searchString;
            if(this.recordIddFromUtility){
                this.recordId = this.recordIddFromUtility;
            }
        }
        if (this.caseSelection && this.previous !== this.caseSubjectInUtilityBar && this.recordIddFromUtility && this.caseSubjectInUtilityBar && (this.recordIddFromUtility.startsWith('500') && this.recordId !== this.recordIddFromUtility && this.searchString !== this.caseSubjectInUtilityBar)) { //isUtility   && this.recordId==undefined{
            this.previous = this.caseSubjectInUtilityBar;
            this._searchString = this.caseSubjectInUtilityBar;
            this._recordId = this.recordIddFromUtility; // id received from SUConsoleLWC component
            this.previousCaseId = this.recordId;
            this.preSelectedFilters = this.casePreSelectedValues || {};
            this.setPreSelectedFilters().then(() => {
                this.handleSearchPageEvent({ searchString: this.searchString, isFreshSearch: -1 });
                fireEvent(null, 'setsearchstring' + this.eventCode, '');
            });
        }
        if (this.firstLoad && this.template.querySelector('div.su__' + this.eventCode) && this.template.querySelector('div.su__' + this.eventCode).clientWidth > 0) {
            this.firstLoad = false;
        }
        this.goToTopContainer = this.template.querySelector('[data-id="searchUnifyContainer"]');
        if(this.template.querySelector('[data-id="searchUnifyContainerResultSection"]')){
            this.resultSectionContainer = this.template.querySelector('[data-id="searchUnifyContainerResultSection"]');
            this.resultSectionContainer.addEventListener('scroll', this.handleScroll.bind(this));
        }
    }

    applyClasses() {
        let e = this.template.querySelector('div.su__searchUnifyContainer');
        this.dataSectionClass = "";
        if (this.template.querySelector('div.su__' + this.eventCode)) {
            this.maincontainerwidth = this.template.querySelector('div.su__' + this.eventCode).clientWidth;
        }
        if (this.maincontainerwidth < 450) {
            e.className = `su__searchUnifyContainer su__' + ${this.eventCode} + ' su__width-320 su__h-100 ${this.defaultlanguage === 'ar' ? 'su__rtl' : ''}`;
            this.fullWidthResults(false);
        }
        else if (this.maincontainerwidth < 600) {
            e.className = `su__searchUnifyContainer su__' + ${this.eventCode} + ' su__width-320 su__width-450 su__h-100 ${this.defaultlanguage === 'ar' ? 'su__rtl' : ''}`;
            this.fullWidthResults(false);
        }
        else if (this.maincontainerwidth < 1200) {
            e.className = `su__searchUnifyContainer su__' + ${this.eventCode} + ' su__width-600 su__h-100 ${this.defaultlanguage === 'ar' ? 'su__rtl' : ''}`;
            this.fullWidthResults(false);
        }
        else if (this.maincontainerwidth > 1200) {
            e.className = `su__searchUnifyContainer su__' + ${this.eventCode} + ' su__width-800 su__h-100 ${this.defaultlanguage === 'ar' ? 'su__rtl' : ''}`;
            this.fullWidthResults(true);
        }

    }

    resizeCheck = () => {
        clearTimeout(this.timeout);
        this.timeout = setTimeout(() => {
            this.applyClasses();
        });
    }

    fullWidthResults = (bigscreenevent) => {
        if (bigscreenevent === false) {
            this.resizeclass = 'su__d-none';
            this.resizeclassFilter = 'su__d-none'
            this.bigScreen = false;

        }
        else if ((bigscreenevent === true && !this.fullWidth) || (bigscreenevent === true && this.totalResults !== 0)) {
            this.resizeclass = 'su__d-block ';
            this.resizeclassFilter = 'su__d-block su__w-25 ';
            this.hideDataSection = false;
            this.dataSectionClass = 'su__w-75';
            this.bigScreen = true;
        }
        if (bigscreenevent && this.aggregationsData && this.aggregationsData.length !== 0) {
            this.fullWidth = true
            for (let index = 1; index < this.aggregationsData.length; index++) {
                if (this.aggregationsData[index].values.length) {
                    this.fullWidth = false;
                }
            }
        }
        if ((this.fullWidth && bigscreenevent) || (bigscreenevent && this.totalResults === 0)) {
            this.dataSectionClass = "su__pops"
            this.resizeclassFilter = 'su__d-none';

        }
    }
    handleActive(event) {
        this.active = event.target.value;
        if (this.active === 'all_Content') {
            this.selectedTypeFilter = "";
            if (this.customSettingsFilled && this.bearer)
                this.getData(null, 'pageChange');
            this.goToTopFunc();
        }
        else {
            var filterValue = '[{"type":"_index","filter":["' + this.active + '"]}]';
            this.selectedTypeFilter = filterValue;
            this.pageNum = 1;
            this._counter = 1;
            this.setPagination(this.pageSize, this.pageNum)
            if (this.customSettingsFilled && this.bearer)
                this.getData(null, 'pageChange');
            this.goToTopFunc();
        }
    }
    get options() {
        return [
            { label: 'Sort By Relevance', value: '_score' },
            { label: 'Sort By Created Date', value: 'post_time' },
        ];
    }

    @wire(getRecord, { recordId: '$caseIdForAh', fields: '$myCustomFields' })
    recordForAh({ data }) {
        if (data) {
            const { fields } = data;
            Object.keys(fields).forEach(item => {
                let value = fields[item] && fields[item].displayValue ? fields[item].displayValue : fields[item].value;
                this.result2 = { ...this.result2, [item]: value }
            });
            this.currentCaseNumberForAh = this.result2.CaseNumber;     
        }
    }

    @wire(CurrentPageReference) pageRef;
    constructor() {
        super();
        this.getDataAndMakeAPICall();
    }

    async getDataAndMakeAPICall() {
        await this.waitForWiredRecord();
        this.initialize();
    }
    
    waitForWiredRecord() {
      return new Promise((resolve) => {
        let retryCount = 0;
         const maxRetries = 5;
         const checkInterval = 100;
         const checkData = () => {
         if (this.wiredRecordData || this.caseSubjectInUtilityBar) {
            resolve();
          } else if (retryCount < maxRetries) {
              retryCount++;
              setTimeout(checkData, checkInterval);
          } else {
              resolve();
            }
          };
          checkData();
        });
    }
    
    async initialize() {
        this.translationObject = translationObject;
        this.getAllVarForConsole = await getCommunitySettingsConsole();
        if (this.getAllVarForConsole) {
            this.uid = this.getAllVarForConsole.su_vf_console__UID__c;
            this.s3EndPoint = this.getAllVarForConsole.su_vf_console__CDN_Support_Endpoint__c + '/' + this.getAllVarForConsole.su_vf_console__UID__c;
            this.endPoint = this.getAllVarForConsole.su_vf_console__Global_Search_Server_Endpoint_V2__c;
            this.JWTToken = this.getAllVarForConsole.token;
            if (this.getAllVarForConsole.su_vf_console__FilterFieldName__c) {
                this.myCustomFields = this.myCustomFields.concat(this.getAllVarForConsole.su_vf_console__FilterFieldName__c.split(',').map(f => 'Case.' + f));
            }
        }
        this.areScriptsLoaded = await scriptsLoaded();
        if (this.areScriptsLoaded) {
            if (this.JWTToken) {
                this.getCommunityCustomSettings2(this.JWTToken);
            }
            if(window.scConfiguration.default_results_sorting){
            this.sortByCheck = window.scConfiguration.default_results_sorting ? window.scConfiguration.default_results_sorting.sortPreference.default : '_score';
            }
            if (window.scConfiguration.resultSharingOptions && window.scConfiguration.resultSharingOptions.length !== 0) {
                this.linkSharingOptions = window.scConfiguration.resultSharingOptions;
            }
            this.agentHelperConfiguration = window.scConfiguration.agentHelperConfiguration || {};
            this.isAgentHelperEnabled = this.agentHelperConfiguration && this.agentHelperConfiguration.enabled;
            this.searchUidAH = this.agentHelperConfiguration && this.agentHelperConfiguration.search_uid_AH ? this.agentHelperConfiguration.search_uid_AH : this.uid;
            this.searchUidRA = this.agentHelperConfiguration && this.agentHelperConfiguration.search_uid_RA ? this.agentHelperConfiguration.search_uid_RA : this.uid;

            if (this.isAgentHelperEnabled && this.openAhDefault) {
                this.showAgentHelperTab = true;
            }

            if (window.scConfiguration.language) {
                var selectedLanguages;
                try {
                    selectedLanguages = JSON.parse(window.scConfiguration.language).config;
                } catch (error) {
                    console.error("An error occurred while parsing the JSON:", error);
                }
                this.currentLanguageSelected = selectedLanguages;
                this.defaultlanguage = selectedLanguages.defaultLanguage && selectedLanguages.defaultLanguage.code;
                updateTranslation(window.scConfiguration.language || {}, this.defaultlanguage);
                this.translationObject = translationObject;
            }
            sendEmail({ userId: this.currentUserId }).then(result => {
                this.currentUserEmail = result;
                try {
                    window.GzAnalytics.setUser(this.currentUserEmail);
                } catch (error) {
                    console.error("An error occurred while setting the user:", error);
                }
            }).catch(error => {
                console.log(error, "error occured in connectedCallBack after fetching scripts");
            });
        }
        this.noGpt = true;
    }
    handleScroll(){
       this.showCitationModal = false;
       this.posXCitationModal = 0;
       this.posYCitationModal = 0;
    }

    showHideGenerateBtnfilterSection(val){
        this.noGpt = val; 
    }

    connectedCallback() {
        if(this.showAgentHelperTab) this.suResultsLoader = true;
        this.eventCode = Math.floor(Math.random() * (10000 - 1 + 1)) + 1;
        try {
            this._bookmarkSearches = JSON.parse(localStorage.getItem('bookmark_searches_' + this.uid) || "[]");
        } catch (error) {
            console.error("An error occurred while parsing the JSON from local storage:", error);
        }

        if (this.bookmarkSearches.length > 0) {
            this.isBookmarkExist = true;
            this.showBookMark = true;
        }
        else {
            this.isBookmarkExist = false
            this.showBookMark = false;
        }
        registerListener('removeWildcardSearch' + this.eventCode, this.removeWildcardSearch, this);
        registerListener('checkType' + this.eventCode, this.checkTypeFromSUSortBy, this);
        registerListener('searchPage' + this.eventCode, this.handleSearchPageEvent, this);
        registerListener('getSearchResults' + this.eventCode, this.getData, this);
        registerListener('advancePagination' + this.eventCode, this.handleAdvanceSearch, this);
        registerListener('selectchange' + this.eventCode, this.selectChangeMethod, this);
        registerListener('paginationClicked' + this.eventCode, this.paginationClicked, this);
        registerListener('languageselected' + this.eventCode, this.langSelecetedMethod, this);
        registerListener('sendLinkEvent' + this.eventCode, this.handleSendLinkEvent, this);
        registerListener('copyLinkEvent' + this.eventCode, this.handleCopyLinkEvent, this);
        registerListener('attachToCaseEvent' + this.eventCode, this.handleAttachToCaseEvent, this);
        registerListener('filterSectionEvent' + this.eventCode, this.handleFilterSectionEvent, this);
        registerListener('tabclicked' + this.eventCode, this.tabClickedMethod, this);
        registerListener('caseCommentEmailEvent' + this.eventCode, this.handleCaseCommentEmailEvent, this);
        registerListener('savetolocal' + this.eventCode, this.saveToLocalMethod, this);
        registerListener('bookmarklistrequired' + this.eventCode, this.sendBookmarkList, this);
        registerListener('checkboxSelectedEvent' + this.eventCode, this.checkboxSelectedEvent, this);
        registerListener('removefromlocalstorage' + this.eventCode, this.removefromlocal, this);
        registerListener('advfilterclicked' + this.eventCode, this.showClearFilterMethod, this);
        registerListener('filterChangesEvent' + this.eventCode, this.handleFilterChangesEvent, this);
        registerListener('savedbookmarkclicked' + this.eventCode, this.savedBmarkClicked, this);
        registerListener('clearFilterSecEvent' + this.eventCode, this.handleClearFilterSecEvent, this);
        registerListener('headerSUData' + this.eventCode, this.handleDataFromSU, this);
        registerListener('removeStickyFacetEvent' + this.eventCode, this.handleRemoveStickyFacetEvent, this);
        registerListener('trackAnalytics' + this.eventCode, this.handleTrackAnalytics, this);
        registerListener('clearAllFilters' + this.eventCode, this.clearAllFilters, this);
        registerListener('clearSearch' + this.eventCode, this.handleClearSearch, this);
        registerListener('collapseSummary' + this.eventCode, this.handleCollapseSummary, this);
        registerListener('stringChangedFromBanner' + this.eventCode, this.stringChangedFromBanner, this);
        registerListener('filterClosed' + this.eventCode, this.filterClosed, this);
        registerListener('setGPTValue' + this.eventCode, this.setSearchStringFromBanner, this);
        registerListener('sentimentEmoji', this.handleAHCaseSentiment, this);
        registerListener('openCitation'+this.eventCode, this.openCitationModal, this);
        registerListener('showHideGenerateBtnfilterSection'+this.eventCode, this.showHideGenerateBtnfilterSection, this);
        registerListener('toggleAH'+ this.eventCode, this.showSearchConsole, this);
        registerListener("checkHeight" + this.eventCode, this.checkHeight, this );
        this.resizeCheck();
        this.customHeight = 'height: calc(100% - 100px)!important; overflow:auto;'
    }

    checkHeight(){
        const outerVariable = this.template.querySelector(".suContainer");
        if(outerVariable) this.suComponentHeight = outerVariable.clientHeight;
        else console.log("===== Failed Height Check ======");
    }
   
    openCitationModal(data){
        this.showCitationModal = data.objToSend.showCitationModal;
        this.posXCitationModal = data.objToSend.posX;
        this.posYCitationModal = data.objToSend.posY;
        this.citationUrl = data.objToSend.href;
        this.diamondPositionX = data.objToSend.diamondPositionX;
        this.diamondPositionY = data.objToSend.diamondPositionY;
        this.visibilityCitations = data.objToSend.visibility;
        this.buttonHovered = data.objToSend.event
        
    }

    setSearchStringFromBanner(data){
        // eslint-disable-next-line
        this.searchStringFromBanner = data;
    }
    @wire(getRecord, { recordId: '$recordId', fields: '$myCustomFields' })
    wiredRecord({ data }) {
        if (data) {
            this.wiredRecordData = data;
            const { fields } = data;
            Object.keys(fields).forEach(item => {
                let value = fields[item] && fields[item].displayValue ? fields[item].displayValue : fields[item].value;
                this.result = { ...this.result, [item]: value }
            })
            this._searchString = this.result.Subject;
            this.currentCaseNumber = this.result.CaseNumber;
            this.currentCaseSubject = this.result.Subject;
            this._caseSubjectVal = this.result.Subject;
            this.preSelectedFilters = this.result;
            this.noGpt = true;
            fireEvent(null, 'showHideGpt' + this.eventCode, this.noGpt );
        } 
    }
    filterClosed() {
        this.hideDataSection = false;
        this.goToTopFunc();
    }

    removeWildcardSearch(){
        this.isWildCardEnabled = false;
        this.withWildcardSearch = ''
        if (this.searchString.startsWith('#')) {
            this._searchString = this.searchString.substring(1);
        }
        this.getData(null,'search')
    }
    paginationClicked(event) {
        this._endPointPagination = event.endpointpagination;
        this.pageNum = event.pagenum;
        this._counter = event.counter;
        this.from = ((this.pageNum - 1) * this.pageSize);
        this.getData(null, 'pageChange');
        this.goToTopFunc();
    }

    
    handleTrackAnalytics(event){
        if (event.type === 'search') {
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
                isFreshSearch: this.isFreshSearch === -1 ? true : false,
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
        if (event.type === 'conversion') {
            event.objToSend.pageSize = this.pageSize;
            event.objToSend.page_no = this.pageNum;
        }
        if (event.type === 'autocomplete') {
            event.type = 'search';
            event.objToSend.searchString = this.searchString;
        }
        try {
            window.gza(event.type, event.objToSend);
        } catch (error) {
            console.error("An error occurred while calling window.gza:", error);
        }
        
    }

    clearAllFilters() {
        this.exactPhrase = '';
        this.withOneOrMore = '';
        this.withoutTheWords = '';
        if (!this.totalResults && !this.isWildCardEnabled ) {
            this._searchString = '';
            fireEvent(null, 'setsearchstring' + this.eventCode, this.searchString);
        }
        this._searchString = !this.totalResults && !this.isWildCardEnabled ? this.caseSubjectVal : this.searchString;
        if(this.isWildCardEnabled && this.totalResults){
            this.withWildcardSearch = this.searchString
        }
    }

    handleRemoveStickyFacetEvent(event) {
        let removed = false;
        this.from = 0;
        this.pageNum = 1;
        if (event.label === "With the exact phrase" || event.label === "With one or more words" || event.label === "Without the words" || event.type === "withWildcardSearch") {
            this.exactPhrase = event.label === "With the exact phrase" ? '' : this.exactPhrase;
            this.withOneOrMore = event.label === "With one or more words" ? '' : this.withOneOrMore;
            this.withoutTheWords = event.label === "Without the words" ? '' : this.withoutTheWords;
            this.withWildcardSearch = event.type === "withWildcardSearch" ? '' : this.withWildcardSearch;
            if (this.exactPhrase === "" && this.withOneOrMore === "" && this.withoutTheWords === "" && this.withWildcardSearch === "") {
                this.advanceSearchEnabled = false
            }
            if(event.type  === "withWildcardSearch"){
                 this.isWildCardEnabled  = false;
            }
            this.isFreshSearch = -1;
            this.getData(null, 'advanceFilterCheck');
        } else {
            if ((event.type === '_index') || (event.type === '_type' && this.setArray[0].key !== '_index' && this.setArray[0].key !== '')) {
                this.selectedTypeFilter = "";
                this.active = 'all';
                removed = true;
            }
            if (removed && (!event.immediateParent || !event.immediateParent.indexOf('merged') > -1)) {
                this.getData(null, 'filterCheck');
            } else {
                var sr = {};
                sr.Contentname = event.contentname;
                sr.immediateParent = event.immediateParent;
                sr.parent = event.type;
                sr.level = event.level;
                sr.checkedProp = false;
                sr.checked = false;
                sr.path = event.path;
                fireEvent(this.pageRef, 'nestedFilter' + this.eventCode, { filter: sr });
            }
        }
    }
    

    //handling clear filter section
    handleClearFilterSecEvent() {
        this.selectedTypeFilter = '[]';
        this.from = 0;
        this.pageNum = 1;
        this._counter = 1;
        this.viewAll = false;
        this.suggestionLength = false;
        this.exactPhrase = '';
        this.withOneOrMore = '';
        this.withoutTheWords = '';
        this.advanceSearchEnabled = false;
        if(this.isWildCardEnabled && !this.totalResults){
            this.getData(null, 'search');
        }else{
            this.getData(null, 'clearFilter');
        }
        this.active = "all_Content";
    }

    handleUtilitySlider() {
        this.showFilter = true;
        if (this.template.querySelector('[data-id="filterBlock"]')) {
            this.template.querySelector('[data-id="filterBlock"]').classList.remove('filterDiv');
        }
    }

    //This event handle Filter chnge event
    handleFilterChangesEvent(event) {
        this.selectedTypeFilter = event.selectedTypeFilter;
        this.filterOrder = event.filterOrder;
        this.currentClickedOrder = event.currentClickedOrder;
        this._counter = event.counter;
        if (this.selectedTypeFilter.length > 0) {
            this._aggregationsData = [];
            this.from = 0;
            this.pageNum = 1;
            this._counter = 1;
            this.setPagination(this.pageSize, this.pageNum)
        }
        if (this.customSettingsFilled && this.bearer)
            this.getData(null, 'pageChange');
        this.goToTopFunc();
    }

    savedBmarkClicked(event) {
        var query = event.target.getAttribute("data-query");
        query = JSON.parse(query);
        if (query.withWildcardSearch && query.withWildcardSearch.length && query.searchString.startsWith('#')) {
            query.searchString = query.searchString.substring(1);
            this.isWildCardEnabled = true
        }

        query.searchString = query.searchString === this.currentCaseSubject ? '' : query.searchString;
        fireEvent(null, 'setsearchstring' + this.eventCode, query.searchString);
        var footerDataObj = {
            "pageNo": query.pageNo,
            "resultsPerPage": query.resultsPerPage
        };
        fireEvent(null, 'sendpaginationdata' + this.eventCode, footerDataObj);
        var sendToDataSection = {
            "pageNo": query.pageNo,
            "aggregations": query.aggregations
        }
        fireEvent(null, 'sendtodatasection' + this.eventCode, sendToDataSection);
        var sendToSortData = {
            "sortby": query.sortby
        }
        fireEvent(null, 'sendsortdata' + this.eventCode, sendToSortData);
        var advSearchObj = {
            "exactPhrase": query.exactPhrase,
            "withOneOrMore": query.withOneOrMore,
            "withoutTheWords": query.withoutTheWords,
            "withWildcardSearch": query.withWildcardSearch
        }
        fireEvent(null, 'advsearchdata' + this.eventCode, advSearchObj);
        fireEvent(null, 'languagedata' + this.eventCode, query.language);
      
        let counter = event.target.getAttribute("data-counter");
        let endpointer = event.target.getAttribute("data-endpoint");
        let total = event.target.getAttribute("data-totalresults");

        this.bookmark_clicked = true
        
        fireEvent(null, 'closesavedbmark' + this.eventCode, false);
        document.body.style.position = 'relative';
        document.body.classList.remove('su__overflow-hidden');
        this._searchString = query.searchString;
        this.sortByCheck = query.sortby;
        this.exactPhrase = query.exactPhrase;
        this.withOneOrMore = query.withOneOrMore;
        this.withoutTheWords = query.withoutTheWords;
        this.withWildcardSearch = query.withWildcardSearch;
        this.pageSize = query.resultsPerPage;
        this.selectedTypeFilter = query.aggregations && JSON.stringify(query.aggregations);
        this.from = query.from;
        this._counter = counter;
        this.totalResults = total;
        this._endPointPagination = endpointer;
        this.pageNum = query.pageNo;
        this._paginationList = JSON.parse(event.target.getAttribute("data-pagelist"));
        this.isFreshSearch = -1;
        if (this.customSettingsFilled && this.bearer) {
            this.getData(null, 'bookmarkSearch');
            this.noBookmarkSaved = false
        }
    }
    showClearFilterMethod(d) {
        this.showClearFiltersButton = d;
        fireEvent(null, 'showclearfilterbtn' + this.eventCode, this.showClearFiltersButton);
    }
    handleDataFromSU(event) {
        let dataToBeSentToHeaderSUComponent = {
            showClearFiltersButton: this.showClearFiltersButton,
            recorId: this.recordId, aggregationsData: this.aggregationsData,
            selectedStickyFilter: this.selectedStickyFilter,
            showFilter: this.showFilter,
            tabsFilter: this.tabsFilter,
            bookmarkList: this.bookmarkSearches
        }
        fireEvent(null, 'dataFromContainer' + this.eventCode, dataToBeSentToHeaderSUComponent);
        if (event === 'header')
            this.hideDataSection = true;
    }
    removefromlocal(data) {
        this.removeBookmarksList(data);
        fireEvent(null, 'bmarkslist' + this.eventCode, this.bookmarkSearches);
    }
    sendBookmarkList() {
        fireEvent(null, 'transssferlist' + this.eventCode, this.bookmarkSearches);
    }
    saveToLocalMethod(data) {
        this.bookmarkName = data;
        this.saveToLocal(data);
    }

    tabClickedMethod(data) {
        this.active = data;
        this.from = 0;
        this.pageNum = 1;
        this._counter = 1;

        this.selectedTypeFilter = JSON.stringify(data);
        this.setPagination(this.pageSize, this.pageNum)
        this.getData(null, 'search');
        this.goToTopFunc();
    }

    //Adding checkboxSelection event from suFilterSection
    checkboxSelectedEvent() {
        this.getData(null, 'pageChange');
    }

    handleCaseCommentEmailEvent(event) {
        try {
            window.gza('linkSharingViaEmail', {
                caseId: this.recordId,
                id: event.id,
                caseNumber: this.currentCaseNumber,
                subject: this.currentCaseSubject,
                searchString: this.searchString,
                object: event.objName,
                url: this.url,
                index: event.sourceName,
                title: event.ptitle,
                author: this.currentUserEmail
            });
        } catch (error) {
            console.error("An error occurred while calling window.gza:", error);
        }
    }
    

    handleFilterSectionEvent(event) {
        this.pagingAggregation = event.pagingAggregation;
        this.key = event.key;
        this.searchFilterString = event.searchFilterString;
        this.getData(null, event.searchFilterString);

    }

    handleAttachToCaseEvent(event) {
        try {
            this.responseListDataBck = JSON.parse(JSON.stringify(this.responseListData));
        } catch (error) {
            console.error("An error occurred while creating a deep copy:", error);
        }
        this.responseListData = [];
        try {
            this.responseListData = JSON.parse(JSON.stringify(this.responseListDataBck));
        } catch (error) {
            console.error("An error occurred while creating a deep copy:", error);
            
        }
        
        this.responseListData[event.index].showDetachButton = event.attached ? true : false;
        this.responseListData[event.index].showAttachButton = event.attached ? false : !(this.responseListData[event.index].record.merge);
        if (event.childindex >= 0) {
            this.responseListData[event.index].record.hits[event.childindex].showDetachButton = event.attached ? true : false;
            this.responseListData[event.index].record.hits[event.childindex].showAttachButton = event.attached ? false : !(this.responseListData[event.index].record.hits[event.childindex].record.merge);
        }
        try {
            event.attached && window.gza('attachToCaseComment', {
                searchString: this.searchString,
                id: event._id,
                articleId: event.Id || event._id,
                url: event.url,
                t: this.responseListData[event.index] && this.responseListData[event.index].record && this.responseListData[event.index].record.highlight && this.responseListData[event.index].record.highlight.TitleToDisplayString[0] ? this.responseListData[event.index].record.highlight.TitleToDisplayString[0] : this.responseListData[event.index].record.href,
                subject: this.currentCaseSubject,
                caseNumber: this.currentCaseNumber,
                index: event.sourceName,
                type: event.objName,
                author: this.currentUserEmail
            });
        } catch (error) {
            console.error("An error occurred while calling window.gza:", error);
        }
        
    }

    handleCopyLinkEvent(evt) {
        try {
            window.gza('copyToClipboard', {
                caseId: this.recordId,
                id: evt.id,
                caseNumber: this.currentCaseNumber,
                subject: this.currentCaseSubject,
                searchString: this.searchString,
                object: evt.objName,
                index: evt.sourceName,
                url: evt.plink,
                title: evt.ptitle,
                author: this.currentUserEmail
            });
        } catch (error) {
            console.error("An error occurred while calling window.gza:", error);
        }
        
    }

    handleSendLinkEvent(event) {
        try {
            window.gza('linkSharingViaCaseComment', {
                caseId: this.recordId,
                id: event.id,
                caseNumber: this.currentCaseNumber,
                subject: this.currentCaseSubject,
                searchString: this.searchString || this.currentCaseSubject,
                object: event.objName,
                index: event.sourceName,
                url: event.url,
                title: event.title,
                author: this.currentUserEmail
            });
        } catch (error) {
            console.error("An error occurred while calling window.gza:", error);

        }
        
    }
    langSelecetedMethod(data) {
        this.translationObject = {}
        if (data) {
            this.defaultlanguage = data.defaultLang
            updateTranslation(window.scConfiguration.language, this.defaultlanguage);
            try {
                this.translationObject = JSON.parse(JSON.stringify(translationObject));
            } catch (error) {
                console.error("An error occurred while creating a deep copy:", error);
            }
            
        }
    }
    selectChangeMethod(event) {
        this.pageSize = event.pagesize;
        this.pageNum = event.pageNum;
        this._counter = 1;
        this.from = ((this.pageNum - 1) * this.pageSize);
        this.getData(null, 'pageChange');
        this.goToTopFunc();
    }
    checkTypeFromSUSortBy(event) {
        this.sortByCheck = event;
        this.from = 0;
        this.pageNum = 1;
        this._counter = 1;
        this.setPagination(this.pageSize, this.pageNum)
        if (this.customSettingsFilled && this.bearer)
            this.getData(null, 'sortBy');
    }
    handleAdvanceSearch(event) {
        this._firstStickyLabel = [];
        this.from = 0;
        this.pageNum = 1;
        this._counter = 1;
        this.exactPhrase = event.exactPhrase;
        this.withOneOrMore = event.withOneOrMore;
        this.withoutTheWords = event.withoutTheWords;
        this.isFreshSearch = -1;
        this.withWildcardSearch = event.withWildcardSearch;
        this.isWildCardEnabled = event.isWildCardEnabledfromas;
        if(this.isWildCardEnabled){
            this._searchString = event.withWildcardSearch
        }
        // add into sticky facets
        if (this.exactPhrase) { this.firstStickyLabel.push({ "key": "exact Phrase", "value": this.exactPhrase }); }
        if (this.withOneOrMore) {
            this.firstStickyLabel.push({ "key": "with One Or More", "value": this.withOneOrMore });
        }
        if (this.withoutTheWords) { this.firstStickyLabel.push({ "key": "without The Words", "value": this.withoutTheWords }); }
        if(this.withWildcardSearch){ 
            this.firstStickyLabel.push({ "key": "With the wildcard search", "value": this.withWildcardSearch });
            this.isWildCardEnabled = true;
        }
        // Sticky label from adb search
        this.advSearchFilter = this.firstStickyLabel;
        fireEvent(null, 'advsearchstickyfltr' + this.eventCode, this.advSearchFilter);
        this.setPagination(this.pageSize, this.pageNum);
        if (this.customSettingsFilled && this.bearer) {
            this.getData(null, 'pageChange');
        }
    }

    handleClearSearch() {
        this._searchString = this.caseSubjectVal;
    }

    handleSearchPageEvent(obj) {
        if ((obj.isFreshSearch === -1 && obj.searchString && obj.searchString.length)
            || (obj.isFreshSearch !== -1)) {
            this._searchString = obj.searchString;
            this.isFreshSearch = obj.isFreshSearch === -1 ? obj.isFreshSearch : this.isFreshSearch;
            this.from = 0;
            this.pageNum = 1;
            this._counter = 1;
            this.setPagination(this.pageSize, this.pageNum);
            if (this.customSettingsFilled && this.bearer)
                this.getData(null, 'pageChange',obj.isActiveSearch);

        }
    }


    saveToLocal() {
        var a;
        try {
            a = JSON.parse(localStorage.getItem('bookmark_searches_' + this.uid) || "[]");
        } catch (error) {
            console.error("An error occurred while parsing the JSON from local storage:", error);
        }
        a.push({
            title: this.bookmarkName,
            href: this.searchQuery && JSON.stringify(this.searchQuery),
            counter: this.counter,
            endpoint: this.endPointPagination,
            totalresults: this.totalResults,
            pagelist:this.paginationList &&  JSON.stringify(this.paginationList)
        });
        localStorage.setItem("bookmark_searches_" + this.uid, JSON.stringify(a));
        this._bookmarkSearches = a;
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
    }

    removeBookmarksList(deleteList) {
        for (var j = 0; j < deleteList.length; j++) {
            let item = deleteList[j];
            let a;
            try {
                a = JSON.parse(localStorage.getItem('bookmark_searches_' + this.uid) || '[]');
            } catch (error) {
                console.error("An error occurred while parsing the JSON from local storage:", error);
            }

            let index = -1;
            for (var i = 0; i < a.length; i++) {
                if (a[i].title === item.title && a[i].href === item.href) {
                    index = i;
                    break;
                }
            }
            if (index > -1) a.splice(index, 1);
            localStorage.setItem("bookmark_searches_" + this.uid, JSON.stringify(a));
        }
        let c;
        try{
          c = JSON.parse(localStorage.getItem('bookmark_searches_' + this.uid) || "[]");
        }catch(error){
            console.error("An error occurred while parsing the JSON from local storage:", error);
        }
        
        let checkboxes = this.template.querySelectorAll('[data-id="checkbox"]')
        for (i = 0; i < checkboxes.length; i++) {
            if (checkboxes[i].checked) {
                checkboxes[i].checked = false;
            }
        }
        this._bookmarkSearches = c;
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

    setResults(hits) {
        let KnowledgeArticle = [];
        checkArticle({ caseIdd: this.recordId })
            .then((result) => {
                for (let i = 0; i < result.length; i++) {
                    KnowledgeArticle.push(result[i].KnowledgeArticleId);
                }
                //    Add additional key value pair
                if (hits.length)
                    this.showAttachToCase(hits, KnowledgeArticle);

                this.responseListData = [...this.responseListData];
            })
            .catch((error) => {
                this.error = error;
                console.log("error", error)
            });
    }

    showAttachToCase(hits, knowledgeArticle) {
        hits.forEach((value) => {
            if (knowledgeArticle.indexOf(value.record._id.substring(0, 18)) > -1) {
                value.attached = true;
                value.showAttachButton = false;
                value.showDetachButton = value.record.LinkViaAttachArticle;
            } else {
                value.attached = false;
                value.showAttachButton = value.record.LinkViaAttachArticle && !(value.record && value.record.merge > 0);
                value.showDetachButton = false;
            }
            if (value.record.hits && value.record.hits.length) {
                this.showAttachToCase(value.record.hits, knowledgeArticle)
            }
        });
    }

    async getData(argument, searchType, activeSearch) {
        this.loading = 'su__loading';
        this.suResultsLoader = true;
        this.selectedTypeFilter = argument && argument.aggregations ? argument.aggregations : this.selectedTypeFilter;
        let selectedFilterDataLength = JSON.parse(JSON.stringify(this.selectedTypeFilter));
        if(selectedFilterDataLength && selectedFilterDataLength.length != 0){
            this.noGpt = false;
            fireEvent(null, 'showHideGpt' + this.eventCode, this.noGpt );
        }
        this.filterSorting = argument && argument.filterSorting ? argument.filterSorting : false;
        searchType = argument ? 'search' : searchType;
        this.from = argument && argument.filterChecked ? 0 : this.from;
        this.pageNum = argument && argument.filterChecked ? 1 : this.pageNum;
        this._counter = argument && argument.filterChecked ? 1 : this.counter;
        var runLoader = '';
        const isSearchStringEmpty = !this._searchString || this._searchString === "";
        const isCaseSubjectDefined = this.caseSubjectVal !== undefined || this.caseSubjectInUtilityBar !== undefined;
        const isCaseSubjectMatchingSearch = this.caseSubjectVal === this._searchString || this.caseSubjectInUtilityBar === this._searchString;

        if (((isSearchStringEmpty && isCaseSubjectDefined) || isCaseSubjectMatchingSearch) && !activeSearch) {
            if (this.caseSubjectInUtilityBar) {
                this._searchString = this.caseSubjectInUtilityBar;
            } else {
                this._searchString = this.caseSubjectVal || '';
            }
            this.default_search = true;
        } else {
            this.noGpt = false;
            fireEvent(null, 'showHideGpt' + this.eventCode, this.noGpt);
            this.default_search = false;
        }
        document.body.style['overflow-y'] = 'unset';
        if (searchType === 'bookmark') {
            this.pageNum = this.pageNum ? this.pageNum : 1;
            this.pageSize = this.defaultPageSize ? this.defaultPageSize : 10;
        }
        var startTime = new Date();
        if (runLoader === 'true') {
            if (!this.filterSortingLoading) {
                this.loadingResult = 0;
            }
        }

        var searchText = '';
        searchText = this.searchString;
        if (searchText !== "" && searchText != null) {
            var EmailregexSlash = '\\\\';
            var regexSlash = new RegExp("\\\\", 'g');
            searchText = searchText.replace(regexSlash, EmailregexSlash);
            var Emailregex = '\\"';
            var re = /^['"][^"]*["']$/;
            if (!re.test(searchText)) {
                if (searchText[0] !== '#') {
                    searchText = searchText.replace(/"/g, Emailregex);
                }
            }
        }
        this._searchString = searchText;
        if (searchText !== "" && searchText != null) {
            searchText = searchText.trim();
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
        var filterSelect = {
            "Contentname": filterData && JSON.parse(filterData).length !== 0 && JSON.parse(filterData)[0].filter ? JSON.parse(filterData)[0].filter[0] : null,
            "checked": true
        }
        if (filterData && filterData.length !== 0 && filterSelect.Contentname && filterSelect.Contentname.indexOf("merged_") > -1) {
            var data = JSON.parse(filterData);
            data[0].filter = arr;
            if (this.checkHere) {
                filterData = this.aggregationsData;
                this.checkHere = false;
            } else {
                filterData = JSON.stringify(data);
            }
        }
        this.viewSavePopup = false;
        try {
            if (filterData && JSON.parse(filterData).length !== 0) {
                this._multiVersion = false;
            } else {
                this._multiVersion = true;
            }
        } catch (error) {
            console.log(error)
        }
        data = {
            "searchString": searchText,
            "from": this.from || 0,
            "pageNo": parseInt(this.pageNum, 10),
            "sortby": this.sortByCheck,
            "orderBy": "desc",
            "resultsPerPage": parseInt(this.pageSize, 10),
            "exactPhrase": this.exactPhrase,
            "withOneOrMore": this.withOneOrMore,
            "withoutTheWords": this.withoutTheWords,
            "withWildcardSearch": this.withWildcardSearch,
            "aggregations": filterData ? JSON.parse(filterData) : [], //@@@
            "referrer": document.referrer,
            "recommendResult": "",
            "indexEnabled": this.contentSourceTab,
            "sid": window._gr_utility_functions ? window._gr_utility_functions.getCookie("_gz_taid") : "",
            "cookie": '',
            "language": localStorage.getItem('language') || 'en',
            "getAutoTunedResult": true,
            "versionResults": this.multiVersion,
            "mergeSources": this.multiVersion,
            "caseId": this.recordId
        };
        let query = JSON.parse(JSON.stringify(data));

        if (this.caseSubjectVal !== this.searchString && this.isWildCardEnabled) {
            query.searchString = this.searchString;
            let hashExists = query.searchString.charAt(0)
            if (hashExists === '#') {
                query.searchString = searchText
            } else {
                query.searchString = '#' + searchText;
            }
            data = JSON.parse(JSON.stringify(query));
        }
        this.searchQuery = query;
        let result = await makeSearchCall(data);
        if (result.statusCode !== 402) {
            var total = result.result.total;
            if (result.statusCode === 200 || result.statusCode === 400) {
                this._mergeResultHits = result.result.hits;

                fireEvent(this.pageRef, 'API_RESULT' + this.eventCode, { result, querySent: data, selectedTypeFilter: this.selectedTypeFilter });
                if (this.exactPhrase !== "" || this.withOneOrMore !== "" || this.withoutTheWords !== "" || this.withWildcardSearch !== "") {
                    this.advancedSearchSelected = true;
                } else {
                    this.advancedSearchSelected = false;
                }

                this.preview = result.searchClientSettings.preview ? true : false;
                this.contentTag = result.searchClientSettings.contentTag ? true : false;
                this.showSummary = result.searchClientSettings.showMore ? true : false;
                if (result.searchClientSettings.hideAllContentSources && this.aggregationsData && this.aggregationsData.length && JSON.parse(filterData)) {
                    let selectedFilters = JSON.parse(filterData);
                    this.allContentHideFacet = selectedFilters.filter(f => f.type === this.aggregationsData[0].key).length ? false : true;
                } else this.allContentHideFacet = result.searchClientSettings.hideAllContentSources || false;
                this.summaryCollapsible = result.searchClientSettings.showMore ? true : false;
                this.maxlength = result.searchClientSettings.minSummaryLength;
                this.languageEnabled = result.searchClientSettings.languageManager;
                this.caseSelection = JSON.parse(result.searchClientSettings.SCsalesforceConsoleConfigurations).caseSelection === 1;
                this.showCaseNumber = JSON.parse(result.searchClientSettings.SCsalesforceConsoleConfigurations).caseNumberView === 1;
                this.urlOpensInNewTab = JSON.parse(result.searchClientSettings.SCsalesforceConsoleConfigurations).searchResultsOpensNewBrowserTab === 1;
                this.showViewedResults = result.searchClientSettings.ViewedResults === 1 ? 'su__viewed-results su__h-100' : 'su__h-100';
                this.hiddenFacet = result.searchClientSettings.hiddenFacet && result.searchClientSettings.hiddenFacet.length !== 0 ? true : false;
                this.mergeResults = result.searchClientSettings.mergeSources ? true : false;
                this.titleToShow = result.searchClientSettings.mergeSourcesTypeIndex ? true : false;
                this.resultperpageForAutocomplete = result.searchClientSettings.autoComplete ? result.searchClientSettings.autoComplete : "10";
                this.gptContext = result.searchClientSettings && result.searchClientSettings.gptConfig && result.searchClientSettings.gptConfig.gptContext;
                this.gptActive = result.searchClientSettings && result.searchClientSettings.gptConfig && result.searchClientSettings.gptConfig.gptActive;
                this.gptLinks = result.searchClientSettings && result.searchClientSettings.gptConfig && result.searchClientSettings.gptConfig.gptLinks;
                if(this.gptActive){
                    fireEvent(null, 'searchCallMade' + this.eventCode, true);
                }
                try {
                    if (this.mergeResults && JSON.parse(data).mergeSources) {
                        this.resultsInAllContentSources = true;
                        this.mergeSourcesTypeIndex = this.titleToShow ? true : false;
                    } else {
                        this.resultsInAllContentSources = false;
                    }
                } catch (error) {
                    console.log(error)
                }

                if (this.hiddenFacet) {
                    this.hideFacetsValues = {
                        hiddenFacet: this.hiddenFacet,
                        values: result.searchClientSettings.hiddenFacet
                    }
                }

            }
            this.totalResults = total;
            var endTime = new Date();
            var Seconds_from_T1_to_T2 = (endTime.getTime() - startTime.getTime()) / 1000;
            var seconds_Between_Dates = Math.abs(Seconds_from_T1_to_T2);
            this.searchResultTime = seconds_Between_Dates;
            this.resultTime = this.searchResultTime;
            this.resultCountReturned = result.result.hits.length;
            if (!this.filterSorting) {
                (this.searchString || this.exactPhrase) && this.handleTrackAnalytics({ type: 'search' });
            }
            var aggrData = result.aggregationsArray;

            try {
                if (result.merged_facets && JSON.parse(result.merged_facets).length) {
                    this.mergedArray = JSON.parse(result.merged_facets || '[]');
                    let self = this;
                    this.mergedArray && this.mergedArray.forEach(function (o) {
                        mergeFilters(o, aggrData, false, self);
                    });
                    this.mergedArrayStr = JSON.stringify(this.mergedArray);
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
                            }
                        });
                    }
                    if (!found) {
                        this.hideFacetsValues.values.forEach(val => {
                            if (agg.key === val) {
                                Object.assign(aggrData[index], { 'values': [] });
                            }
                        });
                    }
                });
            }
            let hiddenAggLength = aggrData.filter((f, index) => index !== 0 || !f.values || !f.values.length)
            if (this.hideFacetsValues && this.hideFacetsValues.hiddenFacet && (this.active === 'all_Content' || (Array.isArray(this.active) && !this.active.length))) {
                if (hiddenAggLength.length === this.hideFacetsValues.values.length) {
                    this._allAreHidden = true;
                }
            }
            else {
                this._allAreHidden = false;
            }
            this._setArray = aggrData;
            this.searchSummaryLength = result.searchClientSettings.minSummaryLength;



            if (result.result.hits && result.result.hits.length) {
                this.manipulateSearchHits(result.result.hits, result.searchClientSettings)
                this.responseListData = result.result.hits;
            }

            if (this.totalResults === 0) {
                this._noResultMsg = "No results found. Kindly search with some other keywords";
            }

            this.setStickyFacets(this.setArray);
            this.setFilters(this.setArray);
            this.fullWidthResults();

            this.setClearFilters();
            if (result.result && result.result.hits && result.result.hits.length) {
                this.setResults(result.result.hits);
            }
            this.setPagination(this.pageSize, this.pageNum);
            this.handleDataFromSU();
            this.setFlag = false;//@@@@
            if (!filterData || !filterData.length) fireEvent(this.pageRef, "clearFilterDataEvent" + this.eventCode, null);
            fireEvent(null, 'setAggregationsData' + this.eventCode, this.aggregationsData);
            this.loading = '';
            this.suResultsLoader = false;
            this.firstLoadContainer = false;
        }
    }
    

    manipulateSearchHits(hits, searchClientSettings) {
        for (var i = 0; i < hits.length; i++) {
            const currentHit = hits[i];
            const uniqueHitId = new Date();
            currentHit.uniqueHitId = i + uniqueHitId;

            if (hits[i].highlight.TitleToDisplay[0] == null || hits[i].highlight.TitleToDisplay[0] === '') {
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
                Object.assign(hits[i], { 'collapseVersionOverlayId': 'collapseVersion-2-' + hits[i]._id } + '_overlay');
            }
            if (this.summaryCollapsible && hits[i].highlight.SummaryToDisplay.join('').length > (this.maxlength + hits[i].highlight.SummaryToDisplay.length * 5)) {
                hits[i].showMore = true;
                hits[i].highlight.SummaryToDisplayMax = hits[i].highlight.SummaryToDisplay.join('#').split('#');
                hits[i].highlight.SummaryToDisplay = hits[i].highlight.SummaryToDisplay.join('#').substring(0, this.maxlength).split('#');
            } else hits[i].showMore = false;
            if (this.linkSharingOptions && this.linkSharingOptions.length) {
                let currentIndex = i;
                var foundObj = this.linkSharingOptions.filter((r) => r.selected_object === hits[currentIndex].objName && r.content_source_label === hits[currentIndex].sourceLabel)
                foundObj.forEach(obj => {
                    if (obj.result_action_id === 1)
                        hits[currentIndex].LinkViaEmail = obj.status;
                    if (obj.result_action_id === 2)
                        hits[currentIndex].LinkViacaseComment = obj.status;
                    if (obj.result_action_id === 3)
                        hits[currentIndex].LinkViaAttachArticle = obj.status;
                    hits[currentIndex].merge = obj.merge;
                    hits[currentIndex].shareResultLink = hits[currentIndex].LinkViaEmail || hits[currentIndex].LinkViacaseComment;

                })
            }
            if(hits[i].icon){
                Object.assign(hits[i], { 'iconPresent': true });
            }else {
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
            Object.assign(hits[i], { 'allowLinkOpenNewTab': true });
            if ((hits[i].objName.toLowerCase().slice(-5) === '__kav' || hits[i].objName.toLowerCase() === 'case') && !this.urlOpensInNewTab)
                Object.assign(hits[i], { 'allowLinkOpenNewTab': false });

            /** added code from setResults **/
            var recordsWrap = {};
            var styleColor;
            /**
             *  Salesforce Object Key Prefix
                Account - 001
                Knowledge Article Version - ka0-kzz
                Case - 500
                Contact - 003
             */
            const regex = /^(k[a-z][0-9]|k[a-z][a-z])\w*$/;
            
            // var restrictSfObjectsPreview = hits[i].Id && hits[i].Id.startsWith('ka0') && hits[i].Id.startsWith('500') && hits[i].Id.startsWith('003') && hits[i].Id.startsWith('001');
            var restrictSfObjectsPreview = typeof hits[i]?.Id === 'string' && regex.test(hits[i]?.Id) && hits[i]?.Id.startsWith('500');
            if (searchClientSettings.preview && (hits[i].href.toLowerCase().includes('youtube.com') || (hits[i].href.toLowerCase().includes('vimeo.com') && /^\d+$/.test(hits[i].href.split('.com/')[1])) || (restrictSfObjectsPreview != false && hits[i].href.includes(window.location.origin))))
                hits[i].showPreview = true;
            else hits[i].showPreview = false;

            if (hits[i].highlight.TitleToDisplayString === this.caseSubjectVal)
                styleColor = 'background-color:#D4E8FF';
            else styleColor = 'background-color:none';

            if (hits[i].metadata && hits[i].metadata.length) {
                hits[i].metadata.sort((a, b) => {
                    return a.value.length - b.value.length;
                })
                for (let j = 0; j < hits[i].metadata.length; j++) {
                    const currentMetadataHit = hits[i].metadata;
                    const uniqueMetadataHitId = new Date();
                    currentMetadataHit.uniqueMetadataHitId = i + j + uniqueMetadataHitId;

                    if (hits[i].metadata[j].value.length && (hits[i].metadata[j].value[0] === "" || hits[i].metadata[j].value[0].length === 0)) {
                        hits[i].metadata[j].noMetadataValue = true;
                        

                    } else{
                        hits[i].metadata[j].noMetadataValue = false;
                        if (hits[i].metadata[j].value.length > 2) {
                            hits[i].metadata[j].seeMore = true;
                            hits[i].metadata[j].keyIndex = `su__${hits[i].metadata[j].key}${i}`;
                            let valueLength = hits[i].metadata[j].value.length
                            hits[i].metadata[j].original = JSON.parse(JSON.stringify((hits[i].metadata[j].value)));
                            hits[i].metadata[j].value.splice(2, valueLength);

                        } else {
                            hits[i].metadata[j].seeMore = false;
                        }
                    }
                }
            }

            let dataContext = hits[i]._id;
            // added for testing
            if (dataContext && dataContext.startsWith("k"))
                recordsWrap = ({ "showArticles": true, "styleColor": styleColor, "record": hits[i] });
            else
                recordsWrap = ({ "showArticles": false, "styleColor": styleColor, "record": hits[i] });
            hits[i] = recordsWrap;

            /** added code from setResults **/

            if (hits[i].record.hits && hits[i].record.hits.length) {
                this.manipulateSearchHits(hits[i].record.hits, searchClientSettings);
            }
        }
    }
    setFilters(setArray) {
        var self = this;
        var filterValue = [{ "displayName": "All Content", "Contentname": "all_Content", "immediateParent": "_all" }];
        this.tabsFilter = filterValue.concat((setArray && setArray.length && setArray[0].values) || []);
        this._aggregationsData = setArray;
        this._aggregationsData = this.aggregationsData.filter(function (facet) {
            if (!facet.values || !facet.values.length) {
                facet.hasValues = false;
                return true;
            }
            facet.hasValues = true;
            if (self.searchFilterString !== "") {
                if (facet.key === self.key) {
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
            else if (self.searchFilterString === "" && self.key !== "") {
                Object.assign(facet, { 'filterSuggest': "no-result" });
                Object.assign(facet, { 'filterSuggestions': [] });
                Object.assign(facet, { 'suggestionLength': false });
                self.suggestionLength = false;

            }
            if (facet.key !== 'post_time' && facet.key !== 'CreatedDate' && facet.label !== 'Created Date') {
                Object.assign(facet, { 'post_Time_Enable': true });
            } else {
                Object.assign(facet, { 'post_Time_Enable': false });
            }
            if (facet.label === 'Sources') {
                Object.assign(facet, { 'enable_Custom_Sort': true });
            } else {
                Object.assign(facet, { 'enable_Custom_Sort': false });
            }
            if (facet.label === 'Created Date') {
                Object.assign(facet, { 'enable_Created_Date': true });
            } else {
                Object.assign(facet, { 'enable_Created_Date': false });
            }
            if (facet.sort === 'custom') {
                Object.assign(facet, { 'customSortingClass': 'font-12 su__color-black su__px-4 su__py-2 su__cursor su__bg-gray-hover su__filters-sort-active' });
            } else {
                Object.assign(facet, { 'customSortingClass': 'font-12 su__color-black su__px-4 su__py-2 su__cursor su__bg-gray-hover' });
            }
            if (facet.sort === 'term_asc') {
                Object.assign(facet, { 'term_ascSortingClass': 'font-12 su__color-black su__px-4 su__py-2 su__cursor su__bg-gray-hover su__filters-sort-active' });
            } else {
                Object.assign(facet, { 'term_ascSortingClass': 'font-12 su__color-black su__px-4 su__py-2 su__cursor su__bg-gray-hover' });
            }
            if (facet.sort === 'term_desc') {
                Object.assign(facet, { 'term_descSortingClass': 'font-12 su__color-black su__px-4 su__py-2 su__cursor su__bg-gray-hover su__filters-sort-active' });
            } else {
                Object.assign(facet, { 'term_descSortingClass': 'font-12 su__color-black su__px-4 su__py-2 su__cursor su__bg-gray-hover' });
            }
            if (facet.sort === 'count_desc') {
                Object.assign(facet, { 'count_descSortingClass': 'font-12 su__color-black su__px-4 su__py-2 su__cursor su__bg-gray-hover su__filters-sort-active' });
            } else {
                Object.assign(facet, { 'count_descSortingClass': 'font-12 su__color-black su__px-4 su__py-2 su__cursor su__bg-gray-hover' });
            }
            if (facet.sort === 'count_asc') {
                Object.assign(facet, { 'count_ascSortingClass': 'font-12 su__color-black su__px-4 su__py-2 su__cursor su__bg-gray-hover su__filters-sort-active' });
            } else {
                Object.assign(facet, { 'count_ascSortingClass': 'font-12 su__color-black su__px-4 su__py-2 su__cursor su__bg-gray-hover' });
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
            if (facet.values.length > 9 ||  facet.merged) {
                Object.assign(facet, { 'filtersMoreThan9': true });
            } else {
                Object.assign(facet, { 'filtersMoreThan9': false });
            }
            Object.assign(facet, { 'showmorefacetIcon': 'show-more-facetIcon-' + facet.key });
            if (facet.values.length > 9) {
                Object.assign(facet, { 'filtervalues': true });
            } else {
                Object.assign(facet, { 'filtervalues': false });
            }
            Object.assign(facet, { 'showMoreOrder': facet.key + '_filter_' + facet.order + '_showMore' });
            if (facet.key !== '_type') {
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
            Object.assign(facet, { 'facetFilterClass': 'facetIcon-' + facet.key + ' su__d-block su__facet-search-icon ' })
            Object.assign(facet, { 'filterSuggestClass': 'su__search-facet-input su__loading-view' });

            facet.values.forEach(function (filter) {
                if (filter.value === 0) {
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
    getCommunityCustomSettings2(jwtToken) {
        var searchQuery = '';
        if (jwtToken) {
            this.bearer = jwtToken;
            this.customSettingsFilled = true;
            this.selectedTypeFilter = localStorage.getItem("selectedFilter") || "";
            this._bookmarkSearches = JSON.parse(localStorage.getItem('bookmark_searches_' + this.uid) || "[]");
            if (this.bookmarkSearches.length > 0) {
                this.showBookMark = true
                this.isBookmarkExist = true
            }
            else {
                this.showBookMark = false
                this.isBookmarkExist = false
            }
            this.pageNum = 1;
            this._counter = 1;
            this._searchString = searchQuery;
            if (this.customSettingsFilled && this.bearer) {
                this.setFlag = true;
                this.preSelectedFilters = this.recordIddFromUtility ? this.casePreSelectedValues || {} : this.preSelectedFilters;
                this.setPreSelectedFilters().then(() => {
                        if (!this.recordIddFromUtility)
                        this.getData(null, 'search');
                    else {
                        this._searchString = this.caseSubjectInUtilityBar;
                        this.previousCaseId = this._recordId = this.recordIddFromUtility;
                        this.getData(null, 'search');
                    }
                }).catch(error => {
                    this.error = error;
                    console.log(error);
                });
            }
        } else {
            this.customSettingErrorMessage = 'Please configure your SearchUnify and try again.';
        }
    }

    setClearFilters() {
        var eitherOfThreeIsTrue = false;
        this.selectedTypeFilter = typeof this.selectedTypeFilter == 'string' ? this.selectedTypeFilter : JSON.stringify(this.selectedTypeFilter);
        if (JSON.parse(this.selectedTypeFilter || "[]").length || this.exactPhrase !== "" || this.withOneOrMore !== "" || this.withoutTheWords !== "" || this.withWildcardSearch !== "") {
            if (this.exactPhrase !== "" || this.withOneOrMore !== "" || this.withoutTheWords !== "") {
                eitherOfThreeIsTrue = true;
            }
            if (eitherOfThreeIsTrue) {
                this.showClearFiltersButton = true;
            }
            else {
                for (let i = 0; i < JSON.parse(this.selectedTypeFilter).length; i++) {
                    if (JSON.parse(this.selectedTypeFilter)[i].filter || JSON.parse(this.selectedTypeFilter)[i].children || this.exactPhrase !== "" || this.withOneOrMore !== "" || this.withoutTheWords !== "" || this.withWildcardSearch !== "") {
                        this.showClearFiltersButton = true;
                    } else {
                        this.showClearFiltersButton = false;
                    }
                }
            }
        } else {
            this.showClearFiltersButton = false;
        }
    }
    clearFilters() {
        this.selectedTypeFilter = '';
        this.from = 0;
        this.pageNum = "1";
        this._counter = 1;
        this.viewAll = false;
        this.suggestionLength = false
        this.exactPhrase = '';
        this.withOneOrMore = '';
        this.withoutTheWords = '';
        this.withWildcardSearch = '';
        this.advanceSearchEnabled = false;
        this.showClearFiltersButton = false;
        if (this.customSettingsFilled && this.bearer) {
            this.getData(null, 'clearFilter');
        }
        this.active = "all_Content";
    }
    setStickyFacets(setArray) {
        let self = this;
        return new Promise(function (resolve) {
            var stickyArray ;
            try{
                stickyArray = JSON.parse(JSON.stringify(setArray));
            }catch(error){
                console.error("An error occurred while creating a deep copy:", error);
            }
            
            var selectedStickyFilter = stickyArray.filter(function (x) {
                x.tempValues = [];
                if (x.key === '_index') {
                    x.values.forEach(function (o) {
                        if (o.selected) {
                            o.sticky_name = o.displayName.toUpperCase();
                            x.sticky_label = "Tab";
                            x.tempValues.push(o)
                        }
                    });
                }

                x.values.forEach(function (f) {
                    if (f.selected && f.parent !== '_index') {
                        f.sticky_name = f.displayName || f.Contentname;
                        x.tempValues.push(f);
                    }
                    if (f.childArray && (x.order !== 0 || (!f.merged || (f.merged && f.showChild !== 0)))) {
                        self.checkChildArray(x.tempValues, f.childArray, (f.displayName || f.Contentname));
                    }
                })

                if (x.tempValues.length) {
                    try {
                        x.values = JSON.parse(JSON.stringify(x.tempValues || []));
                    } catch (error) {
                        console.error("An error occurred while creating a deep copy:", error);
                    }
                    
                    delete x.tempValues;
                    return x;
                }
                    return false;
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

            exactPhrase ? selectedStickyFilter.unshift({ "key": 'exactPhrase', "label": "With the exact phrase", "values": [{ "selected": true, "Contentname": exactPhrase, "sticky_name" : exactPhrase }] }) : '';
            withOneOrMore ? selectedStickyFilter.unshift({ "key": 'withOneOrMore', "label": "With one or more words", "values": [{ "selected": true, "Contentname": withOneOrMore, "sticky_name": withOneOrMore }] }) : '';
            withoutTheWords ? selectedStickyFilter.unshift({ "key": 'withoutTheWords', "label": "Without the words", "values": [{ "selected": true, "Contentname": withoutTheWords, "sticky_name": withoutTheWords }] }) : '';
            var stickyFilter_label = selectedStickyFilter.map(function (c) { return c.label });
            self.exactPhrase = exactPhrase;
            self.withOneOrMore = withOneOrMore;
            self.withoutTheWords = withoutTheWords;
            self.withWildcardSearch = withWildcardSearch;

            self.stickyFilter_label = stickyFilter_label;
            self.activeSticky = stickyFilter_label[0];
            self.selectedStickyFilter = selectedStickyFilter;
            resolve();
        })
    }

    checkChildArray(tempValues, childArray, name) {
        let self = this;
        childArray.forEach(function (y) {
            if (y.selected) {
                y.pathString = y.path && JSON.stringify(y.path);
                y.sticky_name = name + " > " + (y.displayName || y.Contentname);
                tempValues.push(y);
            }
            if (y.childArray) {
                self.checkChildArray(tempValues, y.childArray, name + " > " + (y.displayName || y.Contentname));
            }
        });
    }
    selectedSticky(event) {
        let label = event.target.getAttribute("data-label");
        this.activeSticky = label;
    }

    setPagination(pageSize, pageNum) {
        var pageNumber = parseInt(pageNum,10);
        var total = this.totalResults;
        this.totalPages = Math.ceil(total / pageSize);
        var pageList = [];
        if (this.totalResults === 0) {
            pageList.push(pageNumber - (pageNumber - this.counter), (pageNumber + 1) - (pageNumber - this.counter), (pageNumber + 2) - (pageNumber - this.counter), (pageNumber + 3) - (pageNumber - this.counter))
            this._paginationList = pageList;
        }
        if (this.totalPages > 0) {
            if (this.totalPages <= 4) {
                var counter = 1;
                for (; counter <= this.totalPages; counter++) {
                    pageList.push(counter);
                }
                this._paginationList = pageList;
            }
            else {
                if (this.counter === pageNumber) {
                    for (var i = pageNumber; i <= this.totalPages; i++) {
                        if (i === pageNumber + 4) {
                            this._endPointPagination = i - 1;
                            break;
                        }
                        if ((i) === this.totalPages) {
                            pageList.push(i);
                            this._endPointPagination = this.totalPages;
                            break;
                        }
                        pageList.push(i);
                    }
                    this._paginationList = pageList;
                } else {
                    if (this.endPointPagination === undefined) {
                    this._counter = pageNumber;
                if (this.counter === pageNumber) {
                    for ( i = pageNumber; i <= this.totalPages; i++) {
                        if (i === pageNumber + 4) {
                            this._endPointPagination = i - 1;
                            break;
                        }
                        if ((i) === this.totalPages) {
                            pageList.push(i);
                            this._endPointPagination = this.totalPages;
                            break;
                        }
                        pageList.push(i);
                    }
                    this._paginationList = pageList;
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
                this._paginationList = pageList;
                }
                if (pageNumber === this.counter + 4) {
                    this._counter = pageNumber;
                }
            }
        }
        this.disableEnableActions(pageNumber);
    }
    disableEnableActions(pageNumber) {
        let buttons = this.template.querySelectorAll('[data-id="paginationButton"]');
        buttons.forEach(bun => {
            if (bun.value === pageNumber) {
                bun.style = "background:#0070d2;color:#fff";

            } else {
                bun.style = "background:white;color:#808080";
            }
        });
    }


    goToTopFunc() {
        const activeCase = this.template.querySelector('[data-id="activeCase"]');
        if (activeCase) {
            activeCase.setAttribute('tabindex', '-1');
            var goToTop = this.template.querySelector('[data-id="searchUnifyContainer"]');
            if (goToTop) {
                goToTop.scrollIntoView();
            }
            activeCase.focus();
        }
    }
    handleChange(event) {
        this.sortByCheck = event.detail.value;
        this.from = 0;
        this.pageNum = "1";
        this._counter = 1;
        this.setPagination(this.pageSize, this.pageNum)
        if (this.customSettingsFilled && this.bearer)
            this.getData(null, 'pageChange');
    }

    

    updateContactHandler(event) {
        this.responseListData = [...event.detail.records]
    }
    stringChangedFromBanner(searchString) {
        this._searchString = searchString.trim().length ? searchString : this.caseSubjectVal;
        if(this.isWildCardEnabled){
            this.withWildcardSearch = this.searchString
        }
    }
    setPreSelectedFilters() {
        let self = this;
        return new Promise(function (resolve) {
            self.selectedTypeFilter = [];
            self.sortByCheck = '_score';
            self.withWildcardSearch = '';
            self.withOneOrMore = '';
            self.withoutTheWords ='';
            self.exactPhrase = '';
            self.pageSizeAdvFiltr = 10;
            self.isWildCardEnabled = false;
            if (!self.myCustomSettings) {
                resolve()
            }
            var c_filterSourceFieldValue = typeof self.myCustomSettings.su_vf_console__FilterFieldName__c == 'undefined' ? '' : self.myCustomSettings.su_vf_console__FilterFieldName__c;
            var c_filterSourceName = typeof self.myCustomSettings.su_vf_console__FilterSourceName__c == 'undefined' ? '' : self.myCustomSettings.su_vf_console__FilterSourceName__c;
            if (!c_filterSourceFieldValue.length || !c_filterSourceName.length) {
                resolve();
            }

            if (self.preSelectedFilters) {
                var filterNameSf = c_filterSourceFieldValue ? c_filterSourceFieldValue.split(",") : [];
                var filterSourceSu = c_filterSourceName ? c_filterSourceName.split(",") : [];
                filterSourceSu.forEach(function (field, i) {
                    if (self.preSelectedFilters[filterNameSf[i]]) {
                        let filter = {
                            "type": field,
                            "filter": self.preSelectedFilters[filterNameSf[i]].split(";")
                        };
                        self.selectedTypeFilter.push(filter);
                    }
                });
                self.selectedTypeFilter =self.selectedTypeFilter &&  JSON.stringify(self.selectedTypeFilter);
                resolve();
            } else {
                self.selectedTypeFilter = self.selectedTypeFilter && JSON.stringify(self.selectedTypeFilter);
                resolve();
            }
        });
    }

    handleAHCaseSentiment(url){
        this.sentimentEmojiUrl = url;
    }
}