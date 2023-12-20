@RestResource(urlMapping='/api/sms/approve/*')
global with sharing class FinPlanApproveSMSAPIController {

    public static Map<String, Map<string, List<String>>> apiResponse = new Map<String, Map<string, List<String>>>();
            
    // This method approves the messages which means transaction records are created from these messages and
    // to save storage these sms records are deleted from the system. 
    @HttpPost
    global static Map<String, Map<string, List<String>>> updateApprovedField(Map<String, List<String>> input) {
        
        List<String> recordIds = input.get('data');
        List<finplan__sms_message__c> recordsToUpdate = [SELECT id, Content__c, Approved__c, Amount_Value__c, Beneficiary__c ,CC_Available_Balance__c,
                        Payment_Reference__c, Payment_Via__c ,SA_Available_Balance__c , Savings_or_CC_Account__c ,Transaction_Date__c, Type__c 
                        FROM SMS_Message__c WHERE id IN :recordIds];

        
        if(recordsToUpdate != null && recordsToUpdate.size() > 0) {
            apiResponse = FinPlanTransactionHandler.createTransactions(recordsToUpdate);
            // Can be commented in later, currently commented out so messages are not deleted
            // delete recordsToUpdate;
            // Database.emptyRecycleBin(recordsToUpdate);
        }

        return apiResponse;
    }
}