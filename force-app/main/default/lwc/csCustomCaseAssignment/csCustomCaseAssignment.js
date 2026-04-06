import { LightningElement, track, api } from 'lwc';
import updateCaseOwners from '@salesforce/apex/CaseAssignmentController.updateCaseOwners';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import getRoundRobinedCases from '@salesforce/apex/CaseAssignmentController.getRoundRobinedCases';
import getUserName from '@salesforce/apex/CaseAssignmentController.getUserName';
import XLSXResource from '@salesforce/resourceUrl/xlsx';
import { loadScript } from 'lightning/platformResourceLoader';
import { getFocusedTabInfo, closeTab } from 'lightning/platformWorkspaceApi';

export default class CsCustomCaseAssignment extends LightningElement {
    @track cases;
    @track error;
    isModalOpen = false;
    @track showSpinner = false;
    @track tempWiredCases;
    @track currentPage = 1;
    @track totalCases = 0;
    @track totalPages = 0;
    @track allCasesForAssignment;
    lastCSMId;
    xlsxInitialized = false;
    showActionButtons = false;
    noOfRecords = 50;// to get selected number of records to submit
    totalCasesAvailable = 0;//to show the total number of cases available

    /*Pagination Code*/

    @api visibleCases = [];
    @track pageList = [];

    currentPage = 1;
    pageSize = 10; // you want 5? set to 5
    totalRecords = 0;//records returned from the backend for assignment
    totalPages = 0;
    maxButtonsToShow = 5;

    /*End of Pagination Code*/

    connectedCallback() {
        this.isModalOpen = true;
        this.showSpinner = true;
        this.loadRoundRobinCases(false);
    }

    renderedCallback() {
        if (this.xlsxInitialized) return;
        this.xlsxInitialized = true;

        // Since you uploaded a single file, no extra path needed
        loadScript(this, XLSXResource)
            .then(() => {
                console.log('XLSX loaded successfully');
            })
            .catch(error => {
                console.error('Error loading XLSX', error);
            });
    }

