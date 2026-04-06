import { LightningElement, api, track } from 'lwc';
export default class VfAccordion extends LightningElement {
    
    @api visualforcePageName;
    @api visualforcePageTitle;
    @api visualforcePageHeight;
    @api recordId;
    @track isCollapsed = false;
    visualforceUrl;

    get iconName(){
        return this.isCollapsed ? 'utility:chevronright' : 'utility:chevrondown' ;
    }
    get pageHeight(){
        return this.visualforcePageHeight ? this.visualforcePageHeight + 'px' : '220px'
    }
    connectedCallback() {
        this.visualforceUrl = `/apex/${this.visualforcePageName}?id=${this.recordId}`;
    }    
    toggleSectionHeader(){
        this.isCollapsed = !this.isCollapsed;
    }
}