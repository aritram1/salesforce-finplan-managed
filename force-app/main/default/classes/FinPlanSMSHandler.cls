public with sharing class FinPlanSMSHandler {

    public static List<FinPlan__SMS_Message__c> processedMessages;
    public static List<FinPlan__SMS_Message__c> lastBalanceUpdateSMSList;
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
        lastBalanceUpdateSMSList = new List<FinPlan__SMS_Message__c>();
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
                // Convert String -> Long -> DateTime -> Date
                sms.FinPlan__Transaction_Date__c = Date.valueOf(DateTime.newInstance(Long.valueOf(rawDateString))); 
            }

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
    
            // set credit and debit types
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
            
            ////////////////////////////////////////////////////////////////////////////////////////
            // Few final checks to classify messages further
            ////////////////////////////////////////////////////////////////////////////////////////
            
            // Check if this sms is related to a financial transaction
            if(sms.amount_value__c != null){
                sms.Create_Transaction__c = true;
            }

            // Check if this is useful for balance updating, then add it to static list `lastBalanceUpdateSMSList`
            if(String.isNotBlank(sms.CC_Available_Balance__c) || String.isNotBlank(sms.SA_available_balance__c)){
                sms.Balance_Update__c = true;
                lastBalanceUpdateSMSList.add(sms);
            }

            // the type is still not assigned set type as promotional
            if(sms.type__c == null || sms.type__c == ''){
                sms.type__c = 'promotional';
            }

            processedMessages.add(sms);
        
        }
        System.debug('Processed messages=>' + processedMessages);
        return processedMessages;
    }

    // This method updates the balance for savings account or credit card account from the last balanace update sms
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static String handleBankAccountBalanceUpdate(List<FinPlan__SMS_Message__c> inputSMSList){

        System.debug('inputSMSList value inside handleBankAccountBalanceUpdate =>' + inputSMSList);
        System.debug('inputSMSList value inside handleBankAccountBalanceUpdate size =>' + inputSMSList.size());
        
        // The input list can contain more than one sms and we need the latest ones for each bank account
        Map<String, FinPlan__SMS_Message__c> uniqueMap = new Map<String, FinPlan__SMS_Message__c>();
        for(FinPlan__SMS_Message__c message : inputSMSList){
            uniqueMap.put(message.savings_or_cc_account__c, message);
        }
        List<FinPlan__SMS_Message__c> uniqueSMSList = uniqueMap.values();

        System.debug('uniqueSMSList value inside handleBankAccountBalanceUpdate =>' + uniqueSMSList);
        System.debug('uniqueSMSList value inside handleBankAccountBalanceUpdate size =>' + uniqueSMSList.size());
        String balanceUpdateResponse = '';
        List<Bank_Account__c> toBeUpdatedBankAccounts = new List<Bank_Account__c>();
        try{
            for(FinPlan__SMS_Message__c sms : uniqueSMSList){
                if(sms.savings_or_cc_account__c != null){
                    Bank_Account__c ba = lastBalanceBankAccountsMap.get(sms.savings_or_cc_account__c);
                    System.debug('sms=>' + sms);
                    System.debug('sms.SA_available_balance__c=>' + sms.SA_available_balance__c);
                    String availableBalanceString = sms.SA_available_balance__c.replace(',', '');
                    availableBalanceString = availableBalanceString.endsWith('.') ? availableBalanceString.substring(0, availableBalanceString.length() - 1) : availableBalanceString;
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
                    sms.Beneficiary__c = toCamelCase(sms.Beneficiary__c); // convert to camel case for better readability
                    sms.Payment_Reference__c = str.split('-')[4];
                }
                else{
                    sms.Beneficiary__c = sms.content__c.split('for')[1].split('.Avl bal')[0];
                    sms.Beneficiary__c = toCamelCase(sms.Beneficiary__c); // convert to camel case for better readability
                }
                
            }
            // credit
            else if(sms.content__c.startsWith('Money Received')){
                sms.amount_value__c = contentArray[4];
                sms.SA_available_balance__c = sms.content__c.split('Avl bal: INR')[1];
                sms.type__c = 'credit';
                String str = sms.content__c.split('Avl bal: INR')[0].split('by')[1].replace('(', '').replace(')', '');
                
                sms.Beneficiary__c = str.split('IMPS Ref No. ')[0];
                sms.Beneficiary__c = toCamelCase(sms.Beneficiary__c); // convert to camel case for better readability
                
                if(sms.content__c.contains('IMPS')){
                    sms.Payment_Via__c = 'IMPS';
                    sms.Payment_Reference__c = str.split('IMPS Ref No. ')[1];
                }
                
                
            }
            // debit bank transfer
            else if(sms.content__c.contains('debited from a/c **9560') && sms.content__c.contains('UPI')){
                sms.amount_value__c = contentArray[3];
                sms.type__c = 'debit';
                sms.Payment_Via__c = 'UPI';
                String content = sms.content__c.replace('(', '').replace(')', '');
                sms.Beneficiary__c = content.split('to ')[1].split('. Not you?')[0].split('UPI Ref No ')[0];
                sms.Beneficiary__c = toCamelCase(sms.Beneficiary__c); // convert to camel case for better readability

                String paymentReferenceString = sms.content__c.replace('(', 'START_BRACKET').replace(')', 'END_BRACKET');
                sms.Payment_Reference__c = paymentReferenceString.split('START_BRACKET')[1].split('END_BRACKET')[0].replace('UPI Ref No.', '').trim();
            }
            // debit UPI
            else if(sms.content__c.startswith('Money Transfer:Rs') && sms.content__c.contains('UPI')){
                sms.amount_value__c = contentArray[2];
                sms.type__c = 'debit';
                sms.Payment_Via__c = 'UPI';
                sms.Payment_Reference__c = sms.content__c.split('UPI:')[1].split('Not you?')[0];
                sms.Beneficiary__c = sms.content__c.split('UPI')[0].split(' to ')[1];
                sms.Beneficiary__c = toCamelCase(sms.Beneficiary__c); // convert to camel case for better readability
            }
            // balance update
            else if(sms.content__c.startsWith('Available Bal in HDFC Bank A/c XX9560 as on')){
                sms.SA_available_balance__c = contentArray[12].substring(0, contentArray[12].length()-1);
                sms.SA_available_balance__c =  sms.SA_available_balance__c.replace('.Cheque', ''); // further check added
                // sms.type__c = 'balance_update';
                // lastBalanceUpdateSMSList.add(sms); // Also add it to static list so it can be used to update balance update at the bank account later
            }
            else if(sms.content__c.startsWith('Available Bal in HDFC Bank A/c XX9560 on')){
                sms.SA_available_balance__c = contentArray[10].substring(0, contentArray[10].length()-1);
                sms.SA_available_balance__c =  sms.SA_available_balance__c.replace('.Cheque', ''); // further check added
                // sms.type__c = 'balance_update';
                // lastBalanceUpdateSMSList.add(sms); // Also add it to static list so it can be used to update balance update at the bank account later
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
        // credit
        if(sms.content__c.contains('Your a/c no. XXXXXXXX6414 is credited by')){
            sms.amount_value__c = contentArray[9].replace('Rs.', '');
            String modifiedContent = sms.content__c.replace('(', 'START_BRACKET').replace(')', 'END_BRACKET');
            sms.beneficiary__c = modifiedContent.split('by')[2].split('START_BRACKET')[0];
            sms.Beneficiary__c = toCamelCase(sms.Beneficiary__c); // convert to camel case for better readability
            if(modifiedContent.contains('IMPS')){
                sms.Payment_Via__c = 'IMPS';
                sms.Payment_Reference__c = modifiedContent.split('START_BRACKET')[1].split('END_BRACKET')[0].replace('IMPS Ref no', '').trim();
            }
            sms.type__c = 'credit';
        }
        // debit
        if(sms.content__c.contains('Your a/c no. XXXXXXXX6414 is debited for')){
            sms.amount_value__c = contentArray[9].replace('Rs.', '');
            sms.beneficiary__c = sms.content__c.split('and')[1].split('credited')[0].trim();
            sms.Beneficiary__c = toCamelCase(sms.Beneficiary__c); // convert to camel case for better readability
            sms.type__c = 'debit';
        }
        // atm withdrawal
        if(sms.content__c.contains('withdrawn at SBI ATM')){
            sms.amount_value__c = contentArray[3].replace('Rs.', '');
            sms.beneficiary__c = 'Self - ATM';
            sms.Beneficiary__c = toCamelCase(sms.Beneficiary__c); // convert to camel case for better readability
            sms.SA_available_balance__c = contentArray[18].replace('Rs.', '');
            if(sms.SA_available_balance__c.endsWith('.')){
                sms.SA_available_balance__c = sms.SA_available_balance__c.substring(0, sms.SA_available_balance__c.length()-1);
            }
            sms.Payment_Reference__c = contentArray[15];
            if(sms.Payment_Reference__c.endsWith('.')){
                sms.Payment_Reference__c = sms.Payment_Reference__c.substring(0, sms.Payment_Reference__c.length()-1);
            }
            sms.Payment_Via__c = 'ATM';
            sms.type__c = 'debit';
            // lastBalanceUpdateSMSList.add(sms); // Also add it to static list so it can be used to update balance update at the bank account later
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
            sms.Beneficiary__c = toCamelCase(sms.Beneficiary__c); // convert to camel case for better readability
            sms.amount_value__c = contentArray[1];
            sms.CC_Available_Balance__c = sms.content__c.split('Avl Lmt: INR')[1].split('To dispute')[0];
            // lastBalanceUpdateSMSList.add(sms); // Also add it to static list so it can be used to update balance update at the bank account later
        }
        else if(sms.content__c.contains('received on your ICICI Bank Credit Card Account 4xxx9006')){
            sms.savings_or_cc_account__c = allBankAccountsMap.get('ICICI-CC').Id;
            sms.type__c = 'credit';
            sms.amount_value__c = contentArray[5];
            sms.beneficiary__c = 'ICICI Bank Credit Card Account 4xxx9006';
            sms.Beneficiary__c = toCamelCase(sms.Beneficiary__c); // convert to camel case for better readability
        }
        // Savings account block
        else if(sms.content__c.startsWith('ICICI Bank Account XX360 credited')){
            sms.savings_or_cc_account__c = allBankAccountsMap.get('ICICI-SA').Id;
            sms.type__c = 'credit';
            sms.amount_value__c = contentArray[5];
            if(sms.content__c.contains('UPI')){
                sms.Payment_Via__c = 'UPI';
            }
            else if(sms.content__c.contains('IMPS')){
                sms.Payment_Via__c = 'IMPS';
            }
            else if(sms.content__c.contains('NEFT')){
                sms.Payment_Via__c = 'NEFT';
                String beneficiaryAndReferenceString = sms.content__c.split('Info')[1].split('Available')[0].replace('.', '');
                sms.Payment_Reference__c = beneficiaryAndReferenceString.split('-')[1];
                sms.beneficiary__c = beneficiaryAndReferenceString.split('-')[2];
                sms.Beneficiary__c = toCamelCase(sms.Beneficiary__c); // convert to camel case for better readability

                if(sms.content__c.contains('Available Balance is Rs.')){
                    String availableBalanceString = sms.content__c.split('Available Balance is Rs.')[1];
                    sms.SA_available_balance__c = availableBalanceString.substring(0, availableBalanceString.length()-1).replace(',', '').trim();
                    // lastBalanceUpdateSMSList.add(sms);
                }
            }
        }
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
                sms.Beneficiary__c = toCamelCase(sms.Beneficiary__c); // convert to camel case for better readability
            }
            if(sms.content__c.contains('RTGS')){
                sms.Payment_Via__c = 'RTGS';
            }
        }
        return sms;
    }
    // End method

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Utility methods
    public static String toCamelCase(String inputString) {
        if(inputString == null){
            return inputString;
        }
        else{
            try{
                List<String> modifiedWords = new List<String>();

                inputString = inputString.trim();

                // Split the string into words
                List<String> words = inputString.trim().split(' ');
                
                for (String word : words) {
                    word = word.trim();
                    if(word.length() == 1){
                        modifiedWords.add(word.toUpperCase());
                    }
                    else if(word.length() > 1){
                        String firstAlphabet = word.substring(0, 1).toUpperCase();
                        String rest = word.substring(1, word.length()).toLowerCase();
                        modifiedWords.add(firstAlphabet + rest); 

                        // Logic to apply to ignor eany transformation for specific business names likes HDFC, ICICI etc
                        // if(word.substring(0, 1) == word.substring(0, 1).toUpperCase() && word.substring(1, 2) == word.substring(1, 2).toLowerCase()){
                        //     // if first two alphabets are already capital, no transformation is required.
                        //     // consider this as name of a Business, like HDFC, ICICI
                        //     modifiedWords.add(word);
                        // }
                    }
                }

                // Join the words back together
                return String.join(modifiedWords, ' '   );
            }
            catch(Exception e){
                throw new FinPlanException(e.getMessage());
            }
        }
    }
}