import { LightningElement, api, track } from 'lwc';
import { registerListener, unregisterListener, fireEvent, mergeFilters, getCommunitySettings } from 'c/authsupubsub_b6b3_13';
export default class SU_AuthCustomizeSetting extends LightningElement {

    @track customize = false;
    @track totalResults = true;
    @api translationObject;
    @track values = {}
    @track autoLearning = "Auto Learning"
    @api smartFacetsAdmin;
    @api isAutoLearning;
    @track filtersArray;
    @track customizeDiv = false;
    @api searchQueryData;
    @api noResultFound;
    @api pageSizeAdvFiltr;
    @track bearer;
    @track endPoint;
    @track endPoint;
    @api allContentHideFacet;
    @api facetValues;
    @api aggregationsData;
    @api active;
    @track hiddenFacets = [];
    @api hiddenKeys;
    @track hideTitle = false;
    @track hideUrl = false;
    @track hideSummary = false;
    @track hideMetadata = false;
    @track hideIcon = false;
    @track hideTag = false;
    @track hideData = false;
    @track selectedStickyFilter;
    @track selectedStickyFilterData = '';
    @api defaultTab;
    @api activeMergedChild;
    @api accessKeyValue;
    @api activeTabOrder;
    @api activeTabIndex;
    @api activeTabType;
    @api featuredResponseRecorded;
    @api knowledgeGraphResponseRecorded;
    @track applyThemeVal = false;
    @api selectedTypeFilter;
    @api contentTag;
    @track contentTabs =[] ;
    @api hiddenKeyArray;
    @track sethiddenKeys = [];
    @track dragid;
    @track dropId;
    @track confirmReset = false;
    @track crossIconHiddenKeys = [];
    @track mergedArray;
    @track searchTipsModal = false;
    @api mergedresults;
    @track showArrowIcon = false;
    @api
    set tabsfilter(value) {
        if (value)
            this.contentTabs = JSON.parse(JSON.stringify(value));
    };
    get tabsfilter() {
        return this.contentTabs;
    }

    get applyThemeBtnClass(){
        if (this.hiddenKeyArray.length === 7) {
            return "apply applyChangesBtn su__bg-blue-grd su__radius-0 su__cursor su__p-2 su__text-white"
        } else {
            return "apply su__bg-blue-grd su__radius-0 su__cursor su__p-2 su__text-white";
        }
    }

    get showHideCustomizeButton() {
        return this.mergedresults && this.searchQueryData.aggregations.length == 0 ? true : false;
    }
    get showHideContentTabs() {
        return this.contentTabs && this.contentTabs.length > 1 ? true : false;
    }

    get settingGearIconClass() {
        return this.customize ? 'su__side-Search-tips-on su__facetPreferenceNone su__bg-blue-grd su__p-2 su__position-fixed su__cursor su__loading-view su__d-lg-block ' : 'su__side-Search-tips su__bg-blue-grd su__p-2 su__position-fixed su__cursor su__loading-view su__d-lg-block su__facetPreferenceNone';
    }

    get customizeSettingGearIconOptions() {
        return this.customize ? 'su__d-md-block' : 'visibilityHidden';
    }

    get customizeBoxClass() {
        return this.customizeDiv ? 'su__d-block su__anim-fadeindown su__facetPrefrence' : "visibilityHidden su__position-absolute";
    }

    get getPreSelectedAllContentClass() {
        return this.defaultTab == 'all' ? 'indexData font-md-12 su__cursor su-tab-active' : 'font-md-12 su__cursor indexData';
    }

    get showFacetInCustomizeBox() {
        return this.active === 'all' && this.allContentHideFacet ? 'su-filterspref-active su__col-3 su__d-none' : 'su-filterspref-not-active su__col-3 su__d-inline-block';
    }
    get showResultArrayCustomizeBox() {
        return this.active === 'all' && this.allContentHideFacet ? 'su__allcontent-show su__col-12' : 'su__allcontent-notshow su__col-9 su-customize su__float-right';
    }
    get showGearIconCustomizeSetting() {
        return this.totalResults > 0 ? true : false;
    }

