import { LightningElement, track, api } from 'lwc';
import { registerListener, unregisterListener, fireEvent } from 'c/authsupubsub_b6b3_13';

export default class SU_AuthLanguageSection extends LightningElement {
    defaultLang = 'en';
    langlist;
    @track langconfig = {};
    @api translationObject;
    @api
    set langConfig(value) {
        if (value) {
            this.langconfig = JSON.parse(JSON.stringify(value));
        }
    };
    get langConfig() {
        return this.langconfig;
    }
    renderedCallback() {
        this.langlist = this.langconfig?.selectedLanguages;
        this.defaultLang = this.langconfig?.defaultLanguage?.code || 'en';
        this.langlist.map(x => {
            if (x.code === this.defaultLang) {
                x.selected = true;
            } else {
                x.selected = false;
            }
            return x;
        });
    }
    connectedCallback() {
        registerListener('langListSend', this.langlistfromparent, this);
    }

    disconnectedCallback() {
        unregisterListener('langListSend', this.langlistfromparent, this);
    }

    langlistfromparent(data) {
        if (this.langlist === undefined) {
            this.langlist = data;
        }
    }
    handleMenuSelect(e) {
        this.langlist.map(x => {
            if (x.code === e.target.dataset.id) {
                x.selected = true;
            } else {
                x.selected = false;
            }
            return x;
        });
        this.defaultLang = e.target.dataset.id;
        this.langconfig.defaultLanguage.code = e.target.dataset.id;
        let objSend = {
            defaultLang: this.defaultLang,
            langlist :  this.langlist
        }
        fireEvent(null, "languageselected", objSend);


    }
    // langListCall() {
    //     fireEvent(null, "getlanglist", "");
    // }
}