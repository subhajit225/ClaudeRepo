import { LightningElement, api, track } from 'lwc';
import { registerListener, unregisterListener, fireEvent } from 'c/supubsub';
import { NavigationMixin } from 'lightning/navigation';
import { getFocusedTabInfo } from 'lightning/platformWorkspaceApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import assignArticleToCase from '@salesforce/apex/su_vf_console.SUVFConsoleController.assignArticleToCase';
import doesKnowledgeExist from '@salesforce/apex/su_vf_console.SUVFConsoleController.doesKnowledgeExist';
import createLinkOfAttachment from '@salesforce/apex/su_vf_console.SUVFConsoleController.createLinkOfAttachment';
import getAttachmentRelatedInfo from '@salesforce/apex/su_vf_console.SUVFConsoleController.getAttachmentRelatedInfo';
export default class SU_SearchDataSection extends NavigationMixin(LightningElement) {
    @api failText;
    @api emptySearchString;
    @api searchString;
    @api pageNum;
    @api uid;
    @api totalResults;
    @api gptLinks = [];
    @api gptActive;
    @api gptContext;
    @api bearer;
    @api isUtility;
    @api endPoint;
    @track showArticlePreview = false;
    @track articleRecordExists=false;
    @track attached_Attachments;
    @api maincontainerwidth;
    @track fileAttachment = false;
    @api containerrightcoordinate;
    @api mergeSourcesTypeIndex;
    @track titleImage;
    @track attachLink;
    currentHeight;
    @api senddata;
    @api aggregationsdata;
    @api totalpages;
    @api searchresultime;
    @track showIcon = false;
    firstStickyLabel;
    filterValueOne = [];
    firstStickyLabel1 = false;
    @api totalresults;
    @api resultlabel;
    @api pagenum;
    @track clearAllClass="su__clear-filters-btn su__cursor  font-12 su__font-bold su__mb-2 su__p-0  su__loading-view "
    @api showArticle = false;
    eventSortType = '';
    previousIndexVal = '';
    advFilterData;
    @track dataSectionClasses = 'su__d-block';

    @track result;
    @track ptitle;
    @track objName;
    @track idd;
    @track sourcename;
    @api recordId;
    previewModalVal = false;
    previewSrcVal = '';
    typeofContentForPreview = '';
    previewSourceLabel= '';
    showAllFilters;
    showClearFiltersButton;

    listofStickyFacet = [];
    sourceArr = [{
        "key": "all_Content",
        "values": "All Content"
    }];
    listofStickyFacet1 = [];
    hoverResult = {};
    offsetWidth;
    anchorTagXposition;
    anchorTagOffsetHeight;
    topNew;
    clientLeft;
    clientRight
    @api caseIdExists;
    prevIndex = '';
    _index;
    @track responselistdata = [];
    @api searchStringFromBanner;
    @api
    get index() {
        return this._index;
    }

    set index(value) {
        this._index = value;
    }
    @api
    set responseListData(value) {
        if (value) {
            try{
                this.responselistdata = JSON.parse(JSON.stringify(value));
            } catch(error){
                console.log(error);
            }
            
        }
    }
    bigscreen;
    @api 
    set bigScreen(val){
       if(val){
        this.bigscreen = val;
       } 
        
    }
    get bigScreen(){return this.bigscreen}
    get responseListData() {
        return this.responselistdata;
    }
    @track nogpt = true;
    @api
    set generateAnswerBtn(v){
        this.nogpt = v;
    }
    get generateAnswerBtn(){
        return this.nogpt;
    }
    @api loading = '';
    viewAllStickyButton = false;
    @api selectedStickyFilter;
    @api eventCode;
    @api summaryCollapsible;
    @api mergedresults;
    @api urlopensinnewtab;
    rangerId='';
    left;
    timerid ;
    top;
    oldRangerId;
    @api height;
    @track stickyFacets;
    @api sortByCheck;
    DataLoaded = false;
    @api hasWildcardSearch ;
    currentDivHeight=600;
    previousCurrentDivHeight;
    currentDivWidth;
    @api utilityWidth;
    @api utilityTop;
    @api translationObject;
    diamond;
    emailHref='';
    @api currentUserEmail;
    activeTabId = '';
    showSendAsEmailBlock = false;
    @api tabsfilter;
    linkMouseOutFuncExecuted = false;
    @api caseSubjectVal
    @api checkCaseEmpty;
    get showClearFiltersButton1() {
        return (this.selectedStickyFilter && this.selectedStickyFilter.length) || (this.loading==='' && !this.totalresults) ? true : false;
    }

