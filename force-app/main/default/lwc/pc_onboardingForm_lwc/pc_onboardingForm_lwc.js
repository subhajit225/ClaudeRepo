import { LightningElement, track } from 'lwc';
import getPicklistValues from '@salesforce/apex/PC_PartnerOnboardingRequestContoller.getPicklistValues';
import getDependentValues from '@salesforce/apex/PC_PartnerOnboardingRequestContoller.getDependentPicklistValues';
import getDistributorValue from '@salesforce/apex/PC_PartnerOnboardingRequestContoller.getDistributorNames';
import getDistributorUSValue from '@salesforce/apex/PC_PartnerOnboardingRequestContoller.getUSDistributorNames';
import savePartnerOnboard from '@salesforce/apex/PC_PartnerOnboardingRequestContoller.savePartnerOnboard';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import basepath from '@salesforce/community/basePath';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//fields
import Company_Name_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Company_Name__c';
import Address_1_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Address_1__c';
import Address_2_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Address_2__c';
import City_Field from '@salesforce/schema/Partner_Onboarding_Request__c.City__c';
import Country_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Country__c';
import State_Field from '@salesforce/schema/Partner_Onboarding_Request__c.StateProvince__c';
import Postal_Code_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Postal_Code__c';
import Website_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Website__c';
import Interest_in_becoming_a_Rubrik_Partner_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Interest_in_becoming_a_Rubrik_Partner__c';
import Reselling_Technology_To_Customers_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Reselling_technology_to_customers__c';
import Providing_Software_As_Service_Solution_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Providing_Software_As_Service_Solution__c';
import PartnerType_Field from '@salesforce/schema/Partner_Onboarding_Request__c.PartnerType__c';
import First_Name_Field from '@salesforce/schema/Partner_Onboarding_Request__c.First_Name__c';
import Last_Name_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Last_Name__c';
import Email_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Email__c';
import Phone_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Phone__c';
import Title_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Title__c';
import Contact_Type_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Contact_Type__c';
import Same_As_Portal_Admin_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Same_As_Portal_Admin__c';
import Sales_Contact_First_Name_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Sales_Contact_First_Name__c';
import Sales_Contact_Last_Name_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Sales_Contact_Last_Name__c';
import Sales_Contact_Email_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Sales_Contact_Email__c';
import Sales_Contact_Phone_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Sales_Contact_Phone__c';
import Sales_Contact_Title_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Sales_Contact_Title__c';
import Sales_Point_Contact_type_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Sales_Point_Contact_Type__c';
import Same_as_Partner_Portal_Admin_Technical_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Same_as_Partner_Portal_Admin_Technical__c';
import Same_As_Sales_Contact_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Same_As_Sales_Contact__c';
import Technical_Contact_First_Name_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Technical_Contact_First_Name__c';
import Technical_Contact_Last_Name_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Technical_Contact_Last_Name__c';
import Technical_Contact_Email_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Technical_Contact_Email__c';
import Technical_Contact_Phone_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Technical_Contact_Phone__c';
import Technical_Contact_Title_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Technical_Contact_Title__c';
import Technical_Point_Contact_Type_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Technical_Point_Contact_Type__c';
import Segment_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Segment__c';
import Distributor_Account_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Distributor__c';
import Vendors_your_Org_works_with_today_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Vendors_your_Org_works_with_today__c';
import Additional_Comments_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Additional_Comments__c';
import Referral_Source_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Referral_Source__c';
import Outside_Sales_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Outside_Sales__c';
import Technical_Sales_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Technical_Sales__c';
import Inside_Sales__c from '@salesforce/schema/Partner_Onboarding_Request__c.Inside_Sales__c';
import Employed_by_Gov_Entity_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Employed_by_Gov_Entity__c';
import Sell_to_Gov_Entities_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Sell_to_Gov_Entities__c';
import Violation_of_Anti_Corruption_Laws_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Violation_of_Anti_Corruption_Laws__c';
import FCPAPP_Field from '@salesforce/schema/Partner_Onboarding_Request__c.FCPAPP__c';
import Rubrik_Relationship_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Rubrik_Relationship__c';
import Violation_of_Anti_Corruption_Laws_Notes_Field from '@salesforce/schema/Partner_Onboarding_Request__c.Violation_of_Anti_Corruption_Laws_Notes__c';

