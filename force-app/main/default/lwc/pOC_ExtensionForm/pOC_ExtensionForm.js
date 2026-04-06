import { LightningElement, track, api, wire } from 'lwc';
import updatePOC from '@salesforce/apex/PocFormControllerCls.updatePOCRequest';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import validateDate from '@salesforce/apex/PocFormControllerCls.validateExpectedEndDate';
import pocExtensionAccess from '@salesforce/customPermission/POC_Extension_Access';
import { getRecord } from 'lightning/uiRecordApi';
import NEW_EXPECTED_DATE from '@salesforce/schema/POC__c.New_Expected_End_Date__c';
import POC_TYPE from '@salesforce/schema/POC__c.POC_Type__c';
import APPROVAL_STATUS from '@salesforce/schema/POC__c.Approval_Status__c';
import MOST_RECENT_END_DATE from '@salesforce/schema/POC__c.Most_Recent_End_Date__c';

export default class POC_ExtensionForm extends LightningElement {
	
   @api callfromVfPage=false;
	
    @track orders;
    @track error ;
    @track allReturnRecords;
    @track minDate;
    @track pickupDate;
   // @track recordId;
   _recordId;
    @track pocRecord;
    @track areDetailsVisible = false;
    POCType=null;
    @track approvalStatus = '';
    @track thirtyDaysAfterEndDate;

    disableExpectedDateButton = false;
    newExpectedEndDate = null;
    newExpectedComment = null;
    
    wirePOCRecord = null;

    @wire(getRecord, { recordId: '$recordId', fields: [NEW_EXPECTED_DATE, POC_TYPE, APPROVAL_STATUS, MOST_RECENT_END_DATE]})
    recordFetched({error, data}) {
        this.wirePOCRecord = data;
        var getDateString = function(dateVal) {
            if( dateVal < 10 ) {
                return '0' + dateVal;
            } else {
                return dateVal.toString();
            }
        }
        if( data ) {
            this.POCType=data.fields.POC_Type__c.value;
            console.log('=-===>><><', data);
            this.approvalStatus = data.fields.Approval_Status__c.value;
            let endDate = data.fields.Most_Recent_End_Date__c.value;
            this.thirtyDaysAfterEndDate = new Date(endDate);
            this.thirtyDaysAfterEndDate.setDate(this.thirtyDaysAfterEndDate.getDate() + 30); // Set now + 30 days as the new date
            
            if( data.fields.POC_Type__c.value === 'Web Try and Buy' || data.fields.POC_Type__c.value === 'Ransomware Recovery Software') {
                let currentExpectedDate=data.fields.New_Expected_End_Date__c.value;
                console.log('===>>>Old date', currentExpectedDate);
                var date = new Date(currentExpectedDate);
                date.setDate(date.getDate() + 30);
                var month = (date.getMonth() + 1) < 10 
                var formattedDate = date.getFullYear() + '-' + getDateString((date.getMonth() + 1)) + '-' + getDateString(date.getDate());
                this.newExpectedEndDate = formattedDate;
                this.disableExpectedDateButton = true;
            } else {
                //this.newExpectedEndDate = data.fields.New_Expected_End_Date__c.value;
            }
        }
    }


    loadData() {
    }
   showToast(message, type,title){
        if(this.callfromVfPage==true) {
		
            if(type=='error'){
		    
                //alert('Error :'+message);
                this.template.querySelector('c-custom-toast').showToast('error', message);
            }
           
            else {
		    
               // alert('Success :'+message);
               this.template.querySelector('c-custom-toast').showToast('success', message);
            }
           
        } else {
		
        this.dispatchEvent(
                    new ShowToastEvent({
                        title: title,
                        message: message,
                        variant: type,
                    }),
        );
     }

   }
	
    handleLoad(event){
        this.areDetailsVisible = true;  
    }
    
