import { LightningElement, api, track } from 'lwc';

export default class NewRepPagination extends LightningElement {
    @api totalrecords;
    //@track currentPage = 1;
    @api currentPage;
    @api pageSize;

    get totalPages() {
        return Math.ceil(this.totalrecords / this.pageSize);
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage === this.totalPages;
    }

    get pagesToShow() {
        const pages = [];
        const maxVisible = 5;
        const lastVisibleNumbers = Math.floor(maxVisible / 2);

        if (this.totalPages <= maxVisible + 2) {
            for (let i = 1; i <= this.totalPages; i++) {
                pages.push(this.pageEllipseCheck(i));
            }
        } else {
            if (this.currentPage <= lastVisibleNumbers + 1) {
                for (let i = 1; i <= maxVisible; i++) {
                    pages.push(this.pageEllipseCheck(i));
                }
                pages.push({ label: '...', isEllipsis: true });
                pages.push(this.pageEllipseCheck(this.totalPages));
            } else if (this.currentPage >= this.totalPages - lastVisibleNumbers) {
                pages.push(this.pageEllipseCheck(1));
                pages.push({ label: '...', isEllipsis: true });
                for (let i = this.totalPages - maxVisible + 1; i <= this.totalPages; i++) {
                    pages.push(this.pageEllipseCheck(i));
                }
            } else {
                pages.push(this.pageEllipseCheck(1));
                pages.push({ label: '...', isEllipsis: true });
                for (let i = this.currentPage - 1; i <= this.currentPage + 1; i++) {
                    pages.push(this.pageEllipseCheck(i));
                }
                pages.push({ label: '...', isEllipsis: true });
                pages.push(this.pageEllipseCheck(this.totalPages));
            }
        }

        return pages;
    }

    pageEllipseCheck(label) {   
        console.log('this.currentPage from ellipse is ', this.currentPage);
        console.log('current label is  ',label);  

        return {
            label,
            class: label === this.currentPage ? 'slds-button-group-item active-page' : 'slds-button-group-item',
            isEllipsis: false,
            variant: label === this.currentPage ? 'brand' : 'neutral'
        };
    }

    handlePageClick(event) {
        const page = parseInt(event.target.dataset.page, 10);
        if (page !== this.currentPage) {
            this.currentPage = page;
            this.dispatchPageChange();
        }
    }

    handlePrev() {
        if (this.currentPage > 1) {
            this.currentPage -= 1;
            this.dispatchPageChange();
        }
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage += 1;
            this.dispatchPageChange();
        }
    }

    handlePageSizeChange(event) {
        this.pageSize = parseInt(event.target.value, 10);
        this.currentPage = 1;
        this.dispatchPageChange();
    }

    dispatchPageChange() {
        const event = new CustomEvent('pagechange', {
            detail: {
                page: this.currentPage,
                pageSize: this.pageSize
            }
        });
        this.dispatchEvent(event);
    }
}