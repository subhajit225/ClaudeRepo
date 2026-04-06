/*******************************************************************************    
* @description       : Show Assets whose Product Usable Capaity is not matching with Linked Assets combined Usable capacity 
* @author            : Siva Kumar V
* @last modified on  : 02-06-2025
* Ver   Date          Author        Modification 
* 1.0   02-06-2025   Siva Kumar v   Initial Version 
*******************************************************************************/
  
import { LightningElement,api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getEntList from '@salesforce/apex/LCC_JSMQueryResultService.executeQuery';
import { loadScript } from "lightning/platformResourceLoader";
import workbook from "@salesforce/resourceUrl/writeexcelfile";
export default class AssetsWithMismatchedQuantities extends LightningElement {
  @api currentTab =11;
  error;
  showTable = false;
  consData = [];
  showSpinner = true;
  sortedBy='';
  parentData =[];
  filterText='';

  startDate;
  endDate;
  endDateError;
  disableFilterBTN;
  
  async connectedCallback() {
    this.calculateQuarterDates();
    this.loadEntitlements();
    await loadScript(this, workbook );
  }

  async loadEntitlements(){
    this.consData = [];
    this.showSpinner = true;
    let dateFilter = '';
    if (this.startDate && this.endDate) {
        dateFilter =
            'AND ((StartDate >= ' + this.startDate + ' AND StartDate <= ' + this.endDate + ')  OR (EndDate >= ' + this.startDate + ' AND EndDate <= ' + this.endDate + ')) ';
    }
    let entitlementsQuery = 'Select Id,Order_Number__c,Entitlement_Status__c,Notes__c,Failure_Category__c,Order_Product_Name__c,Order_Service_Item__c,Order_Service_Item__r.Required_by_Product_Code__c, Order_Service_Item__r.Order.ProcessType__c,Order_Service_Item__r.OrderId, Order_Service_Item__r.Product2.ProductCode, Order_Service_Item__r.SerialNumber__c, Order_Service_Item__r.Product2Id,Order_Service_Item__r.OrderItemNumber, Order_Service_Item__r.order.Bill_To_Name__c,Order_Service_Item__r.order.Bill_To_Name__r.Name, Name,Usage_Quantity__c,Order_Quantity__c, Quantity__c,Order_Service_Item__r.Order.SD_Status__c,'+
                '(select id, Asset__r.Name, Asset__r.Product2.Usable_Capacity__c, Asset__r.Product2.Name, Asset__r.Product2Id, Asset__r.Order_Service_Item__c, Asset__r.Order_Service_Item__r.OrderItemNumber, Asset__r.Order_Service_Item__r.OrderId, Asset__r.Order_Service_Item__r.Order.Bill_To_Name__c, Asset__r.Order_Service_Item__r.Order.SD_Status__c, Asset__r.Order_Service_Item__r.Order.Bill_To_Name__r.Name, Asset__r.Order_Number__c, Asset__r.Order_Service_Item__r.Order.ProcessType__c,' +
                'Entitlement__r.Name, Entitlement__r.Order_Quantity__c, Entitlement__r.Product__r.Name  from Scale_Entitlements__r WHERE Renewal_Category__c != \'Refreshed\') from Entitlement where (Entitlement_Status__c != \'Expired\' AND Type= \'Phone Support\' AND Order_Service_Item__r.order.order_status__c= \'Shipped\' AND Order_Service_Item__r.Order.Is_RWD_Polaris_Quote__c = true AND '+
                '(Order_Service_Item__r.Order.ProcessType__c != \'Aspen\' OR (Order_Service_Item__r.order.SD_Status__c= \'Success\' AND Order_Service_Item__r.Order.ProcessType__c = \'Aspen\') OR (Order_Service_Item__r.order.SD_Status__c != \'\' AND Order_Service_Item__r.Order.ProcessType__c = \'Aspen\')) AND ((Order_Service_Item__r.Product2.Product_Level__c = \'LOD Software\' OR Order_Service_Item__r.Product2.Product_Level__c = \'Hybrid Software\' OR (Order_Service_Item__r.Product2.Product_Level__c = \'OnPrem\' AND (Order_Service_Item__r.Product2.Product_Type__c = \'Foundation Edition\' OR Order_Service_Item__r.Product2.Product_Type__c = \'Business Edition\' OR Order_Service_Item__r.Product2.Product_Type__c = \'Enterprise Edition\'))) OR (Product__r.Category__c = \'Support\''+
                'AND Product__r.Product_Type__c = \'RCDM Support\'))AND ContractLineItem.Product_Category__c != \'Virtual Addon\' AND Order_Service_Item__r.Product2.Product_Subtype__c != \'Scale MSP\' AND  Order_Service_Item__r.Product2.Product_Type__c != \'RZTDP\' AND Order_Service_Item__r.Product2.Family != \'Rubrik Scale\' AND Order_Service_Item__r.Product2.Family != \'Third Party License\')';
    entitlementsQuery += dateFilter + ' ORDER BY StartDate DESC';  
    console.log('entitlementsQuery>>', entitlementsQuery);

    try {
      const data = await getEntList({ theQuery: entitlementsQuery });
      let assetToScaleEntitlements = new Map();
      let entitlementMap = new Map();
      let assetMap = new Map();
      data.forEach((entrecord) => {
          entitlementMap.set(entrecord.Id, entrecord);
          if(entrecord.Failure_Category__c == '' || entrecord.Failure_Category__c == undefined ){ // Dont Show Record For Failure Category For PRDOPS25-184
              if(entrecord.Scale_Entitlements__r) { // Status != Refresh 
                  entrecord.Scale_Entitlements__r.forEach((linkedAsset) => {
                      if(assetToScaleEntitlements.has(linkedAsset.Asset__c)){
                          assetToScaleEntitlements.get(linkedAsset.Asset__c).push(linkedAsset);
                      }else{
                          assetToScaleEntitlements.set(linkedAsset.Asset__c, [linkedAsset]);
                      }	
                      assetMap.set(linkedAsset.Asset__c, linkedAsset.Asset__r);			
                  });
              }
          }
      });
      assetToScaleEntitlements.forEach((scaleEntitlements, assetId) => {
          let sumOfEntQuantity = 0;
          let assetRec = assetMap.get(assetId);
          let assetUsableCapacity = assetRec.Product2.Usable_Capacity__c != null ? assetRec.Product2.Usable_Capacity__c : 0;
          scaleEntitlements.forEach((linkedAsset) => {
            if(entitlementMap.has(linkedAsset.Entitlement__c)){
                let entOrdQuantity = entitlementMap.get(linkedAsset.Entitlement__c).Order_Quantity__c;
                sumOfEntQuantity += entOrdQuantity != null ? entOrdQuantity : 0;    
            }
          });
          if(assetRec.Product2.Usable_Capacity__c != sumOfEntQuantity && assetRec.Product2Id != null
              && !assetRec.Product2.Name.includes('R6304') && !assetRec.Product2.Name.includes('R6304')){
            let assetRow = {};  
            assetRow.name = assetRec.Name;
            assetRow.assetUrl = '/lightning/r/Asset/' +assetId+'/view';
            assetRow.usableCapacity = assetRec.Product2.Usable_Capacity__c;
            assetRow.sumOfEntQuantity = sumOfEntQuantity;
            assetRow.diffInQuantity = Math.abs(assetUsableCapacity - sumOfEntQuantity);
            assetRow.scaleEntitlements = scaleEntitlements;
            assetRow.entLevelIdentifier = assetUsableCapacity > sumOfEntQuantity 
                                ? 'Capacity Mismatch - Missing Entitlement Association'
                                : 'Asset is fully covered, check entitlement identifier';
            assetRow.productName = assetRec.Product2.Name;     
            assetRow.productUrl = '/lightning/r/Product2/' +assetRec.Product2Id+'/view'; 
            if(assetRec.Order_Service_Item__c){
                assetRow.orderNumber = assetRec.Order_Number__c; 
                assetRow.orderUrl =  '/lightning/r/Order/'+assetRec.Order_Service_Item__r.OrderId+'/view';
                assetRow.orderProductNumber = assetRec.Order_Service_Item__r.OrderItemNumber;
                assetRow.orderItemUrl = '/lightning/r/OrderItem/' +assetRec.Order_Service_Item__c+'/view'; 
            }
            if(assetRec.Order_Service_Item__c && assetRec.Order_Service_Item__r.Order){
                assetRow.orderShipmentType = assetRec.Order_Service_Item__r.Order.SD_Status__c;
                assetRow.orderProcessType =  assetRec.Order_Service_Item__r.Order.ProcessType__c;
                if(assetRec.Order_Service_Item__r.Order.Bill_To_Name__c){
                    assetRow.billToNameURL = '/lightning/r/Account/' + assetRec.Order_Service_Item__r.Order.Bill_To_Name__c+'/view';
                    assetRow.billToName = assetRec.Order_Service_Item__r.Order.Bill_To_Name__r.Name;
                }
            }
            this.consData.push(assetRow);
          }
      });
      
      this.parentData = this.consData;
      this.showTable = this.consData.length > 0;
      this.showSpinner = false;
    }
    catch(exception){
      console.error('An error occurred:', exception.body ? exception.body.message : exception.message);
      this.showSpinner = false;
      let tempError = exception.body ? exception.body.message : exception.message;
      this.error = tempError.includes("Too many query rows") ?
          "This report doesn't support long date ranges due to technical limitations. Please try with a shorter date range." +
          "\n\nTechnical Error: " + tempError : tempError;
      this.showToastMessage('Error!', this.error);
    }          
  }

  calculateQuarterDates() {
    const today = new Date();
    const currentMonth = today.getMonth(); // Adding 1 to match Rubrik's fiscal year starting from February

    let quarterStartMonth;
    if (currentMonth >= 2 && currentMonth <= 4) { // February - April
        quarterStartMonth = 2; // February
    } else if (currentMonth >= 5 && currentMonth <= 7) { // May - July
        quarterStartMonth = 5; // May
    } else if (currentMonth >= 8 && currentMonth <= 10) { // August - October
        quarterStartMonth = 8; // August
    } else { // November - January
        quarterStartMonth = 11; // November
    }
    const qtStartDate = new Date(today.getFullYear(), quarterStartMonth - 1, 1);
    const qtEndDate = new Date(today.getFullYear(), quarterStartMonth + 2, 0);
    const offset = today.getTimezoneOffset();
    this.startDate = new Date(qtStartDate.getTime() - offset * 60000).toISOString().split('T')[0];
    this.endDate = new Date(qtEndDate.getTime() - offset * 60000).toISOString().split('T')[0];
  }

  handleSort(event) {
    this.showSpinner = true;
    const clickedField = event.currentTarget.dataset.field;

    // If the clicked field is sortable
    this.sortedBy = clickedField;
    this.sortedDirection = this.sortedDirection === 'asc' ? 'desc' : 'asc';

    // Sort the array
    this.consData = [...this.consData.sort((a, b) => this.sortData(a, b))];
      
  }

  sortData(a, b) {
    const field = this.sortedBy;
    console.log('field::', field);
    // Extract values for comparison
    const aValue = a[field];
    const bValue = b[field];

    // Implement your own logic for sorting based on the data type of the field
    // For string values, you can use localeCompare for case-insensitive sorting
    // For numeric values, you can subtract one from the other
    this.showSpinner = false;
    if (this.sortedDirection === 'asc') {
        return aValue > bValue ? 1 : -1;
    } else {
        return aValue < bValue ? 1 : -1;
    }
  }

  handleFilterChange(event) {
    this.filterText = event.target.value;
    try {
      this.consData= this.parentData.filter((item) => {
        let searchtext ='';
        if(item.scaleEntitlements != undefined && item.scaleEntitlements.length>0){
          item.scaleEntitlements.forEach((asset)=>{
            searchtext  += asset.Entitlement__r.Name+', '
          })
        }
        if ((item.name != undefined && item.name.toLowerCase().includes(this.filterText.toLowerCase())) ||	
                    (item.orderNumber && item.orderNumber.toLowerCase().includes(this.filterText.toLowerCase())) ||
          (item.billToName != undefined && item.billToName.toLowerCase().includes(this.filterText.toLowerCase())) ||
          (item.orderProductNumber != undefined && item.orderProductNumber.toLowerCase().includes(this.filterText.toLowerCase())) ||
          (item.requiredByProductCode != undefined && item.requiredByProductCode.toLowerCase().includes(this.filterText.toLowerCase())) ||
          (item.orderProcessType != undefined && item.orderProcessType.toLowerCase().includes(this.filterText.toLowerCase()))||				
          (item.entLevelIdentifier && item.entLevelIdentifier.toLowerCase().includes(this.filterText.toLowerCase())) ||
                    (searchtext != '' && searchtext.toLowerCase().includes(this.filterText.toLowerCase()))) {
          return item;
        }

      });
    } catch (err) {
      console.error('error in filter :: ',err);
    }

    if (this.filterText == '' || this.filterText == undefined) {
      this.consData = this.parentData;
    } 

}

  validateDates(event) {
    const { name, value } = event.target;
    if (name === 'StartDate') {
        this.startDate = value;
    } else if (name === 'EndDate') {
        this.endDate = value;
    }

    if (this.endDate < this.startDate) {
        this.endDateError = 'The End Date should not be lesser than the Start Date';
        this.disableFilterBTN = true;
    } else {
        this.endDateError = '';
        this.disableFilterBTN = false;
    }
  }

  handleFilterClick() {
    try {
        this.showTable = false;
        this.loadEntitlements();
    }catch (error) {
        console.error('An error occurred:', error.body ? error.body.message : error.message);
        this.cmpErrorMSG = error.body ? error.body.message : error.message;
    }
  }
  
  showToastMessage(title, errorMessage){
    const event = new ShowToastEvent({
        title: title,
        message: errorMessage,
    });
    this.dispatchEvent(event);
  }
    
}