    get showNoResults() {
            return this.loading === '' && !this.totalresults ? true : false;   
    }

    get showBackupResults() {
        return this.responselistdata && this.responselistdata.length ? true : false;
    }
    // Code Added for preview Start
    closeKnowledgeWidget(event){
        this.handleMouseout(event);
    }

    get showHideGenerateAnswerButton(){
        return this.nogpt && this.hideGptOnFirstLoad === 'su__d-none';
    }     
    get hideGptOnFirstLoad(){
        return  this.gptActive && ((this.nogpt || this.totalresults == 0 ) || this.checkCaseEmpty  ) ? 'su__d-none' : '';
    }

    async articleMouseHover(event) {
        this.template.querySelector('div.ModelTooltip') && this.template.querySelector('div.ModelTooltip').classList.remove('noRecord')
        clearTimeout(this.timerid);
        const toolTipDiv = this.template.querySelector('div.ModelTooltip');
        toolTipDiv.style.opacity = 0;
        toolTipDiv.style.display = "block";
        this.template.querySelector('div.container').className = 'container';
        this.linkMouseOutFuncExecuted = false;
        this.showArticlePreview = false;
        let currentId = event.target.dataset.id; // Setting the id in new var as we are not able to access them in Async calls
        if(currentId && (currentId.startsWith('ka0') || currentId.startsWith('500')) && 580 < window.innerWidth) {
            this.diamond = 'su__diamond-left';
            event.preventDefault();
            var eve = event.target;
            this.rangerId = currentId;
            this.offsetWidth = event.currentTarget.offsetWidth;
            this.anchorTagXposition = event.offsetX;
            this.anchorTagOffsetHeight = event.target.offsetHeight;
            if(this.template.querySelector(`[data-id="${eve.dataset.id}"]`)) {
                var clientyy = this.template.querySelector(`[data-id="${eve.dataset.id}"]`).getBoundingClientRect().y;
                this.clientLeft = this.template.querySelector(`[data-id="${eve.dataset.id}"]`).getBoundingClientRect().left;
                this.clientRight = this.template.querySelector(`[data-id="${eve.dataset.id}"]`).getBoundingClientRect().right;
                this.topNew = clientyy + (this.anchorTagOffsetHeight / 2);
            }
            this.left = event.clientX;
            this.top = clientyy;
            
            // check if article exist
            await doesKnowledgeExist({ knowledgeId: currentId }).then(result => {
                if (result) {
                    this.showArticlePreview = true; // Article exists
                    this.articleRecordExists = true;
                    this.hoverResult = eve.name;
                    if (eve.name !== undefined && this.showArticlePreview) {
                        if (this.rangerId === undefined || (eve.name != null && eve.name.Id !== undefined && eve.name.Id !== this.oldRangerId)) {
                            this.oldRangerId = this.rangerId;
                            this.rangerId = eve.name.Id;
                        }
                    }
                }
                else {
                    this.showArticlePreview = true; // Article not exists
                    this.articleRecordExists = false;
                    this.template.querySelector('div.ModelTooltip').classList.add('noRecord');
                    this.currentDivHeightWidth(event);
                }
            })
            .catch(error => {
                console.log('Knowledge Id is not valid or knowledge not part of current org ', error);
            });

            if (this.articleRecordExists && currentId.startsWith('ka0')) {
                // Check for the Files from related List
                createLinkOfAttachment({ recordId: currentId })
                .then(result => {
                    if (result.length > 0) {
                        this.fileAttachment = result;
                    }
                    else {
                        this.fileAttachment = false;
                    }
                })
                .catch(error => {
                    console.log(`error>>>>>>"  'No Files exists' + ${JSON.stringify(error)}`);
                });

                // Check for the Attachments FYI depreciated Now in salesforce
                getAttachmentRelatedInfo({ recordId: currentId })
                .then(result => {
                    if(result) {
                        this.attached_Attachments = JSON.parse(result);
                        this.attached_Attachments = this.attached_Attachments.AttachmentList;
                        this.attached_Attachments = this.attached_Attachments.map((value) => {
                            if (value.fieldLabel.endsWith('(Name)')) {
                                let field_val = value.fieldLabel.substring(0, (value.fieldLabel).length - 6);
                                return { ...value, 'fieldLabel': field_val };
                            }
                                return { ...value }; 
                        });
                    }
                })
                .catch(error => {
                    console.log("error in getAttachmentRelatedInfo>>>>>>" + error + JSON.stringify(error));
                });
            }
        } else {
            toolTipDiv.style.display = "none"; // Not an article therefore hide the previe
        }
    }

