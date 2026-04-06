import { LightningElement } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';
import basepath from '@salesforce/community/basePath';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import categoryCardConfig from '@salesforce/apex/PC_PortalNavigationApexController.getCategoryCardConfigs';

export default class Pc_categoryCard_lwc extends NavigationMixin(LightningElement) {
    cardList = [];

    connectedCallback(){
        Promise.all([
            loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
            ]).then(() => {

            })
            .catch(error => {
                console.log( error.body.message );
        });
        let currentPageName = window.document.title;

        categoryCardConfig({ pageName : currentPageName})
        .then(result=>{
            var cardListTemp = [];
            //console.log('20->'+JSON.stringify(result));
            Object.keys(result).forEach(key => {
                let valEle = [];
                valEle = result[key];
                if(result[key].Image_Url__c){
                    valEle['hasImage'] = true;
                }else{
                    valEle['hasImage'] = false;
                }
                if(result[key].Navigate_Url__c && result[key].Link_Type__c == 'Community Page'){
                    valEle['url'] = basepath + valEle.Navigate_Url__c;
                }else if(result[key].Navigate_Url__c && result[key].Link_Type__c == 'External URL'){
                    valEle['url'] = valEle.Navigate_Url__c;
                }
                cardListTemp.push(valEle);
            });
            this.cardList = cardListTemp;
            console.log('cardList all'+JSON.stringify(this.cardList));
        })
        .catch(error=>{
            console.log('-->'+JSON.stringify(error));
        });
    }
}