import { LightningElement } from 'lwc';
import getModalDetails from '@salesforce/apex/PC_PortalNavigationApexController.getPartnerModalDetails';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import { NavigationMixin } from "lightning/navigation";
import basepath from '@salesforce/community/basePath';
export default class Pc_popUpResources_lwc extends NavigationMixin(LightningElement) {
    isShowModal =false;
    error;
    cardList = [];
    mainCard = {};
    basepath = basepath;

    connectedCallback(){
        Promise.all([
            loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
            ]).then(() => {
                //console.log("File path-->"+ PartnerCommunityResource);
            })
            .catch(error => {
                console.log( error.body.message );
        });
        getModalDetails()
        .then(result=>{
            for(let i=0; i<result.length ; i++){
                if(result[i].Link_Type__c == 'External URL'){
                    result[i].URLType = '_blank';
                }else if(result[i].Link_Type__c == 'Community Page'){
                    result[i].URLType = '_self';
                    result[i].Navigate_Url__c = this.basepath + result[i].Navigate_Url__c;
                }
            }
            for(const ele of result){
                if(ele.Image_Type__c == 'Welcome Wizard Resources'){
                    this.mainCard = ele;
                }else {
                    this.cardList.push(ele);
                }
            }
            this.isShowModal = true;

        })
        .catch(error=>{
            this.error =JSON.stringify(error);
            alert(this.error);
        });
    }

    handleExploreClick(event){
        this[NavigationMixin.Navigate]({
            "type": "standard__webPage",
            "attributes": {
                "url": this.mainCard.Navigate_Url__c
            }
        },true);
    }
}