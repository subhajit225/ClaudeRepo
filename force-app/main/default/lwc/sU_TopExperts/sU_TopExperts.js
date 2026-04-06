import { LightningElement, api, track } from 'lwc';
import CaseExpertDetail from '@salesforce/apex/su_vf_console.SUVFConsoleController.getCaseExperts';
import { registerListener, fireEvent } from 'c/supubsub';

export default class SU_TopExperts extends LightningElement {
    @api caseIds;
    @api eventCode;
    @api recordId;
    @api uid;
    @api endPoint;
    @api maincontainerwidth;
    relatedCasesExperts;//variable used to store Experts data and is used for iteration to display top experts that work on related cases
    @track showCasesExperts = true;//flag variable used to toggle display of data in top experts tab
    @track isExpertOneFlag = false;//flag variable used to toggle display of status modal popup 
    showCaseExperts = true;//flag variable used to toggle display of content in Top Experts tab eteen slack data or experts data
    relatedCasesExpertsBckup;
    expertClicked;
    viewExpertPopup = false;
    @track firstLoad = true;
    @track userFilters = {accounts: [{name:'Active',selected:true},{name:'Inactive',selected:true}]};
    origin;
    requiredFields;
    relatedCasesExpertsData;
    tabName;
    @api
    set sectionName(value){
        if (value == 'Top Experts') {
            this.setUserFilters();
            if (this.relatedCasesExperts && this.relatedCasesExperts.length < this.relatedCasesExpertsBckup.length) {
                this.relatedCasesExperts = this.relatedCasesExpertsBckup;
                this.showCasesExperts = this.relatedCasesExperts.length > 0;
            }
        }
        this.tabName = value;
    };
    get sectionName(){
        return this.tabName;
    }
    //method called when back button or share to slack button is clicked in child component
    handleHideCaseExperts(event) {
        this.showCaseExperts = event.detail;
    }

    renderedCallback(){
        let e = this.template.querySelector('.expert-section');
        if (this.maincontainerwidth < 450){
            e.className = 'expert-section su__agent-block-320';
        } else if (this.maincontainerwidth < 650) {
            e.className = 'expert-section su__agent-block-450';
        } else if (this.maincontainerwidth < 800) {
            e.className = 'expert-section su__agent-block-650';
        } else if (this.maincontainerwidth < 1300) {
            e.className = 'expert-section su__agent-block-800';
        } else if (this.maincontainerwidth > 1300) {
            e.className = 'expert-section su__agent-block-1300';
        }
    }
    //connectedCallback called on component loading to fetch experts working on case using case ids passed from parent component
    connectedCallback() {
        this.requiredFields = {
                'Case': 'Subject , Account.name, Status, CreatedDate,ClosedDate',
                'user': 'name, FullPhotoUrl, Department, Title, IsActive , Email'
        };
        this.origin = window.location.origin;
        if (this.caseIds) {
            CaseExpertDetail({ sCaseIds: JSON.stringify(this.caseIds), fieldsToFetch: JSON.stringify(this.requiredFields)}).then(response => {
                this.relatedCasesExpertsData = response;

                let userData = JSON.parse(this.relatedCasesExpertsData.users);
                let caseClosedCount = JSON.parse(this.relatedCasesExpertsData.totalCaseClosedCount);
                let relatedCaseCloseCount = JSON.parse(this.relatedCasesExpertsData.relatedCaseClosedCount);
                
                let responseDataVals = [];
                for(let i = 0; i < userData.length; i++){

                    responseDataVals.push({
                        'OwnerName': userData[i].Name,
                        'OwnerDepartment': userData[i].Department,
                        'OwnerTitle': userData[i].Title,
                        'Icon': userData[i].FullPhotoUrl,
                        'isActive': userData[i].IsActive,
                        'Email':userData[i].Email,
                        'TotalClosedCasesCount': caseClosedCount[userData[i].Id],
                        'RelatedClosedCaseCount': relatedCaseCloseCount[userData[i].Id],
                        previewUrl: this.origin +'/'+ userData[i].Id
                    });

                }
                
                this.relatedCasesExperts = responseDataVals;
                this.relatedCasesExpertsBckup = responseDataVals;
                this.showCasesExperts = responseDataVals.length > 0;
            }).catch(error => {
                this.showCasesExperts = false;
            });
        }
        this.setUserFilters();
    }
    setUserFilters(){
        this.userFilters = {accounts: [{name:'Active',selected:true},{name:'Inactive',selected:true}]};
    }

