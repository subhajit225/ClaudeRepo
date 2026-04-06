import { LightningElement, api, track, wire } from 'lwc';
import getRelatedQuoteLines from '@salesforce/apex/PaymentScheduleCtrl.getRelatedQuoteLines';
import createPayment from '@salesforce/apex/PaymentScheduleCtrl.createPayment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updatePaymentAmount from '@salesforce/apex/PaymentScheduleCtrl.updatePaymentAmount'
import updateStatus from '@salesforce/apex/PaymentScheduleCtrl.updateStatus'
import workbook from "@salesforce/resourceUrl/writeexcelfile";
import { loadScript } from "lightning/platformResourceLoader";
//import { RefreshEvent } from "lightning/refresh";
//import STATUS_FIELD from '@salesforce/schema/SBQQ__Quote__c.ApprovalStatus__c';
export default class PaymentSchedule extends LightningElement {
    @track lstQuoteLines = [];
    @track quoteId;
    @api recordId;
    @track confirmationModal = false;
    @track invoiceCount = '';
    @track quoteLineId;
    @track termValue;
    @track sStatus;
    @track sQuoteName;
    @track bPaymentScheduleconfirmationModal = false;
    @track isLoading = false;
    @track paymentsPresent = false;
    @track paymentOption = '';
    @track mapAmountValue = new Map();
    @track mapOverrideAmountValue = new Map();
    @track mapMonthlyValue = new Map();
    @track statusQoutelineMap = new Map();
    @track lstUpdateStatusQuoteline = new Set();
    @track monthlyAmount = '';
    @track maxTerm = 1;
    @track overrideTotal = 0;
    @track tempStatus = '';
    @track paymentLineStatus = 'Draft';
    @track bTempStatus = false;
    @track index;
    @track netTotal = 0;
    @track disableSaveBtn = false;
    @track quoteTotal = 0;
    @track paymentObj = {
        paymentOne: 0,
        paymentTwo: 0,
        paymentThree: 0,
        totalPayment: 0,
        labelTwo: 'Payment 2',
        labelTwoBillingTerm: 'Payment 2 Billing Term',
    };
    @track statusOptions = [
        { label: 'Draft', value: 'Draft' },
        { label: 'Approved', value: 'Approved' }
    ];
    @track statusChanged = false;
    @track warningMessage = '';
    @track showErrorMessage = false;
    @track paymentScheduleData = {}

    @track disableCSS =  'slds-size_8-of-12 slds-m-left_x-small';

    columnHeader = ['Product/ Qli', 'Term', 'Qty', 'Unit List', 'Discount', 'Net Total', 'Monthly Amount', 'Payment 1', 'Payment 2', 'Payment 3'];



    async connectedCallback() {
        console.log('recordId :::>' + this.recordId);
        //this.getQuoteLines();
        await loadScript(this, workbook);
    }
    get showModal() {
        return this.bPaymentScheduleconfirmationModal /*&& lstQuoteLines?.oQouteLine?.lstPaymentSchedule?.length>0*/;
    }
    get options() {
        return [{ label: 'Annually', value: 'Annual' }, { label: 'Monthly', value: 'Monthly' }, { label: 'Quaterly', value: 'Quarterly' }];
    }
    get bMakeFormReadonly() {
        let bStatus = false;


        this.lstQuoteLines?.map((ele) => {

            if (ele?.bUpdateStatus === true) {
                bStatus = true;
                this.paymentLineStatus = 'Approved'


            }
            else {
                bStatus = false;
                this.paymentLineStatus = 'Draft'
            }
        })


        return bStatus || this.bTempStatus;
    }

    get paymentNumber() {
        console.log('this.maxTerm :::>'+this.maxTerm);
        switch (this.paymentOption.toLowerCase()) {
            case 'monthly':
                return parseInt(this.maxTerm / 1);
               
                break;
            case 'annual':
                return parseInt(this.maxTerm / 12);
               
                break;
            case 'quarterly':
                return parseInt(this.maxTerm / 3);
                
                break;
            default:
            // code block
        }
    }

