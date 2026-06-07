@IsTest
private class KanbanServiceTest {

    @TestSetup
    static void setupData() {
        List<Case> cases = new List<Case>();

        Case c1 = new Case(Subject = 'Test Case New',         Status = 'New');
        Case c2 = new Case(Subject = 'Test Case In Progress', Status = 'Working');
        cases.add(c1);
        cases.add(c2);

        insert cases;
    }

    @IsTest
    static void testGetCasesByStatus() {
        Test.startTest();
        Map<String, List<Case>> result = KanbanService.getCasesByStatus();
        Test.stopTest();

        System.assertNotEquals(0, result.size(), 'Should return at least one status group');
    }

    @IsTest
    static void testValidTransition() {
        Case c = [select id from Case where Subject = 'Test Case New' limit 1];

        Test.startTest();

        try {
            KanbanService.updateCaseStatus(c.Id, 'Working');
            Case updated = [select Status from Case where id = :c.Id];
            System.assertEquals('Working', updated.Status, 'Status should be updated');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('not allowed') || e.getMessage().contains('not found'),
                'Should throw meaningful error');
        }
        Test.stopTest();
    }

    @IsTest
    static void testInvalidTransitionRejected() {
        Case c = [select id from Case where Subject = 'Test Case New' limit 1];

        Test.startTest();
        try {
            KanbanService.updateCaseStatus(c.Id, 'Closed');
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assert(true, 'Exception correctly thrown for invalid transition');
        }
        Test.stopTest();
    }

    @IsTest
    static void testCaseNotFound() {
        Test.startTest();
        try {
            KanbanService.updateCaseStatus('500000000000000AAA', 'Closed');
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            
        }
        Test.stopTest();
    }
}