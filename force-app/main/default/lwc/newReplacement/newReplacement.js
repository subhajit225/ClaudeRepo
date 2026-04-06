import { LightningElement, api, wire, track } from 'lwc';
import getEntitlements from '@salesforce/apex/ReplacementRefreshController.createWrapperData';
import currentUserExceptions from '@salesforce/apex/ReplacementRefreshController.currentUserExceptions';
import getSMSScreenErrorMessages from '@salesforce/apex/ReplacementQueryController.getSMSScreenErrorMessages';
import getPageSize from '@salesforce/apex/ReplacementQueryController.getSmsPageSize';
import getIntervals from '@salesforce/apex/QuoteExtController.getLowerAndUpperBound';//FY25SR-1745
import createQuote from '@salesforce/apex/ReplacementQuoteLineCreation.createNewQuoteLines';
import getQuoteDet from '@salesforce/apex/ReplacementQueryController.getQuoteDetails';
import getPreviousIbmData from '@salesforce/apex/ReplacementQueryController.getPreviousIbmData';
import getDisableBusinessLogic from '@salesforce/apex/ReplacementQueryController.getDisableBusinessLogic'; //FY25SR-1875
import getDispValues from '@salesforce/apex/ReplacementQueryController.getPicklistValuesDispositionQuote';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import MyModal from 'c/sKUNewReplacement';
import refreshModal from 'c/refreshPage';
import quotelineFieldApis from '@salesforce/apex/ReplacementQueryController.fetchDeletionQuoteLineFields';

import { addRow, deleteRow} from './addDeleteRows';
import { setDataOnLoad, formatDate, addMonthsToDate } from './setdataOnInitialLoad';
import { handleDisposition } from './dispositionChange';
import { dataValidity,checkIfErrorAdded, handleQuoteHeaderValidity, removeAllErrors, updateMismatchQuantityFlag} from './dataValidity'; 
import { handleTermChange } from './termChange';
import { handleAssetSelection } from './assetSelection';
import { handleRenewalDateChange } from './renewalDateChange'; 
import { handlecheckBoxSelection,handlecheckBoxSelectionAll,appedCurrentPageDataOnSelectAll } from './checkboxSelection'; 
import { handleQuanChange } from './quantityChangeForNonAssetBasedEnts';
import { assignEntDataToSku, handleSkuAssignment } from './newRepSkuUtility'; 
import { dataFilter } from './filterDataNewRep'; 
import { endDateFilterChangeEnts } from './dataFilterChangeSelectedEnt';
import {mergePrefilData, refreshReconstructionPrep, seggregateDataForPage, getSelectedEntitlements, createRefreshAssetList} from './reconstructionHelper'; 
import { handleSKUPaymentSwitch } from './skuPaymentSwitchUtility';
import { handleSelectedAssetChange, hanleDeleteRow, handleAddRow} from './assetSelectionwithAddDeleteRow';
import { filterRefreshData, handleReplaceAfterRefresh, handleOnRefresh, refreshAssetsReconstruct} from './refreshHelper';
import { exceptionMapping } from './exceptionHelper.js';
import { getSelectedEnt, getSelectedCustomIdex } from './alreadySelectedEnt.js';

import Email from '@salesforce/user/Id';
import MandatoryImage from '@salesforce/resourceUrl/MandatoryImage';
import allSMSExceptions from '@salesforce/label/c.All_SMS_Exceptions';


export default class NewReplacement extends NavigationMixin(LightningElement) {
  @api entitlementSearchString;
  @api startDate;
  @api entitlementOrderNumberSearchString;
  @api entitlementAssetSearchString;
  @api endDate;
  @api oppRecordId;
  @api accRecordId;
  @api wrapperDataFromDispositionUi;    // this is the disposition data coming from disposition UI
  @api wrapperDataForReplacementUi;     // this is the previously modified replacement data coming back from disposition ui
  @api modifiedIdFromDisposition;
  @api quoteCreateDate;
  @track showHeader = true;
  @track data;
  @track dataModified;
  @track showDisposition = false;
  @track dispositionValues;
  @track addboolean = false;
  @api conlist = [];
  @track showSpinner = true;
  @track currentPageData = [];
  @track sortField;
  @track sortAscending = true;
  @track totalRecords;
  @api displaymodel = false;
  @track showShoppingCart = false;
  @track skuOptionsAvail;
  @track currSKUCustomIndex;
  @track currSKUID;
  @track currSKUvalue;
  @track currSKUoptions;
  @track prdTypeOptions;
  @track prdLicTypeOptions;
  @track prdlicCatoptions;
  @track prdtypeval;
  @track prdlictypeval;
  @track prdlicCatval;
  @track editionMappingValues;
  @track replacementPolicyGridValues;
  @api quoteIdOrginial;
  @track baseURL;
  @track quoteDetails;
  @track modifiedIds = [];
  @track quoteDatebackThree;
  @track quoteDateFwTwelve;
  @track ibmData;
  @track updatedDataModified;
  @track runFilterData = true;
  @api errorMessagesValues = new Map();
  //@api errorSreenMessages;
  @track endDateModified = false;
  @track previousDataModified;
  @track initalLoadData;
  @api dispositionpicklistoptions;  //FY25SR-1373
  @api fullSelected; //FY25SR-1373
  @track massDispositionValue = '';//CPQ22-6009
  @track massTermValue;
  @track massEndDate;
  @track numberValue;
  @track selectedDate;
  @track disableSaveButton = false;
  @api filteredDataForPages = [];
  @api totalCountForPages = 0; // FY25SR-1374
  @api pageSizeFromMetadata; // FY25SR-1374
  @api pageKey;  // FY25SR-1374
  @track currentPage = 1;
   selectedEntitlements = [];
  //refresh
  @track refreshData = [];
  productList = [];
  optionsMap = new Map();
  isREQuote = false;
  lowerBound;//FY25SR-1745
  upperBound;//FY25SR-1745
  @api doNotConsolidateUI = false; //FY25SR-1124
  @api replaceAnyToAnyUI = false; //FY25SR-1124
  @api exceptionMessages = [];
  @api exceptionlabel = 'Exceptions';
  @api modalResult;
  @api isMismatchQTY = false;//FY25SR-1124
  @track misMatchExcep = false; //CPQ22-6039
  exceptionComments = '';
  allExceptions = allSMSExceptions;
  isDealOPs = false;
  disableValidations = false; //FY25SR-1875
  refreshUrl; //FY25SR-2245
  quotelineFieldApi = [];//FY25SR-2361
  @track qtName = ''; //MS CPQ22-6072
  @track accName = ''; //MS CPQ22-6072
  @track credCalcDate; //MS CPQ22-6072
  @track entitlementFilter = '';

