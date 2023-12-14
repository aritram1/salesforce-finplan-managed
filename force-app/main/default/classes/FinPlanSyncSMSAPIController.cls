@RestResource(urlMapping='/api/sms/sync/*')
global with sharing class FinPlanSyncSMSAPIController {
    
    global static List<FinPlan__SMS_Message__c> receivedMessages;
    global static List<FinPlan__SMS_Message__c> processedMessages;
    global static Map<String, String> apiResponse;
    global static String balanceUpdateResponse;
    global static String messageDeleteResponse;
    global static String afterTransactionsCreatedMessageDeleteResponse;
    global static String transactionDeleteResponse;
    
    global static String transactionCreateResponse;
    // global static String bankTransactionResponse;
    // global static String investmentTransactionResponse;
    
    
    // This method processes the post request and syncs the messages
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    @HttpPost
    global static Map<String, String> processPostRequests(List<Map<String, String>> records) {
        apiResponse = new Map<String, String>();
        apiResponse = syncMessages(records);
        return apiResponse;
    }

    // This method does more than one actions
    // 1 - Deletes existing messages and transactions
    // 2 - Inserts the New Messages
    // 3 - Updates Balances
    // 4 - Creates Transaction records
    // 5 - Deletes existing messages again [to save sf storage ;)]
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    global static Map<String, String> syncMessages(List<Map<String, String>> records) {
        try{
            messageDeleteResponse = deleteAllMessagesAndClearRecycleBin(); // null denotes no specific message but all existing messages need to be deleted
            // transactionDeleteResponse = deleteAllTransactionsAndClearRecycleBin(); [Not required since we issue that explicitly from flutter app]
            processedMessages = insertMessages(records);
            String insertMessagesResponse = 'SUCCESS : ' + processedMessages.size() + ' messages are processed. ';
            balanceUpdateResponse = FinPlanSMSHandler.handleBankAccountBalanceUpdate();
            transactionCreateResponse = FinPlanTransactionHandler.createTransactions(processedMessages);
            // investmentTransactionResponse = createInvestmentTransactions(processedMessages);
            afterTransactionsCreatedMessageDeleteResponse = deleteAllMessagesAndClearRecycleBin();
            
            apiResponse.put('statusCode', '200');
            apiResponse.put('data', '');
            apiResponse.put('data', apiResponse.get('data') + ' || messageDeleteResponse=>' + messageDeleteResponse);
            // apiResponse.put('data', apiResponse.get('data') + 'transactionDeleteResponse=>' + transactionDeleteResponse); [Not required since we issue that explicitly from flutter app]
            apiResponse.put('data', apiResponse.get('data') + '|| insertMessagesResponse=>' + insertMessagesResponse);
            apiResponse.put('data', apiResponse.get('data') + '|| balanceUpdateResponse=>' + balanceUpdateResponse);
            apiResponse.put('data', apiResponse.get('data') + '|| transactionCreateResponse=>' + transactionCreateResponse);
            apiResponse.put('data', apiResponse.get('data') + '|| afterTransactionsCreatedMessageDeleteResponse=>' + afterTransactionsCreatedMessageDeleteResponse);

            // apiResponse.put('data', apiResponse.get('data') + transactionCreateResponse);
            
            // apiResponse.put('data', apiResponse.get('data') + bankTransactionResponse);
            // apiResponse.put('data', apiResponse.get('data') + investmentTransactionResponse);
            // apiResponse.put('error', '');
        }
        catch(Exception ex){
            apiResponse.put('statusCode', '400');
            // apiResponse.put('data', '');
            apiResponse.put('error', 'Error : ' + ex.getMessage());
        }
        return apiResponse;
    }

    global static List<FinPlan__SMS_Message__c> insertMessages(List<Map<String, String>> records){
        receivedMessages = new List<FinPlan__SMS_Message__c>();
        for(Map<String, String> messageData : records){
            FinPlan__SMS_Message__c sms = new FinPlan__SMS_Message__c();
            sms.FinPlan__Content__c = messageData.get('FinPlan__Content__c');
            sms.FinPlan__Sender__c = messageData.get('FinPlan__Sender__c');
            sms.FinPlan__Received_At__c = messageData.get('FinPlan__Received_At__c');
            sms.FinPlan__Device__c = messageData.get('FinPlan__Device__c');
            receivedMessages.add(sms);
        }
        processedMessages = FinPlanSMSHandler.enrichData(receivedMessages);
        insert processedMessages;
        return processedMessages;
    }

    // global static void createInvestmentTransactions(List<FinPlan__SMS_Message__c> messageList){
    //     bankTransactions = new List<FinPlan__Transaction__c>();
    //     investmentTransactions = new List<FinPlan__Investment_Transaction__c>();
        
    //     for(FinPlan__SMS_Message__c sms : messageList){

    //     }
    // }

    global static String deleteAllMessagesAndClearRecycleBin(){
        String response = FinPlanSMSHandler.deleteSMSAndClearRecycleBin();
        return response;
    }

    global static String deleteAllTransactionsAndClearRecycleBin(){
        String response = FinPlanSMSHandler.deleteAllTransactionsAndClearRecycleBin();
        return response;
    }
    
}