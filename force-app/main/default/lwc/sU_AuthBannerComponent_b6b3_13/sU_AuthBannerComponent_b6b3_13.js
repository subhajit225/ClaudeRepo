import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { registerListener, unregisterListener, fireEvent, scriptsLoaded, getCommunitySettings ,updateTranslation, translationObject, getURLParameter } from 'c/authsupubsub_b6b3_13';
import { NavigationMixin } from 'lightning/navigation';

export default class SU_AuthBannerComponent extends NavigationMixin(LightningElement) {
    xmlHttp = new XMLHttpRequest();
    @track newResult;
    @api searchString;
    smartAgg;
    @track smartFacets = true;
    @track endPointLoaded = false
    @track productClass;
    @track smartFacetClick = false;
    @track selectedTypeFilterJSON;
    @track productContentnameWithSmartFacet;
    @api pagesize;
    @track showViewedResults = '';
    searchStringBackup;
    @api placeHolderText;
    @api advanceFilterData;
    @api advanceFilterValue;
    @api isEnableTitleRedirect;
    @api eventCode;
    @api urlsopensinnewtab;
    searchString2;
    @track withwildsearch
    defaultlanguage = 'en';
    @api isWildCardEnabled;
    customSettingsFilled;
    customSettingErrorMessage = '';
    //searchString;
    currentCommunityURL;
    @track endPoint = '';
    @track bearer = '';
    @track uid = '';
    buttonPress = false;
    @track linkToOpen = null;
    urlredirect;
    firstLoad = 1;
    redirectThroughUrl = false;
    timer = 0;
    aggregation;// object type declaration
    @track currentString = '';
    delayCounter = 0;
    index = -1;
    @track autosuggestList = [];
    recommendedSearches;
    sIndex = -1;
    lastSuggestionIndex = -1;
    baseSearchString = '';
    @api translationObject;
    @api sendDataAttributes;
    @api autoSuggestionActive = false;
    @track currentCommURL;
    @track pageNum;
    @track exactPhrase;
    @track withOneOrMore;
    @track withoutTheWords;
    @track withWildcardSearch;
    @track sortByCheck;
    @track selectedTypeFilter = [];
    @track pageName;
    @track lastSlashIndex
    @track sendData;
    @track aggrValueData
    @track latestHashUrl = '';
    @track resultsPerPage;
    isDataLoaded;
    @track commBaseURL;



    get autosuggestListLength() {
        return this.autosuggestList.Length;
    }
    get getCurrentStringLength() {
        return this.currentString.length > 0 ? true : false;
    }
    get isSmartAggregationsNotEmpty() {
        return this.isDataLoaded && this.smartAgg && this.smartAgg.length > 0;
    }
    get directionText (){
        if(this.defaultlanguage && this.defaultlanguage =='ar'){
            return 'RTL'
        }else{
            return 'LTR'
        }
    }
    get searchboxClass(){
        if(this.defaultlanguage && this.defaultlanguage =='ar'){
            return 'slds-col slds-large-size--1-of-1 slds-small-size--1-of-1 slds-medium-size--1-of-1 su__rtl-search su__width-100'
        }else{
            return 'slds-col slds-large-size--1-of-1 slds-small-size--1-of-1 slds-medium-size--1-of-1 su__width-100'
        }
    }
    get innerSearchBoxClass(){
        if(this.defaultlanguage && this.defaultlanguage =='ar'){
        return'slds-col slds-large-size--1-of-1 slds-small-size--1-of-1 slds-medium-size--1-of-1 su-searchBoxContainer su__rtl-search'
        }else{
            return'slds-col slds-large-size--1-of-1 slds-small-size--1-of-1 slds-medium-size--1-of-1 su-searchBoxContainer '
        }
    }

    errorCallback(error, stack) {
        console.log("[error], [stack]", error, stack);
    }

    handleSearchStringChange(event) {
        this.searchString = event.target.value;
        this.searchString2 = this.searchString;
        this.baseSearchString = event.target.value;
        this.sIndex = -1;
        fireEvent(null, 'stringChangedFromBanner', event.target.value);
    }


    async connectedCallback() {
        this.loadScriptStyle = await scriptsLoaded();
        this.pagesize = window.scConfiguration && window.scConfiguration.noOfAutoSuggestions;
        this.endPointLoaded = true;
        this.getCommunityCustomSettings = await getCommunitySettings();
        this.setCommunityCustomSettings(this.getCommunityCustomSettings);
        if (window.scConfiguration && window.scConfiguration.language) {
            var selectedLanguages = JSON.parse(window.scConfiguration.language).config;
            this.defaultlanguage = selectedLanguages['defaultLanguage'] && selectedLanguages['defaultLanguage'].code;
            updateTranslation(window.scConfiguration.language || {},this.defaultlanguage);
        }
        this.searchString = getURLParameter("searchString");
        this.setSearchString2(this.searchString);
        registerListener('setsearchstring', this.setSearchString2, this);
        registerListener('wildcardEnabled', this.hasWildCardSearch, this);
        registerListener('languageselected', this.langSelecetedMethodBanner, this);
        registerListener('trackAnalyticsAutocomplete', this.trackAnalyticsHome, this);
    }

    disconnectedCallback() {
        unregisterListener('setsearchstring', this.setSearchString2, this);
        unregisterListener('wildcardEnabled', this.hasWildCardSearch, this);
        unregisterListener('languageselected', this.langSelecetedMethodBanner, this);
        unregisterListener('trackAnalyticsAutocomplete', this.trackAnalyticsHome, this);
    }