    generateAnswer(){
        this.nogpt = false;
        fireEvent(null, 'showHideGpt'+this.eventCode, this.nogpt );
        fireEvent(null, 'searchCallMade'+this.eventCode, true );   
    }

    currentDivHeightWidth() {
        var modelTooltipElement = this.template.querySelector('div.ModelTooltip');
        var divContainerElement = this.template.querySelector("div.container");
        this.currentDivWidth = modelTooltipElement && modelTooltipElement.clientWidth;
        this.currentDivHeight = modelTooltipElement && modelTooltipElement.clientHeight;

        // calculating height and top
        var _height;
        var _top;
        var top = 40;
        if(this.articleRecordExists) {
            modelTooltipElement && modelTooltipElement.style.setProperty('width', 580 + 'px');
            this.currentDivWidth = modelTooltipElement && modelTooltipElement.clientWidth;
            if(window.innerWidth < (this.currentDivWidth + this.offsetWidth) - this.clientLeft + 10) {
                if(this.top < window.innerHeight/2) {
                    // show down side
                    _height = !this.utilityTop ? window.innerHeight - this.top - this.anchorTagOffsetHeight - 30 : window.innerHeight - this.top - this.anchorTagOffsetHeight - 20 - 40; /* 20  Diamond arrow height, 40 bottom utility bar */
                    _top = !this.utilityTop ? this.top + this.anchorTagOffsetHeight + 20 : this.top + this.anchorTagOffsetHeight + 20 - 100; /* 20  Diamond arrow height, 100 Utility Top space */
                    this.diamond = 'su__diamond-top';
                    modelTooltipElement && modelTooltipElement.style.setProperty('height', _height + 'px');
                    modelTooltipElement && modelTooltipElement.style.setProperty('top', _top + 'px');
                    modelTooltipElement && modelTooltipElement.style.setProperty('left', (window.innerWidth - this.currentDivWidth) / 2    + 'px');
                } else {
                    // show up side
                    _height = this.top - 20;
                    top = !this.utilityTop ? 5 : -(this.utilityTop - 50); /* 50 Utility Top space 45(header height) + 5 top space */
                    this.diamond = 'su__diamond-bottom';
                    modelTooltipElement && modelTooltipElement.style.setProperty('height', _height + 'px');
                    modelTooltipElement && modelTooltipElement.style.setProperty('top', top + 'px');
                    modelTooltipElement && modelTooltipElement.style.setProperty('left', (window.innerWidth - this.currentDivWidth) / 2 + 'px');
                }
            }else if(this.utilityWidth && this.utilityTop && window.location.href.indexOf('popout') === -1) {
                //_height = 600;
                modelTooltipElement && modelTooltipElement.style.setProperty('top', 'auto');
                modelTooltipElement && modelTooltipElement.style.setProperty('bottom', 0 + 'px');
                //modelTooltipElement && modelTooltipElement.style.setProperty('height', _height + 'px');
                // calculating diamond arrow postioning
                top = this.topNew - (window.innerHeight - (this.currentDivHeight + 35));
            } else {
                // calculating diamond arrow postioning
                if(this.currentDivWidth && window.location.href.indexOf('popout') !== -1){
                    const userAgent = window?.navigator?.userAgent;
                            // Check if the user is using Mac OS
                            const isMac = /Macintosh|Mac OS X/i.test(userAgent);
                            // Check if the user is using Windows
                            const isWindows = /Windows/i.test(userAgent);
                            if (isMac) {
                                top = (this.topNew - (window.innerHeight - this.currentDivHeight) / 2) - 20 ;
                            } else if (isWindows) {
                                top = (this.topNew - (window.innerHeight - this.currentDivHeight) / 2)  ;
                            } else {
                                top = (this.topNew - (window.innerHeight - this.currentDivHeight) / 2) - 10 ;
                            }
                }else{
                    top = (this.topNew - (window.innerHeight - this.currentDivHeight) / 2) - 10 ;
                }
            }
        } else {
            // this.template.querySelector('div.ModelTooltip').classList.add('noRecord');
            if(this.utilityWidth && this.utilityTop && window.location.href.indexOf('popout') === -1) {
                modelTooltipElement && modelTooltipElement.style.setProperty('top', (this.topNew - this.utilityTop - 4) + 'px');
            }
        }
        
        // calculating diamond arrow postioning
        divContainerElement && divContainerElement.style.setProperty("top", top + "px");

        //Article Preview box position from top
        if(!this.utilityWidth) {
            if (modelTooltipElement && modelTooltipElement && this.articleRecordExists) {
                if(this.diamond !== 'su__diamond-bottom' && this.diamond !== 'su__diamond-top'){
                    let temp = (window.innerHeight - this.currentDivHeight) / 2;
                    modelTooltipElement && modelTooltipElement.style.setProperty('top', temp + 'px');
                }
            } else {
                modelTooltipElement && modelTooltipElement.style.setProperty('top', (this.topNew - 50) + 'px');
            }
        }
        
        var left;
        //Article Preview box (calculation left and right position)
        if (modelTooltipElement && (!this.utilityWidth || window.location.href.indexOf('popout') !== -1)) {
            if(window.innerWidth < this.currentDivWidth + this.offsetWidth + 10) {
                    if(window.innerWidth - this.left >  this.currentDivWidth && window.location.href.indexOf('popout') !== -1){
                        modelTooltipElement && modelTooltipElement.style.setProperty('right', + 10 + 'px');
                        modelTooltipElement && modelTooltipElement.style.setProperty('left', 'auto' );
                        modelTooltipElement && modelTooltipElement.style.setProperty('top', + (window.innerHeight -  this.currentDivWidth - 50) / 2 + 'px');
                    }else{
                        if(window.location.href.indexOf('popout') !== -1){
                            modelTooltipElement && modelTooltipElement.style.setProperty('left', + 10 + 'px'  );
                            modelTooltipElement && modelTooltipElement.style.setProperty('top', + (window.innerHeight -  this.currentDivWidth - 50) / 2 + 'px');
                            this.diamond = "su__diamond-right";
                        }
                    }
                // calculation for small resolutions
            } else if((Math.round((this.left + 15 + this.currentDivWidth) / 5) * 5) < window.innerWidth) {
                if(window.innerWidth - ((this.clientLeft) + this.offsetWidth) < this.currentDivWidth) {
                    modelTooltipElement && modelTooltipElement.style.setProperty('left', 'auto');
                    modelTooltipElement && modelTooltipElement.style.setProperty('right', + 10 + 'px');
                } else {
                    if(this.clientLeft + this.offsetWidth + 15 + this.currentDivWidth < window.innerWidth) {
                        left = this.clientLeft + this.offsetWidth + 15;
                    } else {
                        left = this.clientLeft + this.offsetWidth + 15  - (this.clientLeft + this.offsetWidth + 15 + this.currentDivWidth - (window.innerWidth - 15));
                    }
                    if(this.currentDivWidth && window.location.href.indexOf('popout') !== -1){
                         modelTooltipElement && modelTooltipElement.style.setProperty('top', + (window.innerHeight -  this.currentDivWidth - 50  ) / 2 + 'px');
                    }
                    modelTooltipElement && modelTooltipElement.style.setProperty('right', + 10 + 'px');
                    modelTooltipElement && modelTooltipElement.style.setProperty('left', left + 'px');
                }
            } else {
                this.diamond = 'su__diamond-right';
                left = this.clientLeft - this.currentDivWidth - 20;
                
                if(0 < left) {
                    modelTooltipElement && modelTooltipElement.style.setProperty('left', + left + 'px');
                    modelTooltipElement && modelTooltipElement.style.setProperty('right', + 'auto');
                } else {
                    modelTooltipElement && modelTooltipElement.style.setProperty('left', + 10 + 'px');
                }
            }
        } else if(this.utilityWidth && this.utilityTop && window.location.href.indexOf('popout') === -1) {
            modelTooltipElement && modelTooltipElement.style.setProperty('left', this.offsetWidth + 35 + 'px');
        }
        
        // calculating diamond arrow postioning
        if(this.template.querySelector('div.container')) {
            this.template.querySelector('div.container').classList.add(this.diamond);
            if (this.diamond === 'su__diamond-right') {
                this.template.querySelector('div.container').style.setProperty('left', (10 + this.currentDivWidth - 18) + 'px');
            } else if (this.diamond === 'su__diamond-bottom' || this.diamond === 'su__diamond-top') {
                this.template.querySelector('div.container').style.setProperty('left', (this.currentDivWidth / 2) + 'px');
            }
        }

        if(!!this.currentDivHeight && !!this.currentDivWidth && !this.linkMouseOutFuncExecuted && this.showArticlePreview &&  modelTooltipElement) {
            modelTooltipElement && modelTooltipElement.style.setProperty("opacity", "1");
        } 
    }

