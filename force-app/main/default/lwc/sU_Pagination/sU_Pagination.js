import { LightningElement, api, track } from 'lwc';
import { registerListener, unregisterListener, fireEvent } from 'c/supubsub';

export default class SU_Pagination extends LightningElement {
    showAdvanceSearch = false;

    @api resultsectioncontainer;
    disableNext = false;
    storeTotalPage = 0; 
    @api finallang;
    showResultPerPage = true;
    @api responselistdata;
    @api mergedresults;
    @track paginationClass="su__pagination-row footerClass"
    @api eventCode;
    @api translationObject;
    bigscreen;
    _pagesize = 10;
    _pagenum;
    _totalpages;
    _paginationlist;
    _endpointpagination;
    _counter;
    _totalresults;
    @api
    get pagenum() {
        return this._pagenum;
    }

    set pagenum(value) {
        this._pagenum = value;
    }
    @api
    get pagesize() {
        return this._pagesize;
    }

    set pagesize(value) {
        this._pagesize = value;
    }
    @api
    get totalpages() {
        return this._totalpages;
    }

    set totalpages(value) {
        this._totalpages = value;
    }
    @api
    get paginationlist() {
        return this._paginationlist;
    }

    set paginationlist(value) {
        this._paginationlist = value;
    }
    @api
    get endpointpagination() {
        return this._endpointpagination;
    }

    set endpointpagination(value) {
        this._endpointpagination = value;
    }
    @api
    get counter() {
        return this._counter;
    }

    set counter(value) {
        this._counter = value;
    }
    @api
    get totalresults() {
        return this._totalresults;
    }

    set totalresults(value) {
        this._totalresults = value;
    }
    @api 
    set bigScreen(val){
        this.bigscreen = val;
        
        if(this.bigscreen === true){
            this.paginationClass = "su__pagination-row footerClass su__d-flex su__justify-content-end "
        }else {
            this.paginationClass = "su__pagination-row footerClass"
        }

    }
    get bigScreen(){return this.bigscreen}

    get disablePrevious() {
        return ((this.pagenum) === 1) ? true : false;
    }
    get nextPageNo() {
        return this.finallang.Next ? this.finallang.Next : 'Next';
    }
    get pageGreaterThanFour() {
        if ((this.pagenum) <= 4) {
            return false;
        }
            return true;
    }
    get pageGreaterThanEqualToOne() {
        if (
            (this.totalpages - 1) === this.counter ||
            (this.totalpages - 2) === this.counter ||
            (this.totalpages - 3) === this.counter ||
            (this.pagenum === this.storeTotalPage) ||
            (this.disablePrevious === true) ||
            (this.pagenum === this.storeTotalPage - 1) ||
            (this.pagenum === this.storeTotalPage - 2) ||
            (this.pagenum === this.storeTotalPage - 3) ||
            (this.totalpages - 1 === this.pagenum) || (this.totalpages - 2 === this.pagenum) || (this.totalpages - 3 === this.pagenum) ||
            (this.storeTotalPage - 1 === this.pagenum) || (this.storeTotalPage - 2 === this.pagenum) || (this.storeTotalPage - 3 === this.pagenum)
        ) {
            return false;
        }
            return true;

    }

    connectedCallback() {
        registerListener('sendpaginationdata' + this.eventCode, this.receivedPaginationData, this); 
    }
    disconnectedCallback(){
        unregisterListener('sendpaginationdata' + this.eventCode, this.receivedPaginationData, this);
    }
    receivedPaginationData(data) {
        this._pagesize = data.resultsPerPage;
    }
    
    closeResultPerPage() {
        this.showAdvanceSearch = !this.showAdvanceSearch;
        if(this.template.querySelector('[data-id="formBlock"]')) {
            this.template.querySelector('[data-id="formBlock"]').classList.add('mainFormDiv');
        }
    }
    toggleResultsPerPage() {
        this.showAdvanceSearch = !this.showAdvanceSearch;
        if(this.template.querySelector('[data-id="formBlock"]')) {
            if (this.showAdvanceSearch) {
                this.template.querySelector('[data-id="formBlock"]').classList.remove('mainFormDiv');
            }
            else {
                this.template.querySelector('[data-id="formBlock"]').classList.add('mainFormDiv');
            }
        }
        
    }
    onSelectChange(event) {
        if (this.resultsectioncontainer) {
            this.resultsectioncontainer.scrollTop = 0;
        }
        var selectedChange = event.currentTarget.dataset.accesskey;
        this._pagesize = selectedChange;
        this.toggleResultsPerPage();
        this._pagenum = 1;
        var sendData = { "pagesize": this.pagesize, "pageNum": this.pagenum };
        fireEvent(null, "selectchange"+this.eventCode, sendData);
        
        if (this.totalpages) {
            this.storeTotalPage = this.totalpages;
        }
    }
    
