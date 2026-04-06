import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSobjectList from '@salesforce/apex/LCC_JSMQueryResultService.executeQuery';

const columns = [
  {
    label: 'Order Item',
    fieldName: 'oiURL',
    type: 'url',
    typeAttributes: {
      label: {
        fieldName: 'OrderItemNumber',
      },
    },
  },
  {
    label: 'Product Name',
    fieldName: 'prodURL',
    type: 'url',
    typeAttributes: {
      label: {
        fieldName: 'Product_Name__c',
      },
    },
  },
  {
    label: 'Start Date',
    fieldName: 'Support_Start_Date__c',
    type: 'date',
    typeAttributes: {
      day: 'numeric',
      month: 'numeric',
      year: 'numeric',
    },
  },
  {
    label: 'End Date',
    fieldName: 'Support_End_Date__c',
    type: 'date',
    typeAttributes: {
      day: 'numeric',
      month: 'numeric',
      year: 'numeric',
    },
  },
];

const THIRD_PARTY_HARDWARE = new Set(['DELL', 'UCS', 'HPE']);

export default class MissingManufacturingEntitlement extends LightningElement {
  columns = columns;
  @track OIwithoutManfacturingENTs = [];
  @track startDate;
  @track endDate;
  @track datesError = '';
  cmpErrorMsg;
  showTable;
  showSpinner;
  disableFilterBTN = false;

  connectedCallback() {
    this.calculateQuarterDates();
    this.handleFilterClick();
    //this.fetchOrderItems();
  }
  calculateQuarterDates() {
    const today = new Date();
    const currentMonth = today.getMonth();

    let startMonthQuarter;
    if (currentMonth >= 2 && currentMonth <= 4) { // February - April
      startMonthQuarter = 2; // February
    } else if (currentMonth >= 5 && currentMonth <= 7) { // May - July
      startMonthQuarter = 5; // May
    } else if (currentMonth >= 8 && currentMonth <= 10) { // August - October
      startMonthQuarter = 8; // August
    } else { // November - January
      startMonthQuarter = 11; // November
    }
    console.log('startMonthQuarter', startMonthQuarter);
    const qtStartDate = new Date(today.getFullYear(), startMonthQuarter - 1, 1);
    const qtEndDate = new Date(today.getFullYear(), startMonthQuarter + 2, 0);
    this.formatDates(qtStartDate, qtEndDate);
  }

  formatDates(qtStartDate, qtEndDate) {
    const today = new Date();
    const offset = today.getTimezoneOffset();

    if (qtStartDate) this.startDate = new Date(qtStartDate.getTime() - offset * 60000).toISOString().split('T')[0];
    if (qtEndDate) this.endDate = new Date(qtEndDate.getTime() - offset * 60000).toISOString().split('T')[0];
  }

  validateDates(event) {
    const { label, value } = event.target;
    const dateObject = new Date(value);
    if (label === 'Start Date') {
      this.formatDates(dateObject, undefined);
    } else if (label === 'End Date') {
      this.formatDates(undefined, dateObject);
    }

    console.log('### validateDates this.startDate', this.startDate);
    console.log('### validateDatesthis.endDate', this.endDate);

    if (this.endDate < this.startDate) {
      this.datesError = 'The End Date should not be lesser than the Start Date';
      this.disableFilterBTN = true;
    } else {
      this.datesError = '';
      this.disableFilterBTN = false;
    }
  }

  handleFilterClick() {
    this.fetchOrderItems();
  }

