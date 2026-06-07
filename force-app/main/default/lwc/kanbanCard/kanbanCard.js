/*
 * kanbanCard.js
 * Handles drag start and drag end for a single card.
 * Sets the caseId on dataTransfer so the column knows which card was dragged.
 */
import { LightningElement, api, track } from 'lwc';

export default class KanbanCard extends LightningElement {

    // the Case record passed in from the column
    @api card;

    // controls visual feedback during drag
    @track isDragging = false;

    // format the created date nicely
    get formattedDate() {
        if (!this.card || !this.card.CreatedDate) return '';
        let d = new Date(this.card.CreatedDate);
        return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    }

    // dynamic class for the card wrapper — adds dragging style
    get cardClass() {
        return 'kanban-card' + (this.isDragging ? ' is-dragging' : '');
    }

    // left border color based on priority
    get priorityBadgeClass() {
        let p = this.card && this.card.Priority ? this.card.Priority.toLowerCase() : 'low';
        return 'priority-stripe priority-' + p;
    }

    // small badge label class
    get priorityClass() {
        let p = this.card && this.card.Priority ? this.card.Priority.toLowerCase() : 'low';
        return 'priority-badge badge-' + p;
    }

    /*
     * handleDragStart fires when user starts dragging this card.
     * We store the case Id in dataTransfer so any drop target can read it.
     * We also store the current status so the parent knows where it came from.
     */
    handleDragStart(event) {
        this.isDragging = true;

        // put the case id and current status into the drag payload
        event.dataTransfer.setData('caseId',        this.card.Id);
        event.dataTransfer.setData('fromStatus',    this.card.Status);
        event.dataTransfer.effectAllowed = 'move';
    }

    /*
     * handleDragEnd fires when the drag operation ends (drop or cancel).
     * We remove the dragging visual even if drop failed.
     */
    handleDragEnd() {
        this.isDragging = false;
    }
}