import { LightningElement, api, track } from 'lwc';
import { fireEvent } from 'c/authsupubsub_b6b3_13';
export default class SU_AuthSticky extends LightningElement {
    @api loading = '';
    @track showFilterState = '';
    @track deleteAction = false;
    showAll = false;
    @api selectedStickyFilter;
    selectedFilterToShow;
    @track selectedStickyFilterToShow = [];
    @track allSelectedFacets = [];
    @api totalresults;
    @api toshow;
    get stickyFacetsToShow() {
        this.selectedStickyFilterToShow = JSON.parse(JSON.stringify(this.selectedStickyFilter));
        if (this.selectedStickyFilter.length) {
            if (!this.showAll) {
                if (this.selectedStickyFilterToShow.length > 2) {
                    this.showFilterState = 'all';
                    this.selectedStickyFilterToShow = this.selectedStickyFilterToShow.slice(0, 2)
                }
                else if (this.selectedStickyFilterToShow.length <= 2) {
                    this.showFilterState = '';
                }
            }else if(this.showAll && this.selectedStickyFilterToShow.length <= 2 ){
                this.showFilterState = ''
            }else if(this.showAll && this.selectedStickyFilterToShow.length > 2 ){
                this.showFilterState = 'less';
            }
            fireEvent(null, 'selectedFacetData', this.selectedStickyFilterToShow);
            return this.selectedStickyFilterToShow;
        }
        else {
            return []
        };
    }
    get showAllFilters() {
        return this.showFilterState === 'all';
    }
    get showLessFilters() {
        return this.showFilterState === 'less';
    }
    get showNoResults() {
        return ((this.loading && !this.loading.length) || !this.loading) && !this.totalresults ? true : false;
    }
    get showClearFiltersButton1() {
        return (this.selectedStickyFilter && this.selectedStickyFilter.length) || !this.totalresults ? true : false;
    }
    
    clearAll() {
        this.toshow = false;
        fireEvent(null, "clearFilterDataEvent", null);
        fireEvent(null, "clearFilterSecEvent", null);
    }
    getAllStickyFacets(e) {
        this.showAll = !this.showAll
        const currentValue = e.target.dataset.val;
        const originalSelectedStickyFilter = JSON.parse(JSON.stringify(this.selectedStickyFilter));
        if (currentValue === 'less') {
            this.showFilterState = 'less';
            this.selectedStickyFilterToShow = originalSelectedStickyFilter;

        } else if (currentValue === 'all') {
            this.showFilterState = 'all';
            this.selectedStickyFilterToShow = originalSelectedStickyFilter.slice(0, 2);
        }
        else {
            let message = "header";
            fireEvent(null, 'headerSUData', message);
        }
    }
}