import { LightningElement, api } from 'lwc';
import { registerListener, unregisterListener, fireEvent } from 'c/supubsub';

export default class SU_SavedBookmark extends LightningElement {
    renderBookmarksButtons = true;
    isSaveBookMark = false;
    isBookmarkExist = true;
    count = 0;
    @api eventCode;
    @api translationObject;
    connectedCallback() {
        registerListener('savebookmarkclicked'+this.eventCode, this.savedBookMarkClicked, this);
        registerListener('bmarkslist'+this.eventCode, this.bookmarkReceived, this);
        registerListener('transssferlist'+this.eventCode, this.bookmarkReceived, this);
        registerListener('closesavedbmark'+this.eventCode, this.closeseIcon2, this);
    }
    disconnectedCallback(){
        unregisterListener('savebookmarkclicked'+this.eventCode, this.savedBookMarkClicked, this);
        unregisterListener('bmarkslist'+this.eventCode, this.bookmarkReceived, this);
        unregisterListener('transssferlist'+this.eventCode, this.bookmarkReceived, this);
        unregisterListener('closesavedbmark'+this.eventCode, this.closeseIcon2, this);
    }
    
    closeseIcon2() {
        this.isSaveBookMark = false;
    }
    bookmarkReceived(data) {
        if(data.length === 0) {
            this.isBookmarkExist = false;
        } else {
            this.isBookmarkExist = true;
            this.bookmarkSearches = data;
        }
    }

    savedBookMarkClicked() {
        this.count = 0;
        this.isSaveBookMark = true;
        this.renderBookmarksButtons = true;
    }
    closeIcon() {
        this.isSaveBookMark = false;
        this.count = 0;
        this.renderBookmarksButtons = true;
        fireEvent(null, 'closeIconbookmark'+this.eventCode, true);
    }
    closeAndDeleteBmark() {
        let i;
        let deleteList = [];
        let checkboxes = this.template.querySelectorAll('[data-id="checkbox"]')
        for (i = 0; i < checkboxes.length; i++) {
            if (checkboxes[i].checked) {
                let b = {};
                b.href = checkboxes[i].name;
                b.title = checkboxes[i].value;
                deleteList.push(b);
                checkboxes[i].checked = false;
            }
        }
        fireEvent(null, 'removefromlocalstorage'+this.eventCode, deleteList);
        this.closeIcon();
    }
    bookmarkActive(event) {
        if (event.target.checked) {
            this.count++
        } else {
            this.count--
        }
        if (this.count === 0) {
            this.renderBookmarksButtons = true;
        } else {
            this.renderBookmarksButtons = false;
        }
    }
    bookmarkClicked1(e) {
        fireEvent(null, 'savedbookmarkclicked'+this.eventCode, e);
    }
}