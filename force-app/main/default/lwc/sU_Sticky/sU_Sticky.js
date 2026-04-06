import { LightningElement , api, track} from 'lwc';
import { fireEvent } from 'c/supubsub';

export default class SU_Sticky extends LightningElement {
    @api loading = '';
    viewAllStickyButton = false;
    @track showFilterState = '' ;
    @track deleteAction = false;
    @track stickyClass ="su__mt-2 su__d-flex "
    showAll = false;
    @track classesForSticky = "su__d-none";
    @api selectedStickyFilter;
    @track bigscreen;
    selectedFilterToShow ;
    @track  selectedStickyFilterToShow =[];
    @api totalresults;
    @api showviewmore ;
    @api eventCode;
    _toshow;
    @api
    get toshow() {
        return this._toshow;
    }

    set toshow(value) {
        this._toshow = value;
    }
    @api 
    set bigScreenVar(val){
    this.bigscreen = val;
    }
    get bigScreenVar(){
    return this.bigscreen;
    }
     
    get stickyFacetsToShow() {
        
        try {
            this.selectedStickyFilterToShow = JSON.parse(JSON.stringify(this.selectedStickyFilter));
        } catch (error) {
            console.error("An error occurred while creating a deep copy:", error);
        }
        
        if (this.selectedStickyFilter.length) {
            if (this.bigscreen) {
                this.viewAllStickyButton = false;
                if (!this.showAll) {
                    if (this.selectedStickyFilterToShow.length > 2) {
                        this.showFilterState = 'all';
                        this.selectedStickyFilterToShow = this.selectedStickyFilterToShow.slice(0, 2)
                    }
                    else if (this.selectedStickyFilterToShow.length <= 2) {
                        this.showFilterState = '';
                    }
                } else if (this.showAll && this.selectedStickyFilterToShow.length <= 2) {
                    this.showFilterState = ''
                } else if (this.showAll && this.selectedStickyFilterToShow.length > 2) {
                    this.showFilterState = 'less';
                }


            } else if (!this.bigscreen) {
                try {
                    this.selectedStickyFilterToShow = JSON.parse(JSON.stringify(this.selectedStickyFilter.slice(0, 1)));
                } catch (error) {
                    console.error("An error occurred while copying the array:", error)
                }

                this.selectedStickyFilterToShow[0].values = this.selectedStickyFilterToShow[0].values.slice(0, 3);
                this.viewAllStickyButton = this.selectedStickyFilter.length > 1 || this.selectedStickyFilter[0].values.length > 3;

            } 
            return  this.selectedStickyFilterToShow;
            
        }      
            this.viewAllStickyButton = false;
            return []
    }
    get showAllFilters () {
        return this.showFilterState === 'all';
    }
    get showLessFilters () {
        return this.showFilterState === 'less';
    }
    get showNoResults() {
        return (this.loading ==='' && !this.totalresults) ? true : false;
    }
    get showClearFiltersButton1() {
        return (this.selectedStickyFilter && this.selectedStickyFilter.length) || (this.loading==='' && !this.totalresults) ? true : false;
    }
    clearAll(){
        this._toshow = false;
        fireEvent(this.pageRef, "clearFilterDataEvent"+this.eventCode, null);
        fireEvent(this.pageRef, "clearFilterSecEvent"+this.eventCode, null);
    }
    
    renderedCallback() {
        if (this.bigscreen === false) {
            this.classesForSticky = 'su__d-none';
            this.stickyClass = "su__mt-2 su__d-flex "
        }
        else if (this.bigscreen === true) {
            this.classesForSticky = 'su__d-block';
            this.stickyClass = "su__mt-2"
        }
    }
    getAllStickyFacets(e) {
        this.showAll = !this.showAll
        const currentValue = e.target.dataset.val;
        let originalSelectedStickyFilter;
        try {
            originalSelectedStickyFilter = JSON.parse(JSON.stringify(this.selectedStickyFilter));
        } catch (error) {
            console.error("An error occurred while creating a deep copy:", error);
        }
        
        if (currentValue === 'less') {
            this.showFilterState = 'less';
            this.selectedStickyFilterToShow = originalSelectedStickyFilter;
            
        } else if (currentValue === 'all') {
            this.showFilterState = 'all';
            this.selectedStickyFilterToShow = originalSelectedStickyFilter.slice(0, 2);
        }
        else {
            fireEvent(null, 'viewAllStickyButton' + this.eventCode, { show: this.viewAllStickyButton });
            let message = "header";
            fireEvent(null, 'headerSUData' + this.eventCode, message);
        }
     }
    }