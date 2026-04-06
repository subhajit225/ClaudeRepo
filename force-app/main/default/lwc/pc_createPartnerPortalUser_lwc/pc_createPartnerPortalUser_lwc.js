import { LightningElement, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Email_Field from '@salesforce/schema/Contact.Email';
import FirstName_Field from '@salesforce/schema/Contact.FirstName';
import LastName_Field from '@salesforce/schema/Contact.LastName';
import Job_Function_Field from '@salesforce/schema/Contact.Title';
import Phone_Field from '@salesforce/schema/Contact.Phone';
import addNewUser from '@salesforce/apex/PC_UserManagementApexController.createNewUser';
export default class Pc_createPartnerPortalUser_lwc extends LightningElement {
    activateUser = false;
    showSpinner = false;
    disableButton = false;
    fieldNames ={
        email : Email_Field.fieldApiName,
        firstName : FirstName_Field.fieldApiName,
        lastName : LastName_Field.fieldApiName,
        jobTitle : Job_Function_Field.fieldApiName,
        phone : Phone_Field.fieldApiName
    };
    @track contactRecord = {
        [Email_Field.fieldApiName] : "",
        [FirstName_Field.fieldApiName] : "",
        [LastName_Field.fieldApiName] : "",
        [Job_Function_Field.fieldApiName] : "",
        [Phone_Field.fieldApiName] : ""
    };
    result;
    connectedCallback() {
        Promise.all([
            loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
            ]).then(() => {
                console.log("File path-->"+ PartnerCommunityResource);
            })
            .catch(error => {
                console.log( error.body.message );
            });
    }

    handleChangeEvent(event){
        this.contactRecord[event.target.name] = event.target.value;
    }

    handleCheck(event){
        this.activateUser = event.target.checked;
    }

    handleSubmit(){
        console.log('-->',JSON.stringify(this.contactRecord));
        this.showSpinner = true;
        this.disableButton = true;
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.inputClass');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }else{
                inputField.reportValidity();
            }
        });
        if(isValid){
            addNewUser({ conObj : this.contactRecord, createPortalUser : this.activateUser})
            .then(result=>{
                console.log('-->'+result);
                this.result = result;
                if(result != "success"){
                    this.showSpinner = false;
                    this.disableButton = false;
                    let emailField = this.template.querySelector('.emailClass');
                    emailField.setCustomValidity(result);
                    emailField.reportValidity();
                }else{
                    this.showToastEvent("Success",'New User Added',"success");
                    this.showSpinner = false;
                    this.disableButton = false;
                    this.closeModal();
                }
            })
            .catch(error=>{
                var errMsg = '';
                console.log('error->'+JSON.stringify(error));
                if(error != undefined && error.body.pageErrors.length>0 && error.body.pageErrors[0].message !=''){
                    errMsg = JSON.stringify(error.body.pageErrors[0].message);
                }else if(error != undefined){
                    errMsg = JSON.stringify(error);
                }
                this.showSpinner = false;
                this.showToastEvent("Error",errMsg,"error");
                this.disableButton = false;
            });
        }else{
            this.disableButton = false;
            this.showSpinner = false;
        }
    }

    closeModal(){
        var eventDetails = {contactEmail : this.contactRecord.Email , isPartnerUser : this.activateUser, closeModal : false, result : this.result};
        const selectEvent = new CustomEvent('mycustomevent', {
            detail : eventDetails
        });
       this.dispatchEvent(selectEvent);
       this.activateUser = false;
    }

    showToastEvent(title, message, variant){
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}