export default class Pc_onboardingForm_lwc extends LightningElement {
    fieldNames ={
        //Company Information 
        companyName : Company_Name_Field.fieldApiName,
        address1 : Address_1_Field.fieldApiName,
        address2 : Address_2_Field.fieldApiName,
        city : City_Field.fieldApiName,
        country : Country_Field.fieldApiName,
        state : State_Field.fieldApiName,
        postalCode : Postal_Code_Field.fieldApiName,
        website : Website_Field.fieldApiName,
        interestInRubrikPartner : Interest_in_becoming_a_Rubrik_Partner_Field.fieldApiName,
        resellingTechnology : Reselling_Technology_To_Customers_Field.fieldApiName,
        providingSoftware : Providing_Software_As_Service_Solution_Field.fieldApiName,
        partnerType : PartnerType_Field.fieldApiName,

        //Partner Information
        firstName : First_Name_Field.fieldApiName,
        lastName : Last_Name_Field.fieldApiName,
        email : Email_Field.fieldApiName,
        phoneNumber : Phone_Field.fieldApiName,
        title : Title_Field.fieldApiName,
        contactType : Contact_Type_Field.fieldApiName,

        sameAsPartnerPortalAdmin : Same_As_Portal_Admin_Field.fieldApiName,
        salesFirstName : Sales_Contact_First_Name_Field.fieldApiName,
        salesLastName : Sales_Contact_Last_Name_Field.fieldApiName,
        salesEmail : Sales_Contact_Email_Field.fieldApiName,
        salesPhone : Sales_Contact_Phone_Field.fieldApiName,
        salesTitle : Sales_Contact_Title_Field.fieldApiName,
        salesContactType : Sales_Point_Contact_type_Field.fieldApiName,

        sameAsPartnerPortalAdminTech : Same_as_Partner_Portal_Admin_Technical_Field.fieldApiName,
        sameAsSalesPointOfContactTech : Same_As_Sales_Contact_Field.fieldApiName,
        techFirstName : Technical_Contact_First_Name_Field.fieldApiName,
        techLastName : Technical_Contact_Last_Name_Field.fieldApiName,
        techEmail : Technical_Contact_Email_Field.fieldApiName,
        techPhone : Technical_Contact_Phone_Field.fieldApiName,
        techTitle : Technical_Contact_Title_Field.fieldApiName,
        techContactType : Technical_Point_Contact_Type_Field.fieldApiName,

        //Business Information
        segment : Segment_Field.fieldApiName,
        distributor : Distributor_Account_Field.fieldApiName,
        vendors : Vendors_your_Org_works_with_today_Field.fieldApiName,
        additionalComments : Additional_Comments_Field.fieldApiName,
        referralSource : Referral_Source_Field.fieldApiName,
        outsideSales : Outside_Sales_Field.fieldApiName,
        technicalSales : Technical_Sales_Field.fieldApiName,
        insideSales : Inside_Sales__c.fieldApiName,

        //Legal Disclaimer
        employedByGovEntity : Employed_by_Gov_Entity_Field.fieldApiName,
        sellToGovEntity : Sell_to_Gov_Entities_Field.fieldApiName,
        violationOfAntiCorruption : Violation_of_Anti_Corruption_Laws_Field.fieldApiName,
        fcpap : FCPAPP_Field.fieldApiName,
        rubRel : Rubrik_Relationship_Field.fieldApiName,
        violationOfAnticorruptionLawNotes : Violation_of_Anti_Corruption_Laws_Notes_Field.fieldApiName,

    };
    @track partnerOnboardingRecord ={
        [Company_Name_Field.fieldApiName] : "",
        [Address_1_Field.fieldApiName] : "",
        [Address_2_Field.fieldApiName] : "",
        [City_Field.fieldApiName] : "",
        [Country_Field.fieldApiName] : "",
        [State_Field.fieldApiName] : "",
        [Postal_Code_Field.fieldApiName] : "",
        [Website_Field.fieldApiName] : "",
        [Interest_in_becoming_a_Rubrik_Partner_Field.fieldApiName] : "",
        [Reselling_Technology_To_Customers_Field.fieldApiName] : "",
        [Providing_Software_As_Service_Solution_Field.fieldApiName] : "",
        [PartnerType_Field.fieldApiName] : "",

        //Partner Information
        [First_Name_Field.fieldApiName] : "",
        [Last_Name_Field.fieldApiName] : "",
        [Email_Field.fieldApiName] : "",
        [Phone_Field.fieldApiName] : "",
        [Title_Field.fieldApiName] : "",
        [Contact_Type_Field.fieldApiName] : "Admin",

        [Same_As_Portal_Admin_Field.fieldApiName] : "",
        [Sales_Contact_First_Name_Field.fieldApiName] : "",
        [Sales_Contact_Last_Name_Field.fieldApiName] : "",
        [Sales_Contact_Email_Field.fieldApiName] : "",
        [Sales_Contact_Phone_Field.fieldApiName] : "",
        [Sales_Contact_Title_Field.fieldApiName] : "",
        [Sales_Point_Contact_type_Field.fieldApiName] : "Sales",

        [Same_as_Partner_Portal_Admin_Technical_Field.fieldApiName] : "",
        [Same_As_Sales_Contact_Field.fieldApiName] : "",
        [Technical_Contact_First_Name_Field.fieldApiName] : "",
        [Technical_Contact_Last_Name_Field.fieldApiName] : "",
        [Technical_Contact_Email_Field.fieldApiName] : "",
        [Technical_Contact_Phone_Field.fieldApiName] : "",
        [Technical_Contact_Title_Field.fieldApiName] : "",
        [Technical_Point_Contact_Type_Field.fieldApiName] : "Technical",

        //Business Information
        [Segment_Field.fieldApiName] : "",
        [Distributor_Account_Field.fieldApiName] : "",
        [Vendors_your_Org_works_with_today_Field.fieldApiName] : "",
        [Additional_Comments_Field.fieldApiName] : "",
        [Referral_Source_Field.fieldApiName] : "",
        [Outside_Sales_Field.fieldApiName] : "",
        [Technical_Sales_Field.fieldApiName] : "",
        [Inside_Sales__c.fieldApiName] : "",

        //Legal Disclaimer
        [Employed_by_Gov_Entity_Field.fieldApiName] : "",
        [Sell_to_Gov_Entities_Field.fieldApiName] : "",
        [Violation_of_Anti_Corruption_Laws_Field.fieldApiName] : "",
        [FCPAPP_Field.fieldApiName] : "",
        [Rubrik_Relationship_Field.fieldApiName] : "",
        [Violation_of_Anti_Corruption_Laws_Notes_Field.fieldApiName] : "",

    };
    spinnerLoad = false;
    picklistFieldNames =['Vendors_your_Org_works_with_today__c', 'Country__c', 'PartnerType__c', 'Referral_Source__c', 'Territory__c', 'Segment__c', 'Contact_Type__c'];
    picklistArrays;
    picklistDependentArrays;
    