    getQuoteLines() {
        console.log('Inside QuoteLine');
        console.log('reccccId ::::>' + this.recordId);
        this.isLoading = true;
        getRelatedQuoteLines({ recordId: this.recordId })
            .then(result => {

                //console.log('result :::>' + JSON.stringify(result));
                this.bTempStatus = false;
                this.mapAmountValue = new Map();
                this.mapOverrideAmountValue = new Map();
                this.mapMonthlyValue = new Map();
                this.statusQoutelineMap = new Map();
                this.lstUpdateStatusQuoteline = new Set();
                result?.forEach(res => {
                    this.netTotal = res.netTotal != null ? res.netTotal : '';
                    res.quoteLine.recordId = res.quoteLine.Id;
                    res.quoteLine.Id = `/lightning/r/SBQQ__QuoteLine__c/${res.quoteLine.Id}/view`;

                    if (res?.quoteLine?.SBQQ__SubscriptionTerm__c > this.maxTerm) {
                        this.maxTerm = res?.quoteLine?.SBQQ__SubscriptionTerm__c;
                    }
                    res.monthlyAmount = res.quoteLine.SBQQ__NetTotal__c / 1;
                    if ('SBQQ__SubscriptionTerm__c' in res.quoteLine) {

                        res.monthlyAmount = res?.quoteLine?.SBQQ__NetTotal__c / res?.quoteLine?.SBQQ__SubscriptionTerm__c

                    }
                });

                let totalAmount = 0;
                this.lstQuoteLines = result;
                this.paymentScheduleData = result;
                this.quoteTotal = this.lstQuoteLines[0].netTotal;
                console.log('paymentScheduleData :::>' + JSON.stringify(this.paymentScheduleData));
                this.lstQuoteLines.forEach((ele) => {
                    if (ele?.lstPaymentSchedule?.length > 0) {
                        this.paymentsPresent = true;

                    }
                    let lenghtOfPayment = ele?.lstPaymentSchedule?.length;
                    let total = 0;
                    let overRideTotal = 0;

                    ele.lstPaymentSchedule?.forEach((payment, index) => {
                        if (payment?.Payment_Option__c?.length > 0) {
                            this.paymentOption = payment.Payment_Option__c;

                        }
                        if (payment?.Number_of_Invoices__c?.length > 0) {
                            this.invoiceCount = payment?.Number_of_Invoices__c;
                        }
                        payment.redirectUri = `/lightning/r/Payment_Schedule__c/${payment.Id}/view`;

                        if (index == 1 && lenghtOfPayment > 3) {
                            payment.index = `2-${lenghtOfPayment - 1}`;
                            this.index = `2-${lenghtOfPayment - 1}`;
                            payment.display = true;
                            payment.updateAll = true;
                            payment.readOnly = true;
                            //two += Number(payment?.Payment__c);
                        }


                        else if (index == lenghtOfPayment - 1 && lenghtOfPayment > 3) {
                            payment.index = lenghtOfPayment;
                            //payment.index = lenghtOfPayment;
                            this.index = lenghtOfPayment;
                            payment.display = true;
                            payment.readOnly = false;
                            //three += Number(payment?.Payment__c);
                        }
                        else if (index > 1 && lenghtOfPayment > 3) {

                            payment.display = false;
                            payment.readOnly = false;
                            //two += Number(payment?.Payment__c);
                        }
                        else {
                            payment.index = index + 1;
                            payment.display = true;
                            payment.readOnly = false;
                            //one += Number(payment?.Payment__c);
                        }

                        total += Number(payment?.Payment__c);
                        totalAmount += total;
                        overRideTotal += Number(payment?.Override_Amount__c);

                    })
                    ele.monthlyTotal = total;
                    ele.overRideTotal = overRideTotal;
                    this.calaculateTabledata();
                });

                
                this.sStatus = result[0].quoteLine.SBQQ__Quote__r.SBQQ__Status__c;
                console.log('sStatus :::>' + this.sStatus);
                this.tempStatus = this.sStatus;
                //});

                this.sQuoteName = result[0].quoteLine.SBQQ__Quote__r.Name;
                this.sQuoteLink = `/lightning/r/SBQQ__Quote__c/${result[0].quoteLine.SBQQ__Quote__r.Id}/view`;
                this.error = undefined;
            })
            .catch(error => {
                console.log('errr:::>' + JSON.stringify(error));
                console.log(JSON.stringify(error))
                this.error = error;
                //this.accounts = undefined;
            }).finally(() => {
                this.isLoading = false;
            })
    }