    get hiddenKeysData() {
        this.hiddenKeys = this.hiddenKeys &&  JSON.parse(JSON.stringify(this.hiddenKeys));
        if(this.hiddenKeys){
            this.hiddenKeys.forEach(item => {
            item.resultContentTagClass = item.key === 'Tag' && !this.contentTag ? 'su__d-none' : 'su-display';
        });
        return this.hiddenKeys
        }
    }

    get showHideTitle() {
        return this.hiddenKeys && this.hiddenKeys.length && this.hiddenKeys.length &&  !this.hiddenKeys[0].hideEye;
    }

    get showHideTag() {
        return this.hiddenKeys && this.hiddenKeys.length && this.hiddenKeys.length>= 5 && !this.hiddenKeys[5].hideEye && this.contentTag;
    }

    get showHideUrl() {
        return this.hiddenKeys && this.hiddenKeys.length && this.hiddenKeys.length >=2 && !this.hiddenKeys[2].hideEye;
    }

    get showHideSummary() {
        return this.hiddenKeys && this.hiddenKeys.length && this.hiddenKeys.length >=1 && !this.hiddenKeys[1].hideEye;
    }
    get facetsCustom(){
        return this.showHideContentTabs ? "hideFacets su__pt-3 su__pb-3" : "hideFacets su__pb-3"
    }

    get showHideMetadata() {
        return this.hiddenKeys && this.hiddenKeys.length && this.hiddenKeys.length >= 3 && !this.hiddenKeys[3].hideEye; !this.hiddenKeys[3].hideEye;
    }

    get showHideIcon() {
        return this.hiddenKeys && this.hiddenKeys.length && this.hiddenKeys.length >= 4 && !this.hiddenKeys[4].hideEye;
    }

    togglePopup() {
        this.customize = !this.customize;
    }

    toggleEditMode() {
        this.emptySearchCall();
    }

    get checkFacetValues() {
        if (this.facetValues) {
            this.facetValues.forEach(filter => {
                filter.showFacetCustomizeBox = filter.values && filter.values.length > 0 && filter.order != 0 ? true : false;
                filter.showEyeCustomize = filter.hideEye ? true : false;
                filter.hideEyeClass = !filter.hideEye ? 'su__d-block' : 'visibilityHidden su__position-absolute';
                filter.showEyeClass = filter.hideEye ? 'su__d-block' : 'visibilityHidden su__position-absolute';
            })
        }
        return this.facetValues;
    }


