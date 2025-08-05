public class UnlockRecords {
    
    public class UnlockResult {
        @InvocableVariable public Id recordId;
        @InvocableVariable public Boolean success;
        @InvocableVariable public String errorMessage;
        
        public UnlockResult(Id recordId, Boolean success, String errorMessage) {
            this.recordId = recordId;
            this.success = success;
            this.errorMessage = errorMessage;
        }
    }
    
    public class UnlockRequest {
        @InvocableVariable(required=true label='Record IDs' 
                          description='List of record IDs to unlock')
        public List<Id> recordIds;
    }
    
    /**
     * Unlock records locked via approval process
     * @param requests List of UnlockRequest containing record IDs to unlock
     * @return List of UnlockResult with success/failure status for each record
     */
    @InvocableMethod(label='Unlock Records' 
                     description='Unlocks a list of records and returns results')
    public static List<List<UnlockResult>> unlock(List<UnlockRequest> requests) {
        List<List<UnlockResult>> allResults = new List<List<UnlockResult>>();
        
        for(UnlockRequest request : requests) {
            List<UnlockResult> results = new List<UnlockResult>();
            
            // Null safety check
            if(request == null || request.recordIds == null || request.recordIds.isEmpty()) {
                allResults.add(results);
                continue;
            }
            
            // Collect records that need unlocking
            List<Id> recordsToUnlock = new List<Id>();
            Map<Id, UnlockResult> resultMap = new Map<Id, UnlockResult>();
            
            for(Id recordId : request.recordIds) {
                if(recordId == null) {
                    results.add(new UnlockResult(recordId, false, 'Invalid record ID: null'));
                    continue;
                }
                
                try {
                    if(Approval.isLocked(recordId)) {
                        recordsToUnlock.add(recordId);
                        resultMap.put(recordId, new UnlockResult(recordId, true, null));
                    } else {
                        results.add(new UnlockResult(recordId, true, 'Record was not locked'));
                    }
                } catch(Exception e) {
                    results.add(new UnlockResult(recordId, false, 'Error checking lock status: ' + e.getMessage()));
                }
            }
            
            // Bulk unlock operation
            if(!recordsToUnlock.isEmpty()) {
                try {
                    List<Approval.UnlockResult> unlockResults = Approval.unlock(recordsToUnlock);
                    
                    // Process results
                    for(Integer i = 0; i < unlockResults.size(); i++) {
                        Id recordId = recordsToUnlock[i];
                        Approval.UnlockResult unlockResult = unlockResults[i];
                        
                        if(unlockResult.isSuccess()) {
                            results.add(new UnlockResult(recordId, true, null));
                        } else {
                            String errorMsg = 'Unlock failed';
                            if(!unlockResult.getErrors().isEmpty()) {
                                errorMsg += ': ' + unlockResult.getErrors()[0].getMessage();
                            }
                            results.add(new UnlockResult(recordId, false, errorMsg));
                        }
                    }
                } catch(Exception e) {
                    // If bulk operation fails, mark all as failed
                    for(Id recordId : recordsToUnlock) {
                        results.add(new UnlockResult(recordId, false, 'Bulk unlock failed: ' + e.getMessage()));
                    }
                }
            }
            
            allResults.add(results);
        }
        
        return allResults;
    }
}