    calaculateTabledata() {
        let one = 0
        let two = 0
        let three = 0;
        let lenghtPaymentSchedule = 0;

        this.lstQuoteLines.forEach((ele) => {
            lenghtPaymentSchedule =  ele.lstPaymentSchedule?.length;
            ele.lstPaymentSchedule?.forEach((payment, index) => {
                if (lenghtPaymentSchedule === 2) {
                    if (index === 0) {
                        one += Number(payment?.Override_Amount__c || 0);
                    } else if (index === 1) {
                        two += Number(payment?.Override_Amount__c || 0);
                    }
                }else{
                    if (index == 0) {
                        one += Number(payment?.Override_Amount__c)
                    }
                    else if (index === ele.lstPaymentSchedule.length - 1) {
                        three += Number(payment?.Override_Amount__c)
                    }
                    else {
                        two += Number(payment?.Override_Amount__c)
                    }
                }
            })
        })
        this.paymentObj.paymentOne = one;
        this.paymentObj.paymentTwo = two;
        this.paymentObj.paymentThree = three;
        this.paymentObj.totalPayment = one + two + three;
        if(lenghtPaymentSchedule>3){
        this.paymentObj.labelTwo = `Payment 2 - ${lenghtPaymentSchedule-1}`;
        this.paymentObj.labelTwoBillingTerm = `Payment 2 - ${lenghtPaymentSchedule-1} Billing Term`;
        console.log('this.paymentObj.labelTwo :::>'+this.paymentObj.labelTwo);
        }else{
            this.paymentObj.labelTwo = `Payment 2`; 
            this.paymentObj.labelTwoBillingTerm = `Payment 2 Billing Term`;
        }
    }

    increaseValue(event) {
        var value = parseInt(this.template.querySelector(".number").value, 10);
        value = isNaN(value) ? 0 : value;
        value++;
        this.template.querySelector(".number").value = value;
        let qId =
            console.log('qId :::>' + qId);
        this.confirmationModal = true;
    }

    decreaseValue() {
        var value = parseInt(this.template.querySelector(".number").value, 10);
        value = isNaN(value) ? 0 : value;
        value < 1 ? value = 1 : '';
        value--;
        this.template.querySelector(".number").value = value;
    }
    handleTermChange(event) {
        this.confirmationModal = true;
        this.quoteLineId = JSON.stringify(event.target.dataset.donkey);
        this.termValue = Event.target.value;

    }

    handleConfirmClick() {
        this.createPayments();

    }
    closeModal() {
        this.bPaymentScheduleconfirmationModal = false;
    }
    handleInvoiceChange(e) {
        this.invoiceCount = e.target.value;
        //
    }
    onSave() {
        if (this.paymentsPresent) {
            this.bPaymentScheduleconfirmationModal = true;
        }
        else {
            this.createPayments();
        }
    }
    createPayments() {
        this.isLoading = true;
        createPayment({ recordId: this.recordId, invoiceNumber: parseInt(this.invoiceCount), payment: this.paymentOption }).then((res) => {
            if (res.bSuccess) {
                this.showToast('Success', 'success', 'Payment schedules created successfully');
                this.getQuoteLines();
                this.warningMessage = '';
            }
            else {
                this.showToast('Error', 'error', res.errMessage);
            }
        }).catch((error) => {
            console.error(error);
            this.showToast('Error', 'error', 'Error occured while creating payment schedules');
        }).finally(() => {
            this.bPaymentScheduleconfirmationModal = false;
            this.isLoading = false;
        })
    }

    showToast(title, variant, message) {
        const event = new ShowToastEvent({
            title: title,
            variant: variant,
            message: message,

        });
        this.dispatchEvent(event);
    }

