import { LightningElement,api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updatecontact from '@salesforce/apex/PC_UserManagementApexController.updateContact';

import Id_Field from '@salesforce/schema/Contact.Id';
import Email_Field from '@salesforce/schema/Contact.Email';
import FirstName_Field from '@salesforce/schema/Contact.FirstName';
import LastName_Field from '@salesforce/schema/Contact.LastName';
import Job_Function_Field from '@salesforce/schema/Contact.Title';
import Phone_Field from '@salesforce/schema/Contact.Phone';
import PrimaryRole_Field from '@salesforce/schema/Contact.Primary_Role__c';

export default class Pc_editPartnerPortalUser_lwc extends LightningElement {
    @api contactRecord;
    showModal = false;
    showSpinner = true;
    adminaccess = false;
    isDisabled = false;
    fieldValuesChanged = false;
    updateContactRecord = {};

    fieldNames ={
        Email : Email_Field.fieldApiName,
        FirstName : FirstName_Field.fieldApiName,
        LastName : LastName_Field.fieldApiName,
        Title : Job_Function_Field.fieldApiName,
        Phone : Phone_Field.fieldApiName,
        Primary_Role__c : PrimaryRole_Field.fieldApiName,
        Id : Id_Field.fieldApiName
    };


    connectedCallback() {
        Promise.all([
            loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
            ]).then(() => {
                console.log("File path-->"+ PartnerCommunityResource);
            })
            .catch(error => {
                console.log( error.body.message );
            });
        if(this.contactRecord){
            for(const prop in this.fieldNames){
                this.updateContactRecord[this.fieldNames[prop]] = this.contactRecord[this.fieldNames[prop]];
            }
            console.log('conr ec'+JSON.stringify(this.updateContactRecord));
            if(this.updateContactRecord['Primary_Role__c'] === 'Admin'){
                this.adminaccess = true;
                this.isDisabled = true;
            }
            console.log(JSON.stringify(this.updateContactRecord));
        }
        this.showModal = true;
        this.showSpinner = false; 
    }

    handleChangeEvent(event){
        this.updateContactRecord[event.target.name] = event.target.value;
    }

    handleCheck(event){
        this.updateContactRecord[event.target.name] = event.target.checked;
    }

    handleAdminAccess(event){
        console.log(event.target.checked);
        this.adminaccess = event.target.checked;
    }

    handleSubmit(){
        console.log(JSON.stringify(this.updateContactRecord));
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.userClass');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }else{
                inputField.reportValidity();
            }
        });
        if(isValid){
            this.showSpinner = true;
            this.checkChangedFieldValues();
            var toastMessage = '';
            if(this.adminaccess){
                toastMessage = 'Admin access request sent for approval';
            }else{
                toastMessage = 'User Updated';
            }
            updatecontact({ con : this.updateContactRecord, admAccess : this.adminaccess, fieldValuesChanged : this.fieldValuesChanged})
                .then(result=>{
                    console.log('-->'+result);
                    if(result != "Accountexist" && result != "success"){
                        this.showToastEvent("Error","Unable to save record","error");
                        this.showSpinner = false;
                        this.closeModal();
                    }else{
                        this.showToastEvent("Success",toastMessage,"success");
                        this.showSpinner = false;
                        this.closeModal();
                    }
                })
                .catch(error=>{
                    console.log('error->'+JSON.stringify(error));
                    this.showToastEvent("Error",JSON.stringify(error),"error");
                    this.showSpinner = false;
                });
        }
    }

    closeModal(){
        const selectEvent = new CustomEvent('close_edit_user_form', {
            detail: false
        });
       this.dispatchEvent(selectEvent);
    }

    showToastEvent(title, message, variant){
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    checkChangedFieldValues(){
        for(const prop in this.fieldNames){
            if(this.contactRecord[this.fieldNames[prop]] !== this.updateContactRecord[this.fieldNames[prop]]){
                this.fieldValuesChanged = true;

            }
        }
    }
}