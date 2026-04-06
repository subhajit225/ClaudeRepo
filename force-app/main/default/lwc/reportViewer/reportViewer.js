import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getObjectPrefixMap from '@salesforce/apex/LCC_JSMQueryResultService.getObjectPrefixes';
import getReportData from '@salesforce/apex/LCC_JSMQueryResultService.getReportData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import locale from "@salesforce/i18n/locale";
import timezone from "@salesforce/i18n/timeZone";
import getOIData from '@salesforce/apex/LCC_JSMQueryResultService.executeQuery';



const PAGE_SIZE = 25;
const ID_REGEX = /^[a-zA-Z0-9]{15,18}$/;

export default class ReportViewer extends NavigationMixin(LightningElement) {
    @api reportDeveloperName;
    @track reportName;
    @track reportId;
    @track columns = [];
    @track data = [];
    @track filteredData = [];
    @track error;
    @track isLoading = true;
    @track currentPage = 1;
    @track totalPages = 1;
    @track searchTerm = '';
    @track idPrefixMap = {};
    allQuoteLine = [];
    requiredByQli = [];
    quoteLineSet = new Set();
    OrderWithOrderIdForAspen = new Map();
    parentChildQuoteLines = new Map();
    quoteLineWithShiomentDetails = new Map();



    checkReadiness() {
        if (this.idPrefixMap && this.reportDeveloperName) {
            this.isLoading = true;
            this.loadReportData();
        }
    }

    @wire(getObjectPrefixMap)
    wiredPrefixes({ error, data }) {
        if (data) {
            this.idPrefixMap = data;
            this.checkReadiness();
        } else if (error) {
            this.idPrefixMap = {
                '001': 'Account', '003': 'Contact', '005': 'User',
                '006': 'Opportunity', '801': 'Order', '810':'ServiceContract', 
                '00Q': 'Lead', '00O': 'Report', 
                '550': 'Entitlement'
            };
            this.handleError(error);
        }
    }

