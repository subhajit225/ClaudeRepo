import { LightningElement, track, api } from 'lwc';
export default class SU_ArticlePreviewChild extends LightningElement {
    @api kid;
    @api attachment;
    @track toggleShow = false;
    @api object;
    @api fileattachments;
    accordianSection = 'A';
    
    handleToggleSection() {
        if(this.accordianSection.length === 0) {
            this.accordianSection ='';
        }
        else {
            this.accordianSection ='A';
        }
    }
}