    /* onmouseenter*/
    handleMouseover(event) {
        event.preventDefault();
        clearTimeout(this.timerid);
        if (this.rangerId === undefined || (event.target.name != null && event.target.name.Id !== undefined && event.target.name.Id !== this.oldRangerId)) {
            this.oldRangerId = this.rangerId;
            this.rangerId = event.target.name.Id;
        }
    }

    /* onmouseleave*/
    linkMouseOut(event) {
        event.preventDefault();
        this.timerid = setTimeout(() => {
            const toolTipDiv = this.template.querySelector('div.ModelTooltip');
            toolTipDiv.style.opacity = 0;
            toolTipDiv.style.display = "none";
            this.showArticlePreview = false;
            this.linkMouseOutFuncExecuted = true;
            this.template.querySelector('div.ModelTooltip').classList.remove('noRecord');
        }, 150);  // setTimeout is added on link to sustain popup for a second
    }
    
    handleMouseout(event) {
        event.preventDefault();
        clearTimeout(this.timerid);
        const toolTipDiv = this.template.querySelector('div.ModelTooltip');
        toolTipDiv.style.opacity = 0;
        toolTipDiv.style.display = "none";
        this.showArticlePreview = false;
        document.body.style.overflow = 'auto';
        this.template.querySelector('div.ModelTooltip').classList.remove('noRecord');
    }