    handleAmountChange(e) {
        try {
            this.disableSaveBtn = false;
            let amount = e.target.value.length > 0 ? parseFloat(e.target.value) : 0;
            let recordId = e.target.dataset.id;
            let quouteLine = e.target.dataset.qouteline;
            let index = this.lstQuoteLines.findIndex((ele) => {
                return ele?.quoteLine?.recordId === quouteLine;
            });

            
            this.mapAmountValue.set(recordId, amount);
            if (index != -1) {
                console.log('here');
                let payments = this.lstQuoteLines[index]?.lstPaymentSchedule;
                let paymentIndex = payments.findIndex((ele) => {
                    return ele?.Id === recordId;
                });
                if (paymentIndex != -1) {
                    let term = this.lstQuoteLines[index]?.quoteLine?.SBQQ__SubscriptionTerm__c;
                    if (!term) {
                        term = 1;
                    }
                    payments[paymentIndex].Payment__c = Math.round(amount * (this.lstQuoteLines[index]?.quoteLine?.SBQQ__NetTotal__c / term)*100)/100;
                    payments[paymentIndex].Override_Amount__c = Math.round(amount * parseFloat(this.lstQuoteLines[index]?.quoteLine?.SBQQ__NetTotal__c / term)*100)/100;
                    payments[paymentIndex].Term__c = amount;
                    this.mapOverrideAmountValue.set(recordId, payments[paymentIndex].Override_Amount__c);
                    this.mapMonthlyValue.set(recordId, payments[paymentIndex].Payment__c);
                    let filledTerms = 0;
                    let filled = 0;
                    //quatrely 12 - filled ones \\ amount --> subscription term -filledterms ->30 /(qauterly- filled ones)
                    if (payments[0]?.Term__c != null) {
                        filledTerms += parseFloat(payments[0]?.Term__c);
                        filled += 1;
                    }
                    if (payments[payments.length - 1]?.Term__c != null) {
                        filledTerms += parseFloat(payments[payments.length - 1]?.Term__c);
                        filled += 1;
                    }
                    for (let i = 0; i < payments.length; i++) {
                        if (payments.length > 3) {
                            if (i === 0 || i === payments.length - 1) {

                                continue;

                            }
                            else {


                                payments[i].Term__c = (term - filledTerms) / (parseInt(this.invoiceCount) - filled);
                                console.log(payments[i].Term__c)
                                payments[i].Payment__c = Math.round(payments[i].Term__c * parseFloat(this.lstQuoteLines[index]?.quoteLine?.SBQQ__NetTotal__c / term)*100)/100;
                                payments[i].Override_Amount__c = Math.round(payments[i].Term__c * parseFloat(this.lstQuoteLines[index]?.quoteLine?.SBQQ__NetTotal__c / term)*100)/100;
                                this.mapOverrideAmountValue.set(payments[i].Id, payments[i].Override_Amount__c);
                                this.mapMonthlyValue.set(payments[i].Id, payments[i].Payment__c);
                                this.mapAmountValue.set(payments[i].Id, payments[i].Term__c);
                            }
                        }
                    }
                }
            }
            console.log(this.mapMonthlyValue);
            this.calculateTotal();
        } catch (err) {
            console.error(err)
        }

    }
    handleOverrideAmountChange(e) {
        this.disableSaveBtn = false;
        let amount = parseFloat(e.target.value);
        //amount = amount.toFixed(2);
        let recordId = e.target.dataset.id;
        let updateAll = e.target.dataset.update;
        let quouteLine = e.target.dataset.qouteline;

        let arr = this.lstQuoteLines.filter((ele) => {
            return ele?.quoteLine?.recordId === quouteLine;
        });

        let payments = arr[0]?.lstPaymentSchedule;
        if (updateAll && quouteLine) {

            for (let i = 1; i < payments.length - 1; i++) {

                this.mapOverrideAmountValue.set(payments[i].Id, amount);
                payments[i].Override_Amount__c = amount;

            }


        } else {
            let index = payments.findIndex(ele => ele?.Id === recordId)
            this.mapOverrideAmountValue.set(recordId, amount);
            payments[index].Override_Amount__c = Math.round(amount*100)/100;
        }

        this.calculateTotal();
    }
    handlePaymentOptionChange(e) {
        this.paymentOption = e.target.value;
        this.warningMessage = '*Please click on update button to reflect the changes';
        switch (this.paymentOption.toLowerCase()) {
            case 'monthly':
                this.invoiceCount = parseInt(this.maxTerm / 1);
                //this.createPayments();
                break;
            case 'annual':
                this.invoiceCount = parseInt(this.maxTerm / 12);
                //this.createPayments();
                break;
            case 'quarterly':
                this.invoiceCount = parseInt(this.maxTerm / 3);
                //this.createPayments();
                break;
            default:
        }

    }
    handleAmountSave() {
        this.statusChanged ? this.updateStatus() : this.updateAmount();

    }