  get entitlementFilterOptions() {
    return [
      { label: 'All Entitlements', value: 'ALL' },
      { label: 'Show only HW support', value: 'HW_ONLY' },
      { label: 'Hide HW support', value: 'HIDE_HW' }
    ];
  }
  //refactored
  async connectedCallback() {
    this.refreshUrl = MandatoryImage + '/refresh.png';//FY25SR-2245
    this.baseURL = window.location.origin;
    this.fullSelected = false;
    this.showSpinner = true;
    let dispVal;
    // let quotedet = await getQuoteDet({qd : this.quoteIdOrginial})
    await getQuoteDet({qd : this.quoteIdOrginial})
    .then(result => {
      this.quoteDetails = result;
      this.qtName = result && result.Name ? result.Name : 'Quote';
      this.accName = result && result.SBQQ__Account__r && result.SBQQ__Account__r.Name ? result.SBQQ__Account__r.Name : 'Account';
      this.credCalcDate = result && result.Credit_Calculation_Start_Date__c ? result.Credit_Calculation_Start_Date__c : '';
    })
    .catch(error => {
      this.error = error;
      this.handleCatch(false, error, true);
    });
    this.isREQuote = this.quoteDetails.SBQQ__Type__c == 'Renewal+Expansion' ? true : false;
    await getDispValues({qType : this.quoteDetails.SBQQ__Type__c, drType : 'Manual'})
    .then(result => {
      dispVal = result;
    })
    .catch(error => {
      this.error = error;
      this.handleCatch(false, error, true);
    });
    try{
      if(dispVal != undefined){
        let options = [];
        dispVal.forEach(pick =>{
            options.push({
              label : pick.label,
              value : pick.value,
              selected : pick.selected
            })
        });
        this.dispositionpicklistoptions = options;
      }
      this._defaultDateFilters(this.quoteDetails);
    } catch(error){
      this.error = error;
      this.handleCatch(false, error, false);
    }
    
    //FY25SR-1124 - start
    //User enabled exceptions
    let exceptionsDataResponse ;
    await currentUserExceptions()
    .then(result => {
      exceptionsDataResponse = result;
    })
    .catch(error => {
      this.error = error;
      this.handleCatch(false, error, true);
    });
    try{
      let exceptionsResponse = [];
      if(exceptionsDataResponse) {
        if(exceptionsDataResponse.Exception_Message__c != undefined && exceptionsDataResponse.Exception_Message__c != null && exceptionsDataResponse.Exception_Message__c != '') {
          exceptionsResponse = JSON.parse(JSON.stringify(exceptionsDataResponse.Exception_Message__c)).split(',');
          this.isDealOPs = exceptionsDataResponse.Is_Deal_Ops__c ? true : false;
          this.exceptionInitHandler(this.quoteDetails, exceptionsResponse, exceptionsDataResponse.Is_Deal_Ops__c);
          if(this.exceptionMessages.length > 0){
            this.exceptionMessages.forEach(item =>{
              if(this.isEqualStrings(item.value,'Replace Any to Any') && item.selected == true){
                  this.replaceAnyToAnyUI = true;
              }
              if(this.isEqualStrings(item.value,'Do Not Consolidate Replacement Lines') && item.selected == true){
                  this.doNotConsolidateUI = true;
              }
              if(this.isEqualStrings(item.value,'Mismatch Quantity') && item.selected == true){
                  this.isMismatchQTY = true;
              }
            });
          }
        }
      }
    } catch(error) {
      this.error = error;
      this.handleCatch(false, error, false);
    }

    //FY25SR-1124 - End
    await getSMSScreenErrorMessages()
    .then(result => {
      let errorMessages = result;
      this.errorMessagesValues = JSON.parse(JSON.stringify(errorMessages));
    })
    .catch(error => {
      this.error = error;
      this.handleCatch(false, error, true);
    });

    await getPageSize() // FY25SR-1374, CPQ22-6039
    .then(result => {
      if(result.mismatchexcep != undefined && result.mismatchexcep === 'mismatch found'){
          this.misMatchExcep = true;
      }
      if(result.pagesize != undefined){
          this.pageSizeFromMetadata = result.pagesize;// FY25SR-1374
      }else{
          this.pageSizeFromMetadata = 10; 
      }
    })
    .catch(error => {
      this.error = error;
      this.handleCatch(false, error, true);
    });
    //FY25SR-2361 - start
    await quotelineFieldApis()
    .then(result => {
      this.quotelineFieldApi = result;
    })
    .catch(error => {
      this.error = error;
      this.handleCatch(false, error, true);
    })
    //FY25SR-2361 - End
    await getDisableBusinessLogic()//FY25SR-1875 - Disable Validations for current user
    .then(result => {
      this.disableValidations = result;
    })
    .catch(error => {
      this.error = error;
      this.handleCatch(false, error, true);
    }); 
    
    let alreadySel ;
    if (!this.wrapperDataForReplacementUi || this.wrapperDataForReplacementUi.length == 0) {
      await getPreviousIbmData({ quoteId: this.quoteIdOrginial })
      .then(result => {
        this.ibmData = result;
      })
      .catch(error => {
        this.error = error;
        this.handleCatch(false, error, true);
      });
      try {
        this.selectedEntitlements = getSelectedEntitlements(this.ibmData);
      } catch(error) {
        this.error = error;
        this.handleCatch(false, error, true);
      }
      
      let skipCustom;
      //FY25SR-2395 - Name correction
      let entlResult;
      await getEntitlements({ quoteDetail: this.quoteDetails, startDate : this.quoteDatebackThree, endDate : this.quoteDateFwTwelve , selectedEnts : this.selectedEntitlements, alreadySelEnt : alreadySel, skipCustomIndex : skipCustom})
      .then(result => {
        entlResult = result;
      })
      .catch(error => {
        this.error = error;
        this.handleCatch(false, error, true);
      });
      try{
        this.dataModified = setDataOnLoad(entlResult , this.quoteDetails.SBQQ__Type__c, this.disableValidations);
        // Added for FY25SR-1569 - START
        this.dataModified = this.setImagesOnList(this.dataModified);
        // Added for FY25SR-1569 - END
      } catch(error) {
        this.error = error;
        this.handleCatch(false, error, false);
      }
      try {
        if (!this.dataModified) return;
            this.updatedDataModified = JSON.parse(JSON.stringify(this.dataModified));
            if (this.ibmData && this.ibmData.length) { 
              let imbDataMap = seggregateDataForPage(this.ibmData);     
              if(imbDataMap.has('Replacement') && imbDataMap.get('Replacement').length) {
                this.updatedDataModified = mergePrefilData(this.updatedDataModified, imbDataMap.get('Replacement'), this.doNotConsolidateUI, this.replaceAnyToAnyUI, this.quoteDetails.SBQQ__Type__c);
                // Added for FY25SR-1569 - START
                this.updatedDataModified = this.setImagesOnList(this.updatedDataModified);
                // Added for FY25SR-1569 - END
                this.dataModified = this.updatedDataModified;
              }   

              //FY25SR-1176 start moved below replacment to allow populating replaced product in entitlement data
              if(imbDataMap.has('Refresh') && imbDataMap.get('Refresh').length) {
                this.createOptionData(this.updatedDataModified);
                let refreshedAssetList = createRefreshAssetList(imbDataMap.get('Refresh'));
                this.dataModified = refreshAssetsReconstruct(this.updatedDataModified, refreshedAssetList, this.refreshUrl);//FY25SR-2245
                this.refreshData = refreshReconstructionPrep(imbDataMap.get('Refresh'), this.optionsMap, this.productList);
              }  
              //FY25SR-1176 end 
            }
      } catch (error) {
        this.error = error;
        this.handleCatch(false, error, false);
      }
    } else {
      this.dataModified = this.wrapperDataForReplacementUi;
    }
    try{
      this.initalLoadData = this.dataModified;
      //FY25SR-1875 - start
      /* if(this.initalLoadData.length <= 0){
        let url = this.baseURL + '/apex/sbqq__sb?id=' + this.quoteIdOrginial;
        window.location.href = url;
      }*/
      //FY25SR-1875 - End
      // FY25SR-1374 START
      this.totalCountForPages = this.dataModified.length 
      this.filteredDataForPages = this.dataModified; 
      this.updateCurrentPageData(1,this.pageSizeFromMetadata);
      this.updatePageRecords();
      // FY25SR-1374 END
      this.showSpinner = false;
    } catch(error) {
      this.error = error;
      this.handleCatch(false, error, false);
    }
  }
  //FYSR25-1124 start
  exceptionInitHandler(quoteDetail, enabledExceptions, isDealOps) {
    try{
      this.message = '';
      this.showmsg = false;
    if(quoteDetail) {
      if(isDealOps) {
        if(quoteDetail.RWD_Deal_Ops_Exception_Justification__c) {
          this.exceptionComments = quoteDetail.RWD_Deal_Ops_Exception_Justification__c;
        }
      } else {
        if(quoteDetail.RWD_Sales_Rep_Exception_Justification__c) {
          this.exceptionComments = quoteDetail.RWD_Sales_Rep_Exception_Justification__c;
        }
      }
      //User selected exceptions
      let selectedDealOps = quoteDetail.RWD_Deal_Ops_Exception__c != null ? quoteDetail.RWD_Deal_Ops_Exception__c.split(';') : [];
      let selectedSales =  quoteDetail.RWD_Sales_Rep_Exception__c != null ? quoteDetail.RWD_Sales_Rep_Exception__c.split(';') : [];
      let selectedDealopsException = [];
      let selectedSalesRepException = [];
      const allExceptionsList = this.allExceptions.split(',').map(item => item.trim().toLowerCase());
      selectedDealOps.forEach(ele => {
        if(allExceptionsList.includes(ele.trim().toLowerCase())) {
          selectedDealopsException.push(ele);
        }
      });
      selectedSales.forEach(ele => {
        if(allExceptionsList.includes(ele.trim().toLowerCase())) {
          selectedSalesRepException.push(ele);
        }
      });
      if(isDealOps) {
        let allselection = selectedDealopsException;
        if(selectedSalesRepException) {
         selectedSalesRepException.forEach(exception => {
            allselection.push(exception);
          });
        }
        let selectedDealExceptions = allselection.join(',');
        this.exceptionMessages = this.exceptionOptionsHandler(enabledExceptions, selectedDealExceptions, false);
      }
      else {
        let hasMismatchException = enabledExceptions.find(ele => this.isEqualStrings(ele, 'Mismatch Quantity'));
        if(hasMismatchException) {
          let hasexception = selectedDealopsException.find(ele => this.isEqualStrings(ele, hasMismatchException));
          if(!hasexception) {
            selectedDealopsException.push(hasMismatchException);
          } 
          enabledExceptions = enabledExceptions.filter(ele => ele != hasMismatchException);
        }
        this.exceptionMessages = this.exceptionOptionsHandler(enabledExceptions, quoteDetail.RWD_Sales_Rep_Exception__c, false);
        let disabledExceptions = this.exceptionOptionsHandler(selectedDealopsException, quoteDetail.RWD_Deal_Ops_Exception__c, true);
        disabledExceptions.forEach(option=>{
          this.exceptionMessages.push(option);
        });
      }
    }
    }catch (error) {
      this.error = error;
      this.handleCatch(false, error,false);
    }
  }
  //FYSR25-1124 start
  exceptionOptionsHandler(options, selectedExceptions, isDisable) {
   const selectedList = selectedExceptions
    ? selectedExceptions.split(',').map(item => item.trim().toLowerCase())
    : [];
    let optionList = [];
    if(options) {
      options.forEach(exception => {
        const cleanedException = exception.trim().toLowerCase();
        const isSelected = selectedList.includes(cleanedException);
        optionList.push({
          label : exception,
          value : exception,
          selected : isSelected,
          disabled : isDisable
        });
      });
    }
    return optionList;
  }
  // Added for FY25SR-1569 - START
  setImagesOnList(dataModified){
    dataModified.forEach(currentItemWrapper => {
            //Base Product
            if(currentItemWrapper.wrapBaseLicense != undefined){
                currentItemWrapper.wrapBaseLicense = this.setImages(currentItemWrapper.wrapBaseLicense,true, null);
            }

            // HW support Line
            if (currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0) {
                currentItemWrapper.wrapHWSupportLines = this.setImages(currentItemWrapper.wrapHWSupportLines,true, null);
            }
            //upgrade
            if(currentItemWrapper.wrapUpgradeEnt != undefined){
                currentItemWrapper.wrapUpgradeEnt = this.setImages(currentItemWrapper.wrapUpgradeEnt,false, currentItemWrapper.textToShow);//FY25SR-1580 added textToShow
            }
        });
    return dataModified;
  }
  // Added for FY25SR-1569 - END
  // Added for FY25SR-1569 - START
  setImages(data, isRequiredProduct, textToDisp){//FY25SR-1580 added textToShow

    data.forEach(currentItem => {
      // if(isRequiredProduct && currentItem.setRowColor === 'background-color: #E8E8E8;'){
      if(currentItem.setRowColor === 'background-color: #E8E8E8;'){
        currentItem.imageUrlRequired = MandatoryImage + '/medical.png';
      } 
      
      if(!isRequiredProduct){
        currentItem.imageUrlUpgrades = MandatoryImage + '/link.png';
        //FY25SR-1580 added textToShow
        if (textToDisp) {
          currentItem.textToShow = textToDisp;
        }
        //FY25SR-1580 ends
      }
      currentItem.refreshUrl = '';//FY25SR-2245
    });
    return data;
  }
  // Added for FY25SR-1569 - START
  
