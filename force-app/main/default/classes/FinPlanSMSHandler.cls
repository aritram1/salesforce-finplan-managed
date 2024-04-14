public with sharing class FinPlanSMSHandler {

    static final String TAG = 'FinPlanSMSHandler';

    static final Set<String> BANK_SMS_SENDERS = new Set<String>{'HDFC', 'ICICI', 'SBI'};
    static final Set<String> INVESTMENT_SMS_SENDERS = new Set<String>{'NPS', 'PPF', 'EPF'};
    static final String PPF_4DIGITS = '3962';

    public static List<FinPlan__SMS_Message__c> processedMessages;
    public static List<FinPlan__SMS_Message__c> lastBalanceUpdateSMSList;
    public static Map<String, FinPlan__Bank_Account__c> allBankAccountsMap = new Map<String, FinPlan__Bank_Account__c>();
    public static Map<String, FinPlan__Beneficiary__c> allBeneficiariesMap = new Map<String, FinPlan__Beneficiary__c>();
    public static Map<String, FinPlan__Investment__c> allInvestmentsMap = new Map<String, FinPlan__Investment__c>();
    
    public static Map<String, FinPlan__Bank_Account__c> lastBalanceBankAccountsMap = new Map<String, FinPlan__Bank_Account__c>();

    // Standard lists to do further actions
    public static List<FinPlan__SMS_Message__c> listToCreateBankAccountTransacations = new List<FinPlan__SMS_Message__c>();
    public static List<FinPlan__SMS_Message__c> listToCreateInvestmentTransacations = new List<FinPlan__SMS_Message__c>();
    public static List<FinPlan__SMS_Message__c> listOfRejectedRecords = new List<FinPlan__SMS_Message__c>();
    public static List<FinPlan__SMS_Message__c> listOfAllowedRecords = new List<FinPlan__SMS_Message__c>();
    
    // Get all Bank accounts, make a map of code vs Id to set Bank account info later
    public static void getAllBankAccountsAndBeneficiaries(){
        for(Bank_Account__c ba : [SELECT Id, Finplan__Active__c, FinPlan__Account_Code__c, 
                                         FinPlan__Last_Balance__c, FinPlan__CC_Available_Limit__c, 
                                         FinPlan__CC_Max_Limit__c, Name FROM Bank_Account__c]){
            allBankAccountsMap.put(ba.Finplan__Account_Code__c, ba);
            lastBalanceBankAccountsMap.put(ba.id, ba);
        }

        // Get list of investments
        for(Investment__c inv : [SELECT Id, Name FROM Investment__c]){
            allInvestmentsMap.put(inv.Id, inv);
        }        

        // Get list of beneficiaries
        for(FinPlan__Beneficiary__c be : [SELECT Id, Name, FinPlan__Other_Names__c ,
                                                 FinPlan__Phone__c, FinPlan__Type__c, FinPlan__UPI_Id__c,
                                                 FinPlan__External_Id__c
                                                 FROM FinPlan__Beneficiary__c]){
            allBeneficiariesMap.put(be.FinPlan__External_Id__c, be);
        }
    }

    // Method to enrich message data
    public static List<FinPlan__SMS_Message__c> enrichData(List<FinPlan__SMS_Message__c> allMessages){
        // initiate variables
        processedMessages = new List<FinPlan__SMS_Message__c>();
        lastBalanceUpdateSMSList = new List<FinPlan__SMS_Message__c>();
        getAllBankAccountsAndBeneficiaries();

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

                    // Case 1 : HDFC  SA
                    if(sms.Sender__c.contains('HDFC')){ // TBC Urgent Implementation  BANK_SMS_SENDERS.contains(sms.Sender__c)){
                        sms = FinPlanSMSHandlerBank.processForBanks(sms, allBankAccountsMap, 'HDFC-SA');
                    }
                    // Case 2 : ICICI SA
                    else if(sms.Sender__c.contains('ICICI')){
                        sms = FinPlanSMSHandlerBank.processForBanks(sms, allBankAccountsMap, 'ICICI-SA');
                    }
                    // Case 3 : SBI SA
                    else if(sms.Sender__c.contains('SBI') && !sms.content__c.contains(PPF_4DIGITS)){
                        sms = FinPlanSMSHandlerBank.processForBanks(sms, allBankAccountsMap, 'SBI-SA');
                    }
                    // Case 4 : SBI PPF
                    else if(sms.Sender__c.contains('SBI') && sms.content__c.contains(PPF_4DIGITS)){
                        // sms.Investment_Type__c = 'PPF';
                        // sms.Related_To_Investment__c = true;
                        sms = FinPlanSMSHandlerInvestment.processForInvestments(sms, allInvestmentsMap, 'PPF');
                    }
                    // Case 5 : NPS
                    else if(sms.Sender__c.contains('NPS')){
                        // sms.Investment_Type__c = 'NPS';
                        // sms.Related_To_Investment__c = true;
                        sms = FinPlanSMSHandlerInvestment.processForInvestments(sms, allInvestmentsMap, 'NPS'); 
                    }
                    // Other Types (like wallet for Amazon, Paytm, phonePe etc)
                    else{
                        sms = FinPlanSMSHandlerOthers.processForOthers(sms, allBankAccountsMap);
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
                if(sms.beneficiary__c != null){
                    sms = fixBeneficiaryName(sms);
                }
            }

            catch(Exception e){
                // throw e;
                // Get the detail error Info and Log the error
                String errorMessage = FinPlanLogger.getDetailedErrorMessage(e);
                String smsContent = sms.content__c + ' || Sender : ' + sms.sender__c + ' || Received At: ' + sms.FinPlan__Received_At__c;
                FinPlanLogger.logError(new FinPlanException(errorMessage), TAG, smsContent);
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
                        else if(ba.Account_Code__c.endsWith('-CC')){   // Credit Card Account
                            String availableCCBalanceString = sms.FinPlan__CC_Available_Balance__c.replace(',', '');
                            System.debug('Inside handleBankAccountBalanceUpdate for CC =>' + availableCCBalanceString);                      
                            ba.FinPlan__CC_Available_Limit__c = Double.valueOf(availableCCBalanceString);
                        }
                        else if(ba.Account_Code__c.endsWith('-WA')){   // Wallet Account (Like Amazon / Paytm etc)
                            String availableWABalanceString = sms.SA_available_balance__c.replace(',', '');
                            System.debug('Inside handleBankAccountBalanceUpdate for WA =>' + availableWABalanceString);                      
                            ba.FinPlan__Last_Balance__c = Double.valueOf(availableWABalanceString);
                        }
                        toBeUpdatedBankAccounts.add(ba);
                            
                        // Also captur  e the updated balance and bank account name for further showing response
                        String resultText = 'Account Name : ' + ba.Name + ' Updated Balance : ' + sms.SA_available_balance__c + '. ';
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

        if(String.isNotEmpty(sms.beneficiary__c) && String.isNotBlank(sms.beneficiary__c)){ // may be overchecked :P

            // If the name contains a dash (-), use specific fixes
            if(sms.beneficiary__c.contains('-')){
                if(sms.beneficiary__c.toUpperCase().contains('CONCENTRIX')){
                    sms.beneficiary__c = 'Concen'; // This is a specific fix
                }
                else if(sms.beneficiary__c.toUpperCase().contains('YESB0000001')){
                    sms.beneficiary__c = 'Transferwise'; // This is a specific fix
                }
                else{
                    sms.beneficiary__c = sms.beneficiary__c.split('-')[2].trim();
                }
            }

            // Correct the beneficiary names from the list of all beneficiaries in the System
            String beneficiaryNameUpperCase = sms.beneficiary__c.toUpperCase();
            for(String extId : allBeneficiariesMap.keySet()){
                if(extId.toUpperCase().contains(beneficiaryNameUpperCase)){
                    sms.beneficiary__c = allBeneficiariesMap.get(extId).Name;
                    break;
                }
            }

            // Some scenarios where we require to check by usin gcontain and not having a adirect match in names
            if(beneficiaryNameUpperCase.contains('NFS*')){ 
                sms.beneficiary__c = 'ICICI ATM Withdrawal'; // NFS means National Financial Switch (NFS), A Leading ATM Network
            }
            else if(beneficiaryNameUpperCase.contains('INFOBIL')){
                // If the bill is paid in Aug month, the bill is generated for July month
                // So 1 month is deducted from Transaction_date__c during calculation below
                String timeFrame = Datetime.newInstance(sms.Transaction_Date__c.addMonths(-1), Time.newInstance(0, 0, 0, 0)).format('MMM-yy'); // CC Bill 
                sms.beneficiary__c = 'ICICI CC Bill for ' + timeFrame;
            }
            // Investment related beneficiary names
            if(sms.beneficiary__c.toUpperCase().contains('CBDT')){
                sms.Related_To_Investment__c = true;
                sms.Investment_Type__c = 'Advance Tax';
            }
            else if(sms.beneficiary__c.toUpperCase().startsWith('INDIANCLEARINGCORP')){
                sms.Related_To_Investment__c = true;
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