    handleViewReport() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.reportId,
                objectApiName: 'Report',
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, "_blank");
        });
    }

    async loadReportData() {
        this.isLoading = true;
        try {
            const result = await getReportData({ reportDeveloperName: this.reportDeveloperName });
            const report = JSON.parse(result);
            if(report){
                this.processReport(report);
            }
            else{
                this.isLoading = false;
            }
        } catch (error) {
            this.handleError(error);
        }
        this.isLoading = false;
    }

    async processReport(report) {
        const columnInfo = report.reportExtendedMetadata?.detailColumnInfo || {};
        this.reportName = report.reportMetadata.name;
        this.reportId = report.reportMetadata.id;
        // Process columns first
        this.columns = report.reportMetadata.detailColumns.map(colName => ({
            label: columnInfo[colName]?.label || colName,
            fieldName: colName,
            type: 'text',
            initialWidth:200
        }));

        // Process rows
        this.data = [];
        Object.values(report.factMap).forEach(fact => {
            if (fact.rows) {
                fact.rows.forEach(row => {
                    const processedRow = {};
                    row.dataCells.forEach((cell, index) => {
                        const colName = report.reportMetadata.detailColumns[index];
                        const { displayValue, url } = this.processCell(cell, columnInfo[colName]);
                        
                        processedRow[colName] = displayValue;
                        if (url) {
                            processedRow[`${colName}_url`] = url;
                        }
                    });
                    this.data.push(processedRow);
                });
            }
        });

            if(this.reportDeveloperName === 'ASPEN_HW_SW_Shipped_HW_Shipped_Report'){
            this.quoteLineSet = [...new Set(this.allQuoteLine)];
            await this.handleGetAccounts();
            await this.handleShipmentDetails();
            this.data.forEach(row => {
                const quoteline = row['OrderItem.SBQQ__QuoteLine__c'];
                if (this.parentChildQuoteLines.has(quoteline) && this.quoteLineWithShiomentDetails.has(this.parentChildQuoteLines.get(quoteline))) {
                    const sd =   this.quoteLineWithShiomentDetails.get(this.parentChildQuoteLines.get(quoteline));
    
                    if (sd!==undefined) {
                        row['HWShipmentDetailDate'] = sd.ShippedDate__c;
                        row['HWShipmentDetailName'] = sd.Name;
                        row['HWShipmentDetailURL'] = `${window.location.origin}/lightning/r/ShipmentDetail__c/${sd.Id}/view`;
                    }
                    
                }

            });

            this.columns.push(
                {
                    fieldName: 'HWShipmentDetailURL',
                    label : 'HW Shipment Detail',
                    type: 'url',
                    typeAttributes: {
                        label: { fieldName: 'HWShipmentDetailName' },  // Display original field
                        target: '_blank'
                    },
                    initialWidth:200

                },
                {
                    fieldName: 'HWShipmentDetailDate',
                    type: "date",
                    label : 'HW Shipment Date',
                    initialWidth:200
                }
            );
        }

        // Update columns with URL configuration
        this.columns = this.columns.map(col => {
            const hasUrls = this.data.some(row => row[`${col.fieldName}_url`]);
            return hasUrls ? {
                ...col,
                fieldName: `${col.fieldName}_url`,  // Use the URL field
                type: 'url',
                typeAttributes: {
                    label: { fieldName: col.fieldName },  // Display original field
                    target: '_blank'
                },
                initialWidth:200

            } : col;
        });

        if (report.reportMetadata.customSummaryFormula) {
            this.processSummaryFormulas(report);
        }

        this.filteredData = [...this.data];
        this.totalPages = Math.ceil(this.filteredData.length / PAGE_SIZE);
    }

        async handleGetAccounts() {
        var formattedIds = Array.from(this.quoteLineSet)
        .map(id => `'${id}'`)
        .join(',');
        
        var queryOIData = 'SELECT Id,Name, SBQQ__RequiredBy__c FROM SBQQ__QuoteLine__c WHERE SBQQ__RequiredBy__c!=null AND  ' + 

        ' Id IN (' + formattedIds + ')';
        await getOIData({'theQuery' : queryOIData})
        .then((result) => {
        this.parentChildQuoteLines = new Map();
            result.forEach(qli => {
                if (!this.parentChildQuoteLines.has(qli.Name)) {
                    this.parentChildQuoteLines.set(qli.Name, qli.SBQQ__RequiredBy__c);
                }
                this.requiredByQli.push(qli.SBQQ__RequiredBy__c);
            });
        })
        .catch((error) => {
            // Handle errors and clear any previous account data
            console.error(JSON.stringify(error));
            this.error = error.body.message;
        });

    }


    async handleShipmentDetails() {
        var formattedIds = Array.from(this.requiredByQli)
        .map(id => `'${id}'`)
        .join(',');

        var queryOIData = 'SELECT Id,Name,Quote_Line__c,ShippedDate__c ' +
        'FROM ShipmentDetail__c ' +
        'WHERE Quote_Line__c!=null AND ' +
        ' Quote_Line__c IN (' + formattedIds + ')';

        await getOIData({'theQuery' : queryOIData})
        .then((result) => {

            this.quoteLineWithShiomentDetails = new Map();
            result.forEach(shipment => {


                if (!this.quoteLineWithShiomentDetails.has(shipment.Quote_Line__c)) {
                    this.quoteLineWithShiomentDetails.set(shipment.Quote_Line__c, shipment);
                }

            });
  
        })
        .catch((error) => {
            // Handle errors and clear any previous account data
            console.error(JSON.stringify(error));
            this.error = error.body.message;
        });

    }

    processCell(cell, columnMeta) {
        const rawValue = cell.value !== null ? cell.value : cell.label;
        const isId = this.isValidId(rawValue) && !rawValue.includes(',');
        
        // Handle object-based values (common in Salesforce reports)
        const getActualValue = (value) => {
            return (typeof value === 'object' && value.value !== undefined) 
                ? value.value 
                : value;
        };

        // Get actual primitive value
        const actualValue = getActualValue(rawValue);
        const actualLabel = getActualValue(cell.label);

        let displayValue = '-';
        let url = null;

        // Enhanced date formatter
        const formatDate = (value) => {
            try {
                const dateValue = new Date(value);
                
                // For 24-hour format with full control
                return new Intl.DateTimeFormat(locale, {
                    year: 'numeric',
                    month: '2-digit',
                    day: '2-digit',
                    hour: '2-digit',
                    minute: '2-digit',
                    timeZone: timezone
                }).format(dateValue);
            } catch (e) {
                console.error('Date formatting error:', e);
                return actualLabel || value || '-';
            }
        };
    
    
        if (isId) {
            const id = typeof rawValue === 'object' ? rawValue.value : rawValue;
            const prefix = id.substring(0, 3);
            const objectApiName = this.idPrefixMap[prefix] || 'Account';
            if(objectApiName == 'SBQQ__QuoteLine__c')
            this.allQuoteLine.push(id);


            
            displayValue = typeof rawValue === 'object' ? rawValue.label : cell.label;
            
            // Generate proper Salesforce record URL
            url = `${window.location.origin}/lightning/r/${objectApiName}/${id}/view`;
        } else if (columnMeta?.dataType === 'CURRENCY_DATA') {
            const amount = typeof rawValue === 'object' ? rawValue.amount : rawValue;
            displayValue = new Intl.NumberFormat(locale, {
                style: 'currency',
                currency: (typeof rawValue === 'object' ? rawValue.currencyCode : 'USD') || 'USD'
            }).format(amount);
        } else if (columnMeta?.dataType === 'DATE_DATA') {
            displayValue = actualValue ? 
                formatDate(actualValue).split(',')[0] : // Show only date part
                actualLabel || '-';
        }  else if (columnMeta?.dataType === 'DATETIME_DATA') {
            displayValue = actualValue ? 
                formatDate(actualValue) : 
                actualLabel || '-';
        } else if (columnMeta?.dataType === 'PERCENT_DATA') {
            const percentValue = rawValue / 100;
            displayValue = new Intl.NumberFormat(locale, { 
                style: 'percent',
                maximumFractionDigits: 0 
            }).format(percentValue);
        } else {
            displayValue = actualValue || actualLabel || '-';
        }
    
        return { displayValue, url };
    }

    isValidId(value) {
        const id = typeof value === 'object' ? value.value : value;
        return ID_REGEX.test(id) && this.idPrefixMap[id?.substring(0, 3)];
    }

    // Search implementation
    handleSearch(event) {
        this.searchTerm = event.target.value.toLowerCase();
        this.filteredData = this.data.filter(row => 
            Object.entries(row).some(([key, value]) => 
                !key.endsWith('_url') && 
                String(value).toLowerCase().includes(this.searchTerm)
        ));
        this.currentPage = 1;
        this.totalPages = Math.ceil(this.filteredData.length / PAGE_SIZE);
    }

    // Pagination controls
    get paginatedData() {
        const start = (this.currentPage - 1) * PAGE_SIZE;
        return this.filteredData.slice(start, start + PAGE_SIZE);
    }

    previousPage() { if (this.currentPage > 1) this.currentPage--; }
    nextPage() { if (this.currentPage < this.totalPages) this.currentPage++; }

    get currentRange() {
        const start = (this.currentPage - 1) * PAGE_SIZE + 1;
        const end = Math.min(this.currentPage * PAGE_SIZE, this.filteredData.length);
        return `${start}-${end} of ${this.filteredData.length}`;
    }

    processSummaryFormulas(report) {
        // Add summary formulas as first row
        const summaryRow = {};
        Object.entries(report.reportMetadata.customSummaryFormula).forEach(([key, formula]) => {
            summaryRow[formula.label] = `${Math.round(report.factMap['T!T']?.aggregates?.[0]?.value || 0)}%`;
        });
        this.data.unshift(summaryRow);
    }

    handleError(error) {
        this.error = error;
        this.isLoading = false;
        console.error('Error:', error);
    
        // Show toast notification
        const toastEvent = new ShowToastEvent({
            title: 'Error',
            message: error.body?.message || error.message || 'An unexpected error occurred',
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(toastEvent);
    }

    get hasData() {
        return this.data.length > 0;
    }
    
}