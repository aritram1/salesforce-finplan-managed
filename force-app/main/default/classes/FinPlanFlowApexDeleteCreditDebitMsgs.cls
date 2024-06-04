public with sharing class FinPlanFlowApexDeleteCreditDebitMsgs {
    
    // Invocable method that can be called from a Salesforce Flow
    @InvocableMethod(label='Delete Txn Messages after 5 mins' description='Delete Txn Messages after 5 mins')
    public static void deleteCreditDebitMessages(List<FinPlan__SMS_Message__c> messageList){
        System.debug('Inside FinPlanFlowApexActions.deleteCreditDebitMessages()' + messageList.size() + ' records are deleted!');
        FinPlanTransactionHandler.deleteCreditDebitSMSMessages(messageList);
    }

}