    // Code Added for preview End
    clearFilterForSlider1(event) {
        fireEvent(null, 'clearAllFilters' + this.eventCode, null);
        fireEvent(null, 'tabClicked' + this.eventCode, event);
    }
    
    tabClicked(event){
        fireEvent(null, 'tabClicked' + this.eventCode, event);
    }

    showHideGpt(value){
        this.nogpt = value
    }

    connectedCallback() {
        getFocusedTabInfo().then((tabInfo) => {
            this.activeTabId = tabInfo.tabId;
        }).catch((error) => {
            console.log("[error]", error);
        });
        registerListener("checkType"+this.eventCode, this.checkDataFromSearchSection, this);
        registerListener("showclearfilterbtn"+this.eventCode, this.searchBtn, this);
        registerListener("advsearchstickyfltr"+this.eventCode, this.stickyFilterData, this);
        registerListener("sendtodatasection"+this.eventCode, this.dataFromFilterSection, this);
        registerListener("clearFilterDataEvent"+this.eventCode, this.handleClearFilterDataEvent, this);
        registerListener("closeSendEmailBlock"+this.eventCode, this.closeSendEmailBlock, this);
        registerListener("showHideGpt"+this.eventCode, this.showHideGpt, this);
    }
    
    disconnectedCallback(){
        unregisterListener("checkType"+this.eventCode, this.checkDataFromSearchSection, this);
        unregisterListener("showclearfilterbtn"+this.eventCode, this.searchBtn, this);
        unregisterListener("advsearchstickyfltr"+this.eventCode, this.stickyFilterData, this);
        unregisterListener("sendtodatasection"+this.eventCode, this.dataFromFilterSection, this);
        unregisterListener("clearFilterDataEvent"+this.eventCode, this.handleClearFilterDataEvent, this);
        unregisterListener("closeSendEmailBlock"+this.eventCode, this.closeSendEmailBlock, this);
        unregisterListener("showHideGpt"+this.eventCode, this.showHideGpt, this);
    }

    closeSendEmailBlock(){
        this.showSendAsEmailBlock = false;
    }
    
