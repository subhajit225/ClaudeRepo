import { LightningElement, api } from 'lwc';
import { registerListener, unregisterListener, fireEvent } from 'c/authsupubsub_b6b3_13';

export default class SU_AuthBookmark extends LightningElement {
    @api showmodal;
    @api bookmarkSearches = [];

    isModalOpen = true;
    noBookmarkSaved = true;
    renderBookmarksButtons = true;
    bookmarkSearches = true;
    disableButton = true;
    @api translationObject;
    isBookmarkDuplicate = false;
    @api uid;

    get getBookmarkDivClass() {
        return this.bookmarkSearches.length >= 20 || this.isBookmarkDuplicate
            ? "su__bookmark-popup su__position-absolute su__shadow-lg su__bg-white su__radius-1 su__mx-auto su__zindex-2 su__height-expand"
            : "su__bookmark-popup su__position-absolute su__shadow-lg su__bg-white su__radius-1 su__mx-auto su__zindex-2"
    }
    get bookmarkSearchesLength() {
        return this.bookmarkSearches.length < 20 ? true : false;
    }

    connectedCallback() {
        registerListener('starclickedbookmark', this.openBookMark, this);
    }

    disconnectedCallback() {
        unregisterListener('starclickedbookmark', this.openBookMark, this);
    }
    
    closeIcon() {
        this.renderBookmarksButtons = true;
        this.isBookmarkDuplicate = false;
        fireEvent(null, 'closeIcon', false);
    }
    saveBookmark() {
        this.showmodal = false;
    }
    openBookMark(data) {
        this.showmodal = data;
    }
    viewSavePopup_toggle() {
        this.bookmarkName = "";

        this.disableButton = true;

        this.viewSavePopup = false;
        this.isModalOpen = false;
        this.noBookmarkSaved = false;

        document.body.classList.remove('su__overflow-hidden');
    }
    bookMarkTyped() {
        var temp;
        if (this.template.querySelector('lightning-input[data-name="temp"]')) {
            temp = this.template.querySelector('lightning-input[data-name="temp"]').value.trim();
            temp = temp.replace(/ /g, "");
        }

        if ((!temp && !temp.length) || this.bookmarkSearches.length == 20) {
            this.renderBookmarksButtons = true;
        } else {
            this.renderBookmarksButtons = false;
        }
    }
    saveToLocal() {
        var sr;
        if (this.template.querySelector('.searchtext')) {
            sr = this.template.querySelector('.searchtext').value.trim();
        }
        let a = JSON.parse(localStorage.getItem('bookmark_searches_' + this.uid) || '[]');
        this.isBookmarkDuplicate = false;
        a.length && a.map((ele) => {
            if (ele.title === sr) {
                this.isBookmarkDuplicate = true;
            }
        });

        if (this.isBookmarkDuplicate) {
            this.getBookmarkDivClass;
        }
        else {
            this.renderBookmarksButtons = true;
            fireEvent(null, 'closeIcon', false);
            fireEvent(null, 'savetolocal', sr);
        }
    }
}