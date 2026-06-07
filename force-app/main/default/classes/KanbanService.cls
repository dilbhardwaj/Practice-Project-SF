public with sharing class KanbanService {

    @AuraEnabled(cacheable=true)
    public static Map<String, List<Case>> getCasesByStatus() {
        Map<String, List<Case>> result = new Map<String, List<Case>>();

        List<Case> cases = [
            select id, CaseNumber, Subject, Status,
                   Priority, Owner.Name, CreatedDate
            from Case
            where isClosed = false
            order by createddate desc
            limit 200
        ];

        for (Case c : cases) {
            if (!result.containsKey(c.Status)) {
                result.put(c.Status, new List<Case>());
            }
            result.get(c.Status).add(c);
        }

        return result;
    }

    @AuraEnabled
    public static void updateCaseStatus(Id caseId, String newStatus) {

        List<Case> cases = [
            select id, Status
            from Case
            where id = :caseId
            limit 1
        ];

        if (cases.isEmpty()) {
            throw new AuraHandledException('Case not found: ' + caseId);
        }

        String currentStatus = cases[0].Status;

        Boolean isAllowed = isTransitionAllowed(currentStatus, newStatus);

        if (!isAllowed) {
            throw new AuraHandledException(
                'Transition from "' + currentStatus + '" to "' + newStatus + '" is not allowed.'
            );
        }

        cases[0].Status = newStatus;
        update cases[0];
    }

    private static Boolean isTransitionAllowed(String fromStatus, String toStatus) {
        List<Case_Status_Transition__mdt> transitions = [
            select Allowed__c
            from Case_Status_Transition__mdt
            where From_Status__c = :fromStatus
              and To_Status__c   = :toStatus
            limit 1
        ];

        if (transitions.isEmpty()) {
            return false;
        }

        return transitions[0].Allowed__c;
    }
}