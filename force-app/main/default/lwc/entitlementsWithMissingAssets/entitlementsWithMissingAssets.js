import { LightningElement,api, wire, track } from 'lwc';
import getEntList from '@salesforce/apex/EntitlementsWithMissingAssestCtrl.getEntitlemetsWithMissingAssets';
//, target: '_blank'
import { loadScript } from "lightning/platformResourceLoader";
import workbook from "@salesforce/resourceUrl/writeexcelfile";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const columns = [
    {
        label: 'Name', fieldName: 'EntitlementURL', type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'Name'
            }
        }
    },
    {
        label: 'Order Line', fieldName: 'orderLineURL', type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'orderLine'
            }
        }
    },
    {
        label: 'Order', fieldName: 'orderURL', type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'order'
            }
        }
    },
    {
        label: 'Order Process Type', fieldName: 'orderProcessType', type: 'text'
    },
    {
        label: 'Shipment Status', fieldName: 'orderShipmentStatus', type: 'text'
    },
    {
        label: 'Support Start Date', fieldName: 'supportStartDate', type: 'date',
        typeAttributes: {
            day: "numeric",
            month: "numeric",
            year: "numeric"
        }
    },
	{
        label: 'Notes', fieldName: 'notes', type: 'text'
    },

];



export default class EntitlementsWithMissingAssets extends LightningElement {
    /*@api tableData;
    @api tableColumns;
    @api filterColumnsAPINames=["Name", "OrderLine", "Order","OrderProcessType"];
    @api filterColumnLabels=["Name", "Billing Country", "Rating"];
    filterData = [];
    tableDataCopy;
    pillData = [];*/
   
    @track missingAssetsDataDisplay = [];
    @track missingAssetsData = [];
    @track startDate;
    @track endDate;
    @track endDateError = '';
    clisWithAssets = new Map();
    columns = columns;
    showTable = false;
    disableFilterBTN = false;
    filteredData = [];
    timer;
    filterBy = "Name";
    condition = "Filter In"
    isLoaded = false;
    value;
    /*theQuery = 'SELECT CreatedDate, Id, Name, Order_Service_Item__r.OrderItemNumber, Order_Service_Item__c,'+ 
    'StartDate, EndDate, Order_Service_Item__r.Order.OrderNumber,   Order_Service_Item__r.OrderId,'+ 
    'Order_Service_Item__r.Order.ProcessType__c, Order_Service_Item__r.Order.SD_Status__c, Notes__c'+
    'FROM  Entitlement'+ 
    'WHERE AssetId = null AND Product__r.Product_Type__c != \'Training\' AND Entitlement_Status__c != \'Expired\''+
    'AND('+
        '('+  
            'Order_Service_Item__r.Order.Is_RWD_Polaris_Quote__c = false'+
            'AND('+
                '(Product__r.Category__c =\'Support\' '+
                    'OR Product__r.Product_Subtype__c IN (\'GO\',\'Rubrik Promo\',\'Saas Cloud\')'+
                    'OR Product__r.Product_Type__c =\'NFR\''+
                ')'+
                'OR('+
                    'Product__r.Product_Level__c = \'Hybrid Software\''+
                    'AND (Product__r.Product_Subtype__c = \'SaaS Cloud\' OR Product__r.Product_Type__c IN (\'Complete\',\'Complete Elite\',\'Complete Pro\')'+
                        'OR Product__r.Family = \'Third Party License\')'+
                ')'+
                'OR('+
                    'Product__r.Product_Level__c = \'On Prem\' AND  Product__r.Product_Type__c IN (\'Foundation Edition\',\'Business Edition\',\'Enterprise Edition\')'+
                ')'+ 
                'OR Product__r.Product_Level__c = \'LOD Software\''+
            ')'+
        ')'+
        'OR('+
            'Order_Service_Item__r.Order.Is_RWD_Polaris_Quote__c = true'+
            'AND('+
                '(Product__r.Product_Type__c  = \'HW Support\' AND Product__r.Product_Level__c = \'Support\')'+
                'OR'+ 
                '(Product__r.Product_Type__c  = \'RCDM Support\' AND Product__r.Product_Level__c = \'Support\')'+
            ')'+
        ')'+
    ')'+
    'AND Name NOT IN : lstProductName'+
    'AND Order_Service_Item__r.Order.Type != \'POC\''+ 
    'AND (NOT(Product__r.Product_Type__c  = \'NFR\' AND Product__r.Product_Subtype__c  = \'RCDM\' ))'+
    'AND (Product__r.Family not in (\'CEM\', \'Dell\', \'HPE\', \'UCS\',\'ASE\'))'+
    'AND Product__r.Id NOT IN :lstProdsExclude'+
    'AND AccountId NOT IN :lstAccountsExclude'+
    'AND (Order_Service_Item__r.Required_by_Product_Code__c  != null'+   
    'AND'+
    '(Order_Service_Item__r.SBQQ__QuoteLine__r.Required_By_Product_Code__c != null'+
        'OR'+ 
        '(   Order_Service_Item__r.SBQQ__QuoteLine__r.Required_By_Product_Code__c = null'+ 
            'AND'+
            '('+
                'Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__ProductOption__r.SBQQ__ConfiguredSKU__r.Product_Type__c != \'Add-On Node\''+ 
                'OR Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__ProductOption__r.SBQQ__ConfiguredSKU__r.Appliance_Model__c = null'+
                'OR Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__ProductOption__r.SBQQ__ConfiguredSKU__r.Item_Type__c = \'Serialized Inventory Item\''+
            ')'+
        ')'+
    ')'+   
')'+
'ORDER BY CreatedDate desc';*/

