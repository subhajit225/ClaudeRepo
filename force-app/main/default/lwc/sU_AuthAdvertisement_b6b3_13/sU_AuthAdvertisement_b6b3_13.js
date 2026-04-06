import { LightningElement, track, api } from 'lwc';
import { registerListener, unregisterListener, fireEvent, getURLParameter } from 'c/authsupubsub_b6b3_13';

export default class SU_AuthAdvertisement extends LightningElement {
    @track advertisement = '';
    @api uidAdv;
    @track searchstring;
    @track uniqueHrefsList = [];
    @api pageNumber;
    @track renderHtml;
    @api endPointAdv;

    connectedCallback() {
        registerListener('getAdvertisement', this.searchStringAdv, this);
        if (typeof this.searchstring == 'undefined') {
            this.searchstring = getURLParameter('searchString') != "" ? getURLParameter('searchString') : '';
        }
        this.getAdv();
    }
    
    disconnectedCallback() {
        unregisterListener('getAdvertisement', this.searchStringAdv, this);
    }

    searchStringAdv(string) {
        this.searchstring = string;
        this.getAdv();
    }
 

    getAdv() {
        this.renderHtml = true;
        const xhr = new XMLHttpRequest();
        const url = `${this.endPointAdv}/admin/searchClient/readAdHTML/${this.uidAdv}?phrase=${this.searchstring}`;
        xhr.open('GET', url, true);
        xhr.onload = () => {
            if (xhr.status === 200) {
                this.uniqueHrefsList = [];
                const response = JSON.parse(xhr.responseText).htmlString;
                this.advertisement = response;
                if (response !== '') {
                    const container = this.template.querySelector('[data-id="advertisementString"]');
                    if(container){
                        container.innerHTML = this.advertisement;
                    }
                    gza('adv_view', {
                        textSearched: this.searchstring,
                        advId: this.searchstring,
                        url: window.location.href,
                        page_no: parseInt(this.pageNumber)
                    })

                } else {
                    this.advertisement = ''
                    this.renderHtml = false;
                }

            }
        };
        xhr.send();
    }
    advertisementClick(e) {
        const closestHrefElement = e.target.closest('[href]:not([href=""])');
        if (closestHrefElement) {
            const href = closestHrefElement.getAttribute('href');
            if (href && href.trim() !== '') {
                if (!this.uniqueHrefsList.includes(href)) {
                    this.uniqueHrefsList.push(href);
                    gza('adv_click', {
                        textSearched: this.searchstring,
                        advId: this.searchstring,
                        url: window.location.href,
                        advUrl: href,
                        page_no: parseInt(this.pageNumber)
                    });
                }
            }
        }
    }


}