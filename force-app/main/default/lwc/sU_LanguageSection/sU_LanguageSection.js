import { LightningElement, track, api } from 'lwc';
import { registerListener, unregisterListener, fireEvent } from 'c/supubsub';

export default class SU_LanguageSection extends LightningElement {
    defaultLang = 'en';
    langlist;
    @api eventCode;
    @track langconfig = {};
    @api translationObject;
    @api
    set langConfig(value) {
        try{
            if (value) {
                this.langconfig = JSON.parse(JSON.stringify(value));
            }
        } catch{
            (error)=>{
                console.error("An error occurred while parsing and stringifying the value:", error);
            }  
        }  
    }
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
        registerListener('langListSend'+this.eventCode, this.langlistfromparent, this);
    }
    disconnectedCallback(){
        unregisterListener('langListSend'+this.eventCode, this.langlistfromparent, this);
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
        fireEvent(null, "languageselected"+this.eventCode, objSend);


    }
}