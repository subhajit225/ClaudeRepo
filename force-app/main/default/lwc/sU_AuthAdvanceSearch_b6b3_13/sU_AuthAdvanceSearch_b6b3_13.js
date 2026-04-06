import { LightningElement, api, track } from 'lwc';

import { registerListener, unregisterListener, fireEvent } from 'c/authsupubsub_b6b3_13';

export default class SU_AuthAdvanceSearch extends LightningElement {
    @api advancedSearchSelected;
    @track withoutTheWords;
    @track withOneOrMore;
    exactPhraseOnRefine = ''
    withOneOrMoreOnRefine = ''
    withoutTheWordsOnRefine = ''
    withWildcardSearchOnRefine  = ''
    @track exactPhrase;
    withWildcardSearch = '';
    @api searchString;
    @track isWildCardEnabledfromas = false;
    @track sessionToggle;
    showAdvanceSearch = false;
    @api
    set exactword(val) {
        this.exactPhrase = val;
        this.exactPhraseOnRefine = this.exactPhrase
    }
    @api
    set withonemore(val) {
        this.withOneOrMore = val;
        this.withOneOrMoreOnRefine = this.withOneOrMore;
    }

    @api
    set withoutword(val) {
        this.withoutTheWords = val;
        this.withoutTheWordsOnRefine = this.withoutTheWords;
    }
    @api
    set withwildsearch(val) {
        this.withWildcardSearch = val;
        this.withWildcardSearchOnRefine = this.withWildcardSearch
    }
    @api updateadvancedsearch;
    @track refineClass = "su__refineSearchButton su__outline-none su__text-capitalize font-12 su__loading-view"
    @api translationObject;
    @track isActiveAdvanceSearchClass = false ;
    get exactword() {
        return this.exactPhrase;
    }
    get withonemore() {
        return this.withOneOrMore;
    }
    get refineSearchbtnClass() {
        if (this.exactPhrase.length === 0 && this.withOneOrMore.length === 0 && this.withoutTheWords.length === 0 && this.withWildcardSearch.length === 0) {
            return 'su__refineSearchButtonClass su__refineSearchButtonDisabled su__outline-none su__text-capitalize font-12 su__loading-view'
        } else {
            return 'su__refineSearchButtonClass  su__outline-none su__text-capitalize font-12 su__loading-view'
        }
    }
    get withoutword() {
        return this.withoutTheWords;
    }
    get withwildsearch() {
        return this.withWildcardSearch;
    }
    get sliderClass() {
        if (this.isActiveAdvanceSearchClass) {
            return 'slider-Advance su__py-2 showHideAdvanceSearch su__rtl-adv su__advance-active-border'
        } else {
            return 'slider-Advance su__py-2 showHideAdvanceSearch su__rtl-adv'
        }
    }
    get advanceSearchLabelClass(){
        return this.isActiveAdvanceSearchClass ? 'su__ml-2 su__pr-3 su__mr-5 su__mr-rtl su__color-advance-search' : 'su__ml-2 su__pr-3 su__mr-5 su__mr-rtl';
    }
    get advanceSearchSvgColor(){
        return this.isActiveAdvanceSearchClass ? '#59befb' : '#919bb0'
    }
    connectedCallback() {
        registerListener('removeStickyFacetEvent', this.clearSticky, this);
        registerListener('clearAdvanceFilters', this.clearAdvanceFilters, this);
        registerListener('toggleExpandAdvanceSearch', this.handleRefineSearch, this);
        registerListener('removeWildcardSearch', this.removeWildcardSearch, this);
    }

    disconnectedCallback() {
        unregisterListener('removeStickyFacetEvent', this.clearSticky, this);
        unregisterListener('clearAdvanceFilters', this.clearAdvanceFilters, this);
        unregisterListener('toggleExpandAdvanceSearch', this.handleRefineSearch, this);
        unregisterListener('removeWildcardSearch', this.removeWildcardSearch, this);
    }