    setCommunityCustomSettings(result) {
        if (result && result.isCustomSettingFilled) {
            this.endPoint = result.endPoint;
            this.bearer = result.token;
            this.uid = result.uid;
            this.customSettingsFilled = result.isCustomSettingFilled;
            this.currentCommURL = result.currentCommURL;
            this.commBaseURL = result.commBaseURL;
        } else {
            this.customSettingsFilled = result.isCustomSettingFilled;
            this.customSettingErrorMessage = result.customSettingErrorMessage;
        }
    }

    trackAnalyticsHome(event){
        if (event.type == 'autocompleteFromHome') {
            event.type = 'search';
            event.objToSend.searchString = this.searchString2;
        }
        window.gza(event.type, event.objToSend);
    }
    
    hasWildCardSearch(data) {
        this.isWildCardEnabled = data;
    }
    langSelecetedMethodBanner(data){
        this.translationObject = {}
        if (data) {
            this.defaultlanguage = data.defaultLang
            updateTranslation(window.scConfiguration.language, this.defaultlanguage);
            this.translationObject = JSON.parse(JSON.stringify(translationObject));
        }
    }

    setSearchString2(data) {
        this.searchString2 = data;
    }
    
    bannerUrlManipulation() {
        this.pageName = this.currentCommURL && this.currentCommURL.substring(this.commBaseURL.length);
        this.pageNum = getURLParameter('pageNum') != "" ? getURLParameter('pageNum') : "1";
        this.exactPhrase = getURLParameter('exactPhrase') != "" ? getURLParameter('exactPhrase') : "";
        this.withOneOrMore = getURLParameter('withOneOrMore') != "" ? getURLParameter('withOneOrMore') : "";
        this.withoutTheWords = getURLParameter('withoutTheWords') != "" ? getURLParameter('withoutTheWords') : "";
        this.withWildcardSearch = getURLParameter('withWildcardSearch') != "" ? getURLParameter('withWildcardSearch') : "";
        this.sortByCheck = getURLParameter('sortBy') != "" ? getURLParameter('sortBy') : '_score';
        this.pagesize = getURLParameter('resultsPerPage') != "" ? getURLParameter('resultsPerPage') : '10';
        if (!this.smartFacetClick) {
            if (this.advanceFilterData && this.advanceFilterValue) {
                this.selectedTypeFilter = `[{"type": "${this.advanceFilterData}","filter":["${this.advanceFilterValue}"]}]`;
            } else {
                this.selectedTypeFilter = getURLParameter('selectedType') != "" ? getURLParameter('selectedType') : '';
            }
        }
        this.latestHashUrl = '#' + "searchString=" + encodeURIComponent(this.searchString) + "&pageNum=" + this.pageNum + "&sortBy=" + this.sortByCheck + "&orderBy=desc&resultsPerPage=" + this.pagesize + "&exactPhrase=" + this.exactPhrase + "&withOneOrMore=" + this.withOneOrMore + "&withoutTheWords=" + this.withoutTheWords + "&withWildcardSearch=" + this.withWildcardSearch + "&selectedType=" + encodeURIComponent(this.selectedTypeFilter);
    }

    preSelectedBuilderConfig() {
        if (this.advanceFilterData != "" && this.advanceFilterValue != "") {
            var builderAdvanceFilterData = this.advanceFilterData;
            var builderAdvanceFilterValue = this.advanceFilterValue;
            let builderAggData = `[{"type": "${builderAdvanceFilterData}","filter":["${builderAdvanceFilterValue}"]}]`;
            this.selectedTypeFilter = builderAggData;
            this.latestHashUrl = '#' + "searchString=" + getURLParameter('searchString') + "&pageNum=" + getURLParameter('pageNum') + "&sortBy=" + getURLParameter('sortBy') + "&orderBy=desc&resultsPerPage=" + getURLParameter('resultsPerPage') + "&exactPhrase=" + getURLParameter('exactPhrase') + "&withOneOrMore=" + getURLParameter('withOneOrMore') + "&withoutTheWords=" + getURLParameter('withoutTheWords') + "&withWildcardSearch=" + getURLParameter('withWildcardSearch') + "&selectedType=" + encodeURIComponent(this.selectedTypeFilter);
        }
    }
    smartAutocompleteSelection(e) {
        this.smartFacetClick = true;

        const smartIndex = e?.currentTarget?.dataset.smart;
        const filterIndex = e?.currentTarget?.dataset.filter;

        if (smartIndex !== undefined && filterIndex !== undefined) {
            const smart = this.smartAgg[smartIndex];
            const filter = smart?.values[filterIndex];

            if (smart && filter ) {
                filter.selected = !filter.selected; // Toggle the filter.selected property directly

                if (filter.selected) {
                    filter.selectedClass = 'su__product-sugg-category su__cursor su__product-active su__font-13';
                } else {
                    filter.selectedClass = 'su__product-sugg-category su__cursor su__font-13';
                }

                // Update this.selectedTypeFilter based on active buttons
                this.selectedTypeFilter = this.smartAgg.reduce((result, smartItem) => {
                    smartItem.values.forEach(filterItem => {
                        if (filterItem.selectedClass === 'su__product-sugg-category su__cursor su__product-active su__font-13') {
                            const existingTypeIndex = result.findIndex(item => item.type === filterItem.parent);
                            if (existingTypeIndex !== -1) {
                                // If the type already exists, check if the filter.Contentname exists
                                const filterNameIndex = result[existingTypeIndex].filter.indexOf(filterItem.Contentname);
                                if (filterNameIndex === -1) {
                                    // If the filter.Contentname doesn't exist, add it to the filter array
                                    result[existingTypeIndex].filter.push(filterItem.Contentname);
                                }
                            } else {
                                // If the type doesn't exist, create a new entry for it and add it to the result array
                                result.push({
                                    type: filterItem.parent,
                                    filter: [filterItem.Contentname],
                                });
                            }
                        }
                    });
                    return result;
                }, []);

                this.smartAgg = [...this.smartAgg];
            }
            document.cookie = "smartFacets=false; expires=Thu, 01 Jan 9999 00:00:00 UTC; path=/;";
            this.smartFacets = false;
        }
    }



