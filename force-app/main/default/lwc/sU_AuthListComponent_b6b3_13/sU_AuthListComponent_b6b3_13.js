import { LightningElement, track, api } from 'lwc';
import { scriptsLoaded, getCommunitySettings  } from 'c/authsupubsub_b6b3_13';
export default class SU_AuthListComponent extends LightningElement {
    firstLoad = true;
    customSettingsFilled;
    autosuggestList = [];
    showDescMetadata = false;
    @api pagesize;
    @api modalopen;
    @api showbody;
    @api opennewtab;
    @api pageheadertitle = "View suggested articles";
    @track currentCommURL;
    @track isShowSearchButton;
    @track showViewedResults = '';
    customSettingErrorMessage = '';
    @track totalResults;
    @track loadingResult = true;
    @api aggregation;
    aggregations;
    communitySettingsLoaded = false;
    @api gotosearchpagemsg = "Go to search result page";
    @track endPoint = '';
    @track bearer = '';
    @track uid = '';
    eventCaseCreatedOnly = false;
    @track currentUserEmail;
    @api showmetadata;
    @api sourcename;
    _searchString;
    @api sourcevalue;
    @track isConversionWithSearch;
    @track endPoint;
    sendAnalytics;
    sendAnalyticsCaseCreatedVal;
    @api noresultfoundmsg = "Sorry, no results found.";
    @track showNoResults;
    @api caseuid;
    @api 
    set sendanalytics(val){
        this.sendAnalytics = val;
        if (this.sendAnalytics) {
            if (this.eventCaseCreatedOnly) {
                var event = 'caseCreated';
                var data = { 'caseUid': this.caseuid, 'subject': this._searchString };
                window.gza && window.gza(event, data);
            } else {
                var event2 = 'search';
                var data2 = { 'searchString': this._searchString, 'resultCount': this.totalResults, 'uid': this.uid, 'filter': this.aggregations ? this.aggregations : '[]' }
                window.gza && window.gza(event2, data2);
            }
        }
    }
    get sendanalytics(){
        return this.sendAnalytics;
    }

    @api 
    set sendanalyticscasecreated(data){
        this.sendAnalyticsCaseCreatedVal = data;
        if(this.sendAnalyticsCaseCreatedVal && !this.eventCaseCreatedOnly){
            var event1 = 'caseCreated';
            var data1 = { 'caseUid': this.caseuid, 'subject': this._searchString };
            window.gza && window.gza(event1, data1);
        }
    }

    get sendanalyticscasecreated(){
        return this.sendAnalyticsCaseCreatedVal;
    }

    @api
    set searchString(value) {
        this.isConversionWithSearch = true;
        this._searchString = value;
        if (this.communitySettingsLoaded) {
            this.autosearchFunc();
        }
    }

    get searchString() {
        return this._searchString || '';
    }
    
    async connectedCallback() {
        this.loadScriptStyle = await scriptsLoaded();
        this.getCommunityCustomSettings = await getCommunitySettings();
        this.setCommunityCustomSettings(this.getCommunityCustomSettings);
        this.showDescMetadata = this.showbody || this.showmetadata;
    }

    async setCommunityCustomSettings(result) {
        if (result && result.isCustomSettingFilled) {
            this.customSettingsFilled = result.isCustomSettingFilled;
            this.bearer = result.token;
            this.currentCommURL = result.currentCommURL;
            this.endPoint = result.endPoint;
            this.uid = result.uid;
            if (result.UserType == "Guest" || result.UserType == undefined) {
                result.userEmail = '';
            } else if (result.userEmail != null && result.userEmail != '') {
                this.currentUserEmail = result.userEmail;
            }
            this.autosearchFunc();
            this.firstLoad = false;
        } else {
            this.customSettingsFilled = result.isCustomSettingFilled;
            this.customSettingErrorMessage = result.customSettingErrorMessage;
        }
        this.communitySettingsLoaded = true;
    }

    handleTrackAnalytics(type, objToSend) {
        if (type == 'caseDeflection') {
            type = 'search';
        }
        window.gza(type, objToSend);
    }
    openResult(e) {
        if (!this.isConversionWithSearch) {
            this.handleTrackAnalytics('conversion', {
                searchString: this._searchString,
                index: e.currentTarget.dataset.index,
                type: e.currentTarget.dataset.type,
                id: e.currentTarget.dataset.recordid,
                rank: parseInt(e.currentTarget.dataset.rank) + 1,
                convUrl: e.currentTarget.dataset.url,
                convSub: e.currentTarget.dataset.sub || e.currentTarget.dataset.url,
                autoTuned: e.currentTarget.dataset.autotuned ? e.currentTarget.dataset.autotuned : false,
                sc_analytics_fields: e.currentTarget && e.currentTarget.dataset.track ? e.currentTarget.dataset.track : [],
                pageSize: this.pageSize,
                page_no: 1
            });
        }
        var aggrValue = "[]";
        var sourceType = this.sourcename;
        var sourceValue = this.sourcevalue;
        var filterData;
        if (sourceType !== "" && sourceValue !== "") {
            filterData = { "sourceType": sourceType, "valueFilter": sourceValue };
            this.createAggregationFilter(filterData);
            aggrValue = this.aggregations || '[]';
        }
        var sendData = {
            "searchString": this._searchString,
            'page_no': 1,
            'filter': aggrValue ? JSON.parse(aggrValue) : "[]",
            'result_count': this.autosuggestList && this.autosuggestList.length,
            'conversion': [{
                rank: parseInt(e.currentTarget ? e.currentTarget.dataset.rank : e.rank) + 1,
                url: e.currentTarget && e.currentTarget.dataset ? e.currentTarget.dataset.url : e.url,
                subject: e.currentTarget && e.currentTarget.dataset ? e.currentTarget.dataset.sub : e.currentTarget.dataset.url,
                es_id: (e.currentTarget ? e.currentTarget.dataset.index : e.index) + '/' + (e.currentTarget ? e.currentTarget.dataset.type : e.type) + '/' + encodeURIComponent(e.currentTarget ? e.currentTarget.dataset.value : e.value)
            }]
        };

        if (this.isConversionWithSearch) {
            this.handleTrackAnalytics('caseDeflection', sendData);
        }
        this.isConversionWithSearch = false;
        this.eventCaseCreatedOnly = true;
    }

