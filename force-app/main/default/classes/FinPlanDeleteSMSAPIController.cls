@RestResource(urlMapping='/api/sms/delete/*')
global with sharing class FinPlanDeleteSMSAPIController {

    // This method processes post requests at this endpoint and deletes selected/all messages
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    @HttpPost
    global static Map<String, List<String>> processPostRequests() {
        Map<String, List<String>> response = new Map<String, List<String>>();
        List<String> deletedIds = new List<String>();
        List<String> errors = new List<String>();
        try {
            List<SMS_Message__c> messagesToDelete = [SELECT Id FROM SMS_Message__c];
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
// Response structure for Error :
// [{"errorCode":"APEX_ERROR","message":"System.MathException: Divide by 0\n\nClass.FinPlan.FinPlanDeleteSMSAPIController.processPostRequests: line 10, column 1"}]