    renderedCallback(){ 
        if( this.exactPhraseOnRefine.length || this.withOneOrMoreOnRefine.length || this.withoutTheWordsOnRefine.length || this.withWildcardSearchOnRefine.length){
            this.isActiveAdvanceSearchClass = true
        }else{
            this.isActiveAdvanceSearchClass = false
        }
    }
    clearSticky(event){
        if (event.label == "With the exact phrase" || event.label == "With one or more words" || event.label == "Without the words" || event.type == "withWildcardSearch") {
            this.exactPhrase = event.label == "With the exact phrase" ? '' : this.exactPhrase;
            this.withOneOrMore = event.label == "With one or more words" ? '' : this.withOneOrMore;
            this.withoutTheWords = event.label == "Without the words" ? '' : this.withoutTheWords;
        }
        
    }

    removeWildcardSearch() {
        this.withWildcardSearch = ''
        this.isWildCardEnabledfromas = false;
    }

    removeFromAdvFilter(data) {
        let inputs = this.template.querySelectorAll(".su__advance_group lightning-input");
        if (inputs) {
            inputs.forEach(input => {
                if (input.name == 'exactPhrase' && data.label == 'exactPhrase') {
                    input.value = '';

                }
                else if (input.name == 'withOneOrMore' && data.label == 'withOneOrMore') {
                    input.value = '';

                }
                else if (input.name == 'withoutTheWords' && data.label == 'withoutTheWords') {
                    input.value = '';

                }
                else if (input.name == 'withWildcardSearch' && data.label == 'withWildcardSearch') {
                    input.value = '';
                }
            })
        }

        this.refineSearch();
        this.handleRefineSearch();
    }
    clearAdvanceFilters(event) {
        this.exactPhraseOnRefine = '';
        this.withOneOrMoreOnRefine = '';
        this.withoutTheWordsOnRefine = '';
    }
    clearAllAdvFilters(event) {
        this.exactPhraseOnRefine = '';
        this.withOneOrMoreOnRefine = '';
        this.withoutTheWordsOnRefine = '';
        this.withWildcardSearchOnRefine= '';
        this.isActiveAdvanceSearchClass = false;
        this.isWildCardEnabledfromas = false;
        this.sessionToggle = false;

        window.sessionStorage.setItem('sessionToggle', this.sessionToggle);
        fireEvent(null, 'wildcardEnabled', false);
        this.refineSearch(event, 1);
        let inputFields = this.template.querySelectorAll(".su__advance_group lightning-input");
        this.advanceSearchFieldValues(inputFields);
    }

    removeAdvSearchFilter(data) {
        let inputs = this.template.querySelectorAll(".su__advance_group lightning-input");
        if (inputs) {
            inputs.forEach(input => {
                input.value = '';
            })
        }
        for (let i = 0; i < data.length; i++) {
            let inputs = this.template.querySelectorAll(".su__advance_group lightning-input");
            if (inputs) {
                inputs.forEach(input => {
                    if (data[i].label == 'exactPhrase' && input.name == 'exactPhrase') {
                        input.value = data[i].values;
                    }
                    else if (data[i].label == 'withOneOrMore' && input.name == 'withOneOrMore') {
                        input.value = data[i].values;
                    }
                    else if (data[i].label == 'withoutTheWords' && input.name == 'withoutTheWords') {
                        input.value = data[i].values;
                    }
                    else if (data[i].label == 'withWildcardSearch' && input.name == 'withWildcardSearch') {
                        input.value = data[i].values;
                    }
                })
            }
        }
        this.refineSearch();
    }
    handleRefineSearch() {
        this.showAdvanceSearch = !this.showAdvanceSearch;
        if(this.template.querySelector('[data-id="formBlock"]') && this.template.querySelectorAll('.su__backdrop')) {
            if (this.showAdvanceSearch) {
                this.template.querySelector('[data-id="formBlock"]').classList.remove('mainFormDiv');
                this.template.querySelectorAll('.su__backdrop').forEach(f => f.classList.remove('su__d-none'));
            } else {
                let inputs = this.template.querySelectorAll(".su__advance_group lightning-input");
                inputs.forEach(input => {
                    if (input.name === 'exactPhrase' && this.exactPhrase.length === 0) {
                        input.value = '';
                    }
                    if (input.name === 'withOneOrMore' && this.withOneOrMore.length === 0) {
                        input.value = '';
                    }
                    if (input.name === 'withoutTheWords' && this.withoutTheWords.length === 0) {
                        input.value = '';
                    }
                    if (input.name === 'withWildcardSearch' && this.withWildcardSearch.length === 0) {
                        input.value = '';
                    }
                })
                this.advanceSearchFieldValues(inputs);
                this.template.querySelector('[data-id="formBlock"]').classList.add('mainFormDiv');
                this.template.querySelectorAll('.su__backdrop').forEach(f => f.classList.add('su__d-none'));
            }
        }
    }