  fetchOrderItems() {
    console.log('this.startDate', this.startDate);
    console.log('this.endDate', this.endDate);
    this.showSpinner = true;
    this.showTable = false; 
    this.OIwithoutManfacturingENTs = [];
    var orderItemQuery =
      'SELECT Id, Support_Start_Date__c, Support_End_Date__c, LastModifiedDate, ' +
      "(SELECT Id FROM Entitlements__r WHERE Type = 'Manufacturing Entitlement' LIMIT 1), " +
      'OrderItemNumber, Product_Name__c, Product2.Id, Product2.Product_Type__c, ' +
      'Product2.Product_Level__c, Product2.Family, Product2.Bundle_Features__c, ' +
      'Product2.License_Type__c, Product2.Product_Subtype__c, SBQQ__SegmentIndex__c, ' +
      'Product2.MSP_Std_Actual__c, Product2.ProductCode, SBQQ__QuoteLine__c, Product2.License_Category__c ' +
      'FROM OrderItem ' +
      'WHERE ((NOT Product2.Product_Subtype__c IN (\'Scale MSP\', \'On Demand\', \'Ondemand Above Reserve\', \'Ondemand Sub Reserve\')) OR  Product2.License_Category__c != \'SAAS\') AND Order.Order_Status__c = \'Shipped\' AND DAY_ONLY(LastModifiedDate) >= ' + this.startDate + ' AND DAY_ONLY(LastModifiedDate) <= ' + this.endDate+ ' ORDER BY LastModifiedDate DESC';

    console.log('orderItemQuery', orderItemQuery);
    getSobjectList({ theQuery: orderItemQuery })
      .then((OIResult) => {
        console.log('OIResult length : ', OIResult.length);
        console.log('OIResult : ', OIResult);

        OIResult.forEach((OI) => {
          
          if (
            !OI.Entitlements__r &&
            OI.Product2 &&
            ((OI.Product2.Product_Type__c && OI.Product2.Product_Type__c === '3rd Party Hardware' && OI.Product2.Family && THIRD_PARTY_HARDWARE.has(OI.Product2.Family)) ||
              (OI.Product2.Product_Type__c && OI.Product2.Product_Type__c === 'RCDM') ||
              (OI.Product2.Product_Level__c &&
                (OI.Product2.Product_Level__c === 'Hybrid Software' || OI.Product2.Product_Level__c === 'OnPrem' || !OI.Product2.Product_Level__c) &&
                OI.Product2.Family &&
                OI.Product2.Family === 'Rubrik Scale') ||
              (OI.Product2.Family && OI.Product2.Family === 'Third Party License') ||
              (OI.Product2.Product_Type__c &&
                OI.Product2.Product_Type__c === 'MSP' &&
                OI.Product2.Family &&
                OI.Product2.Family === 'RCDM' &&
                OI.SBQQ__SegmentIndex__c &&
                OI.SBQQ__SegmentIndex__c === 1 &&
                //OI.MSP_Std_Actual__c &&
                OI.Product2.MSP_Std_Actual__c != 'MSP Actual & Overage') ||
                (OI.Product2.ProductCode.includes('RSVX') &&
                  OI.Product2.Product_Subtype__c === 'Scale MSP' && 
                  OI.Product2.Product_Level__c === 'Hybrid Software'
                )
              )
          ) {
            const newOI = {
              ...OI,
              oiURL: '/' + OI.Id,
              prodURL: '/' + OI.Product2.Id,
            };
            this.OIwithoutManfacturingENTs = [...this.OIwithoutManfacturingENTs, newOI];
          }
        });
        
        this.showSpinner = false;
        if (this.OIwithoutManfacturingENTs.length > 0){
          this.showTable = true;
          this.cmpErrorMsg = '';
        }else{
          this.cmpErrorMsg = 'No Records Found';
        };
      })
      .catch((error) => {
        this.showSpinner = false;
        console.log('An error occurred:', error.body ? error.body.message : error.message);
        if(error.body.message.includes('Too many query rows:')){
          this.showToast('Error', 'Minumum Date Range', 'The selected date range is hitting system limit. Please reduce the date range and try again');
        }else{
        this.cmpErrorMsg = error.body ? error.body.message : error.message;
        }
      });
  }

  showToast(variant, title, message) {
    const event = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant,
        mode: 'dismissable'
    });
    this.dispatchEvent(event);
  }
}