  async _defaultDateFilters(quotedet) {
    // Assuming quotedet.CreatedDate is a string or Date object in a valid format
    let startDate = new Date(quotedet.CreatedDate);  // Convert to Date object
    let endDate = new Date(quotedet.CreatedDate);  // Convert to Date object

    // Modify the dates by changing the month (without overwriting with timestamp)
    //FY25SR-1745 Starts
    await getIntervals()
    .then(result => {
      this.lowerBound = result.LowerBoundM__c;
      this.upperBound = result.UpperBoundM__c;
    })
    .catch(error => {
      this.error = error;
      this.handleCatch(false, error, true);
    });
        
    startDate.setMonth(startDate.getMonth() - this.lowerBound);  // Min End Date months
    endDate.setMonth(endDate.getMonth() + this.upperBound);  // Max End Date months
    //FY25SR-1745 Ends

    // Helper function to format the date to YYYY-MM-DD for lightning-input
    const formatDate = (date) => {
        let year = date.getFullYear();
        let month = (date.getMonth() + 1).toString().padStart(2, '0');  // months are 0-based
        let day = date.getDate().toString().padStart(2, '0');
        return year+'-'+month+'-'+day;
    };

    // Set formatted date for input value
    this.startDate = formatDate(startDate);
    this.quoteDatebackThree = this.startDate;
    this.endDate = formatDate(endDate);
    this.quoteDateFwTwelve = this.endDate;
  }

