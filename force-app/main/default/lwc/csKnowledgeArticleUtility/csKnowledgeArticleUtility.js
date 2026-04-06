import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateRecords from '@salesforce/apex/CsKnowledgeArticleUtilityController.updateRecords';
import sendProcessingEmail from '@salesforce/apex/CsKnowledgeArticleUtilityController.sendProcessingEmail';
import { loadScript } from 'lightning/platformResourceLoader';
import XLSX_RESOURCE from '@salesforce/resourceUrl/fileExtractor';

export default class CsKnowledgeArticleUtility extends LightningElement {
    fileName = '';
    @track data = [];
    @track columns = [];
    @track activeTab = 'all';
    @track currentPage = 1;
    @track pageSize = 10;
    @track batchSize = 10;

    @track processedCount = 0;
    @track sendEmailAfterProcessing = false;

    pageSizeOptions = [
        { label: '10 records', value: 10 },
        { label: '25 records', value: 25 },
        { label: '50 records', value: 50 },
        { label: '100 records', value: 100 },
        { label: '200 records', value: 200 },
        { label: '500 records', value: 500 }
    ];
    batchSizeOptions = [
        { label: '10 records', value: 10 },
        { label: '25 records', value: 25 }
    ];
    @track statusTabs = [];
    @track selectedRows = [];
    @track isLoading = false;
    xlsxInitialized = false;
    @track selectedGroupingField = '';
    @track selectedIds = new Set();

    get isDataLoaded() {
        return this.data.length > 0;
    }

    get totalSelectedCount() {
        return this.selectedIds.size;
    }

    get isDownloadDisabled() {
        return !this.isDataLoaded;
    }

    get processButtonVariant() {
        return this.isLoading ? 'brand' : 'neutral';
    }

    async connectedCallback() {
        if (this.xlsxInitialized) return;
        try {
            await loadScript(this, XLSX_RESOURCE);
            this.xlsxInitialized = true;
        } catch (error) {
            this.showToast('Error', 'Failed to load file processing library', 'error');
        }
    }

    handleEmailCheckboxChange(event) {
        this.sendEmailAfterProcessing = event.target.checked;
    }

    handleFileChange(event) {
        const file = event.target.files[0];
        if (!file) return;

        this.fileName = file.name;
        const reader = new FileReader();

        reader.onload = (e) => {
            try {
                const data = e.target.result;
                const workbook = XLSX.read(data, { type: 'binary' });
                const firstSheetName = workbook.SheetNames[0];
                const worksheet = workbook.Sheets[firstSheetName];
                const jsonData = XLSX.utils.sheet_to_json(worksheet, { header: 1 });
                this.processExcelData(jsonData);
            } catch (error) {
                this.showToast('Error', 'Failed to process file: ' + error.message, 'error');
            }
        };

        reader.onerror = () => {
            this.showToast('Error', 'Failed to read file', 'error');
        };

        reader.readAsBinaryString(file);
    }

    processExcelData(jsonData) {
        try {
            if (!jsonData || jsonData.length < 2) {
                throw new Error('File contains no data or headers');
            }

            const headers = jsonData[0].map(header => String(header).trim());
            const seenIds = new Set();
            let uniqueData = [];

            // Ensure the 'Id' column exists
            const idIndex = headers.indexOf('Id');
            if (idIndex === -1) {
                this.showToast('Error', `Missing 'Id' column in the data.`, 'error');
            }

            jsonData.slice(1).forEach((row, index) => {
                if (row.length === 0) return;

                const rowData = {
                    uniqueId: `row - ${index}`
                };
                const rowId = row[idIndex] !== undefined ? String(row[idIndex]).trim() : '';

                if (!rowId || seenIds.has(rowId)) {
                    return; // Ignore duplicate or empty Id rows
                }

                seenIds.add(rowId);

                headers.forEach((header, i) => {
                    rowData[header] = row[i] !== undefined ? String(row[i]).trim() : '';
                });

                uniqueData.push(rowData);
            });

            this.data = uniqueData;

            // Adjust column definitions based on number of columns
            if (headers.length === 1) {
                this.columns = headers.map(header => ({
                    label: header,
                    fieldName: header,
                    sortable: true,
                    cellAttributes: {
                        class: 'slds-size_1-of-1',
                    }
                }));
            } else {
                this.columns = headers.map(header => ({
                    label: header,
                    fieldName: header,
                    sortable: true
                }));
            }

            this.selectedGroupingField = '';
            this.activeTab = 'all';
            this.updateStatusTabs();
            this.showToast('Success', `Successfully loaded ${this.data.length} unique records`, 'success');
        } catch (error) {
            this.showToast('Error', 'Failed to process data: ' + error.message, 'error');
        }
    }