    advanceSearchFieldValues(inputs) {
        inputs.forEach(input => {
            if (input.name == 'exactPhrase')
                this.exactPhrase = input.value.trim();
            else if (input.name == 'withOneOrMore')
                this.withOneOrMore = input.value.trim();
            else if (input.name == 'withoutTheWords')
                this.withoutTheWords = input.value.trim();
            else if (input.name == 'withWildcardSearch')
                this.withWildcardSearch = input.value.trim();
        })
    }

    refineSearch(event, clearFilters) {
        fireEvent(null, "disableSmartFacets", false);
        let inputs = this.template.querySelectorAll(".su__advance_group lightning-input");
        if (!clearFilters && inputs){
            this.advanceSearchFieldValues(inputs);
            this.exactPhraseOnRefine= this.exactPhrase;
            this.withOneOrMoreOnRefine = this.withOneOrMore;
            this.withoutTheWordsOnRefine = this.withoutTheWords;
            this.withWildcardSearchOnRefine = this.withWildcardSearch;
        }
        if (this.withWildcardSearchOnRefine.length === 0) {
            this.isWildCardEnabledfromas = false
        } else {
            this.isWildCardEnabledfromas = true
        }
        if (this.isWildCardEnabledfromas) {
            this.sessionToggle = true;
            window.sessionStorage.setItem('sessionToggle', this.sessionToggle);
            fireEvent(null, 'setsearchstring', this.withWildcardSearch);
            fireEvent(null, 'wildcardEnabled', true);
        }


        if (this.exactPhraseOnRefine.length === 0 && this.withOneOrMoreOnRefine.length === 0 && this.withoutTheWordsOnRefine.length === 0 && this.withWildcardSearchOnRefine.length === 0) {
            this.isActiveAdvanceSearchClass = false;
            if (!clearFilters) {
                return;
            }
        } 
        else {
            this.isActiveAdvanceSearchClass = true;
        }
        this.handleRefineSearch();
        var sendData = { "exactPhrase": this.exactPhraseOnRefine, "withOneOrMore": this.withOneOrMoreOnRefine, "withoutTheWords": this.withoutTheWordsOnRefine, 'withWildcardSearch': this.withWildcardSearchOnRefine, "isWildCardEnabledfromas": this.isWildCardEnabledfromas };
        fireEvent(null, "advancePagination", sendData);
        if (this.exactPhraseOnRefine || this.withOneOrMoreOnRefine || this.withoutTheWordsOnRefine) {
            fireEvent(null, 'showclearfilter', true);
        }
    }
    enterKeyAdvanceSearch(event) {
        if (event.which == 13) {
            this.refineSearch(event);
        } else {
            let advanceSearchFields = this.template.querySelectorAll(".su__advance_group lightning-input");
            this.advanceSearchFieldValues(advanceSearchFields);
        }
    }
}