    async connectedCallback() {
        //this.getQuarterDates();
        await  loadScript(this, workbook );
        this.getEntitlementRecords();
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
		/*if(this.currentTab == 3){
			sheetName = 'Asset Quantity Mismatch Report'
			filename ='Asset Quantity Mismatch Report.xlsx'
		}*/
		
		const workbook = XLSX.utils.book_new();
		const headers = [];
		const worksheetData = [];	
		let nameToLabelMap ={
			"Entitlement  Name":"Name",
			"Order Line":"orderLine",
			"Order":"order",
			"Order Process Type":"orderProcessType",
			"Order Shiment Status":"orderShipmentStatus",
            "Notes":"notes"
            
		}
		//console.log(nameToLabelMap);
		this.missingAssetsDataDisplay.forEach((row)=>{	
				let rowObj ={}
				
					for (let key in nameToLabelMap) {
						rowObj[key] = row[nameToLabelMap[key]];
					  }		  
					worksheetData.push(rowObj)
				
				
	
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

    getEntitlementRecords(){
        getEntList()
            .then(result => {
                this.isLoaded = true;
                result = JSON.parse(JSON.stringify(result));
                console.log('result data : ', JSON.stringify(result));
                result.forEach((ent) => {
					if((ent.Order_Service_Item__r.Order.SD_Status__c !== undefined && ent.Order_Service_Item__r.Order.ProcessType__c === 'Aspen') || ent.Order_Service_Item__r.Order.ProcessType__c !== 'Aspen'){
						if(!ent?.Notes__c?.includes('without chassis')  &&
                           !ent?.Notes__c?.includes('Virtual AddOn Node') ||
                            (ent?.Notes__c == null && ent?.Notes__c == undefined)){

                        let tempEnt1 = { EntitlementURL: '', Name: '', orderLineURL: '', orderLine: '', orderURL: '', order: '', orderProcessType: '', orderShipmentStatus: '', supportStartDate: '', notes: ''};
                            tempEnt1.EntitlementURL = '/' + ent.Id;
                            tempEnt1.Name = ent.Name;
                            tempEnt1.orderLineURL = '/' + ent.Order_Service_Item__c;
                            tempEnt1.orderLine = ent.Order_Service_Item__r.OrderItemNumber;
                            tempEnt1.orderURL = '/' + ent.Order_Service_Item__r.OrderId;
                            tempEnt1.order = ent.Order_Service_Item__r.Order.OrderNumber;
                            tempEnt1.orderProcessType = ent.Order_Service_Item__r.Order.ProcessType__c;
                            tempEnt1.orderShipmentStatus = ent.Order_Service_Item__r.Order.SD_Status__c;
                            tempEnt1.supportStartDate = ent.StartDate;
							tempEnt1.notes = ent.Notes__c;
                            this.missingAssetsData = [...this.missingAssetsData, tempEnt1];
                        }
					}
                })
                this.missingAssetsDataDisplay = this.missingAssetsData;
                this.filteredData = this.missingAssetsData;
                if (this.missingAssetsDataDisplay.length > 0) this.showTable = true;
            })
    }

    filterHandler(event){
        this.value = event.target;
    }

    filterHandle(){
        const {value} = this.value;
        console.log('value :::>'+value);
        window.clearTimeout(this.timer);
        if(value){
            this.timer = window.setTimeout(()=>{
                this.filteredData = this.missingAssetsData.filter(eachObj =>{
                    const val = eachObj[this.filterBy] ? eachObj[this.filterBy]:'';
                    console.log('val :::>'+val);
                    console.log()
                    if(this.condition === 'Filter In'){
                        return val.includes(value);
                    }else{
                        return !val.includes(value);
                    }
                    
                    /*return Object.keys(eachObj).some(key =>{
                        return eachObj[key].toLowerCase().includes(value)
                    })*/
                });
            },0);
        }else{
            this.filteredData = [...this.missingAssetsData];
        }
    }
    get FilterByOptions(){
        return [
            {
                label: 'Name', value: 'Name'
            },
            {
                label: 'Order Line', value: 'orderLine'
            },
            {
                label: 'Order', value: 'order'
            },
            {
                label: 'Order Process Type', value: 'orderProcessType'
            },
            {
                label: 'Shipment Status', value: 'orderShipmentStatus'
            },
            {
                label: 'Notes', value: 'notes'
            }
            /*{
                label: 'Name', value: 'Name'
            }*/
        ];
    }

    filterByHandler(event){
        this.filterBy = event.target.value;
        console.log('filterBy :::>'+this.filterBy);
    }

    conditionHandler(event){
        this.condition = event.target.value;
    }

    get ConditionOption(){
        return[
            {
                label: 'Filter In', value: 'Filter In'
            },
            {
                label: 'Filter Out', value: 'Filter Out'
            }
        ]
    }
    filterText;
    handleFilterChange(event) {
		this.filterText = event.target.value;
		try {
			this.filteredData= this.missingAssetsDataDisplay.filter((item) => {
			

				if ((item.Name != undefined && item.Name.toLowerCase().includes(this.filterText.toLowerCase())) ||					
					(item.orderLine && item.orderLine.includes(this.filterText)) ||
					(item.order != undefined && item.order.toLowerCase().includes(this.filterText.toLowerCase())) ||
					(item.orderProcessType != undefined && item.orderProcessType.toLowerCase().includes(this.filterText.toLowerCase())) ||
					(item.orderShipmentStatus != undefined && item.orderShipmentStatus.toLowerCase().includes(this.filterText.toLowerCase())) 
					
					
					) {
					return item
				}

			});
		} catch (err) {
			console.error(err)
		}

		if (this.filterText == '' || this.filterText == undefined) {
			this.filteredData = this.missingAssetsDataDisplay;
		} 


	}
  
}