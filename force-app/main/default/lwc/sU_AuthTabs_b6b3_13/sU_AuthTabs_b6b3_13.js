import { LightningElement, api, track, wire } from 'lwc';
import { registerListener, fireEvent, unregisterListener } from 'c/authsupubsub_b6b3_13';

export default class SU_AuthTabs extends LightningElement {
    allContentTabSelected = false;
    @api showFilter1 = false;
    @api aggregationsdata;
    previousIndexVal = '';
    @track contentTab = [];
    @track showArrowIcon = false;
    showMergedCSTabs = false;
    @api mergeSourcesTypeIndex;
    @track active;
    @track selectedChildArray;
    @track selectedMergedCsVal;
    sourceArr = [{
        "key": "all",
        "values": "All Content"
    }];
    @api
    set tabsfilter(value) {
        if (value)
            this.contentTab = JSON.parse(JSON.stringify(value));
    };
    get tabsfilter() {
        return this.contentTab;
    }
    tabClicked2(event) {
        this.tabClicked(event);
        this.showMergedCs();
    }
    connectedCallback() {
        registerListener('tabClicked', this.tabClicked, this);
    }

    disconnectedCallback() {
        unregisterListener('tabClicked', this.tabClicked, this);
    }

    get showHideContentTabs() {
        return this.contentTab.length > 1 ? true : false;
    }
    tabClicked(event) {
        if (event && event.target.dataset.name != 'all') {
            this.allContentTabSelected = true;
            this.showFilter1 = true;
        } else {
            this.allContentTabSelected = false;
            this.showFilter1 = false;
        }
        if (this.previousIndexVal == '') {
            this.previousIndexVal = event.target.dataset.name;
        }
        if (event && this.previousIndexVal != '' && this.previousIndexVal != event.target.dataset.name) {
            if (this.template.querySelector(`[data-name= '${this.previousIndexVal}']`) && this.template.querySelector(`[data-name='${this.previousIndexVal}']`).classList) {
                this.template.querySelector(`[data-name='${this.previousIndexVal}']`).classList.remove('active-type');
            }
            this.previousIndexVal = event.target.dataset.name;
        }
        var currentIndex = event && event.target.dataset.name;
        if (this.template.querySelector(`[data-name='${currentIndex}']`) && this.template.querySelector(`[data-name='${currentIndex}']`).classList) {
            this.template.querySelector(`[data-name='${currentIndex}']`).classList.add("active-type");
        }
        if (event && event.target.dataset.mergedchild == 'true' && this.template.querySelector(`[data-name='${event.target.name}']`) && this.template.querySelector(`[data-name='${event.target.name}']`).classList) {
            this.template.querySelector(`[data-name='${event.target.name}']`).classList.add("active-type");
            this.previousIndexVal = event.target.name;
        }
        if (this.sourceArr.length == 0) {
            this.sourceArr.push({
                "key": event.target.dataset.mergedchild == 'true' ? event.target.name : event.target.dataset.name || 'all',
                "values": event.target.label || 'All Content'
            });
        } else {
            this.sourceArr.splice(0, 1, {
                "key": event.target.dataset.mergedchild == 'true' ? event.target.name : event.target.dataset.name || 'all',
                "values": event.target.label || 'All Content'
            });
        }

        var data = event && event.target.dataset;
        var filterValue;
        if (this.sourceArr && !this.sourceArr[0].key && !this.sourceArr[0].values) {
            filterValue = [];
        } else if (this.sourceArr && this.sourceArr[0].key === 'all' && this.sourceArr[0].values === 'All Content') {
            filterValue = [];
        }
        else if (this.sourceArr && this.sourceArr[0].key && this.sourceArr[0].values && this.aggregationsdata[0].key == '') {
            this.aggregationsdata.map((data, index) => {
                if (data.key == '_type') {
                    filterValue = [{ type: this.aggregationsdata[index].key, filter: [] }];
                }
            })
        }
        else {
            filterValue = [{ type: this.aggregationsdata[0].key, filter: [] }];
        }
        if (!data.merged && data.name != 'all' && filterValue.length !== 0) {
            if (this.mergeSourcesTypeIndex === true) {
                filterValue[0].filter = [data.name]
            } else if (event.target.dataset.objname != '' && event.target.dataset.objname !== undefined && (this.aggregationsdata[0].key == '' || this.aggregationsdata[0].key == '_type')) {
                filterValue[0].filter = [event.target.dataset.objname]
            } else {
                filterValue[0].filter = [data.name]
            }
        } else if (data.merged && !data.showchild && filterValue.length !== 0) {
            let index = data.ind;
            this.contentTab[index].childArray.forEach(function (ele) {
                filterValue[0].filter.push(ele.Contentname);
            });
        }
        fireEvent(null, 'tabClickedMethod', {filterValueData : filterValue,selectedCs : event && event.target.dataset.name });
    }
    showMergedCs(event) {
        let ind = event && event.currentTarget && event.currentTarget.dataset.ind;
        ind = ind >= 0 ? ind : this.mergedTabIndex;
        if (ind >= 0) {
            this.contentTab[ind].showMergedCSTabs = !this.contentTab[ind].showMergedCSTabs;
            this.mergedTabIndex = ind;
        }
        if (ind >= 0 && this.contentTab[ind].showMergedCSTabs) {
            for (let j = 0; j < this.template.querySelectorAll('[data-id="su__overflow-visible"]').length; j++) {
                this.template.querySelectorAll('[data-id="su__overflow-visible"]')[j].classList.add('su__overflow-visible');
            }
        } else {
            for (let j = 0; j < this.template.querySelectorAll('[data-id="su__overflow-visible"]').length; j++) {
                this.template.querySelectorAll('[data-id="su__overflow-visible"]')[j].classList.remove('su__overflow-visible');
            }
        }
    }
    renderedCallback() {
        var selectedTab = '';
        var CsNavBar = this.template.querySelector('[data-id="su__csNavbar"]');
        var internalCsDiv = this.template.querySelector('[data-name="internal__div"]');
        if (this.sourceArr) {
            selectedTab = this.sourceArr[0].key;
        } else {
            selectedTab = 'all';
        }
        if (this.aggregationsdata && this.aggregationsdata.length) {
            this.selectedMergedCsVal = '';
            if (this.aggregationsdata && this.aggregationsdata.length && this.aggregationsdata[0].values && this.aggregationsdata[0].values.find(f => f.selected)) {
                var selectedTabObj = this.aggregationsdata[0].values.find(f => f.selected);
                selectedTab = selectedTabObj.Contentname;
            } else if (this.aggregationsdata && this.aggregationsdata.length && this.aggregationsdata[0].values && this.aggregationsdata[0].values.find(f => f.indeterminate)) {
                var selectedTabObj = this.aggregationsdata[0].values.find(f => f.indeterminate);
                selectedTab = selectedTabObj.Contentname;
                this.selectedChildArray = selectedTabObj.childArray.filter(item => {
                    return item.selected
                });
                if(this.selectedChildArray){
                  this.selectedMergedCsVal = this.selectedChildArray[0].Contentname;
                }
            }
            else {
                selectedTab = 'all';
                this.selectedMergedCsVal = selectedTab;
                }
            if (this.previousIndexVal && this.template.querySelector(`[data-name='${this.previousIndexVal}']`) && this.template.querySelector(`[data-name='${this.previousIndexVal}']`).classList)
                this.template.querySelector(`[data-name='${this.previousIndexVal}']`).classList.remove("active-type");
            this.previousIndexVal = selectedTab;
            
            let focusCSTab = this.template.querySelector(`[data-name='${selectedTab}']`)
            if (focusCSTab && focusCSTab.classList) {
                focusCSTab.classList.add("active-type");
            }
            if(CsNavBar && focusCSTab) {
                const containerRect = CsNavBar.getBoundingClientRect();
                const targetRect = focusCSTab.getBoundingClientRect();
                const position = targetRect.left - containerRect.left;
                CsNavBar.scrollLeft = position;
            }
            var mergeCsTab = this.template.querySelector('[data-id="mergedcs"]');
            if (mergeCsTab) {
                var mergeCsWidth = mergeCsTab.offsetWidth;
                if (mergeCsWidth) {
                    var optionTabsDiv = this.template.querySelector('[data-id="optionTabs"]');
                    if (optionTabsDiv) {
                        optionTabsDiv.style.width = mergeCsWidth + 'px';

                    }

                }
            }
        }
        
        if (CsNavBar && internalCsDiv) {
            var navBarWidth = CsNavBar.offsetWidth;
            var internalCsWidth = internalCsDiv.offsetWidth;
            if (internalCsWidth > navBarWidth) {
                this.showArrowIcon = true;
            } else {
                this.showArrowIcon = false;
            }
        }
        this.active = selectedTab;
        if(this.selectedMergedCsVal){
            this.active = this.selectedMergedCsVal;
        }
        fireEvent(null, 'selectedCsTab', this.active);
    }
    
    nextContentSource() {
        const divElement = this.template.querySelector('[data-id="su__csNavbar"]');
        divElement.scrollLeft += 100;
    }
    previousContentSource() {
        const divElement = this.template.querySelector('[data-id="su__csNavbar"]');
        divElement.scrollLeft += -100;
    }
    
}