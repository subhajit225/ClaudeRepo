import { LightningElement } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import getContactsList from '@salesforce/apex/PC_UserManagementApexController.getContactList';
import deactivateUser from '@salesforce/apex/PC_UserManagementApexController.deactivateUser';
import activateUser from '@salesforce/apex/PC_UserManagementApexController.userActivation';
import updateUser from '@salesforce/apex/PC_UserManagementApexController.updateUser';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class Pc_UserManagementTable_lwc extends LightningElement {
    loader = false;
    error = null;
    pageSize = 20;
    pageNumber = 1;
    totalRecords = 0;
    totalPages = 0;
    recordEnd = 0;
    recordStart = 0;
    isPrev = true;
    isNext = true;
    contacts = [];
    nameSearch = '';
    disableReset = true;
    showAddUserForm = false;
    selectedRow;
    personLeftTheCompany = false;
    other = false;
    conId = null;
    userEmail = null;
    isShowModalDeactivateUser = false;
    showEditUserForm = false;
    customEventDetail = {};
    contactRec = {};
    activatedUser ={};
    deactivateUser = {};

    //On load
    connectedCallback() {
        Promise.all([
            loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
        ]).then(() => {
            console.log("File path-->"+ PartnerCommunityResource);
        }).catch(error => {
            console.log( error.body.message );
        });
        this.getContacts();
    }

    //handle next
    handleNext(){
        this.pageNumber = this.pageNumber+1;
        this.getContacts();
    }

    //handle prev
    handlePrev(){
        this.pageNumber = this.pageNumber-1;
        this.getContacts();
    }

    //get accounts
    getContacts(){
        this.loader = true;
        getContactsList({pageSize: this.pageSize, pageNumber : this.pageNumber, searchText : this.nameSearch})
        .then(result => {
            this.loader = false;
            if(result){
                let resultData = JSON.parse(result);
                console.log('contact'+JSON.stringify(resultData.contactRecList));
                let contactRecAll = [];
                for(let ele of resultData.contactRecList){
                    let conRec = {};
                    conRec = ele;

                    let createdDate = new Date(ele.CreatedDate);
                    let todayDate = new Date();
                    let tempCreatedDateTime = createdDate.getTime();
                    let tempTodayDateTime = todayDate.getTime();
                    let daysDifference = Math.floor((tempTodayDateTime-tempCreatedDateTime)/(24*3600*1000));

                    if(ele.CommunityUser__c && ele.CommunityUser__r.IsActive && this.conId != ele.Id){
                        conRec['Status'] = 'Active';
                        conRec['Toggle'] = true;
                    }else if(ele.Email == this.customEventDetail.contactEmail && this.customEventDetail.isPartnerUser && this.conId != ele.Id){
                        conRec['Status'] = 'Active';
                        conRec['Toggle'] = true;
                    }else if(ele.Id == this.deactivateUser.Id && this.deactivateUser.isDeactivate == true){
                        conRec['Status'] = 'Inactive';
                        conRec['Toggle'] = false;
                        this.deactivateUser = {};
                    }else if(ele.Id == this.activatedUser.Id && this.activatedUser.isActivate == true){
                        conRec['Status'] = 'Active';
                        conRec['Toggle'] = true;
                        this.activatedUser = {};
                    }else{
                        conRec['Status'] = 'Inactive';
                        conRec['Toggle'] = false;
                    }
                    if(daysDifference <= 1){
                        conRec['isNew'] = true;
                    }else{
                        conRec['isNew'] = false;
                    }
                    contactRecAll.push(conRec);
                }
                this.contacts = contactRecAll;
                this.pageNumber = resultData.pageNumber;
                this.totalRecords = resultData.totalRecords;
                this.recordStart = resultData.recordStart;
                this.recordEnd = resultData.recordEnd;
                this.totalPages = Math.ceil(resultData.totalRecords / this.pageSize);
                this.isNext = (this.pageNumber == this.totalPages || this.totalPages == 0);
                this.isPrev = (this.pageNumber == 1 || this.totalRecords < this.pageSize);
            }
        })
        .catch(error => {
            this.loader = false;
            this.error = error;
        });
    }

    //display no records
    get isDisplayNoRecords() {
        var isDisplay = true;
        if(this.contacts){
            if(this.contacts.length == 0){
                isDisplay = true;
            }else{
                isDisplay = false;
            }
        }
        return isDisplay;
    }

    //search portal users
    handleKeyUp(event) {
        const isEnterKey = event.keyCode === 13;
        if(isEnterKey) {
            let searchVal = event.target.value;
            if(searchVal){
                this.nameSearch = searchVal;
                this.disableReset = false;
                this.getContacts();
            }
        }
    }

    handleReset(){
        this.nameSearch = '';
        this.getContacts();
        this.disableReset = false;
    }

    handleToggle(event){
        this.conId = event.currentTarget.dataset.id;
        this.userEmail = event.currentTarget.dataset.email;
        if(event.target.checked == false){
            this.selectedRow = event.target;
            this.isShowModalDeactivateUser = true;
        }else if(event.target.checked == true){
            this.selectedRow = event.target;
            this.loader = true;
            this.handleActivateUser();
        }
    }

    handleAddNewUser(){
        this.isPartnerUser = false;
        this.showAddUserForm = true;
    }

    handleCustomEvent(event){
        this.showAddUserForm = event.detail.closeModal;
        this.customEventDetail = event.detail;
        console.log('this.customEventDetail'+JSON.stringify(this.customEventDetail));
        if(event.detail.result == "success"){
            this.getContacts();
        }
    }

    handlePersonLeft(event){
        if(event.target.checked == true){
            this.other = false;
            this.personLeftTheCompany = event.target.checked;
        }else{
            this.personLeftTheCompany = event.target.checked;
        }
    }

    handleOther(event){
        if(event.target.checked == true){
            this.personLeftTheCompany = false;
            this.other = event.target.checked;
        }else{
            this.other = event.target.checked;
        }
    }

    handleDeactivateUser(event){
        this.loader = true;
        deactivateUser({conId : this.conId , reason : this.personLeftTheCompany})
        .then(result=>{
            console.log('result'+result);
            if(result == 'success'){
                this.deactivateUserRecord();
            }  
        })
        .catch(error=>{
            console.log('error Deactivate User->'+JSON.stringify(error));
            this.showToastEvent('Error', JSON.stringify(error),'error');
            this.loader = false;
        });
    }

    deactivateUserRecord(){
        updateUser({contactId : this.conId})
                .then(result=>{
                    console.log('deactivateUserRecord result->'+result);
                    this.showToastEvent('Success', 'User Deactivated','success');
                    this.selectedRow.checked = false;
                    let Deactivatetemp = {};
                    Deactivatetemp['isDeactivate'] = true;
                    Deactivatetemp['Id'] = this.conId;
                    this.deactivateUser = Deactivatetemp;
                    this.getContacts();
                    this.closeModalDeactivateUser();
                    this.loader = false;
                })
                .catch(error=>{
                    console.log('error update User->'+JSON.stringify(error));
                    this.showToastEvent('Error', JSON.stringify(error),'error');
                    this.loader = false;
                });
    }

    closeModalDeactivateUser(){
        this.isShowModalDeactivateUser = false;
        //Reactivate the toggle code here
        this.selectedRow.checked = true;
        this.personLeftTheCompany = false;
        this.other = false;
    }

    showToastEvent(title, message, variant){
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    handleActivateUser(){
        activateUser({conId : this.conId})
        .then(result=>{
            console.log('result->'+result);
            this.showToastEvent('Success', 'User Activated','success');
            let Activatetemp ={};
            Activatetemp['Id'] = this.conId;
            Activatetemp['isActivate'] = true;
            this.activatedUser = Activatetemp;
            this.getContacts();
            this.selectedRow.checked = true;
        })
        .catch(error=>{
            console.log('error->'+JSON.stringify(error));
            this.showToastEvent('Error', JSON.stringify(error),'error');
        });
        this.loader = false;
    }

    handleEditUser(event){
        const rowIndex = event.currentTarget.dataset.index;
        this.contactRec = this.contacts[rowIndex];
        this.showEditUserForm = true;
    }

    handleCloseEditUserEvent(event){
        this.showEditUserForm = event.detail;
        this.getContacts();
    }
}