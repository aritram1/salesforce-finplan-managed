@RestResource(urlMapping='/api/sms/delete/*')
global with sharing class FinPlanDeleteSMSAPIController {

    // This method processes post requests at this endpoint and deletes selected/all messages
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    @HttpPost
    global static Map<String, Object> processPostRequests() {
        Map<String, List<String>> response = new Map<String, List<String>>();
        List<String> deletedIds = new List<String>();
        List<String> errors = new List<String>();
        
        try {
            List<SMS_Message__c> messagesToDelete = [SELECT Id FROM Account];
            if(messagesToDelete != null && messagesToDelete.size() > 0){
                Database.DeleteResult [] deleteResults = Database.delete(messagesToDelete, false);
                for(Database.DeleteResult dr : deleteResults){
                    deletedIds.add(dr.getId());
                }
                Database.emptyRecycleBin(messagesToDelete);
            }
            response = null;
            response.put('deletedIds', deletedIds);
        } 
        catch (Exception e) {
            errors.add(e.getMessage());
            response.put('errors', errors);
        }
        return response;
    }
    
}

// Request body : Not required
// Error Response structures :
// [{"errorCode":"APEX_ERROR","message":"System.MathException: Divide by 0\n\nClass.FinPlan.FinPlanDeleteSMSAPIController.processPostRequests: line 10, column 1"}]
// [{"errorCode":"APEX_ERROR","message":"System.NullPointerException: Attempt to de-reference a null object\n\nClass.FinPlan.FinPlanDeleteSMSAPIController.processPostRequests: line 25, column 1"}]

// Success Response Structure
// { "deletedIds" : ['id1', 'id2' etc], "errors" : []}