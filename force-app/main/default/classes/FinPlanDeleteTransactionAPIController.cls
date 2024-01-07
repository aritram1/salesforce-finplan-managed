@RestResource(urlMapping='/api/transactions/delete/*')
global with sharing class FinPlanDeleteTransactionAPIController {

    static final String TAG = 'FinPlanDeleteTransactionAPIController';
    
    @HttpPost
    global static Map<String, String> processPostRequest() {
        Map<String, String> response = new Map<String, String>();
        try{
            response = FinPlanPermanentDeleteAPIController.permanentlyDeleteMessagesAndTransactions();
        }
        catch(Exception e){
            response.put('error', e.getMessage());
            FinPlanLogger.logError(e, TAG);
        }
        return response;
    }
}