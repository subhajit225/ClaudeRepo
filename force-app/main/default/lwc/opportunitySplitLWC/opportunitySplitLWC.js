import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import modal from "@salesforce/resourceUrl/quickActionWidthLWCCSS";
import { loadStyle } from "lightning/platformResourceLoader";
import getOppDetails from '@salesforce/apex/OpportunitySplitLWCController.getOppDetails';
import getSplitOppDetails from '@salesforce/apex/OpportunitySplitLWCController.getSplitOppDetails';
import saveItem from '@salesforce/apex/OpportunitySplitLWCController.saveItem';
import getmappingDetails from '@salesforce/apex/OpportunitySplitLWCController.getmappingDetails';
export default class OpportunitySplitLWC extends NavigationMixin(LightningElement){
    @api recordId;
    @track wrapDetails = [{splitopp : {'Owner' : {}}}];
    @track primaryOppWrapDetails = {};
    @track primaryopp = { 'Account' : {}, 'Owner' : {}};
    @track mappingtablWrapDetails = {};
    @track totalAmount = 0 ;
    @track totalACVAmount = 0 ;
    @track totalSplit = 0;
    @track totalCSplit = 0;
    @track totalUplift = 0;
    @track oppOwnerName = '';
    @track disableButtons = false;
    keyIndex = 1;
    @track newoptyTotalValue = 0;
    @track newoptyTotalValueUI = 0;
    @track optyTotalValue = 0;
    @track optyTotalACVValue = 0;
    @track optyTotalValueUI = 0;
    @track optyTotalACVValueUI = 0;
    @track oppStageName = '';
    @track isglobal = false;
    @track isSplitException = false;
    @track showLoader = false;
    spliOppList = [{ splitopp: {} }];
    @track previousOwnerId = new Array();
    @track itemList = [
        {
           opp : {}
        }];
    get isFirstItem() {
        return this.selectVal === "Jan";
    }