  //refactored
  handleSort(event) {
    let fieldName = event.target.dataset.fieldName;
    if (this.sortField === fieldName) {
      this.sortAscending = !this.sortAscending;
    } else {
      this.sortField = fieldName;
      this.sortAscending = true;
    }
    // this.sortData(this.sortField, this.sortAscending);
  }
  // FY25SR-1374 START
  updatePageRecords(){
      this.pageKey = Date.now();
    }

  handlePageChange(event) {
        const { page, pageSize } = event.detail;
        this.currentPage = page;
        this.updateCurrentPageData(page, pageSize);
        this.fullSelected = false;
        if(this.dispositionpicklistoptions != undefined){
            this.dispositionpicklistoptions.forEach(curritem =>{
              if(curritem.selected == true){
                  curritem.selected = false;
                  this.massDispositionValue = '';
              } 
          });
        }
    }

  updateCurrentPageData(page, pageSize) {
        const start = (page - 1) * pageSize;
        const end = page * pageSize;
        this.currentPageData = this.filteredDataForPages.slice(start, end);
    }
  // FY25SR-1374 END
  //refactored
  @api
  filterData() {
    //CPQ22-6380
    let localdata = dataFilter(this.dataModified, this.entitlementSearchString, this.startDate, this.endDate, this.entitlementOrderNumberSearchString, this.entitlementAssetSearchString, this.quoteDatebackThree, this.quoteDateFwTwelve,this.entitlementFilter);
    try {
      this.message = '';
      this.showmsg = false;
      // FY25SR-1374 START
      this.totalCountForPages = localdata.length;
      this.filteredDataForPages = localdata;
      this.updatePageRecords();
      if(this.runFilterData == true){
        this.currentPage = 1;
        this.updateCurrentPageData(1,this.pageSizeFromMetadata);
      }else if(this.runFilterData == false){
        this.updateCurrentPageData(this.currentPage,this.pageSizeFromMetadata);
      }
      // FY25SR-1374 END
    } catch (error) {
      this.error = error;
      this.handleCatch(false, error,false);
    }
  }

  //refactored
  handleQuanChange(event) {
    try{
      this.message = '';
      this.showmsg = false;
      let quantity = event.detail.quantity;
      let customIndex = event.detail.customIndex;
      // Added as part of FY25SR-1207 - Start
      let entitlementId = event.detail.entitlementId;
      let keyIdentifier = event.detail.keyIdentifier;
      this.dataModified = handleQuanChange(quantity, customIndex, this.dataModified,entitlementId,keyIdentifier, this.exceptionMessages);
      // Added as part of FY25SR-1207 - END
      this.runFilterData = false;
      this.filterData();
    } catch (error) {
        this.dataModified = undefined;
        this.error = error;
        this.handleCatch(false, error, false);
    }
  }
  
  handleDoubleClick(event) {
        event.preventDefault();
        event.stopPropagation();
    }

  //refactored
  handleTermChange(event) {
    try{
      this.message = '';
      this.showmsg = false;
      let termHandle = event.detail.termvalue;
      let customIndex = event.detail.customIndex;
      // Added as part of FY25SR-1207 - Start
      let entitlementId = event.detail.entitlementId;
      let keyIdentifier = event.detail.keyIdentifier;
      this.dataModified = handleTermChange(termHandle,customIndex,this.dataModified,this.quoteDetails,this.errorMessagesValues,entitlementId,keyIdentifier);
       // Update renewal/end date for the single-row (non-bulk) term change.
      // Use the existing helper to recompute renewal date based on the new term.
      try {
        this.dataModified = handleRenewalDateChange(
          null,                // selectedRenewalDate (not used when driving from term)
          customIndex,         // customIndex to identify the row to update
          this.dataModified,   // data list to operate on
          this.errorMessagesValues,
          entitlementId,
          keyIdentifier,
          false,               // isBulk = false
          termHandle           // pass the new term value so helper recalculates dates
        );
      } catch (err) {
        // swallow and log — keep existing behavior on helper failure
        // this.error will be handled by outer catch below
        console.error('Renewal date update after term change failed', err);
      }
      // Added as part of FY25SR-1207 - END
      this.runFilterData = false;
      this.filterData();
    } catch (error) {
        this.dataModified = undefined;
      this.error = error;
        this.handleCatch(false, error, false);
    }
  }
  
    
  addRows(event){
    try{
      this.message = '';
      this.showmsg = false;
      let customIndex = event.detail.customIndex;
      // Added as part of FY25SR-1207 - Start
      let entitlementId = event.detail.entitlementId;
      let keyIdentifier = event.detail.keyIdentifier;
      let newdata = handleAddRow(customIndex,this.dataModified,this.quoteDetails.SBQQ__Type__c,
            entitlementId,keyIdentifier, this.doNotConsolidateUI, this.disableValidations, this.quotelineFieldApi);
      // Added as part of FY25SR-1207 - END
      this.dataModified = [];
      this.dataModified = [...newdata];
      this.dataModified = exceptionMapping(this.dataModified,this.doNotConsolidateUI, this.replaceAnyToAnyUI, this.errorMessagesValues, this.isMismatchQTY);
      this.runFilterData = false;
      this.handleSKUPaymentSwitch(this.dataModified, customIndex);
      this.filterData();
    } catch (error) {
        this.dataModified = undefined;
      this.error = error;
        this.handleCatch(false, error, false);
    }
    
  }
    
   
  deleteRows(event){
    try{
      this.message = '';
      this.showmsg = false;
      let customIndex = event.detail.customIndex;
      //FY25SR-1176 start
      handleReplaceAfterRefresh(this.dataModified, this.refreshData, 'delete', customIndex, this.errorMessagesValues);
      //FY25SR-1176 end
      // Added as part of FY25SR-1207 - Start
      let keyIdentifier = event.detail.keyIdentifier;
      this.dataModified = hanleDeleteRow(customIndex,this.dataModified,keyIdentifier, this.exceptionMessages);
      // Added as part of FY25SR-1207 - END
      this.handleSKUPaymentSwitch(this.dataModified, customIndex);
      this.runFilterData = false;
      this.filterData();
    } catch (error) {
        this.dataModified = undefined;
      this.error = error;
        this.handleCatch(false, error, false);
    }
    
  }
  
  
  //refactored
  handleDisposition(event) {
    try{
      this.message = '';
      this.showmsg = false;
    let selectedDisposition = event.detail.selectedDisposition;
    let customIndex = event.detail.customIndex;
    // Added as part of FY25SR-1207 - Start
    let entitlementId = event.detail.entitlementId;
    let keyIdentifier = event.detail.keyIdentifier;
    this.dataModified = handleDisposition(selectedDisposition,customIndex,this.dataModified,entitlementId,keyIdentifier);
    // Added as part of FY25SR-1207 - END
    // this.handleSKUPaymentSwitch(this.dataModified, customIndex);
    this.runFilterData = false;
    this.filterData();
    } catch (error) {
        this.dataModified = undefined;
      this.error = error;
        this.handleCatch(false, error, false);
    }
  }