    submitForm(event) {
        this.autoSuggestionActive = false;
        if (this.isEnableTitleRedirect && this.linkToOpen) {
            this.searchString2 = this.searchStringBackup;
            this.searchString = this.searchString2
            this.autoSuggestionAnalytics(this.sendDataAttributes);  
            window.open(this.linkToOpen, "_blank");
            this.linkToOpen = null;
        } else {
            if (this.searchString2.length > 1) {
                event.preventDefault();
                this.buttonPress = true;
                this.autosuggestList = [];

                if (window.location.hash == "") {
                    this.searchString = getURLParameter('searchString') != "" ? getURLParameter('searchString') : this.searchString2;
                    if (this.advanceFilterData && this.advanceFilterValue ) {
                        this.preSelectedBuilderConfig();
                    }
                    this.bannerUrlManipulation();
                    this.smartFacetClick = false;
                    window.location.href = this.currentCommURL + "/" + this.latestHashUrl;

                }
                else {
                    this.searchString = this.searchString2;
                    this.bannerUrlManipulation();
                }
                if (this.template.querySelector(`[data-id="su-suggestions"]`) && this.template.querySelector(`[data-id="su-suggestions"]`).classList) {
                    this.template.querySelector(`[data-id="su-suggestions"]`).classList.add('su-hidePanel');
                }
               this.fireSearchPageEventBannerToContainer();
            } else {
                const toastEvent = new ShowToastEvent({
                    title: 'You must enter at least 2 characters to search',
                    message: '',
                    variant: 'warning'
                });
                this.dispatchEvent(toastEvent);
                return;
            }
           
        }
    }

    fireSearchPageEventBannerToContainer() {
        fireEvent(null, 'searchPage', { searchString: this.searchString2, isFreshSearch: -1, autoSuggestionActive: this.autoSuggestionActive });
    }

    autoSuggestionAnalytics(e) {
        var aggrValue = "[]";
        var sourceType = this.advanceFilterData;
        var sourceValue = this.advanceFilterValue;
        var filterData;
        if ( sourceType !== "" && sourceValue !== "") {
            filterData = { "sourceType": sourceType, "valueFilter": sourceValue };
            this.createAggregationFilter(filterData);
            aggrValue = this.aggregation || '[]';
            this.aggrValueData = aggrValue;
        }
        
        this.sendData = {
            'page_no': 1,
            'filter': getURLParameter('selectedType') ? JSON.parse(getURLParameter('selectedType')) : aggrValue && JSON.parse(aggrValue),
            'result_count': this.autosuggestList && this.autosuggestList.length,
            'conversion': [{
                rank: parseInt(e.currentTarget ? e.currentTarget.dataset.rank : e.rank) + 1,
                url: e.currentTarget ? e.currentTarget.dataset.url : e.url,
                subject: e.currentTarget ? (e.currentTarget.dataset.subject || e.currentTarget.dataset.url) : e.convSub,
                es_id: (e.currentTarget ? e.currentTarget.dataset.index : e.index) + '/' + (e.currentTarget ? e.currentTarget.dataset.type : e.type) + '/' + encodeURIComponent(e.currentTarget ? e.currentTarget.dataset.value : e.value),
              
            }]
        }
        if(this.isEnableTitleRedirect){
            fireEvent(null, 'trackAnalyticsAutocomplete', {
                type: 'autocompleteFromHome', objToSend: this.sendData
            });
        }
    }

    invokeWorkspaceAPI(methodName, methodArgs) {
        return new Promise((resolve, reject) => {
            const apiEvent = new CustomEvent("internalapievent", {
                bubbles: true,
                composed: true,
                cancelable: false,
                detail: {
                    category: "workspaceAPI",
                    methodName: methodName,
                    methodArgs: methodArgs,
                    callback: (err, response) => {
                        if (err) {
                            return reject(err);
                        } else {
                            return resolve(response);
                        }
                    }
                }
            });
            window.dispatchEvent(apiEvent);
        });
    }

    autoSuggestionClick(e) {
        if (e.currentTarget) {
            var autoBoxTitleRecommended = e.currentTarget.dataset.suggest;
        }
        var href = e.currentTarget ? e.currentTarget.dataset.url : e.url;
        if(!this.isEnableTitleRedirect||e.currentTarget.dataset.recent){
        this.searchString = e.currentTarget ? (e.currentTarget.dataset.subject || e.currentTarget.dataset.id) : e.convSub;
        }
        if (!autoBoxTitleRecommended) {
            this.autoSuggestionAnalytics(e);
        }
        if (this.template.querySelector(`[data-id="su-suggestions"]`) && this.template.querySelector(`[data-id="su-suggestions"]`).classList) {
            this.template.querySelector(`[data-id="su-suggestions"]`).classList.add('su-hidePanel');
        }
        if (this.isEnableTitleRedirect && href) {
            window.open(href, "_blank");
            this.autoSuggestionActive = false;
        } else {
            this.searchString2 = this.searchString;
            fireEvent(null,'setsearchstring', this.searchString);
            this.submitForm(e);
        }

    }

