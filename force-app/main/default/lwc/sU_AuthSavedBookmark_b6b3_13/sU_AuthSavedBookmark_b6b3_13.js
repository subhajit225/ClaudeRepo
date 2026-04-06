import { LightningElement, api } from 'lwc';
import { registerListener, unregisterListener, fireEvent } from 'c/authsupubsub_b6b3_13';

export default class SU_AuthSavedBookmark extends LightningElement {
    renderBookmarksButtons = true;
    isSaveBookMark = false;
    isBookmarkExist = true;
    count = 0;
    @api translationObject;
   
    connectedCallback() {
        registerListener('savebookmarkclicked', this.savedBookMarkClicked, this);
        registerListener('bmarkslist', this.bookmarkReceived, this);
        registerListener('transssferlist', this.bookmarkReceived, this);
        registerListener('closesavedbmark', this.closeseIcon2, this);
    }

    disconnectedCallback() {
        unregisterListener('savebookmarkclicked', this.savedBookMarkClicked, this);
        unregisterListener('bmarkslist', this.bookmarkReceived, this);
        unregisterListener('transssferlist', this.bookmarkReceived, this);
        unregisterListener('closesavedbmark', this.closeseIcon2, this);
    }

    closeseIcon2(d) {
        this.isSaveBookMark = false;
    }
    bookmarkReceived(data) {
        if (data.length === 0) {
            this.isBookmarkExist = false;
        } else {
            this.isBookmarkExist = true;
            this.bookmarkSearches = data.reverse();
        }
    }

    savedBookMarkClicked(d) {
        this.count = 0;
        this.isSaveBookMark = true;
        this.renderBookmarksButtons = true;
    }
    closeIcon() {
        this.isSaveBookMark = false;
        this.count = 0;
        this.renderBookmarksButtons = true;
        fireEvent(null, 'closeIconbookmark', true);
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
        fireEvent(null, 'removefromlocalstorage', deleteList);
         this.closeBookmarkIcon();
    }
    closeBookmarkIcon() {
        this.count = 0;
        this.renderBookmarksButtons = true;
        fireEvent(null, 'closeIconbookmark', true);
    }
    bookmarkActive(event) {
        if (event.target.checked) {
            this.count++
        } else {
            this.count--
        }
        if (this.count == 0) {
            this.renderBookmarksButtons = true;
        } else {
            this.renderBookmarksButtons = false;
        }
    }
    bookmarkClicked1(e) {
        fireEvent(null, 'savedbookmarkclicked', e);
    }
}