    updateStatusTabs() {
        const statuses = new Set(this.data.map(row => row.PublishStatus || 'Unknown'));
        this.statusTabs = Array.from(statuses).map(status => ({
            label: `${status} (${this.data.filter(row => (row.PublishStatus || 'Unknown') === status).length})`,
            value: status
        }));

        this.statusTabs.unshift({
            label: `All (${this.data.length})`,
            value: 'all'
        });
    }

    get groupingOptions() {
        return [
            { label: 'All', value: '' },
            ...this.columns
                .filter(col => col.sortable)
                .map(col => ({
                    label: col.label,
                    value: col.fieldName
                }))
        ];
    }

    get groupedData() {
        if (!this.selectedGroupingField) {
            return [{
                label: `All (${this.data.length})`,
                value: 'all'
            }];
        }

        const groups = new Set(this.data.map(row => row[this.selectedGroupingField] || 'Unknown'));
        const groupedTabs = Array.from(groups).map(group => ({
            label: `${group} (${this.data.filter(row => (row[this.selectedGroupingField] || 'Unknown') === group).length})`,
            value: group
        }));

        return [
            { label: `All (${this.data.length})`, value: 'all' },
            ...groupedTabs
        ];
    }

    handleGroupingChange(event) {
        this.selectedGroupingField = event.detail.value;
        this.currentPage = 1;
        this.selectedRows = [];
        this.updateStatusTabs();
    }

    get filteredData() {
        if (!this.selectedGroupingField || this.activeTab === 'all') {
            return this.data;
        }
        return this.data.filter(row =>
            (row[this.selectedGroupingField] || 'Unknown') === this.activeTab
        );
    }

    get paginatedData() {
        const startIndex = (this.currentPage - 1) * this.pageSize;
        const endIndex = startIndex + this.pageSize;
        const data = this.filteredData.slice(startIndex, endIndex).map(row => ({
            ...row,
            uniqueId: row.uniqueId || `${startIndex + index}`
        }));

        // Update datatable selection whenever paginated data changes
        requestAnimationFrame(() => {
            this.updateDatatableSelection();
        });

        return data;
    }

    get totalPages() {
        return Math.ceil(this.filteredData.length / this.pageSize);
    }

    get isPreviousDisabled() {
        return this.currentPage <= 1;
    }

    get isNextDisabled() {
        return this.currentPage >= this.totalPages;
    }