    autosearchFunc() {
        let self = this;
        self.loadingResult = true;
        var aggrValue = "[]";
        var resultPerSize = self.pagesize;
        if (resultPerSize === 'undefined' || resultPerSize === undefined) { resultPerSize = '10'; } //default handling
        var sourceType = self.sourcename;
        var sourceValue = self.sourcevalue;
        var filterData;
        if (sourceType !== "" && sourceValue !== "") {
            filterData = { "sourceType": sourceType, "valueFilter": sourceValue };
            self.createAggregationFilter(filterData);
            aggrValue = self.aggregations || '[]';
        }
        var searchText = self._searchString || '';
        var data = JSON.stringify({
            "searchString": searchText,
            "from": 0,
            "pageNum": 1,
            "sortby": "_score",
            "orderBy": "desc",
            "resultsPerPage": parseInt(resultPerSize),
            "aggregations": aggrValue ? JSON.parse(aggrValue) : '[]',
            "referrer": "",
            "exactPhrase": "",
            "withOneOrMore": "",
            "withoutTheWords": "",
            "recommendResult": "",
            "indexEnabled": false,
            "sid": window._gr_utility_functions.getCookie("_gz_taid"),
            "uid": self.uid
        });
        var xmlHttp = new XMLHttpRequest();
        var url = self.endPoint + "/search/SUSearchResults";
        xmlHttp.withCredentials = true;
        xmlHttp.open("POST", url, true);
        xmlHttp.setRequestHeader("Accept", "application/json");
        xmlHttp.setRequestHeader('Authorization', 'bearer ' + self.bearer);
        xmlHttp.setRequestHeader('Content-Type', 'application/json');
        xmlHttp.send(data);
        xmlHttp.onreadystatechange = async function () {
            if (xmlHttp.readyState === 4) {
                if (xmlHttp.status === 200) {
                    var result = JSON.parse(xmlHttp.response);
                    if (result.statusCode != 402) {
                        self.showViewedResults = result.searchClientSettings && result.searchClientSettings.ViewedResults == 1 ? 'su__viewed-results' : '';
                        var total = result.result.total;
                        self.totalResults = total;
                        if (!self.totalResults) {
                            self.showNoResults = true;
                        } else {
                            self.showNoResults = false;
                        }
                        if (self.totalResults > resultPerSize) {
                            self.isShowSearchButton = true;
                        } else {
                            self.isShowSearchButton = false;
                        }
                        self.loadingResult = false;
                        self.autosuggestList = result.result.hits;
                        if (self.autosuggestList) {
                            for (var i = 0; i < self.autosuggestList.length; i++) {
                                if (self.autosuggestList[i].highlight.TitleToDisplayString[0]) {
                                    Object.assign(self.autosuggestList[i], { 'highlightTitleToDisplayString': self.autosuggestList[i].highlight.TitleToDisplayString[0] });
                                } else {
                                    Object.assign(self.autosuggestList[i], { 'highlightTitleToDisplayString': null });
                                }
                                for (var j = 0; j < self.autosuggestList[i].metadata.length; j++) {
                                    if (self.autosuggestList[i].metadata[j].key == 'post_time') {
                                        Object.assign(self.autosuggestList[i].metadata[j], { 'metaKeyValBoolean': true });
                                        Object.assign(self.autosuggestList[i].metadata[j], { 'metaKeyVal': 'Created Date' });
                                    }
                                    else {
                                        if (self.autosuggestList[i].metadata[j].key != 'Title' && self.autosuggestList[i].metadata[j].key != 'Description') {
                                            Object.assign(self.autosuggestList[i].metadata[j], { 'metaKeyValBoolean': false });
                                            Object.assign(self.autosuggestList[i].metadata[j], { 'metaKeyVal': self.autosuggestList[i].metadata[j].key });
                                        }
                                        if (self.autosuggestList[i].metadata[j].key === 'Title' || self.autosuggestList[i].metadata[j].key === 'Description') {
                                            self.autosuggestList[i].metadata[j].value.splice(0);
                                        }
                                    }
                                }
                                Object.assign(self.autosuggestList[i], { 'autosuggestTitleToDisplay': self.autosuggestList[i].highlight.TitleToDisplay[0] || self.autosuggestList[i].href });
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
    createAggregationFilter(filterData) {
        if (filterData !== undefined && filterData !== null) {
            if (this.searchString !== undefined && this.searchString.length !== 0) {
            }
            var sourceType = filterData.sourceType;
            var valueType = filterData.valueFilter;
            var totalResult = this.pageSize;
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
                    this.aggregations = finalJson;
                }
            }
            if (totalResult != undefined && totalResult != '') {
                this.pagesize = totalResult;
            }
        }
    }

    searchButtonPress(e) {
        if (this._searchString != null && this._searchString != '' && this._searchString != undefined) {
            this._searchString = this._searchString.trim();
        } else {
            this._searchString = ''
        }
        window.location.hash = encodeURIComponent("searchString=" + encodeURIComponent(this._searchString));
        if (!this.opennewtab) {
            e.target.href = this.currentCommURL + window.location.hash;
        } else {
            window.open(this.currentCommURL + window.location.hash, '_blank');
        }
    }

}