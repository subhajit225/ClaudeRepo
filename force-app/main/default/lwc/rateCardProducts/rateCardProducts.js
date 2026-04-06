import { LightningElement, wire, track } from 'lwc';
import getProducts from '@salesforce/apex/RateCardProductsController.getProducts';
import saveProducts from '@salesforce/apex/RateCardProductsController.saveProducts';
import deleteProducts from '@salesforce/apex/RateCardProductsController.deleteProducts';
import updateSortOrder from '@salesforce/apex/RateCardProductsController.updateSortOrder';
import addProductToTable from '@salesforce/apex/RateCardProductsController.addRateCardProduct';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const PAGE_SIZE = 50;
export default class RateCardProducts extends LightningElement {

    @track products = [];
    @track pagedData = [];
    @track draftValues = [];
    @track selectedRows = [];

    sortedBy = 'Product_Name__c';
    sortedDirection = 'asc';

    pageNumber = 1;
    totalPages = 1;

    wiredResult;

    isLoading = false;
    @track selectedProductId = '';
    showPicker = true;

    columns = [
        { label: 'Product name', fieldName: 'Product_Name__c', sortable: true, editable: true, wrapText: true, hideDefaultActions: true, resizable: false },
        { label: 'Product description', fieldName: 'Product_Description__c', editable: true, wrapText: true, hideDefaultActions: true, resizable: false }
        //,{ label: 'Sort Order', fieldName: 'Sort_Order__c', editable: false, hideDefaultActions: true }
    ];

    /* ---------------- DATA ---------------- */

    @wire(getProducts)
    wiredProducts(result) {
        this.wiredResult = result;
        if (result.data && result.data.length > 0) {
            this.products = result.data;
            this.sortedDirection = this.products[0].Sort_Order__c;
            this.setupPagination();
        } else {
            this.products = [];
        }
    }

    get hasData() {
        return this.products.length > 0;
    }

    get isDeleteDisabled() {
        return this.selectedRows.length === 0;
    }

    /* ---------------- TOAST ---------------- */

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    /* ---------------- PAGINATION ---------------- */

    setupPagination() {
        this.totalPages = Math.ceil(this.products.length / PAGE_SIZE);
        this.pageNumber = 1;
        this.updatePagedData();
    }

    updatePagedData() {
        const start = (this.pageNumber - 1) * PAGE_SIZE;
        this.pagedData = this.products.slice(start, start + PAGE_SIZE);
    }

    nextPage() {
        if (this.pageNumber < this.totalPages) {
            this.pageNumber++;
            this.updatePagedData();
        }
    }

    previousPage() {
        if (this.pageNumber > 1) {
            this.pageNumber--;
            this.updatePagedData();
        }
    }

    get isFirstPage() {
        return this.pageNumber === 1;
    }

    get isLastPage() {
        return this.pageNumber === this.totalPages;
    }

    /* ---------------- SORT ---------------- */

    handleSort(event) {
        const { sortDirection } = event.detail;
        const value = sortDirection;

        this.isLoading = true;

        updateSortOrder({ sortDirection: value })
            .then(() => {
                this.sortedDirection = sortDirection;
                //this.showToast('Success', `Sort order updated to ${value}`, 'success');
                return refreshApex(this.wiredResult);
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /* ---------------- INLINE SAVE ---------------- */

    handleSave(event) {
        const drafts = event.detail.draftValues;

        // VALIDATION: prevent null / empty values
        const hasInvalidRow = drafts.some(d =>
            (d.Product_Name__c !== undefined && !d.Product_Name__c?.trim()) ||
            (d.Product_Description__c !== undefined && !d.Product_Description__c?.trim())
        );

        if (hasInvalidRow) {
            this.showToast('Error', 'Product Name and Product Description cannot be empty', 'error');
            return;
        }
        this.isLoading = true;

        saveProducts({ products: event.detail.draftValues })
            .then(() => {
                this.showToast('Success', 'Products updated', 'success');
                this.draftValues = [];
                return refreshApex(this.wiredResult);
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /* ---------------- ROW SELECTION ---------------- */

    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows;
    }

    /* ---------------- DELETE ---------------- */

    deleteSelected() {
        const ids = this.selectedRows.map(r => r.Id);

        this.isLoading = true;

        deleteProducts({ productIds: ids })
            .then(() => {
                this.showToast('Success', `${ids.length} product(s) deleted`, 'success');
                this.selectedRows = [];
                return refreshApex(this.wiredResult);
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    async handleProductSelection(e) {
        const selectedProdId = e.detail.recordId;
        console.log(selectedProdId);
        if (selectedProdId) {
            this.isLoading = true;
            try {
                let result = await addProductToTable({ productId: selectedProdId });
                if (result && result.isDuplicate) {
                    this.showToast('Duplicate', 'Product already exist in the table.', 'error');
                }
                else {
                    if (result && result.recId != null && !result.isDuplicate) {
                        this.showPicker = false;
                        this.showToast('Success', 'Product added', 'success');
                        this.selectedProductId = null;
                        await refreshApex(this.wiredResult);
                        setTimeout(() => {
                            this.showPicker = true;
                        }, 0);
                        setTimeout(() => {
                            this.template.querySelector('lightning-record-picker[data-id="rateCardProductPicker"]')?.focus();
                        }, 2);
                    }
                }
            } catch (error) {
                console.error('Error adding product:', error);
                this.showToast('Error', error.body.message, 'error');
            } finally {
                this.isLoading = false;
            }
        }
    }
}