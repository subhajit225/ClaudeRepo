import { LightningElement, track, api } from 'lwc';
import getAllOrders from '@salesforce/apex/PocFormControllerCls.getOrders'; 
import getStatebyCountry from '@salesforce/apex/PocFormControllerCls.getStatebyCountry'; 
import submitReturnRequest from '@salesforce/apex/PocFormControllerCls.submitRequest';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';

export default class POC_ReturnForm extends NavigationMixin(LightningElement) {
   
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
    @track hideSpinner = false;
    @track fieldsSelected ={};
    @track stateValues;
    @track deliveryStateValues;
    @track rubrikEmployeeSelected;
    @track DeliveryState='';
    @track PickupState='';
	
    _value;

    get deliveryOptions() {
        return [
            {label: 'Partner Account', value: 'PartnerAccount'},
            {label: 'Rubrik Employee', value: 'RubrikEmployee'},
        ];
    }

    loadData() {
        var params = new URLSearchParams(window.location.search);
        //this.recordId = params.get('recordId');
        //alert(this.recordId);
        var someDate = new Date();
        var numberOfDaysToAdd = 4;
        someDate.setDate(someDate.getDate() + numberOfDaysToAdd); 
        var dd = someDate.getDate();
        var mm = someDate.getMonth() + 1;
        var y = someDate.getFullYear();

        this.minDate = y + '-'+ mm + '-'+dd;
        //this.stateValues = [];
		getAllOrders({ pocRequestId: this.recordId })
		.then(result => {
            if(!result.isSuccess){
                this.showToast(result.errorMessage, 'error','Error');
                if(this.callfromVfPage==false) {
			
                        this.dispatchEvent(new CloseActionScreenEvent());
                    } else {
			    
			    

                        this.navigateToRecord(this.recordId);
                    }
                return;
            }
            var rec= [];
            this.pocRecord = result.pocRecords[0];
			this.orders = result.assetRecords;
			this.error = undefined;
            var i = 0;
            result.assetRecords.forEach(function(order){
               rec.push(
                    {
                        selected: true,
                        index: i,
                        Id: order.Id,
                        productName : order.Product2.Name,
                        productId : order.Product2.Id,
                        damaged : false,
                        eraseRequested: false,
                        sdResetComplete: false,
                        demageDetails: '',
                        serial: order.SerialNumber,
                        originalPackaging: false,
                    }
               );
               i++;
            });
            if(this.pocRecord.Ship_To_Country__c != undefined){
                let value = this.pocRecord.Ship_To_Country__c;
                getStatebyCountry({ Countryname: value }) 
                .then(result1 => {
                    console.log('result1:', result1);
                    if(result1 !=undefined){
                        let options = [];
                        result1.forEach(function (item, index) {
                            //console.log(item, index);
                            options.push({ label: item.split(';')[0], value: item.split(';')[1] });
                        });
                        this.stateValues = options;
                    }
                    console.log('this.stateValues:', this.stateValues);
	               
                    //this.hideSpinner=true;
                }) 
                .catch(error => {
                    this.error = error;
                   
                })

                this.PickupState = this.pocRecord.Shipping_State__c;
                this.hideSpinner= true;
            }
            this.hideSpinner= true;
            this.allReturnRecords = rec;
            this.areDetailsVisible = true;
            this.fieldsSelected.Return_to_Rubrik_warehouse__c = true;
            this.rubrikEmployeeSelected = false;
            
            this._value = 'PartnerAccount';
            console.log(rec);
		}) 
		.catch(error => {
			this.error = error;
			this.allReturnRecords = undefined;
            this.showToast(error.body.message, 'error','Error');
            this.dispatchEvent(new CloseActionScreenEvent());
		})
    }
// Changes add reated to POC Classic Migration//
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
    onDateChange(event) {
        var isValid = event.target.checkValidity();
        this.pickupDate = event.target.value;
    }

    handleFieldSelected(event){
        this.fieldsSelected[event.target.dataset.field] = event.target.value;
    }
	
