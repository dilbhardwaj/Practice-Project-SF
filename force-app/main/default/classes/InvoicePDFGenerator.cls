public without sharing class InvoicePDFGenerator {

    public static String getPdfBase64(String invoiceId) {

        if (Test.isRunningTest()) {
            return EncodingUtil.base64Encode(Blob.valueOf('MOCK_PDF_CONTENT'));
        }

        PageReference pdfPage = Page.InvoicePDF;
        pdfPage.getParameters().put('id', invoiceId);

        Blob pdfBlob = pdfPage.getContent();
        System.debug('PDF size bytes: ' + pdfBlob.size());
        return EncodingUtil.base64Encode(pdfBlob);
    }
}