  // Added this method as part of FY25SR-1215
  handleRenewalDateChange(event){
    try{
      this.message = '';
      this.showmsg = false;
      let selectedRenewalDate = event.detail.selectedRenewalDate;
      let customIndex = event.detail.customIndex;
      // Added as part of FY25SR-1207 - Start
      let entitlementId = event.detail.entitlementId;
      let keyIdentifier = event.detail.keyIdentifier;
      this.dataModified = handleRenewalDateChange(selectedRenewalDate,customIndex,this.dataModified,this.errorMessagesValues,entitlementId,keyIdentifier,false,null);
      // Added as part of FY25SR-1207 - END
      this.handleSKUPaymentSwitch(this.dataModified, customIndex);  
      this.runFilterData = false;
      this.filterData();
    } catch (error) {
        this.dataModified = undefined;
      this.error = error;
        this.handleCatch(false, error, false);
    }
  }

  async handleSKUClick(event) {
    try{
      this.message = '';
      this.showmsg = false;
      let parentOptionSelection = event.detail.skuSelected;
      let customIndex = event.detail.customIndex;
      // Added as part of FY25SR-1207 - Start
      let entitlementId = event.detail.entitlementId;
      let keyIdentifier = event.detail.keyIdentifier;
      // Added as part of FY25SR-1207 - END
      const { cindex, rowsel } = parentOptionSelection;
      
      // Added as part of FY25SR-1207 - Start
      this.handleSKUEvent(cindex, rowsel , entitlementId , keyIdentifier);
      // Added as part of FY25SR-1207 - END
    } catch(error) {
      this.handleCatch(false, error, false);
    }
  }
  
  handleSKUEvent(cindex, rowsel,entitlementId , keyIdentifier) {
    try{
      this.message = '';
      this.showmsg = false;
        // Added as part of FY25SR-1207 - Start
        let displayedData = handleSkuAssignment(
          this.doNotConsolidateUI,true,this.dataModified,cindex,this.fullSelected,
      this.massDispositionValue,entitlementId , keyIdentifier,rowsel, this.isMismatchQTY, this.quotelineFieldApi);
        // Added as part of FY25SR-1207 - END
        this.dataModified = displayedData;        
        this.runFilterData = false;
        this.handleSKUPaymentSwitch(this.dataModified, cindex);
        //FY25SR-1176
        handleReplaceAfterRefresh(this.dataModified, this.refreshData, 'skuchange', cindex, this.errorMessagesValues);
        //FY25SR-1176 end
        this.filterData();
    } catch (error) {
        this.dataModified = undefined;
      this.error = error;
        this.handleCatch(false, error, false);
    }
  }
  
  
  handleSKUChange(event) {
    try{
      this.message = '';
      this.showmsg = false;
        let cIndex = event.detail.customIndex;
        // Added as part of FY25SR-1207 - Start
        let entitlementId = event.detail.entitlementId;
        let keyIdentifier = event.detail.keyIdentifier;
        let displayedData = handleSkuAssignment(
          this.doNotConsolidateUI,false, this.dataModified,cIndex,this.fullSelected,
          this.massDispositionValue,entitlementId,keyIdentifier, this.isMismatchQTY);
        // Added as part of FY25SR-1207 - END
        this.dataModified = displayedData;
        this.runFilterData = false;
        this.handleSKUPaymentSwitch(this.dataModified, cIndex);
        //FY25SR-1176
        handleReplaceAfterRefresh(this.dataModified, this.refreshData, 'skuchange', cIndex, this.errorMessagesValues);
        //FY25SR-1176 end
        this.filterData();
      } catch (error) {
        this.dataModified = undefined;
      this.error = error;
        this.handleCatch(false, error, false);
    }
  }

  handleSKUPaymentSwitch(datamodified, cIndex){
        this.dataModified = handleSKUPaymentSwitch(datamodified, cIndex);
  }

  handleServiceContract(event) {
    let cIndex = event.currentTarget.dataset.customIndex;
    this.baseURL = window.location.origin;
    let url = this.baseURL + '/' + event.currentTarget.dataset.serviceId;
    window.open(url, '_blank');
  }

  checkDataValidity() {
    this.dataModified = updateMismatchQuantityFlag(this.dataModified, this.isMismatchQTY);
    //FY25SR-1875 - Start
    if(this.disableValidations){
      return false;
    }
    //FY25SR-1875 - End
    this.dataModified = dataValidity(this.dataModified,this.quoteDetails,this.errorMessagesValues, this.exceptionMessages, this.misMatchExcep);
    this.filterData();
    let errorMsg = handleQuoteHeaderValidity(this.dataModified, this.exceptionMessages, this.exceptionComments, this.errorMessagesValues);
    if(errorMsg && errorMsg!=null) {
      this.error = errorMsg;
      this.handleCatch(false, errorMsg, true);
      return true;
    } 
    return checkIfErrorAdded(this.dataModified);
  }

  //refactored
  handleNext() {
    if (!this.checkDataValidity()) {
      const selectEvent = new CustomEvent('showdisposition', {
        detail: {
              replacementData : this.dataModified,
              dispositionData : this.wrapperDataFromDispositionUi,
              modifiedEntitlementIDs : this.modifiedIds
          } 
      });
      this.dispatchEvent(selectEvent);
    }
  }

   //refactored
  handleselectoptionparent(event) {
    try{
      this.message = '';
      this.showmsg = false;
      let parentOptionSelection = event.detail.parentOptionSelection;
      let customIndex = event.detail.customIndex;
      // Added as part of FY25SR-1207 - Start
      let entitlementId = event.detail.entitlementId;
      let keyIdentifier = event.detail.keyIdentifier;
      // Added as part of FY25SR-1207 - END
      if(customIndex != undefined){
        this.dataModified = handleSelectedAssetChange(parentOptionSelection, customIndex, this.dataModified,entitlementId,keyIdentifier);
        this.handleSKUPaymentSwitch(this.dataModified, customIndex);
      }
      //FY25SR-1176 start Refresh+Replace
      handleReplaceAfterRefresh(this.dataModified, this.refreshData, 'assetchange', customIndex, this.errorMessagesValues, [parentOptionSelection.value]);
      //FY25SR-1176 end
      this.runFilterData = false;
      this.filterData();
    }catch (error){
      this.error = error;
      this.handleCatch(false, error, false);
    }
    
    // this.dataModified = displayedData;
    // this.setCurrentPageData();
  }

