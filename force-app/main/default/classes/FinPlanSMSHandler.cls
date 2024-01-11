public with sharing class FinPlanSMSHandler {

    static final String TAG = 'FinPlanSMSHandler';

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
        try{
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
                        FinPlanSMSHandlerBank.processForHDFCBank(sms, allBankAccountsMap);
                    }
                    // SBI
                    else if(sms.Sender__c.contains('SBI')){
                        FinPlanSMSHandlerBank.processForSBIBank(sms, allBankAccountsMap);
                    }
                    // ICICI
                    else if(sms.Sender__c.contains('ICICI')){
                        FinPlanSMSHandlerBank.processForICICIBank(sms, allBankAccountsMap);
                    }
                    // Investments
                    // To be completed 
                    // Urgent
                    // else if(){
                    // }
                }
                
                ////////////////////////////////////////////////////////////////////////////////////////
                // Few final checks to classify messages further
                ////////////////////////////////////////////////////////////////////////////////////////
                
                // Check if this sms is related to a financial transaction
                if(sms.amount_value__c != null){
                    sms.Create_Transaction__c = true;
                }

                // Check if this is useful for balance updating, then add it to static 
                // list `lastBalanceUpdateSMSList` for further use
                if(String.isNotBlank(sms.CC_Available_Balance__c) || String.isNotBlank(sms.SA_available_balance__c)){
                    sms.Balance_Update__c = true;
                    lastBalanceUpdateSMSList.add(sms);
                }

                // the type is still not assigned set type as promotional
                if(sms.type__c == null || sms.type__c == ''){
                    sms.type__c = 'promotional';
                }

                // Fix some specific beneficiary names to correct sms typos or better abbreviations
                switch on sms.beneficiary__c {
                    when 'Icici Bank Credit Card Account 4xxx9006' {
                        sms.beneficiary__c = 'ICICI Bank Credit Card Account 4xxx9006';
                    }
                    when 'Amazon Pay Indi' {
                        sms.beneficiary__c = 'Amazon Pay India';
                    }
                    when 'Sbi Atm Withdrawal' {
                        sms.beneficiary__c = 'SBI ATM withdrawal';
                    }
                    when 'Hdfc Atm Withdrawal' {
                        sms.beneficiary__c = 'HDFC ATM withdrawal';
                    }
                    when 'Cbdttax' {
                        sms.beneficiary__c = 'CBDTTAX';
                        sms.Related_To_Investment__c = true;
                        sms.Investment_Type__c = 'Advance Tax';
                    }
                    when else {
                        // Do nothing
                    }
                }
                
                if(sms.beneficiary__c != null && sms.beneficiary__c != '' && sms.beneficiary__c.contains('a/c linked to VPA')){
                    sms.beneficiary__c = sms.beneficiary__c.replace('a/c linked to VPA', '')?.trim();
                }

                processedMessages.add(sms);
            
            }
            System.debug('Processed messages=>' + processedMessages);
        }
        catch(Exception e){
            FinPlanLogger.logError(e, TAG);
        }
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
                    
                    if(ba != null && ba.Account_Code__c != null && ba.Account_Code__c != ''){
                        if(ba.Account_Code__c.endsWith('-SA')){ // Savings Account
                            System.debug('sms.SA_available_balance__c=>' + sms.SA_available_balance__c);
                            String availableSABalanceString = sms.SA_available_balance__c.replace(',', '');
                            availableSABalanceString = availableSABalanceString.endsWith('.') ? availableSABalanceString.substring(0, availableSABalanceString.length() - 1) : availableSABalanceString;
                            System.debug('Inside handleBankAccountBalanceUpdate for SA =>' + availableSABalanceString);                      
                            ba.FinPlan__Last_Balance__c = Double.valueOf(availableSABalanceString);
                        }
                        else if(ba.Account_Code__c.endsWith('-CC')){   // Current Account
                            String availableCCBalanceString = sms.FinPlan__CC_Available_Balance__c.replace(',', '');
                            System.debug('Inside handleBankAccountBalanceUpdate for CC =>' + availableCCBalanceString);                      
                            ba.FinPlan__CC_Available_Limit__c = Double.valueOf(availableCCBalanceString);
                        }
                        toBeUpdatedBankAccounts.add(ba);
                        
                        // Also captur  e the updated balance and bank account name for further showing response
                        String resultText = 'Bank Account Name : ' + ba.Name + ' Updated Balance : ' + sms.SA_available_balance__c + '. ';
                        balanceUpdateResponse = balanceUpdateResponse + resultText;
                    }
                }
            }
            if(toBeUpdatedBankAccounts.size() > 0){
                System.debug('toBeUpdatedBankAccounts inside FinPlanSMSHandler.handleBankAccountBalanceUpdate =>' + toBeUpdatedBankAccounts);
                update toBeUpdatedBankAccounts;
            }
        }
        catch(Exception ex){
            FinPlanLogger.logError(ex, TAG);
            balanceUpdateResponse = 'Error occurred inside handleBankAccountBalanceUpdate : ' + ex.getMessage();
        }
        return balanceUpdateResponse;
    }
    // End method

}