    updateAmount() {
       
        this.isLoading = true;
        console.log(this.mapMonthlyValue);
        console.log(this.mapAmountValue);
        const obj = Object.fromEntries(this.mapAmountValue);
        const overrideObj = Object.fromEntries(this.mapOverrideAmountValue);
        const monthlyMap = Object.fromEntries(this.mapMonthlyValue)
        let jsonString = JSON.stringify(obj);
        console.log('jsonString :::>'+jsonString);
        let sOverrideAmount = JSON.stringify(overrideObj);
        console.log('sOverrideAmount :::>'+sOverrideAmount);
        console.log(':::::>>>>');
        console.log('monthlyMap ::::>'+JSON.stringify(monthlyMap));
        updatePaymentAmount({ jsonString: jsonString, sOverrideAmount: sOverrideAmount, sMonthlyValue: JSON.stringify(monthlyMap) }).then((res) => {
            if (res.bSuccess) {
                this.showToast('Success', 'success', 'Payment  Updated successfully');
                this.getQuoteLines();
                this.mapMonthlyValue = new Map();
                this.mapAmountValue = new Map();
                this.mapOverrideAmountValue = new Map();
            }
            else {
                if (!this.statusChanged) {
                    this.showToast('Error', 'error', res.errMessage);
                }
            }
        }).catch((error) => {
            console.error(error);
            this.showToast('Error', 'error', 'Error occured while updating payment');
        }).finally(() => {

            this.isLoading = false;
        })
        
    }

    calculateTotal() {
        console.log('here in total calcuaalte');
        this.lstQuoteLines?.forEach((ele) => {

            let total = 0;
            let overRideTotal = 0;
            ele.lstPaymentSchedule?.forEach((payment, index) => {
                total += Number(payment.Payment__c);
                overRideTotal += Number(payment.Override_Amount__c);
            })
            ele.monthlyTotal = total;
            ele.overRideTotal = overRideTotal;
            let netTotal = ele.quoteLine.SBQQ__NetTotal__c === NaN ? 0 : ele.quoteLine.SBQQ__NetTotal__c;
            console.log(`${Number(ele.overRideTotal)}       ${ele.quoteLine.SBQQ__NetTotal__c}`)
            //if (parseInt(ele.overRideTotal) > parseInt(ele.quoteLine.SBQQ__NetTotal__c)){ //changed 10/10/2024
            ele.overRideTotal = ele.overRideTotal === NaN ? 0 : ele.overRideTotal;
            if (parseFloat(ele.overRideTotal.toFixed(2)) > parseFloat(netTotal.toFixed(2))) {
                ele.showErrorMessage = true;
            } else {
                ele.showErrorMessage = false;
            }
        });
    }

    handleStatusChange(e) {
        this.disableCSS = 'slds-size_8-of-12 slds-m-left_x-small';
        this.statusChanged = true;
        this.tempStatus = e.target.value;
        let total = 0;
        if (this.tempStatus?.toLowerCase() === 'approved') {
            this.disableCSS = 'slds-size_8-of-12 slds-m-left_x-small disableCSS';
            this.lstQuoteLines?.forEach((ele) => {



                total += ele.overRideTotal;


            });

            console.log('Net TOtal>>>' + parseInt(this.netTotal));
            console.log('Net TOtal>>>' + parseInt(total));
            if (parseFloat(total.toFixed(2)) != parseFloat(this.netTotal.toFixed(2))) {
                this.disableSaveBtn = true;
                this.showToast('Error', 'error', 'Total Amount Should be equal to the Net Total on Quote, Please adjust and try again');
                this.tempStatus = 'Draft';
                this.template.querySelector('.statusCombobox').value = 'Draft'
                this.paymentLineStatus = 'Draft';
                this.disableCSS = 'slds-size_8-of-12 slds-m-left_x-small';
            }
            
        }

        this.lstQuoteLines?.forEach((ele) => {
           
            this.lstUpdateStatusQuoteline.add(ele?.quoteLine?.recordId);

        })

    }