  //refactored
  handleCheckBoxSelectionChange(event) {
    try{
      this.message = '';
      this.showmsg = false;
      this.runFilterData = false;
      let checkBoxSelection = event.detail.checkBoxSelection;
      let customIndex = event.detail.customIndex;
      this.dataModified = handlecheckBoxSelection(this.dataModified,customIndex,checkBoxSelection, this.doNotConsolidateUI);
      this.dataModified = exceptionMapping(this.dataModified,this.doNotConsolidateUI, this.replaceAnyToAnyUI, this.errorMessagesValues, this.isMismatchQTY);
      this.handleSKUPaymentSwitch(this.dataModified, customIndex);      
      this.dataModified = removeAllErrors(this.dataModified, this.exceptionMessages);    
      //FY25SR-1176 start Refresh+Replace
      
      handleReplaceAfterRefresh(this.dataModified, this.refreshData, 'checkboxchange', customIndex, this.errorMessagesValues);
       this.filterData();
      //FY25SR-1176 end
      
    }catch (error){
      this.error = error;
      this.handleCatch(false, error, false);
    }
    
  }

  //refactored
  handleSelectAll(event) {
    this.fullSelected = event.target.checked;
    try{
      this.message = '';
      this.showmsg = false;
      this.runFilterData = false;
      //let currPageData = this.currentPageData;
      //CPQ22-6009 - replaced currentPageData with filteredDataForPages to ensure all records are considered on select all.
      let displayedData = handlecheckBoxSelectionAll(this.filteredDataForPages,this.fullSelected, this.massDispositionValue, true, this.doNotConsolidateUI,this.massTermValue);//CPQ22-6193 this.massTermValue//this.dataModified
      this.dataModified = exceptionMapping(this.dataModified,this.doNotConsolidateUI, this.replaceAnyToAnyUI, this.errorMessagesValues, this.isMismatchQTY);
      this.dataModified = removeAllErrors(this.dataModified, this.exceptionMessages);
      let appendedData = appedCurrentPageDataOnSelectAll(displayedData, this.dataModified);
      this.dataModified = appendedData;
      this.filterData();
    }catch (error){
      this.error = error;
      this.handleCatch(false, error, false);
    }
  }

  @track contrList = [];
  @track message;
  @track showcomp = false;
  @track showSpinner = false;
  @track showmsg = false;


  //refactored
  handleCatch(spinnerValue, error, apexCall) {
    let errorMessage = 'An unexpected error occurred. Please reach out to IT Support team.';
    console.log('Debugging level log ::'+JSON.stringify(error));
    // Apex error with structured body.message
    if(apexCall) {
      if (error?.body && typeof error.body === 'object' && error.body.message) {
        errorMessage = errorMessage + ' Error: ' + error.body.message;
  
      // Apex error where body is a plain string
      } else if (typeof error?.body === 'string') {
        errorMessage = errorMessage + ' Error: ' + error.body;
  
      // JavaScript error (TypeError, ReferenceError, etc.)
      } else if (error?.message) {
        errorMessage = errorMessage + ' Error: ' + error.message;
  
      // Raw string error
      } else if (typeof error === 'string') {
        errorMessage = errorMessage + ' Error: ' + error;
      } else {
        // Fallback — convert entire object to string for debug
        errorMessage = errorMessage + ' Error: ' +  JSON.stringify(error, null, 2);
      }
    }
    this.showSpinner = spinnerValue;
    this.message = errorMessage;
    this.showmsg = true;
    this.showErrorToast(error);
  }

  //refactored
  showErrorToast(messgae) {
    const evt = new ShowToastEvent({
      title: 'Error',
      message: String(messgae),
      variant: 'error',
      mode: 'dismissable'
    });
    this.dispatchEvent(evt);
  }

  //refactored
  
  handleStartDate(event) {
    this.startDate = event.target.value; 
    this.handleStartEndDate();   
  }

   handleEndDate(event) {
    this.endDate = event.target.value;
    this.handleStartEndDate();
  }

  handleStartEndDate(){
    try{
      this.message = '';
      this.showmsg = false;
        this.showSpinner = true;
        if(this.endDate <= this.quoteDateFwTwelve && this.startDate >= this.quoteDatebackThree && this.endDateModified == false){
            this.runFilterData = false;
            this.filterData();
        }else if(this.endDate <= this.quoteDateFwTwelve && this.startDate >= this.quoteDatebackThree && this.endDateModified == true){
            this.endDateModified = false;
            this.previousDataModified = this.dataModified;
            this.dateChanged(this.endDate);
        }else if(this.endDate > this.quoteDateFwTwelve || this.startDate < this.quoteDatebackThree){
            this.endDateModified = true;
            this.previousDataModified = this.dataModified;
            this.dateChanged(this.endDate);
        }       
        this.showSpinner = false;
    }catch (error){
      this.error = error;
      this.handleCatch(false, error, false);
    }
  }

  async dateChanged(endDate){
          try{
      this.message = '';
      this.showmsg = false;
              this.showSpinner = true;
              let alreadySel = [];
              alreadySel = getSelectedEnt(this.dataModified);
              let skipCustom = [];
              skipCustom = getSelectedCustomIdex(this.dataModified);
              let entlResult = await getEntitlements({ quoteDetail: this.quoteDetails, startDate : this.startDate, endDate : endDate, selectedEnts : null, alreadySelEnt : alreadySel, skipCustomIndex : skipCustom});
              this.dataModified = setDataOnLoad(entlResult , this.quoteDetails.SBQQ__Type__c);
              // Added for FY25SR-1569 - START
              this.dataModified = this.setImagesOnList(this.dataModified);
              // Added for FY25SR-1569 - END     
                  this.showSpinner = false;
                  this.endDateModified = true;
                  this.dataModified = endDateFilterChangeEnts(this.previousDataModified, this.dataModified);  
              } catch (error) {
                this.dataModified = undefined;
                this.error = error;
                this.handleCatch(false, error, false);
            }      
            this.runFilterData = true;
            this.filterData();      
  }

  //refactored
  handleSearchEntitlement(event) {
    try{
      this.message = '';
      this.showmsg = false;
      this.entitlementSearchString = event.target.value;
      this.runFilterData = true;
      this.filterData();
    }catch (error){
      this.error = error;
      this.handleCatch(false, error, false);
    }
  }

  //refactored
  handleSearchOrder(event) {
    try{
      this.message = '';
      this.showmsg = false;
      this.entitlementOrderNumberSearchString = event.target.value;
      this.runFilterData = true;
      this.filterData();
    }catch (error){
      this.error = error;
      this.handleCatch(false, error, false);
    }
  }

  //refactored
  handleAssetName(event) {
    try{
      this.message = '';
      this.showmsg = false;
      this.runFilterData = true;
      this.entitlementAssetSearchString = event.target.value;
      this.filterData();
    } catch (error){
      this.error = error;
      this.handleCatch(false, error, false);
    }   
  }

