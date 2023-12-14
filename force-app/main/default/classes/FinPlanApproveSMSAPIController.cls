@RestResource(urlMapping='/api/sms/approve/*')
global with sharing class FinPlanApproveSMSAPIController {

    static String apiResponse = 'Default response from /api/sms/approve/*';
    
    // This method approves the messages which means transaction records are created from these messages and
    // to save storage these sms records are deleted from the system. 
    @HttpPost
    global static String updateApprovedField(Map<String, List<String>> input) {
        List<String> recordIds = input.get('data');
        List<finplan__sms_message__c> recordsToUpdate = [SELECT id, Content__c, Approved__c, Amount_Value__c, Beneficiary__c ,CC_Available_Balance__c,
                        Payment_Reference__c, Payment_Via__c ,SA_Available_Balance__c , Savings_or_CC_Account__c ,Transaction_Date__c, Type__c 
                        FROM SMS_Message__c WHERE id IN :recordIds];

        String createTransactionsFromApprovedMessageResponse = '';
        try {
            if(recordsToUpdate != null && recordsToUpdate.size() > 0) {
            createTransactionsFromApprovedMessageResponse = FinPlanSyncSMSAPIController.createTransactions(recordsToUpdate);
                // delete recordsToUpdate;
                // Database.emptyRecycleBin(recordsToUpdate);
                apiResponse = 'SUCCESS : ' + recordsToUpdate.size() + ' Message Records deleted successfully. ' + createTransactionsFromApprovedMessageResponse;
            }
        } catch (DmlException e) {
            apiResponse = 'ERROR : from /api/sms/approve/* : ' + e.getMessage();
        }
        return apiResponse;
    }
}