/*
 * kanbanBoard.js
 * The parent board component.
 *
 * Key responsibilities:
 *   1. Load cases from Apex on connect
 *   2. Listen for "casedropped" events from columns
 *   3. OPTIMISTICALLY move the card in local state immediately
 *   4. Call Apex to persist the change in background
 *   5. ROLLBACK to the saved snapshot if Apex fails
 *   6. Show success/error toast
 */
import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCasesByStatus  from '@salesforce/apex/KanbanService.getCasesByStatus';
import updateCaseStatus  from '@salesforce/apex/KanbanService.updateCaseStatus';

// define the order of columns on the board
// add or remove statuses to match your org's Case Status picklist
const COLUMN_ORDER = ['New', 'Working', 'Escalated', 'Closed'];

export default class KanbanBoard extends LightningElement {

    // tracked so UI re-renders on any nested change
    @track statusColumns = [];

    // page-level loading (first load / refresh)
    @track isPageLoading = false;

    // error state
    @track hasError      = false;
    @track errorMessage  = '';

    /*
     * connectedCallback loads data when the component is first placed on the page.
     */
    connectedCallback() {
        this.loadCases();
    }

    /*
     * loadCases calls Apex and builds the statusColumns array.
     * Each entry looks like: { status: 'New', cards: [...], isLoading: false }
     */
    loadCases() {
        this.isPageLoading = true;
        this.hasError      = false;

        getCasesByStatus()
            .then(data => {
                this.statusColumns = this.buildColumns(data);
            })
            .catch(error => {
                this.hasError     = true;
                this.errorMessage = this.extractError(error);
            })
            .finally(() => {
                this.isPageLoading = false;
            });
    }

    /*
     * buildColumns converts the Apex map into the statusColumns array.
     * It uses COLUMN_ORDER to ensure consistent column ordering.
     * Columns not in COLUMN_ORDER are appended at the end.
     */
    buildColumns(apexMap) {
        let columns = [];

        // first add columns in our preferred order
        COLUMN_ORDER.forEach(status => {
            columns.push({
                status   : status,
                cards    : apexMap[status] ? [...apexMap[status]] : [],
                isLoading: false
            });
        });

        // then add any extra statuses that came from Apex but aren't in our order list
        Object.keys(apexMap).forEach(status => {
            let alreadyAdded = columns.some(col => col.status === status);
            if (!alreadyAdded) {
                columns.push({
                    status   : status,
                    cards    : [...apexMap[status]],
                    isLoading: false
                });
            }
        });

        return columns;
    }

    /*
     * handleCaseDropped is called when a "casedropped" event bubbles up from a column.
     * This is the heart of the optimistic UI pattern:
     *   Step 1 - take a deep snapshot of current state (for rollback)
     *   Step 2 - move the card in local state IMMEDIATELY (optimistic update)
     *   Step 3 - set spinner on the target column
     *   Step 4 - call Apex in background
     *   Step 5a - on success: remove spinner, show success toast
     *   Step 5b - on failure: ROLLBACK to snapshot, show error toast
     */
    handleCaseDropped(event) {
        let { caseId, fromStatus, toStatus } = event.detail;

        // --- STEP 1: take a snapshot BEFORE changing anything ---
        // JSON parse/stringify is a simple deep clone trick
        let snapshot = JSON.parse(JSON.stringify(this.statusColumns));

        // --- STEP 2: optimistically move the card in local state ---
        let movedCard = null;

        this.statusColumns = this.statusColumns.map(col => {
            let updatedCol = { ...col, cards: [...col.cards] };

            if (col.status === fromStatus) {
                // find and remove the card from the source column
                let cardIndex = updatedCol.cards.findIndex(c => c.Id === caseId);
                if (cardIndex !== -1) {
                    // splice it out and save a reference
                    movedCard = { ...updatedCol.cards[cardIndex], Status: toStatus };
                    updatedCol.cards.splice(cardIndex, 1);
                }
            }

            return updatedCol;
        });

        // add the card to the target column with the new status
        this.statusColumns = this.statusColumns.map(col => {
            if (col.status === toStatus) {
                return {
                    ...col,
                    cards    : [movedCard, ...col.cards],  // add to top
                    isLoading: true   // --- STEP 3: show spinner on target column ---
                };
            }
            return col;
        });

        // --- STEP 4: call Apex in background ---
        updateCaseStatus({ caseId: caseId, newStatus: toStatus })
            .then(() => {
                // --- STEP 5a: success ---
                // just remove the spinner, card is already in the right place
                this.setColumnLoading(toStatus, false);
                this.showToast('Success', 'Case moved to ' + toStatus, 'success');
            })
            .catch(error => {
                // --- STEP 5b: failure — ROLLBACK ---
                // restore everything from the snapshot we took before the optimistic update
                this.statusColumns = snapshot;
                this.setColumnLoading(toStatus, false);

                let msg = this.extractError(error);
                this.showToast('Move Failed', msg, 'error');
            });
    }

    /*
     * setColumnLoading finds a column by status and sets its isLoading flag.
     * Used to show/hide the spinner on a specific column.
     */
    setColumnLoading(status, loadingState) {
        this.statusColumns = this.statusColumns.map(col => {
            if (col.status === status) {
                return { ...col, isLoading: loadingState };
            }
            return col;
        });
    }

    /*
     * handleRefresh reloads all cases from Apex.
     */
    handleRefresh() {
        this.loadCases();
    }

    /*
     * showToast fires an SLDS toast notification.
     */
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title  : title,
            message: message,
            variant: variant
        }));
    }

    /*
     * extractError gets a readable message from an Apex error object.
     * AuraHandledExceptions come through in error.body.message.
     */
    extractError(error) {
        if (error && error.body && error.body.message) {
            return error.body.message;
        }
        if (error && error.message) {
            return error.message;
        }
        return 'An unexpected error occurred.';
    }
}