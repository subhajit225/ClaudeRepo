import { LightningElement, api } from 'lwc';
import { registerListener, unregisterListener, fireEvent } from 'c/supubsub';
export default class SU_BookmarkComponent extends LightningElement {
    showSaved = false;
    @api eventCode;
    saveBookmarkClicked() {
        fireEvent(null, 'savebookmarkclicked'+this.eventCode, true);
        this.showSaved = true;
        fireEvent(null, 'bookmarklistrequired'+this.eventCode, '');
    }
    connectedCallback() {
        registerListener('closeIconbookmark'+this.eventCode, this.closeSavedBookmark, this);
    }
    disconnectedCallback(){
        unregisterListener('closeIconbookmark'+this.eventCode, this.closeSavedBookmark, this);
    }
    
    closeSavedBookmark() {
        this.showSaved = false;
    }
}