    exportData() {
        if (!window.XLSX) {
            console.error('XLSX is not loaded yet');
            return;
        }

        // Step 1: Define header row
        const worksheetData = [
            ['Case Number', 'Account Name', 'Product Name', 'Phase', 'Case Owner']
        ];
        this.cases.forEach(c => {
            worksheetData.push([
                c.caseNumber,
                c.accountName || '',
                c.productName || '',
                c.phase || '',
                c.csmName || ''
            ]);
        });
        // Step 3: Convert array to worksheet
        const worksheet = window.XLSX.utils.aoa_to_sheet(worksheetData);

        // Step 4: Create workbook and append worksheet
        const workbook = window.XLSX.utils.book_new();
        window.XLSX.utils.book_append_sheet(workbook, worksheet, 'Cases');

        // Step 5: Generate Excel file
        const excelBuffer = window.XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });
        const blob = new Blob([excelBuffer], { type: 'application/octet-stream' });

        // 7. Build filename with today's date (dd-MM-YYYY)
        const today = new Date();
        const dd = String(today.getDate()).padStart(2, '0');
        const mmm = today.toLocaleString('en-US', { month: 'short' }); // e.g., "Sep"
        const yyyy = today.getFullYear();
        const fileName = `CSM Case Assignment Report (${dd}-${mmm}-${yyyy}).xlsx`;

        // Step 6: Trigger browser download
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.download = fileName;
        link.click();
    }

    /* isSubmitted is used to identify if Cases are assigned and if there is nothing to assign, it will close the tab*/
    async loadRoundRobinCases(isSubmitted) {
        try {
            this.showSpinner = true;
            const casesListResult = await getRoundRobinedCases({
                noOfRecords: this.noOfRecords
            });
            if (casesListResult && casesListResult.roundRobinCases.length > 0) {
                this.cases = casesListResult.roundRobinCases;
                this.lastCSMId = casesListResult.lastCSMId;
                this.error = undefined;

                /*Set Pagination Data*/
                this.totalRecords = this.cases.length;
                this.totalCasesAvailable = casesListResult.totalCaseCount;
                this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
                this.showActionButtons = this.totalRecords > 0 ? true : false;
                this.setPageData();
                this.showSpinner = false;
            } else {
                this.totalRecords = 0;
                this.totalPages = 0;
                this.totalCasesAvailable = 0;
                this.showSpinner = false;
                if (isSubmitted) {
                    this.closeModal();
                }
            }
        }
        catch (err) {
            this.error = err;
            console.error('Error found:', err.body.message);
            this.showSpinner = false;
            this.cases = [];
        }
    }

    /* Starts Pagination Methods*/
    setPageData() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;

        this.visibleCases = this.cases.slice(start, end);
        this.generatePageList();
    }

    generatePageList() {
        let pages = [];

        // Always show full list if small
        if (this.totalPages <= this.maxButtonsToShow) {
            for (let i = 1; i <= this.totalPages; i++) {
                pages.push(this.createPageObject(i));
            }
        } else {
            // Start window
            let startPage = Math.max(this.currentPage - 2, 1);
            let endPage = Math.min(startPage + this.maxButtonsToShow - 1, this.totalPages);

            if (startPage > 1) {
                pages.push(this.createPageObject(1));
                if (startPage > 2) {
                    pages.push({ key: 'ellipsis-left', isEllipsis: true });
                }
            }

            for (let i = startPage; i <= endPage; i++) {
                pages.push(this.createPageObject(i));
            }

            if (endPage < this.totalPages) {
                if (endPage < this.totalPages - 1) {
                    pages.push({ key: 'ellipsis-right', isEllipsis: true });
                }
                pages.push(this.createPageObject(this.totalPages));
            }
        }

        this.pageList = pages;
    }

    createPageObject(pageNumber) {
        return {
            key: `page-${pageNumber}`,
            number: pageNumber,
            isEllipsis: false,
            class:
                pageNumber === this.currentPage
                    ? 'page-btn active'
                    : 'page-btn'
        };
    }

    handlePageClick(event) {
        const page = parseInt(event.target.dataset.page, 10);
        if (page !== this.currentPage) {
            this.currentPage = page;
            this.setPageData();
        }
    }

    handleFirst() {
        this.currentPage = 1;
        this.setPageData();
    }

    handleLast() {
        this.currentPage = this.totalPages;
        this.setPageData();
    }

    handlePrev() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.setPageData();
        }
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.setPageData();
        }
    }

    get startRecord() {
        return (this.currentPage - 1) * this.pageSize + 1;
    }

    get endRecord() {
        return Math.min(this.currentPage * this.pageSize, this.totalRecords);
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage === this.totalPages;
    }
    /*End of Pagination methods*/

    /*Edit and Close button Handling*/
    handleEditClick(event) {
        const caseId = event.target.dataset.id;
        this.visibleCases = this.visibleCases.map(c => {
            if (c.id === caseId) {
                c.oldOwnerId = c.ownerId;
                c.ownerId = '';
                c.disabled = false;
                return { ...c, isEdit: true };
            }
            return c;
        });
    }

    handleCloseClick(event) {
        const caseId = event.target.dataset.id;
        this.visibleCases = this.visibleCases.map(c => {
            if (c.id === caseId) {
                //Added fix for null value when submitting after closing the empty value in user
                if (c.ownerId == null || c.ownerId == '') {
                    this.cases.forEach(currentItem => {
                        if (currentItem.id === caseId) {
                            currentItem.ownerId = c.oldOwnerId;
                        }
                    });
                }
                c.ownerId = c.oldOwnerId;
                c.disabled = true;
                return { ...c, isEdit: false };
            }
            return c;
        });
    }
    /*End of Edit and Close button Handling*/

    async closeModal(event) {
        this.dispatchEvent(new CloseActionScreenEvent());
        this.isModalOpen = false;
        const focusedTab = await getFocusedTabInfo();

        if (focusedTab && focusedTab.tabId) {
            // Close the current tab
            await closeTab(focusedTab.tabId);
        }
    }
    /*Handling Owner Change Operation*/
    async handleOwnerChange(event) {
        const pickerElement = event.target;
        const parentDiv = pickerElement.closest('div[data-id]');
        if (parentDiv) {
            const parentId = parentDiv.getAttribute('data-id');
            console.log('Parent data-id:', parentId);
        } else {
            console.warn('Parent div with data-id not found.');
        }
        const caseId = parentDiv ? parentDiv.getAttribute('data-id') : '';
        const newOwnerId = event.detail.recordId;
        let selectedCsmName = '';
        //calling apex method to get URL
        if (newOwnerId && newOwnerId.startsWith('005')) {
            let result = await getUserName({ userId: newOwnerId });
            selectedCsmName = result;
        }

        // Find the case to update from this.cases
        const caseToUpdate = this.cases.find(c => c.id === caseId);
        if (caseToUpdate && newOwnerId != null) {
            this.cases.forEach(currentItem => {
                if (currentItem.id === caseId) {
                    currentItem.ownerId = newOwnerId;
                    if (selectedCsmName) {
                        currentItem.csmName = selectedCsmName;
                    }
                }
            });
        }
        selectedCsmName = '';
    }
    /*Handling Case Assignment Operation*/
    async handleAssignments() {
        this.showSpinner = true;
        try {
            const result = await updateCaseOwners({ roundRobinCases: this.cases, lastCSMId: this.lastCSMId });//uncomment this after testing the wrapper
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Cases Assigned Successfully!!',
                    variant: 'success'
                })
            );
            this.showSpinner = false;
            await this.loadRoundRobinCases(true);
        } catch (error) {
            this.showSpinner = false;
            let errorMessage = error.body.message;
            if (error.status == 500) {
                if (error.body.pageErrors[0].statusCode == 'OP_WITH_INVALID_USER_TYPE_EXCEPTION') {
                    errorMessage = 'A Community user has been selected. Please select a valid CSM user.';
                }
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: errorMessage,
                    variant: 'error'
                })
            );
        }
    }

    get recordOptions() {
        return [
            { label: '25', value: 25 },
            { label: '50', value: 50 },
            { label: '75', value: 75 },
            { label: '100', value: 100 },
        ];
    }

    handleChange(event) {
        this.noOfRecords = Number(event.detail.value);
        this.showSpinner = true;
        this.loadRoundRobinCases(false);
    }
}