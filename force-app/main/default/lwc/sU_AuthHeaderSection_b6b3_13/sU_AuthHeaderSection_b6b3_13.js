import { LightningElement, api, track } from 'lwc';
import { registerListener, unregisterListener, fireEvent } from 'c/authsupubsub_b6b3_13';

export default class SU_AuthHeaderSection extends LightningElement {
    @api showClearFiltersButton;
    @api searchString;
    @track toShowModal = false;
    @api langlist;
    @api recordId;
    @api aggregationsData;
    @api recordIdfromSUParent;
    @api selectedStickyFilter;
    @api showFilter;
    @api tabsFilter;
    @api uid;
    @api endPoint;
    @api allarehidden;
    @api bearer;
    @api exactphrase;
    @api withoneormore;
    @api withoutthewords;
    @api withwildcardsearches;
    @api updateadvancesearch;
    @api advancedSearchSelected = false;
    @api searchQuery;
    @api isWildCardEnabled;
    @api bookmarkList;
    @api allContentHideFacet = false;
    @api languageEnabled = false;
    @api mergedArray;
    @api urlopensinnewtab;
    @api translationObject;
    @api hasWildcardSearch
    @api totalresults;
    @api mergedresults;
    @api pagenum;
    @api totalpages;
    @api searchresultime;
    @track gridDisplay = {};
    @track DataLoaded = false;
    @api sortByCheck;
    @track suListViewActive = 'su__view-active';
    @track suGridViewActive = '';
    @api activelistview;
    @api showHideDidYouMean;
    @api correctspell
    filterButtonClass = 'su__text-center su__bg-white su__p-2 su__border su__radius su__cursor su__filters-button su__loading-view';

    connectedCallback() {
        registerListener('dataFromContainer', this.handleDataFromContainer, this);
        registerListener('activemobileview', this.gridView, this);
        registerListener('filterClosed', this.filterClosed, this);
        registerListener('viewAllStickyButton', this.viewAllStickyButton, this);
        registerListener('closeIcon', this.closeIcon, this);
        if (this.activelistview) {
            this.listView()
        } else {
            this.gridView();
        }
    }

    disconnectedCallback() {
        unregisterListener('dataFromContainer', this.handleDataFromContainer, this);
        unregisterListener('activemobileview', this.gridView, this);
        unregisterListener('filterClosed', this.filterClosed, this);
        unregisterListener('viewAllStickyButton', this.viewAllStickyButton, this);
        unregisterListener('closeIcon', this.closeIcon, this);
    }

    correctSpelling() {
        fireEvent(null, 'setsearchstring', this.correctspell);
        fireEvent(null, 'searchPage', { searchString: this.correctspell, isFreshSearch: -1 });
    };

    renderedCallback() {
        this.DataLoaded = true;
        this.allContentHideFacet = this.aggregationsData && (this.aggregationsData.length == 0 || this.aggregationsData.length == 1);
        if (this.allContentHideFacet) {
            this.filterButtonClass = 'su__facethide-inner su__text-center su__p-2 su__border su__radius su__bg-white su__cursor su__filters-button su__disable-btn';
        }
        else if (this.allarehidden) {
            this.filterButtonClass = 'su__text-center su__p-2 su__border su__radius su__bg-white su__filters-button su__disable-btn';

        }
        else {
            this.filterButtonClass = 'su__text-center su__p-2 su__border su__radius su__bg-white su__cursor su__filters-button';
        }

        if (this.selectedStickyFilter && this.selectedStickyFilter.length) {
            this.stickyFacets = true;
        } else {
            this.stickyFacets = false;
        }
    }

    filterClosed() {
        if (this.template.querySelector('[data-id="filterBlock"]')) {
            this.template.querySelector('[data-id="filterBlock"]').classList.remove('filter-absolute');
        }
        this.showFilter = false;
    }

    starClicked() {
        this.toShowModal = true;
        fireEvent(null, 'starclickedbookmark', true);
    }

    closeIcon() {
        this.toShowModal = false;
        fireEvent(null, 'starclickedbookmark', false);
    }

    viewAllStickyButton() {
        this.template.querySelector('[data-id="filterBlock"]').classList.add('filter-absolute');
    }

    //this method is called when button is clicked and will fire the event to parent(SuSearchClientLWC Container)
    handleUtilitySlider() {
        this.showFilter = true;
        let message = "header";
        fireEvent(null, 'headerSUData', message);
        fireEvent(null, 'showMobileFilter', null);
        document.body.style.overflow = 'hidden';
        document.body.style['overflow-y'] = "hidden";
    }

    gridView() {
        this.gridDisplay.mainDivClass = "width:48%;margin-left:15px;border-radius: 5px;margin:0 15px 24px 1px;"
        this.gridDisplay.divtextAlignment = 'display:flex;flex-direction: column-reverse;'
        this.gridDisplay.gridElementMetaData = 'su__meta-date-gridView su__word-break su__pt-1 su__loading-view';
        this.gridDisplay.suActiveView = 'gridView';
        this.suGridViewActive = 'su__view-active';
        this.suListViewActive = '';
        setTimeout(() => {
            fireEvent(null, 'dataSectionView', this.gridDisplay);
        });

    }
    listView() {
        this.gridDisplay.mainDivClass = "width:100%;border-radius: 5px;margin-left: 1px; margin-top: 1px; margin-right: 1px;";
        this.gridDisplay.divtextAlignment = 'display:flex;align-items:center';
        this.gridDisplay.gridElementMetaData = 'su__meta-date su__word-break su__pt-1 su__loading-view';
        this.gridDisplay.suActiveView = 'listView';
        this.suListViewActive = 'su__view-active';
        this.suGridViewActive = 'su__GridViewIconColor';
        setTimeout(() => {
            fireEvent(null, 'dataSectionView', this.gridDisplay);
        });
    }

    removeWildcardSearch() {
        fireEvent(null, 'removeWildcardSearch', this);
    }

    handleDataFromContainer(event) {
        this.recordIdfromSUParent = event.recorId;
        this.aggregationsData = event.aggregationsData;
        this.selectedStickyFilter = event.selectedStickyFilter;
        this.tabsFilter = event.tabsFilter;
        this.showClearFiltersButton = event.showClearFiltersButton;
        this.bookmarkList = event.bookmarkList;
    }
}