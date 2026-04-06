import { LightningElement, api, track } from 'lwc';
import { registerListener, unregisterListener, fireEvent } from 'c/authsupubsub_b6b3_13';

export default class SU_AuthPagination extends LightningElement {
    @api pagesizeadvfiltr = 10;
    showRecommendation = false;
    showAdvanceSearch = false;
    @api showPageSize = false;
    @api showPageFIlter = false;
    @api totalresults;
    @api totalpages;
    @api resultsectioncontainer;
    flag = true;
    disableNext = false;
    storeTotalPage = 0;
    showPageClass
    @api finallang;
    @api counter;
    @api endpointpagination;
    @api pagenum;
    @api pagesize;
    showResultPerPage = true;
    @api paginationlist;
    @api responselistdata;
    @api mergedresults;
    @api latesturlval;
    @track paginationClass = "su__pagination-row footerClass"
    @api translationObject;
    get disablePrevious() {
        return ((this.pagenum) == 1) ? true : false;
    }
    get nextPageNo() {
        return this.finallang.Next ? this.finallang.Next : 'Next';
    }
    get pageGreaterThanFour() {
        if ((this.pagenum) <= 4) {
            return false;
        }
        else {
            return true;
        }
    }
    get pageGreaterThanEqualToOne() {
        if (
            (this.totalpages - 1) == this.counter ||
            (this.totalpages - 2) == this.counter ||
            (this.totalpages - 3) == this.counter ||
            (this.pagenum == this.storeTotalPage) ||
            (this.disablePrevious == true) ||
            (this.pagenum == this.storeTotalPage - 1) ||
            (this.pagenum == this.storeTotalPage - 2) ||
            (this.pagenum == this.storeTotalPage - 3) ||
            (this.totalpages - 1 == this.pagenum) || (this.totalpages - 2 == this.pagenum) || (this.totalpages - 3 == this.pagenum) ||
            (this.storeTotalPage - 1 == this.pagenum) || (this.storeTotalPage - 2 == this.pagenum) || (this.storeTotalPage - 3 == this.pagenum)
        ) {
            return false;
        }
        else {
            return true;
        }
    }

    connectedCallback() {
        registerListener('sendpaginationdata', this.receivedPaginationData, this);
    }

    disconnectedCallback() {
        unregisterListener('sendpaginationdata', this.receivedPaginationData, this);
    }

    receivedPaginationData(data) {
        this.pagesizeadvfiltr = data.resultsPerPage;
    }

    closeResultPerPage() {
        this.showAdvanceSearch = !this.showAdvanceSearch;
        if (this.template.querySelector('[data-id="formBlock"]')) {
            this.template.querySelector('[data-id="formBlock"]').classList.add('mainFormDiv');
        }
    }
    toggleResultsPerPage() {
        this.showAdvanceSearch = !this.showAdvanceSearch;
        if (this.template.querySelector('[data-id="formBlock"]')) {
            if (this.showAdvanceSearch) {
                this.template.querySelector('[data-id="formBlock"]').classList.remove('mainFormDiv');
            }
            else {
                this.template.querySelector('[data-id="formBlock"]').classList.add('mainFormDiv');
            }
        }

    }


    onSelectChange(event) {
        var selectedChange = event.currentTarget.dataset.accesskey;
        this.pagesizeadvfiltr = selectedChange;
        if (this.resultsectioncontainer) {
            this.resultsectioncontainer.scrollTop = 0;
        }
        this.toggleResultsPerPage();
        this.pagesize = this.pagesizeadvfiltr;
        this.pagenum = 1;
        var sendData = { "pagesizeadvfiltr": this.pagesizeadvfiltr, "pagesize": this.pagesize, "pageNum": this.pagenum };
        fireEvent(null, "selectchange", sendData);
        if (this.totalpages) {
            this.storeTotalPage = this.totalpages;
        }
        this.flag = true;
    }

