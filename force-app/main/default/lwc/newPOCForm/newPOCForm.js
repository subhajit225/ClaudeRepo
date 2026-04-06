import { LightningElement, track, api, wire } from 'lwc';
import retrunDefaultValuetoFrom from '@salesforce/apex/PocFormControllerCls.retrunDefaultValuetoFrom';  
import getStatebyCountry from '@salesforce/apex/PocFormControllerCls.getStatebyCountry'; 
import submitPOCRequest from '@salesforce/apex/PocFormControllerCls.submitPOCRequest'; 
import validateDate from '@salesforce/apex/PocFormControllerCls.validateInstallationDate'; 
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import fetchUserSessionId from '@salesforce/apex/LexSessionController.fetchUserSessionId'; 
import POC_Request_Content_REST from '@salesforce/label/c.POC_Request_Content_REST';
import getPicklistValues from '@salesforce/apex/PocFormControllerCls.getPicklistValues';
import getExistingRscInstance from '@salesforce/apex/PocFormControllerCls.getRscInstance';


const FILE_SIZE_LIMIT = 20971520;
const CONTENT_VERSION_REST_URL = POC_Request_Content_REST;
export default class NewPOCForm extends NavigationMixin(LightningElement)  {


    @api componentMode = 'quickaction';

    _recordId;
    @api callfromVfPage=false;
    @track pocRecord;
    @track oppRecord;
    @track rscAccountType;
    @track rscExistingRscUrl;
    @track isExistingUrlRequired = false;
    @track isExistingUrlDisabled = true;
    @track isSuggestedUrlDisabled = true;
    @track showRscInstanceFields = false;
    @track isExistingCustomer = false;
    @track urlToRscInstanceMap;
    @track selectedRscInstance;
    @track selectedRscUrl;
    @track suggestedUrl;
    @track selectedRscAccountType;
    @track mappedRscAccountType;
    @track hideSpinner = false;
    @track isRecordReturn=false;
    @track objectWrapper=[];
    @track fileUploadList=[];
    @track PartnerDistributorSignedPOCAddendum='';
    @track setOnlineAgreementSigned='';
    @track setAgreementWaivedOff='';
    @track showAgreementFileUpload=false;
    @track returnObjectName='';
    @track hidepocrelocation=false;
    @track hidesctionforwebvirtual=false;
    @track showTestPlan = true;
    @track showIncidentManager = false;
    @track showPOcAssetrelocation=false;
    @track stateoptions=[];
    @track isRecordReturnState=false;
    @track renderDistubutorName=true;
    @track renderpartnerName=true;
    @track shipCountry='';
    @track shipStreet='';
    @track shipState='';
    @track shipCity='';
    @track shipPostalCode='';
    @track fileUploadValidation=true;
    @track fileUploadValidationManual=false;
    @track hideOpportunitySection=false;
    @track hidesctionfortrybuy=false;
    @track showtrybuyfieluploadsection=false;
    @track showVirtualTab=false;
    @track pocQty='';
    @track pocType='';
    @track planDate='';
    @track showPOCJustification = true;
    @track isvalidPlanDateStatus=false;
    @track isPOCApproverPresent=false;
    @track isConditionalPOC=false;
    @track isConditionalPOCAllowUser=false;
    @track isStandradPocRscGAllowUser =false;
    @track uclEdition='';
    _sessionId ;
    showToastMethodInst = this.showToast.bind(this);
    persistBanner = false;
    @track COMMON_TWO_LEVEL_TLDS = [
        "co.uk", "org.uk", "gov.uk", "ac.uk",
        "com.au", "net.au", "org.au",
        "co.nz",
        "com.br",
        "com.mx",
        "co.jp",
        "co.in",
        "com.sg"
    ];
    @track isExistingDomainMatch = false;
    selectedStateValue;
    @track dataReduncyArchive;
	@track storageRegionRCVArchGov;
    @track storageRegionRCVBackupGov;
    fileData
    openfileUpload(event) {
        this.handleFileValidity();
        const file = event.target.files[0]
        var reader = new FileReader()
        reader.onload = () => {
            var base64 = reader.result.split(',')[1]
            this.fileData = {
                'filename': file.name,
                'base64': base64
            }
            console.log(this.fileData)
           // this.fileUploadList.push(this.fileData);
           // console.log('FILE LIST '+JSON.stringify(this.fileUploadList));
        }
        reader.readAsDataURL(file)
    }