    //clear filter
    handleClearFilterDataEvent() {
        this.listofStickyFacet = [];
        var selectedTab = 'all_Content';
        this.sourceArr.splice(0, 1, {
            "key": "all_Content",
            "values": "All Content"
        });

        if (this.previousIndexVal !== '' && this.template.querySelector(`[data-name=' ${this.previousIndexVal}']`)) {
            this.template.querySelector(`[data-name=' ${this.previousIndexVal}']`).classList.remove("active-type");
            this.previousIndexVal = selectedTab;
        }
        if (this.template.querySelector(`[data-name='${selectedTab}']`))
            this.template.querySelector(`[data-name='${selectedTab}']`).classList.add("active-type")
        fireEvent(this.pageRef, 'clearStickyFilter' + this.eventCode, null);
    }

    dataFromFilterSection(data) {
        this.listofStickyFacet = [];
        this.listofStickyFacet = data.arr_StickyData;

    }

    stickyFilterData(data) {
        this.firstStickyLabel = data;
        if (this.firstStickyLabel.length > 0) {
            this.firstStickyLabel1 = true;
        }
        if (data.length > 1) {
            this.viewAll = true;
        }
        this.showAllFilters = data;

    }
    searchBtn(d) {
        this.showClearFiltersButton = d;
    }

    checkDataFromSearchSection(event) {
        this.eventSortType = event;
    }

    renderedCallback() {
        if(this.bigscreen){
            this.showIcon = true;
            this.dataSectionClasses = 'su__d-none'
            if(this.selectedStickyFilter && this.selectedStickyFilter.length ){
                this.stickyFacets = true;
            }else{
                this.stickyFacets = false;
            }
        }else{
            this.showIcon = false;
            this.dataSectionClasses = 'su__d-block'
            if(this.selectedStickyFilter && this.selectedStickyFilter.length ){
                this.stickyFacets = true;
            }else{
                this.stickyFacets = false;

            }
        }
        this.DataLoaded = true;
        var selectedTab = '';
        if (this.sourceArr) {
            selectedTab = this.sourceArr[0].key;
        } else {
            selectedTab = 'all_Content';
        }
        if (this.aggregationsdata && this.aggregationsdata.length) {
            if (this.aggregationsdata && this.aggregationsdata.length && this.aggregationsdata[0].values && this.aggregationsdata[0].values.find(f => f.selected)) {
                var selectedTabObj = this.aggregationsdata[0].values.find(f => f.selected);
                selectedTab = selectedTabObj.Contentname;
            } else selectedTab = 'all_Content';
            if (this.previousIndexVal && this.template.querySelector(`[data-name='${this.previousIndexVal}']`))
                this.template.querySelector(`[data-name='${this.previousIndexVal}']`).classList.remove("active-type");
            this.previousIndexVal = selectedTab;
            if (this.template.querySelector(`[data-name='${selectedTab}']`)) {
                this.template.querySelector(`[data-name='${selectedTab}']`).classList.add("active-type")
            }
        }
        if(this.selectedStickyFilter && this.selectedStickyFilter.length ){
            this.stickyFacets = true;

        }else{
            this.stickyFacets = false;
        }

    }

    openPreviewModal(event){
        this.runScriptMethod(event);
        this.typeofContentForPreview = event.currentTarget.dataset.title || event.currentTarget.dataset.value;
        this.previewSrcVal  = this.modifyUrlForPreview(event.currentTarget.dataset.value); 
        this.previewSourceLabel = event.currentTarget.dataset && event.currentTarget.dataset.tag;
        this.previewModalVal = true;
    }

    closePreviewModal(){
        this.previewModalVal = false;
    }
     modifyUrlForPreview(url){
        if (url.toLowerCase().includes('youtube.com')) {
            return url.replace('watch?v=', 'embed/')
        }
        else if (url.toLowerCase().includes('vimeo.com')) {
            return 'https://player.vimeo.com/video/' + url.split('.com/')[1];
        }
        return url 
    }

    // This method is used to toggle show and hide of filter data
    handleInsideFilters(event) {
        this._index = event.currentTarget.dataset.rank;
        if (this.prevIndex !== this.index) {
            this.responselistdata.forEach((value) => {
                if (value.record && value.record.showMR) {
                    value.record.showMR = false;
                    value.record.showMRClass = 'version-field';
                }
            })
            this.prevIndex = this.index;
        }
        this.responselistdata[this.index].record.showMR = !this.responselistdata[this.index].record.showMR;
        if(this.responselistdata[this.index].record.showMRClass !== 'version-field su__active-Filter-color') {
            this.responselistdata[this.index].record.showMRClass = 'version-field su__active-Filter-color';
        } else {
            this.responselistdata[this.index].record.showMRClass = 'version-field';
        }
    }