  userEmail = Email;
  
  handleQuotelineCreation() {
    this.showSpinner = true;
    let refreshModifiedOnly =  [];
    this._collectDispositionPayload();
    if (!this.checkDataValidity()) {
      this.message = '';
      this.showmsg = false;
      const quoteDetail = {};
      try{
        quoteDetail['exceptionComments'] = this.exceptionComments;
        quoteDetail['exceptionMessages'] = JSON.stringify(this.exceptionMessages);
        quoteDetail['isDealOps'] = ''+this.isDealOPs;
        // check if all the entered data is correct and valid with no errors then create quote lines
            this.disableSaveButton = true;
        refreshModifiedOnly = filterRefreshData(this.refreshData);
      } catch (error){
        this.error = error;
        this.handleCatch(false, error, false);
      }
      createQuote({
        quoteId: this.quoteDetails.Id,
        lstWrapperEntitlement: this.dataModified,
        refreshWrapperData : refreshModifiedOnly,
        quoteDetail : JSON.stringify(quoteDetail)
      })
      .then((result) => {
        if (result != null) {
          if (result.toString().startsWith('a6')) {
            this.quoteId = result;
            let url = this.baseURL + '/apex/sbqq__sb?id=' + this.quoteIdOrginial;

            window.location.href = url;
            this.showSpinner = false;
          } else {
            let notQuoteError = 'Server error!'
            this.error = notQuoteError
            this.handleCatch(false, notQuoteError, false);
            this.showSpinner = false;
          }
        } else {
          this.showcomp = true;
          this.handleCatch(false, 'Server error!', true);
          this.showSpinner = false;
        }
      })
      .catch((error) => {
        this.error = error;
        this.handleCatch(false, error, true);
        this.showSpinner = false;
      });
    } else {
      let pageErrorMsg = this.errorMessagesValues.find(smsError => smsError.Message_Label__c === 'Page has Error');
      if(pageErrorMsg && (this.message === '' || this.message === undefined || this.message == null) ) {
        this.message = pageErrorMsg.Error_Message__c;
        this.showmsg = true;
      }
      this.showSpinner = false;
    }
  }

    /** CPQ22-6009
   * Traverse this.dataModified and return a new array (deep-cloned) that contains
   * only wrappers / rows where selecteddisposition is non-empty.
   * Keeps original wrapper structure but removes rows without disposition.
   */
  _collectDispositionPayload() {
    if (!this.dataModified || !Array.isArray(this.dataModified)) return [];
      this.dataModified.forEach(wrapper => {
      //future transactions: update rowSelected to true where disposition Reason is populated.
       if (wrapper.mapAssetEntitlements != undefined && wrapper.customIndex != undefined && wrapper.mapAssetEntitlements.futureValues && wrapper.mapAssetEntitlements.futureValues.length > 0) {
                    wrapper.rowSelected = true;
                    wrapper.mapAssetEntitlements.futureValues.forEach(citem => {
                      if(citem && citem.selecteddisposition && String(citem.selecteddisposition).trim() !== ''){
                          citem.rowSelected = true;
                      } else {
                          citem.rowSelected = false;
                          wrapper.rowSelected = false;
                      }
            });
       }
        // Base wrapper: update rowSelected to true where disposition Reason is populated.
        const lists = ['wrapBaseLicense','wrapHWSupportLines','wrapAddOnSupportLines','wrapInactiveEnt','wrapUpgradeEnt'];
        lists.forEach(listName => {
          if (Array.isArray(wrapper[listName])) {
            wrapper[listName].forEach(item => {
              item.rowSelected = item && item.selecteddisposition && String(item.selecteddisposition).trim() !== ''?true:false;
            });
          }
        });   
    });
  }

  handleCancel() {
      let url = this.baseURL + '/apex/sbqq__sb?id=' + this.quoteIdOrginial;
      window.location.href = url;
  }

  async handleRefresh(event) {
    const result = await refreshModal.open({
          size: 'full',
          description: "Accessible description of modal's purpose",
          label: 'test',
          entitlementData: this.dataModified,
          refreshRecreateData : this.refreshData,
          errorMessagesValues : this.errorMessagesValues,
          quoteDetails : this.quoteDetails,
          disableValidations : this.disableValidations //FY25SR-1875
        });
        if (result) {
            this.modalResult = result;
            this.refreshData = this.modalResult;
            //FY25SR-1176 start
            handleOnRefresh(this.dataModified, this.refreshData, this.refreshUrl);//FY25SR-2245
            this.filterData();
            //FY25SR-1176 end
        }

  }

  handleBulkDispositionChange(){
        //CPQ22-6009: replaced this.currentPage with this.filteredDataForPages in handlecheckBoxSelectionAll invocation.
    this.massDispositionValue = this.massDispositionValue== "None"?"":this.massDispositionValue;
    let displayedData = handlecheckBoxSelectionAll(this.filteredDataForPages,this.fullSelected, this.massDispositionValue, false, this.doNotConsolidateUI,this.massTermValue);//CPQ22-6193 this.massTermValue
    let appendedData = appedCurrentPageDataOnSelectAll(displayedData, this.dataModified);
    this.dataModified = appendedData;
  }

  //refactored
  handleDispositionChangeMultiple(event) {
    //this.massDispositionValue = event.detail.value;
    if(this.dispositionpicklistoptions != undefined){
            this.dispositionpicklistoptions.forEach(curritem =>{
              curritem.selected = false;
              if(curritem.value == event.detail.value){
                  curritem.selected = true;
                  this.massDispositionValue = event.detail.value?event.detail.value:"None";
              } 
          });
    }
  }
   /**CPQ22-6009- Apply a subscription term update (this.massTermValue) to the set of entitlements
   *   that the user has selected (bulk action)
   **/
  handleBulkTermDataUpdate(){
        if(this.massTermValue != null && this.massTermValue != ''){
        //CPQ22-6009: replaced this.currentPage with this.filteredDataForPages in handleRenewalDateChange invocation.
          let displayedData = handleRenewalDateChange(null,null,this.filteredDataForPages,this.errorMessagesValues,null,null,true,this.massTermValue);
    let appendedData = appedCurrentPageDataOnSelectAll(displayedData, this.dataModified);
    this.dataModified = appendedData;
        }
  }
   // CPQ22- 5969
    handleTermChangeMultiple(event) {
    this.template.querySelector('[data-id="dateInput"]').value = null;
    this.selectedDate = null;
    this.massTermValue = event.target.value;
  }

  handleBulkDataUpdateEndDate(){
      if(this.massEndDate !=null && this.massEndDate !=''){
        //CPQ22-6009: replaced this.currentPage with this.filteredDataForPages in handleRenewalDateChange invocation.
        let displayedData = handleRenewalDateChange(this.massEndDate,null,this.filteredDataForPages,this.errorMessagesValues,null,null,true,null);
    let appendedData = appedCurrentPageDataOnSelectAll(displayedData, this.dataModified);
    this.dataModified = appendedData;
      }
  }
  handleEndDateChangeMultiple(event) {
    this.template.querySelector('[data-id="termInput"]').value = null;
    this.numberValue = null;
    this.massEndDate = event.target.value;
  }

