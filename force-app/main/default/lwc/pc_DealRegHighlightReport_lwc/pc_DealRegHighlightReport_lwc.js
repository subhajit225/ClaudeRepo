import { LightningElement } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import getDealRegData from '@salesforce/apex/PC_DealRegTableController.getDealRegData';
import getUserDetails from '@salesforce/apex/PC_PortalNavigationApexController.getLoggedInUserDetails';
import {NavigationMixin} from "lightning/navigation";
export default class Pc_DealRegHighlightReport_lwc extends NavigationMixin(LightningElement){
    dealRegList = [];
    approvedDRCount = 0;
    submittedDRCount = 0;

    //prit26-7
    userDetails;
    showManageServiceButton = false;

    connectedCallback(){
        Promise.all([
            loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
            ]).then(() => {
                //console.log("File path-->"+ PartnerCommunityResource);
            })
            .catch(error => {
                console.log( error );
            });

        getDealRegData()
        .then(result=>{
            console.log('result'+JSON.stringify(result));
            this.approvedDRCount = result.approvedDRCount;
            this.submittedDRCount = result.submittedDRCount;
            this.dealRegList = result.dealRegList;
        })
        .catch(error=>{
            console.log('-->'+error);
        });

        getUserDetails()
        .then(result=>{
            this.userDetails = result;
            if(result.ContactId != null && (result.Contact.Account.Type == 'MSP' || result.Contact.Account.Type == 'MSP-Reseller')){
                this.showManageServiceButton = true;
            }
        })
        .catch(error=>{
            console.log('->'+error);
        });
    }

    handleClick(){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Deal_Reg_Terms__c'
            }
        });
    }

    handleClickManagedService(){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Managed_Service_Request_Terms__c'
            }
        });
    }

    handleViewAll(){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Deal_Reg_List__c'
            }
        });
    }
}