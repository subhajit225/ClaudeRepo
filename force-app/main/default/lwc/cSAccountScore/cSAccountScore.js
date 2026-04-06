import { LightningElement ,track,api} from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import chartJS from '@salesforce/resourceUrl/gaugeJs';
import getScoreData from '@salesforce/apex/CS_CX_Chart.getAccountScore';



export default class CSAccountScore extends LightningElement {
    @api recordId;
    accountRecord;
    score;
    scoreSupport;
    scoreProduct;
    onboardingScoreDetails;
    adoptionScoreDetails
    renderBlock = false;
    scoreCode;
    isCSM;
    cemName;
    Rubrik_Sales_Engineer;
    ownerName;
    colorCode;
    onboardingStyle;
    adoptionStyle;
    productStyle;
    supportStyle;
    connectedCallback() {
        // Call the Apex method imperatively
        getScoreData({ accountId: this.recordId })
        .then((result) => {
            this.accountRecord = result.account; 
            this.onboardingScoreDetails = result.onboardingScoreDetails; 
            this.adoptionScoreDetails = result.adoptionScoreDetails;
            this.isCSM = this.accountRecord.Account_SAM__c !=null ? true : false;
            this.cemName = this.accountRecord.Account_SAM__c !=null ? this.accountRecord.Account_SAM__r.Name : '';
            this.ownerName = this.accountRecord.OwnerId !=null ? this.accountRecord.Owner.Name : '';
            this.Rubrik_Sales_Engineer = this.accountRecord.Rubrik_Sales_Engineer__c !=null ? this.accountRecord.Rubrik_Sales_Engineer__r.Name : '';
            let fieldNames = ['DEFECT_SCORE__c','RFE_SCORE__c','DEF_CNT__c','RF_CNT__c','DEFECT_FIXED__c','DEFECT_UNRESOLVED__c','RFES_COMMIT__c','RFES_PENDING_COMMIT__c',
                            'TTR_WITH_JIRA_SCORE__c','TTR_WITHOUT_JIRA_SCORE__c','P1_P2_CASECOUNT_SCORE__c','ESCALATIONS_SCORE__c','AVG_TTR_WITH_JIRA__c','AVG_TTR_WITHOUT_JIRA__c','P1_P2_CASE_COUNT__c','P1_CASE_COUNT__c','P2_CASE_COUNT__c','ESC_CNT__c'];
            let score = { ...result.score };  // Create a shallow copy
            let scoreProduct = { ...result.scoreProduct };  // Create a shallow copy
            let scoreSupport = { ...result.scoreSupport };  // Create a shallow copy

            for(let i in fieldNames){
                let fieldName = fieldNames[i];
                if(score[fieldName] == null){
                    score[fieldName] = 0;
                }
                if(scoreProduct[fieldName] == null){
                    scoreProduct[fieldName] = 0;
                }else if(scoreProduct[fieldName] != null){
                    scoreProduct[fieldName] = parseInt(scoreProduct[fieldName]);
                }
                if(scoreSupport[fieldName] == null){
                    scoreSupport[fieldName] = 0;
                }else if(scoreSupport[fieldName] != null){
                    scoreSupport[fieldName] = parseInt(scoreSupport[fieldName]);
                }
            }
            score.OnBoarding_Score__c = Math.round(score.OnBoarding_Score__c);
            score.Adoption_Score__c = Math.round(score.Adoption_Score__c);
            score.Product_Score__c = Math.round(score.Product_Score__c);
            score.Support_Score__c = Math.round(score.Support_Score__c);
            score.CX_Score__c = Math.round(score.CX_Score__c);
            let style = 'color:';
            if(score.OnBoarding_Score__c != null){
                if(score.OnBoarding_Score__c < 10){
                    this.onboardingStyle = style + '#FFBF00;';
                }
                if(score.OnBoarding_Score__c >= 10 && score.OnBoarding_Score__c < 20){
                    this.onboardingStyle = style + '#FFFF00;';
                }
                if(score.OnBoarding_Score__c >= 20 && score.OnBoarding_Score__c <= 30){
                    this.onboardingStyle = style + '#008000;';
                }
            }
            if(score.Adoption_Score__c != null){
                if(score.Adoption_Score__c < 10){
                    this.adoptionStyle = style + '#FFBF00;';
                }
                if(score.Adoption_Score__c >= 10 && score.Adoption_Score__c < 20){
                    this.adoptionStyle = style + '#FFFF00;';
                }
                if(score.Adoption_Score__c >= 20 && score.Adoption_Score__c <= 30){
                    this.adoptionStyle = style + '#008000;';
                }
            }
            if(score.Product_Score__c != null){
                 if(score.Product_Score__c < 6){
                    this.productStyle = style + '#FFBF00;';
                }
                if(score.Product_Score__c >= 6 && score.Product_Score__c < 13){
                    this.productStyle = style + '#FFFF00;';
                }
                if(score.Product_Score__c >= 13 && score.Product_Score__c <= 20){
                    this.productStyle = style + '#008000;';
                }
            }
            if(score.Support_Score__c != null){
                if(score.Support_Score__c < 6){
                    this.supportStyle = style + '#FFBF00;';
                }
                if(score.Support_Score__c >= 6 && score.Support_Score__c < 13){
                    this.supportStyle = style + '#FFFF00;';
                }
                if(score.Support_Score__c >= 13 && score.Support_Score__c <= 20){
                    this.supportStyle = style + '#008000;';
                }
            }
            this.score = score; 
            this.scoreProduct = scoreProduct;
            this.scoreSupport = scoreSupport;
            this.renderBlock = true;
            this.initializePieChart();
        })
        .catch((error) => {
            this.error = error;  // Store the error if any occurs
            console.error('Error fetching accounts:', error);
        });
    }

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
            
        })
        .catch(error => {
            console.log('Error loading Chart.js');
            console.error(error);
        });
    }

     initializePieChart() {
        const canvasId = 'canvas[id*="gauageChart"]';
        let chartResult = this.score.CX_Score__c;
        let style;
        if (chartResult < 30) {
            this.scoreCode = 'Fragile';
            style = '#de3163';
        } else if (chartResult >= 30 && chartResult < 50) {
            this.scoreCode = 'Poor';
            style = '#e4d00a';
        } else if (chartResult >= 50 && chartResult < 75) {
            this.scoreCode = 'Good';
            style = '#32CD32';
        }else{
            this.scoreCode = 'Excellent';
            style = '#6495ed';
        }
        this.colorCode = 'color:'+ style+';';
        var opts = {
            currval : chartResult,
            angle: 0, // The span of the gauge arc
            lineWidth: 0.44, // The line thickness
            radiusScale: 1, // Relative radius
            pointer: {
                length: 0.6, // // Relative to gauge radius
                strokeWidth: 0, // The thickness
                color: '#000000' // Fill color
            },
            fontSize : 33,
            limitMax: false,     // If false, max value increases automatically if value > maxValue
            limitMin: false,     // If true, the min value of the gauge will be fixed
            // to see which ones work best for you
            generateGradient: true,
            highDpiSupport: true,  
            staticZones: [
                {strokeStyle: style, min: 0, max: chartResult},
                {strokeStyle: "#E0E0E0", min: chartResult, max: 100},  // Yellow
            ]// High resolution support
                
        };
        var target = this.template.querySelector(canvasId);// your canvas element
        var gauge = new Gauge(target).setOptions(opts); // create sexy gauge!
        gauge.maxValue = 100; // set max gauge value
        gauge.setMinValue(0);  // Prefer setter over gauge.minValue = 0
        gauge.animationSpeed = 32; // set animation speed (32 is default value)
        gauge.set(chartResult); // set actual value
        this.template.querySelector('span[id*="res"]').innerHTML = chartResult;
    }

}