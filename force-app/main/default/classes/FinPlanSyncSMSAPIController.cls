@RestResource(urlMapping='/api/sms/sync/*')
global with sharing class FinPlanSyncSMSAPIController {
    
    global static List<FinPlan__SMS_Message__c> receivedMessages;
    global static List<FinPlan__SMS_Message__c> processedMessages;
    global static List<FinPlan__SMS_Message__c> balanceUpdateSMSList;
    global static Map<String, String> apiResponse;
    global static String balanceUpdateResponse;
    global static String messageDeleteResponse;
    global static String afterTransactionsCreatedMessageDeleteResponse;
    
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
    // 1 - Deletes existing messages
    // 2 - Inserts the New Messages
    // 3 - Updates Balances
    // 4 - Creates Bank/Investment Transaction records, as applicable, from messages
    // 5 - After transactions are created, delete messages [to save sf storage ;)]
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    global static Map<String, String> syncMessages(List<Map<String, String>> records) {
        balanceUpdateSMSList = new List<FinPlan__SMS_Message__c>();
        try{
            
            apiResponse.put('data', ''); // Create success response - can be optimized to return better json. TBD
            
            // Step 1 : Deletes existing messages
            messageDeleteResponse = deleteAllMessagesAndClearRecycleBin();
            apiResponse.put('data', apiResponse.get('data') + '|| messageDeleteResponse=>' + messageDeleteResponse);

            // Step 2 : Inserts the New Messages
            processedMessages = insertMessages(records);
            String insertMessagesResponse = 'SUCCESS : ' + processedMessages.size() + ' messages are processed. ';
            apiResponse.put('data', apiResponse.get('data') + '|| insertMessagesResponse=>' + insertMessagesResponse);

            // Step 3 : Updates Balances
            balanceUpdateResponse = handleUpdateAccountBalance(balanceUpdateSMSList);
            apiResponse.put('data', apiResponse.get('data') + '|| balanceUpdateResponse=>' + balanceUpdateResponse);

            // Step 4 : Creates Bank/Investment Transaction records, as applicable, from messages

            transactionCreateResponse = String.valueOf(FinPlanTransactionHandler.createTransactions(processedMessages));
            apiResponse.put('data', apiResponse.get('data') + '|| transactionCreateResponse=>' + transactionCreateResponse);

            // Step 5 : After transactions are created, delete messages [to save sf storage ;)]
            // (this can be conditionally commented pout for debugging/testing)
            afterTransactionsCreatedMessageDeleteResponse = deleteAllMessagesAndClearRecycleBin(); 
            apiResponse.put('data', apiResponse.get('data') + '|| afterTransactionsCreatedMessageDeleteResponse=>' + afterTransactionsCreatedMessageDeleteResponse);

            // Set the status code
            apiResponse.put('statusCode', '200');
            
        }
        catch(Exception ex){
            // Set status code and error
            apiResponse.put('statusCode', '400');
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
        balanceUpdateSMSList = FinPlanSMSHandler.lastBalanceUpdateSMSList;
        insert processedMessages;
        return processedMessages;
    }

    // global static void createInvestmentTransactions(List<FinPlan__SMS_Message__c> messageList){
    //     bankTransactions = new List<FinPlan__Transaction__c>();
    //     investmentTransactions = new List<FinPlan__Investment_Transaction__c>();
        
    //     for(FinPlan__SMS_Message__c sms : messageList){

    //     }
    // }

    public static String handleUpdateAccountBalance(List<FinPlan__SMS_Message__c> msgList){
        String response = '';
        response = FinPlanSMSHandler.handleBankAccountBalanceUpdate(msgList);
        return response;
    }

    global static String deleteAllMessagesAndClearRecycleBin(){
        String response = String.valueOf(FinPlanSMSHandler.deleteSMSAndClearRecycleBin());
        return response;
    }

}