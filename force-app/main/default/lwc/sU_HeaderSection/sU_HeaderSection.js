import { LightningElement, api } from 'lwc';

import { registerListener, fireEvent, unregisterListener } from 'c/supubsub';

export default class SU_HeaderSection extends LightningElement {
    @api searchString;
    @api langlist;
    @api selectedTypeFilter;
    @api recordId;
     _recordIdfromSUParent;
     _aggregationsData;
    _selectedStickyFilter;
    _tabsFilter;
    _showClearFiltersButton;
    _bookmarkList;
    _showFilter;
    _allContentHideFacet = false;
    dynamicClassHeader = 'su__d-block';
    @api uid;
    @api endPoint;
    @api gototopcontainer;
    @api allarehidden;
    @api bearer;
    @api exactphrase;
    @api withoneormore;
    @api withoutthewords;
    @api withwildcardsearches ;
    @api advancedSearchSelected = false;
    @api eventCode;
    @api searchQuery;
    @api languageEnabled = false;
    @api mergedArrayStr;
    @api urlopensinnewtab;
    @api translationObject;
    @api isWildCardEnabled;
    @api caseSubjectVal
    @api resultperpage;
    bigscreen ;
    @api
    get recordIdfromSUParent() {
        return this._recordIdfromSUParent;
    }

    set recordIdfromSUParent(value) {
        this._recordIdfromSUParent = value;
    }
    @api
    get aggregationsData() {
        return this._aggregationsData;
    }

    set aggregationsData(value) {
        this._aggregationsData = value;
    }
    @api
    get selectedStickyFilter() {
        return this._selectedStickyFilter;
    }

    set selectedStickyFilter(value) {
        this._selectedStickyFilter = value;
    }
    @api
    get tabsFilter() {
        return this._tabsFilter;
    }

    set tabsFilter(value) {
        this._tabsFilter = value;
    }
    @api
    get showClearFiltersButton() {
        return this._showClearFiltersButton;
    }

    set showClearFiltersButton(value) {
        this._showClearFiltersButton = value;
    }
    @api
    get bookmarkList() {
        return this._bookmarkList;
    }

    set bookmarkList(value) {
        this._bookmarkList = value;
    }
    @api
    get showFilter() {
        return this._showFilter;
    }

    set showFilter(value) {
        this._showFilter = value;
    }
    @api
    get allContentHideFacet() {
        return this._allContentHideFacet;
    }

    set allContentHideFacet(value) {
        this._allContentHideFacet = value;
    }
    @api 
    set bigScreen(val){
      
        this.bigscreen = val;
       
    }
    get bigScreen(){return this.bigscreen}

    filterButtonClass = 'su__text-center su__bg-white su__cursor su__filters-button';

    buttonValue=false;

    get getBookmarkListLength() {
        return this.bookmarkList && this.bookmarkList.length ? true : false;
    }

    connectedCallback() {
        registerListener('dataFromContainer'+this.eventCode,this.handleDataFromContainer,this);
        registerListener('filterClosed'+this.eventCode,this.filterClosed,this);
        registerListener('viewAllStickyButton'+this.eventCode, this.viewAllStickyButton, this);
    }
    disconnectedCallback(){
        unregisterListener('dataFromContainer'+this.eventCode,this.handleDataFromContainer,this);
        unregisterListener('filterClosed'+this.eventCode,this.filterClosed,this);
        unregisterListener('viewAllStickyButton'+this.eventCode, this.viewAllStickyButton, this);
    }

    renderedCallback(){
        if(this.bigscreen){
           this.dynamicClassHeader = 'su__d-none';
        }else{
            this.dynamicClassHeader = 'su__d-block'
        }
        this._allContentHideFacet = this._aggregationsData && (this._aggregationsData.length === 0 || this._aggregationsData.length === 1);
        if (this.allContentHideFacet){
            this.filterButtonClass = 'su__facethide-inner su__text-center su__bg-white su__cursor su__filters-button su__disable-btn';
        }
        else if(this.allarehidden ){
             this.filterButtonClass = 'su__text-center su__bg-white su__filters-button su__disable-btn';

        }
        else{
            this.filterButtonClass = 'su__text-center su__bg-white su__cursor su__filters-button';
        }
    }

    filterClosed(){
        if(this.template.querySelector('[data-id="filterBlock"]')) {
            this.template.querySelector('[data-id="filterBlock"]').classList.remove('filter-absolute');             
        }
        this._showFilter = false;
    }

    viewAllStickyButton(){
        if(this.template.querySelector('[data-id="filterBlock"]')) {
        this.template.querySelector('[data-id="filterBlock"]').classList.add('filter-absolute');
        }
    }

    //this method is called when button is clicked and will fire the event to parent(SuSearchClientLWC Container)
    handleUtilitySlider() {
        this._showFilter= true;
        let message="header";
        fireEvent(null,'headerSUData'+this.eventCode,message);
        if(this.template.querySelector('[data-id="filterBlock"]')) {
            this.template.querySelector('[data-id="filterBlock"]').classList.add('filter-absolute');            
        }
    }
    handleDataFromContainer(event){
        this._recordIdfromSUParent=event.recorId;
        this._aggregationsData=event.aggregationsData;
        this._selectedStickyFilter=event.selectedStickyFilter;
        this._tabsFilter=event.tabsFilter;
        this._showClearFiltersButton = event.showClearFiltersButton;
        this._bookmarkList = event.bookmarkList;
        this.selectedStickyFilter.forEach(item=>{
            if(item.key === 'withWildcardSearch'){
                item.label = '';
                item.wildCardData = true;
                item.values.forEach(ele=>{
                    ele.sticky_name = 'Wildcard Search';
                })
            }else{
                item.wildCardData = false;
            }
        })
    }

}