    get isProcessButtonDisabled() {
        return !this.selectedRows || this.selectedRows.length === 0;
    }

    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updateDatatableSelection();
        }
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updateDatatableSelection();
        }
    }

    handleTabChange(event) {
        this.activeTab = event.target.value;
        this.currentPage = 1;
        this.selectedRows = [];
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        selectedRows.forEach(row => this.selectedIds.add(row.Id));

        // Remove IDs that were unselected
        const unselectedRows = this.paginatedData.filter(
            row => !selectedRows.some(selected => selected.Id === row.Id)
        );
        unselectedRows.forEach(row => this.selectedIds.delete(row.Id));

        this.selectedRows = Array.from(this.selectedIds);
    }

    handleSelectAll() {
        if (this.selectedIds.size === this.filteredData.length) {
            // Unselect all
            this.selectedIds.clear();
        } else {
            // Select all filtered data
            this.filteredData.forEach(row => this.selectedIds.add(row.Id));
        }

        this.selectedRows = Array.from(this.selectedIds);

        const datatable = this.template.querySelector('lightning-datatable');
        if (datatable) {
            datatable.selectedRows = this.paginatedData
                .filter(row => this.selectedIds.has(row.Id))
                .map(row => row.Id);
        }
    }

    handleBatchSizeChange(event) {
        this.batchSize = parseInt(event.detail.value, 10);
    }
    /*
    async handleProcessRecords() {
        if (this.selectedIds.size === 0) {
            this.showToast('Error', 'Please select records to process', 'error');
            return;
        }

        try {
            this.isLoading = true;
            const selectedIds = Array.from(this.selectedIds);
            const batches = this.createBatches(selectedIds, this.batchSize);

            for (let batch of batches) {
                const result = await updateRecords({ idList: batch });
                this.updateProcessedRecords(result);
            }

            this.showToast('Success', 'Records processed successfully', 'success');
            this.selectedIds.clear();
            this.selectedRows = [];
            this.updateDatatableSelection();
        } catch (error) {
            console.error('Error processing batch:', error);
            this.showToast('Error', error.body ? (error.body.message || 'Error processing records') : 'error');
        } finally {
            this.isLoading = false;
        }
    }
    */

    createBatches(ids, batchSize) {
        let batches = [];
        for (let i = 0; i < ids.length; i += batchSize) {
            batches.push(ids.slice(i, i + batchSize));
        }
        return batches;
    }

    updateProcessedRecords(results) {
        // Add Status and ErrorMessage columns if they don't exist
        if (!this.columns.some(col => col.fieldName === 'Status')) {
            this.columns = [...this.columns, {
                label: 'Processing Status',
                fieldName: 'Status',
                type: 'text',
                sortable: true
            }];
        }

        if (!this.columns.some(col => col.fieldName === 'ErrorMessage')) {
            this.columns = [...this.columns, {
                label: 'Error Message',
                fieldName: 'ErrorMessage',
                type: 'text',
                wrapText: true,
                sortable: true
            }];
        }

        // Update the data with processing results
        const updatedData = this.data.map(row => {
            const result = results.find(r => r.id === row.Id);
            if (result) {
                return {
                    ...row,
                    Status: result.success ? 'Success' : 'Error',
                    ErrorMessage: result.errorMessage || ''
                };
            }
            return row;
        });

        // Force reactivity by creating a new array
        this.data = [...updatedData];

        this.updateStatusTabs();
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }

    handlePageSizeChange(event) {
        this.pageSize = parseInt(event.detail.value, 10);
        this.currentPage = 1;
    }

    get selectAllButtonLabel() {
        const count = this.filteredData.length;
        return this.selectedIds.size === count ?
            `Unselect All (${count})` :
            `Select All (${count})`;
    }

    updateDatatableSelection() {
        const datatable = this.template.querySelector('lightning-datatable');
        if (datatable) {
            const selectedRows = this.paginatedData
                .filter(row => this.selectedIds.has(row.Id))
                .map(row => row.Id);
            if (selectedRows.length > 0) {
                datatable.selectedRows = selectedRows;
            }
        }
    }

    handleDownload() {
        try {
            // Create worksheet from the current data
            const ws = XLSX.utils.json_to_sheet(this.data);

            // Create workbook and add the worksheet
            const wb = XLSX.utils.book_new();
            XLSX.utils.book_append_sheet(wb, ws, 'Records');

            // Generate file name with timestamp
            const fileName = `knowledge_articles_${new Date().toISOString().slice(0, 19).replace(/[:]/g, '-')}.xlsx`;

            // Save the file
            XLSX.writeFile(wb, fileName);

            this.showToast('Success', 'File downloaded successfully', 'success');
        } catch (error) {
            console.error('Download error:', error);
            this.showToast('Error', 'Failed to download file', 'error');
        }
    }

    async handleProcessRecords() {
        if (this.selectedIds.size === 0) {
            this.showToast('Error', 'Please select records to process', 'error');
            return;
        }

        try {
            this.isLoading = true;
            this.processedCount = 0;
            const selectedIds = Array.from(this.selectedIds);
            const batches = this.createBatches(selectedIds, this.batchSize);
            const processedResults = [];

            for (let batch of batches) {
                const result = await updateRecords({ idList: batch });
                processedResults.push(...result);
                this.processedCount += batch.length;
                this.updateProcessedRecords(result);
            }

            if (this.sendEmailAfterProcessing) {
                await this.sendProcessingEmail(processedResults);
            }

            this.showToast('Success', 'Records processed successfully', 'success');
            this.selectedIds.clear();
            this.selectedRows = [];
            this.updateDatatableSelection();
        } catch (error) {
            console.error('Error processing batch:', error);
            this.showToast('Error', error.body ? (error.body.message || 'Error processing records') : 'error');
        } finally {
            this.isLoading = false;
            this.processedCount = 0;
        }
    }

    async sendProcessingEmail(processedResults) {
        try {
            // Create worksheet from the processed results
            const ws = XLSX.utils.json_to_sheet(processedResults);

            // Create workbook and add the worksheet
            const wb = XLSX.utils.book_new();
            XLSX.utils.book_append_sheet(wb, ws, 'Processed Records');

            // Convert workbook to binary string
            const wbout = XLSX.write(wb, { bookType: 'xlsx', type: 'binary' });

            // Convert binary string to base64
            const base64Data = btoa(
                wbout.split('').map(char => String.fromCharCode(char.charCodeAt(0) & 0xFF)).join('')
            );

            // Call Apex method to send email with attachment
            await sendProcessingEmail({
                attachmentBody: base64Data,
                fileName: `processed_records_${new Date().toISOString().slice(0, 19).replace(/[:]/g, '-')}.xlsx`
            });

            this.showToast('Success', 'Processing report sent via email', 'success');
        } catch (error) {
            console.error('Error sending email:', error);
            this.showToast('Error', 'Failed to send processing report email', 'error');
        }
    }

}