    connectedCallback(){
        this.showLoader = true;
        loadStyle(this, modal);
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            console.log(' recordId..!', this.recordId);
            getOppDetails({
                'recId' : this.recordId
            }).then(result => {
                this.showLoader = false;
                console.log(' oppDetails..!');         
                console.log(result);
                this.primaryOppWrapDetails = result[0];
               if(result[0].errMsg != ''){
                   this.showToast('', result[0].errMsg, result[0].variant, 'pester');
                   this.disableButtons = true;
               }
                this.primaryopp = this.primaryOppWrapDetails.primaryopp;
                this.isglobal = this.primaryOppWrapDetails.isglobal;
                this.oppStageName = this.primaryOppWrapDetails.primaryopp.StageName;
                this.optyTotalValue = this.primaryOppWrapDetails.optyTotalValue;
                this.optyTotalACVValue = this.primaryOppWrapDetails.newoptyACVValue;
                this.optyTotalValueUI = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(this.optyTotalValue);
                this.newoptyTotalValue = this.primaryOppWrapDetails.newoptyTotalValue;
                this.newoptyTotalValueUI = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(this.newoptyTotalValue);
                
                this.oppOwnerName = this.primaryopp.Owner.Name;

                var newtcv = this.newoptyTotalValue;
                var newacv = this.optyTotalACVValue;
                if(this.primaryopp.Split_percentage__c != null && this.primaryopp.Split_percentage__c != ''){
                    newtcv = (this.newoptyTotalValue*this.primaryopp.Split_percentage__c)/100;
                    newacv = (this.optyTotalACVValue*this.primaryopp.Split_percentage__c)/100;
                }
                var newItem = [{ id:1,firstItem : true, userId :this.primaryopp.OwnerId,splitperc : this.primaryopp.Split_percentage__c,cperc:this.primaryopp.Commission_Credit_Split_Split_screen__c,uplift:this.primaryopp.Global_Acct_Split_Uplift__c,splitamount : newtcv, splitACVamount : newacv, opp : this.primaryopp}];
                this.itemList = newItem;
                this.keyIndex = 1;
                console.log(this.itemList);

                getSplitOppDetails({
                    'recId' : this.recordId
                }).then(result => {
                    console.log(' getSplitOppDetails..!');         
                    console.log(result);
                    this.wrapDetails = result;
                    if(this.wrapDetails != null && this.wrapDetails.length > 0){
                        for(var i =0;i<this.wrapDetails.length;i++){
                            if(!(this.wrapDetails[i].splitopp.ACV_Amount__c != '' && this.wrapDetails[i].splitopp.ACV_Amount__c != null)){
                                this.wrapDetails[i].splitopp.ACV_Amount__c = 0.00;
                            }
                            
                            if(this.primaryopp.OwnerId != this.wrapDetails[i].splitopp.OwnerId){
                                this.previousOwnerId.push(this.wrapDetails[i].splitopp.OwnerId);
                            }
                            var newItem = [{ id: this.wrapDetails[i].index, userId :this.wrapDetails[i].splitopp.OwnerId,splitperc : this.wrapDetails[i].splitopp.Split_percentage__c,cperc:this.wrapDetails[i].splitopp.Commission_Credit_Split_Split_screen__c,uplift:this.wrapDetails[i].splitopp.Global_Acct_Split_Uplift__c,splitamount : this.wrapDetails[i].splitopp.Amount, splitACVamount : this.wrapDetails[i].splitopp.ACV_Amount__c, opp : this.wrapDetails[i].splitopp}];
                            this.itemList = this.itemList.concat(newItem);
                            this.keyIndex = this.wrapDetails[i].index;
                        }
                    }
                    
                    this.optyTotalACVValueUI = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(this.optyTotalACVValue);
                    this.calculateTotalPercAmount();
                     getmappingDetails({
                    'isglobal' : this.isglobal
                        }).then(result => {
                            console.log(' getmappingDetails..!');         
                            console.log(result);
                            this.mappingtablWrapDetails = result;  
                            this.calculateUpliftAndTotalCSplit_Uplift('onload');       
                        }).catch(error => {
                            console.log('error..!', error);
                            this.showToast('', error, 'error', 'pester');
                        });
                    }).catch(error => {
                        console.log('error..!', error);
                        this.showToast('', error, 'error', 'pester');
                    });
                }).catch(error => {
                    this.showLoader = false;
                    console.log('error..!', error);
                    this.showToast('', error, 'error', 'pester');
                });
                
        }, 1000);
    }
    handleUserChange(event){ 
        this.itemList[event.target.tableindex].userId = event.detail.Id;
    }
    handlePercChange(event){  // handling split% change & autopopulation of commissionsplit% from mapping table
        if(event.target.value == '')
            event.target.value = 0;

        // Check if this is the first record (index 0) and value is zero
        const recordIndex = parseInt(event.target.dataset.id);
        if(recordIndex === 0 && (parseFloat(event.target.value) === 0 || event.target.value === '0')) {
            // Reset the field and show error
            event.target.value = '';
            event.target.setCustomValidity('Booking Split (%) cannot be zero on the Parent Opportunity');
            event.target.reportValidity();
            return;
        } else {
            // Clear any previous custom validity
            event.target.setCustomValidity('');
        }

        this.itemList[event.target.dataset.id].splitperc = parseFloat(event.target.value);
        this.itemList[event.target.dataset.id].splitamount = (this.newoptyTotalValue*this.itemList[event.target.dataset.id].splitperc)/100;
        this.itemList[event.target.dataset.id].splitACVamount = (this.optyTotalACVValue*this.itemList[event.target.dataset.id].splitperc)/100;
        
        this.calculateTotalPercAmount();

        if(this.mappingtablWrapDetails != null && this.mappingtablWrapDetails.length > 0){
            for(var i = 0; i<this.mappingtablWrapDetails.length; i++){
                if(this.itemList[event.target.dataset.id].splitperc == this.mappingtablWrapDetails[i].split && this.isglobal == this.mappingtablWrapDetails[i].isgbl){
                    this.itemList[event.target.dataset.id].cperc = parseFloat(this.mappingtablWrapDetails[i].csplit);
                    if(this.isglobal){
                        this.itemList[event.target.dataset.id].uplift = this.itemList[event.target.dataset.id].cperc - this.itemList[event.target.dataset.id].splitperc;
                    }
                }
            }
            this.calculateUpliftAndTotalCSplit_Uplift('onchange');
        }
    }
    //Commented SAL25-668
    /*handleCPercChange(event){ //handling commission split% change & autopopulation of uplift%
        if(event.target.value == '')
            event.target.value = 0;   
        this.itemList[event.target.dataset.id].cperc = parseFloat(event.target.value);
        if(parseFloat(this.itemList[event.target.dataset.id].cperc) > 100){
            this.itemList[event.target.dataset.id].cperc = '';
            event.target.value = '';
            this.showToast('Commission/Credit Split(%)', 'Commission/Credit Split(%) cannot be more than 100%', 'error', 'pester');
        }else{
            if(parseFloat(this.itemList[event.target.dataset.id].cperc) < parseFloat(this.itemList[event.target.dataset.id].splitperc)){
                this.itemList[event.target.dataset.id].cperc = '';
                event.target.value = '';
                this.showToast('Commission/Credit Split(%)', 'Commission/Credit Split(%) cannot be less than Booking Split(%)', 'error', 'pester'); 
            }else{
                this.calculateUpliftAndTotalCSplit_Uplift('onchange');
            }
        }
    }*/
    calculateUpliftAndTotalCSplit_Uplift(evnt){ //calculation of Uplift%, total commission split% & Uplift%
        var tcsplit = 0;
        var tuplift = 0;
        var isSplitExcptn = false;
        const splitMetadataArr = [];

        if(this.mappingtablWrapDetails != null && this.mappingtablWrapDetails.length > 0){
                for(var j = 0; j< this.mappingtablWrapDetails.length; j++){
                    splitMetadataArr[j] = this.mappingtablWrapDetails[j].split;
                }
        }
        for(var i=0;i<this.itemList.length;i++){
            tcsplit = tcsplit+parseFloat(this.itemList[i].cperc);
            if(this.isglobal && this.itemList[i].cperc != '' &&  parseFloat(this.itemList[i].cperc) >= 0 && (this.itemList[i].splitperc != '' || parseFloat(this.itemList[i].splitperc) == 0)){
                this.itemList[i].uplift = this.itemList[i].cperc - this.itemList[i].splitperc;
                tuplift = tuplift+parseFloat(this.itemList[i].uplift);
            }
            if(this.mappingtablWrapDetails != null && this.mappingtablWrapDetails.length > 0){
                for(var j = 0; j< this.mappingtablWrapDetails.length; j++){
                    if(this.itemList[i].splitperc == this.mappingtablWrapDetails[j].split && this.isglobal == this.mappingtablWrapDetails[j].isgbl && 
                       this.itemList[i].cperc != this.mappingtablWrapDetails[j].csplit){
                           isSplitExcptn = true;
                           break;
                    }
                }
                if(splitMetadataArr != null && splitMetadataArr.length > 0 && !splitMetadataArr.includes(this.itemList[i].splitperc)){
                    isSplitExcptn = true;
                }
            }
        }
        console.log('isSplitExcptn');
        console.log(isSplitExcptn);
        this.totalCSplit = tcsplit;
        this.totalUplift = tuplift;
        if(evnt == 'onchange'){
            this.isSplitException = isSplitExcptn;
        }
    }
    calculateTotalPercAmount(){ // calculates total Split% , ACV & TCV
        var tsplit = 0;
        var tamt = 0;
        var tacvamt = 0;
        for(var i=0;i<this.itemList.length;i++){
            tsplit = tsplit+parseFloat(this.itemList[i].splitperc);
            if(this.itemList[i].splitamount != null && this.itemList[i].splitamount != '')
                tamt = tamt+parseFloat(this.itemList[i].splitamount);
            if(this.itemList[i].splitACVamount != null && this.itemList[i].splitACVamount != '')
                tacvamt = tacvamt+parseFloat(this.itemList[i].splitACVamount);
        }
        this.totalSplit = tsplit;
        this.totalAmount = tamt;
        this.totalACVAmount = tacvamt;
    }
    addRow() {  // adds new row when clicked on + sign
        ++this.keyIndex;
        var newItem = [{ id: this.keyIndex,  userId : '',splitperc : 0,cperc : 0, uplift : 0, splitamount : 0, splitACVamount : 0, opp : {Id : null}}];
        this.itemList = this.itemList.concat(newItem);
    }

    removeRow(event) {  //deletion of row
        console.log(event.target.accessKey);
        var i = event.target.accessKey-1;
        var resetIndex = false;
        if (this.itemList.length >= 2 && parseInt(event.target.accessKey) != 1) {
            resetIndex = true;
            this.itemList = this.itemList.filter(function (element) {
                return parseInt(element.id) !== parseInt(event.target.accessKey);
            });
            for(var j=0;j<this.itemList.length; j++){
                this.itemList[j].id = j+1;
            }
            --this.keyIndex;
            this.calculateTotalPercAmount();
        }
    }
    handleSubmit(event){  // handles save functionality when clicked on 'Submit' button
        var isValid = true;
        var index = 0;
        var tsplit = 0;
        var tcsplit = 0;
        for(var i=0;i<this.itemList.length;i++){
            index = i+1;
            if(this.itemList[i].userId == ''){
                this.showToast('Team Member', 'Please enter value at row '+index, 'error', 'pester');
                isValid = false;
            }
            tsplit = tsplit+this.itemList[i].splitperc;
            tcsplit = tcsplit+this.itemList[i].cperc;
        }
        if(tsplit < 100 ){
            this.showToast('Booking Split(%)', 'Total Booking Split(%) cannot be less than 100', 'error', 'pester');
            isValid = false;
        }
        //Commented SAL25-668
        /*if(tcsplit < 100 || tcsplit > 150 ){
            this.showToast('Commission/Credit Split(%)', 'Total Commission/Credit Split(%) value can only between 100 & 150', 'error', 'pester');
            isValid = false;
        }*/
        if(tsplit > 100 ){
            this.showToast('Booking Split(%)', 'Total Booking Split(%) cannot exceed 100', 'error', 'pester');
            isValid = false;
        }
        if(this.oppStageName == '6 PO With Channel' && this.isSplitException){
            this.showToast('', 'Cannot create a split exception after Opportunity reaches 6 PO With Channel', 'error', 'pester');
            isValid = false;
        }
        this.spliOppList =  [{ splitopp: {} }];
        if(isValid){
            for(var i=0;i<this.itemList.length;i++){
                if(i == 0){
                    this.primaryopp = this.itemList[i].opp; 
                    this.primaryopp.Split_percentage__c = this.itemList[i].splitperc;
                    this.primaryopp.Commission_Credit_Split_Split_screen__c = this.itemList[i].cperc;
                }else{
                    if(i > 1){ //allocate memory
                        var newItem = [{ splitopp: {Id : null, ownerID : '',Split_percentage__c : 0},  index : i}];
                        this.spliOppList = this.spliOppList.concat(newItem);
                    }
                    this.spliOppList[i-1].splitopp = this.itemList[i].opp;
                    this.spliOppList[i-1].splitopp.Id = this.itemList[i].opp.Id;
                    this.spliOppList[i-1].splitopp.ownerID = this.itemList[i].userId;
                    this.spliOppList[i-1].splitopp.split_percentage__c = this.itemList[i].splitperc;
                    this.spliOppList[i-1].splitopp.Commission_Credit_Split_Split_screen__c = this.itemList[i].cperc;
                    this.spliOppList[i-1].index = i;
                }
            }
            console.log('this.spliOppList');
            console.log(this.spliOppList);
            this.showLoader = true;
            saveItem({
                'primaryOpp' : this.primaryopp,
                'jsonwrapperList' : JSON.stringify(this.spliOppList),
                'newoptyTotalValue' : this.newoptyTotalValue,
                'staticAmount' : this.staticAmount,
                'prevOwnerIdList' : this.previousOwnerId,
                'isglobal' : this.isglobal,
                'isSplitException' : this.isSplitException

            }).then(result => {
                this.showLoader = false;
                console.log(' save splits..!');         
                console.log(this.primaryopp.Id);
                if(result === true){
                     this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                             recordId : this.primaryopp.Id,
                             actionName : 'view'
                        }
                    }); 
                }
            }).catch(error => {
                this.showLoader = false;
                console.log('error..!', error);
                this.showToast('', error.body.message, 'error', 'pester');
            }); 
        }
    }
    
    handleCancel(event){ 
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    showToast(title, message, variant, mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(event);
    } 
}