    fillSearchboxFunc(event) {
        this.smartFacetClick = false
        var valueToBeFilled = event.currentTarget.dataset.id;
        this.searchString = valueToBeFilled;
        let searchPageUrl = window.location.href.split('#')[0].split('?')[0] == this.currentCommunityURL ? true : false
        if (!searchPageUrl) this.redirectThroughUrl = true;
        else this.redirectThroughUrl = false;
        this.searchButtonPressFunc();
        this.fillSearchBoxEventFire();
    }
    fillSearchBoxEventFire() {
        window.location.hash = encodeURIComponent("searchString=" + encodeURIComponent(this.searchString) + "&pageNum=" + getURLParameter("pageNum") + "&sortBy=" + getURLParameter("sortBy") + "&orderBy=desc&resultsPerPage=" + getURLParameter("resultsPerPage") + "&pageSizeAdv=" + getURLParameter("pageSizeAdv") + "&exactPhrase=" + encodeURIComponent(getURLParameter('exactPhrase')) + "&withOneOrMore=" + encodeURIComponent(getURLParameter('withOneOrMore')) + "&withoutTheWords=" + encodeURIComponent(getURLParameter('withoutTheWords')) + "&selectedType=" + encodeURIComponent(getURLParameter('selectedType')));
        fireEvent(null, 'searchPage', { searchString: this.searchString }); this.mouseleft();
    }

    searchButtonPressFunc() {
        var SearchQuery = this.searchString;
        if (SearchQuery != null && SearchQuery != '' && SearchQuery != undefined) {
            SearchQuery = SearchQuery.trim();
            if (SearchQuery.length > 1 && this.template.querySelector('[data-id="su-suggestions"]') && this.template.querySelector('[data-id="su-suggestions"]').classList) {
                this.template.querySelector('[data-id="su-suggestions"]').classList.add('su-hidePanel');
                this.index = -1;
                clearTimeout(this.timer);
            }
        }
    }