    fileDataAgreement
    openfileUploadAgreement(event) {
        this.handleFileValidity();
        const file = event.target.files[0]
        var reader = new FileReader()
        reader.onload = () => {
            var base64 = reader.result.split(',')[1]
            this.fileDataAgreement = {
                'filename': file.name,
                'base64': base64
            }
            //console.log(this.fileDataAgreement)
           // this.fileUploadList.push(this.fileDataAgreement);
           // console.log('FILE LIST '+JSON.stringify(this.fileUploadList));
        }
        reader.readAsDataURL(file)
    }
    fileDataAgreementTryBuy
    openfileUploadAgreementTryBuy(event) {
        this.handleFileValidity();
        const file = event.target.files[0]
        var reader = new FileReader()
        reader.onload = () => {
            var base64 = reader.result.split(',')[1]
            this.fileDataAgreementTryBuy = {
                'filename': file.name,
                'base64': base64
            }
            //console.log(this.fileDataAgreement)
           // this.fileUploadList.push(this.fileDataAgreementTryBuy);
           // console.log('FILE LIST '+JSON.stringify(this.fileUploadList));
        }
        reader.readAsDataURL(file)
    }
    @wire(getPicklistValues, { objectName: 'RscInstance__c', fieldName: 'RSCAccountType__c' })
        wiredPicklist({ data, error }) {
            if (data) {
                const allowed = ['Production', 'POC']; 
                this.rscAccountType = data
                    .filter(val => allowed.includes(val))   // allow only these two
                    .map(val => ({ label: val, value: val }));
            } else if (error) {
                console.error(error);
            }
    }
    handleAccTypeChange(event){
        this.selectedRscAccountType = event.detail.value;
        this.isExistingUrlRequired = false;
        const ACCOUNT_TYPE_MAPPING = {'Production': 'Revenue','POC': 'POC'};
        this.mappedRscAccountType = ACCOUNT_TYPE_MAPPING[event.detail.value] || event.detail.value;
        this.selectedRscUrl = null;
        this.rscExistingRscUrl = [];
        this.suggestedUrl = null;
        this.clearSuggestUrlFieldValidation();
        getExistingRscInstance({ accountId: this.oppRecord.AccountId}) 
                .then(result => {
                    if(result !=undefined){
                       this.processExistingRscInstance(result);
                    }
                    else{
                       this.isExistingUrlDisabled = true;
                    }
                }) 
                .catch(error => {
                    console.error('accChange'+error);
                    this.isExistingUrlDisabled = true;
                })
    }
    processExistingRscInstance(result) {
        // Build map
        this.urlToRscInstanceMap = new Map();
        this.existingProdUrl = '';
        if (result && Array.isArray(result)) {
            result.forEach(rec => {
                if (rec.RSCUrl__c && rec.RSCAccountType__c == this.mappedRscAccountType) {
                    this.urlToRscInstanceMap.set(rec.RSCUrl__c, rec);
                }
                if (rec.RSCUrl__c && rec.RSCAccountType__c == 'Revenue'){
                    this.existingProdUrl = rec.RSCUrl__c;
                }
            });
        }
        // Build combobox options
        this.rscExistingRscUrl = Array.from(this.urlToRscInstanceMap.keys()).map(url => ({
            label: url,
            value: url
        }));
        const hasNoUrls = this.rscExistingRscUrl.length === 0;

        // Set flags
        this.isExistingUrlDisabled = hasNoUrls;
        this.isExistingUrlRequired = !hasNoUrls;

        this.isSuggestedUrlDisabled = !(
            this.selectedRscAccountType === 'POC' && hasNoUrls
        );

        if(!this.isSuggestedUrlDisabled){
            this.handleDomainUpdate();
    }

    }
    handleDomainUpdate(){
        if(this.suggestedUrl == null || this.suggestedUrl == ''){
            const parsed = this.parseDomain(this.oppRecord.Account.Website);
            if (!parsed || !parsed.domain) {
                this.suggestedUrl = '';
                return;
            }
            let dominaName;
            if (parsed.subdomain) {
                dominaName = `${parsed.subdomain}-${parsed.domain}`;
            } else {
                dominaName = parsed.domain;
            }
            dominaName = dominaName.replace(/\./g, '-');
            dominaName = dominaName.replace(/_/g, '-');
            this.suggestedUrl = dominaName;
        }
        if(this.existingProdUrl != null && this.existingProdUrl != ''){
            this.existingProdUrl = this.normalizeRubrikUrl(this.existingProdUrl);
            const existingDomain = this.parseDomain(this.existingProdUrl);
            let parsedExistDomain;

            if (existingDomain.subdomain) {
                parsedExistDomain = `${existingDomain.subdomain}-${existingDomain.domain}`;
            } else {
                parsedExistDomain = existingDomain.domain;
            }
            parsedExistDomain = parsedExistDomain.replace(/\./g, '-');
            parsedExistDomain = parsedExistDomain.replace(/_/g, '-');
            if(this.suggestedUrl === parsedExistDomain){
                this.isExistingDomainMatch = true;
            }else {
                this.isExistingDomainMatch = false;
        }
      } 
    }
    normalizeRubrikUrl(input) {
        if (!input) return input;

        return input
            // Remove www. only if it appears after protocol
            .replace(/(https?:\/\/)www\./i, '$1')

            .replace(/(http?:\/\/)www\./i, '$1')

            .replace(
                /(https?:\/\/)?([^\/]*?)(?:-sandbox|\.sandbox)[^\/]*/i,
                (match, protocol, prefix) => {
                    return (protocol || '') + prefix;
                }
            )
            .replace(
                /(http?:\/\/)?([^\/]*?)(?:-sandbox|\.sandbox)[^\/]*/i,
                (match, protocol, prefix) => {
                    return (protocol || '') + prefix;
                }
            )
            .replace(
                /(https?:\/\/)?([^\/]*?)(?:-dev-065|\.dev-065)[^\/]*/i,
                (match, protocol, prefix) => {
                    return (protocol || '') + prefix;
                }
            )
            .replace(
                /(http?:\/\/)?([^\/]*?)(?:-dev-065|\.dev-065)[^\/]*/i,
                (match, protocol, prefix) => {
                    return (protocol || '') + prefix;
                }
            )
            // Replace .my.rubrik-lab.com with .com
            .replace(/\.my\.rubrik-lab\.com\b/i, '.com')

            // Replace .my.rubrik.com with .com
            .replace(/\.my\.rubrik\.com\b/i, '.com');
    }
    handleSelectedExistingUrl(event){
        // Get the selected URL from combobox
        this.selectedRscUrl = event.detail.value;
        // Retrieve the matching RSCInstance record from the map
        if (this.urlToRscInstanceMap && this.urlToRscInstanceMap.has(this.selectedRscUrl)) {
            this.selectedRscInstance = this.urlToRscInstanceMap.get(this.selectedRscUrl);
        } else {
            this.selectedRscInstance = null;
        }
    }
    handleSuggestedUrlChange(event){
        this.suggestedUrl = event.detail.value;
        this.clearSuggestUrlFieldValidation();
        this.handleDomainUpdate();
    }
    clearSuggestUrlFieldValidation(){
        const suggestedUrlInputComp = this.template.querySelector('[data-id="suggestedUrl"]');
        suggestedUrlInputComp.setCustomValidity('');
        suggestedUrlInputComp.reportValidity();
    }
    validatePocRscInstance(inputValue) {
        const regex = /^[a-zA-Z0-9-]+$/;
        return regex.test(inputValue);
    }
    handleFileValidity() {
        var allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputCmp) => {
                        if( inputCmp.type === 'file' && inputCmp.files ) {
                            let totalSize = 0;
                            [...inputCmp.files].forEach( file => (totalSize += file.size));
                            if( totalSize > FILE_SIZE_LIMIT ) {
                                inputCmp.setCustomValidity('Selected File exceeds limit of 20 MB');
                            } else {
                                inputCmp.setCustomValidity('');
                            }
                        }
                        inputCmp.reportValidity();
                        return validSoFar && inputCmp.checkValidity();
            }, true);
            return allValid;
    }

    get addendumOption() {
        return [
            { label: 'Partner/Disty Signed POC Addendum', value: 'POCAddendum' }
            
        ];
    }

    get agreementOption() {
        return [
            { label: 'Online Agreement Signed', value: 'OnlineAgreement' }
            
        ];
    }

    get agreementWaivedOffOption() {
        return [
            { label: 'Agreement Waived (Existing Customer)', value: 'AgreementWaivedOff' }
            
        ];
    }

    get ManualPOCAgreementOption() {
        return [
            { label: 'Manual POC Agreement', value: 'ManualPOCAgreement' }
            
        ];
    }
    get TryBuyAgreementOption() {
        return [
            { label: 'Try and Buy Agreement', value: 'TryBuyAgreement' }
            
        ];
    }
    get copyAddressfromAccount() {
        return [
            { label: 'Copy Address from Account', value: 'AddressFromAccount' }
            
        ];
    }

    get VirtualFields() {
        return this.pocType === 'Virtual Lab';
    }

    get rscGContactName() { //added for MKT26-99
        if( this.oppRecord.Rubrik_Security_Cloud_Gov_t_Owner__c !== undefined ) {
            return this.oppRecord.Rubrik_Security_Cloud_Gov_t_Owner__r.Name;
        }
        return '';
    }

    copyAddressFromAccountfunction(event){
        
        this.value = event.detail.value;
        if(this.value=='AddressFromAccount'){
            //console.log('INSIDE COUNTRY'+this.oppRecord.Account.ShippingCountry);
            if(this.oppRecord.Account.BillingCountry !=undefined) {
                console.log('INSIDE COUNTRY'+this.oppRecord.Account.BillingCountry);
                this.shipCountry=this.oppRecord.Account.BillingCountry;
                
            }
            if(this.oppRecord.Account.BillingStreet !=undefined) {
                this.shipStreet=this.oppRecord.Account.BillingStreet;
            }
            if(this.oppRecord.Account.BillingCity !=undefined) {
                this.shipCity=this.oppRecord.Account.BillingCity;
            }
            if(this.oppRecord.Account.BillingStateCode !=undefined) {
                this.shipPostalCode=this.oppRecord.Account.BillingPostalCode;
            }
            if(this.oppRecord.Account.BillingStateCode !=undefined) {
                this.displayStatebyCountryonLoad(this.oppRecord.Account.BillingCountry,this.oppRecord.Account.BillingStateCode);
            }
            this.hideSpinner = true;
           
            
        } else {
            this.shipCountry='';
            this.shipStreet='';
            this.shipCity='';
            this.shipPostalCode='';
            this.selectedStateValue='';
            this.hideSpinner = true;

        }


    }

    displayStatebyCountry (event){
        this.value = event.detail.value;
        this.hideSpinner=false;
        this.shipCountry=this.value;
       
        getStatebyCountry({ Countryname: this.value }) 
                .then(result => {
        
                  //  console.log('STATE'+JSON.stringify(result));
                    if(result !=undefined){
                   // String[] statesList = result;

                    let options = [];
                    result.forEach(function (item, index) {
                        //console.log(item, index);
                        options.push({ label: item.split(';')[0], value: item.split(';')[1] });
                      });

                   

                      
                        this.stateoptions = options;
                        if(options.length>1)
                        this.isRecordReturnState=true;
                        this.hideSpinner=true;
                       
                    }
                    
                }) 
                .catch(error => {
                    this.error = error;
                   
                })
}


