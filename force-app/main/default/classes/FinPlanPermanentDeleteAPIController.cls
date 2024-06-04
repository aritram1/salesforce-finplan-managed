@RestResource(urlMapping='/api/delete/*')
global with sharing class FinPlanPermanentDeleteAPIController {

    static final String TAG = 'FinPlanPermanentDeleteAPIController';
    
    @HttpPost
    global static Map<String, String> permanentlyDeleteMessagesAndTransactions(String deviceId) {
        Map<String, String> response = new  Map<String, String>();
        try{
            String message = '';

            // Delete logs
            List<FinPlan__System_Log__c> logs = [SELECT id from FinPlan__System_Log__c];
            delete logs;
            if(logs.size() > 0){
                Database.emptyRecycleBin(logs);     
            }       
            
            // Delete messages
            List<SMS_Message__c> messagesToDelete = [SELECT Id FROM SMS_Message__c where FinPlan__Device__c = :deviceId];
            if(messagesToDelete != null && messagesToDelete.size() > 0){
                Database.delete(messagesToDelete, false);
                Database.emptyRecycleBin(messagesToDelete);
            }
            message = message + messagesToDelete.size() + ' messages are found and deleted | ';

            // Delete bank transactions
            List<FinPlan__Bank_Transaction__c> bankTxntoDelete = [SELECT Id FROM FinPlan__Bank_Transaction__c where FinPlan__Created_From__c != 'Manual'];
            if(bankTxntoDelete != null && bankTxntoDelete.size() > 0){
                Database.delete(bankTxntoDelete, false);
                Database.emptyRecycleBin(bankTxntoDelete); 
            }
            message = message + bankTxntoDelete.size() + ' bank transactions found and deleted | ';
            
            // Delete investment transactions
            List<FinPlan__Investment_Transaction2__c> invTxntoDelete = [SELECT Id FROM FinPlan__Investment_Transaction2__c where FinPlan__Created_From__c != 'Manual'];
            if(invTxntoDelete != null && invTxntoDelete.size() > 0){
                Database.delete(invTxntoDelete, false);
                Database.emptyRecycleBin(invTxntoDelete);
            }
            message = message + invTxntoDelete.size() + ' investment transactions are found and deleted | ';
            
            // Add to data property
            response.put('data', message);
            response.put('statusCode', '200');
        }
        catch(Exception e){
            // Get the detail error Info and Log the error, also add to errors property
            String errorMessage = FinPlanLogger.getDetailedErrorMessage(e);
            FinPlanLogger.logError(new FinPlanException(errorMessage), TAG);
            response.put('errors', errorMessage);
            response.put('statusCode', '400');
        }
        return response;
    }
    
}