    emptySearchCall() {
        const self = this;
        var data = JSON.stringify({
            "searchString": "",
            "orderBy": "desc",
            "referrer": document.referrer,
            "uid": this.searchQueryData.uid,
        });
        let query = JSON.parse(data);
        query.pageSizeAdv = this.pageSizeAdvFiltr;

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
                        if (result.statusCode == 200 || result.statusCode == 400) {
                            self.values = result.aggregationsArray;
                            if (result.merged_facets && result.merged_facets.length) {
                                self.mergedArray = JSON.parse(result.merged_facets) || '[]';
                                self.mergedArray.forEach(function (o) {
                                    mergeFilters(o, self.values, false, self);
                                });
                            }
                            self.filtersArray = result.aggregationsArray[0];
                            self.assignFacetVal(self.values);
                            self.customize = false;
                            self.customizeDiv = !self.customizeDiv;
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

    get checkResultValues() {
        if (this.filtersArray) {
            let newfiltersArray = [this.filtersArray];
            newfiltersArray.forEach(filter => {
                filter.showResultCustomizeBox = filter.values && filter.values.length > 0 && filter.order == 0 ? true : false;
                filter.values.forEach(filterType => {
                    if (filterType) {
                        filterType.showCustomizeMergedResults = filterType.merged && filterType.showChild == '1' ? true : false;
                        filterType.mergedResultClass = (this.defaultTab === filterType.Contentname && (filterType.merged && filterType.showChild == '1' || filterType.indeterminate)) ? 'indexData su__cursor font-md-12 su-tab-active' : 'font-md-12 su__cursor indexData';
                        filterType.mergedResultFalseClass = (this.defaultTab == filterType.Contentname || (filterType.selected && filter.indeterminate == true)) ? 'indexData su__cursor font-md-12 su-tab-active' : 'font-md-12 su__cursor indexData';
                        filterType.showFacetPreferenceClickedCS = filterType.showFacetPreferenceClickedCS ? true : false;
                        if (filterType.childArray) {
                            filterType.childArray.forEach(child => {
                                child.displayNameOrContentname = child.displayName ? child.displayName : child.Contentname;
                                child.mergedOptionClass = this.activeMergedChild == child.Contentname ? 'su__merge-options-active su__merge-options-child su__loading-view' : 'su__merge-options-child su__loading-view';
                            })
                        }
                    }
                })
            })
            return newfiltersArray;
        }
    }

    mergedFacetPreferenceCS(event) {
        var Closed = event.currentTarget.dataset.close ? event.currentTarget.dataset.close : false;
        var order = event.currentTarget.dataset.order ? event.currentTarget.dataset.order : 0;
        var id = event.currentTarget.dataset.id ? event.currentTarget.dataset.id : '';
        this.filtersArray = JSON.parse(JSON.stringify(this.filtersArray));
        if (!Closed) {
            if (order !== null) {
                if (this.filtersArray.merged) {
                    this.filtersArray.values.forEach(function (element) {
                        if (element.Contentname === id) {
                            element.showFacetPreferenceClickedCS = true;
                        } else {
                            element.showFacetPreferenceClickedCS = false;
                        }
                    });
                }
            }
        } else {
            this.filtersArray.values.forEach(function (element) {
                element.showFacetPreferenceClickedCS = false;
            });
        }
        this.filtersArray = this.filtersArray;
    }

    toggleAutoLearning() {
        this.isAutoLearning = !this.isAutoLearning;
        if (this.isAutoLearning) {
            localStorage.setItem('AutoLearning', true);
        } else {
            localStorage.setItem('AutoLearning', false);
            document.cookie = "smartFacets=false; expires=Thu, 01 Jan 9999 00:00:00 UTC; path=/;";
        }
    }

    assignFacetVal(val) {
        this.facetValues = val;
        this.aggregationsData = val;
        var c = JSON.parse(localStorage.getItem('theme' + this.searchQueryData.uid));
        if (c) {
            if (c["hiddenFacets"]) {
                this.aggregationsData.forEach(function (child) {
                    if (c.hiddenFacets.includes(child.label)) {
                        child.hideEye = true;
                    } else {
                        child.hideEye = false;
                    }
                })
            }
            
            this.sethiddenKeys = JSON.parse(JSON.stringify(this.hiddenKeys));
            this.sethiddenKeys.forEach(item => {
                if (item.key == "Title") {
                    c.hideTitle ? item.hideEye = true : item.hideEye = false;
                }
                if (item.key == "Url") {
                    c.hideUrl ? item.hideEye = true : item.hideEye = false;
                }
                if (item.key == "Tag") {
                    c.hideTag ? item.hideEye = true : item.hideEye = false;
                }
                if (item.key == "Summary") {
                    c.hideSummary ? item.hideEye = true : item.hideEye = false;
                }
                if (item.key == "Metadata") {
                    c.hideMetadata ? item.hideEye = true : item.hideEye = false;
                }
                if (item.key == "Icon") {
                    c.hideIcon ? item.hideEye = true : item.hideEye = false;
                }
            })
            
            this.hiddenKeys = this.sethiddenKeys;
            this.hiddenKeyArray = [];
            this.hiddenKeys.forEach(item => {
                if (item.hideEye) {
                    this.hiddenKeyArray.push(item.key);
                }
            });

            this.facetValues = this.aggregationsData


            var sortArr = this.facetValues;
            sortArr.forEach(function (d) {
                (c.facetsOrder).forEach(function (o) {
                    if (d.label == o.value.label) {
                        d.index = o.indexVal;
                    }
                })
            });

            sortArr.sort(function (a, b) {
                return parseFloat(a.index) - parseFloat(b.index);
            });

            this.defaultTab = c.defaultTab.indexOf('merged_') > -1 ? c.defaultTab : c.activeTabIndex;
            this.activeMergedChild = c.defaultTab.indexOf('merged_') > -1 ? c.activeMergedChild : '';

            this.facetValues = sortArr;
        } else {
            this.defaultTab = "all";
            this.activeMergedChild = "";
            this.facetValues.forEach(e=>{
                e.hideEye = false
            }
            );
            this.facetValues = [...this.facetValues];
            this.hiddenKeys.forEach(e=>{
                e.hideEye = false
            }
            );
            this.hiddenKeys = [...this.hiddenKeys];
            this.sethiddenKeys = [];
            this.hiddenKeyArray = [];
        }
    }

    hideFacets(event) {
        this.setHiddenFilters = true;
        let hiddenFacet = [];
        const data = event.currentTarget ? event.currentTarget.dataset.query : '';
        hiddenFacet.push(data);
        this.hiddenFacets.push(data);
        this.aggregationsData.forEach((c) => {
            if (data === c.label) {
                c.hideEye = true;
            }
        });
        this.facetValues.forEach((c) => {
            if (data === c.label) {
                c.hideEye = true;
            }
        });
        this.aggregationsData = [...this.aggregationsData];
        this.facetValues = [...this.facetValues];
    }

    showFacets(event) {
        this.setHiddenFilters = true;
        const data = event.currentTarget ? event.currentTarget.dataset.item : '';
        let arr = this.hiddenFacets.filter((item) => item !== data);
        this.hiddenFacets = arr;
        this.aggregationsData.forEach((c) => {
            if (data === c.label) {
                c.hideEye = false;
            }
        });
        this.facetValues.forEach((c) => {
            if (data === c.label) {
                c.hideEye = false;
            }
        });
        this.aggregationsData = [...this.aggregationsData];
        this.facetValues = [...this.facetValues];
    }

    hideKey(event) {
        let hiddenItemKey = [];
        const data = event.currentTarget && event.currentTarget.dataset.query;
        hiddenItemKey.push(data);
        this.hiddenKeyArray = JSON.parse(JSON.stringify(this.hiddenKeyArray));
        this.hiddenKeyArray.push(data);

        const updatedKeys = this.hiddenKeys.map(c => {
            if (c.key === data) {
                return { ...c, hideEye: true };
            }
            return c;
        });
        this.hiddenKeys = updatedKeys;
    }

    showKey(event) {
        const data = event.currentTarget && event.currentTarget.dataset.item;
        const arr1 = this.hiddenKeyArray.filter(item => item !== data);
        this.hiddenKeyArray = arr1;
        const updatedKeys = this.hiddenKeys.map(c => {
            if (c.key === data) {
                return { ...c, hideEye: false };
            }
            return c;
        });

        this.hiddenKeys = updatedKeys;
    }

    applyTheme() {
        let themeProperties = JSON.parse(localStorage.getItem("theme" + this.searchQueryData.uid));
        if (this.hiddenKeyArray.length) {
            this.disbleApplyChangesBtn = false;
            this.hideTitle = this.hiddenKeyArray.includes('Title');
            this.hideUrl = this.hiddenKeyArray.includes('Url');
            this.hideSummary = this.hiddenKeyArray.includes('Summary');
            this.hideMetadata = this.hiddenKeyArray.includes('Metadata');
            this.hideIcon = this.hiddenKeyArray.includes('Icon');
            this.hideTag = this.hiddenKeyArray.includes('Tag');
        } else {
            this.hideTitle = false;
            this.hideUrl = false;
            this.hideSummary = false;
            this.hideMetadata = false;
            this.hideIcon = false;
            this.hideTag = false;
        }
        fireEvent(null, 'getShowHideSearchResult', {
            hideTitle: this.hideTitle, hideUrl: this.hideUrl,
            hideSummary: this.hideSummary, hideMetadata: this.hideMetadata, hideIcon: this.hideIcon, hideTag: this.hideTag
        });
        this.customizeDiv = false;
        this.hideData = false;
        let c = {};
        let filter = [];

        if (this.activeTabIndex && this.activeTabIndex.includes('merged_')) {
            let filterSelect = {
                "Contentname": this.activeTabIndex,
                "checked": true
            };
            this.mergeFilterClicked(filterSelect, filter, this.filtersArray.values);
        }

        c["hideTitle"] = this.hideTitle;
        c["hideUrl"] = this.hideUrl;
        c["hideSummary"] = this.hideSummary;
        c["hideMetadata"] = this.hideMetadata;
        c["hideIcon"] = this.hideIcon;
        c["hideTag"] = this.hideTag;
        if (this.accessKeyValue || (themeProperties && themeProperties["accessKeyValue"])) {
            c["accessKeyValue"] = (this.accessKeyValue || (themeProperties && themeProperties["accessKeyValue"]));
            this.accessKeyValue = c["accessKeyValue"];
        } else {
            c["accessKeyValue"] = 'all';
            this.accessKeyValue = c["accessKeyValue"];
        }
        c["activeTabOrder"] = this.activeTabOrder || (themeProperties && themeProperties["activeTabOrder"]);
        if (this.activeTabOrder === undefined) {
            this.activeTabOrder = c["activeTabOrder"];
        }
        if (this.activeTabIndex || (themeProperties && themeProperties["activeTabIndex"])) {
            c["activeTabIndex"] = this.activeTabIndex || (themeProperties && themeProperties["activeTabIndex"]);
            this.activeTabIndex = c["activeTabIndex"];
        } else {
            c["activeTabIndex"] = 'all';
            this.activeTabIndex = c["activeTabIndex"];
        }
        c["activeTabValue"] = filter;
        c["defaultTab"] = this.defaultTab;
        c["activeMergedChild"] = this.activeMergedChild || (themeProperties && themeProperties["activeMergedChild"]);
        if (this.activeMergedChild == undefined) {
            this.activeMergedChild = c["activeMergedChild"];
        }
        c["activeTabType"] = this.activeTabType || (themeProperties && themeProperties["activeTabType"]);
        if (this.activeTabType == undefined) {
            this.activeTabType = c && c["activeTabType"];
        }
        c["hiddenFacets"] = this.hiddenFacets.length ? this.hiddenFacets : (themeProperties && !this.setHiddenFilters ? themeProperties["hiddenFacets"] : []);

        c["facetsOrder"] = this.facetsList && this.facetsList.length ? this.facetsList : (themeProperties ? themeProperties["facetsOrder"] : []);
        localStorage.setItem("theme" + this.searchQueryData.uid, JSON.stringify(c));
        let selectedStickyFilters = this.selectedStickyFilter;

        if (c["hiddenFacets"].length) {
            for (let num = 0; num < c["hiddenFacets"].length; num++) {
                if (selectedStickyFilters) {
                    for (let counter = 0; counter < selectedStickyFilters.length; counter++) {
                        if (c["hiddenFacets"][num] === selectedStickyFilters[counter].label) {
                            let abc = selectedStickyFilters.splice(counter, 1);
                            let newFilter = JSON.parse(JSON.stringify(selectedStickyFilters)).reduce((arr, f) => {
                                let v = f.values.reduce((arr, v) => {
                                    arr.push(v.Contentname);
                                    return arr;
                                }, []);
                                arr.push({ type: f.key, filter: v });
                                return arr;
                            }, []);
                            this.selectedStickyFilterData = newFilter;
                        }
                    }
                }
            }
        }
        let xyz = this.aggregationsData;
        this.applyThemeVal = true;
        if (this.isSmartFacets) {
            this.isSmartHidden = true;
        }
        xyz.forEach(d => {
            if (this.facetsList) {
                this.facetsList.forEach(o => {
                    if (d.label === o.value.label) {
                        d.index = o.indexVal;
                    }
                });
            }
        });
        xyz.sort((a, b) => {
            if (a.index === undefined) return 1;
            if (b.index === undefined) return -1;
            if (a.index < b.index) return -1;
            if (a.index > b.index) return 1;
            return 0;
        });

        this.setHiddenFilters = false;
        this.aggregationsData = JSON.parse(JSON.stringify(xyz));
        this.indexSearchCall();
    }

    indexSearchCall() {
        let data = this.accessKeyValue;
        let order = this.activeTabOrder;;
        if (data === 'all') {
            this.defaultTab = 'all';
            this.activeMergedChild = '';
        } else {
            const tabValue = this.defaultTab.indexOf('merged_') > -1 ? this.defaultTab : this.activeTabIndex;
            this.defaultTab = tabValue;
        }
        this.filterOrder = order;
        this.knowledgeGraphResponseRecorded = false;
        this.featuredResponseRecorded = false;
        const id = this.activeTabIndex;
        const keyType = this.activeTabType;
        if (data === 'all') {
            if(this.active != 'all' || this.selectedTypeFilter.length === 0 || this.selectedStickyFilter.length === 0){
                this.selectedTypeFilter = '';
            }
            this.active = 'all';
        } else {
            if (this.active === this.activeTabIndex) {
                this.active = id;
            }
            if (this.applyThemeVal) {
                if (this.active !== this.activeTabIndex ) {
                    const filterValue = `[{"type": "${keyType}","filter":["${id}"]}]`;
                    this.selectedTypeFilter = filterValue;
                }
            } else {
                const filterValue = `[{"type": "${keyType}","filter":["${id}"]}]`;
                this.selectedTypeFilter = filterValue;
            }
            this.applyThemeVal = false;
        }
        fireEvent(null, 'facetPreference', { 
            aggregationsData: this.aggregationsData,
            aggregations: this.selectedTypeFilter,
            activeTab: this.activeTabIndex
        });
    }

    activeTab(event) {
        let data = event.currentTarget && event.currentTarget.dataset.accesskey;
        let order = event.currentTarget && event.currentTarget.dataset.order
        let id = event.currentTarget && event.currentTarget.dataset.id;
        let facetType = event.currentTarget && event.currentTarget.dataset.item;
        let mergedCS = event.currentTarget && event.currentTarget.dataset.mergedCs;

        this.defaultTab = mergedCS ? mergedCS : id;
        this.activeMergedChild = id;
        this.accessKeyValue = data;
        this.activeTabOrder = order;
        this.activeTabIndex = id;
        this.activeTabType = facetType;
        this.activeTabFunc = true;

        if (mergedCS) {
            let filtersArray = JSON.parse(JSON.stringify(this.filtersArray));
            filtersArray.values.forEach((element) => {
                element.showFacetPreferenceClickedCS = false;
            });
            this.filtersArray = filtersArray;
        }

    }

    selectedStickyFacetData(val) {
        this.selectedStickyFilter = val;
    }

    async connectedCallback() {
        this.getCommunityCustomSettings = await getCommunitySettings();
        this.setCommunityCustomSettings(this.getCommunityCustomSettings);
        registerListener('selectedFacetData', this.selectedStickyFacetData, this);
        registerListener('toggleSearchTipsFunc', this.toggleSearchTipsFunc, this);
        registerListener('selectedCsTab', this.selectedCsTabName, this);
    }

    disconnectedCallback() {
        unregisterListener('selectedFacetData', this.selectedStickyFacetData, this);
        unregisterListener('toggleSearchTipsFunc', this.toggleSearchTipsFunc, this);
        unregisterListener('selectedCsTab', this.selectedCsTabName, this);
    }

    setCommunityCustomSettings(result) {
        if (result && result.isCustomSettingFilled) {
            this.endPoint = result.endPoint;
            this.bearer = result.token;
        }
    }

    selectedCsTabName(name){
       this.active = name;
    }

    toggleSearchTipsFunc() {
        this.toggleSearchTips();
    }

    // facet re-arranging code
    dragstart(event) {
        this.dragid = event.target.dataset.dragId;
        event.dataTransfer.setData('dragStart', event.target.dataset.dragId);
    }

    drop(event) {
        const arr = [];
        const aggregation = this.aggregationsData;
        aggregation.forEach((c) => {
            arr.push(c.label);
        });
        this.dropId = event.target.dataset.dragId;
        if (this.dropId !== undefined) {
            this.array_move();
        }
        event.preventDefault();
    }

    array_move() {
        let arr = this.facetValues;
        let old_index = parseInt(this.dragid);
        let new_index = parseInt(this.dropId);
        let facetsOrder = [];

        if (new_index >= arr.length) {
            let k = new_index - arr.length + 1;
            while (k--) {
                arr.push(undefined);
            }
        }
        arr.splice(new_index, 0, arr.splice(old_index, 1)[0]);
        this.facetValues = arr;
        arr.forEach((c, i) => {
            facetsOrder.push({ indexVal: i, value: c });
        });
        this.facetsList = facetsOrder;
    }


    cancel(event) {
        event.preventDefault();
    }

    // Reset popup toggle 
    toggleConfirmationDialog() {
        if (this.confirmReset) {
            this.confirmReset = false
        } else {
            this.confirmReset = true;
        }
    }

    // Reset Customize Setting
    reset() {
        this.confirmReset = false
        this.customizeDiv = false;
        localStorage.removeItem('theme' + this.searchQueryData.uid);
        this.hideTitle = false;
        this.hideUrl = false;
        this.hideSummary = false;
        this.hideMetadata = false;
        this.hideIcon = false;
        this.hideTag = false;
        this.facetsOrder = [];
        this.hiddenFacets = [];
        this.defaultTab = 'all';
        this.activeMergedChild = '';

        this.facetValues.forEach((item) => {
            item.hideEye = false;
        });
        this.facetValues = [...this.facetValues];

        this.hiddenKeys.forEach(ele => {
            ele.hideEye = false;
        })

        this.hiddenKeys = [...this.hiddenKeys];

        this.sethiddenKeys = [];
        this.hiddenKeyArray = [];
        this.selectedTypeFilter = '';
        this.active = 'all';
        fireEvent(null, 'setResetCustomizeAggData', {
            active: this.active,
            selectedTypeFilter: this.selectedTypeFilter,
            defaultTab: this.defaultTab,
            hideTitle: this.hideTitle,
            hideUrl: this.hideUrl,
            hideSummary: this.hideSummary,
            hideMetadata: this.hideMetadata,
            hideIcon: this.hideIcon,
            hideTag: this.hideTag,
            aggregations: ''
        });

    }

    // close Box while clicking on box icon
    discardChanges() {
        this.customizeDiv = false;
        this.confirmReset = false;
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

    // toggle SearchTips 
    toggleSearchTips() {
        this.customize = false;
        this.searchTipsModal = true;
        const myElement = this.template.querySelector('[data-id="myElement"]');
        const myElementModal = this.template.querySelector('[data-id="myElementModal"]');
        document.body.style.overflow = 'hidden';
        document.body.style['overflow-y'] = "hidden";
        if (myElement) {
            myElement.classList.add('su__search-tip-toggle')
        }
        if (myElementModal) {
            myElementModal.classList.remove('su__d-none');
        }
    }

    // close SearchTips Modal
    dismiss_modal() {
        this.searchTipsModal = false;
        const myElement = this.template.querySelector('[data-id="myElement"]');
        const myElementModal = this.template.querySelector('[data-id="myElementModal"]');
        document.body.style['overflow-y'] = "unset";
        if (myElement) {
            myElement.classList.remove('su__search-tip-toggle')
        }
        if (myElementModal) {
            myElementModal.classList.add('su__d-none');
        }
        document.body.style.overflow = "unset";
    }

    nextContentSource() {
        const divElement = this.template.querySelector('[data-id="su__NavbarFacetPreference"]');
        divElement.scrollLeft += 100;
    }
    previousContentSource() {
        const divElement = this.template.querySelector('[data-id="su__NavbarFacetPreference"]');
        divElement.scrollLeft += -100;
    }

    renderedCallback(){
        var CsNavBar = this.template.querySelector('[data-id="su__NavbarFacetPreference"]');
        var internalCsDiv = this.template.querySelector('[data-name="su__internal__divFacetPreference"]');
        if (CsNavBar && internalCsDiv) {
            var navBarWidth = CsNavBar.offsetWidth;
            var internalCsWidth = internalCsDiv.offsetWidth;
            if (internalCsWidth > navBarWidth) {
                this.showArrowIcon = true;
            } else {
                this.showArrowIcon = false;
            }
        }
    }

}