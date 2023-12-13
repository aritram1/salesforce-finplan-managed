@RestResource(urlMapping='/api/sms/sync/*')
global with sharing class FinPlanSyncSMSAPIController {
    
    global static List<FinPlan__SMS_Message__c> receivedMessages;
    global static FinPlan__SMS_Message__c lastBalanceUpdateSMS;
    global static List<FinPlan__SMS_Message__c> processedMessages;
    global static Map<String, String> apiResponse;
    global static String balanceUpdateResponse;
    global static String messageDeleteResponse;
    global static String transactionCreateResponse;
    // global static String bankTransactionResponse;
    // global static String investmentTransactionResponse;
    global static List<FinPlan__Bank_Transaction__c> bankTransactionsList;
    global static List<FinPlan__Investment_Transaction__c> investmentTransactionsList;
    
    // This method processes the post request and syncs the messages
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    @HttpPost
    global static Map<String, String> processPostRequests(List<Map<String, String>> records) {
        apiResponse = syncMessages(records);
        return apiResponse;
    }

    // This method does more than one actions
    // 1 - Deletes existing messages
    // 2 - Inserts the New Messages
    // 3 - Updates Balances
    // 4 - Creates Transaction records
    // 5 - Deletes existing messages again (if required, TBD)
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    global static Map<String, String> syncMessages(List<Map<String, String>> records) {
        try{
            messageDeleteResponse = deleteAllMessagesAndClearRecycleBin(); // null denotes no specific message but all existing messages need to be deleted
            processedMessages = insertMessages(records);
            balanceUpdateResponse = updateBankBalance(FinPlanSMSHandler.lastBalanceUpdateSMS);
            // transactionCreateResponse = createTransactions(processedMessages);
            // investmentTransactionResponse = createInvestmentTransactions(processedMessages);
            // messageDeleteResponse = deleteMessages(processedMessages);
            
            apiResponse.put('statusCode', '200');
            apiResponse.put('data', 'SUCCESS : ' + processedMessages.size() + ' messages are processed. ');
            apiResponse.put('data', apiResponse.get('data') + balanceUpdateResponse);
            apiResponse.put('data', apiResponse.get('data') + transactionCreateResponse);
            apiResponse.put('data', apiResponse.get('data') + messageDeleteResponse);
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

    global static String updateBankBalance(FinPlan__SMS_Message__c sms){
        String response = null;
        if(FinPlanSMSHandler.lastBalanceUpdateSMS != null){
            response = FinPlanSMSHandler.handleBankAccountBalanceUpdate(sms);
        }
        return response;
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

    global static String createTransactions(List<FinPlan__SMS_Message__c> messageList){
        bankTransactionsList = new List<FinPlan__Bank_Transaction__c>();
        investmentTransactionsList = new List<FinPlan__Investment_Transaction__c>();
        // List<FinPlan__Beneficiary__c> beneficiaries = new List<FinPlan__Beneficiary__c>();
        for(FinPlan__SMS_Message__c sms : messageList){
            if(sms.FinPlan__Beneficiary__c?.contains('Fund')){
                FinPlan__Investment_Transaction__c ivt = new FinPlan__Investment_Transaction__c();
                
            }
            else{
                FinPlan__Bank_Transaction__c tr = new FinPlan__Bank_Transaction__c();
                bankTransactionsList.add(tr);
            }
        }
        if(bankTransactionsList != null && bankTransactionsList.size() > 0){
            insert bankTransactionsList;
        }
        if(investmentTransactionsList != null && investmentTransactionsList.size() > 0){
            insert investmentTransactionsList;
        }
        return bankTransactionsList.size() + ' Bank Transactions and ' + investmentTransactionsList.size() + ' investment transactions are created';
    }

    // global static void createInvestmentTransactions(List<FinPlan__SMS_Message__c> messageList){
    //     bankTransactions = new List<FinPlan__Transaction__c>();
    //     investmentTransactions = new List<FinPlan__Investment_Transaction__c>();
        
    //     for(FinPlan__SMS_Message__c sms : messageList){

    //     }
    // }

    global static String deleteAllMessagesAndClearRecycleBin(){
        String response = FinPlanSMSHandler.deleteSMSAndEmptyRecycleBin();
        return response;
    }
    
}