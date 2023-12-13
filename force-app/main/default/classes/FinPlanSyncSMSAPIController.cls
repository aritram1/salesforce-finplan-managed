@RestResource(urlMapping='/api/sms/sync/*')
global with sharing class FinPlanSyncSMSAPIController {
    
    global static List<FinPlan__SMS_Message__c> receivedMessages;
    global static FinPlan__SMS_Message__c lastBalanceUpdateSMS;
    global static List<FinPlan__SMS_Message__c> processedMessages;
    global static Map<String, String> apiResponse;
    global static String balanceUpdateResponse;
    global static String messageDeleteResponse;
    global static String afterTransactionsCreatedMessageDeleteResponse;
    global static String transactionDeleteResponse;
    
    global static String transactionCreateResponse;
    // global static String bankTransactionResponse;
    // global static String investmentTransactionResponse;
    global static List<FinPlan__Bank_Transaction__c> bankTransactionsList;
    global static List<FinPlan__Investment_Transaction__c> investmentTransactionsList;
    
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
            balanceUpdateResponse = updateBankBalance(FinPlanSMSHandler.lastBalanceUpdateSMS);
            transactionCreateResponse = createTransactions(processedMessages);
            // investmentTransactionResponse = createInvestmentTransactions(processedMessages);
            afterTransactionsCreatedMessageDeleteResponse = deleteAllMessagesAndClearRecycleBin();
            
            apiResponse.put('statusCode', '200');
            apiResponse.put('data', '');
            apiResponse.put('data', apiResponse.get('data') + messageDeleteResponse);
            apiResponse.put('data', apiResponse.get('data') + transactionDeleteResponse);
            apiResponse.put('data', apiResponse.get('data') + insertMessagesResponse);
            apiResponse.put('data', apiResponse.get('data') + balanceUpdateResponse);
            apiResponse.put('data', apiResponse.get('data') + transactionCreateResponse);
            apiResponse.put('data', apiResponse.get('data') + afterTransactionsCreatedMessageDeleteResponse);

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
                ivt.FinPlan__Amount__c = Double.valueOf(sms.amount_value__c.replace(',', ''));
                // To be implemented
            }
            else{
                FinPlan__Bank_Transaction__c tr = new FinPlan__Bank_Transaction__c();
                tr.FinPlan__Approved__c = sms.Approved__c;
                tr.FinPlan__Created_From__c = 'SMS';
                tr.FinPlan__Beneficiary_Name__c = sms.Beneficiary__c;
                tr.FinPlan__From_Account__c = sms.savings_or_cc_account__c;
                tr.FinPlan__Transaction_Date__c = sms.FinPlan__Transaction_Date__c;
                tr.Type__c = sms.Type__c == 'credit' ? 'Credit' : 'Debit';
                tr.FinPlan__Amount__c = Double.valueOf(sms.amount_value__c.replace(',', ''));
                bankTransactionsList.add(tr);
            }
        }
        if(bankTransactionsList != null && bankTransactionsList.size() > 0){
            insert bankTransactionsList;
        }
        if(investmentTransactionsList != null && investmentTransactionsList.size() > 0){
            insert investmentTransactionsList;
        }
        return bankTransactionsList.size() + ' Bank Transactions and ' + investmentTransactionsList.size() + ' investment transactions are created. ';
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