    setPagination(pagesize, pagenum) {
        var pageNumber = parseInt(pagenum);
        var total = this.totalresults;
        this.totalpages = Math.ceil(total / pagesize);
        var pageList = [];
        if (this.totalresults == 0) {
            pageList.push(pageNumber - (pageNumber - this.counter), (pageNumber + 1) - (pageNumber - this.counter), (pageNumber + 2) - (pageNumber - this.counter), (pageNumber + 3) - (pageNumber - this.counter))
            this.paginationlist = pageList;
        }
        if (this.totalpages > 0) {
            if (this.totalpages <= 4) {
                var counter = 1;
                for (; counter <= this.totalpages; counter++) {
                    pageList.push(counter);
                }
                this.paginationlist = pageList;
            }
            else {
                if (this.counter == pageNumber) {
                    for (var i = pageNumber; i <= this.totalpages; i++) {
                        if (i == pageNumber + 4) {
                            this.endpointpagination = i - 1;
                            break;
                        }
                        if ((i) == this.totalpages) {
                            pageList.push(i);
                            this.endpointpagination = this.totalpages;
                            break;
                        }
                        pageList.push(i);
                    }
                    this.paginationlist = pageList;
                } else {
                    if (pageNumber - (pageNumber - this.counter) == this.endpointpagination) {
                        pageList.push(pageNumber - (pageNumber - this.counter));
                    }
                    else if ((pageNumber + 1) - (pageNumber - this.counter) == this.endpointpagination) {
                        pageList.push(pageNumber - (pageNumber - this.counter), (pageNumber + 1) - (pageNumber - this.counter))

                    }
                    else if ((pageNumber + 2) - (pageNumber - this.counter) == this.endpointpagination) {
                        pageList.push(pageNumber - (pageNumber - this.counter), (pageNumber + 1) - (pageNumber - this.counter), (pageNumber + 2) - (pageNumber - this.counter))
                    }
                    else if ((pageNumber + 3) - (pageNumber - this.counter) == this.endpointpagination) {
                        pageList.push(pageNumber - (pageNumber - this.counter), (pageNumber + 1) - (pageNumber - this.counter), (pageNumber + 2) - (pageNumber - this.counter), (pageNumber + 3) - (pageNumber - this.counter))
                    }
                    this.paginationlist = pageList;
                }
                if (pageNumber == this.counter + 4) {
                    this.counter = pageNumber;
                }
            }
        }

        this.disableEnableActions(pageNumber);
    }
    disableEnableActions(pageNumber) {
        let buttons = this.template.querySelectorAll('[data-id="paginationButton"]');
        buttons.forEach(bun => {
            if (bun.value == pageNumber) {
                bun.classList.add('paging_new');

            } else {
                bun.classList.add('newPageActiveBtn');
            }
        });

    }
    renderedCallback() {
        if (this.totalpages) {
            this.storeTotalPage = this.totalpages;
        }
        if (this.pagenum == this.totalpages || this.pagenum == this.storeTotalPage) {
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
                if (bun.value == this.pagenum) {
                    bun.classList.add('paging_new');
                } else {
                    bun.classList.remove('paging_new');
                    bun.classList.add('newPageActiveBtn');
                }
            });
        }

    }

    pageChanged(event) {
        if (event.currentTarget.dataset.id == 'previous-page') {
            if (this.counter == parseInt(this.pagenum)) {
                this.counter = this.counter - 4;
                if (this.counter === 0) {
                    this.counter = this.counter + 1;
                }
                if (this.counter < 0) {
                    this.counter = 1;
                }
                this.endpointpagination = this.counter + 3;
            }
            this.pagenum = parseInt(this.pagenum) - 1;
            this.setPagination(this.pagesize, this.pagenum)
        } else if (event.currentTarget.dataset.id == 'previous-Dots') {
            if (this.pagenum != 5) {
                this.pagenum = parseInt(this.pagenum) - (parseInt(this.pagenum) - this.counter) - 1;
            } else {
                this.pagenum = 4;
            }
            this.counter = this.counter - 4;
            if (this.counter < 1) {
                this.counter = 2;
            }
            this.endpointpagination = this.pagenum;
            this.setPagination(this.pagesize, this.pagenum)
            this.disableEnableActions(this.pagenum);
        } else if (event.currentTarget.dataset.id == 'next-Dots') {
            this.pagenum = parseInt(this.pagenum) - (parseInt(this.pagenum) - this.counter) + 4;
            if (this.pagenum == (parseInt(this.endpointpagination) + 1)) {
                this.counter = this.pagenum;
            }
            this.setPagination(this.pagesize, this.pagenum);
        } else if (event.currentTarget.dataset.id == 'next-page') {
            if (this.totalpages) {
                this.storeTotalPage = this.totalpages;
            }
            this.pagenum = parseInt(this.pagenum) + 1;
            if (this.pagenum == (parseInt(this.endpointpagination) + 1)) {
                this.counter = this.pagenum;
            }
            this.setPagination(this.pagesize, this.pagenum)
        } else {
            // clicked pagination
            if (this.totalpages) {
                this.storeTotalPage = this.totalpages;
            }
            this.pagenum = parseInt(event.target.value);
            if (this.pagenum == this.totalpages) {
                this.disableNext = true;
            }
            if (this.pagenum < this.storeTotalPage) {
                this.disableNext = false;
            }
            this.disableEnableActions(this.pagenum);
        }
        var sendData = { "pagenum": this.pagenum, "counter": this.counter, "endpointpagination": this.endpointpagination };
        fireEvent(null, "paginationClicked", sendData);
    }
}