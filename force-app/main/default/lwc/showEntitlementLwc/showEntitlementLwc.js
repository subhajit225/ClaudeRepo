/*******************************************************************************     
* @description       : Show Entitlements whose Entitlement Capaity is not matching with Linked Assets combined Usable capacity 
* @author            : Nitin
* @last modified on  : 24-08-2021
* Ver   Date          Author        Modification 
* 1.0   23-08-2022   Nitin        Initial Version  
  2.0   17-01-2024	 Abir         Added excel download functionality
*******************************************************************************/
  
import { LightningElement,api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getEntList from '@salesforce/apex/LCC_JSMQueryResultService.executeQuery';
import getserviceOrders from '@salesforce/apex/LCC_JSMQueryResultService.executeQuery';
import { loadScript } from "lightning/platformResourceLoader";
import workbook from "@salesforce/resourceUrl/writeexcelfile";


export default class ShowEntitlementLwc extends LightningElement {    
	@api currentTab =3;
	@api assetTab;
	isMissingAsset = false;
    error;
	serviceOrderObject = {};
	EntitlementObjectNew;
	consData = [];
	showTable = false;
	sortedBy='';
    sortedDirection = 'asc'; // Initial sorting direction
    //
	showSpinner = true;
	theQuery = 'Select Id,Order_Number__c,Entitlement_Status__c,Notes__c,Product__r.Family, Product__r.Product_Subtype__c,Failure_Category__c,Order_Product_Name__c,Order_Service_Item__c,Order_Service_Item__r.Required_by_Product_Code__c, Order_Service_Item__r.Order.ProcessType__c,Order_Service_Item__r.OrderId, Order_Service_Item__r.Product2.ProductCode, Order_Service_Item__r.SerialNumber__c, Order_Service_Item__r.Product2Id,Order_Service_Item__r.OrderItemNumber, Order_Service_Item__r.order.Bill_To_Name__c,Order_Service_Item__r.order.Bill_To_Name__r.Name, Name,Usage_Quantity__c,Order_Quantity__c, Quantity__c,Order_Service_Item__r.Order.SD_Status__c,(select id,Asset__r.Name, Asset__r.Product2.Usable_Capacity__c, Asset__r.Product2.Name from Scale_Entitlements__r) from Entitlement where (Type= \'Phone Support\' AND Order_Service_Item__r.order.order_status__c= \'Shipped\' AND Order_Service_Item__r.Order.Is_RWD_Polaris_Quote__c = true AND '+
	'(Order_Service_Item__r.Order.ProcessType__c != \'Aspen\' OR (Order_Service_Item__r.order.SD_Status__c= \'Success\' AND Order_Service_Item__r.Order.ProcessType__c = \'Aspen\') OR (Order_Service_Item__r.order.SD_Status__c != \'\' AND Order_Service_Item__r.Order.ProcessType__c = \'Aspen\')) AND ((Order_Service_Item__r.Product2.Product_Level__c = \'LOD Software\' OR Order_Service_Item__r.Product2.Product_Level__c = \'Hybrid Software\' OR (Order_Service_Item__r.Product2.Product_Level__c = \'OnPrem\' AND (Order_Service_Item__r.Product2.Product_Type__c = \'Foundation Edition\' OR Order_Service_Item__r.Product2.Product_Type__c = \'Business Edition\' OR Order_Service_Item__r.Product2.Product_Type__c = \'Enterprise Edition\'))) OR (Product__r.Category__c = \'Support\''+
		'AND Product__r.Product_Type__c = \'RCDM Support\'))AND ContractLineItem.Product_Category__c != \'Virtual Addon\' AND Order_Service_Item__r.Product2.Family != \'Rubrik Scale\' AND Order_Service_Item__r.Product2.Product_Subtype__c != \'Scale MSP\' AND Order_Service_Item__r.Product2.Family != \'Third Party License\' AND  Order_Service_Item__r.Product2.Product_Type__c != \'RZTDP\') AND Status != \'Expired\'  AND (StartDate >= LAST_N_DAYS:280 OR CreatedDate >= LAST_N_DAYS:280) AND (NOT Notes__c LIKE \'%reviewed by installed base%\') AND Entitlement_Status__c != \'Terminated\' ';
	//theQuery = 'Select Id,Order_Number__c,Order_Product_Name__c,Order_Service_Item__c,Order_Service_Item__r.Order.ProcessType__c,Order_Service_Item__r.OrderId,Order_Service_Item__r.Product2Id,Order_Service_Item__r.OrderItemNumber,Name,Usage_Quantity__c,Order_Quantity__c,Quantity__c,(select  id,Asset__r.Name, Asset__r.Product2.Usable_Capacity__c, Asset__r.Product2.Name from Scale_Entitlements__r) from Entitlement  where (Type= \'Phone Support\' AND Order_Service_Item__r.order.order_status__c=\'Shipped\' AND (Order_Service_Item__r.Order.ProcessType__c != \'Aspen\'	or (Order_Service_Item__r.order.SD_Status__c=\'Success\' AND Order_Service_Item__r.Order.ProcessType__c = \'Aspen\')) AND  ((Order_Service_Item__r.Product2.Product_Type__c !=\'RZTDP\' AND (Order_Service_Item__r.Product2.Family !=\'Third Party License\' AND Order_Service_Item__r.Product2.Family !=\'Rubrik Scale\') AND (Order_Service_Item__r.Product2.Product_Level__c =\'On Prem\' OR Order_Service_Item__r.Product2.Product_Level__c =\'Hybrid Software\' OR Order_Service_Item__r.Product2.Product_Level__c =\'LOD Software\')) OR (Order_Service_Item__r.Product2.Product_Level__c = \'OnPrem\' AND Order_Service_Item__r.Product2.Product_Subtype__c = \'OnPrem LOD Addon\' AND Order_Service_Item__r.Order.Is_RWD_Polaris_Quote__c = true) OR (Order_Service_Item__r.Product2.Family = \'Rubrik Scale\' AND Order_Service_Item__r.order.SD_Status__c=\'Success\' AND Order_Service_Item__r.Order.ProcessType__c = \'Aspen\')))';
  
	tempConListNew = []; 
	parentData =[]
	filterText=''

	async  connectedCallback() {
       await  loadScript(this, workbook )  
	   if(this.assetTab == 'MissingAsset'){
		this.isMissingAsset=true
	   }  
    }

	@wire (getEntList,{theQuery: '$theQuery'})
	wiredEntitlements({data, error}){
		if(data) {
			console.log("this.consData::"+this.consData);
			console.log("data::"+data);
			let tempConList = []; 
			let orderServiceItemList = []; 
			let EntitlementObject = new Map();
			this.showSpinner = false;
            data.forEach((Entrecord) => {
			let usableCapacity = 0;
			console.log("Entrecord::"+Entrecord);
			if(Entrecord.Failure_Category__c == '' || Entrecord.Failure_Category__c == undefined ){ // Dont Show Record For Failure Category For PRDOPS25-184
			if(Entrecord && Entrecord.Scale_Entitlements__r) {
				Entrecord.Scale_Entitlements__r.forEach((linkedAsset) => {
				if(linkedAsset.Asset__r.Product2.Usable_Capacity__c != undefined && linkedAsset.Asset__r.Product2.Usable_Capacity__c !=null ){
					usableCapacity = usableCapacity + linkedAsset.Asset__r.Product2.Usable_Capacity__c;
				}				
				console.log("linkedAsset::"+linkedAsset);				
			});
			}
			console.log('Shipment Status ::::>'+Entrecord.Order_Service_Item__r.Order.SD_Status__c);
			if(Entrecord.Order_Quantity__c != usableCapacity && (Entrecord.Order_Service_Item__r.Order.ProcessType__c === undefined || (Entrecord.Order_Service_Item__r.Order.ProcessType__c === 'Aspen' && Entrecord.Order_Service_Item__r.Order.SD_Status__c !== undefined)) && Entrecord.Entitlement_Status__c !== 'Expired')
				//)
			{
				// 
				let tempRec = {};
				if(this.isMissingAsset){

				if(!Entrecord?.Notes__c?.toLowerCase().includes('without chassis') &&
			      (Entrecord?.Product__r?.Family != 'Rubrik Licence' || 
				  Entrecord?.Product__r?.Product_Subtype__c != 'Virtual')){
					tempRec = Object.assign({}, Entrecord);
					}
			    	}else{
				   	tempRec = Object.assign({}, Entrecord);
					}  
					
					if(Object.keys(tempRec).length != 0 && tempRec.Order_Service_Item__r)
					{
						tempRec.EntitlementURL = '/lightning/r/Entitlement/' +tempRec.Id+'/view';
						tempRec.OrderURL = '/lightning/r/Order/' +tempRec.Order_Service_Item__r.OrderId+'/view';
						tempRec.OrderServiceItem = tempRec.Order_Service_Item__r.OrderItemNumber;
						tempRec.requiredByProductCode = tempRec.Order_Service_Item__r.Required_by_Product_Code__c;
						tempRec.OrderProcessType = tempRec.Order_Service_Item__r.Order.ProcessType__c != undefined?tempRec.Order_Service_Item__r.Order.ProcessType__c:'';
						tempRec.ProductURL = '/lightning/r/OrderItem/' +tempRec.Order_Service_Item__c+'/view';
						tempRec.OrderServiceItemURL = '/lightning/r/OrderItem/' +tempRec.Order_Service_Item__c+'/view';
						tempRec.LinkedAssetQuantity = usableCapacity;
						tempRec.DiffOLIAndAssetQuntity = usableCapacity != 0 && Entrecord.Order_Quantity__c != usableCapacity ? Math.abs(Entrecord.Order_Quantity__c - usableCapacity) : null;
						tempRec.Notes = tempRec.Notes__c;
						if(tempRec && tempRec.Order_Service_Item__r.Order && tempRec.Order_Service_Item__r.Order.Bill_To_Name__c){
							console.log('Bill To Name Id : ',tempRec.Order_Service_Item__r.Order.Bill_To_Name__c);
							tempRec.BillToNameURL = '/lightning/r/Account/' + tempRec.Order_Service_Item__r.Order.Bill_To_Name__c+'/view';
							tempRec.BillToName = tempRec.Order_Service_Item__r.Order.Bill_To_Name__r.Name;
						}
						if(tempRec && tempRec.Order_Service_Item__r.Order && tempRec.Order_Service_Item__r.Order.SD_Status__c){
							tempRec.OrderShipmentType = tempRec.Order_Service_Item__r.Order.SD_Status__c;
						}
					
					tempConList.push(tempRec);
					orderServiceItemList.push(tempRec.Order_Service_Item__c);
					EntitlementObject.set(tempRec.Order_Service_Item__c,tempRec);
				}
			}
		    }
            });
			this.tempConListNew= tempConList;
			console.log("EntitlementObject::"+EntitlementObject);
			this.EntitlementObjectNew = EntitlementObject;
			this.getServiceOrdersList(orderServiceItemList);
			//create a set of Order_Service_Item__c of entitlements
			//fetch data of order service item with related order products and product's usable capacity and item type If Item type is ='Non-inventory Item' check LinkedAssetQuantity+ product's usable capacity with entitlement's Usage_Quantity__c if not matching no action if matching then remove from tempConList list 
			
			
		}
		else
		{
			const event = new ShowToastEvent({
            title: 'Error!',
            message: error,
            });
			this.dispatchEvent(event);
		}
	}
	
	getServiceOrdersList(orderServiceItemList){
		let serviceOrders = [];
		
			let queryString = 'Select Id,Product2.Name,(select  id,Product2Id,Product2.Item_Type__c,Product2.Usable_Capacity__c from SBQQ__Components__r where Product2.Item_Type__c = \'Non-inventory Item\') from OrderItem  where Id IN (\''+orderServiceItemList.join('\',\'')+'\')';
			
			console.log("queryString::"+queryString);
			 getserviceOrders({ theQuery : queryString })
				.then(result => {
					console.log("result::"+ JSON.stringify(result));
					this.serviceOrders = result;
					this.error = undefined;
					this.serviceOrders.forEach((orderObj) => {
						let orderusableCapacity = 0;
						if(orderObj && orderObj.SBQQ__Components__r) {
							orderObj.SBQQ__Components__r.forEach((relatedOrder) => {
							if(relatedOrder.Product2.Usable_Capacity__c)
							{
								orderusableCapacity = orderusableCapacity + relatedOrder.Product2.Usable_Capacity__c;
							}
						});
						}
						console.log("orderusableCapacity::"+orderusableCapacity);
						if(orderObj&& orderusableCapacity!= 0)
						{
								let tempRec = this.EntitlementObjectNew.get(orderObj.Id);
								console.log("tempRec::"+JSON.stringify(tempRec));
								if(tempRec && ( tempRec.LinkedAssetQuantity + orderusableCapacity == tempRec.Usage_Quantity__c ) )
								{
									console.log("this.tempConListNew before::"+this.tempConListNew);
									 this.arrayRemove(this.tempConListNew,tempRec);
								}	
						}
					});
					
					console.log("this.tempConListNew After::"+this.tempConListNew);
					console.log("this.serviceOrders::"+this.serviceOrders);
					if( this.tempConListNew &&  this.tempConListNew.length != 0 )
					{
						this.consData = this.tempConListNew;
						this.parentData =this.consData
						console.log('---->',this.consData.length)
						this.intitialFilter();
						console.log('---->',this.consData.length)
						this.showTable= true;
						this.showSpinner = false;
					}
						
					console.log("this.showTable::"+this.showTable);
					console.log("this.consData::"+this.consData);
					/*this.serviceOrders.forEach((ordProductrecord) => {
						this.serviceOrderObject[ordProductrecord.Id]=ordProductrecord
					});*/
				})
				.catch(error => {
					console.log("error::"+ error);
					this.showSpinner = false;
					const event = new ShowToastEvent({
					title: 'Error!',
					message: error,
					});
					this.dispatchEvent(event);
					this.error = error;
					this.serviceOrders = undefined;
				})
		
			//create a set of Order_Service_Item__c of entitlements
			//fetch data of order service item with related order products and product's usable capacity and item type If Item type is ='Non-inventory Item' check LinkedAssetQuantity+ product's usable capacity with entitlement's Usage_Quantity__c if not matching no action if matching then remove from tempConList list 
	}
	
	arrayRemove(arr, value) { 
    
        this.tempConListNew = arr.filter(function(ele){ 
            return ele != value; 
        });
    }

	handleFilterChange(event) {
		this.filterText = event.target.value;
		try {
			this.consData= this.parentData.filter((item) => {
				let searchtext ='';

				if(item.Scale_Entitlements__r != undefined && item.Scale_Entitlements__r.length>0){
					item.Scale_Entitlements__r.forEach((asset)=>{
						searchtext = searchtext + asset.Asset__r.Name +', ' +asset.Asset__r.Product2.Name+', '
					})
				}

				if ((item.Name != undefined && item.Name.toLowerCase().includes(this.filterText.toLowerCase())) ||					
					(item.Order_Number__c && item.Order_Number__c.toLowerCase().includes(this.filterText.toLowerCase())) ||
					(item.BillToName != undefined && item.BillToName.toLowerCase().includes(this.filterText.toLowerCase())) ||
					(item.OrderServiceItem != undefined && item.OrderServiceItem.toLowerCase().includes(this.filterText.toLowerCase())) ||
					(item.requiredByProductCode != undefined && item.requiredByProductCode.toLowerCase().includes(this.filterText.toLowerCase())) ||
					(item.OrderProcessType != undefined && item.OrderProcessType.toLowerCase().includes(this.filterText.toLowerCase()))||
					(searchtext != '' && searchtext.toLowerCase().includes(this.filterText.toLowerCase()))||				
					(this.filterText == '@' && item.OrderProcessType =='')
					
					) {
					return item
				}

			});
		} catch (err) {
			console.error(err)
		}

		if (this.filterText == '' || this.filterText == undefined) {
			this.consData = this.parentData;
		} 

	}

	intitialFilter(){
		this.consData = this.consData.filter((item) => {

			if ((item.Scale_Entitlements__r == undefined || item.Scale_Entitlements__r.length<1 ) && this.isMissingAsset) 
			{
			   return item
		   }
   		
			//console.log(this.consData)
			if ((item.Scale_Entitlements__r != undefined && item.Scale_Entitlements__r.length>0 ) &&  !this.isMissingAsset) 
				 {
					return item
				}
		})
		this.parentData = this.consData
	}


	async handleDownload() {
		try{
		  await this.exportToExcel();
		}catch(err){
			console.log(err);
		}
	}
	
	
	
	  exportToExcel() {		

		let sheetName = 'Missing Assets Report'
		let filename = 'Missing Assets Report.xlsx';
		if(this.currentTab == 3){
			sheetName = 'Asset Quantity Mismatch Report'
			filename ='Asset Quantity Mismatch Report.xlsx'
		}
		
		const workbook = XLSX.utils.book_new();
		const headers = [];
		const worksheetData = [];	
		let nameToLabelMap ={
			"Entitlement  Name":"Name",
			"Order Number":"Order_Number__c",
			"Bill To Name":"BillToName",
			"Order Product Number":"OrderServiceItem",
			"Order Process Type":"OrderProcessType"
            
		}

		
		//console.log(nameToLabelMap);
		this.consData.forEach((row)=>{	
				let rowObj ={}
				if(row.Scale_Entitlements__r != undefined && row.Scale_Entitlements__r.length>0){
					nameToLabelMap["Entitlement Quantity"]='Order_Quantity__c'
					nameToLabelMap["Diff B/W OLI Quantity"] ='DiffOLIAndAssetQuntity'
					
					for (let key in nameToLabelMap) {
						rowObj[key] = row[nameToLabelMap[key]];
					  }	
					  
					  let assetDetails =''
					row.Scale_Entitlements__r.forEach((iteration)=>{
						
						//  rowObj["Asset Name"]=iteration.Asset__r.Name
						//  rowObj["Product Name"]=iteration.Asset__r.Product2.Name
						 // rowObj["Usable Capacity"]=iteration.Asset__r.Product2.Usable_Capacity__c
						 assetDetails = assetDetails + iteration.Asset__r.Name +"("+iteration.Asset__r.Product2.Usable_Capacity__c+"), "
						  
					})
					if(assetDetails != '' && assetDetails != undefined){
						assetDetails=assetDetails.substring(0, assetDetails.length - 2);
						rowObj["Asset Details"] = assetDetails
					}
					
					worksheetData.push(rowObj)

				}else{
					for (let key in nameToLabelMap) {
						rowObj[key] = row[nameToLabelMap[key]];
					  }		  
					worksheetData.push(rowObj)
				}
				
	
		})
		//console.log(JSON.stringify(worksheetData))
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

		handleSort(event) {
			const clickedField = event.currentTarget.dataset.field;
		
			// If the clicked field is sortable
			 console.log(clickedField)

				this.sortedBy = clickedField;
				console.log(this.sortedBy)
				this.sortedDirection = this.sortedDirection === 'asc' ? 'desc' : 'asc';
		
				// Sort the array
				this.consData = [...this.consData.sort((a, b) => this.sortData(a, b))];
			
		}
		
		sortData(a, b) {
			const field = this.sortedBy;
			console.log(field)
			// Extract values for comparison
			const aValue = a[field];
			const bValue = b[field];
		
			// Implement your own logic for sorting based on the data type of the field
			// For string values, you can use localeCompare for case-insensitive sorting
			// For numeric values, you can subtract one from the other
		
			if (this.sortedDirection === 'asc') {
				return aValue > bValue ? 1 : -1;
			} else {
				return aValue < bValue ? 1 : -1;
			}
		}
		
		
}