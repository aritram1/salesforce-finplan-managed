@RestResource(urlMapping='/api/delete/*')
global with sharing class FinPlanPermanentDeleteAPIController {
    
    @HttpPost
    global static Map<String, String> deleteRecordsFromObjects() {
        Map<String, String> response = new  Map<String, String>();
        try{
            String message = '';

            // Delete messages
            List<SMS_Message__c> messagesToDelete = [SELECT Id FROM SMS_Message__c];
            if(messagesToDelete != null && messagesToDelete.size() > 0){
                Database.delete(messagesToDelete, false);
                Database.emptyRecycleBin(messagesToDelete);
            }
            message = message + messagesToDelete.size() + ' messages are found and deleted | ';

            // Delete bank transactions
            List<FinPlan__Bank_Transaction__c> bankTxntoDelete = [SELECT Id FROM FinPlan__Bank_Transaction__c];
            if(bankTxntoDelete != null && bankTxntoDelete.size() > 0){
                Database.delete(bankTxntoDelete, false);
                Database.emptyRecycleBin(bankTxntoDelete); 
            }
            message = message + bankTxntoDelete.size() + ' bank transactions found and deleted | ';
            
            // Delete investment transactions
            List<FinPlan__Investment_Transaction__c> invTxntoDelete = [SELECT Id FROM FinPlan__Investment_Transaction__c];
            if(invTxntoDelete != null && invTxntoDelete.size() > 0){
                Database.delete(invTxntoDelete, false);
                Database.emptyRecycleBin(invTxntoDelete);
            }
            message = message + invTxntoDelete.size() + ' investment transactions are found and deleted | ';
            
            // Add to data property
            response.put('data', message);
        }
        catch(Exception e){
            // In case of errors, add to errors property
            response.put('errors', e.getMessage());
        }
        return response;
    }
    
}