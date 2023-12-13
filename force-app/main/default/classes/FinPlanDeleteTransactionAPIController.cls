@RestResource(urlMapping='/api/transactions/delete/*')
global with sharing class FinPlanDeleteTransactionAPIController {
    
    @HttpPost
    global static String processPostRequest() {
        String response = '';
        try {
            response = FinPlanSMSHandler.deleteAllTransactionsAndClearRecycleBin();
        } catch (DmlException e) {
            response = 'Error updating records: ' + e.getMessage();
        }
        return response;
    }
}