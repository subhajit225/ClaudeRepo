import { LightningElement, api, track } from 'lwc';
import { registerListener, unregisterListener, fireEvent } from 'c/authsupubsub_b6b3_13';
export default class SU_AuthBookmarkComponent extends LightningElement {
    showSaved = false;
    @track isBookmarkExist = false;
    @api bookmarkList;
    @api translationObject;
    saveBookmarkClicked() {
        fireEvent(null, 'savebookmarkclicked', true);
        this.showSaved = true;
        fireEvent(null, 'bookmarklistrequired', '');
    }

    renderedCallback() {
        if (this.bookmarkList && this.bookmarkList.length > 0) {
            this.isBookmarkExist = true;
        } else {
            this.isBookmarkExist = false;
        }
    }

    connectedCallback() {
        registerListener('closeIconbookmark', this.closeSavedBookmark, this);
        registerListener('toggleSavedBookmark', this.toggleSavedBookmark, this);
        registerListener('sendBookmarkListOnSave', this.sendBookmarkListOnSave, this);
    }

    disconnectedCallback() {
        unregisterListener('closeIconbookmark', this.closeSavedBookmark, this);
        unregisterListener('toggleSavedBookmark', this.toggleSavedBookmark, this);
        unregisterListener('sendBookmarkListOnSave', this.sendBookmarkListOnSave, this);
    }
    
    toggleSavedBookmark() {
        this.saveBookmarkClicked();
    }

    get bookmarkListIconClass() {
        return this.isBookmarkExist ? '#1770d4' : '#919bb0'
    }

    sendBookmarkListOnSave(data) {
        if (data.length === 0) {
            this.isBookmarkExist = false;
        } else {
            this.isBookmarkExist = true;
        }
    }

    closeSavedBookmark() {
        this.showSaved = false;
    }
}