    //Company Information
    coreBV = [];
    coreBVOld = null;
    optionsState=[];
    stateDisbaled = true;

    //Contact Information
    technicalPointAdmin;
    technicalPointSales;
    disableSalesPoint = false;
    disableTechnicalPoint = false;
    disableSalesPointCheck = true;
    disableTechPointCheck = true;

    //Business Information
    segmentValue ='Selected';
    isSegmentShown = false;
    @track allSegmentValues = [];
    segmentMultiValue = null;
    distributorValues = null;
    optionsDistributor = [];
    isDistributorDisabled = true;
    vendorValues=[];
    showSpinner = false;

    //Disclaimer
    showDisclamer21 = false;
    showDisclaimer31 = false;

    //Terms And Conditions
    resellerAgreement = false;
    mspAgreement = false;
    @track openMasterTermsModal = false;
    masterUrl;
    resellerUrl;
    mspUrl;
    masterAgreementCheck = false;
    resellerAgreementCheck = false;
    mspAgreementCheck = false;
    masterTermsAndConditionsAgreed = false;
    resellerAgreed = false;
    mspAgreed = false;
    baseUrl = basepath;

    saveMessage = null;
    isSubmit = false;
    distiRequired = true;

    connectedCallback(){
        Promise.all([
            loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
            ]).then(() => {
                console.log("File path-->"+ PartnerCommunityResource);
            })
            .catch(error => {
                console.log( error.body.message );
        });

        //get all picklist values in one go
        getPicklistValues({fieldAPINamesList : this.picklistFieldNames})
        .then(result=>{
            this.picklistArrays = result;
        })
        .catch(error=>{
            console.log('Error->'+JSON.stringify(error));
        });

        //get state country dependent values
        getDependentValues()
        .then(result=>{
            this.picklistDependentArrays = result;
        })
        .catch(error=>{
            console.log('Error->'+error);
        });
    }