    mergeResultOutsideClick() {
        this.responselistdata.forEach((value) => {
            if (value.record && value.record.showMR) {
                value.record.showMR = false;
                value.record.showMRClass = 'version-field';
            }
        })
    }

    attachToCaseCmt(e) {
        var attached = parseInt(e.currentTarget.dataset.attached);
        var knowledgeId = e.currentTarget.dataset.knowledgeid;
        var sendData = {
            Id: e.currentTarget.dataset.Id,
            _id: knowledgeId,
            objName: e.currentTarget.dataset.objname,
            sourceName: e.currentTarget.dataset.sourcename,
            url: e.currentTarget.dataset.url,
            title: e.currentTarget.dataset.title,
            attached: attached === 0 ? true : false,
            index: e.currentTarget.dataset.index,
            childindex :e.currentTarget.dataset.childindex
        };
        knowledgeId = knowledgeId.slice(0, 18);

        assignArticleToCase({ contextIdentifier: attached === 0 ? 'attach' : 'deattach', caseIdVal: this.recordId, knowlegeId: knowledgeId })
            .then((data, error) => {
                if (data) {
                    this.error = undefined;
                    if (attached === 0) {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Attach To Case',
                                message: 'Attached To Case Successfully',
                                variant: 'success',
                                mode: 'dismissable'
                            }),
                        );
                    } else {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Detach To Case',
                                message: 'Detached To Case Successfully',
                                variant: 'success',
                                mode: 'dismissable'
                            }),
                        );
                    }
                } else if (error) {
                    this.error = error;
                    console.log('Error:' + JSON.stringify(error));
                    this.dispatchEvent(
                        new ShowToastEvent({
                            message: 'Something went wrong:' + error,
                            variant: 'error'
                        }));
                }
            });
        fireEvent(null, "attachToCaseEvent" + this.eventCode, sendData);
    }

    handleCaseComments(event) {
        var id = event.currentTarget.dataset.knowledgeid;
        var shouldDettach = event.currentTarget.dataset.showdettached;
        if ((shouldDettach === 'false' || shouldDettach === '0') && parseInt(event.currentTarget.dataset.merge,10) && parseInt(event.currentTarget.dataset.shouldattach,10))
            this.attachToCaseCmt(event);
        var sendData = {
            id: id,
            url: event.currentTarget.dataset.url,
            title: event.currentTarget.dataset.title,
            objName: event.currentTarget.dataset.objname,
            sourceName: event.currentTarget.dataset.sourcename,
        };
        fireEvent(null, "sendLinkEvent" + this.eventCode, sendData);
        this[NavigationMixin.Navigate]({
            type: "standard__component",
            attributes: {
                componentName: "c__SUNavigateToCaseComment"
            },
            state: {
                c__caseId: this.recordId,
                c__caseComment: event.currentTarget.dataset.url,
                c__tabId: this.activeTabId
            }
        });
    }

    copyLink(event) {
        var ptitle = event.currentTarget.dataset.sub;
        var plink = event.currentTarget.dataset.url;
        var idd = event.currentTarget.dataset.recordid;
        var copyId = plink;

        let tag = document.createElement('textarea');
        tag.setAttribute('id', 'input_test_id');
        tag.value = copyId;
        tag.href = plink;
        document.body.appendChild(tag);
        tag.select();
        document.execCommand('copy');
        tag.remove();

        var linkId = this.template.querySelector('[data-id="toastId"]');
        this.template.querySelector('[data-id="toastId"]').classList.remove('showFormBlock');
        setTimeout(() => {
            linkId.classList.add('showFormBlock');
        }, 1000);
        var sendData = {
            "id": idd,
            "plink": plink,
            "ptitle": ptitle,
            objName: event.currentTarget.dataset.type,
            sourceName: event.currentTarget.dataset.index
        };
        fireEvent(null, "copyLinkEvent" + this.eventCode, sendData);
    }

    handleCaseCommentsEmail(event) {
        var shouldDettach = event.currentTarget.dataset.showdettached;
        if ((shouldDettach === 'false' || shouldDettach === '0') && parseInt(event.currentTarget.dataset.merge,10) && parseInt(event.currentTarget.dataset.shouldattach,10)){
            this.attachToCaseCmt(event);

        }
        this.emailHref = event.currentTarget.dataset.url;
        this.ptitle = event.currentTarget.dataset.title;
        this.objName = event.currentTarget.dataset.objname;
        this.idd = event.currentTarget.dataset.id;
        this.showSendAsEmailBlock = true;
        this.sourcename = event.currentTarget.dataset.sourcename;
    }
 
    removeStickyFilter(event) {
        let objToSend = {
            contentname: event.target.getAttribute("data-Contentname"),
            label: event.target.getAttribute("data-label"),
            level: event.target.getAttribute("data-level"),
            type: event.target.getAttribute("data-type"),
            immediateParent: event.target.getAttribute("data-immediateParent"),
            path: event.target.getAttribute("data-path") ? JSON.parse(event.target.getAttribute("data-path")) : [],
        }

        fireEvent(this.pageRef, 'removeStickyFacetEvent' + this.eventCode, objToSend);
    }
    removeWildcardSearch(){
        fireEvent(null, 'removeWildcardSearch' + this.eventCode);
    }
    getAllStickyFacets() {
        fireEvent(null, 'viewAllStickyButton' + this.eventCode, { show: this.viewAllStickyButton });
        let message = "header";
        fireEvent(null, 'headerSUData' + this.eventCode, message);
    }
    runScriptMethod(e) {
        fireEvent(null, 'trackAnalytics' + this.eventCode, {
            type: 'conversion', objToSend: {
            index: e.currentTarget.dataset.index,
            type: e.currentTarget.dataset.type,
            id: e.currentTarget.dataset.recordid,
            rank: parseInt(e.currentTarget.dataset.rank,10) + 1,
            convUrl: e.currentTarget.dataset.url,
            convSub: e.currentTarget.dataset.sub || e.currentTarget.dataset.url,
            autoTuned: e.currentTarget.dataset.autotuned ? e.currentTarget.dataset.autotuned : false,
            ...(e.currentTarget.dataset.track && { sc_analytics_fields: e.currentTarget.dataset.track })

            }
        });
        var href = e.currentTarget.dataset.url;
        var id = e.currentTarget.dataset.recordid.split('__')[0];
        var object = e.currentTarget.dataset.type;
        var allowLinkOpenNewTab = e.currentTarget.dataset.allowlinkopennewtab;
        if (this.urlopensinnewtab) return null;
        else if (object === 'case' || object.toLowerCase().slice(-5) === '__kav') {
            e.preventDefault();
            this.invokeWorkspaceAPI('isConsoleNavigation').then(isConsole => {
                if (isConsole) {
                    this.invokeWorkspaceAPI('getFocusedTabInfo').then(focusedTab => {
                        this.invokeWorkspaceAPI('openSubtab', {
                            parentTabId: focusedTab.isSubtab ? focusedTab.parentTabId : focusedTab.tabId,
                            recordId: id,
                            focus: true
                        }).then(() => { })
                        .catch(() => {
                            this.invokeWorkspaceAPI('openTab', {
                                recordId: id,
                                focus: true
                            }).then(() => { });
                        });
                    });
                }
            });
        } else if(!allowLinkOpenNewTab) {
            window.open(href, "_blank"); // to give href or result as it is here
        }
        return null;
    }
    collapseSummary(event){
        let collapse = event.target.dataset.collapse;
        let index = event.target.dataset.index;

        this.responselistdata[index].showLess = parseInt(collapse,10) ? false : true;
        if( this.responselistdata[index].showLess){
            this.responselistdata[index].record.showMore = false;
        }
        this.responselistdata[index].record.showMore = parseInt(collapse,10) ? true : false;
        if( this.responselistdata[index].record.showMore){
            this.responselistdata[index].showLess = false;
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
                        } 
                            return resolve(response);
                    }
                }
            });

            window.dispatchEvent(apiEvent);
        });
    }

    handleMouseLeaveMetaData(event) {
        if(this.template.querySelector(`[data-id='${event.target.dataset.id}']`)) {
            this.template.querySelector(`[data-id='${event.target.dataset.id}']`).classList.remove('su__metaData-block');
        }
    }

    handleMouseEnterMetaData(event) {
        if(this.template.querySelector(`[data-id='${event.target.dataset.id}']`)) {
            this.template.querySelector(`[data-id='${event.target.dataset.id}']`).classList.add('su__metaData-block');
        }
    }
}