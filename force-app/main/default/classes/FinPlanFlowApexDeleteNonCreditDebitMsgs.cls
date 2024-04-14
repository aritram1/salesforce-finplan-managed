public with sharing class FinPlanFlowApexDeleteNonCreditDebitMsgs {
    
    // Invocable method that can be called from a Salesforce Flow
    @InvocableMethod(label='Delete Non Credit/Debit Messages' 
                     description='Deletes messages permanently')
    public static void deleteNonCreditDebitMessages(List<String> deviceIds) {
        List<SMS_Message__c> messagesToDelete = [SELECT Id FROM SMS_Message__c WHERE FinPlan__Type__c != 'credit' AND FinPlan__Type__c != 'debit' AND FinPlan__Device__c = :deviceIds[0]];
        if(messagesToDelete != null && messagesToDelete.size() > 0){
            Database.delete(messagesToDelete, false);
            Database.emptyRecycleBin(messagesToDelete);
        }
    }

}