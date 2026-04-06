import { LightningElement, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import getPageDetails from '@salesforce/apex/PC_PortalNavigationApexController.getPageDescription';
import getUserDetails from '@salesforce/apex/PC_PortalNavigationApexController.getLoggedInUserDetails';
import { NavigationMixin } from "lightning/navigation";
import basepath from '@salesforce/community/basePath';
export default class Pc_titleTextButton_lwc extends NavigationMixin(LightningElement) {

    @api headerValue = null;
    @api titleValue = null;
    @api textValue = null;
    @api buttonValue = null;
    @api navigationLink = null;
    isData = true;
    urlType;
    basepath = basepath;

    //prit26-7
    userDetails;
    showManageServiceButton = false;
    navigationLink2 = basepath + '/managed-service-request-terms';
    urlType2 = '_self';

    connectedCallback()
    {
        Promise.all([
            loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
            ]).then(() => {
                console.log("File path-->"+ PartnerCommunityResource);
            })
            .catch(error => {
                console.log( error.body.message );
        });
        getUserDetails()
        .then(result=>{
            this.userDetails = result;
            let pageName = window.document.title;
            if(result.ContactId != null && (result.Contact.Account.Type == 'MSP' || result.Contact.Account.Type == 'MSP-Reseller') && pageName == 'Deal Registrations'){
                this.showManageServiceButton = true;
            }
            
        })
        .catch(error=>{

        });
        let pName = window.document.title;
        getPageDetails({pageName : pName})
        .then(result=>{
            console.log('result ->'+JSON.stringify(result));
            if(result.length > 0){
                this.headerValue = result[0].Headline__c;
                this.titleValue = result[0].Card_Title__c;
                this.textValue = result[0].Description__c;
                this.buttonValue = result[0].Navigate_Text__c;
                if(result[0].Link_Type__c == 'External URL'){
                    this.urlType = '_blank';
                    this.navigationLink = result[0].Navigate_Url__c;
                }else if(result[0].Link_Type__c == 'Community Page'){
                    this.urlType = '_self';
                    this.navigationLink = this.basepath + result[0].Navigate_Url__c;
                }
            }else{
                this.isData = false;
            }
            
        })
        .catch(error=>{
            console.log(JSON.stringify(error));
        });
    }

    handleButtonClick(event){
        if(this.navigationLink != null){
            window.open(this.navigationLink,this.urlType);
        }
    }

    handleButtonClick2(evennt){
        if(this.navigationLink2 != null){
            window.open(this.navigationLink2,this.urlType2);
        }
    }

    get showButton(){
        if(this.buttonValue != null){
            return true;
        }else{
            return false;
        }
    }

    get showText(){
        if(this.textValue != null){
            return true;
        }else{
            return false;
        }
    }

    get showTitle(){
        if(this.titleValue != null){
            return true;
        }else{
            return false;
        }
    }

    get showHeader(){
        if(this.headerValue != null){
            return true;
        }else{
            return false;
        }
    }
}