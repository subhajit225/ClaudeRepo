import { LightningElement, api, wire } from 'lwc';

export default class CeOperationsMetricChart extends LightningElement {
    @api label;
    @api currentValue;
    @api isLoading;
    @api name;
    @api reportDisabled = false;
    @api chartConfiguration;

   isFloat(n) {
        return Number(n) === n && n % 1 !== 0;
    }

    get isReportAvailable() {
        if (this.reportDisabled) {
            return false;
        }
        if(Boolean(this.chartConfiguration)){
            return Boolean(this.chartConfiguration.data.labels.length)
        }
        return (Number.isInteger(this.currentValue) || this.isFloat(this.currentValue)) && this.currentValue;
    }

    get value() {
        if (this.currentValue == undefined || this.currentValue == null) {
            return 'N/A';
        }
        if (Number.isInteger(this.currentValue) || this.isFloat(this.currentValue)) {
            return Intl.NumberFormat('en-US', {
                notation: "compact",
                maximumFractionDigits: 1
            }).format(this.currentValue);
        } else if (this.currentValue == undefined || this.currentValue == null) {
            return 'N/A';
        } else {
            return this.currentValue
        }
    }
    handleViewReport(event) {
        this.dispatchEvent(new CustomEvent('viewreport', { detail: { name: this.name, label: this.label } }));
    }
}