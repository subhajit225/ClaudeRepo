import { LightningElement,api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
export default class Pc_partnerReport_lwc extends LightningElement {  

    openClosedDealscolumns = [
        { label: 'Transacting Partner', fieldName: 'Transacting Partner', type: 'text', sortable: false, hideDefaultActions: true, wrapText: true, cellAttributes: { class: 'custom-column'} },
        { label: 'Customer', fieldName: 'Customer', type: 'text', sortable: false, hideDefaultActions: true, wrapText: true, cellAttributes: { class: 'custom-column'} },
        { label: 'Close Date', fieldName: 'Close Date', type: 'Date', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'} },
        //{ label: 'Amount', fieldName: 'Amount' , type: 'currency', sortable: false, hideDefaultActions: true, typeAttributes: {minimumFractionDigits: 0, maximumFractionDigits: 2}, cellAttributes: { class: 'custom-column', alignment: 'right'} },
        { label: 'Deal Initiated Type', fieldName: 'Deal Initiated Type', type: 'text', sortable: false, hideDefaultActions: true, wrapText: true, cellAttributes: { class: 'custom-column'} },
        { label: 'Sourcing Partner', fieldName: 'Sourcing Partner', type: 'text', sortable: false, hideDefaultActions: true, wrapText: true, cellAttributes: { class: 'custom-column'} }
        ];

    approvedDRColumns = [
        { label: 'Partner Account', fieldName: 'Partner Account', type: 'text', sortable: false, hideDefaultActions: true, wrapText: true, cellAttributes: { class: 'custom-column'} },
        { label: 'Customer', fieldName: 'Customer', type: 'text', sortable: false, hideDefaultActions: true, wrapText: true, cellAttributes: { class: 'custom-column'} },
        { label: 'Opportunity Id', fieldName: 'Opportunity Id', type: 'text', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'}},
        { label: 'Amount', fieldName: 'Amount', type: 'currency', sortable: false, hideDefaultActions: true, typeAttributes: {minimumFractionDigits: 0, maximumFractionDigits: 2}, cellAttributes: { class: 'custom-column', alignment: 'right'} },
        { label: 'Deal Initiated Type', fieldName: 'Deal Initiated Type', type: 'text', sortable: false, hideDefaultActions: true, wrapText: true, cellAttributes: { class: 'custom-column'} }
        ];

    activeCertColumns = [
        { label: 'Contact Name', fieldName: 'Contact Name', type: 'text', sortable: false, hideDefaultActions: true, wrapText: true, cellAttributes: { class: 'custom-column'} },
        { label: 'Account Name', fieldName: 'Account Name', type: 'text', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'} },
        { label: 'RCSA', fieldName: 'RCSA', type: 'Date', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column', alignment: 'right'}},
        { label: 'RCRS', fieldName: 'RCRS', type: 'Date', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column', alignment: 'right'}},
        { label: 'RCCS', fieldName: 'RCCS', type: 'Date', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column', alignment: 'right'}},
        { label: 'RTP', fieldName: 'RTP', type: 'Date', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column', alignment: 'right'}},
        { label: 'RCDP-T', fieldName: 'RCDP-T', type: 'Date', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column', alignment: 'right'}},
        { label: 'RCDP-S', fieldName: 'RCDP-S', type: 'Date', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column', alignment: 'right'}}
    ];

    approvedSPIFFColumns = [
        { label: 'Partner Account', fieldName: 'Partner Account', type: 'text', sortable: false, hideDefaultActions: true, wrapText: true, cellAttributes: { class: 'custom-column'} },
        { label: 'Customer', fieldName: 'Customer', type: 'text', sortable: false, hideDefaultActions: true, wrapText: true, cellAttributes: { class: 'custom-column'} },
        { label: 'Partner Payee Amount', fieldName: 'Partner Payee Amount', type: 'currency', sortable: false, hideDefaultActions: true, typeAttributes: {minimumFractionDigits: 0, maximumFractionDigits: 2}, cellAttributes: { class: 'custom-column', alignment: 'right'} },
        { label: 'Partner SE Amount', fieldName: 'Partner SE Amount', type: 'currency', sortable: false, hideDefaultActions: true, typeAttributes: {minimumFractionDigits: 0, maximumFractionDigits: 2}, cellAttributes: { class: 'custom-column', alignment: 'right'} },
        { label: 'Approval Date', fieldName: 'Approval Date', type: 'Date', sortable: false, hideDefaultActions: true, wrapText: true, cellAttributes: { class: 'custom-column'} },
        { label: 'Incentive', fieldName: 'Incentive', type: 'text', sortable: false, hideDefaultActions: true, wrapText: true, cellAttributes: { class: 'custom-column'} }
        ];

    approvedMDFColumns = [
        { label: 'Partner Account', fieldName: 'Partner Account', type: 'text', sortable: false, hideDefaultActions: true, wrapText: true, cellAttributes: { class: 'custom-column'} },
        { label: 'Activity', fieldName: 'Activity', type: 'text', sortable: false, hideDefaultActions: true, wrapText: true, cellAttributes: { class: 'custom-column'} },
        { label: 'Type', fieldName: 'Type', type: 'text', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'}},
        { label: 'Start Date', fieldName: 'Start Date', type: 'Date', sortable: false, hideDefaultActions: true, wrapText: true, cellAttributes: { class: 'custom-column'} },
        { label: 'Approved Amount', fieldName: 'Approved Amount', type: 'currency', sortable: false, hideDefaultActions: true, typeAttributes: {minimumFractionDigits: 0, maximumFractionDigits: 2}, cellAttributes: { class: 'custom-column', alignment: 'right'} }
        ];

    programPointColumns = [
        { label: 'Partner Name', fieldName: 'Partner Name', type: 'text', sortable: false, hideDefaultActions: true, wrapText: true, cellAttributes: { class: 'custom-column'} },
        { label: 'Partner Sourced', fieldName: 'Partner Sourced', type: 'number', sortable: false, hideDefaultActions: true, wrapText: true, cellAttributes: { class: 'custom-column', alignment: 'right'} },
        { label: 'Partner Sourced Bookings', fieldName: 'Partner Sourced Bookings', type: 'number', sortable: false, hideDefaultActions: true, wrapText: true, cellAttributes: { class: 'custom-column', alignment: 'right'} },
        { label: 'Save the Datas', fieldName: 'Save the Datas', type: 'number', sortable: false, hideDefaultActions: true, wrapText: true, cellAttributes: { class: 'custom-column', alignment: 'right'} },
        { label: 'Accreditations & Certifications', fieldName: 'Accreditations & Certifications', type: 'number', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column', alignment: 'right'} },
        { label: 'Technical Accreditations', fieldName: 'Technical Accreditations', type: 'number', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column', alignment: 'right'} },
        { label: 'Technical Certifications', fieldName: 'Technical Certifications', type: 'number', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column', alignment: 'right'} },
        { label: 'Transform Accelerators', fieldName: 'Transform Accelerators', type: 'number', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column', alignment: 'right'} },
        { label: 'Total', fieldName: 'Total', type: 'number', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column', alignment: 'right'} }
        ];

    rebateAchievedColumns = [
        { label: 'Start Date', fieldName: 'Start Date', type: 'Date', sortable: false, hideDefaultActions: true, wrapText: true, cellAttributes: { class: 'custom-column'} },
        { label: 'End Date', fieldName: 'End Date', type: 'Date', sortable: false, hideDefaultActions: true, wrapText: true, cellAttributes: { class: 'custom-column'} },
        { label: 'Max Rebate Payout', fieldName: 'Max Rebate Payout', type: 'currency', sortable: false, hideDefaultActions: true, typeAttributes: {minimumFractionDigits: 0, maximumFractionDigits: 2}, cellAttributes: { class: 'custom-column', alignment: 'right'} },
        { label: 'Actual Rebate Payout', fieldName: 'Actual Rebate Payout', type: 'currency', sortable: false, hideDefaultActions: true, typeAttributes: {minimumFractionDigits: 0, maximumFractionDigits: 2}, cellAttributes: { class: 'custom-column', alignment: 'right'} }
        ];

    showSpinner = true;
    showReport = false;
    showDisclaimer = false;
    reportData = [];
    @api reportName;
    detailURL;
    columns=[];
    showDetailedReport = false;
    @api
    sendReportData(widgetTile,widgetData,url, toggleValue){
        this.showReport = false;
        this.reportData = [];
        this.showDisclaimer = false;
        if(widgetTile && widgetData){
            this.showDetailedReport = false;
            this.reportData = [];
            console.log('widgetData->'+JSON.stringify(widgetData));
            if(widgetTile === "Open Deals" || widgetTile === "PSNL Open Deals" || widgetTile === "PS Expand Open Deals" || widgetTile === "Closed Deals" || widgetTile === "PSNL Closed Deals" || widgetTile === "PS Expand Closed Deals"){
                widgetData.forEach(rec => {
                    let colRec = {};
                    colRec.Id = rec.Id;
                    colRec["Transacting Partner"] = rec.Partner_Lookup__r != null ? rec.Partner_Lookup__r.Name : '';
                    colRec["Customer"] = rec.Account.Name;
                    colRec["Close Date"] = rec.CloseDate;

                    /*if(!toggleValue){
                        colRec["Amount"] = rec.Amount;
                    }else{
                        colRec["Amount"] = rec.ACV_Amount__c;
                    }*/

                    colRec["Deal Initiated Type"] = rec.Deal_Registration_Type__c;
                    if(rec.Sourcing_Partner__c != null)
                    colRec["Sourcing Partner"] = rec.Sourcing_Partner__r.Name;
                    this.reportData.push(colRec);
                });
                this.columns = this.openClosedDealscolumns;
                this.showDetailedReport = true;
            }else if(widgetTile === "Approved Deal Registrations" || widgetTile === "Approved Partner Sourced Deal Registrations"){
                widgetData.forEach(rec => {
                    let colRec = {};
                    colRec.Id = rec.Id;
                    colRec["Partner Account"] = rec.Partner_Lookup__r != null ? rec.Partner_Lookup__r.Name : '';
                    colRec["Customer"] = rec.Company__c;
                    colRec["Opportunity Id"] = rec.Opportunity__c;

                    if(!toggleValue){
                        colRec["Amount"] = rec.Opportunity_Amount_TVC__c;
                    }else{
                        colRec["Amount"] = rec.PID_Meeting_Task__c;
                    }
                    
                    colRec["Deal Initiated Type"] = rec.Deal_Registration_Type__c;
                    this.reportData.push(colRec);
                });
                this.columns = this.approvedDRColumns;
                this.showDetailedReport = true;
            }else if(widgetTile === "Active Certifications"){
                widgetData.forEach(rec => {
                    let colRec = {};
                    colRec.Id = rec.Id;
                    colRec["Contact Name"] = rec.Name;
                    colRec["Account Name"] = rec.Account_Name__c;
                    colRec["RCSA"] = rec.RCSA_Accredited__c;
                    colRec["RCRS"] = rec.RCRS_Accredited__c;
                    colRec["RCCS"] = rec.RCCS_Accredited__c;
                    colRec["RTP"] = rec.RTP_Accredited__c;
                    colRec["RCDP-T"] = rec.RCDP_Accredited__c;
                    colRec["RCDP-S"] = rec.RCDP_S_Accredited__c;
                    this.reportData.push(colRec);
                });
                this.columns = this.activeCertColumns;
                this.showDisclaimer = true;
                this.showDetailedReport = false;
            }else if(widgetTile === "Approved SPIFF Claims"){
                widgetData.forEach(rec => {
                    let colRec = {};
                    colRec.Id = rec.Id;
                    colRec["Partner Account"] = rec.Partner_Company_Name__r != null ? rec.Partner_Company_Name__r.Name : '';
                    colRec["Customer"] = rec.Customer_Company__c;
                    colRec["Partner Payee Amount"] = rec.Partner_REP_Amount__c;
                    colRec["Partner SE Amount"] = rec.Partner_SE_Amount__c;
                    colRec["Approval Date"] = rec.Approval_Date__c;
                    colRec["Incentive"] = rec.Incentive__r != null ? rec.Incentive__r.Name : '';
                    this.reportData.push(colRec);
                });
                this.columns = this.approvedSPIFFColumns;
                this.showDetailedReport = true;
            }else if(widgetTile === "Approved Development Fund Requests"){
                widgetData.forEach(rec => {
                    let colRec = {};
                    colRec.Id = rec.Id;
                    colRec["Partner Account"] = rec.ChannelPartner.Name;
                    colRec["Activity"] = rec.Title;
                    colRec["Type"] = rec.Activity;
                    colRec["Start Date"] = rec.Activity_Start_Date__c;
                    colRec["Approved Amount"] = rec.Amount;
                    this.reportData.push(colRec);
                });
                this.columns = this.approvedMDFColumns;
                this.showDetailedReport = true;
            }else if(widgetTile === "Program Points"){
                widgetData.forEach(rec => {
                    let colRec = {};
                    colRec.Id = rec.Id;
                    colRec["Partner Name"] = rec.Partner_Name__c;
                    colRec["Partner Sourced"] = rec.Partner_Sourced_New_Logo__c;
                    colRec["Partner Sourced Bookings"] = rec.X100K_Increment_of_Total_Bookings__c;
                    colRec["Save the Datas"] = rec.Save_the_Data_Events__c;
                    colRec["Accreditations & Certifications"] = rec.Ransomware_Accreditations_Certifications__c;
                    colRec["Technical Accreditations"] = rec.Technical_Sales_Accreditation__c;
                    colRec["Technical Certifications"] = rec.Technical_Certifications__c;
                    colRec["Transform Accelerators"] = rec.Accelerator_Points__c;
                    colRec["Total"] = rec.Total__c;
                    this.reportData.push(colRec);
                });
                this.columns = this.programPointColumns;
                this.showDetailedReport = false;
            }else if(widgetTile === "Rebates Achieved"){
                widgetData.forEach(rec => {
                    let colRec = {};
                    colRec.Id = rec.Id;
                    colRec["Start Date"] = rec.Start_Date__c;
                    colRec["End Date"] = rec.End_Date__c;
                    colRec["Max Rebate Payout"] = rec.Max_Rebate_Payout__c;
                    colRec["Actual Rebate Payout"] = rec.Actual_Rebate_Payout__c;
                    this.reportData.push(colRec);
                });
                this.columns = this.rebateAchievedColumns;
                this.showDetailedReport = false;
            }else{
                this.columns = [];
            }
            this.reportName = widgetTile;
            this.detailURL = url;
            this.showReport = true;
        }
    }

    connectedCallback(){
        Promise.all([loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')])
            .then(() => {
                console.log("File path-->"+ PartnerCommunityResource);
                this.showSpinner = false;
            })
            .catch(error => {
                console.log( error.body.message );
            });
    }

    handleExportClick(){
        let rowEnd = '\n';
        let csvString = '';
        let rowData = new Set();
        let conToExport = this.reportData;

        conToExport.forEach(function (con) {
            Object.keys(con).forEach(function(key) {
                rowData.add(key);
            });
        });
        rowData = Array.from(rowData);

        csvString += rowData.join(',');
        csvString += rowEnd;

        for(let i=0; i < conToExport.length; i++){
            let colValue = 0;
            for(let key in rowData) {
                if(rowData.hasOwnProperty(key)) {
                    let rowKey = rowData[key];
                    if(colValue > 0){
                        csvString += ',';
                    }
                    let value = conToExport[i][rowKey] === undefined ? '' : conToExport[i][rowKey];
                    csvString += '"'+ value +'"';
                    colValue++;
                }
            }
            csvString += rowEnd;
        }

        let downloadElement = document.createElement('a');

        downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvString);
        downloadElement.target = '_self';
        downloadElement.download = this.reportName+'.csv';
        document.body.appendChild(downloadElement);
        downloadElement.click();
    }
}