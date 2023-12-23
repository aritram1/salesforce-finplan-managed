public with sharing class FinPlanDeleteAPIController {
    // This method deletes all transaction records - This is mostly when syncing / debugging
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static Map<String, String> deleteAllTransactionsAndClearRecycleBin() {
        Map<String, String> response = new Map<String, String>();
        String message = '';
        try {
            List<FinPlan__Bank_Transaction__c> bankTxntoDelete = [SELECT Id FROM FinPlan__Bank_Transaction__c];
            List<FinPlan__Investment_Transaction__c> invTxntoDelete = [SELECT Id FROM FinPlan__Investment_Transaction__c];
            if(bankTxntoDelete != null && bankTxntoDelete.size() > 0){
                Database.DeleteResult[] deleteResults = Database.delete(bankTxntoDelete, false);
                Database.emptyRecycleBin(bankTxntoDelete);
                message = 'SUCCESS : ' + bankTxntoDelete.size() + ' bank transaction records deleted successfully. ';
            }
            else{
                message = 'SUCCESS : No bank transactions are available to delete. ';
            }
            if(invTxntoDelete != null && invTxntoDelete.size() > 0){
                Database.DeleteResult[] deleteResults = Database.delete(invTxntoDelete, false);
                Database.emptyRecycleBin(invTxntoDelete);
                message = 'SUCCESS : ' + invTxntoDelete.size() + ' investment records deleted successfully. ';
            }
            else{
                message = 'SUCCESS : No investment transactions available to delete. ';
            }
            response.put('data', message);
        } 
        catch (Exception e) {
            message = 'Failed : Error deleting transactions : ' + e.getMessage();
            response.put('errors', message);
        }
        return response;
    }
}

// public static Map<String, String> deleteAllTransactionsAndClearRecycleBin() {
//     Map<String, String> response = new Map<String, String>();
//     String message = '';
//     try {
//         List<FinPlan__Bank_Transaction__c> bankTxntoDelete = [SELECT Id FROM FinPlan__Bank_Transaction__c];
//         List<FinPlan__Investment_Transaction__c> invTxntoDelete = [SELECT Id FROM FinPlan__Investment_Transaction__c];
//         if(bankTxntoDelete != null && bankTxntoDelete.size() > 0){
//             Database.DeleteResult[] deleteResults = Database.delete(bankTxntoDelete, false);
//             Database.emptyRecycleBin(bankTxntoDelete);
//             message = 'SUCCESS : ' + bankTxntoDelete.size() + ' bank transaction records deleted successfully. ';
//         }
//         else{
//             message = 'SUCCESS : No bank transactions are available to delete. ';
//         }
//         if(invTxntoDelete != null && invTxntoDelete.size() > 0){
//             Database.DeleteResult[] deleteResults = Database.delete(invTxntoDelete, false);
//             Database.emptyRecycleBin(invTxntoDelete);
//             message = 'SUCCESS : ' + invTxntoDelete.size() + ' investment records deleted successfully. ';
//         }
//         else{
//             message = 'SUCCESS : No investment transactions available to delete. ';
//         }
//         response.put('data', message);
//     } 
//     catch (Exception e) {
//         message = 'Failed : Error deleting transactions : ' + e.getMessage();
//         response.put('errors', message);
//     }
//     return response;
// }