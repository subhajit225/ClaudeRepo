import { LightningElement, api} from 'lwc';
import { registerListener, unregisterListener, fireEvent } from 'c/supubsub';

export default class SU_Bookmark extends LightningElement {
    get viewSavePopupDIVCSS() {
        return this.viewSavePopup ? 'su__anim-fadeindown su__bookmark-popup su__position-fixed su__shadow-lg su__bg-white su__radius-1 su__mx-auto su__zindex-2 su__d-block' : 'visibilityHidden su__position-absolute';
    }
    save_bookmark = 'Save Bookmark';
    showmodal;
    @api eventCode;
    @api bookmarkSearches = [];

    showBookMark = true;
    isModalOpen = true;
    noBookmarkSaved = true;
    renderBookmarksButtons = true;
    disableButton = true;
    // bookmarksButtonsSaveText = 'Save';
    dynamicClass = 'greyClass';
    finalLang = 'en';
    @api translationObject;
    isBookmarkDuplicate = false;
    @api uid; 
    get getBookmarkDivClass(){
        return this.bookmarkSearches.length >= 20 || this.isBookmarkDuplicate
            ? "su__bookmark-popup su__position-absolute su__shadow-lg su__bg-white su__radius-1 su__mx-auto su__zindex-2 su__height-expand"
            : "su__bookmark-popup su__position-absolute su__shadow-lg su__bg-white su__radius-1 su__mx-auto su__zindex-2"
    }
    get bookmarkSearchesLength() {
        return this.bookmarkSearches.length < 20 ? true : false;
    }
    
    connectedCallback() {
        registerListener('starclickedbookmark'+this.eventCode, this.openBookMark, this);
    }

    disconnectedCallback() {
        unregisterListener('starclickedbookmark' + this.eventCode, this.openBookMark, this);
    }
    
    
    closeIcon() {
        this.renderBookmarksButtons = true; 
        this.isBookmarkDuplicate = false;
        fireEvent(null, 'closeIcon'+this.eventCode, false);
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
        
        if ((!temp && !temp.length) || this.bookmarkSearches.length === 20) {
            this.renderBookmarksButtons = true;
        } else {
            this.renderBookmarksButtons = false;
        }
        this.dynamicClass = 'saveButton';
    }
    saveToLocal() {
        var sr;
        if (this.template.querySelector('.searchtext')) {
            sr = this.template.querySelector('.searchtext').value.trim();
        }
        let a ;
        try {
            a = JSON.parse(localStorage.getItem('bookmark_searches_' + this.uid) || '[]');
        } catch (error) {
            console.error("An error occurred while parsing the JSON from local storage:", error);
        }
        this.isBookmarkDuplicate = false;
        if (a.length && a.some(ele => ele.title === sr)) {
            this.isBookmarkDuplicate = true;
        }
    
        if(this.isBookmarkDuplicate){
            this.getBookmarkDivClass;
        }
       else{
        this.renderBookmarksButtons = true;
        fireEvent(null, 'closeIcon'+this.eventCode, false);
        fireEvent(null, 'savetolocal'+this.eventCode, sr);
       }
    }
}