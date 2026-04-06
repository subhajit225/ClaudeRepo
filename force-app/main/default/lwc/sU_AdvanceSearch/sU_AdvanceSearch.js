import { LightningElement, api, track } from 'lwc';

import { registerListener, fireEvent } from 'c/supubsub';

export default class SU_AdvanceSearch extends LightningElement {
    @api advancedSearchSelected;
    @api eventCode;
    @track withoutTheWords;
    @track withOneOrMore;
    @track exactPhrase;
    withWildcardSearch = '';
    @api searchString;
    @track isWildCardEnabledfromas = false;
    @api
    set exactword(val){
        this.exactPhrase = val;
    }
    @api 
    set withonemore(val){
        this.withOneOrMore=val;
    }
    
    @api 
    set withoutword(val){
        this.withoutTheWords=val;
    }
     
    @api 
    set withwildsearch(val){
        this.withWildcardSearch = val;
    }
    @api updateadvancedsearch;
    @track refineClass ="su__refineSearchButton su__outline-none su__text-capitalize font-12 su__loading-view"
    @api translationObject;
    @track showAdvanceSearch = true; //this variable is used for show and hide advance search
    addClassToAdvanceSearch = 'su__width-100 su__text-center';
    get exactword(){
        return this.exactPhrase;
    }
    get withonemore(){
        return this.withOneOrMore;
    }
    get withoutword(){
        return this.withoutTheWords;
    }
    get withwildsearch(){
        return this.withWildcardSearch;
    }
    connectedCallback() {
        registerListener("advsearchdata"+this.eventCode, this.advSearchData, this);
        registerListener('clearAllFilters'+this.eventCode, this.clearAdvanceFilters, this);
    }

    renderedCallback() {
        if(this.advancedSearchSelected) {
            this.addClassToAdvanceSearch = ''
        } else {
            this.addClassToAdvanceSearch = 'su__width-100 su__text-center';
        }
    }
    
    removeFromAdvFilter(data) {
        let inputs = this.template.querySelectorAll(".su__advance_group lightning-input");
        if (inputs) {
            inputs.forEach(input => {
                if ((input.name === 'exactPhrase' && data.label === 'exactPhrase') || 
                    (input.name === 'withOneOrMore' && data.label === 'withOneOrMore') || 
                    (input.name === 'withoutTheWords' && data.label === 'withoutTheWords') || 
                    (input.name === 'withWildcardSearch' && data.label === 'withWildcardSearch')) {
                    input.value = '';
                }
            })
        }
        this.refineSearch();
        this.showAdvanceSearch = false; // to hide adv search
        this.handleRefineSearch();
    }
    clearAdvanceFilters(){
        this.exactPhrase = '';
        this.withOneOrMore = '';
        this.withoutTheWords = '';
       
    }
    clearAllAdvFilters(event) {
        this.exactPhrase = '';
        this.withOneOrMore = '';
        this.withoutTheWords = '';
        this.withWildcardSearch ='';
        this.isWildCardEnabledfromas = false;
        this.refineSearch(event, 1);
    }
    handleRefineSearch() {
        if (this.showAdvanceSearch) {
            this.showAdvanceSearch = false;
            this.template.querySelector('[data-id="formBlock"]').classList.remove('mainFormDiv');
            this.template.querySelectorAll('.su__backdrop').forEach(f => f.classList.remove('su__d-none'));
            
        } else {
            this.showAdvanceSearch = true;
            let inputs = this.template.querySelectorAll(".su__advance_group lightning-input");
            inputs.forEach(input => {
                if(input.name === 'exactPhrase' && this.exactPhrase.length === 0){
                    input.value = '';
                }
                if(input.name === 'withOneOrMore' && this.withOneOrMore.length === 0){
                    input.value = '';
                }
                if(input.name === 'withoutTheWords' && this.withoutTheWords.length ===0){
                    input.value = '';
                }
                if(input.name === 'withWildcardSearch' && this.withWildcardSearch.length ===0){
                    input.value = '';
                }
            })
            this.template.querySelector('[data-id="formBlock"]').classList.add('mainFormDiv');
            this.template.querySelectorAll('.su__backdrop').forEach(f => f.classList.add('su__d-none'));
        }
    }

    refineSearch(event, clearFilters) {
        let inputs = this.template.querySelectorAll(".su__advance_group lightning-input");
        if (!clearFilters && inputs)
            inputs.forEach(input => {
                if (input.name === 'exactPhrase')
                    this.exactPhrase = input.value.trim();
                else if (input.name === 'withOneOrMore')
                    this.withOneOrMore = input.value.trim();
                else if (input.name === 'withoutTheWords')
                    this.withoutTheWords = input.value.trim();
                else if (input.name === 'withWildcardSearch')
                    this.withWildcardSearch = input.value.trim();
            })
            if(this.withWildcardSearch.length === 0){
                this.isWildCardEnabledfromas = false
              }else{
                this.isWildCardEnabledfromas = true
              }
            if(this.isWildCardEnabledfromas){
                fireEvent(null, 'setsearchstring'+this.eventCode, this.withWildcardSearch);
            }
       if(this.exactPhrase.length === 0 && this.withOneOrMore.length === 0 && this.withoutTheWords.length === 0 && this.withWildcardSearch.length === 0){
        if (!clearFilters){
            return;
        }
       }
       this.handleRefineSearch();
        var arr = [];
        arr.push(this.exactPhrase);
        arr.push(this.withOneOrMore);
        arr.push(this.withoutTheWords);
        arr.push(this.withWildcardSearch);
        var sendData = { "exactPhrase": this.exactPhrase, "withOneOrMore": this.withOneOrMore, "withoutTheWords": this.withoutTheWords, 'withWildcardSearch': this.withWildcardSearch,"isWildCardEnabledfromas": this.isWildCardEnabledfromas };
        fireEvent(null, "advancePagination"+this.eventCode, sendData);
    }
    enterKeyAdvanceSearch(event){
        if (event.which === 13){
            this.refineSearch(event);
        }  
    }
}