    createAggregationFilter(filterData) {
        if (filterData !== undefined && filterData !== null) {
            if (this.searchString !== undefined && this.searchString.length !== 0) {
            }
            var sourceType = filterData.sourceType;
            var valueType = filterData.valueFilter;
            var totalResult = this.pagesize;
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
                    this.aggregation = finalJson;
                }
            }
            if (totalResult != undefined && totalResult != '') {
                this.pagesize = totalResult;
            }
        }
    }
    navigateToWebPage() {
        this[NavigationMixin.Navigate]({
            "type": "standard__webPage",
            "attributes": {
                "url": this.urlredirect
            }
        },
            true
        );
    }

    navigateToSearchPage(url) {
        this[NavigationMixin.Navigate]({
            "type": "standard__webPage",
            "attributes": {
                "url": url
            }
        },
            true
        );
    }



    enterKeySearch(event) {
        let self = this;
        self.index = -1;
        sessionStorage.setItem('searchValue', event.target.value);
        var SearchQuery = self.searchString;
        if (SearchQuery != null && SearchQuery != '' && SearchQuery != undefined) {
            SearchQuery = SearchQuery.trim();
        }
        if (event.keyCode == 13 && self.searchString2.length < 2) {
            const toastEvent = new ShowToastEvent({
                title: 'You must enter at least 2 characters to search',
                message: '',
                variant: 'warning'
            });
            self.dispatchEvent(toastEvent);
            return;
        }

        if (SearchQuery != null && SearchQuery != '' && SearchQuery != undefined && SearchQuery.length > 1) {
            if (event.keyCode == 13) {
                fireEvent(null, 'setsearchstring', self.searchString2);
                self.submitForm(event);
                if (self.template.querySelector(`[data-id="su-suggestions"]`) && self.template.querySelector(`[data-id="su-suggestions"]`).classList) {
                    self.template.querySelector(`[data-id="su-suggestions"]`).classList.add('su-hidePanel');
                }

                clearTimeout(self.timer);
            } else if (event.keyCode != 37 && event.keyCode != 38 && event.keyCode != 39 && event.keyCode != 40) {
                self.currentString = self.searchString;
                self.autoSuggestionActive = false;
                self.linkToOpen = null;
                var delayCounter = self.delayCounter;
                var timer = self.timer;
                self.buttonPress = false;
                clearTimeout(timer);
                if (delayCounter == 0) {
                    self.delayCounter = 1;
                    self.xmlHttp.abort();
                    timer = window.setTimeout(function () {
                        SearchQuery = self.searchString;
                        if (SearchQuery) {
                            SearchQuery = SearchQuery.trim();
                        }
                        if (SearchQuery != '' && self.customSettingsFilled && self.bearer) {
                            self.autosearchFunc('autosuggestion', 'false');
                        }
                        clearTimeout(timer);
                        self.timer = null;
                    }, 1000);
                    self.index = -1;
                    self.timer = timer;
                    self.delayCounter = 0;
                }
            }
        }
    }

    async autosearchFunc(searchType, runLoader) {
        this.autoSuggestionActive = false;
        this.isDataLoaded = false;
        this.sIndex = -1;
        let self = this;
        self.autosuggestList = [];
        var resultPerSize = window.scConfiguration && window.scConfiguration.noOfAutoSuggestions;
        var aggrValue = "[]";
        if (resultPerSize === 'undefined' || resultPerSize === undefined) { resultPerSize = '10'; } //default handling
        var sourceType = this.advanceFilterData;
        var sourceValue = this.advanceFilterValue;
        var filterData;
        if (searchType === 'autosuggestion' && sourceType !== "" && sourceValue !== "") {
            filterData = { "sourceType": sourceType, "valueFilter": sourceValue };
            this.createAggregationFilter(filterData);
            aggrValue = this.aggregation || '[]';
            this.aggrValueData = aggrValue;
        }
        
        let sendSmartFacets;
        try {
            sendSmartFacets = (window._gr_utility_functions && window._gr_utility_functions.getCookie("smartFacets") == "" || window._gr_utility_functions && window._gr_utility_functions.getCookie("smartFacets") == "true") && localStorage.getItem("AutoLearning") == "true";
        } catch (error) {
            console.log("[error]", error);
        }

        this.smartFacets = sendSmartFacets
        var data = JSON.stringify({
            "searchString": this.searchString.trim(),
            "from": 0,
            "pageNum": 1,
            "sortby": "_score",
            "orderBy": "desc",
            "resultsPerPage": parseInt(resultPerSize),
            "aggregations": getURLParameter('selectedType') ? JSON.parse(getURLParameter('selectedType')) : JSON.parse(aggrValue),
            "referrer": "",
            "exactPhrase": getURLParameter('exactPhrase'),
            "withOneOrMore": getURLParameter('withOneOrMore'),
            "withoutTheWords": getURLParameter('withoutTheWords'),
            "recommendResult": "",
            "indexEnabled": false,
            "smartFacets": this.smartFacets,
            "sid": window._gr_utility_functions.getCookie("_gz_taid")+ "$Enter$",
            "uid": this.uid,
            "language": localStorage.getItem('language') || 'en',
            "autocomplete": true
        });
        let query = JSON.parse(data);
        if (this.isWildCardEnabled || (window.sessionStorage.getItem('sessionToggle') === '1' || window.sessionStorage.getItem('sessionToggle') === 'true')) {
            query.searchString = this.searchString;
            let hashExists = query.searchString.charAt(0)
            if (hashExists === '#') {
                query.searchString = this.searchString
            } else {
                query.searchString = '#' + this.searchString;
            }
            data = JSON.stringify(query);
        }
       // var xmlHttp = new XMLHttpRequest();
        var url = this.endPoint + "/search/SUSearchResults";
        self.xmlHttp.withCredentials = true;
        self.xmlHttp.open("POST", url, true);
        self.xmlHttp.setRequestHeader("Accept", "application/json");
        self.xmlHttp.setRequestHeader('Authorization', 'bearer ' + this.bearer);
        self.xmlHttp.setRequestHeader('Content-Type', 'application/json');
        self.xmlHttp.send(data);
        self.xmlHttp.onreadystatechange = async function () {
            if (self.xmlHttp.readyState === 4) {
                if (self.xmlHttp.status === 200) {
                    var result = JSON.parse(self.xmlHttp.response);
                    if (result.statusCode != 402) {
                        self.showViewedResults = result.searchClientSettings && result.searchClientSettings.ViewedResults == 1 ? 'su__viewed-results' : '';
                        var total = result.result.total;
                        self.totalResults = total;
                        if (searchType === 'autosuggestion' && !self.buttonPress) {
                            self.autosuggestList = result.result.hits;
                            self.recommendedSearches = result.recentSearchHistory;
                            self.smartAgg = result.smartAggregations && result.smartAggregations.map((aggregation) => {
                                const updatedValues = aggregation.values.map((value) => {
                                    const selectedClass = value.selected
                                        ? 'su__product-sugg-category su__cursor su__product-active su__font-13'
                                        : 'su__product-sugg-category su__cursor su__font-13';

                                    return {
                                        ...value,
                                        selectedClass: selectedClass,
                                    };
                                });

                                return {
                                    ...aggregation,
                                    values: updatedValues,
                                };
                            });
                            let smartAggSlice = self.smartAgg && JSON.parse(JSON.stringify(self.smartAgg));

                            if (smartAggSlice && smartAggSlice.length) {
                                smartAggSlice.forEach(function (s) {
                                    if (s.values.length > 3) {
                                        s.values = s.values.slice(0, 3)
                                    }
                                });
                            }
                            self.smartAgg = smartAggSlice;
                            self.isDataLoaded = true;
                            if (self.recommendedSearches) {
                                for (var i = 0; i < self.recommendedSearches.length; i++) {
                                    Object.assign(self.recommendedSearches[i], { 'recommendedRecentSearch': self.recommendedSearches[i].type == 'recentSearch' ? true : false });
                                    Object.assign(self.recommendedSearches[i], { 'recommendedAutoSuggestion': self.recommendedSearches[i].type == 'autoSuggestion' ? true : false });
                                }
                            }
                            
                            if (self.autosuggestList) {
                                for (var i = 0; i < self.autosuggestList.length; i++) {
                                    if (self.autosuggestList[i].icon) {
                                        Object.assign(self.autosuggestList[i], { 'iconPresent': true });
                                    } else {
                                        Object.assign(self.autosuggestList[i], { 'iconPresent': false });
                                    }
                                    for (var j = 0; j < self.autosuggestList[i].autosuggestData.length; j++) {
                                        if(self.autosuggestList[i].autosuggestData[j].value && self.autosuggestList[i].autosuggestData[j].value[0] && self.autosuggestList[i].autosuggestData[j].value[0].length===0){
                                            Object.assign(self.autosuggestList[i].autosuggestData[j], {'metaValue':false})
                                        }else{
                                            Object.assign(self.autosuggestList[i].autosuggestData[j], {'metaValue':true})
                                        }
                                        
                                        if (self.autosuggestList[i].autosuggestData[j].key == 'post_time') {
                                            Object.assign(self.autosuggestList[i].autosuggestData[j], { 'metaKeyValBoolean': true });
                                            Object.assign(self.autosuggestList[i].autosuggestData[j], { 'metaKeyVal': 'Created Date' });
                                        }
                                        else {
                                            if (self.autosuggestList[i].autosuggestData[j].key != 'Title') {
                                                Object.assign(self.autosuggestList[i].autosuggestData[j], { 'metaKeyValBoolean': false });
                                                Object.assign(self.autosuggestList[i].autosuggestData[j], { 'metaKeyVal': self.autosuggestList[i].autosuggestData[j].key });
                                            }
                                            if (self.autosuggestList[i].autosuggestData[j].key === 'Title') {
                                                self.autosuggestList[i].autosuggestData.splice(j);
                                            }
                                        }
                                    }
                                    Object.assign(self.autosuggestList[i], { 'autosuggestTitleToDisplay': self.autosuggestList[i].highlight.TitleToDisplay[0] || self.autosuggestList[i].href });
                                }
                            }

                            if (self.autosuggestList.length > 0 && self.template.querySelector(`[data-id="autosuggestElement"]`) !== null && self.template.querySelector(`[data-id="autosuggestElement"]`) !== undefined && self.template.querySelector(`[data-id="su-suggestions"]`).classList) {
                                self.template.querySelector(`[data-id="su-suggestions"]`).classList.remove('su-hidePanel');
                                self.template.querySelector(`[data-id="autosuggestElement"]`).style.display = 'block';
                                if (self.template.querySelector(`[data-id="autosuggestAutoElement"]`) !== null && self.template.querySelector(`[data-id="autosuggestAutoElement"]`) !== undefined) {
                                    self.template.querySelector(`[data-id="autosuggestAutoElement"]`).style.display = 'block';
                                }
                            }
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
   
    mouseleft() {
        let self = this;
        setTimeout(function () {
            let smartLength = self.smartAgg;
            if (smartLength && smartLength.length && self.smartFacetClick) {
                return;
            }
            else if (self.template.querySelector('[data-id="autosuggestElement"]') !== null && self.template.querySelector('[data-id="autosuggestElement"]') !== undefined) {
                self.template.querySelector('[data-id="autosuggestElement"]').style.display = 'none';
                self.autosuggestList = [];
            }
        }, 500);
    }
    onfocus() {
        var input = this.template.querySelector('[data-id="form-search"]');
        if (input.getAttribute("autocomplete") !== "off") {
            input.setAttribute("autocomplete", "off");
        }
    }
    deleteSearch() {
        this.searchString2 = '';
        this.searchString = '';
        this.autosuggestList = [];
    }
    setFocus(element) {
        setTimeout(() => {
            element && element.focus && element.focus();
        })
    }

    decodeEntityCharacters(inputText){
        let decodedValue = document.createElement("textarea");
        decodedValue.innerHTML = inputText;
        this.searchString2 = decodedValue.value;
    }

    handleKeyDown(e) {
        if (this.template.querySelectorAll(".su-autoSuggest-element")) {
            if (this.template.querySelectorAll(".su-autoSuggest-element").length != 0) {
                var autoSuggestElement = this.template.querySelectorAll(".su-autoSuggest-element");
                this.lastSuggestionIndex = this.template.querySelectorAll(".su-autoSuggest-element").length - 1;
                if (e.keyCode === 40) {
                    if (this.sIndex === -1) {
                        var x = autoSuggestElement[++this.sIndex];
                        if (x && x.classList) {
                            x.classList.add("su__autoSuggestion-active");
                            this.autoSuggestionActive = true;
                            this.sendDataAttributes = {
                                index: x.getAttribute('data-index'),
                                type: x.getAttribute('data-type'),
                                recordid: x.getAttribute('data-recordid'),
                                rank: x.getAttribute('data-rank'),
                                convUrl: x.getAttribute('data-url'),
                                convSub: x.getAttribute('data-subject'),
                                autoTuned: x.getAttribute('data-auto'),
                                url: x.getAttribute('data-url'),
                                value: x.getAttribute('data-value'),
                            }
                        }
                        this.onfocus();
                        if (this.template.querySelector(`[data-id="autosuggestElement"]`) && this.template.querySelector(".su__autoSuggestion-active") && this.template.querySelector(".su__autoSuggestion-active").offsetTop && this.template.querySelector(".su__autoSuggestion-active").offsetHeight) {
                            this.template.querySelector(`[data-id="autosuggestElement"]`).scrollTop = this.template.querySelector(".su__autoSuggestion-active").offsetTop + this.template.querySelector(".su__autoSuggestion-active").offsetHeight - this.template.querySelector(`[data-id="autosuggestElement"]`).offsetHeight / 2;

                        }
                        if (x && x.getAttribute('data-id')) {
                            this.searchString2 = x.getAttribute('data-id').replace(/(<([^>]+)>)/ig, '');
                            this.decodeEntityCharacters(this.searchString2);
                        }
                        if (this.isEnableTitleRedirect) {
                            this.searchStringBackup = this.searchString
                        }
                        this.searchString = this.searchString2;
                        if (this.template.querySelectorAll('lightning-input[data-id="searchBoxInput"]')) {
                            let searchInputbox = this.template.querySelectorAll(`lightning-input[data-id="searchBoxInput"]`);
                            this.setFocus(searchInputbox);
                        }
                    }
                    else if (this.sIndex === this.lastSuggestionIndex) {
                        this.linkToOpen = null;
                        this.searchString2 = this.baseSearchString;
                        this.searchString = this.searchString2;
                        var x = autoSuggestElement[this.sIndex];
                        if (x && x.classList) {
                            x.classList.remove("su__autoSuggestion-active");
                            this.autoSuggestionActive = false;
                            this.sendDataAttributes = {
                                index: x.getAttribute('data-index'),
                                type: x.getAttribute('data-type'),
                                recordid: x.getAttribute('data-recordid'),
                                rank: x.getAttribute('data-rank'),
                                convUrl: x.getAttribute('data-url'),
                                convSub: x.getAttribute('data-subject'),
                                autoTuned: x.getAttribute('data-auto'),
                                url: x.getAttribute('data-url'),
                                value: x.getAttribute('data-value'),
                            }
                        }
                        this.sIndex = -1;
                        if (this.template.querySelector(`[data-id="autosuggestElement"]`) && this.template.querySelector(".su__autoSuggestion-active") && this.template.querySelector(".su__autoSuggestion-active").offsetTop && this.template.querySelector(".su__autoSuggestion-active").offsetHeight) {
                            this.template.querySelector(`[data-id="autosuggestElement"]`).scrollTop = this.template.querySelector(".su__autoSuggestion-active").offsetTop + this.template.querySelector(".su__autoSuggestion-active").offsetHeight - this.template.querySelector(`[data-id="autosuggestElement"]`).offsetHeight / 2;
                        }
                        if (this.template.querySelectorAll('lightning-input[data-id="searchBoxInput"]')) {
                            let searchInputbox = this.template.querySelectorAll('lightning-input[data-id="searchBoxInput"]');
                            this.setFocus(searchInputbox);

                        }
                    }
                    else {
                        if (autoSuggestElement && autoSuggestElement[this.sIndex] && autoSuggestElement[this.sIndex].classList) {
                            autoSuggestElement[this.sIndex].classList.remove("su__autoSuggestion-active");
                        }
                        var x = autoSuggestElement[++this.sIndex];
                        if (x && x.classList) {
                            x.classList.add("su__autoSuggestion-active");
                            this.autoSuggestionActive = true;
                            this.sendDataAttributes = {
                                index: x.getAttribute('data-index'),
                                type: x.getAttribute('data-type'),
                                recordid: x.getAttribute('data-recordid'),
                                rank: x.getAttribute('data-rank'),
                                convUrl: x.getAttribute('data-url'),
                                convSub: x.getAttribute('data-subject'),
                                autoTuned: x.getAttribute('data-auto'),
                                url: x.getAttribute('data-url'),
                                value: x.getAttribute('data-value'),
                            }
                        }
                        this.onfocus();
                        if (x && x.getAttribute('data-id')) {
                            this.searchString2 = x.getAttribute('data-id').replace(/(<([^>]+)>)/ig, '');
                            this.decodeEntityCharacters(this.searchString2);
                        }
                        this.searchString = this.searchString2;
                        if (this.template.querySelector(`[data-id="autosuggestElement"]`) && this.template.querySelector(".su__autoSuggestion-active") && this.template.querySelector(".su__autoSuggestion-active").offsetTop && this.template.querySelector(".su__autoSuggestion-active").offsetHeight) {
                            this.template.querySelector(`[data-id="autosuggestElement"]`).scrollTop = this.template.querySelector(".su__autoSuggestion-active").offsetTop + this.template.querySelector(".su__autoSuggestion-active").offsetHeight - this.template.querySelector(`[data-id="autosuggestElement"]`).offsetHeight / 2;
                        }
                        if (this.template.querySelectorAll('lightning-input[data-id="searchBoxInput"]')) {
                            let searchInputbox = this.template.querySelectorAll('lightning-input[data-id="searchBoxInput"]');
                            this.setFocus(searchInputbox);
                        }
                    }
                    if (this.template.querySelector(".su__autoSuggestion-active")) {
                        this.linkToOpen = this.template.querySelector(".su__autoSuggestion-active").getAttribute('data-url');
                    }
                } else if (e.keyCode === 38) {
                    if (this.sIndex === -1) {
                        this.sIndex = this.lastSuggestionIndex;
                        var x = autoSuggestElement[this.sIndex];
                        if (x && x.classList) {
                            x.classList.add("su__autoSuggestion-active");
                            this.autoSuggestionActive = true;
                            this.sendDataAttributes = {
                                index: x.getAttribute('data-index'),
                                type: x.getAttribute('data-type'),
                                recordid: x.getAttribute('data-recordid'),
                                rank: x.getAttribute('data-rank'),
                                convUrl: x.getAttribute('data-url'),
                                convSub: x.getAttribute('data-subject'),
                                autoTuned: x.getAttribute('data-auto'),
                                url: x.getAttribute('data-url'),
                                value: x.getAttribute('data-value'),
                            }
                        }
                        this.onfocus();
                        if (x && x.getAttribute('data-id')) {
                            this.searchString2 = x.getAttribute('data-id').replace(/(<([^>]+)>)/ig, '');
                            this.decodeEntityCharacters(this.searchString2);
                        }
                        this.searchString = this.searchString2;
                        if (this.template.querySelector(`[data-id="autosuggestElement"]`) && this.template.querySelector(".su__autoSuggestion-active") && this.template.querySelector(".su__autoSuggestion-active").offsetTop && this.template.querySelector(".su__autoSuggestion-active").offsetHeight) {
                            this.template.querySelector(`[data-id="autosuggestElement"]`).scrollTop = this.template.querySelector(".su__autoSuggestion-active").offsetTop + this.template.querySelector(".su__autoSuggestion-active").offsetHeight - this.template.querySelector(`[data-id="autosuggestElement"]`).offsetHeight / 2;
                        }
                        if (this.template.querySelectorAll('lightning-input[data-id="searchBoxInput"]')) {
                            let searchInputbox = this.template.querySelectorAll('lightning-input[data-id="searchBoxInput"]');
                            this.setFocus(searchInputbox);
                        }
                    }
                    else if (this.sIndex === 0) {
                        this.linkToOpen = null;
                        var x = autoSuggestElement[this.sIndex];
                        if (x && x.classList) {
                            x.classList.remove("su__autoSuggestion-active");
                            this.autoSuggestionActive = false;
                            this.sendDataAttributes = {
                                index: x.getAttribute('data-index'),
                                type: x.getAttribute('data-type'),
                                recordid: x.getAttribute('data-recordid'),
                                rank: x.getAttribute('data-rank'),
                                convUrl: x.getAttribute('data-url'),
                                convSub: x.getAttribute('data-subject'),
                                autoTuned: x.getAttribute('data-auto'),
                                url: x.getAttribute('data-url'),
                                value: x.getAttribute('data-value'),
                            }
                        }
                        this.sIndex = -1;
                        this.searchString2 = this.baseSearchString;
                        this.searchString = this.searchString2;
                        if (this.template.querySelector(`[data-id="autosuggestElement"]`) && this.template.querySelector(".su__autoSuggestion-active") && this.template.querySelector(".su__autoSuggestion-active").offsetTop && this.template.querySelector(".su__autoSuggestion-active").offsetHeight) {
                            this.template.querySelector(`[data-id="autosuggestElement"]`).scrollTop = this.template.querySelector(".su__autoSuggestion-active").offsetTop + this.template.querySelector(".su__autoSuggestion-active").offsetHeight - this.template.querySelector(`[data-id="autosuggestElement"]`).offsetHeight / 2;
                        }
                        if (this.template.querySelectorAll('lightning-input[data-id="searchBoxInput"]')) {
                            let searchInputbox = this.template.querySelectorAll('lightning-input[data-id="searchBoxInput"]');
                            this.setFocus(searchInputbox);
                        }
                    }
                    else {
                        if (autoSuggestElement && autoSuggestElement[this.sIndex] && autoSuggestElement[this.sIndex].classList) {
                            autoSuggestElement[this.sIndex].classList.remove("su__autoSuggestion-active");
                        }
                        var x = autoSuggestElement[--this.sIndex];
                        if (x && x.classList) {
                            x.classList.add("su__autoSuggestion-active");
                            this.autoSuggestionActive = true;
                            this.sendDataAttributes = {
                                index: x.getAttribute('data-index'),
                                type: x.getAttribute('data-type'),
                                recordid: x.getAttribute('data-recordid'),
                                rank: x.getAttribute('data-rank'),
                                convUrl: x.getAttribute('data-url'),
                                convSub: x.getAttribute('data-subject'),
                                autoTuned: x.getAttribute('data-auto'),
                                url: x.getAttribute('data-url'),
                                value: x.getAttribute('data-value'),
                            }
                        }
                        this.onfocus();
                        if (x && x.getAttribute('data-id')) {
                            this.searchString2 = x.getAttribute('data-id').replace(/(<([^>]+)>)/ig, '');
                            this.decodeEntityCharacters(this.searchString2);
                        }
                        this.searchString = this.searchString2;
                        if (this.template.querySelector(`[data-id="autosuggestElement"]`) && this.template.querySelector(".su__autoSuggestion-active") && this.template.querySelector(".su__autoSuggestion-active").offsetTop && this.template.querySelector(".su__autoSuggestion-active").offsetHeight) {
                            this.template.querySelector(`[data-id="autosuggestElement"]`).scrollTop = this.template.querySelector(".su__autoSuggestion-active").offsetTop + this.template.querySelector(".su__autoSuggestion-active").offsetHeight - this.template.querySelector(`[data-id="autosuggestElement"]`).offsetHeight / 2;
                        }
                        if (this.template.querySelectorAll('lightning-input[data-id="searchBoxInput"]')) {
                            let searchInputbox = this.template.querySelectorAll('lightning-input[data-id="searchBoxInput"]');
                            this.setFocus(searchInputbox);
                        }
                    }
                    if (this.template.querySelector(".su__autoSuggestion-active")) {
                        this.linkToOpen = this.template.querySelector(".su__autoSuggestion-active").getAttribute('data-url');
                    }
                }
            }
        }
    }
}