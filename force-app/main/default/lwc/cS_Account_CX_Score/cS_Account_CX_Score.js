import { LightningElement,track,api } from 'lwc';
import getChartData from '@salesforce/apex/CS_CX_Chart.getHistoricalCharts';


    export default class CS_Account_CX_Score extends LightningElement {
    @track isChartJsInitialized = false;
    @api recordId;
    @track chartData;  // Store data fetched from Apex
    error;     // Store any error that occurs
    monthlyData;
    weeklyData;
    quaterlyData;
    @track showCharts = false;
    @api confluenceLink;
    @api dashboardLink;
    
    connectedCallback() {
        // Call the Apex method imperatively
        getChartData({ accountId: this.recordId })
        .then((result) => {
            this.chartData = result;  // Store the data in the component
            this.monthlyData = this.chartData.monthlyCharts;
            this.weeklyData = this.chartData.weeklyCharts;
            this.quaterlyData = this.chartData.quaterlyCharts;
            this.showCharts = true;
            console.log('chartData: ', this.chartData.monthlyCharts);
        })
        .catch((error) => {
            this.error = error;  // Store the error if any occurs
            console.error('Error fetching accounts:', error);
        });
    }

    handleConfluenceLink(){
        window.open(this.confluenceLink, '_blank');
    }
    handleDashboardLink(){
        window.open(this.dashboardLink, '_blank');
    }


}