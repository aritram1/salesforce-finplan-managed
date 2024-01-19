public with sharing class FinPlanSMSHandler {

    static final String TAG = 'FinPlanSMSHandler';

    static final Set<String> BANK_SMS_SENDERS = new Set<String>{'HDFC', 'ICICI', 'SBI'};
    static final Set<String> INVESTMENT_SMS_SENDERS = new Set<String>{'NPS', 'PPF', 'EPF'};
    static final String PPF_4DIGITS = '3962';

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
            try{
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

                // Personal
                if(sms.sender__c.startsWith('+')){  // set personal type
                    sms.type__c = 'personal';   
                }                
                // OTP
                else if (sms.content__c?.toUpperCase().contains('OTP') || sms.content__c?.toUpperCase().contains('VERIFICATION CODE')){
                    sms.Type__c = 'otp';
                }
                // Credit / Debit / Balance Update
                else{ 
                    // Bank Types
                    if(sms.Sender__c.contains('HDFC') || sms.Sender__c.contains('ICICI') || sms.Sender__c.contains('SBI')){ // TBC Urgent Implementation  BANK_SMS_SENDERS.contains(sms.Sender__c)){
                        if(sms.Sender__c.contains('SBI') && sms.content__c.contains(PPF_4DIGITS)){ // PPF
                            sms.Investment_Type__c = 'PPF';
                            sms.Related_To_Investment__c = true;
                            FinPlanSMSHandlerInvestment.processForInvestments(sms, allBankAccountsMap);
                        }
                        else{
                            FinPlanSMSHandlerBank.processForBanks(sms, allBankAccountsMap);
                        }
                    }
                    // Investment Types
                    else if(sms.Sender__c.contains('EPF') || sms.Sender__c.contains('NPS')) { // TBC Urgent Implementation INVESTMENT_SMS_SENDERS.contains(sms.Sender__c)){
                        FinPlanSMSHandlerInvestment.processForInvestments(sms, allBankAccountsMap);
                    }
                }
                
                ////////////////////////////////////////////////////////////////////////////////////////
                // Few final checks to classify messages further
                ////////////////////////////////////////////////////////////////////////////////////////
                
                // Check if this sms is related to a financial transaction
                if(sms.amount_value__c != null){
                    sms.Create_Transaction__c = true;
                }

                // Identify if this helps to update balance, set flags accordingly
                if(String.isNotBlank(sms.CC_Available_Balance__c) || String.isNotBlank(sms.SA_available_balance__c)){
                    sms.Balance_Update__c = true;
                    lastBalanceUpdateSMSList.add(sms);
                }

                // If the type is still not assigned set type as promotional
                if(String.isBlank(sms.type__c)){
                    sms.type__c = 'promotional';
                }

                // Fix some specific beneficiary names to correct sms typos / provide better abbreviations
                sms = fixBeneficiaryName(sms);
            }
            catch(Exception e){
                // Get the detail error Info and Log the error
                String errorMessage = FinPlanLogger.getDetailedErrorMessage(e);
                FinPlanLogger.logError(new FinPlanException(errorMessage), TAG, sms.content__c);
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
        catch(Exception e){
            // Get the detail error Info and Log the error
            String errorMessage = FinPlanLogger.getDetailedErrorMessage(e);
            FinPlanLogger.logError(new FinPlanException(errorMessage), TAG);
            balanceUpdateResponse = 'Error occurred inside handleBankAccountBalanceUpdate : ' + errorMessage;
        }
        return balanceUpdateResponse;
    }
    // End method

    // This method fixes if there is any typo in beneficiary name or some abbreviations are missed
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static FinPlan__SMS_Message__c fixBeneficiaryName(FinPlan__SMS_Message__c sms){

        if(sms.beneficiary__c != null && sms.beneficiary__c != ''){

            // some abbreviations are corrected in case present in beneficiary names
            if(sms.beneficiary__c == 'Icici Bank Credit Card Account 4xxx9006'){
                sms.beneficiary__c = 'ICICI Bank Credit Card Account 4xxx9006';
            }
            if(sms.beneficiary__c.toUpperCase() == 'CONCEN'){
                sms.beneficiary__c = 'Concentrix Catalyst';
            }
            else if(sms.beneficiary__c.toUpperCase() == 'AMAZON PAY INDI'){
                sms.beneficiary__c = 'Amazon Pay India';
            }
            else if(sms.beneficiary__c.toUpperCase() == 'FLIPKART INTERN'){
                sms.beneficiary__c = 'Flipkart';
            }
            else if(sms.beneficiary__c.toUpperCase() == 'SBI ATM WITHDRAWAL'){
                sms.beneficiary__c = 'SBI ATM withdrawal';
            }
            else if(sms.beneficiary__c.toUpperCase() == 'HDFC ATM WITHDRAWAL'){
                sms.beneficiary__c = 'HDFC ATM withdrawal';
            }
            else if(sms.beneficiary__c.toUpperCase().contains('NFS*')){ // NFS means National Financial Switch (NFS), A Leading ATM Network
                sms.beneficiary__c = 'ICICI ATM Withdrawal';
            }
            else if(sms.beneficiary__c.toUpperCase().contains('INFOBIL')){
                sms.beneficiary__c = 'ICICI CC Bill';
            }
            else if(sms.beneficiary__c.toUpperCase() == 'SBIMOPS'){
                sms.beneficiary__c = 'Kolkata Metro Recharge';
            }
            else if(sms.beneficiary__c.toUpperCase() == 'A/C xxxxxxx6414'){
                sms.beneficiary__c = 'Dr. Sanyal';
            }

            // Investment related beneficiary names
            else if(sms.beneficiary__c.toUpperCase().contains('CBDT')){
                sms.Related_To_Investment__c = true;
                sms.beneficiary__c = 'CBDTTAX';
                sms.Investment_Type__c = 'Advance Tax';
            }
            else if(sms.beneficiary__c.toUpperCase().startsWith('INDIANCLEARINGCORP')){
                sms.Related_To_Investment__c = true;
                sms.beneficiary__c = 'NPS';
                sms.Investment_Type__c = 'NPS';
            }

            // Clean up VPA and A/c related beneficiary names
            else if(sms.beneficiary__c.contains('a/c linked to VPA')){
                sms.beneficiary__c = sms.beneficiary__c.replace('a/c linked to VPA', '')?.trim();
            }
            else if(sms.beneficiary__c.toUpperCase().startsWith('VPA')){
                sms.beneficiary__c = sms.beneficiary__c.replace('Vpa ', '').replace('VPA ', '')?.trim();
            }
            else if(sms.beneficiary__c.contains('A/c Linked to mobile No')){
                sms.beneficiary__c = sms.beneficiary__c.replace('A/c Linked to mobile No', 'UPI @')?.trim();
            }
        }

        return sms;

    }


}