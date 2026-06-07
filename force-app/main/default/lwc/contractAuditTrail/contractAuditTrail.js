import { LightningElement, api, track } from 'lwc';
import getAuditRecords from '@salesforce/apex/ContractAuditController.getAuditRecords';

const PAGE_SIZE = 10; // must match Apex PAGE_SIZE constant

export default class ContractAuditTrail extends LightningElement {
    @api recordId;
    @track auditRows = [];
    @track isLoading = false;
    @track error = '';

    // Each entry = the Change_Time__c of the OLDEST record of that page
    // so we can re-fetch that page when going back
    cursorStack = [];

    // The oldest Change_Time__c on the current page
    // passed to Apex as the "fetch records newer than this" cursor
    currentPageOldestTime = '';

    connectedCallback() {
        this.loadFirstPage();
    }

    // ── Load helpers ──────────────────────────────────────────

    loadFirstPage() {
        this.cursorStack = [];
        this.currentPageOldestTime = '';
        this.fetchRecords('');
    }

    fetchRecords(cursorTime) {
        this.isLoading = true;
        this.error = '';

        getAuditRecords({
            contractId: this.recordId,
            lastSeenTime: cursorTime
        })
        .then(data => {
            this.auditRows = data;

            if (data.length > 0) {
                // Apex returns newest-first (reversed ASC)
                // So data[0]  = newest record on this page
                //    data[last] = oldest record on this page
                this.currentPageOldestTime = data[data.length - 1].Change_Time__c;
            }

            this.isLoading = false;
            this.error = '';
        })
        .catch(err => {
            this.error = 'Error loading audit trail: ' +
                (err.body ? err.body.message : err.message);
            this.isLoading = false;
        });
    }

    // ── Pagination handlers ───────────────────────────────────

    handleNext() {
        // Save the oldest time of the current page so Previous can return here
        this.cursorStack.push(this.currentPageOldestTime);

        // Fetch the next page: records older than the oldest on current page
        // Apex query: WHERE Change_Time__c > cursor — but we need OLDER records
        // So pass the oldest time; Apex fetches the next ASC window beyond it
        this.fetchRecords(this.currentPageOldestTime);
    }

    handlePrev() {
        // Remove current page's cursor
        this.cursorStack.pop();

        // The previous page's cursor is now at the top of the stack
        // If stack is empty, we're back to page 1 (no cursor)
        const prevCursor = this.cursorStack.length > 0
            ? this.cursorStack[this.cursorStack.length - 1]
            : '';

        this.fetchRecords(prevCursor);
    }

    // ── Computed properties ───────────────────────────────────

    get noRecords() {
        return this.auditRows.length === 0 && !this.isLoading;
    }

    get isPrevDisabled() {
        return this.cursorStack.length === 0;
    }

    get isNextDisabled() {
        // If fewer records returned than page size, we're on the last page
        return this.auditRows.length < PAGE_SIZE || this.isLoading;
    }
}