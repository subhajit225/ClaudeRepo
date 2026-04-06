import { LightningElement, track } from 'lwc';
import fetchAssetsWithOrderLines from '@salesforce/apex/LCC_ButtonsController.fetchAssetsWithOrderLines';

export default class TradeUpUnflaggedReportLWC extends LightningElement {
    
    hasData = false;
    @track data = [];
    @track isLoading = true;
    columns = [
                {label: 'Account Name', fieldName: 'AccountName', type: 'text'},
                {label: 'Asset Name', fieldName: 'AssetName', type: 'text'},
                {label: 'Product Name', fieldName: 'ProductName', type: 'text'},
                {label: 'Sales Order', fieldName: 'OrderNumber', type: 'text'},
                {label: 'Purchase Date', fieldName: 'PurchaseDate', type: 'url '},
                {label: 'Quote Number', fieldName: 'QuoteNumber', type: 'url '},
                {label: 'orderItemNumber', fieldName: 'orderItem', type: 'url',typeAttributes: {label: { fieldName: 'OInumber' }, target: '_blank'}}
            ];

    connectedCallback() {
        this.loadData();
    }

    loadData() {
        this.isLoading = true;

        fetchAssetsWithOrderLines()
            .then(result => {
                this.data = result.map(item => {
                    return {
                        ...item,
                        orderItem: '/' + item.orderItemId
                    };
                });
                this.hasData = result && result.length > 0;
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error fetching data:', JSON.stringify(error));
                this.isLoading = false;
            });
    }
    
}