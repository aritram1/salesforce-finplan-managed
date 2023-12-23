@RestResource(urlMapping='/api/transactions/delete/*')
global with sharing class FinPlanDeleteTransactionAPIController {
    
    @HttpPost
    global static Map<String, String> processPostRequest() {
        Map<String, String> response = new Map<String, String>();
        response = FinPlanSMSHandler.deleteAllTransactionsAndClearRecycleBin();
        return response;
    }
}