    handleCancelClick() {
        this.getQuoteLines();
    }
    updateStatus() {
        this.isLoading = true;
        const array = Array.from(this.lstUpdateStatusQuoteline);
        console.table(array);
        let bValidationPassed = true;
        //this.validateData();
        if (bValidationPassed) {
            updateStatus({ lstQouteLineId: array, status: this.tempStatus }).then((res) => {
                if (res) {
                    console.log(res);
                    this.sStatus = this.tempStatus;
                    this.tempStatus === 'Approved' ? this.bTempStatus = true : '';
                    this.lstUpdateStatusQuoteline = new Set();

                    this.updateAmount();



                }
                else {
                    this.showToast('Error!', error, 'Error Updating Status');
                    this.isLoading = false;
                }

            }).catch((err) => {
                console.log(err);
            }).finally(() => {
                this.isLoading = false
            });
        } else {
            this.showToast('Error', 'error', 'Total Amount Should be equal to the Net Total on Quote, Please adjust and try again');
            this.isLoading = false;
        }
    }
    validateData() {
        console.log('Here in validate data');
        let bValidate = true;
        this.lstQuoteLines?.forEach((ele) => {

            let total = 0;
            let overRideTotal = 0;

            ele.lstPaymentSchedule?.forEach((payment, index) => {

                total += Number(payment.Payment__c);
                overRideTotal += Number(payment.Override_Amount__c);



            });
            console.log(`${parseInt(overRideTotal)}  ${ele?.quoteLine?.SBQQ__NetTotal__c} `);
            console.log(`${parseInt(total)}  ${ele?.quoteLine?.SBQQ__NetTotal__c} `);

            if (overRideTotal.toFixed(2) > ele?.quoteLine?.SBQQ__NetTotal__c.toFixed(2) || total.toFixed(2) > ele?.quoteLine?.SBQQ__NetTotal__c.toFixed(2) || total.toFixed(2) !== ele?.quoteLine?.SBQQ__Quote__r.SBQQ__NetAmount__c.toFixed(2)) {
                bValidate = false;

            }

        });
        return bValidate;
    }
    calculateTableData() {
        try {
            let one = 0;
            let two = 0;
            let three = 0;

            this.lstQuoteLines?.forEach((ele) => {
                if (ele?.lstPaymentSchedule?.length > 0) {
                    ele?.lstPaymentSchedule?.forEach((payment, index) => {
                        // Ensure that payment.Term__c is a number
                        let amount = payment?.Term__c || 0;

                        if (index === 0) {
                            one += amount;
                        } else if (index === ele.lstPaymentSchedule.length - 1) {
                            two += amount;
                        } else {
                            three += amount;
                        }
                    });
                }
            });

           
        }
        catch (error) {
            console.log('error in table data');
            console.log(error);
        }
    }

    async handleDownload() {
        try {
            await this.exportToExcel();
        } catch (err) {
            console.log(err);
        }
    }