    setPagination(pagesize, pagenum) {
        var pageNumber = parseInt(pagenum,10);
        var total = this.totalresults;
        this._totalpages = Math.ceil(total / pagesize);
        var pageList = [];
        if (this.totalresults === 0) {
            pageList.push(pageNumber - (pageNumber - this.counter), (pageNumber + 1) - (pageNumber - this.counter), (pageNumber + 2) - (pageNumber - this.counter), (pageNumber + 3) - (pageNumber - this.counter))
            this._paginationlist = pageList;
        }
        if (this.totalpages > 0) {
            if (this.totalpages <= 4) {
                var counter = 1;
                for (; counter <= this.totalpages; counter++) {
                    pageList.push(counter);
                }
                this._paginationlist = pageList;
            }
            else {
                if (this.counter === pageNumber) {
                    for (var i = pageNumber; i <= this.totalpages; i++) {
                        if (i === pageNumber + 4) {
                            this._endpointpagination = i - 1;
                            break;
                        }
                        if ((i) === this.totalpages) {
                            pageList.push(i);
                            this._endpointpagination = this.totalpages;
                            break;
                        }
                        pageList.push(i);
                    }
                    this._paginationlist = pageList;
                } else {
                    if (pageNumber - (pageNumber - this.counter) === this.endpointpagination) {
                        pageList.push(pageNumber - (pageNumber - this.counter));
                    }
                    else if ((pageNumber + 1) - (pageNumber - this.counter) === this.endpointpagination) {
                        pageList.push(pageNumber - (pageNumber - this.counter), (pageNumber + 1) - (pageNumber - this.counter))

                    }
                    else if ((pageNumber + 2) - (pageNumber - this.counter) === this.endpointpagination) {
                        pageList.push(pageNumber - (pageNumber - this.counter), (pageNumber + 1) - (pageNumber - this.counter), (pageNumber + 2) - (pageNumber - this.counter))
                    }
                    else if ((pageNumber + 3) - (pageNumber - this.counter) === this.endpointpagination) {
                        pageList.push(pageNumber - (pageNumber - this.counter), (pageNumber + 1) - (pageNumber - this.counter), (pageNumber + 2) - (pageNumber - this.counter), (pageNumber + 3) - (pageNumber - this.counter))
                    }
                    this._paginationlist = pageList;
                }
                if (pageNumber === this.counter + 4) {
                    this._counter = pageNumber;
            }
        }
        }

        this.disableEnableActions(pageNumber);
    }
    disableEnableActions(pageNumber) {
        let buttons = this.template.querySelectorAll('[data-id="paginationButton"]');
        buttons.forEach(bun => {
            if (parseInt(bun.value,10) === pageNumber) {
                bun.classList.add('paging_new') ;

            } else {
                bun.classList.add('newPageActiveBtn');
            }
        });

    }
    renderedCallback() {
        if (this.totalpages) {
            this.storeTotalPage = this.totalpages;
        }
        if (this.pagenum === this.totalpages || this.pagenum === this.storeTotalPage) {
            this.disableNext = true;
        }
        else {
            this.disableNext = false;
        }
        if (this.pagenum < this.storeTotalPage) {
            this.disableNext = false;
        }
        let buttons = this.template.querySelectorAll('[data-id="paginationButton"]');
        if (buttons) {
            buttons.forEach(bun => {
                if (parseInt(bun.value,10) === this.pagenum) {
                    bun.classList.add('paging_new');
                } else {
                    bun.classList.remove('paging_new');
                    bun.classList.add('newPageActiveBtn');
                }
            });
        }
    }

    pageChanged(event) {
        if(this.resultsectioncontainer){
        this.resultsectioncontainer.scrollTop = 0;
        }
        if(event.currentTarget.dataset.id === 'previous-page') {

            if (this.counter === parseInt(this.pagenum,10)) {
                this._counter = this.counter - 4;
                if (this.counter === 0) {
                    this._counter = this.counter + 1;
                }
                if (this.counter < 0) {
                    this._counter = 1;
                }
                this._endpointpagination = this.counter + 3;
            }
            this._pagenum = parseInt(this.pagenum,10) - 1;
            this.setPagination(this.pagesize, this.pagenum)
        } else if (event.currentTarget.dataset.id === 'previous-Dots') {
            if (this.pagenum !== 5) {
                this._pagenum = parseInt(this.pagenum,10) - (parseInt(this.pagenum,10) - this.counter) - 1;
            } else {
                this._pagenum = 4;
            }
            this._counter = this.counter - 4;
            if (this.counter < 1) {
                this._counter = 2;
            }
            this._endpointpagination = this.pagenum;
            this.setPagination(this.pagesize, this.pagenum)
            this.disableEnableActions(this.pagenum);
        } else if (event.currentTarget.dataset.id === 'next-Dots') {
            this._pagenum = parseInt(this.pagenum,10) - (parseInt(this.pagenum,10) - this.counter) + 4;
            if (this.pagenum === (parseInt(this.endpointpagination) + 1)) {
                this._counter = this.pagenum;
            }
            this.setPagination(this.pagesize, this.pagenum);
        } else if (event.currentTarget.dataset.id === 'next-page') {
            if (this.totalpages) {
                this.storeTotalPage = this.totalpages;
            }
            this._pagenum = parseInt(this.pagenum,10) + 1;
            if (this.pagenum === (parseInt(this.endpointpagination) + 1)) {
                this._counter = this.pagenum;
            }
            this.setPagination(this.pagesize, this.pagenum)
        } else {
            // clicked pagination
            if (this.totalpages) {
                this.storeTotalPage = this.totalpages;
            }
            this._pagenum = parseInt(event.target.value,10);
            if (this.pagenum === this.totalpages) {
                this.disableNext = true;
            }
            if (this.pagenum < this.storeTotalPage) {
                this.disableNext = false;
            }
            this.disableEnableActions(this.pagenum);
        }
        var sendData = { "pagenum": this.pagenum, "counter": this.counter, "endpointpagination": this.endpointpagination };
        fireEvent(null, "paginationClicked"+this.eventCode, sendData);
    }
}