import { LightningElement,track,api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import chartJS from '@salesforce/resourceUrl/ChartJS_LWC';


export default class CS_LWC_chartJS extends LightningElement {
    @track isChartJsInitialized = false;
    @api recordId;
    @api chartData;  // Store data fetched from Apex
    error;     // Store any error that occurs
    @api chartName;
    @api chartId;
    @api location;
    tableColoumn= [];
    tableRow = [];
    cxScoreObj = [];
    cxScore = [];
    onboardingScore = [];
    adoptionScore = [];
    supportScore = [];
    productScore = [];
    renderedCallback() {
        if (this.isChartJsInitialized) {
            return;
        }
        this.isChartJsInitialized = true;
        Promise.all([
            loadScript(this, chartJS)
        ])
        .then(() => {
            // Chart.js library loaded
            this.initializePieChart();
        })
        .catch(error => {
            console.log('Error loading Chart.js');
            console.error(error);
        });
    }



    initializePieChart() {
        console.log('chartData: ', this.chartData);
        const labels = this.chartData.labelsList;
        let chartData = this. chartData.dataRowList;
        this.tableColoumn = labels;
        for(let i in labels){
            let row = chartData[i];
            let score = row.cxScore.toFixed(0);
            let style;
            let code;
            if (score < 30) {
                code = 'Fragille';
                style = 'background-color: rgb(222, 49, 99);';
            } else if (score >= 30 && score < 50) {
                code = 'Poor';
                style = 'background-color: rgb(228, 208, 10);';
            } else if (score >= 50 && score < 75) {
                code = 'Good';
                style = 'background-color: rgb(50, 205, 50);';
            }else{
                code = 'Excellent';
                style = 'background-color: rgb(100, 149, 237);';
            }
            style += 'font-weight: bold; color: white;';
            this.cxScoreObj.push({
                key :score,
                style: style,
                code: code
            });
            this.cxScore.push(score);
            this.onboardingScore.push(row.onboardingScore.toFixed(0));
            this.adoptionScore.push(row.adoptionScore.toFixed(0));
            this.supportScore.push(row.supportScore.toFixed(0));
            this.productScore.push(row.productScore.toFixed(0));
        }
        const data = {
        labels: labels,
        datasets: [
            {
                label: 'CX Score',
                data: this.cxScore,
                borderColor: 'rgb(212, 212, 212)',
                backgroundColor: 'rgba(212, 212, 212, 0.8)',
                type: 'bar',
                order: 4

            },
            {
                label: 'Onboarding Score',
                data: this.onboardingScore,
                borderColor: 'rgb(255, 99, 132)',
                backgroundColor: 'rgba(255, 99, 132, 0.5)',
                type: 'line',
                order: 3

            },
            {
                label: 'Adoption Score',
                data: this.adoptionScore,
                borderColor: 'rgb(75, 192, 192)',
                backgroundColor: 'rgba(75, 192, 192, 0.5)',
                type: 'line',
                order: 2
            },{
                label: 'Support Scrore',
                data: this.supportScore,
                borderColor: 'rgb(255, 205, 86)',
                backgroundColor: 'rgba(255, 205, 86, 0.5)',
                type: 'line',
                order: 1
            },{
                label: 'Product Score',
                data: this.productScore,
                borderColor: 'rgb(54, 162, 235)',
                backgroundColor: 'rgba(54, 162, 235, 0.5)',
                type: 'line',
                order: 0
            }
        ]
        };
        const config = {
            type: 'line',
            data: data,
            options: {
                plugins: {
                    legend: {
                    position: 'top',
                    },
                    title: {
                        display: false,
                        text: this.chartName
                    }
                },
                responsive: true,
                scales: {
                y: {
                    beginAtZero: true
                }
                }
            },
        };
        const canvasId = 'canvas[id*="'+this.chartId+'"]';
        console.log('canvasId: ', canvasId);
        const ctx = this.template.querySelector(canvasId).getContext('2d');
        console.log('ctx: ', ctx);

        let chartInstance = new window.Chart(ctx,config);
        chartInstance.resize(1500, 600);

    }
}