displayStatebyCountryonLoad (Countryname,SelectedState){
    
   
    getStatebyCountry({ Countryname: Countryname }) 
            .then(result => {
    
               // console.log('STATE'+JSON.stringify(result));
                if(result !=undefined){
               // String[] statesList = result;

                let options = [];
                result.forEach(function (item, index) {
                    console.log(item, index);
                    options.push({ label: item.split(';')[0], value: item.split(';')[1] });
                  });
                  
                  /*  for (String  s: statesList)  {
                        options.push({ label: key.split(';')[0], value: key.split(';')[0] });
                    } */

                  
                    this.stateoptions = options;
                    this.isRecordReturnState=true;
                    this.hideSpinner=true;
                   this.selectedStateValue=SelectedState;
                }
                
            }) 
            .catch(error => {
                this.error = error;
               
            })
}

handleStateChange(event){
    this.value = event.detail.value;
    this.selectedStateValue=this.value;
}

handleCityChange(event) {
    this.value = event.detail.value;
    this.shipCity=this.value;
}
handleStreetChange(event) {
    this.value = event.detail.value;
    this.shipStreet=this.value;
}

handlePostalCodeChange(event) {
    this.value = event.detail.value;
    this.shipPostalCode=this.value;
}




 addDays(date, days) {
    var result = new Date(date);
    let day = result.getDate()+days;
    let month = result.getMonth();
    let year = result.getFullYear();
    
    let fullDate = `${year}-${month}-${day}.`;
    return fullDate;
  }

  get displayProductPicker() {
      console.log('=====', this.pocType);
      return this.pocType !== 'Virtual Lab' && this.pocType !== 'Web Try and Buy';
  }

  get isWebTryAndBuy() {
      return this.pocType === 'Web Try and Buy';
  }

  get displayPOCJustification() {
        return !this.isWebTryAndBuy;
    }
    handleChangePOCType(event){
        this.value = event.detail.value;
        this.pocType= this.value;
        this.template.querySelector(".planInstDate lightning-input-field:first-child").value='';
        this.template.querySelector(".expectedDate lightning-input-field:first-child").value='';
        this.disabledexpectedendDate=false;
        this.showRscInstanceFields = this.value != 'Standard POC : RSC-G';
        if(this.value =='Conditional PO'){
            this.hidesctionfortrybuy=true;
            
           // this.hidepocrelocation=true;
            this.hidesctionforwebvirtual=false;

            if(!this.isConditionalPOCAllowUser) {

            this.showVirtualTab=true;
            this.hidesctionforwebvirtual=true;
            this.hidesctionfortrybuy=false;
            this.hidepocrelocation = true;
            this.isConditionalPOC=true;
            this.showIncidentManager=false;
            this.showToast('Conditional PO Discontinuance: By exception basis only, require Brian McCarthy and Melinda Wu’s approval for Conditional POs offline. Contact pochelp@rubrik.com for submission.', 'error','Error');

            }
            
           
            
        } else if (this.value =='Web Try and Buy') {
            this.showVirtualTab=false;
            this.hidesctionforwebvirtual=true;
            this.hidesctionfortrybuy=false;
            this.hidepocrelocation = true;
            this.showPOCJustification = false;
            this.isConditionalPOC=false;
            this.showIncidentManager=false;
        }
        else if (this.value =='Virtual Lab' ) {
            // this.pocQty=1;
            this.showVirtualTab=false;
            this.hidesctionforwebvirtual=true;
            this.hidesctionfortrybuy=false;
            this.hidepocrelocation = true;
            this.isConditionalPOC=false;
            this.showIncidentManager=false;
        } 
        else if(this.value == 'Partner Software Access'){
            this.pocQty=1;
            this.showVirtualTab=false;
            this.hidesctionforwebvirtual=false;
            this.hidesctionfortrybuy=false;
            this.hidepocrelocation = true;
            this.showSectionForPAC = true;
            this.isConditionalPOC=false;
            this.showIncidentManager=false;
            this.showTestPlan=true;
        }
        else if(this.value == 'Ransomware Recovery Software'){
            this.showVirtualTab=false;
            this.hidesctionforwebvirtual=false;
            this.hidesctionfortrybuy=false;
            this.hidepocrelocation = true;
            this.isConditionalPOC=false;
            this.showTestPlan=false;
            this.showIncidentManager=true;
        }else if(this.value == 'Standard POC : RSC-G'){
            if(this.isStandradPocRscGAllowUser){
                this.showVirtualTab=false;
                this.hidepocrelocation=false;
                this.hidesctionforwebvirtual=false;
                this.showTestPlan=true;
                this.isConditionalPOC=true;
                this.showIncidentManager=false;
                this.showToast(this.rscGMessage,'error','Error');

            }
        }
        else{
            this.showVirtualTab=false;	
            this.hidepocrelocation=false;	
            this.hidesctionforwebvirtual=false;	
            this.hidesctionfortrybuy=false;	
            this.fileUploadValidationTryBuy=false;	
            this.showPOCJustification = true;
            this.isConditionalPOC=false;
            this.showIncidentManager=false;
            this.showTestPlan=true;
        }      
    }
    handleChangePOCRelocation(event) {
        this.value = event.detail.value;
        if(this.value =='Yes')
        this.showPOcAssetrelocation=true;
        else
        this.showPOcAssetrelocation=false;
    }

    handleChangePOCAgreement(event){
        this.value = event.detail.value;
        if(this.value =='ManualPOCAgreement'){
            this.showAgreementFileUpload=true;
        } else {
            this.showAgreementFileUpload=false;
        }
    }

    handleChangeTrybuyCheckbox(event){
        this.value = event.detail.value;
        if(this.value =='TryBuyAgreement'){
            this.showtrybuyfieluploadsection=true;
        } else {
            this.showtrybuyfieluploadsection=false;
        }
    }
    @track rscGMessage = '';
    loadData() {
        var params = new URLSearchParams(window.location.search);
        console.log('RECORD ID>> WITH OPPORTUNITY'+this.recordId);
      
		retrunDefaultValuetoFrom({ recordId: this.recordId })
		.then(result => {

           console.log('result>>'+JSON.stringify(result)); 
            if(result !=undefined){
            var rec= [];
            console.log('result.opportunityObj>>>'+JSON.stringify(result.opportunityObj));
            this.objectWrapper=result;
            this.pocRecord = result.pocRequestObj;
			this.oppRecord = result.opportunityObj;
            if(result.opportunityObj.Partner_Lookup__c !=undefined){
                this.renderpartnerName=false;
            }
            if(!this.oppRecord.Account.RSC_G_Eligible__c){
                this.isStandradPocRscGAllowUser = true;
                this.rscGMessage = 'This account does not currently have RSC-G eligibility, and as a result, the creation of a POC is not possible. To enable RSC-G on this account, please submit a request to RSCGeligibility@rubrik.com.';
            }else if(this.oppRecord.Account.RSC_G_Eligible__c && this.oppRecord.Rubrik_Security_Cloud_Gov_t_Owner__c == null){
                this.isStandradPocRscGAllowUser = true;
                this.rscGMessage = 'To create the RSC-G , please go back to the Opportunity and fill in the Rubrik Security Cloud - Gov’t Owner'
            }
               
            if(result.opportunityObj.Opportunity_Type__c === 'Existing Customer'){
                this.isExistingCustomer = true;
            }
            if(result.opportunityObj.Distributor_Lookup__c !=undefined){
                this.renderDistubutorName=false;
            }
								
					  this.isPOCApproverPresent=result.isPOCApproverPresent;
                      this.isConditionalPOCAllowUser=result.isconditionalpocallowed;
                   

            if(result.isValidation) { //Redundant since handled through Aura Component
                this.showToast(result.errorMessage, 'error','Error');
                this.closeComponent();
                //this.dispatchEvent(new CloseActionScreenEvent());
                //this.cancelPOC();
             } else {

                this.selectedStateValue =this.pocRecord.Shipping_State__c;
                this.shipCountry = this.pocRecord.Ship_To_Country__c;
                this.shipStreet = this.pocRecord.Shipping_Street__c;
                this.shipCity = this.pocRecord.Shipping_City__c;
                this.shipPostalCode =this.pocRecord.Shipping_Zip_Postal_Code__c;

                  console.log('sdfdsfdsfds '+result.PartnerDistributorSignedPOCAddendum);
                if(result.PartnerDistributorSignedPOCAddendum){
                    this.PartnerDistributorSignedPOCAddendum='POCAddendum';       
                }
                if(result.setOnlineAgreementSigned){
                    this.setOnlineAgreementSigned='OnlineAgreement';
                }
                if(result.setAgreementWaivedOff){
                    this.setAgreementWaivedOff='AgreementWaivedOff';
                }
                this.returnObjectName=result.returnObjectName;
                if(result.pocRequestObj.POC_Type__c!=undefined){
                        if(result.pocRequestObj.POC_Type__c=='Conditional PO') {
                            this.hidepocrelocation=true;
                        }
                        if (result.pocRequestObj.POC_Type__c =='Web Try and Buy' || result.pocRequestObj.POC_Type__c =='Virtual Lab' ) {
                            this.hidesctionforwebvirtual=true;
                        }
                }
            
             
            if(this.returnObjectName == 'POC__c'){
                 if(result.pocRequestObj.Ship_To_Country__c !=''){
                this.displayStatebyCountryonLoad(result.pocRequestObj.Ship_To_Country__c,result.pocRequestObj.Shipping_State__c);
              }
              this.fileUploadValidation=false;
              this.fileUploadValidationManual=false;
              if(result.pocRequestObj.POC_Relocation__c=='Yes') {
               this.showPOcAssetrelocation=true;
              }
              
            }
            
                  
    
                this.error = undefined;
                this.hideSpinner= true;
                this.isRecordReturn=true;
                this.hideOpportunitySection=false;

             }
           
           
            //console.log('LOAD DATA '+JSON.stringify(this.objectWrapper));

            }
            
		}) 
		.catch(error => {
			this.error = error;
			//this.allReturnRecords = undefined;
            this.showToast(error.message, 'error','Error');
            //this.cancelPOC();
            this.closeComponent();
           //this.dispatchEvent(new CloseActionScreenEvent());
		})
    }


    loadDatawithoutOpportunity() {
        var params = new URLSearchParams(window.location.search);
        console.log('RECORD ID>> dssadsad---'+this.recordId);
        if(this.recordId ==undefined){
            this.hideOpportunitySection=true;
            //this.isRecordReturn=true;
            this.recordId ='';
        }
		retrunDefaultValuetoFrom({ recordId: this.recordId })
		.then(result => {

           console.log('result>>'+JSON.stringify(result)); 
            if(result !=undefined){
            var rec= [];
            console.log('result.opportunityObj>>>'+JSON.stringify(result.opportunityObj));
            this.objectWrapper=result;
            this.pocRecord = result.pocRequestObj;
			this.oppRecord = result.opportunityObj;
            if(result.isValidation) {
                this.showToast(result.errorMessage, 'error','Error');
                //this.dispatchEvent(new CloseActionScreenEvent());
                this.closeComponent();
             } else {

                this.error = undefined;
                this.hideSpinner= true;
                this.isRecordReturn=true;

             }
           
           
            //console.log('LOAD DATA '+JSON.stringify(this.objectWrapper));

            }
            
		}) 
		.catch(error => {
			this.error = error;
			//this.allReturnRecords = undefined;
            this.showToast(error.message, 'error','Error in Page');
            this.closeComponent();
           //this.dispatchEvent(new CloseActionScreenEvent());
           //this.cancelPOC();
		})
    }

    @api set recordId(value) {
        this._recordId = value;
        console.log('sdsdsads'); 

        if(value)
            this.loadData();

    }

    get recordId() {
        console.log('GET RECORD ID'+this._recordId);
        return this._recordId;
    }

    connectedCallback(){
        console.log('TEST ABC');
        console.log('this> ffff '+this._recordId);
      if(this._recordId ==undefined){
        this.loadDatawithoutOpportunity();
      } 
        
      fetchUserSessionId().then( result => {
        console.log('result', result);
        this._sessionId = result;
      });
    }
    handleSubmit(event){
        
        event.preventDefault();       // stop the form from submitting
        //this.hideSpinner= false;
        /*let allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputCmp) => {
                        if( inputCmp.type === 'file' && inputCmp.files ) {
                            let totalSize = 0;
                            [...inputCmp.files].forEach( file => (totalSize += file.size));
                            if( totalSize > FILE_SIZE_LIMIT ) {
                                inputCmp.setCustomValidity('Selected File exceeds limit of 20 MB');
                            } else {
                                inputCmp.setCustomValidity('');
                            }
                        }
                        inputCmp.reportValidity();
                        return validSoFar && inputCmp.checkValidity();
            }, true);*/
	    let allValid = this.handleFileValidity(); 
	    let allValidcheckBox = [...this.template.querySelectorAll('lightning-checkbox-group')]
            .reduce((validSoFar, inputCmp) => {
                        inputCmp.reportValidity();
                        return validSoFar && inputCmp.checkValidity();
            }, true);
		
        if(!allValidcheckBox) {
		    this.showToast('Please update the invalid form entries and try again.', 'error','Error');
          	return;
	     }

        if (this.isExistingDomainMatch){
            const suggestedUrlInputCompt = this.template.querySelector('[data-id="suggestedUrl"]');
            suggestedUrlInputCompt.setCustomValidity('Domain has been already used, Kindly change domain for creating new POC instance.');
            suggestedUrlInputCompt.reportValidity();
          	return;
	     }

        let validHostEnv = true;
        let validUCL = true;
        let validNCD = true;
        let validRubrikAlliance = true;
        let validAtlJiraCloud = true;
        let isValidUcl = true;
        let isValidRCVDetails = true;
        let isValidcloudType = true;
        if( this.template.querySelector('c-poc-product-picker') ) {
            let validPicker = this.template.querySelector('c-poc-product-picker').validate();
            validHostEnv = this.template.querySelector('c-poc-product-picker').validateHostEnv();
            validUCL = this.template.querySelector('c-poc-product-picker').validateNumberOfUCL();
            isValidUcl = this.template.querySelector('c-poc-product-picker').checkValidationForCombobox();
            validAtlJiraCloud = this.template.querySelector('c-poc-product-picker').atlassianValidation();
            isValidcloudType = this.template.querySelector('c-poc-product-picker').validateCloudType();
            allValid = allValid && validPicker;
        } 
        if(!isValidcloudType){
            this.showToast('Please update the invalid form entries and try again.', 'error','Error');
            return;
        }
        if(!validAtlJiraCloud){
            this.showToast('Atlassian Jira requires a minimum of 200 user licenses to quote', 'error','Error');
                return;
        }
        if(!validUCL){
            this.showToast('Number of UCL FETB should be between 1 to 5', 'error','Error');
                return;
        }
        if(!validNCD){
        this.showToast('Number of NCD FETB should be between 1 to 10', 'error','Error');
            return;
        }
        if(!validHostEnv){
           this.showToast('Please change the M365 Hosting environment to Rubrik Hosted Enterprise Edition', 'error','Error');
            return;
        }
        
        if (!allValid) {
            this.showToast('Please update the invalid form entries and try again.', 'error','Error');
            return;
        }
        
		if( this.isPOCApproverPresent) {
            this.showToast('You’re missing a POC Approver. Please reach out to POChelp@rubrik.com” ', 'error','Error');
            return;
        }
        if( !isValidUcl) {
            this.showToast('Please Fill the Required Detail For UCL (Cloud Cluster, Cloud Native & Entra ID)', 'error','Error');
            return;
        }
        if(!isValidRCVDetails){
            this.showToast('Please update the invalid form entries and try again.', 'error','Error');
            return;
        }
        if(this.showRscInstanceFields && this.selectedRscAccountType === null){
            this.showToast('Please Fill RSC AccountType', 'error','Error');
            return;
        }
        if(this.isExistingUrlDisabled && this.selectedRscAccountType === 'Production'){
            this.showToast('No Production RSC instance was found. Please select a different RSC Account Type.', 'error','Error');
            this.selectedRscAccountType = '';
            return;
        }
        if(this.isExistingUrlRequired && this.selectedRscUrl === null){
            this.showToast('Please Fill Existing RSC URL', 'error','Error');
            return;
        }
        if (!this.validatePocRscInstance(this.suggestedUrl)) {
            this.showToast('RSC POC Domain name can contain only letters, numbers, and hyphens. No spaces or special characters.', 'error','Error');
            return;
        }
        this.fileUploadList = [];
       
        if(this.fileData !=undefined)
            this.fileUploadList.push(this.fileData);

        if(this.fileDataAgreement !=undefined)
            this.fileUploadList.push(this.fileDataAgreement);

        if(this.fileDataAgreementTryBuy !=undefined)
            this.fileUploadList.push(this.fileDataAgreementTryBuy);

        const fields = event.detail.fields;
        
        var pocRequest= fields;
        var returnItems = {};
        returnItems.pocRequestObj=pocRequest;
        returnItems.pocRequestObj.Shipping_State__c=this.selectedStateValue;
        returnItems.pocRequestObj.Ship_To_Country__c=this.shipCountry;
        returnItems.pocRequestObj.Shipping_Street__c=this.shipStreet;
        returnItems.pocRequestObj.Shipping_City__c=this.shipCity;
        returnItems.pocRequestObj.Shipping_Zip_Postal_Code__c=this.shipPostalCode;
        
        if(this.dataReduncyArchive){
            if(this.pocType == 'Standard POC : RSC-G'){
                returnItems.pocRequestObj.Data_Redundancy_Archive__c = this.dataReduncyArchive;
            } else{
            returnItems.pocRequestObj.Data_Redundancy_Archive_NAS__c = this.dataReduncyArchive;
}
        }
        if(this.mappedRscAccountType){
            returnItems.pocRequestObj.RSCAccountType__c = this.mappedRscAccountType;
        }
        if(this.suggestedUrl){
            returnItems.pocRequestObj.RscSuggestedUrl__c = 'https://'+this.suggestedUrl+'.my.rubrik.com';
        }
        returnItems.selectedRscInstance = this.selectedRscInstance;
        
        
        // if(this.storageRegionRCVArchGov){
        //    returnItems.pocRequestObj.Storage_Region_Bundle_RCV_Archive__c = this.storageRegionRCVArchGov;
        // }
        // if(this.storageRegionRCVBackupGov){
        //    returnItems.pocRequestObj.Storage_Region_Bundle_RCV_Backup__c = this.storageRegionRCVBackupGov;
        // }
        if(this.pocType == 'Standard POC : RSC-G'){
            returnItems.pocRequestObj.Polaris_Region__c = 'US';
        }
        if( this.template.querySelector('.pocQuantity lightning-input-field') )
            returnItems.pocRequestObj.POC_Qty__c= this.template.querySelector('.pocQuantity lightning-input-field').value || undefined;

      
        if(this.setOnlineAgreementSigned=='OnlineAgreement')
            returnItems.pocRequestObj.Online_Agreement_Signed__c= true;
            else
            returnItems.pocRequestObj.Online_Agreement_Signed__c= false;
	    
	     if(this.ManualPOCAgreementOption =='ManualPOCAgreement')
            returnItems.pocRequestObj.Manual_POC_Agreement__c= true;
          else
          returnItems.pocRequestObj.Manual_POC_Agreement__c=false;

        returnItems.pocRequestObj.Manual_POC_Agreement__c= this.showAgreementFileUpload;
        if( this.PartnerDistributorSignedPOCAddendum=='POCAddendum')
        returnItems.pocRequestObj.Partner_Disty_Signed_POC_Addendum__c= 'Yes';
        else 
        returnItems.pocRequestObj.Partner_Disty_Signed_POC_Addendum__c= 'No';


        console.log('DDD>>'+returnItems.pocRequestObj.POC_Type__c);
        console.log('XXX>>'+returnItems.pocRequestObj.Partner_Disty_Signed_POC_Addendum__c);
        console.log('BBB>>'+returnItems.pocRequestObj.Online_Agreement_Signed__c);
        console.log('BB>>'+returnItems.pocRequestObj.Manual_POC_Agreement__c);
        returnItems.pocRequestObj.POC_Agreement_Waived_Customer__c = this.oppRecord.Account.Type == 'Customer' ? true : false;
        
        if( this.isWebTryAndBuy && event.detail.fields.Online_Agreement_Signed__c === false && returnItems.pocRequestObj.POC_Agreement_Waived_Customer__c == false) {
            this.showToast('Online Agreement Signed is required (To make it Checked, Related Account should be Agreed to POC Terms and have atleast one contact in it.)', 'error','Error');
            return;
        }

        if( (returnItems.pocRequestObj.POC_Type__c == 'Standard POC' || returnItems.pocRequestObj.POC_Type__c== 'Conditional PO' ||  returnItems.pocRequestObj.POC_Type__c== 'CSAT Loaner' || returnItems.pocRequestObj.POC_Type__c== 'Ransomware Recovery Software' || returnItems.pocRequestObj.POC_Type__c == 'Standard POC : RSC-G')  && 
        (returnItems.pocRequestObj.Partner_Disty_Signed_POC_Addendum__c =='No' && returnItems.pocRequestObj.Online_Agreement_Signed__c==false && returnItems.pocRequestObj.Manual_POC_Agreement__c ==false && returnItems.pocRequestObj.POC_Agreement_Waived_Customer__c == false) ) {
            this.showToast('Any one of option should be checked to process POC Request ( Online Agreement Sing , Partner singed agreement or manual agreement', 'error','Error');
            return;
        }
        
        this.hideSpinner= false;
        returnItems.opportunityObj=this.oppRecord;
        //returnItems.fileUpload=this.fileUploadList;
        var editmode ='';
        if(this.returnObjectName == 'POC__c'){
            editmode='true';
            if(this.pocRecord.Id !=undefined)
            returnItems.pocRequestObj.Id = this.pocRecord.Id
        }
       
        else{
            editmode='false';
        }
        
        if(this.template.querySelector('c-poc-product-picker') !=undefined) {
            let productAttributes = this.template.querySelector('c-poc-product-picker').getAllData();
            console.log('productAttributes-->',productAttributes);
            console.log('productAttributes-->'+JSON.stringify(productAttributes));
            returnItems.pocRequestObj.Product_Categories__c = '';
            for(let productAttribute of productAttributes){
                //product categories
                console.log('productAttribute', productAttribute);
                if('Rubrik Appliance' === productAttribute['productName']
                    || 'RSC Enterprise Edition' === productAttribute['productName']
                    || 'Ransomware Monitoring & Investigation' === productAttribute['productName']
                    || 'Sensitive Data Monitoring & Remediation' === productAttribute['productName']
                    || 'Orchestrated Application Recovery' === productAttribute['productName']
                    || 'UCL (Cloud Cluster, Cloud Native & Entra ID)' === productAttribute['productName']
                    || 'Edge' === productAttribute['productName']
                    || 'M365 and Entra ID' === productAttribute['productName']
                    || 'Polaris Cloud Native Protection' === productAttribute['productName']
                    || 'Rubrik Cloud Vault' === productAttribute['productName']
                    || 'NAS Cloud Direct' === productAttribute['productName']
                    || 'RSC-Private' === productAttribute['productName']//updated for MKT26-93
                    || 'RSC 3rd Party S/W With Enterprise Ed.' === productAttribute['productName']
                    || 'SAP HANA for Cloud Cluster' === productAttribute['productName']
                    || 'RSC Proactive Edition' === productAttribute['productName']
                    // || 'Laminar' === productAttribute['productName']
                    || 'Data Security Posture Management' === productAttribute['productName']
                    || 'Atlassian Jira Cloud' === productAttribute['productName']

                    || 'RSC-G Enterprise Edition' === productAttribute['productName']
                    || 'RSC-G Proactive Edition' === productAttribute['productName']
                    || 'UCL(Cloud Cluster & Cloud Native)' === productAttribute['productName']
                    || 'Rubrik Cloud Vault - Government' === productAttribute['productName']
                    || 'RSC-G Third Party Software with Enterprise Edition' === productAttribute['productName']
                    || 'M365' === productAttribute['productName']
                    || 'SaaS (Jira Cloud, Salesforce)' === productAttribute['productName']
                    || 'RSC Enterprise and Proactive Editions' === productAttribute['productName'] // Added for MKT26-410
                    || 'RSC-G Enterprise and Proactive Editions' === productAttribute['productName'] // Added for MKT26-410
                    || 'Identity Recovery and Resilience - AD, Entra ID, Okta' === productAttribute['productName']
                    || 'Identity Recovery' === productAttribute['productName']
                    || 'Cloud Unstructured (S3, Azure Blob, and Cloud Files)' === productAttribute['productName']
                    || 'SaaS (Jira Cloud, Salesforce, Dynamics)' === productAttribute['productName']
                    || 'Codebase Recovery' === productAttribute['productName'] // Added for MKT26-490
                                        //|| 'Polaris AppFlows' === productAttribute['productName'] 
                    || 'Annapurna' === productAttribute['productName'] // Added for MKT26-405
                    || 'SaaS (Salesforce)' === productAttribute['productName']
                    || 'Identity Cyber Recovery for Okta' === productAttribute['productName']
                    || 'M365 and Google Workspace' === productAttribute['productName']
					|| 'Rubrik Agent Cloud' === productAttribute['productName']
                ){
                    if('RSC 3rd Party S/W With Enterprise Ed.' === productAttribute['productName']  && productAttribute['fields']['RSC_3rd_Party_Acknowledgment__c'] ===false) {
                        this.showToast('Please remove RSC Third Party software with Enterprise Edition from the Product Category selection section.',  'error','Error');
                        this.hideSpinner= true;
                        return;
                    }
                    if('RSC-G Third Party Software with Enterprise Edition' === productAttribute['productName'] && productAttribute['fields']['RSC_G_3rd_Party_Acknowledgment__c'] ===false) {
                        this.showToast('Please remove RSC-G Third Party Software with Enterprise Edition from the Product Category selection section.',  'error','Error');
                        this.hideSpinner= true;
                        return;
                    }
                    if('RSC-Private' === productAttribute['productName'] && productAttribute['fields']['RSC_Private_Acknowledgement__c'] ==false) {//updated for MKT26-93
                        this.showToast('Please remove RSC-Private from the Product Category selecteion section', 'error', 'Error' );
                        this.hideSpinner= true;
                        return;
                    }
                    if('RSC Enterprise Edition' === productAttribute['productName'] && productAttribute['fields']['Ransomware_Recovery_Software_Acknowledge__c'] ==false) {
                        this.showToast('Please select another POC Type', 'error', 'Error' );
                        this.hideSpinner= true;
                        return;
                    }
					//Start - Added for MKT26-405
                    if('Annapurna' === productAttribute['productName']  && ( productAttribute['fields']['Annapurna_Acknowledgment__c'] === 'No' || productAttribute['fields']['Annapurna_Acknowledgment__c'] === undefined) ) {
                        this.showToast('Please remove Annapurna from the Product Category selection section',  'error','Error');
                        this.hideSpinner= true;
                        return;
                    }
                    //End - Added for MKT26-405
                    //Start - Added for MKT26-410
                    if('RSC Enterprise and Proactive Editions' === productAttribute['productName'] && productAttribute['fields']['RSC_Enterprise_Edition__c'] === 'No' && productAttribute['fields']['RSC_Proactive_Edition__c'] === 'No') {
                        this.showToast('Please select one option to proceed', 'error', 'Error' );
                        this.hideSpinner= true;
                        return;
                    }
                    if('RSC-G Enterprise and Proactive Editions' === productAttribute['productName'] && productAttribute['fields']['RSC_G_Enterprise_Edition__c'] === 'No' && productAttribute['fields']['RSC_G_Proactive_Edition__c'] === 'No') {
                        this.showToast('Please select one option to proceed', 'error', 'Error' );
                        this.hideSpinner= true;
                        return;
                    }
                    //End - Added for MKT26-410
                    /*if('RSC Proactive Edition' === productAttribute['productName'] && productAttribute['fields']['RSC_Proactive_Edition_Acknowledgement__c'] ==false) {
                        console.log('productAttribute[fields][RSC_Proactive_Edition_Acknowledgement__c]: '+productAttribute['fields']['RSC_Proactive_Edition_Acknowledgement__c']);
                        this.showToast('Please remove RSC Proactive Edition from the Product Category selection section', 'error', 'Error' );
                        this.hideSpinner= true;
                        return;
                    }*/
                    if(returnItems.pocRequestObj.Product_Categories__c === ''){
                        returnItems.pocRequestObj.Product_Categories__c = productAttribute['productName'];
                    }
                    else if(!returnItems.pocRequestObj.Product_Categories__c.includes(productAttribute['productName'])){
                        returnItems.pocRequestObj.Product_Categories__c = returnItems.pocRequestObj.Product_Categories__c+';'+productAttribute['productName'];
                    }
                    if('UCL(Cloud Cluster & Cloud Native)' === productAttribute['productName'] && productAttribute['fields']['Cloud_Cluster_Location__c'] == 'GCP') {
                        this.showToast('Cloud Location is unavailable for this POC Type', 'error', 'Error' );
                        this.hideSpinner= true;
                        return;
                    }
                    if('UCL(Cloud Cluster & Cloud Native)' === productAttribute['productName']){
                        returnItems.pocRequestObj.Number_Of_UCL_FETB__c = 1;
                    }
                    returnItems.pocRequestObj.Storage_Region_Bundle_RCV_Archive__c ='Rubrik Cloud Vault' === productAttribute['productName'] ? this.storageRegionRCVArchGov : '';
                    returnItems.pocRequestObj.Storage_Region_Bundle_RCV_Backup__c = 'Rubrik Cloud Vault' === productAttribute['productName'] ? this.storageRegionRCVBackupGov : '';
                    
                    if('M365 and Google Workspace' === productAttribute['productName']){
                        const numberOfUsers = productAttribute['fields']['Number_of_Users__c'];
                        const numberOfUsersGoogle = productAttribute['fields']['Number_of_Users_Google_Workspace__c'];
                        const m365HostingEnvironment = productAttribute['fields']['M365_Hosting_environment__c'];
                        const googleHostingEnvironment = productAttribute['fields']['Google_Workspace_Hosting_Environment__c'];
                        if(productAttribute['fields']['M365_Option__c'] == 'No'){
                            if(numberOfUsers){
                                this.showToast('Number Of Users must be null.', 'error', 'Error' );
                                this.hideSpinner= true;
                                return;
                            }else if(m365HostingEnvironment){
                                this.showToast('M365 and Entra ID Hosting Environment must be null.', 'error', 'Error' );
                                this.hideSpinner= true;
                                return;
                            }
                        }
                        if(productAttribute['fields']['Google_Workspace__c'] == 'No'){
                            if(numberOfUsersGoogle){
                                this.showToast('Number of Users (Google Workspace) must be null.', 'error', 'Error' );
                                this.hideSpinner= true;
                                return;
                            }else if(googleHostingEnvironment){
                                this.showToast('Google Workspace Hosting Environment must be null.', 'error', 'Error' );
                                this.hideSpinner= true;
                                return;
                            }
                        }
                    }
                }
                //save the fields
                console.log('Products', JSON.stringify(productAttribute.product));
                Object.assign(returnItems.pocRequestObj, productAttribute['fields']);

                if('Rubrik Appliance' === productAttribute['productName']){
                    for(let element of productAttribute.product){
                        if(element.productName === '10Base-T NIC (RJ45, Copper)' && (element.switchType === 'r6416S' || element.switchType === 'r6420S' || element.switchType === 'r7420S' || element.switchType === 'r7424S')){
                            validRubrikAlliance = false;
                            break;
                        }
                    }
                  
                    if(!validRubrikAlliance){
                        this.showToast('r6416S, r6420S, r7420S & r7424S are only available for SFP+ NIC (Fiber) Networking type', 'error','Error');
                        this.hideSpinner= true;
                        return;
                    }
                }
                //compute data for Rubrik-Appliance
                if(productAttribute.product){
                    returnItems.pocRequestObj.Rubrik_Appliance_Products__c = JSON.stringify(productAttribute.product);
                                    }
                if(productAttribute.accessory){
                    returnItems.pocRequestObj.Rubrik_Appliance_Accessories__c = JSON.stringify(productAttribute.accessory);
                }
            }
            

        }
        returnItems.uclEdition = this.uclEdition; 
        
        returnItems.dataReduncyArchive = this.dataReduncyArchive;
        
                
console.log('FIANL REQUEST >>', JSON.stringify(returnItems.pocRequestObj));
        
        submitPOCRequest({ requestArrayObj: returnItems,fileListInsert: [],editmode:editmode})
		.then(result => {
           // console.log('result>>>'+ JSON.stringify(result));
            if(!result.isSuccess){
                this.hideSpinner= true;
                this.showToast(result.errorMessage, 'error','Error');
                return;
            }
            console.log('==Response', result);
            //this.showToast('Record Created Successfully !!', 'success','Success');
            /*if( this.componentMode !== 'nested' ) {
                this.dispatchEvent(new CloseActionScreenEvent());
                setTimeout(() => location.reload(), 500);
            } else {
                let _self = this;
                setTimeout(() => _self.closeComponent(), 500);
            }*/
            /*let _self = this;
            setTimeout(function(){
                _self.navigateToRecord( result.pocRequestObj.Id );
            }, 500)*/
            console.log('======Files to Upload', this.fileUploadList);
            if( this.fileUploadList.length > 0 ) {
                this.persistBanner = true;
                //this.showToast('File Upload in Progress. Please do not close current tab or press back button.', 'success','Record Created Successfully!!');
                const start = Date.now();
                var fileCount = 1;
                var totalFileCount = this.fileUploadList.length;
                this.uploadFile( this._sessionId, this.fileUploadList, result.pocRequestObj.Id, fileCount, totalFileCount, () => {
                    this.hideSpinner= true;
                    const duration = Date.now() - start;
                    console.log('Duration in milliseconds:: ', duration);
                    this.navigateToRecord( result.pocRequestObj.Id );
                });
            } else {
                this.showToast('Record Created Successfully!!', 'success','Success');
                let _self = this;
                setTimeout(function(){
                    _self.navigateToRecord( result.pocRequestObj.Id );
                }, 500)
            }
            //
            /*setTimeout(function(){ 
                this.cancelPOC(); 
            }, 500);*/
           
        }) 
		.catch(error => {
            this.hideSpinner= true;
			this.error = error;
            alert('ERROR'+error.message);
            this.showToast(error.message, 'error','Error');
		})
    }

  showToast(message, type,title){

        if(this.callfromVfPage==true) {
            if(type=='error'){
                //alert('Error :'+message);
                this.template.querySelector('c-custom-toast').showToast('error', message);
            }
           
            else {
                //alert('Success :'+message);
                this.template.querySelector('c-custom-toast').showToast('success', message);
            }
           
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: title,
                    message: message,
                    variant: type
                }),
    );
 }
}

    cancelPOC() {
        this.navigateToRecord( this.recordId );
    }

    closeComponent() {
        if( this.componentMode === 'nested' ) {
            this.cancelPOC();
        } else {
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }

    navigateToRecord(targetRecordId) {
        const cancelEvent = new CustomEvent('redirectrecord', {
            'detail' : {"targetRecordId" : targetRecordId}
        });
        this.dispatchEvent(cancelEvent);
    }


   
    handleChangePlanDateChange(event) {
        this.value = event.detail.value;
        var planDateRaw = this.value;
        var expectedEndDate = new Date();
        this.planDate =planDateRaw;
    
        if(this.pocType === 'Virtual Lab') {
           
         this.validateDateonScreen(planDateRaw,'PlanDateLogic','3','Virtual Lab',expectedEndDate);
         console.log('ll'+this.template.querySelector(".planInstDate lightning-input-field:first-child").value);
         
        }
        if(this.pocType === 'Standard POC : RSC-G' ) {
            this.validateDateonScreen(planDateRaw,'PlanDateLogic','0',this.pocType,expectedEndDate);
            console.log('ll'+this.template.querySelector(".planInstDate lightning-input-field:first-child").value);
        }
        if(this.pocType === 'Standard POC' || this.pocType === 'Conditional PO' || this.pocType === 'CSAT Loaner' ) {
           
            //Updated as part of MKT26-505
            //this.validateDateonScreen(planDateRaw,'PlanDateLogic','7',this.pocType,expectedEndDate);
            this.validateDateonScreen(planDateRaw,'PlanDateLogic','1',this.pocType,expectedEndDate);
            console.log('ll'+this.template.querySelector(".planInstDate lightning-input-field:first-child").value);
            
           }

           if(this.pocType === 'Web Try and Buy') {
           
            this.validateDateonScreen(planDateRaw,'PlanDateLogic','30',this.pocType,expectedEndDate);
            console.log('ll'+this.template.querySelector(".planInstDate lightning-input-field:first-child").value);
            
           }
           if(this.pocType === 'Partner Software Access') {
           
            //Updated as part of MKT26-505
            //this.validateDateonScreen(planDateRaw,'PlanDateLogic','7',this.pocType,expectedEndDate);
            this.validateDateonScreen(planDateRaw,'PlanDateLogic','1',this.pocType,expectedEndDate);
            console.log('ll'+this.template.querySelector(".planInstDate lightning-input-field:first-child").value);
            
           }
           if(this.pocType === 'Ransomware Recovery Software') {
           
            this.validateDateonScreen(planDateRaw,'PlanDateLogic','0',this.pocType,expectedEndDate);
            console.log('ll'+this.template.querySelector(".planInstDate lightning-input-field:first-child").value);
            
           }
        
    }

    handleChangeExpectedDateChange(event) {
        this.value = event.detail.value;
        var expectedDateRaw = this.value;
      
        if(this.pocType == 'Virtual Lab') {
          if(this.planDate !=''){
            this.validateDateonScreen(this.planDate,'ExpectedDateLogic','14','Virtual Lab',expectedDateRaw);
          } else{
            this.showToast('Please Enter Plan intallation date first', 'error','Error'); 
            this.template.querySelector(".expectedDate lightning-input-field:first-child").value='';   
          }
            
        
        }
        if(this.pocType == 'Ransomware Recovery Software') {
            if(this.planDate !=''){
              this.validateDateonScreen(this.planDate,'ExpectedDateLogic','30','Ransomware Recovery Software',expectedDateRaw);
            } else{
              this.showToast('Please Enter Plan intallation date first', 'error','Error'); 
              this.template.querySelector(".expectedDate lightning-input-field:first-child").value='';   
            }
              
          
          }
          if(this.pocType == 'Standard POC : RSC-G') {
            if(this.planDate !=''){
              this.validateDateonScreen(this.planDate,'ExpectedDateLogic','60','Virtual Lab',expectedDateRaw);
            } else{
              this.showToast('Please Enter Plan intallation date first', 'error','Error'); 
              this.template.querySelector(".expectedDate lightning-input-field:first-child").value='';   
            }
          }
        if(this.pocType === 'Standard POC' || this.pocType === 'Conditional PO' || this.pocType === 'CSAT Loaner') {
            if(this.planDate !=''){
              this.validateDateonScreen(this.planDate,'ExpectedDateLogic','180',this.pocType,expectedDateRaw);
            } else{
              this.showToast('Please Enter Plan intallation date first', 'error','Error'); 
              this.template.querySelector(".expectedDate lightning-input-field:first-child").value='';
            }
              
          
          }
          else if(this.pocType === 'Partner Software Access') {
            if(this.planDate !=''){
                this.validateDateonScreen(this.planDate,'ExpectedDateLogic','365',this.pocType,expectedDateRaw);
              } else{
                this.showToast('Please Enter Plan intallation date first', 'error','Error'); 
                this.template.querySelector(".expectedDate lightning-input-field:first-child").value='';
              }
        }
        
    }
   
    validateDateonScreen(fullDatePlan,typeofValidation,addDays,poCType,expectedEndDate) {
      
        this.hideSpinner= false;
       
       validateDate({ inputDate: fullDatePlan,typeofValidation:typeofValidation,days:addDays,poCType:poCType,expectedEndDate:expectedEndDate })
       .then(result => {

          console.log('result>>'+JSON.stringify(result)); 
           if(result !=undefined){
            this.hideSpinner= true;
           if(result['Status']=='Error' && poCType !='Web Try and Buy') {
               this.showToast(result['Message'], 'error','Error');
               if(typeofValidation==='PlanDateLogic'){
                   
                    this.template.querySelector(".planInstDate lightning-input-field:first-child").value='';
                    this.template.querySelector(".expectedDate lightning-input-field:first-child").value='';
                  
               }
               if(typeofValidation==='ExpectedDateLogic'){
                   console.log('sfdfds'+this.template.querySelector(".planInstDate lightning-input-field:last-child"));
                this.template.querySelector(".expectedDate lightning-input-field:first-child").value='';
                this.disabledexpectedendDate=false;
               }
                
               return false;
            } else if( poCType ==='Web Try and Buy') {
               
                if(result['Status']=='Error') {
                    this.showToast(result['Message'], 'error','Error');
                    if(typeofValidation==='PlanDateLogic'){

                        this.template.querySelector(".planInstDate lightning-input-field:first-child").value='';
                        this.template.querySelector(".expectedDate lightning-input-field:first-child").value='';
                        this.disabledexpectedendDate=false; 
                    }
              } else {
                 
                if(result['Expected End Date'] !=undefined){
                    this.template.querySelector(".expectedDate lightning-input-field:first-child").value=result['Expected End Date']; 
                    this.disabledexpectedendDate=true;
                   }
              }
        }
             else {
                if(typeofValidation==='PlanDateLogic'){
                     this.template.querySelector(".expectedDate lightning-input-field:first-child").value='';
                }
               this.hideSpinner= true;
               this.disabledexpectedendDate=false;

          }
       }
    } ) 
       .catch(error => {
           this.error = error;
           this.showToast(error.message, 'error','Error in Page'); 
       })
  
}
    uploadFile( sessionId, files, recordId, fileCount, fileTotalCount, afterFileUpload ) {
        var data = files.shift();
        var dataPayload = {
            "PathOnClient": "TestName", 
            "Title": data.filename,
            "versionData" : data.base64,
            "FirstPublishLocationId": recordId
        }
        var payloadHeaders = {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': "Bearer " + sessionId
        };
        fetch( CONTENT_VERSION_REST_URL,
            {
                headers: payloadHeaders,
                method: "POST",
                body: JSON.stringify(dataPayload)
            }).then(( result ) => {
                
                if( files.length > 0 ) {
                    this.showToast( 'File ' + fileCount +' of ' + fileTotalCount + ' Uploaded', 'success',data.filename + ' Uploaded!');
                    fileCount++;
                    this.uploadFile( sessionId, files, recordId, fileCount, afterFileUpload, afterFileUpload ); 
                } else {
                    this.showToast( 'All Files Uploaded', 'success', data.filename + ' Uploaded!');
                    afterFileUpload();    
                }
            }, (failure) => {
                this.showToast( 'File ' + fileCount +' of ' + fileTotalCount + ' could not be uploaded', 'error', data.filename + ' Failed!');
                afterFileUpload();
            });
    }
    uclEditionMethod(event){
        this.uclEdition = event.detail;
    }
    handleGovDataAndStorage(event) {
        const eventDetailString = event.detail; 
        const [dataReduncyArchive, storageRegionRCVArchGov, storageRegionRCVBackupGov] = eventDetailString.split(';');
        this.dataReduncyArchive = dataReduncyArchive;
        this.storageRegionRCVArchGov = storageRegionRCVArchGov;
        this.storageRegionRCVBackupGov = storageRegionRCVBackupGov;
    }
    handleGovDataAndStorage(event) {
        const eventDetailString = event.detail; 
        const [dataReduncyArchive, storageRegionRCVArchGov, storageRegionRCVBackupGov] = eventDetailString.split(';');
        this.dataReduncyArchive = dataReduncyArchive;
        this.storageRegionRCVArchGov = storageRegionRCVArchGov;
        this.storageRegionRCVBackupGov = storageRegionRCVBackupGov;
    }
    extractHostname(url) {
        try {
            return new URL(url).hostname;
        } catch (e) {
            return url.split('/')[0];
        }
    }
    parseDomain(url) {
        if (!url) {
            return null;
        }

        const hostname = this.extractHostname(url).toLowerCase();
        const parts = hostname.split('.').filter(Boolean);
        
        if (parts.length === 0) {
            return null;
        }

        let publicSuffix = parts.slice(-1)[0];
        let domain = '';
        let subdomain = '';

        if (parts.length >= 3) {
            const lastTwo = parts.slice(-2).join('.');

            if (this.COMMON_TWO_LEVEL_TLDS.includes(lastTwo)) {
                publicSuffix = lastTwo;
                domain = parts.slice(-3, -2)[0];
                subdomain = parts.slice(0, -3).join('.');
            } else {
                publicSuffix = parts.slice(-1)[0];
                domain = parts.slice(-2, -1)[0];
                subdomain = parts.slice(0, -2).join('.');
            }
        } else if (parts.length === 2) {
            domain = parts[0];
        } else if (parts.length === 1) {
            domain = parts[0];
        }

        return {
            hostname,
            domain,
            publicSuffix,
            subdomain
        };
    }    
}