	 handleStateChange(event) {
        this.value=event.target.value;
       this.DeliveryState= this.value;
    }

    handleCheckboxChange(event) {
        this.allReturnRecords[event.target.dataset.id][event.target.dataset.field] = event.target.checked;
    }

    handletextChange(event) {
        this.allReturnRecords[event.target.dataset.id].demageDetails = event.target.value;
    }
    
    handleSubmit(event){
        event.preventDefault();       // stop the form from submitting
        //this.hideSpinner= false;
        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputCmp) => {
                        inputCmp.reportValidity();
                        return validSoFar && inputCmp.checkValidity();
            }, true);
        if (!allValid) {
            this.showToast('Please update the invalid form entries and try again.', 'error','Error');
            return;
        } 
        this.hideSpinner= false;
        const fields = event.detail.fields;
        fields.POC_Request__c = this.recordId;
        fields.Name = this.pocRecord.Name+'-Return';
        fields.Available_Pick_Up_Day__c = this.pickupDate;
        var pocReturn= fields;
        var returnItems = [];
        this.allReturnRecords.forEach(function(record){
            if(record.selected){
               returnItems.push(
                    {
                        Damage_Details__c: record.demageDetails,
                        Damage_Reported_by_the_customer__c: record.damaged,
                        Data_Erase_Requested__c: record.eraseRequested,
                        Asset__c : record.Id,
                        Name: record.productName+'-Return',
                        Product__c : record.productId,
                        Original_Packaging_Available__c : record.originalPackaging,
                        Serial_Number__c: record.serial,
                        complete_a_SD_Reset__c: record.sdResetComplete
                       
                    }
               );
            }
            });
	    
	     pocReturn.Delivery_State__c= this.DeliveryState;
            pocReturn.Pick_up_State__c= this.PickupState;
	    
        submitReturnRequest({ pocReturn: pocReturn, returnItemList: returnItems})
		.then(result => {
            this.hideSpinner= true;
            if(!result.isSuccess){
                this.showToast(result.errorMessage, 'error','Error');
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
            this.hideSpinner= true;
			this.error = error;
			this.allReturnRecords = undefined;
            this.showToast(error.message, 'error','Error');
		})

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
    handlepickupSateChange(event) {
        this.value=event.detail.value;
        this.PickupState=this.value;
    }	
	
    handleShippingCountryChange(event){
        let value = event.detail.value;
        console.log('value:', value);
        this.hideSpinner=false;
        getStatebyCountry({ Countryname: value }) 
                .then(result => {
                    console.log('result:', result);
                    if(result !=undefined){
                        let options = [];
                        result.forEach(function (item, index) {
                            //console.log(item, index);
                            options.push({ label: item.split(';')[0], value: item.split(';')[1] });
                        });
                        this.stateValues = options;
                    }
                    console.log('this.stateValues:', this.stateValues);
                    this.hideSpinner=true;
                }) 
                .catch(error => {
                    this.error = error;
                   
                })
    }
    handleDeliveryCountryChange(event){
        let value = event.detail.value;
        console.log('value:', value);
        this.hideSpinner=false;
        getStatebyCountry({ Countryname: value }) 
                .then(result => {
                    console.log('result:', result);
                    if(result !=undefined){
                        let options = [];
                        result.forEach(function (item, index) {
                            //console.log(item, index);
                            options.push({ label: item.split(';')[0], value: item.split(';')[1] });
                        });
                        this.deliveryStateValues = options;
                    }
                    console.log('this.deliveryStateValues:', this.deliveryStateValues);
                    this.hideSpinner=true;
                }) 
                .catch(error => {
                    this.error = error;
                   
                })
    }

    handleDeliveryAccountChange(event){
        let value = event.detail.value;
        if(value === 'RubrikEmployee'){
            this.rubrikEmployeeSelected = true;
        }
        else {
            this.rubrikEmployeeSelected = false;
        }
    }
	
// Navigate method on redirection.//	
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