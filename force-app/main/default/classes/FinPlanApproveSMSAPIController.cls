@RestResource(urlMapping='/api/sms/approve/*')
global with sharing class FinPlanApproveSMSAPIController {

    public static Map<String, Map<string, List<String>>> apiResponse = new Map<String, Map<string, List<String>>>();
    // This method approves the messages which means transaction records are created from these messages and
    // to save storage these sms records are deleted from the system. 
    @HttpPost
    global static Map<String, Map<string, List<String>>> updateApprovedField(Map<String, List<String>> input) {
        System.debug('input is => ' + input);
        List<String> recordIds = input.get('data');
        List<finplan__sms_message__c> recordsToUpdate = [SELECT id, Content__c, Approved__c, Amount_Value__c, Beneficiary__c ,CC_Available_Balance__c, Payment_Reference__c, Payment_Via__c ,SA_Available_Balance__c , Savings_or_CC_Account__c ,Transaction_Date__c, Type__c FROM SMS_Message__c WHERE id IN :recordIds];
        
        if(recordsToUpdate != null && recordsToUpdate.size() > 0) {
            
            // A. Either update the SMS Records ///////////////////////////////////////////////////
            // Set approved__c as false so they dont appear in approval list
            // for(finplan__sms_message__c rec : recordsToUpdate){
            //     rec.Approved__c = true;
            // }
            // update recordsToUpdate;

            // B. Or delete the SMS Records///////////////////////////////////////////////////
            // additionally to save storage delete if any unapproved ones, 
            // promotional ones etc. are left in system
            for(finplan__sms_message__c sms : [SELECT id FROM SMS_Message__c WHERE Create_Transaction__c = false]){
                recordsToUpdate.add(sms);
            }   
            delete recordsToUpdate;
            Database.emptyRecycleBin(recordsToUpdate);

            // And create corresponding transaction records from the messages
            apiResponse = FinPlanTransactionHandler.createTransactions(recordsToUpdate);
            
        }
        return apiResponse;
    }
}

// Sample input request body : Strictly follow this structure
// Map<String, dynamic> body = {
//   "input" : {
//     "data": ["a0D5i00000HdZeREAV", "a0D5i00000HdZNPEA3"]
//   }
// };