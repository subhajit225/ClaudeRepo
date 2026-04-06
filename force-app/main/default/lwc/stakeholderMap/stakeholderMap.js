import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCategorizedContacts from '@salesforce/apex/StakeholderMapController.getCategorizedContacts';

export default class StakeholderMap extends LightningElement {
    @api recordId;
    toastMessage;

    // CXO
    @track cxoContacts = { CIO: [], CISO: [], CTO: [], Data: [] };
    @track cxoHasMoreAny = false;

    // Additional C-Suite
    @track cSuiteRow = [];
    @track cSuiteHasMore = false;
    allCSuiteContacts = [];

    // VP/Head
    @track vpHeadBuckets = [];
    @track vpHeadHasMore = false;
    allVpHeadContacts = [];

    // Product Personas
    @track productBuckets = [];

    // Modal
    @track showModal = false;
    @track modalTitle;
    @track modalContacts = [];

    connectedCallback(){
    }

    @wire(getCategorizedContacts, { accountId: '$recordId' })
    wiredContacts({ error, data }) {
        if (data) {
            if(data.Success){
                this.prepareCXO(data.Data['Key CXO Stakeholders']);
                this.prepareCSuite(data.Data['Additional C-Suite Personas']);
                this.prepareVpHead(data.Data['VP/Head Personas']);
                this.prepareProducts(data.Data);
            } else {
                this.toastMessage = data.Message;
                this.showError();
            }
        } else if (error) {
            if (Array.isArray(error.body)) {
                this.toastMessage = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.toastMessage = error.body.message;
            }
            this.showError();
        }
    }

    /** CXO **/
    prepareCXO(list) {
        const all = (list || []).map(c => ({ ...c, contactUrl: '/lightning/r/Contact/' + c.Id + '/view' }));
        this.cxoContacts = { CIO: [], CISO: [], CTO: [], Data: [] };
        all.forEach(c => {
            switch (c.Key_CXO_Stakeholder_Title__c) {
                case 'Head of IT (CIO)': this.cxoContacts.CIO.push(c); break;
                case 'Head of Security (CISO)': this.cxoContacts.CISO.push(c); break;
                case 'Head of Infrastructure (CTO)': this.cxoContacts.CTO.push(c); break;
                case 'Head of Data': this.cxoContacts.Data.push(c); break;
            }
        });
        this.cxoHasMoreAny =
            this.cxoContacts.CIO.length > 1 ||
            this.cxoContacts.CISO.length > 1 ||
            this.cxoContacts.CTO.length > 1 ||
            this.cxoContacts.Data.length > 1;
    }
    get firstCio() { return this.cxoContacts.CIO[0]; }
    get firstCiso() { return this.cxoContacts.CISO[0]; }
    get firstCto() { return this.cxoContacts.CTO[0]; }
    get firstData() { return this.cxoContacts.Data[0]; }

    /** Additional C-Suite **/
    prepareCSuite(list) {
        this.allCSuiteContacts = (list || []).map(c => ({ ...c, contactUrl: '/lightning/r/Contact/' + c.Id + '/view' }));
        const slice = this.allCSuiteContacts.slice(0, 4);
        this.cSuiteRow = slice.map((c, idx) => ({
            ...c,
            isLast: idx === slice.length - 1
        }));
        this.cSuiteHasMore = this.allCSuiteContacts.length > 4;
    }

    /** VP/Head **/
    prepareVpHead(list) {
        this.allVpHeadContacts = (list || []).map(c => ({ ...c, contactUrl: '/lightning/r/Contact/' + c.Id + '/view' }));
        const buckets = [[], [], [], [], []];
        this.allVpHeadContacts.forEach((c, index) => {
            const colIndex = index % 5; // round-robin distribution
            buckets[colIndex].push(c);
        });
        this.vpHeadBuckets = buckets.map((contacts, i, arr) => {
            const marked = contacts.map((c, idx) => ({
                ...c,
                isLast: idx === contacts.length - 1
            }));
            return { id: 'vp' + i, contacts: marked, isLastCol: i === arr.length - 1 };
        });
        this.vpHeadHasMore = this.allVpHeadContacts.length > 25;
    }

    /** Product Personas **/
    prepareProducts(data) {
        const names = ['Infrastructure Technology', 'Technology Architecture', 'Cloud Engineering', 'Security', 'App Owners'];
        this.productBuckets = names.map(name => {
            const all = (data[name] || []).map(c => ({ ...c, contactUrl: '/lightning/r/Contact/' + c.Id + '/view' }));
            return {
                id: name,
                name: name,
                contacts: all,
                display: all.slice(0, 10),
                hasMore: all.length > 10
            };
        });
    }

    /** Modal **/
    handleShowMore(event) {
        const category = event.target.dataset.category;
        if (category === 'CXO') {
            this.modalTitle = 'Key CXO Stakeholders';
            this.modalContacts = [
                ...this.cxoContacts.CIO,
                ...this.cxoContacts.CISO,
                ...this.cxoContacts.CTO,
                ...this.cxoContacts.Data
            ];
        } else if (category === 'C-Suite') {
            this.modalTitle = 'Additional C-Suite Personas';
            this.modalContacts = this.allCSuiteContacts;
        } else if (category === 'VPHead') {
            this.modalTitle = 'VP/Head Personas';
            this.modalContacts = this.allVpHeadContacts;
        } else {
            const bucket = this.productBuckets.find(b => b.name === category);
            this.modalTitle = 'Product Personas - ' + category;
            this.modalContacts = bucket ? bucket.contacts : [];
        }
        
        this.modalContacts = this.modalContacts.map(c => ({
            ...c,
            emailLink: c.Email ? 'mailto:' + c.Email : null
        }));

        this.showModal = true;
    }
    handleModalClose() {
        this.showModal = false;
    }

    // show error toast message
    showError(){
        const evt = new ShowToastEvent({
            title: 'Error',
            message: this.toastMessage,
            variant: 'error'
        });
        this.dispatchEvent(evt);
    }
    // myComponent.js
get mainTableStyle() {
  return '--cols: 2;';
}
get productTableStyle() {
  // assume productBuckets is an array from your code
  return `--cols: ${this.productBuckets ? this.productBuckets.length : 1};`;
}
get vpTableStyle() {
  return `--cols: ${this.vpHeadBuckets ? this.vpHeadBuckets.length : 1};`;
}

}