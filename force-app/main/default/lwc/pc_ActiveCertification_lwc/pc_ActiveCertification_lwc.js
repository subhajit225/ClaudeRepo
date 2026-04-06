import { LightningElement } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import getActiveCertifications from '@salesforce/apex/PC_PortalNavigationApexController.getActiveCertifications';
export default class Pc_ActiveCertification_lwc extends LightningElement {
    columns = [
        { label: 'Contact Name', fieldName: 'Name', type: 'text', sortable: false, hideDefaultActions: true, wrapText: true, cellAttributes: { class: 'custom-column'} },
        { label: 'Account Name', fieldName: 'Account_Name', type: 'text', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'} },
        { label: 'RSA', fieldName: 'RCSA_Accredited', type: 'Date', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column', alignment: 'right'}},
        { label: 'RTA', fieldName: 'RTA_Accredited', type: 'Date', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column', alignment: 'right'} },
        { label: 'RRE', fieldName: 'RRE_Accredited', type: 'Date', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column', alignment: 'right'} },
        { label: 'RRS', fieldName: 'RRS_Accredited', type: 'Date', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column', alignment: 'right'} },
        { label: 'RTP', fieldName: 'RTP_Accredited', type: 'Date', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column', alignment: 'right'} },
        { label: 'RCIE', fieldName: 'RCIE_Certified', type: 'Date', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column', alignment: 'right'} }
    ];

    conList = [];
    disableExport = true;
    loadSpinner = false;
    accountIds = [];

    connectedCallback(){
        this.loadSpinner = true;
        Promise.all([loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')])
        .then(() => {
            console.log("File path-->"+ PartnerCommunityResource);
        })
        .catch(error => {
            console.log( error.body.message );
        });

        this.fetchData();
    }

    fetchData(){
        this.loadSpinner = true;
        getActiveCertifications({accIds : this.accountIds})
        .then(result=>{
            console.log('result->'+JSON.stringify(result));
            if(result.length > 0){
                let conRecAll = [];
                result.forEach(conEle => {
                    let conRec = {};
                    conRec.Id = conEle.Id;
                    conRec.Name = conEle.Name;
                    conRec.Account_Name = conEle.Account_Name__c;
                    conRec.RCSA_Accredited = conEle.RCSA_Accredited__c;
                    conRec.RTA_Accredited = conEle.RTA_Accredited__c;
                    conRec.RRE_Accredited = conEle.RRE_Accredited__c;
                    conRec.RRS_Accredited = conEle.RRS_Accredited__c;
                    conRec.RTP_Accredited = conEle.RTP_Accredited__c;
                    conRec.RCIE_Certified = conEle.RCIE_Certified__c;
                    conRecAll.push(conRec);
                })
                this.conList = conRecAll;
                if(this.conList.length > 0 && this.conList){
                    this.disableExport = false;
                }
                this.loadSpinner = false;
            }else{
                this.conList = [];
                this.loadSpinner = false;
            }
        })
        .catch(error=>{
            console.log('Error->'+JSON.stringify(error));
            this.loadSpinner = false;
        });
    }

    handleResetClick(){
        console.log('inreset');
        this.template.querySelector('c-pc_account-Hierarchy').reset();
    }

    handleAccountFilter(event){
        console.log('event->'+event.detail);
        this.accountIds = event.detail;
        this.fetchData();
    }

    handleExportClick(){
        let rowEnd = '\n';
        let csvString = '';
        
        let rowData = new Set();

        let conToExport = this.conList;

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
        downloadElement.download = 'Active Certifications.csv';
        document.body.appendChild(downloadElement);
        downloadElement.click(); 
    }
}