    handleSubmit(event){
        event.preventDefault();       // stop the form from submitting
        this.areDetailsVisible = false;
        if(this.approvalStatus != 'Approved' && this.approvalStatus != 'Extension Approved' && this.approvalStatus != 'Extension Rejected' && this.approvalStatus != 'Return Rejected' && this.approvalStatus != 'Extension Requested' && this.approvalStatus != 'Extension Recalled'){
            this.showToast('A return is already Initiated / Completed for this POC.','error','Error');
            this.areDetailsVisible = true;
        }else if(this.approvalStatus == 'Extension Requested'){
            this.showToast('An Extension has already been requested for this POC.','error','Error');
            this.areDetailsVisible = true;
        }else{
            const fields = event.detail.fields;
            console.log('===>>><<><>', JSON.stringify(fields));
            if( this.disableExpectedDateButton === true ) {
                event.detail.fields.New_Expected_End_Date__c = this.newExpectedEndDate;
            }
            fields.Id = this._recordId;
            fields.Approval_Status__c = 'Extension Requested';
            fields.POC_Type__c=this.POCType;
            const todaysDate = new Date();
        
            if(todaysDate < this.thirtyDaysAfterEndDate){
                updatePOC({ pocRequest: fields})
		        .then(result => {
                    this.areDetailsVisible = true;
                    if(!result.isSuccess){
                        if(result.errorMessage.includes('You Cannot Create  More than One Extension for Web Try and Buy')){
                            this.showToast('You Cannot Create More than One Extension for Web Try and Buy','error','Error');
                        }
                        else if(result.errorMessage.includes('You Cannot Create More than Two Extensions for Ransomware Recovery Software')){
                            this.showToast('You Cannot Create More than Two Extensions for Ransomware Recovery Software','error','Error');
                        }
                        else{
                            this.showToast(result.errorMessage, 'error','Error');
                        }
                        return;
                    }
                
                    if(this.callfromVfPage==false) {
                    
                        this.dispatchEvent(new CloseActionScreenEvent());
                        setTimeout(function(){ location.reload(); }, 500);
                        } else {
                        
                         this.navigateToRecord(this.recordId);
                        
                        }
                    
                }) 
		        .catch(error => {
		        	this.error = error;
		        	this.allReturnRecords = undefined;
                    this.showToast(error.message, 'error','Error');
		        })
            }else{
                this.showToast('The end date has already passed and an extension is not allowed','error','Error');
                this.areDetailsVisible = true; 
            }
        }
    }
    handleSucess(event){
        const updatedRecord = event.detail.id;
        console.log('onsuccess: ', updatedRecord);
    }



    @api set recordId(value) {
        this._recordId = value;
        if(value)
            this.loadData();

    }

    get recordId() {
        return this._recordId;
    }
   
    // Getter
    get noAccessForExtension(){
        var noAccess = !pocExtensionAccess;
        if(noAccess){
            this.showToast("Your Profile don't have access for the extension of POC", 'error','Error');
            if(this.callfromVfPage==false) {
		    
                this.dispatchEvent(new CloseActionScreenEvent());
                } else {
			
                    this.navigateToRecord(this.recordId);  
                }
        }
        return noAccess;
    }
	
	  handleChangeExpectedDateChange(event) {
        this.value = event.detail.value;
        var expectedDateRaw = this.value;
        var pocRecordId = this._recordId;
       
         if(expectedDateRaw !='')
            this.validateDateonScreen(pocRecordId,'ExpectedDateLogic',expectedDateRaw);
      
    }

    validateDateonScreen(pocrecordId,typeofValidation,expectedEndDate) {
      
        this.areDetailsVisible= false;
       
       validateDate({pocRecordId:pocrecordId,typeofValidation:typeofValidation,expectedEndDate:expectedEndDate })
       .then(result => {

          console.log('result>>'+JSON.stringify(result)); 
           if(result !=undefined){
            this.areDetailsVisible= true;
           if(result['Status']=='Error') {
               this.showToast(result['Message'], 'error','Error');
               this.template.querySelector(".expectedEndDate lightning-input-field:first-child").value='';
              
                
               return false;
            } 
             else {
               
               this.areDetailsVisible= true;
               this.disabledexpectedendDate=false;

          }
       }
    } ) 
       .catch(error => {
           this.error = error;
           this.showToast(error.message, 'error','Error in Page'); 
       })
  
}
	
navigateToRecord(targetRecordId) {
	
	
    const cancelEvent = new CustomEvent('redirectrecord', {
        'detail' : {"targetRecordId" : targetRecordId}
    });
	
    this.dispatchEvent(cancelEvent);
}

cancleButtonEvent(event){ 
    if(this.callfromVfPage==false) {
		    
        this.dispatchEvent(new CloseActionScreenEvent());
        } else {
    
            this.navigateToRecord(this.recordId);  
        }
 }

}