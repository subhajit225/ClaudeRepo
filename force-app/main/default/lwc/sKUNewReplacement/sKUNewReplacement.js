/*********************************This componenent is build as a part of FY25SR-1081******************************* */

import { api, LightningElement, track, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import getProducts from '@salesforce/apex/SKUNewReplacementController.getSKUData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Toast from 'lightning/toast';
import PROD_OBJ from '@salesforce/schema/Product2';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import PRODTYPE_FIELD from '@salesforce/schema/Product2.Product_Type__c';
import PRODLICTYPE_FIELD from '@salesforce/schema/Product2.License_Type__c';
import PRODLICCAT_FIELD from '@salesforce/schema/Product2.License_Category__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import {dataFilter, selectedValueSKU, selectedSkuAfterFilter, checkRowSelectionInPrdFilter,calculateConsolidation,mapPathforSKUForAsset,mapPathforSKUForNonAsset,assetNonAssetTypeCheck,attributeSectionCheck } from './skuUtility';
 
export default class SKUNewReplacement extends LightningModal {
  @api prodname;
  @api prodrepname;
  @api entdata;
  @api entsDataAll;
  @api disableValidations; //FY25SR-1875
  @track showAttributeSection;
  @api customErrorMessages = new Map();
  @api replacementanytoany;
  @api quoteDetails;
  @track data;
  @track error;
  @track showSpinner = false;
  @api prodList;
  @track message;
  @api customIndex;
  @api selectedRowval;
  @api disReasonVal;
  @track searchProdName;
  @track searchProdDes;
  @track prdLicTypeOptions;
  @track prdlicCatoptions;
  @track prdtypeval;
  @track prdlictypeval;
  @track prdlicCatval;
  @track rawdata;
  @api quantitySum;
  @track dataFromChild;
  @track isSKUSelected = false;
  @track qlStorBundleFrontValue;
  @track qlStorageBundleFrontOptions;
  @track qlStorTierValue;
  @track assetSelectedProductId;
  @track multiAddSelectedProductId;
  @track qlStoragTierOptions;
  @track storBundleCheck = false;
  @track storTierCheck = false;
  @track showmsg = false;
  @api entsData;
  fixedWidth = "width:15rem;";
  @track componentVisible = false;
  @api isMismatchQTY;

  hwNonHwSelected = '';

  get hwOptions() {
    return [
      { label: 'Hardware', value: 'Hardware' },
      { label: 'Non Hardware', value: 'Non Hardware' }
    ];
  }

  @wire(getObjectInfo, {
    objectApiName: PROD_OBJ
  })
  objectInfo;

  @wire(getPicklistValues, {
    recordTypeId: '$objectInfo.data.defaultRecordTypeId',
    fieldApiName: PRODTYPE_FIELD
  })
  wiredProdTypeVal(result) {
    if (result.data) {
      this.prdTypeOptions = [{ label: 'None', value: 'None', selected: true }, ...result.data.values];
    } else if (result.error) {
      this.prdTypeOptions = undefined;
      this.error = result.error;
      this.handleCatch(false, result.error);
    }
  }

  @wire(getPicklistValues, {
    recordTypeId: '$objectInfo.data.defaultRecordTypeId',
    fieldApiName: PRODLICTYPE_FIELD
  })
  wiredProdLicTypeVal(result) {
    if (result.data) {
      this.prdLicTypeOptions = [{ label: 'None', value: 'None', selected: true }, ...result.data.values];
    } else if (result.error) {
      this.prdLicTypeOptions = undefined;
      this.error = result.error;
      this.handleCatch(false, result.error);
    }
  }

  @wire(getPicklistValues, {
    recordTypeId: '$objectInfo.data.defaultRecordTypeId',
    fieldApiName: PRODLICCAT_FIELD
  })
  wiredProdLicCatVal(result) {
    if (result.data) {
      this.prdLicCatoptions = [{ label: 'None', value: 'None', selected: true }, ...result.data.values];
    } else if (result.error) {
      this.prdLicCatoptions = undefined;
      this.error = result.error;
      this.handleCatch(false, result.error);
    }
  }

  connectedCallback() {
    try {
    if(this.quoteDetails.SBQQ__Type__c === 'Renewal+Expansion'){ 
              this.componentVisible = true;
    }
    console.log('quantitySum is ',this.quantitySum);
    this.showSpinner = true;
    this.showAttributeSection = false;
    let ents = this.entdata;
   // let pbId = this.quotePbId;
    this.entsData = this.entdata;
    console.log('ents ',JSON.stringify(this.entsData));
    console.log('errors from SKU ', JSON.stringify(this.customErrorMessages));
    console.log('replacementanytoany from main is ', this.replacementanytoany);
    getProducts({ entData: this.entdata, quoteDet : this.quoteDetails, replacementanytoany : this.replacementanytoany })
      .then((result) => {
          if(result != undefined && result.length > 0){
              this.prodList = result;
              this.rawdata = result;
              this.showSpinner = false;
              let newWrap = [];
              let rowVals;
              let displayedData = JSON.parse(JSON.stringify(this.prodList));
              console.log('displayedData ::',JSON.stringify(displayedData));
                  displayedData.forEach(function(currentItemWrapper){
                      if(ents.skuProductId != undefined && ents.skuProductId != null && ents.skuProdName != undefined && ents.skuProdName != null
                             && ents.skuProductId == currentItemWrapper.productId && ents.skuProdName === currentItemWrapper.productName){
                            rowVals = currentItemWrapper;
                            rowVals.showAttributeSection = false;
                            if(rowVals.attributeEligibleCheck == true){   
                                  rowVals.showAttributeSection = true;
                                  let childMapping = {};
                                  if(ents.skuAttributesToQuoteLine != undefined){
                                        for(var key in ents.skuAttributesToQuoteLine){
                                              childMapping[key] = ents.skuAttributesToQuoteLine[key];
                                        }
                                        rowVals.childMappingSKUattributes = childMapping;
                                  }
                            }
                            if(ents.selectedAssetsFromNonAsset != undefined && ents.selectedAssetsFromNonAsset.length > 0){
                               rowVals.pathAssetSelected = ents.selectedAssetsFromNonAsset.map(item => item);
                             }
                            currentItemWrapper.isRowSelected = true;
                            rowVals = assetNonAssetTypeCheck(ents, rowVals);                             
                            newWrap.push(currentItemWrapper);
                      }
                  });
              this.selectedRowval = rowVals;              
              this.prodList = displayedData;
              this.rawdata = this.prodList;

              if(rowVals != undefined){    
                  if(rowVals.showAssets == true){this.assetSelectedProductId = rowVals.productId;}
                  if(rowVals.multiAddAssets == true){this.multiAddSelectedProductId = rowVals.productId;}              
                  displayedData.forEach(function(curr){
                    if(curr.customIndex != rowVals.customIndex){
                          newWrap.push(curr);
                    }
                  });
                  this.prodList = newWrap;
                  this.rawdata = this.prodList;
              }
          }else{
            this.customErrorMessages.forEach(currentItem => {
              if(currentItem.Message_Label__c === 'Replacment_Not_Found'){
                    this.message = currentItem.Error_Message__c;
                }
              });
            this.showmsg = true;
            this.showSpinner =  false;
          }
          
      })
      .catch((error) => {
        this.error = JSON.stringify(error);
        this.prodList = undefined;
        this.showSpinner = false;
        this.rawdata = undefined;
      });
    } 
    catch (error) {
          this.prodList = undefined;
          this.handleCatch(false, error);
      }   
  }
  
  get showChildAttributesSection(){
    if(this.selectedRowval != undefined && this.selectedRowval != null){
        return this.selectedRowval.showAssets || this.selectedRowval.showAttributeSection;
    }else{
      return false;
    }    
  }

  handleRadioChange(event) {
      try { 
          let cIndex = event.currentTarget.dataset.customIndex;
          this.showSpinner = true;                  
          this.prodList = selectedValueSKU(this.prodList, cIndex);
          if(this.rawdata.length != this.prodList.length){
              this.rawdata = selectedValueSKU(this.rawdata, cIndex);
          }else{
              this.rawdata = this.prodList;
          }          
          this.selectedRowval = attributeSectionCheck(this.prodList, true,this.assetSelectedProductId, this.multiAddSelectedProductId,this.selectedRowval);
          if(this.entdata != undefined){
            this.selectedRowval = assetNonAssetTypeCheck(this.entdata, this.selectedRowval); 
            if(this.selectedRowval.showAssets == true){
              this.assetSelectedProductId = this.selectedRowval.productId;
            }                         
          }
          if (this.showmsg === true) {
              this.showmsg = false;
              this.message = '';
          }          
          this.showSpinner = false;
      } catch (error) {
          this.prodList = undefined;
          this.handleCatch(false, error);
      }
  }

  handleSkuAssetNonAssetChange(event){
      try{
        let sourcePath = event.detail.sourcepath;
        let rowFound = false;
        this.selectedRowval = event.detail.rowselpath;
        console.log('pathFromChild is ', event.detail.pathFromChild);
        this.selectedRowval.pathFromSKU = event.detail.pathFromChild;        
          console.log('Received from Path11111:', JSON.stringify(this.selectedRowval));
          let anyErrors = this.checkDataValidforPathSKU(this.selectedRowval);
          if(anyErrors == false){
                this.showmsg = false;
                this.message = '';
                this.showSpinner = false
          }
      }catch(error){
        this.handleCatch(false, error);
      }
  }
  
  handleDoubleClick(event) {
        event.preventDefault();
        event.stopPropagation();
    }

  async handleOkay(event) {
    
    debugger;
    this.showSpinner = true;
        let rowsVal = this.selectedRowval;        
        let ent = this.entsData;
        if (rowsVal != null) {              
              try{  
                            if (!this.validateData(ent)){
                              return;
                            }
                            rowsVal = calculateConsolidation(rowsVal, ent);
                            if(rowsVal.attributeEligibleCheck == true && this.dataFromChild != undefined){     
                                if(!this.checkDataValidity(this.dataFromChild)){ 
                                        this.showmsg = false;
                                        this.message = '';
                                        this.calculateDispositionAndFireEvent(ent);
                                }else{  
                                        this.showSpinner = false;
                                        this.showmsg = true;
                                        this.customErrorMessages.forEach(currentItem => {
                                        if(currentItem.Message_Label__c === 'Resolve_All_Errors'){
                                              this.message = currentItem.Error_Message__c;
                                          }
                                        });
                                }   
                            }else{  
                                this.calculateDispositionAndFireEvent(ent);
                            }                   
                  } catch (error) {
                      this.error = error;
                      this.showSpinner = false;
                      this.prodList = undefined;
                      this.handleCatch(false, error);
                  }          
                        
            } else {
              let optionError;
              this.customErrorMessages.forEach(currentItem => {
              if(currentItem.Message_Label__c === 'Option_Select_Error'){
                    optionError = currentItem.Error_Message__c;
                }
              });
              Toast.show(
                {
                                            label: 'Toast Message',                                 
                                            message: optionError,                                   
                                            mode: 'sticky',
                                            variant: 'info'
                },
                this
                );
                this.showSpinner = false;
            }
  }

  
  handleSkuAttributes(event){
    try{
      this.dataFromChild = event.detail.dataFromInnerChild;
        console.log('Received from child:', JSON.stringify(this.dataFromChild));
        let anyErrors = this.checkDataValidity(this.dataFromChild);
        if(anyErrors == false){
              this.showmsg = false;
              this.message = '';
        }
    }catch(error){
      this.handleCatch(false, error);
    }        
  }

  checkDataValidity(dataFromChild){   
    let anyErrors = false;
    let displayedData = JSON.parse(JSON.stringify(dataFromChild));
        displayedData.forEach(currentItemWrapper => {
                currentItemWrapper.columns.forEach(currItem =>{
                    if(currItem.errorOccured == true){
                      anyErrors = true;
                    }
                });
        });
    return anyErrors;
  }
  
  checkDataValidforPathSKU(selRowVal){
     let anyErrors = false;
     if(selRowVal.errors === 'Error Occured'){
        anyErrors = true;
        this.showmsg = true;
        this.customErrorMessages.forEach(currentItem => {
              if(currentItem.Message_Label__c === 'Resolve_All_Errors'){
                  this.message = currentItem.Error_Message__c;
                 }
              });
        this.showSpinner = false;
     }
     return anyErrors;
  }

  validateData(ent){
    //FY25SR-1875 - Start
    if(this.disableValidations){
      return true;
    }
    //FY25SR-1875 - End 
    let isValid = true;
    let upgradedEntIds = [];

    if(this.entsDataAll != undefined && this.entsDataAll.length >0){
      //CPQ22-5939 exclude renewal
      if(this.quoteDetails.SBQQ__Type__c != 'Renewal'){
        for (let bundleWrapper of this.entsDataAll){
            if (bundleWrapper.wrapUpgradeEnt){
              for (let upgradeWrapper of bundleWrapper.wrapUpgradeEnt){
                  if (upgradeWrapper.entitlementId && bundleWrapper.baseProdIds){
                    upgradedEntIds.push(bundleWrapper.baseProdIds.split(','))
                  }
              }
            }
          }

          if (JSON.stringify(upgradedEntIds).includes(ent.entitlementId)){
            this.customErrorMessages.forEach(currentItem => {
            if(currentItem.Message_Label__c === 'Replacement_on_Upgraded_SKU'){
                  this.message = currentItem.Error_Message__c;
              }
            });
            this.showmsg = true;
            this.showSpinner = false;
            isValid = false;
          }
          }
    }
    
   return isValid;
  }

  handleCatch(spinnerValue, error) {
    this.showSpinner = spinnerValue;
    this.message = error;
    this.showmsg = true;
    this.showErrorToast(error);
  }
  
  calculateDispositionAndFireEvent(ent){                      
                      let rowsel = this.selectedRowval;
                      let cindex = this.customIndex;
                      if(!this.checkDataValidforPathSKU(rowsel)){
                      if(this.dataFromChild != undefined){
                          let mappingSkuAttributes = {};
                          let displayedData = JSON.parse(JSON.stringify(this.dataFromChild));
                          displayedData.forEach(currentItemWrapper => {
                                  currentItemWrapper.columns.forEach(currItem =>{
                                    if(currItem.fieldValue != undefined && currItem.fieldValue != null && currItem.fieldValue != 'null'){
                                      mappingSkuAttributes[currItem.fieldApiName] = currItem.fieldValue;                                    
                                    }
                                  });
                          });
                          if(this.quoteDetails.SBQQ__Type__c === 'Renewal+Expansion'){ 
                                        rowsel.dispositionReason = 'Conversion'; 
                          }else if(this.quoteDetails.SBQQ__Type__c === 'Renewal'){
                                        rowsel.dispositionReason = 'Renew Now';
                          }
                          
                          rowsel.childMappingSKUattributes = mappingSkuAttributes;                     
                      }else{
                          let mapUpgValues = new Map();                          
                          if(rowsel.mapUpgradeMapping != undefined){
                              for(var key in rowsel.mapUpgradeMapping){
                                mapUpgValues.set(key, rowsel.mapUpgradeMapping[key]);
                            } 
                          } 
                          if(this.quoteDetails.SBQQ__Type__c === 'Renewal+Expansion'){ 
                            if(ent.oldProductEdition != undefined && rowsel.productEdition != undefined && rowsel.productLicenseSubCategory != undefined && ent.SrprodLicSubCategoryVal != undefined && rowsel.productLicenseSubCategory === ent.SrprodLicSubCategoryVal){
                                    let editionMap = ((ent.oldProductEdition+rowsel.productEdition).split(' ').join('')).toLowerCase();
                                      if(mapUpgValues.has(editionMap) && mapUpgValues.get(editionMap) != undefined && mapUpgValues.get(editionMap) == 'Upgrade'){
                                              rowsel.dispositionReason = mapUpgValues.get(editionMap);
                                      }else{
                                            rowsel.dispositionReason = 'Conversion';
                                      }                          
                            }else{
                                rowsel.dispositionReason = 'Conversion';
                            }                              
                          }else if(this.quoteDetails.SBQQ__Type__c === 'Renewal'){
                                        rowsel.dispositionReason = 'Renew Now';
                          }
                      }
                        if(rowsel.enablePaymentSwitchRE != undefined && rowsel.enablePaymentSwitchRE == true){
                                    rowsel.dispositionReason = 'Renew Now';
                        } 
                        //FY25SR-1557 START
                        if(rowsel.sourceToDestinationMatrix != undefined){
                          let targetRep = [];
                          targetRep = rowsel.sourceToDestinationMatrix;
                          if(rowsel.productReplacementCategory != undefined){
                               if(targetRep.includes(rowsel.productReplacementCategory)){
                                        rowsel.anyToAnyFlag = false;
                                  }else if(rowsel.productReplacementCategory != 'Not Replaceable'){
                                        rowsel.anyToAnyFlag = true;
                                  }
                          }
                        }
                        //FY25SR-1557 END
                        //FY25SR-2232 START 
                        if(this.quoteDetails.SBQQ__Type__c === 'Renewal'){
                                  rowsel.anyToAnyFlag = false;
                        }
                        //FY25SR-2232 END
                        this.selectedRowval = rowsel;
                        this.showSpinner = false;
                        rowsel = this.selectedRowval;
                       // const selectEvent = new CustomEvent('skuselect', {
                      //  detail: { cindex, rowsel }
                       // });
                      //  this.dispatchEvent(selectEvent);  
                        /*****************************/
                        const dataVal = {
                          cindex : cindex,
                          rowsel : rowsel
                        }
                        this.template.querySelector('c-new-rep-event-wrapper').sendEventWrap(dataVal);
                        /****************************/
                      //  this.close('okay');
                      }
  }

  handleSkuData(event){
      console.log('inside handleSKU event11 22 ', JSON.stringify(event.detail.value));
      this.close(event.detail.value);
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

  handleSearchProduct(event) {
    try{
        this.showSpinner = true;
        this.searchProdName = event.target.value;
        this.prodList = dataFilter(this.searchProdName, this.searchProdDes,this.prdtypeval, this.prdlictypeval, this.prdlicCatval, this.rawdata);
        let recordFound = checkRowSelectionInPrdFilter(this.prodList,this.selectedRowval);
        if(recordFound == true){
            this.prodList = selectedSkuAfterFilter(this.prodList,this.selectedRowval);
            if(this.selectedRowval != undefined && this.selectedRowval != null){
              this.selectedRowval = attributeSectionCheck(this.prodList,false,this.assetSelectedProductId, this.multiAddSelectedProductId,this.selectedRowval); 
            }
        }    
        this.showSpinner = false;               
    }
    catch(error){
      this.handleCatch(false, error);
    }
    
  }

  handleprodDescription(event) {
    try{
        this.showSpinner = true;  
        this.searchProdDes = event.target.value;
        this.prodList = dataFilter(this.searchProdName, this.searchProdDes,this.prdtypeval, this.prdlictypeval, this.prdlicCatval, this.rawdata);
        let recordFound = checkRowSelectionInPrdFilter(this.prodList,this.selectedRowval);
        if(recordFound == true){
            this.prodList = selectedSkuAfterFilter(this.prodList,this.selectedRowval);
            if(this.selectedRowval != undefined && this.selectedRowval != null){
              this.selectedRowval = attributeSectionCheck(this.prodList,false,this.assetSelectedProductId, this.multiAddSelectedProductId,this.selectedRowval); 
            }
        }
        this.showSpinner = false;
    }catch(error){
      this.handleCatch(false, error);
    }
  }

  handleProdTypeChange(event) {
    try{
      this.showSpinner = true;
      this.prdtypeval = event.detail.value;    
      this.prodList = dataFilter(this.searchProdName, this.searchProdDes,this.prdtypeval, this.prdlictypeval, this.prdlicCatval, this.rawdata);
      let recordFound = checkRowSelectionInPrdFilter(this.prodList,this.selectedRowval);
        if(recordFound == true){
            this.prodList = selectedSkuAfterFilter(this.prodList,this.selectedRowval);
            if(this.selectedRowval != undefined && this.selectedRowval != null){
              this.selectedRowval = attributeSectionCheck(this.prodList,false,this.assetSelectedProductId, this.multiAddSelectedProductId,this.selectedRowval); 
            }
        }
      this.showSpinner = false;
    }catch(error){
      this.handleCatch(false, error);
    }    
  }

  handleProdLicTypeChange(event) {
    try{
      this.showSpinner = true;
      this.prdlictypeval = event.detail.value;
      this.prodList = dataFilter(this.searchProdName, this.searchProdDes,this.prdtypeval, this.prdlictypeval, this.prdlicCatval, this.rawdata);
      let recordFound = checkRowSelectionInPrdFilter(this.prodList,this.selectedRowval);
        if(recordFound == true){
            this.prodList = selectedSkuAfterFilter(this.prodList,this.selectedRowval);
            if(this.selectedRowval != undefined && this.selectedRowval != null){
              this.selectedRowval = attributeSectionCheck(this.prodList,false,this.assetSelectedProductId, this.multiAddSelectedProductId,this.selectedRowval); 
            }
        }
      this.showSpinner = false;
    }catch(error){
      this.handleCatch(false, error);
    }     
  }

  handleProdLicCatChange(event) {
    try{
        this.showSpinner = true;
        this.prdlicCatval = event.detail.value;
        this.prodList = dataFilter(this.searchProdName, this.searchProdDes,this.prdtypeval, this.prdlictypeval, this.prdlicCatval, this.rawdata);
        let recordFound = checkRowSelectionInPrdFilter(this.prodList,this.selectedRowval);
        if(recordFound == true){
            this.prodList = selectedSkuAfterFilter(this.prodList,this.selectedRowval);
            if(this.selectedRowval != undefined && this.selectedRowval != null){
              this.selectedRowval = attributeSectionCheck(this.prodList,false, this.assetSelectedProductId, this.multiAddSelectedProductId,this.selectedRowval); 
            }
        }
        this.showSpinner = false;
    }catch(error){
      this.handleCatch(false, error);
    }    
  }

  

  /************************************************************/

  tableOuterDivScrolled(event) {
        this._tableViewInnerDiv = this.template.querySelector(".tableViewInnerDiv");
        if (this._tableViewInnerDiv) {
            if (!this._tableViewInnerDivOffsetWidth || this._tableViewInnerDivOffsetWidth === 0) {
                this._tableViewInnerDivOffsetWidth = this._tableViewInnerDiv.offsetWidth;
            }
            this._tableViewInnerDiv.style = 'width:' + (event.currentTarget.scrollLeft + this._tableViewInnerDivOffsetWidth) + "px;" + this.tableBodyStyle;
        }
        this.tableScrolled(event);
    }
 
    tableScrolled(event) {
        if (this.enableInfiniteScrolling) {
            if ((event.target.scrollTop + event.target.offsetHeight) >= event.target.scrollHeight) {
                this.dispatchEvent(new CustomEvent('showmorerecords', {
                    bubbles: true
                }));
            }
        }
        if (this.enableBatchLoading) {
            if ((event.target.scrollTop + event.target.offsetHeight) >= event.target.scrollHeight) {
                this.dispatchEvent(new CustomEvent('shownextbatch', {
                    bubbles: true
                }));
            }
        }
    }
 
    //#region ***************** RESIZABLE COLUMNS *************************************/
    handlemouseup(e) {
        this._tableThColumn = undefined;
        this._tableThInnerDiv = undefined;
        this._pageX = undefined;
        this._tableThWidth = undefined;
    }
 
    handlemousedown(e) {
        if (!this._initWidths) {
            this._initWidths = [];
            let tableThs = this.template.querySelectorAll("table thead .dv-dynamic-width");
            tableThs.forEach(th => {
                this._initWidths.push(th.style.width);
            });
        }
 
        this._tableThColumn = e.target.parentElement;
        this._tableThInnerDiv = e.target.parentElement;
        while (this._tableThColumn.tagName !== "TH") {
            this._tableThColumn = this._tableThColumn.parentNode;
        }
        while (!this._tableThInnerDiv.className.includes("slds-cell-fixed")) {
            this._tableThInnerDiv = this._tableThInnerDiv.parentNode;
        }
        this._pageX = e.pageX;
 
        this._padding = this.paddingDiff(this._tableThColumn);
 
        this._tableThWidth = this._tableThColumn.offsetWidth - this._padding;
    }
 
    handlemousemove(e) {
        if (this._tableThColumn && this._tableThColumn.tagName === "TH") {
            this._diffX = e.pageX - this._pageX;
 
            this.template.querySelector("table").style.width = (this.template.querySelector("table") - (this._diffX)) + 'px';
 
            this._tableThColumn.style.width = (this._tableThWidth + this._diffX) + 'px';
            this._tableThInnerDiv.style.width = this._tableThColumn.style.width;
 
            let tableThs = this.template.querySelectorAll("table thead .dv-dynamic-width");
            let tableBodyRows = this.template.querySelectorAll("table tbody tr");
            let tableBodyTds = this.template.querySelectorAll("table tbody .dv-dynamic-width");
            tableBodyRows.forEach(row => {
                let rowTds = row.querySelectorAll(".dv-dynamic-width");
                rowTds.forEach((td, ind) => {
                    rowTds[ind].style.width = tableThs[ind].style.width;
                });
            });
        }
    }
 
    handledblclickresizable() {
        let tableThs = this.template.querySelectorAll("table thead .dv-dynamic-width");
        let tableBodyRows = this.template.querySelectorAll("table tbody tr");
        tableThs.forEach((th, ind) => {
            th.style.width = this._initWidths[ind];
            th.querySelector(".slds-cell-fixed").style.width = this._initWidths[ind];
        });
        tableBodyRows.forEach(row => {
            let rowTds = row.querySelectorAll(".dv-dynamic-width");
            rowTds.forEach((td, ind) => {
                rowTds[ind].style.width = this._initWidths[ind];
            });
        });
    }
 
    paddingDiff(col) {
 
        if (this.getStyleVal(col, 'box-sizing') === 'border-box') {
            return 0;
        }
 
        this._padLeft = this.getStyleVal(col, 'padding-left');
        this._padRight = this.getStyleVal(col, 'padding-right');
        return (parseInt(this._padLeft, 10) + parseInt(this._padRight, 10));
 
    }
 
    getStyleVal(elm, css) {
        return (window.getComputedStyle(elm, null).getPropertyValue(css))
    }

    /**************************************************************** */
}