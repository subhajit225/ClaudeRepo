import { LightningElement, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';

export default class Pc_FeaturedItemCard_lwc extends LightningElement {
    @api cardslist = [];
    connectedCallback(){
        Promise.all([
            loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
            ]).then(() => {
                //console.log("File path-->"+ PartnerCommunityResource);
            })
            .catch(error => {
                console.log( error.body.message );
        });
        console.log('cardsList'+JSON.stringify(this.cardslist));
    }
}