@RestResource(urlMapping='/api/sms/delete/*')
global with sharing class FinPlanDeleteSMSAPIController {

    // This method processes post requests at this endpoint and deletes selected/all messages
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    @HttpPost
    global static String processPostRequests() {
        String response = FinPlanSMSHandler.deleteSMSAndEmptyRecycleBin();
        return response;
    }
    
}