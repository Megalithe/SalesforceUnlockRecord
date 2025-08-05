@isTest
public class UnlockRecordsTest {
    
    @TestSetup
    static void makeData() {
        // Create test accounts
        List<Account> testAccounts = new List<Account>();
        for(Integer i = 0; i < 5; i++) {
            testAccounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert testAccounts;
    }
    
    @isTest
    static void testUnlockLockedRecords() {
        // Get test accounts
        List<Account> accounts = [SELECT Id FROM Account LIMIT 3];
        
        // Lock the accounts using approval process simulation
        List<Id> accountIds = new List<Id>();
        for(Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        
        // Lock records (simulate approval process lock)
        Approval.lock(accountIds);
        
        // Verify records are locked
        for(Id accountId : accountIds) {
            System.assert(Approval.isLocked(accountId), 'Account should be locked');
        }
        
        Test.startTest();
        
        // Create unlock request
        UnlockRecords.UnlockRequest request = new UnlockRecords.UnlockRequest();
        request.recordIds = accountIds;
        
        // Call unlock method
        List<List<UnlockRecords.UnlockResult>> results = UnlockRecords.unlock(new List<UnlockRecords.UnlockRequest>{request});
        
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should have one result set');
        List<UnlockRecords.UnlockResult> unlockResults = results[0];
        System.assertEquals(3, unlockResults.size(), 'Should have 3 unlock results');
        
        // Verify all records were successfully unlocked
        for(UnlockRecords.UnlockResult result : unlockResults) {
            System.assertEquals(true, result.success, 'Unlock should be successful for record: ' + result.recordId);
            System.assertEquals(null, result.errorMessage, 'Should have no error message');
        }
        
        // Verify records are no longer locked
        for(Id accountId : accountIds) {
            System.assert(!Approval.isLocked(accountId), 'Account should no longer be locked');
        }
    }
    
    @isTest
    static void testUnlockAlreadyUnlockedRecords() {
        // Get test accounts (these are not locked)
        List<Account> accounts = [SELECT Id FROM Account LIMIT 2];
        List<Id> accountIds = new List<Id>();
        for(Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        
        Test.startTest();
        
        // Create unlock request
        UnlockRecords.UnlockRequest request = new UnlockRecords.UnlockRequest();
        request.recordIds = accountIds;
        
        // Call unlock method
        List<List<UnlockRecords.UnlockResult>> results = UnlockRecords.unlock(new List<UnlockRecords.UnlockRequest>{request});
        
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should have one result set');
        List<UnlockRecords.UnlockResult> unlockResults = results[0];
        System.assertEquals(2, unlockResults.size(), 'Should have 2 unlock results');
        
        // Verify all records show success (already unlocked)
        for(UnlockRecords.UnlockResult result : unlockResults) {
            System.assertEquals(true, result.success, 'Should be successful for already unlocked record');
            System.assertEquals('Record was not locked', result.errorMessage, 'Should indicate record was not locked');
        }
    }
    
    @isTest
    static void testUnlockWithNullRecordIds() {
        Test.startTest();
        
        // Create unlock request with null record IDs
        UnlockRecords.UnlockRequest request = new UnlockRecords.UnlockRequest();
        request.recordIds = null;
        
        // Call unlock method
        List<List<UnlockRecords.UnlockResult>> results = UnlockRecords.unlock(new List<UnlockRecords.UnlockRequest>{request});
        
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should have one result set');
        List<UnlockRecords.UnlockResult> unlockResults = results[0];
        System.assertEquals(0, unlockResults.size(), 'Should have no unlock results for null input');
    }
    
    @isTest
    static void testUnlockWithEmptyList() {
        Test.startTest();
        
        // Create unlock request with empty list
        UnlockRecords.UnlockRequest request = new UnlockRecords.UnlockRequest();
        request.recordIds = new List<Id>();
        
        // Call unlock method
        List<List<UnlockRecords.UnlockResult>> results = UnlockRecords.unlock(new List<UnlockRecords.UnlockRequest>{request});
        
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should have one result set');
        List<UnlockRecords.UnlockResult> unlockResults = results[0];
        System.assertEquals(0, unlockResults.size(), 'Should have no unlock results for empty input');
    }
    
    @isTest
    static void testUnlockWithInvalidRecordId() {
        Test.startTest();
        
        // Create unlock request with null record ID in list
        UnlockRecords.UnlockRequest request = new UnlockRecords.UnlockRequest();
        request.recordIds = new List<Id>{null};
        
        // Call unlock method
        List<List<UnlockRecords.UnlockResult>> results = UnlockRecords.unlock(new List<UnlockRecords.UnlockRequest>{request});
        
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should have one result set');
        List<UnlockRecords.UnlockResult> unlockResults = results[0];
        System.assertEquals(1, unlockResults.size(), 'Should have one unlock result');
        
        UnlockRecords.UnlockResult result = unlockResults[0];
        System.assertEquals(false, result.success, 'Should fail for null record ID');
        System.assert(result.errorMessage.contains('Invalid record ID'), 'Should indicate invalid record ID');
    }
    
    @isTest
    static void testUnlockMixedScenario() {
        // Get test accounts
        List<Account> accounts = [SELECT Id FROM Account LIMIT 4];
        
        // Lock first two accounts
        List<Id> lockedAccountIds = new List<Id>{accounts[0].Id, accounts[1].Id};
        Approval.lock(lockedAccountIds);
        
        // Create mixed list: locked records, unlocked records, and null
        List<Id> mixedIds = new List<Id>{
            accounts[0].Id,  // locked
            accounts[1].Id,  // locked
            accounts[2].Id,  // not locked
            accounts[3].Id,  // not locked
            null             // invalid
        };
        
        Test.startTest();
        
        // Create unlock request
        UnlockRecords.UnlockRequest request = new UnlockRecords.UnlockRequest();
        request.recordIds = mixedIds;
        
        // Call unlock method
        List<List<UnlockRecords.UnlockResult>> results = UnlockRecords.unlock(new List<UnlockRecords.UnlockRequest>{request});
        
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should have one result set');
        List<UnlockRecords.UnlockResult> unlockResults = results[0];
        System.assertEquals(5, unlockResults.size(), 'Should have 5 unlock results');
        
        // Verify locked records were unlocked successfully
        System.assertEquals(true, unlockResults[0].success, 'First locked record should be unlocked');
        System.assertEquals(true, unlockResults[1].success, 'Second locked record should be unlocked');
        
        // Verify unlocked records show success with appropriate message
        System.assertEquals(true, unlockResults[2].success, 'Unlocked record should show success');
        System.assertEquals('Record was not locked', unlockResults[2].errorMessage, 'Should indicate not locked');
        System.assertEquals(true, unlockResults[3].success, 'Unlocked record should show success');
        System.assertEquals('Record was not locked', unlockResults[3].errorMessage, 'Should indicate not locked');
        
        // Verify null record ID shows failure
        System.assertEquals(false, unlockResults[4].success, 'Null record ID should fail');
        System.assert(unlockResults[4].errorMessage.contains('Invalid record ID'), 'Should indicate invalid ID');
    }
    
    @isTest
    static void testMultipleRequests() {
        // Get test accounts
        List<Account> accounts = [SELECT Id FROM Account LIMIT 4];
        
        // Lock some accounts
        Approval.lock(new List<Id>{accounts[0].Id, accounts[2].Id});
        
        Test.startTest();
        
        // Create multiple unlock requests
        UnlockRecords.UnlockRequest request1 = new UnlockRecords.UnlockRequest();
        request1.recordIds = new List<Id>{accounts[0].Id, accounts[1].Id};
        
        UnlockRecords.UnlockRequest request2 = new UnlockRecords.UnlockRequest();
        request2.recordIds = new List<Id>{accounts[2].Id, accounts[3].Id};
        
        // Call unlock method with multiple requests
        List<List<UnlockRecords.UnlockResult>> results = UnlockRecords.unlock(
            new List<UnlockRecords.UnlockRequest>{request1, request2}
        );
        
        Test.stopTest();
        
        // Verify results
        System.assertEquals(2, results.size(), 'Should have two result sets');
        
        // Verify first request results
        List<UnlockRecords.UnlockResult> results1 = results[0];
        System.assertEquals(2, results1.size(), 'First request should have 2 results');
        
        // Verify second request results  
        List<UnlockRecords.UnlockResult> results2 = results[1];
        System.assertEquals(2, results2.size(), 'Second request should have 2 results');
    }
}
