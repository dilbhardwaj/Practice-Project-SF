import { LightningElement, api, track } from 'lwc';
import createInvoiceRecord  from '@salesforce/apex/InvoiceService.createInvoiceRecord';
import generatePdfForInvoice from '@salesforce/apex/InvoiceService.generatePdfForInvoice';
import { subscribe, onError } from 'lightning/empApi';

export default class InvoiceGenerator extends LightningElement {
    @api recordId;
    @track lineItems = [
        { id: 1, productName: '', quantity: 1, unitPrice: 0, taxRate: 20 }
    ];
    @track isLoading    = false;
    @track isAsync      = false;
    @track pdfUrl       = null;
    @track downloadUrl  = null;
    @track errorMessage = null;
    nextId = 2;

    handleLineChange(event) {
        const id    = parseInt(event.target.dataset.id);
        const field = event.target.dataset.field;
        const value = event.target.value;
        this.lineItems = this.lineItems.map(l =>
            l.id === id ? { ...l, [field]: value } : l
        );
    }

    addLine() {
        this.lineItems = [...this.lineItems,
            { id: this.nextId++, productName: '', quantity: 1, unitPrice: 0, taxRate: 20 }
        ];
    }

    removeLine(event) {
        const id = parseInt(event.target.dataset.id);
        this.lineItems = this.lineItems.filter(l => l.id !== id);
    }

    async handleGenerateInvoice() {
        this.isLoading    = true;
        this.pdfUrl       = null;
        this.downloadUrl  = null;
        this.errorMessage = null;

        try {
            // ── Step 1: commit Invoice + lines to DB ──────────────────
            const invoiceId = await createInvoiceRecord({
                opportunityId : this.recordId,
                lineItemsJson : JSON.stringify(this.lineItems)
            });

            // ── Step 2: generate PDF from committed record ────────────
            const result = await generatePdfForInvoice({ invoiceId });

            this.pdfUrl      = `/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_Pdf&versionId=${result.versionId}`;
            this.downloadUrl = `/sfc/servlet.shepherd/document/download/${result.contentDocumentId}`;

        } catch (e) {
            this.errorMessage = e.body?.message || 'Invoice generation failed.';
            console.error('Invoice generation failed:', e);
        } finally {
            this.isLoading = false;
        }
    }

    subscribeToInvoiceComplete() {
        const channel = '/event/InvoiceComplete__e';
        subscribe(channel, -1, (message) => {
            const payload = message.data.payload;
            if (payload.OpportunityId__c === this.recordId) {
                this.pdfUrl      = `/sfc/servlet.shepherd/document/download/${payload.ContentDocumentId__c}`;
                this.isLoading   = false;
                this.isAsync     = false;
            }
        });
    }
}