    //method to toggle display of status modal popup 
    openExpertModalOne(event) {
        this.isExpertOneFlag = !this.isExpertOneFlag;
        let expertModal = this.template.querySelector('div[data-id="containerExpertModalOne"]');
        let backdrop = this.template.querySelector('div[data-id="backdrop"]');
        if (this.isExpertOneFlag) {
            expertModal.classList.remove('su__d-none');
            backdrop.classList.remove('su__d-none');
        } else {
            expertModal.classList.add('su__d-none');
            backdrop.classList.add('su__d-none');
        }
        let selectedValues = this.userFilters.accounts.filter(function(f) {return f.selected }).map(function(f){return f.name});
        var chk = this.template.querySelectorAll('lightning-input[data-id="chkStatus"]') || [];
        chk.forEach(element => {
            let i = this.userFilters.accounts.find(f => f.name == element.label);
            element.checked = i.selected;
        });
        let allStatusChecked = this.template.querySelector('lightning-input[data-id="allStatusChecked"]') || {};
        allStatusChecked.checked = selectedValues.length == this.userFilters.accounts.length;
        event.currentTarget.blur();
    }
    //method called when the status checkbox (selects all statuses ) in modal popup is toggled
    handleAllStatusChange(event) {
        let allStatusChecked = this.template.querySelector('lightning-input[data-id="allStatusChecked"]');
        this.userFilters.accounts.forEach(f => f.selected = allStatusChecked.checked);
        if (allStatusChecked.checked)
            this.relatedCasesExperts = this.relatedCasesExpertsBckup;
        else this.relatedCasesExperts = [];
        var chk = this.template.querySelectorAll('lightning-input[data-id="chkStatus"]');
        chk.forEach(element => {
            element.checked = allStatusChecked.checked;
        });
        this.showCasesExperts = this.relatedCasesExperts.length > 0;
        event.currentTarget.blur();
    }

    getSlackChannels(event){
            fireEvent(null, 'getSlackChannels'+this.eventCode, null);
            event.currentTarget.blur();
    }

    expertsDivClicked(event) {
        if (event.currentTarget.dataset.index > -1)
            this.expertClicked = this.relatedCasesExperts[event.currentTarget.dataset.index];
            this.viewExpertPopup =  true;
    }

    emailCopyToClipboard(){
        let check = true;
        let expert_email= this.expertClicked.Email ;
        if (!expert_email || !expert_email.length){
            check = false; 
        }
        let tag = document.createElement('textarea');
        tag.setAttribute('id', 'input_test_id');
        tag.value = expert_email;
        document.getElementsByTagName('body')[0].appendChild(tag);
        document.getElementById('input_test_id').select();
        document.execCommand('copy');
        document.getElementById('input_test_id').remove();

        var linkId = this.template.querySelector('[data-id="toastId"]');
        this.template.querySelector('[data-id="toastId"]').classList.remove('showFormBlock');
        setTimeout(function () { linkId.classList.add('showFormBlock'); }, 1000);
    }

    expertsPopupClosed(){
        this.viewExpertPopup = false;
    }

    //method called when individual status value is toggled in status modal popup .Filters data being displayed in Top Experts Tab
    applyUserFilters(event){
        var chk = this.template.querySelectorAll('lightning-input[data-id="chkStatus"]');
        chk.forEach(element => {
            let i = this.userFilters.accounts.find(f => f.name == element.label);
            i.selected = element.checked;
        });
        let selectedValues = this.userFilters.accounts.filter(function(f) {return f.selected }).map(function(f){return f.name});
        if (!selectedValues.length)
            this.relatedCasesExperts = [];
        else {
            this.relatedCasesExperts = this.relatedCasesExpertsBckup.filter(function(u) {
                return (selectedValues.indexOf(u.isActive == 'false' || !u.isActive ? 'Inactive': 'Active') > -1);
            })
        }

        let allStatusChecked = this.template.querySelector('lightning-input[data-id="allStatusChecked"]')
        allStatusChecked.checked = selectedValues.length == this.userFilters.accounts.length;
        this.showCasesExperts = this.relatedCasesExperts.length > 0;
        event.currentTarget.blur();
    }
}