    //to handle all values
    handleChangeEvent(event){
        this.partnerOnboardingRecord[event.target.name] = event.target.value;
        //PRIT26--410
        if ( event.target.type == 'email'){
            const value = event.target.value?.toLowerCase() || '';
            const domain = value.split('@')[1] || '';
            const blockedDomains = new Set(['gmail.com', 'yahoo.com', 'hotmail.com', 'googlemail.com', 'gmx.com', 'ymail.com', 'outlook.com']);
            event.target.setCustomValidity(
                blockedDomains.has(domain) ? 'Please provide a valid business email. We cannot accept applications using a personal email.' : ''
            );
            event.target.reportValidity();
            return;
        }
        let isValidppa = true;
        let inputFields = this.template.querySelectorAll('.ppaClass');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                isValidppa = false;
            }
        });
        if(isValidppa){
            this.disableSalesPointCheck = false;
        }else{
            this.disableSalesPointCheck = true;
        }
        let issalesValid = true;
        let salesFields = this.template.querySelectorAll('.spClass');
        salesFields.forEach( field =>{
            if(!field.checkValidity()){
                issalesValid = false;
            }
        });
        if(issalesValid){
            this.disableTechPointCheck = false;
        }else{
            this.disableTechPointCheck = true;
        }
    }
    //fetch state values based on country
    handleChangeCountry(event){
        this.partnerOnboardingRecord[event.target.name] = event.target.value;
        //control State Values
        let stateOptionsList = [];
        for(var key in this.picklistDependentArrays){
            if(key == event.target.value){
                let stateOptions = this.picklistDependentArrays[key];
                for(var val in stateOptions){
                    stateOptionsList.push( {label: val, value:stateOptions[val]} );
                }
            }
        }
        this.optionsState = stateOptionsList;
        if(stateOptionsList.length > 0){
            this.stateDisbaled = false;
        }else{
            this.stateDisbaled = true;
        }

        //control segment multiselect
        if(event.target.value == 'United States'){
            this.isSegmentShown = true;
            this.optionsDistributor = [];
            this.distributorValues = null;
            this.isDistributorDisabled = true;
            this.distiRequired = true;
        }else{
            this.isSegmentShown = false;
            getDistributorValue({sellingCountry : event.target.value})
            .then(result=>{
                console.log('result'+JSON.stringify(result));
                if(result.length > 0){
                    let distributorValue = [];
                    for(key in result){
                        distributorValue.push({ label: result[key].split(';')[0], value : result[key].split(';')[1]});
                    }
                    this.optionsDistributor = distributorValue;
                    this.isDistributorDisabled = false;
                    this.distiRequired = true;

                }else{
                    this.optionsDistributor = [];
                    this.distiRequired = false;
                    this.isDistributorDisabled = true;
                }
            })
            .catch(error=>{
                console.log('error->'+error);
            });
        }
    }
    //partner type selection
    handleCoreBusinessOptions(event){
        this.coreBV = event.detail.value;
        if(event.detail.value.length == 1){
            this.coreBVOld = event.detail.value[0];
        }else if(event.detail.value.length == 2){
            this.coreBV = this.coreBV.filter(item => item !== this.coreBVOld);
            this.coreBVOld = this.coreBV[0];
        }
        if(this.coreBV.includes('Reselling technology to customers')){
            this.partnerOnboardingRecord[this.fieldNames.resellingTechnology] = "true";
            this.resellerAgreement = true;
            this.partnerOnboardingRecord[this.fieldNames.partnerType] = "Reseller";
            this.mspAgreement = false;
            this.partnerOnboardingRecord[this.fieldNames.providingSoftware] = "false";
        }else if(this.coreBV.includes('Providing software as-a-service solution to customers')){
            this.partnerOnboardingRecord[this.fieldNames.providingSoftware] = "true";
            this.mspAgreement = true;
            this.partnerOnboardingRecord[this.fieldNames.partnerType] = "MSP-Reseller";
            this.resellerAgreement = true;
            this.partnerOnboardingRecord[this.fieldNames.resellingTechnology] = "false";
        }else{
            this.partnerOnboardingRecord[this.fieldNames.resellingTechnology] = "false";
            this.resellerAgreement = false;
            this.partnerOnboardingRecord[this.fieldNames.providingSoftware] = "false";
            this.mspAgreement = false;
            this.partnerOnboardingRecord[this.fieldNames.partnerType] = "";
        }
    }

    handleNextCompanyInformation(){
        
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.cmpInfo');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
        });
        console.log('000'+isValid);
        console.log('rec->'+JSON.stringify(this.partnerOnboardingRecord));
        if(isValid) {
            let companyInfoHeader = this.template.querySelector("[data-id=company-info-header]");
            let contactInfoheader = this.template.querySelector("[data-id=contact-info-header]");
            companyInfoHeader.classList.remove("section_header--active");
            companyInfoHeader.classList.add("section_header--complete");
            contactInfoheader.classList.add("section_header--active");
            this.template.querySelector(".section_header--active").scrollIntoView();
        }else {
            this.template.querySelector(".slds-has-error").focus();
        }
        return isValid;
    }

    //Partner Contact Details Change
    handleSalesPointAdminChange(event){
        if(event.target.checked == true){
            this.partnerOnboardingRecord[this.fieldNames.sameAsPartnerPortalAdmin] = "true";
            //setting Values
            this.partnerOnboardingRecord[this.fieldNames.salesFirstName] = this.partnerOnboardingRecord[this.fieldNames.firstName];
            this.partnerOnboardingRecord[this.fieldNames.salesLastName] = this.partnerOnboardingRecord[this.fieldNames.lastName];
            this.partnerOnboardingRecord[this.fieldNames.salesEmail] = this.partnerOnboardingRecord[this.fieldNames.email];
            this.partnerOnboardingRecord[this.fieldNames.salesPhone] = this.partnerOnboardingRecord[this.fieldNames.phoneNumber];
            this.partnerOnboardingRecord[this.fieldNames.salesTitle] = this.partnerOnboardingRecord[this.fieldNames.title];
            this.partnerOnboardingRecord[this.fieldNames.salesContactType] = this.partnerOnboardingRecord[this.fieldNames.contactType];
            this.disableSalesPoint = true;
        }else{
            this.disableSalesPoint = false;
            this.partnerOnboardingRecord[this.fieldNames.sameAsPartnerPortalAdmin] = "false";
            //resetting Values
            this.partnerOnboardingRecord[this.fieldNames.salesFirstName] = "";
            this.partnerOnboardingRecord[this.fieldNames.salesLastName] = "";
            this.partnerOnboardingRecord[this.fieldNames.salesEmail] = "";
            this.partnerOnboardingRecord[this.fieldNames.salesPhone] = "";
            this.partnerOnboardingRecord[this.fieldNames.salesTitle] = "";
            this.partnerOnboardingRecord[this.fieldNames.salesContactType] = "Sales";
        }
        Promise.resolve().then(() => {
            let issalesValid = true;
            let salesFields = this.template.querySelectorAll('.spClass');
            salesFields.forEach( field =>{
                if(!field.checkValidity()){
                    field.reportValidity();
                    issalesValid = false;
                }else{
                    field.reportValidity();
                }
            });
            if(issalesValid){
                this.disableTechPointCheck = false;
            }else{
                this.disableTechPointCheck = true;
            }
        });
    }

    handleTechnicalPointAdminChange(event){
        if(event.target.checked == true){
            this.disableTechnicalPoint = true;
            this.technicalPointSales = false;
            this.technicalPointAdmin = true;
            this.partnerOnboardingRecord[this.fieldNames.sameAsPartnerPortalAdminTech] = true;
            this.partnerOnboardingRecord[this.fieldNames.sameAsSalesPointOfContactTech] = false;

            this.partnerOnboardingRecord[this.fieldNames.techFirstName] = this.partnerOnboardingRecord[this.fieldNames.firstName];
            this.partnerOnboardingRecord[this.fieldNames.techLastName] = this.partnerOnboardingRecord[this.fieldNames.lastName];
            this.partnerOnboardingRecord[this.fieldNames.techEmail] = this.partnerOnboardingRecord[this.fieldNames.email];
            this.partnerOnboardingRecord[this.fieldNames.techPhone] = this.partnerOnboardingRecord[this.fieldNames.phoneNumber];
            this.partnerOnboardingRecord[this.fieldNames.techTitle] = this.partnerOnboardingRecord[this.fieldNames.title];
            this.partnerOnboardingRecord[this.fieldNames.techContactType] = this.partnerOnboardingRecord[this.fieldNames.contactType];
        }else{
            this.disableTechnicalPoint = false;
            this.technicalPointAdmin = false;
            this.partnerOnboardingRecord[this.fieldNames.sameAsPartnerPortalAdminTech] = "false";
            this.partnerOnboardingRecord[this.fieldNames.techFirstName] = "";
            this.partnerOnboardingRecord[this.fieldNames.techLastName] = "";
            this.partnerOnboardingRecord[this.fieldNames.techEmail] = "";
            this.partnerOnboardingRecord[this.fieldNames.techPhone] = "";
            this.partnerOnboardingRecord[this.fieldNames.techTitle] = "";
            this.partnerOnboardingRecord[this.fieldNames.techContactType] = "Technical";
        }
        Promise.resolve().then(() => {
            let issalesValid = true;
            let salesFields = this.template.querySelectorAll('.tpClass');
            salesFields.forEach( field =>{
                if(!field.checkValidity()){
                    field.reportValidity();
                    issalesValid = false;
                }else{
                    field.reportValidity();
                }
            });
        });
    }

    handleTechnicalPointSalesChange(event){
        if(event.target.checked == true){
            this.disableTechnicalPoint = true;
            this.technicalPointSales = true;
            this.technicalPointAdmin = false;
            this.partnerOnboardingRecord[this.fieldNames.sameAsPartnerPortalAdminTech] = "false";
            this.partnerOnboardingRecord[this.fieldNames.sameAsSalesPointOfContactTech] = true;
            this.partnerOnboardingRecord[this.fieldNames.techFirstName] = this.partnerOnboardingRecord[this.fieldNames.salesFirstName];
            this.partnerOnboardingRecord[this.fieldNames.techLastName] = this.partnerOnboardingRecord[this.fieldNames.salesLastName];
            this.partnerOnboardingRecord[this.fieldNames.techEmail] = this.partnerOnboardingRecord[this.fieldNames.salesEmail];
            this.partnerOnboardingRecord[this.fieldNames.techPhone] = this.partnerOnboardingRecord[this.fieldNames.salesPhone];
            this.partnerOnboardingRecord[this.fieldNames.techTitle] = this.partnerOnboardingRecord[this.fieldNames.salesTitle];
            this.partnerOnboardingRecord[this.fieldNames.techContactType] = this.partnerOnboardingRecord[this.fieldNames.salesContactType];
        }else{
            this.disableTechnicalPoint = false;
            this.technicalPointSales = false;
            this.partnerOnboardingRecord[this.fieldNames.sameAsSalesPointOfContactTech] = false;
            this.partnerOnboardingRecord[this.fieldNames.techFirstName] = "";
            this.partnerOnboardingRecord[this.fieldNames.techLastName] = "";
            this.partnerOnboardingRecord[this.fieldNames.techEmail] = "";
            this.partnerOnboardingRecord[this.fieldNames.techPhone] = "";
            this.partnerOnboardingRecord[this.fieldNames.techTitle] = "";
            this.partnerOnboardingRecord[this.fieldNames.techContactType] = "Technical";
        }
        Promise.resolve().then(() => {
            let issalesValid = true;
            let salesFields = this.template.querySelectorAll('.tpClass');
            salesFields.forEach( field =>{
                if(!field.checkValidity()){
                    field.reportValidity();
                    issalesValid = false;
                }else{
                    field.reportValidity();
                }
            });
        });
    }

    handleBackPartnerPortalAdmin() {
        let contactInfoheader = this.template.querySelector("[data-id=contact-info-header]");
        let companyInfoHeader = this.template.querySelector("[data-id=company-info-header]");
        contactInfoheader.classList.remove("section_header--active");
        companyInfoHeader.classList.add("section_header--active");
        this.template.querySelector(".section_header--active").scrollIntoView();
    }

    handleNextPartnerPortalAdmin(){
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.conDetails');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }else{
                inputField.reportValidity();
            }
        });
        if(isValid) {
            let contactInfoheader = this.template.querySelector("[data-id=contact-info-header]");
            let businessInfoHeader = this.template.querySelector("[data-id=business-info-header]")
            contactInfoheader.classList.remove("section_header--active");
            contactInfoheader.classList.add("section_header--complete");
            businessInfoHeader.classList.add("section_header--active");
            this.template.querySelector(".section_header--active").scrollIntoView();
        }else {
            this.template.querySelector(".slds-has-error").focus();
        }
        return isValid;

    }

    //Business Information Change
    handleChangeSegment(event){
        this.showSpinner = true;
        if(!this.allSegmentValues.includes(event.target.value)){
            this.allSegmentValues.push(event.target.value);
        }
        if(this.segmentMultiValue != null){
            this.segmentMultiValue = this.segmentMultiValue + ';' + event.target.value;
        }else{
            this.segmentMultiValue = event.target.value;
        }
        
        getDistributorUSValue({segment : this.segmentMultiValue})
        .then(result=>{
            if(result.length > 0){
                let distributorValue = [];
                for(let i = 0 ; i<result.length; i++){
                    distributorValue.push({label:result[i].split(';')[0], value:result[i].split(';')[1]});
                }
                this.optionsDistributor = distributorValue;
                this.isDistributorDisabled = false;
                this.distiRequired = true;
            }else{
                this.optionsDistributor = [];
                this.isDistributorDisabled = true;
                this.distiRequired = false;
            }
            this.showSpinner = false;
        })
        .catch(error=>{
            console.log('error->'+error);
            this.showSpinner = false;
        });
    }

    handleRemoveSegment(event){
        this.allSegmentValues.splice(this.allSegmentValues.indexOf(event.target.name), 1);
        let stringRemoved = event.target.name +';';
        if(this.segmentMultiValue.includes(stringRemoved)){
            this.segmentMultiValue = this.segmentMultiValue.replace(stringRemoved,'');
        }else if(this.segmentMultiValue.includes(event.target.name)){
            this.segmentMultiValue = this.segmentMultiValue.replace(event.target.name,'');
        }

        if(this.allSegmentValues.length == 0){
            this.optionsDistributor = [];
            this.isDistributorDisabled = true;
        }
    }

    handleVendorChange(event){
        this.vendorValues = event.detail.value;
    }

    handleBackBusinessInformation() {
        let businessInfoHeader = this.template.querySelector("[data-id=business-info-header]");
        let contactInfoheader = this.template.querySelector("[data-id=contact-info-header]");
        businessInfoHeader.classList.remove("section_header--active");
        contactInfoheader.classList.add("section_header--active");
        this.template.querySelector(".section_header--active").scrollIntoView();
    }

    handleNextBusinessInformation(){
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.seClass');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
        });
        if(this.allSegmentValues.length < 1 && this.isSegmentShown == true){
            alert("Please select a Segment");
            isValid = false;
        }
        if(isValid) {
            let businessInfoHeader = this.template.querySelector("[data-id=business-info-header]");
            let legalDiscHeader = this.template.querySelector("[data-id=legal-disclaimer-header]");
            businessInfoHeader.classList.remove("section_header--active");
            businessInfoHeader.classList.add("section_header--complete");
            legalDiscHeader.classList.add("section_header--active");
            this.template.querySelector(".section_header--active").scrollIntoView();
        }else {
            this.template.querySelector(".slds-has-error").focus();
        }
        return isValid;
    }

    //Disclamer Change
    handleDisclaimer2Change(event){
        this.partnerOnboardingRecord[this.fieldNames.sellToGovEntity] = event.target.value;
        if(event.target.value == 'Yes'){
            this.showDisclamer21 = true;
        }else{
            this.showDisclamer21 = false;
            this.partnerOnboardingRecord[this.fieldNames.fcpap] = "";
        }
    }

    handleDisclaimer3Change(event){
        this.partnerOnboardingRecord[this.fieldNames.violationOfAntiCorruption] = event.target.value;
        if(event.target.value == 'Yes'){
            this.showDisclaimer31 = true;
        }else{
            this.showDisclaimer31 = false;
            this.partnerOnboardingRecord[this.fieldNames.violationOfAnticorruptionLawNotes] = "";
        }
    }

    handleBackDisclaimer() {
        let legalDiscHeader = this.template.querySelector("[data-id=legal-disclaimer-header]");
        let businessInfoHeader = this.template.querySelector("[data-id=business-info-header]");
        legalDiscHeader.classList.remove("section_header--active");
        businessInfoHeader.classList.add("section_header--active");
        this.template.querySelector(".section_header--active").scrollIntoView();
    }

    handleNextDisclaimer(){
        console.log('-519->'+JSON.stringify(this.partnerOnboardingRecord));
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.disClass');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
        });
        console.log('-539->'+isValid);
        if(isValid) {
            let legalDiscHeader = this.template.querySelector("[data-id=legal-disclaimer-header]");
            let partnerShipHeader = this.template.querySelector("[data-id=partnership--header]");
            legalDiscHeader.classList.remove("section_header--active");
            legalDiscHeader.classList.add("section_header--complete");
            partnerShipHeader.classList.add("section_header--active");
            this.template.querySelector(".section_header--active").scrollIntoView();
        }else {
            this.template.querySelector(".slds-has-error").focus();
        }
        return isValid;
    }

    //Terms and Conditions
    openMasterModel(){
        if(this.partnerOnboardingRecord[this.fieldNames.partnerType] != "" && this.partnerOnboardingRecord[this.fieldNames.email] != ""){
            if(this.baseUrl.search('/s') >= 0){
                var temp = this.baseUrl.split('/s');
                this.baseUrl = temp[0];
            }
            console.log('555'+this.baseUrl);
            this.masterUrl = this.baseUrl + '/apex/Pactsafe?groupType=Master&partnerType=' + this.partnerOnboardingRecord[this.fieldNames.partnerType] +'&email=' + this.partnerOnboardingRecord[this.fieldNames.email];
            this.openMasterTermsModal = true;
            this.masterTermsAndConditionsAgreed = true;
            window.addEventListener("message", (event) => {
                if (event.data.name === "Master") {
                    // Handle the message
                    if(event.data.payload == 'agreed'){
                        this.masterAgreementCheck = true;
                    }else{
                        this.masterAgreementCheck = false;
                    }
                }
                this.openMasterTermsModal = false;
                this.masterTermsAndConditionsAgreed = false;
            });
        }else{
            alert("Please enter Core Business and Email");
        }
    }

    openResellerModel(){
        if(this.partnerOnboardingRecord[this.fieldNames.partnerType] != "" && this.partnerOnboardingRecord[this.fieldNames.email] != ""){
            if(this.baseUrl.search('/s') >= 0){
                var temp = this.baseUrl.split('/s');
                this.baseUrl = temp[0];
            }
            this.resellerUrl = this.baseUrl + '/apex/Pactsafe?groupType=Secondary&partnerType=' + this.partnerOnboardingRecord[this.fieldNames.partnerType] +'&email=' + this.partnerOnboardingRecord[this.fieldNames.email];
            this.openMasterTermsModal = true;
            this.resellerAgreed = true;
            console.log('-->'+this.resellerUrl);
            window.addEventListener("message", (event) => {
                if (event.data.name === "Secondary") {
                    // Handle the message
                    if(event.data.payload == 'agreed'){
                        this.resellerAgreementCheck = true;
                    }else{
                        this.resellerAgreementCheck = false;
                    }
                }
                this.openMasterTermsModal = false;
                this.resellerAgreed = false;
            });
        }else{
            alert("Please enter Core Business and Email");
        }
    }

    openMSPModel(){
        if(this.partnerOnboardingRecord[this.fieldNames.partnerType] != "" && this.partnerOnboardingRecord[this.fieldNames.email] != ""){
            if(this.baseUrl.search('/s') >= 0){
                var temp = this.baseUrl.split('/s');
                this.baseUrl = temp[0];
            }
            this.mspUrl = this.baseUrl + '/apex/Pactsafe?groupType=Tertiary&partnerType=' + this.partnerOnboardingRecord[this.fieldNames.partnerType] +'&email=' + this.partnerOnboardingRecord[this.fieldNames.email];
            this.openMasterTermsModal = true;
            this.mspAgreed = true;
            window.addEventListener("message", (event) => {
                if (event.data.name === "Tertiary") {
                    // Handle the message
                    if(event.data.payload == 'agreed'){
                        this.mspAgreementCheck = true;
                    }else{
                        this.mspAgreementCheck = false;
                    }
                }
                this.openMasterTermsModal = false;
                this.mspAgreed = false;
            });
        }else{
            alert("Please Select Core Business and Enter Email");
        }
    }

    hideModalBox(){
        this.openMasterTermsModal = false;
        this.masterTermsAndConditionsAgreed = false;
        this.resellerAgreed = false;
        this.mspAgreed = false;
    }

    handleBackPartnershipAgreement() {
        let legalDiscHeader = this.template.querySelector("[data-id=legal-disclaimer-header]");
        let partnershipHeader = this.template.querySelector("[data-id=partnership--header]");
        partnershipHeader.classList.remove("section_header--active");
        legalDiscHeader.classList.add("section_header--active");
        this.template.querySelector(".section_header--active").scrollIntoView();
    }

    handleSubmit(event){
        this.spinnerLoad = true;
        this.partnerOnboardingRecord[this.fieldNames.vendors] = this.vendorValues.toString().replaceAll(",",";");
        this.partnerOnboardingRecord[this.fieldNames.segment] = this.segmentMultiValue;
        console.log('-->'+JSON.stringify(this.partnerOnboardingRecord));
        if(this.masterAgreementCheck == true && ((this.resellerAgreement == true && this.resellerAgreementCheck === true) || (this.resellerAgreement == false)) && ((this.mspAgreement == true && this.mspAgreementCheck == true) || (this.mspAgreement == false))){
            savePartnerOnboard({PO_Request : this.partnerOnboardingRecord})
            .then(result=>{
                console.log('->'+result);
                if(result == 'success'){
                    this.isSubmit = true;
                    this.showToastEvent('Saved','The record was saved.','success');
                    this.saveMessage = 'Thank you for your request. We will reach out within 48 hours once your request is reviewed. For any questions please reach out to <a href="mailto:goforward@rubrik.com">goforward@rubrik.com</a>';
                }else if(result == 'Error while saving onboarding'){
                    this.ShowToastEvent('Error','Error occurred while submitting record','error');
                    this.saveMessage = 'Error occurred while submitting record. Please contact <a href="mailto:goforward@rubrik.com">goforward@rubrik.com</a> if you have questions.';
                }else if(result =='Account record already Exists'){
                    this.showToastEvent('Already a Partner','You are already registered as a Partner','info');
                    var currenturl = window.location.href;
                    var tempurl = currenturl.split('/s/');
                    var navurl =tempurl[0]+'/s/useraccess';
                    this.saveMessage = '<h3>You are already registered as a partner.To get Partner access, please click <a href="+navurl+">here</a> </h3>';
                }else if(result == 'Error while saving'){
                    this.ShowToastEvent('Error','Error occurred while submitting record','error');
                    this.saveMessage = 'Error occurred while submitting record. Please contact <a href="mailto:goforward@rubrik.com">goforward@rubrik.com</a> if you have questions.';
                }
                this.spinnerLoad = false;
            })
            .catch(error=>{
                this.spinnerLoad = false;
                console.log('--->'+JSON.stringify(error));
            });
        }
        else{
            this.spinnerLoad = false;
            alert("Please agree to the terms and Conditions");
            return;
        }
    }

    get optionsCountry(){
        let countryOptions = [];
        for(var key in this.picklistArrays){
            if(key == 'Country__c'){
                for (let i =0; i<this.picklistArrays[key].length; i++){
                    countryOptions.push( {label : this.picklistArrays[key][i].split(';')[0], value : this.picklistArrays[key][i].split(';')[1]});
                }
            }
        }
        return countryOptions;
    }

    get optionsContactType(){
        let contactTypeOptions = [];
        for(var key in this.picklistArrays){
            if(key == 'Contact_Type__c'){
                for (let i =0; i<this.picklistArrays[key].length; i++){
                    contactTypeOptions.push( {label : this.picklistArrays[key][i].split(';')[0], value : this.picklistArrays[key][i].split(';')[1]});
                }
            }
        }
        return contactTypeOptions;
    }

    get coreBusinessOptions() {
        return [
            { label: 'Reselling technology to customers', value: 'Reselling technology to customers' },
            { label: 'Providing software as-a-service solution to customers', value: 'Providing software as-a-service solution to customers' }
        ];
    }

    get optionsSegment(){
        let segmentOptions = [];
        for(var key in this.picklistArrays){
            if(key == 'Segment__c'){
                for (let i =0; i<this.picklistArrays[key].length; i++){
                    segmentOptions.push( {label : this.picklistArrays[key][i].split(';')[0], value : this.picklistArrays[key][i].split(';')[1]});
                }
            }
        }
        return segmentOptions;
    }

    get vendorOptions(){
        let vendorOptions = [];
        for(var key in this.picklistArrays){
            if(key == 'Vendors_your_Org_works_with_today__c'){
                for (let i =0; i<this.picklistArrays[key].length; i++){
                    vendorOptions.push( {label : this.picklistArrays[key][i].split(';')[0], value : this.picklistArrays[key][i].split(';')[1]});
                }
            }
        }
        return vendorOptions;
    }

    get referralSourceOptions(){
        let referralSourceOptions = [];
        for(var key in this.picklistArrays){
            if(key == 'Referral_Source__c'){
                for (let i =0; i<this.picklistArrays[key].length; i++){
                    referralSourceOptions.push( {label : this.picklistArrays[key][i].split(';')[0], value : this.picklistArrays[key][i].split(';')[1]});
                }
            }
        }
        return referralSourceOptions;
    }

    get checkboxOptions(){
        return [
            { label: "Yes", value: "Yes" },
            { label: "No", value: "No" }
        ];
    }

    showToastEvent(title, message, variant){
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    handleRedirect() {
        location.href = "https://www.rubrik.com/"
    }
}