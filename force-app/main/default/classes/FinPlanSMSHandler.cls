public with sharing class FinPlanSMSHandler {

    public static List<FinPlan__SMS_Message__c> processedMessages;
    public static List<FinPlan__SMS_Message__c> lastBalanceUpdateList;
    public static Map<String, Bank_Account__c> allBankAccountsMap = new Map<String, Bank_Account__c>();
    public static Map<String, Bank_Account__c> lastBalanceBankAccountsMap = new Map<String, Bank_Account__c>();

    // Standard lists to do further actions
    public static List<FinPlan__SMS_Message__c> listToCreateBankAccountTransacations = new List<FinPlan__SMS_Message__c>();
    public static List<FinPlan__SMS_Message__c> listToCreateInvestmentTransacations = new List<FinPlan__SMS_Message__c>();
    public static List<FinPlan__SMS_Message__c> listOfRejectedRecords = new List<FinPlan__SMS_Message__c>();
    public static List<FinPlan__SMS_Message__c> listOfAllowedRecords = new List<FinPlan__SMS_Message__c>();
    
    // Get all Bank accounts, make a map of code vs Id to set Bank account info later
    public static void getAllBankAccounts(){
        for(Bank_Account__c ba : [SELECT Id, Finplan__Account_Code__c, FinPlan__Last_Balance__c, FinPlan__CC_Available_Limit__c, FinPlan__CC_Max_Limit__c, Name from Bank_Account__c]){
            allBankAccountsMap.put(ba.Finplan__Account_Code__c, ba);
            lastBalanceBankAccountsMap.put(ba.id, ba);
        }
    }

    // Method to enrich message data
    public static List<FinPlan__SMS_Message__c> enrichData(List<FinPlan__SMS_Message__c> allMessages){
        
        // initiate variables
        processedMessages = new List<FinPlan__SMS_Message__c>();
        lastBalanceUpdateList = new List<FinPlan__SMS_Message__c>();
        getAllBankAccounts();

        // The main loop starts
        for(FinPlan__SMS_Message__c sms : allMessages){
            
            // set the date;
            String rawDateString = sms.FinPlan__Received_At__c?.split(' ')[0];
            if(rawDateString?.contains('-')){
                Integer yyyy = Integer.valueOf(rawDateString.split('-')[0]);
                Integer mm = Integer.valueOf(rawDateString.split('-')[1]);
                Integer dd = Integer.valueOf(rawDateString.split('-')[2]);
                sms.FinPlan__Transaction_Date__c = Date.newInstance(yyyy, mm, dd);
            }
            else{ 
                //TBD optimization 
                // this will be affected once the flag (to determine whether its bulk 
                // sync or single sms insert), is implemented
                sms.FinPlan__Transaction_Date__c = Date.valueOf(DateTime.newInstance(Long.valueOf(rawDateString))); // String->Long->DateTime->Date
            }
                
            // get the splitted content
            List<String> contentArray = new List<String>();
            contentArray = sms.content__c?.split(' ');
    
            
            // set personal type
            ////////////////////////////////////////////////////////////////////////////////////////
            if(sms.sender__c.startsWith('+')){
                sms.type__c = 'personal';
            }
            
            // set OTP type
            ////////////////////////////////////////////////////////////////////////////////////////
            else if (sms.content__c?.contains('OTP') || sms.sender__c?.contains('OTP') || sms.content__c?.contains('Verification') || sms.content__c?.contains('verification')){
                sms.Type__c = 'otp';
            }
    
            // set credit, debit and balance_update types
            ////////////////////////////////////////////////////////////////////////////////////////
            else{ 
                // HDFC
                if(sms.Sender__c.contains('HDFC')){
                    processForHDFCBank(sms);
                }
                // SBI
                else if(sms.Sender__c.contains('SBI')){
                    processForSBIBank(sms);
                }
                // ICICI
                else if(sms.Sender__c.contains('ICICI')){
                    processForICICIBank(sms);
                }
            }
    
            // the rest ones are promotional messages, set promotional type if type is not set yet
            ////////////////////////////////////////////////////////////////////////////////////////
            if(sms.type__c == null || sms.type__c == ''){
                sms.type__c = 'promotional';
            }
    
            // A final check to see if this sms is related to a financial transaction
            ////////////////////////////////////////////////////////////////////////////////////////
            if(sms.amount_value__c != null){
                sms.Create_Transaction__c = true;
            }

            // Only add to processed list if the message is about credit or debit
            if(sms.Type__c == 'credit' ||  sms.Type__c == 'debit'){
                processedMessages.add(sms);
            }
        }
        System.debug('Processed messages=>' + processedMessages);
        return processedMessages;
    }

    // This method updates the balance for savings account or credit card account from the last balanace update sms
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static String handleBankAccountBalanceUpdate(List<FinPlan__SMS_Message__c> smsList){
        System.debug('SMS List inside handleBankAccountBalanceUpdate =>' + smsList);
        System.debug('SMS List inside handleBankAccountBalanceUpdate =>' + smsList.size());
        String balanceUpdateResponse = '';
        List<Bank_Account__c> toBeUpdatedBankAccounts = new List<Bank_Account__c>();
        try{
            for(FinPlan__SMS_Message__c sms : smsList){
                if(sms.savings_or_cc_account__c != null){
                    Bank_Account__c ba = lastBalanceBankAccountsMap.get(sms.savings_or_cc_account__c);
                    String availableBalanceString = sms.SA_available_balance__c.replace(',', '');
                    System.debug('Inside handleBankAccountBalanceUpdate=>' + availableBalanceString);
                    if(ba != null && sms.SA_available_balance__c != null && sms.SA_available_balance__c != ''){
                        if(ba.Account_Code__c.endsWith('-SA')){ // Savings Account
                            ba.FinPlan__Last_Balance__c = Double.valueOf(availableBalanceString);
                        }
                        else if(ba.Account_Code__c.endsWith('-CC')){   // Current Account
                            ba.FinPlan__CC_Available_Limit__c = Double.valueOf(availableBalanceString);
                        }
                        toBeUpdatedBankAccounts.add(ba);
                        
                        // Also captur  e the updated balance and bank account name for further showing response
                        String resultText = 'Bank Account Name : ' + ba.Name + ' Updated Balance : ' + sms.SA_available_balance__c + '. ';
                        balanceUpdateResponse = balanceUpdateResponse + resultText;
                    }
                }
            }
            if(toBeUpdatedBankAccounts.size() > 0){
                System.debug('toBeUpdatedBankAccounts inside handleBankAccountBalanceUpdate =>' + toBeUpdatedBankAccounts);
                update toBeUpdatedBankAccounts;
            }
        }
        catch(Exception ex){
            balanceUpdateResponse = 'Error occurred inside handleBankAccountBalanceUpdate : ' + ex.getMessage();
        }
        return balanceUpdateResponse;
    }
    // End method

    // This method enriches the sms record if it's from HDFC
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static FinPlan__SMS_Message__c processForHDFCBank(FinPlan__SMS_Message__c sms){
        List<String> contentArray = new List<String>();
        contentArray = sms.content__c?.split(' ');
        if(sms.Sender__c.contains('HDFC')){
            sms.savings_or_cc_account__c = allBankAccountsMap.get('HDFC-SA').Id;
            // credit
            if(sms.content__c.contains('deposited')){
                sms.amount_value__c = contentArray[2];
                sms.type__c = 'credit';
                sms.SA_available_balance__c = sms.content__c.split('.Avl bal INR ')[1].split('. Cheque deposits')[0];
                if(sms.content__c.contains('UPI')){
                    sms.Payment_Via__c = 'UPI';
                    String str = sms.content__c.split('for')[1].split('.Avl bal')[0];
                    sms.Beneficiary__c = str.split('-')[1] + '-' + str.split('-')[2] + '-' + str.split('-')[3];
                    sms.Payment_Reference__c = str.split('-')[4];
                }
                else{
                    sms.Beneficiary__c = sms.content__c.split('for')[1].split('.Avl bal')[0];
                }
                
            }
            // credit
            else if(sms.content__c.startsWith('Money Received')){
                sms.amount_value__c = contentArray[4];
                sms.SA_available_balance__c = sms.content__c.split('Avl bal: INR')[1];
                sms.type__c = 'credit';
                String str = sms.content__c.split('Avl bal: INR')[0].split('by')[1].replace('(', '').replace(')', '');
                
                sms.Beneficiary__c = str.split('IMPS Ref No. ')[0];
                
                if(sms.content__c.contains('IMPS')){
                    sms.Payment_Via__c = 'IMPS';
                    sms.Payment_Reference__c = str.split('IMPS Ref No. ')[1];
                }
                
                
            }
            // debit bank transfer
            else if(sms.content__c.contains('debited from a/c **9560') && sms.content__c.contains('UPI')){
                sms.amount_value__c = contentArray[3];
                // sms.SA_available_balance__c = CONST_NA;
                sms.type__c = 'debit';
                sms.Payment_Via__c = 'UPI';
                String content = sms.content__c.replace('(', '').replace(')', '');
                sms.Beneficiary__c = content.split('to ')[1].split('. Not you?')[0].split('UPI Ref No ')[0];
                sms.Payment_Reference__c = content.split('(')[1].split(')')[0].replace('UPI Ref No.', '').trim();
            }
            // debit UPI
            else if(sms.content__c.startswith('Money Transfer:Rs') && sms.content__c.contains('UPI')){
                sms.amount_value__c = contentArray[2];
                sms.type__c = 'debit';
                sms.Payment_Via__c = 'UPI';
                sms.Payment_Reference__c = sms.content__c.split('UPI:')[1].split('Not you?')[0];
                sms.Beneficiary__c = sms.content__c.split('UPI')[0].split('to')[1];
            }
            // balance update
            else if(sms.content__c.startsWith('Available Bal in HDFC Bank A/c XX9560 as on')){
                sms.SA_available_balance__c = contentArray[12].substring(0, contentArray[12].length()-1);
                sms.SA_available_balance__c =  sms.SA_available_balance__c.replace('.Cheque', ''); // further check added
                sms.type__c = 'balance_update';
                lastBalanceUpdateList.add(sms); // Also add it to static list so it can be used to update balance update at the bank account later
            }
            else if(sms.content__c.startsWith('Available Bal in HDFC Bank A/c XX9560 on')){
                sms.SA_available_balance__c = contentArray[10].substring(0, contentArray[10].length()-1);
                sms.SA_available_balance__c =  sms.SA_available_balance__c.replace('.Cheque', ''); // further check added
                sms.type__c = 'balance_update';
                lastBalanceUpdateList.add(sms); // Also add it to static list so it can be used to update balance update at the bank account later
            }
        }
        return sms;
    }
    // End method

    // This method enriches the sms record if it's from SBI
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static FinPlan__SMS_Message__c processForSBIBank(FinPlan__SMS_Message__c sms){
        List<String> contentArray = new List<String>();
        contentArray = sms.content__c?.split(' ');
        sms.savings_or_cc_account__c = allBankAccountsMap.get('SBI-SA').Id;
        // balance update
        if(sms.content__c.contains('is debited for')){
            sms.amount_value__c = contentArray[10];
            sms.beneficiary__c = sms.content__c.split('and')[1].split('credited')[0];
            sms.type__c = 'balance_update';
            lastBalanceUpdateList.add(sms); // Also add it to static list so it can be used to update balance update at the bank account later
        }
        // atm withdrawal
        if(sms.content__c.contains('withdrawn at SBI ATM')){
            sms.amount_value__c = contentArray[3].replace('Rs.', '');
            sms.beneficiary__c = 'self';
            sms.SA_available_balance__c = contentArray[18].replace('Rs.', '');
            sms.Payment_Reference__c = contentArray[15];
            sms.Payment_Reference__c = contentArray[15];
            sms.Payment_Via__c = 'ATM';
            lastBalanceUpdateList.add(sms); // Also add it to static list so it can be used to update balance update at the bank account later
        }
        return sms;
    }
    // End method

    // This method enriches the sms record if it's from ICICI
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static FinPlan__SMS_Message__c processForICICIBank(FinPlan__SMS_Message__c sms){
        List<String> contentArray = new List<String>();
        contentArray = sms.content__c?.split(' ');
        // Credit card blocks
        if(sms.content__c.contains('spent on ICICI Credit Card XX9006')){
            sms.savings_or_cc_account__c = allBankAccountsMap.get('ICICI-CC').Id;
            sms.type__c = 'debit';
            sms.beneficiary__c = sms.content__c.split('at')[1].split('Avl Lmt')[0];
            sms.amount_value__c = contentArray[1];
            sms.CC_Available_Balance__c = sms.content__c.split('Avl Lmt: INR')[1].split('To dispute')[0];
            lastBalanceUpdateList.add(sms); // Also add it to static list so it can be used to update balance update at the bank account later
        }
        else if(sms.content__c.contains('received on your ICICI Bank Credit Card Account 4xxx9006')){
            sms.savings_or_cc_account__c = allBankAccountsMap.get('ICICI-CC').Id;
            sms.type__c = 'credit';
            sms.amount_value__c = contentArray[5];
            sms.beneficiary__c = 'ICICI Bank Credit Card Account 4xxx9006';
        }
        // Savings account block
        else if(sms.content__c.startsWith('ICICI Bank Acct XX360 debited with')){
            sms.savings_or_cc_account__c = allBankAccountsMap.get('ICICI-SA').Id;
            sms.type__c = 'debit';
            sms.amount_value__c = contentArray[7];
            if(sms.content__c.contains('UPI')){
                sms.Payment_Via__c = 'UPI';
            }
            if(sms.content__c.contains('IMPS')){
                sms.Payment_Via__c = 'IMPS';
                sms.Payment_Reference__c = sms.content__c.split('IMPS:')[1].split('. Call ')[0];
                sms.beneficiary__c = sms.content__c.split('credited.')[0].split('&')[1];
            }
            if(sms.content__c.contains('RTGS')){
                sms.Payment_Via__c = 'RTGS';
            }
        }
        return sms;
    }
    // End method

    // This method updates the balance for savings account or credit card account from the last balanace update sms
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static String deleteSMSAndClearRecycleBin() {
        try {
            List<SMS_Message__c> messagesToDelete = [SELECT Id FROM SMS_Message__c];
            if(messagesToDelete != null && messagesToDelete.size() > 0){
                Database.DeleteResult[] deleteResults = Database.delete(messagesToDelete, false);
                Database.emptyRecycleBin(messagesToDelete);
                return 'SUCCESS : ' + messagesToDelete.size() + ' message records deleted successfully. ';
            }
            else{
                return 'SUCCESS : No messages available to delete. ';
            }
        } catch (Exception e) {
            return 'Failed : Error deleting messages: ' + e.getMessage();
        }
    }

    // This method updates the balance for savings account or credit card account from the last balanace update sms
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static String deleteAllTransactionsAndClearRecycleBin() {
        String response = '';
        try {
            List<FinPlan__Bank_Transaction__c> bankTxntoDelete = [SELECT Id FROM FinPlan__Bank_Transaction__c];
            List<FinPlan__Investment_Transaction__c> invTxntoDelete = [SELECT Id FROM FinPlan__Investment_Transaction__c];
            if(bankTxntoDelete != null && bankTxntoDelete.size() > 0){
                Database.DeleteResult[] deleteResults = Database.delete(bankTxntoDelete, false);
                Database.emptyRecycleBin(bankTxntoDelete);
                response = 'SUCCESS : ' + bankTxntoDelete.size() + ' bank transaction records deleted successfully. ';
            }
            else{
                response = 'SUCCESS : No bank transactions are available to delete. ';
            }
            if(invTxntoDelete != null && invTxntoDelete.size() > 0){
                Database.DeleteResult[] deleteResults = Database.delete(invTxntoDelete, false);
                Database.emptyRecycleBin(invTxntoDelete);
                response = 'SUCCESS : ' + invTxntoDelete.size() + ' investment records deleted successfully. ';
            }
            else{
                response = 'SUCCESS : No investment transactions available to delete. ';
            }
        } catch (Exception e) {
            response = 'Failed : Error deleting transactions : ' + e.getMessage();
        }
        return response;
    }
}