    exportToExcel() {

        let sheetName = 'PaymentSchedules' + this.sQuoteName;
        let filename = 'PaymentSchedules' + this.sQuoteName + '.xlsx';
        let newPaymentSchedule = [];
        console.log('this.paymentScheduleData :::>' + JSON.stringify(this.paymentScheduleData));
        this.paymentScheduleData.forEach((oPaymentScheduleData) => {
            console.log('Inside For');
            let arrPaymentSchedules = [...oPaymentScheduleData.lstPaymentSchedule];
            let n = arrPaymentSchedules.length;
            let wrapper = {};
            wrapper.quoteNumber = this.sQuoteName
            wrapper.quoteTotal = this.quoteTotal;
            wrapper.product = oPaymentScheduleData.quoteLine?.SBQQ__Product__r.Name;
            wrapper.paymentOption = this.paymentOption;
            wrapper.term = oPaymentScheduleData.quoteLine?.SBQQ__SubscriptionTerm__c;
            wrapper.qty = oPaymentScheduleData.quoteLine?.SBQQ__Quantity__c;
            wrapper.unitList = oPaymentScheduleData.quoteLine?.SBQQ__ListPrice__c;
            wrapper.discount = oPaymentScheduleData.quoteLine?.SBQQ__TotalDiscountRate__c;
            wrapper.total = oPaymentScheduleData.quoteLine?.SBQQ__NetTotal__c;
            wrapper.monthlyAmount = oPaymentScheduleData.dMonthlyPayment;
            wrapper.p1 = arrPaymentSchedules[0]?.Override_Amount__c;
            wrapper.p1BillingTerm = arrPaymentSchedules[0]?.Term__c;
            wrapper.p2 = arrPaymentSchedules[1]?.Override_Amount__c !== undefined ? Math.round(arrPaymentSchedules[1]?.Override_Amount__c*100)/100 : 0;
            wrapper.p2BillingTerm = arrPaymentSchedules[1]?.Term__c !== undefined ? arrPaymentSchedules[1]?.Term__c : 0;
            if (n > 2) {
                wrapper.p3 = arrPaymentSchedules[n - 1]?.Override_Amount__c !== undefined ? (arrPaymentSchedules[n - 1]?.Override_Amount__c * 100) / 100 : 0;
                wrapper.p3BillingTerm = arrPaymentSchedules[n - 1]?.Term__c !== undefined ? arrPaymentSchedules[n - 1]?.Term__c : 0;
            }
            newPaymentSchedule.push(wrapper);
        });


        const workbook = XLSX.utils.book_new();
        const headers = [];
        const worksheetData = [];
        let nameToLabelMap = {
            "Quote Number": "quoteNumber",
            "Quote Total": "quoteTotal",
            "Product/ Qli": "product",
            "Payment Option": "paymentOption",
            "Term": "term",
            "Qty": "qty",
            "Unit List": "unitList",
            "Discount": "discount",
            "Net Total": "total",
            "Monthly Amount": "monthlyAmount",
            "Payment 1 Billing Term" : "p1BillingTerm",
            "Payment 1": "p1",
        }
        nameToLabelMap[this.paymentObj.labelTwoBillingTerm] = "p2BillingTerm";
        nameToLabelMap[this.paymentObj.labelTwo] = "p2";
        nameToLabelMap["Payment 3 Billing Term"] = "p3BillingTerm";
        nameToLabelMap["Payment 3"] = "p3";
        
        
        newPaymentSchedule.forEach((row) => {
            let rowObj = {};
            let paymentScheduleArray = [];
            for (let key in nameToLabelMap) {

                rowObj[key] = row[nameToLabelMap[key]];

            }
            	  
            worksheetData.push(rowObj);
        });
        //console.log(JSON.stringify(worksheetData))
        let rowObj = {};
        rowObj["Monthly Amount"] = 'Total';
        rowObj["Payment 1"] = this.paymentObj.paymentOne;
        rowObj[this.paymentObj.labelTwo] = this.paymentObj.paymentTwo;
        rowObj["Payment 3"] = this.paymentObj.paymentThree;
        worksheetData.push(rowObj);
        const worksheet = XLSX.utils.json_to_sheet(worksheetData, { header: headers });
        //console.log(worksheet)

        XLSX.utils.book_append_sheet(workbook, worksheet, sheetName);
        const excelBuffer = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });
        const blob = new Blob([excelBuffer], { type: 'application/octet-stream' })
        // Create a download link and click it programmatically to initiate the download
        const a = document.createElement('a');
        a.href = URL.createObjectURL(blob);
        a.download = filename
        a.click();
        // Release the object URL to free up memory
        URL.revokeObjectURL(a.href);
    }



    handleRecordChange(event) {
        console.log('console.log :::>' + event.detail.recordId);
        this.quoteId = event.detail.recordId;
        this.recordId = event.detail.recordId;
        this.getQuoteLines();
    }


}