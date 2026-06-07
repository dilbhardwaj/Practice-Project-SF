public without sharing class ContractAuditController {
    private static final Integer PAGE_SIZE = 10;

    @AuraEnabled(cacheable=false)
    public static List<Contract_Audit__b> getAuditRecords(
        String contractId,
        String lastSeenTime
    ) {
        List<Contract_Audit__b> results;

        if (String.isBlank(lastSeenTime)) {
    
            results = [
                SELECT Contract_Id__c, Field_Name__c, Old_Value__c,
                       New_Value__c, Changed_By__c, Change_Time__c
                FROM Contract_Audit__b
                WHERE Contract_Id__c = :contractId
                ORDER BY Contract_Id__c ASC, Change_Time__c ASC
                LIMIT 10000   
            ];
            if (results.size() > PAGE_SIZE) {
                results = sliceLast(results, PAGE_SIZE);
            }

        } else {
            DateTime cursor = parseCursor(lastSeenTime);

            results = [
                SELECT Contract_Id__c, Field_Name__c, Old_Value__c,
                       New_Value__c, Changed_By__c, Change_Time__c
                FROM Contract_Audit__b
                WHERE Contract_Id__c = :contractId
                  AND Change_Time__c < :cursor
                ORDER BY Contract_Id__c ASC, Change_Time__c ASC
                LIMIT 10000
            ];
            if (results.size() > PAGE_SIZE) {
                results = sliceLast(results, PAGE_SIZE);
            }
        }

        return reverseList(results);
    }


    private static DateTime parseCursor(String raw) {
        try {
            String cleaned = raw.replace('T', ' ').replace('Z', '').left(19);
            return DateTime.valueOfGmt(cleaned);
        } catch (Exception e) {
            throw new AuraHandledException('Invalid cursor: ' + raw);
        }
    }

    private static List<Contract_Audit__b> sliceLast(
        List<Contract_Audit__b> src, Integer n
    ) {
        List<Contract_Audit__b> sliced = new List<Contract_Audit__b>();
        Integer start = src.size() - n;
        for (Integer i = start; i < src.size(); i++) {
            sliced.add(src[i]);
        }
        return sliced;
    }

    private static List<Contract_Audit__b> reverseList(
        List<Contract_Audit__b> src
    ) {
        List<Contract_Audit__b> reversed = new List<Contract_Audit__b>();
        for (Integer i = src.size() - 1; i >= 0; i--) {
            reversed.add(src[i]);
        }
        return reversed;
    }
}