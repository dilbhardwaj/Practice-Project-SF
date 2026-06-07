/*
 * kanbanColumn.js
 * Manages drop zone behaviour for a single Kanban column.
 * Fires "casedropped" custom event to the parent when a card is dropped.
 */
import { LightningElement, api, track } from 'lwc';

export default class KanbanColumn extends LightningElement {

    // the status label for this column (e.g. "New", "In Progress")
    @api status;

    // array of Case records for this column
    @api cards = [];

    // true while the Apex save is running — shows spinner
    @api isLoading = false;

    // true when a card is being dragged over this column
    @track isDragOver = false;

    // whether this column has any cards
    get hasCards() {
        return this.cards && this.cards.length > 0;
    }

    // adds drag-over highlight to the column
    get columnClass() {
        return 'kanban-column' + (this.isDragOver ? ' drag-over' : '');
    }

    /*
     * handleDragOver fires repeatedly while card hovers over this column.
     * We MUST call preventDefault() here to signal this is a valid drop zone.
     * Without this the drop event never fires.
     */
    handleDragOver(event) {
        event.preventDefault();
        event.dataTransfer.dropEffect = 'move';
    }

    /*
     * handleDragEnter fires once when the card first enters this column.
     * We use it to highlight the column.
     */
    handleDragEnter(event) {
        event.preventDefault();
        this.isDragOver = true;
    }

    /*
     * handleDragLeave fires when the card leaves this column's area.
     * We remove the highlight.
     * We check relatedTarget to avoid flickering when hovering over child elements.
     */
    handleDragLeave(event) {
        // only remove highlight if leaving the column entirely (not just entering a child)
        if (!event.currentTarget.contains(event.relatedTarget)) {
            this.isDragOver = false;
        }
    }

    /*
     * handleDrop fires when the user releases the card over this column.
     * Reads the caseId and fromStatus from dataTransfer.
     * Fires a custom "casedropped" event to the parent board.
     */
    handleDrop(event) {
        event.preventDefault();
        this.isDragOver = false;

        // read what was dragged
        let caseId     = event.dataTransfer.getData('caseId');
        let fromStatus = event.dataTransfer.getData('fromStatus');
        let toStatus   = this.status;

        // do nothing if dropped in the same column
        if (fromStatus === toStatus) {
            return;
        }

        // fire event up to the parent board with all info it needs
        this.dispatchEvent(new CustomEvent('casedropped', {
            bubbles   : true,
            composed  : true,
            detail    : {
                caseId    : caseId,
                fromStatus: fromStatus,
                toStatus  : toStatus
            }
        }));
    }
}