  createOptionData(entilementList) {
    entilementList.forEach(dataRow => {
      if(dataRow.wrapBaseLicense) {
        let licenseRows = this.createOptionWithLicenseRow(dataRow.wrapBaseLicense, this.productList);
        licenseRows.forEach((value, key) => {
          this.optionsMap.set(key, value);
        });
      }
      if(dataRow.wrapHWSupportLines) {
        this.updateOptionsWithHWSupportData(dataRow.wrapHWSupportLines, this.optionsMap);
      }
    });
    return this.optionsMap;
  }
  
  createOptionWithLicenseRow(licenseWrapperList, productList) {
    let rows = new Map();
    
    for(let license of licenseWrapperList) {
      let productDetails = {};
      productDetails.productCode = license.entitlementName === undefined ? '' : license.entitlementName;
      productDetails.supportType = license.srSuppType;
      productDetails.productId = license.productId;
      productList.push(productDetails);

      //FY25SR-1176 start, for replaced product
      if (license.skuProdName){
        let productReplace = {};
        productReplace.productCode = license.skuProdName;
        productReplace.supportType = license.skuSuppType;
        productReplace.productId = license.skuProductId;
        productList.push(productReplace);
      }
      //FY25SR-1176 end

      if(license.assetsAvailable) {
        for(let asset of license.assetsAvailable) {
          if(asset.label !== 'Full') {
            let row = {
              "entitlementId": asset.entitlementId,
              "entitlementName": asset.entitlementName,
              "label": asset.label,
              "quantity": asset.quantity,
              "selected": true,
              "value": asset.value,
              "supportEntId": "",
              "supportProdId": ""
            };
            rows.set(asset.value, row);
          }
        }
      }
    }
    return rows;
  }

  updateOptionsWithHWSupportData(HWSupportList, optionsMap) {
    for(let hwSupport of HWSupportList) {
      if(hwSupport.assetsAvailable) {
        for(let asset of hwSupport.assetsAvailable) {
          if(optionsMap.has(asset.value)) {
            let assetData = optionsMap.get(asset.value);
            assetData.supportEntId = hwSupport.entitlementId;
            assetData.supportProdId = hwSupport.productId;
          }
        }
      }
    }
    return optionsMap;
  }

  // FY25SR-1124 - start
  handleexceptionoptionparet(event) {
    try{
      this.message = '';
      this.showmsg = false;
      let parentOptionSelection = event.detail;
      if(Array.isArray(parentOptionSelection)){
          parentOptionSelection.forEach(item =>{
            
          if(this.isEqualStrings(item.value,'Do Not Consolidate Replacement Lines')){
                this.doNotConsolidateUI = item.selected;
          }
          if(this.isEqualStrings(item.value,'Replace Any to Any')){
                this.replaceAnyToAnyUI = item.selected;
          }
          if(this.isEqualStrings(item.value,'Mismatch Quantity')) {
            this.isMismatchQTY = item.selected;
          }
        });
        this.exceptionMessages = parentOptionSelection;
        let displayedData = removeAllErrors(this.dataModified, this.exceptionMessages);
        displayedData = exceptionMapping(displayedData,this.doNotConsolidateUI, this.replaceAnyToAnyUI, this.errorMessagesValues, this.isMismatchQTY);
        
        this.dataModified = displayedData;
        
      }
      this.runFilterData = false;
      this.filterData();
    }
    catch(error) {
      this.error = error;
      this.handleCatch(false, error, false);
    }
  }
  handleExceptionCommentsChange(event) {
    let comments = event.target.value;
    this.exceptionComments = event.target.value;
  }
  
  // FY25SR-1124 - end
  isEqualStrings(itemValue, tocompare) {
    return itemValue.trim().toLowerCase() === tocompare.trim().toLowerCase();
  }
    /**CPQ22-6009
   * Optimized handler:
   * - Applies show flags and obtains filtered wrappers in one pass.
   * - If HW_ONLY selected, uses the filtered result to rebuild pagination (avoids a second pass).
   * - Otherwise falls back to existing filterData() path.
   */
  handleEntitlementFilterChange(event) {
    try{
      this.message = '';
      this.showmsg = false;
      this.entitlementFilter = event.target.value;
      this.runFilterData = true;
      this.filterData();
    }catch (error){
      this.error = error;
      this.handleCatch(false, error, false);
    }
  }

    /** CPQ22-6009
   * Apply bulk actions (disposition, subscription term, renewal/end date) to the entitlements
   * selected by the user. This method delegates the actual row-level work to the existing
   * helpers: handleBulkDispositionChange, handleBulkTermDataUpdate and handleBulkDataUpdateEndDate.
   */
    handleApplyBulkActions(){
    try{
      this.message = "";
      this.showmsg = false;
      
      // Call disposition handler 
      if(this.massDispositionValue){
        this.handleBulkDispositionChange();
      }
      // Subscription Term handler
      if (this.massTermValue) {
        this.handleBulkTermDataUpdate();
        const termInput = this.template.querySelector('[data-id="termInput"]');
        if (termInput) termInput.value = null;
      }

      // Renewal End Date handler
      if (this.massEndDate) {
        this.handleBulkDataUpdateEndDate();
        const dateInput = this.template.querySelector('[data-id="dateInput"]');
        if (dateInput) dateInput.value = null;
      }
      // Clear applied checkbox selections
      this.clearOutCheckBoxOnApply();
      this.runFilterData = false;
      this.filterData();
    } catch (err) {
      console.error("handleApplyBulkActions error", err);
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: "Error applying bulk actions. See console.",
          variant: "error",
        }),
      );
    }
  }

  clearOutCheckBoxOnApply() {
    if (!this.dataModified || !Array.isArray(this.dataModified)) return;

    const lists = [
      "wrapBaseLicense",
      "wrapHWSupportLines",
      "wrapAddOnSupportLines",
      "wrapInactiveEnt",
      "wrapUpgradeEnt"
    ];

    this.dataModified.forEach((wrapper) => {
      if (!wrapper) return;

      // Clear mapAssetEntitlements.futureValues selection if present
        const mapAsset = wrapper.mapAssetEntitlements;
        if (
          mapAsset &&
          Array.isArray(mapAsset.futureValues) &&
          mapAsset.futureValues.length
        ) {
          mapAsset.futureValues.forEach((fv) => {
            if (fv && fv.rowSelected) fv.rowSelected = false;
          });
        }

      // Clear rowSelected only when true (avoids unnecessary writes)
      lists.forEach((listName) => {
        const arr = wrapper[listName];
        if (!Array.isArray(arr) || arr.length === 0) return;
        arr.forEach((item) => {
          if (item && item.rowSelected) item.rowSelected = false;
        });
      });
    });

    // Reset top-level bulk UI state so UI reflects cleared selections
    this.fullSelected = false;
    this.massDispositionValue = "";
    this.massTermValue = null;
    this.massEndDate = null;
  }
}