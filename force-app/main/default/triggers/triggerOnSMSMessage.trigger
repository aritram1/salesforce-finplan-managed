trigger triggerOnSMSMessage on FinPlan__SMS_Message__c (before insert, before update, after insert, after update) {
    if(Trigger.isBefore){
        List<FinPlan__SMS_Message__c> all = FinPlanSMSHandler.enrichData(Trigger.new);
        FinPlan__SMS_Message__c enrichedMessage = all[0];
        Trigger.new[0].Amount_Value__c = enrichedMessage.Amount_Value__c;
        Trigger.new[0].Amount__c = enrichedMessage.Amount__c;
        Trigger.new[0].Approved__c = enrichedMessage.Approved__c;
        Trigger.new[0].Beneficiary__c = enrichedMessage.Beneficiary__c;
        Trigger.new[0].CC_Available_Balance__c = enrichedMessage.CC_Available_Balance__c;
        Trigger.new[0].Create_Transaction__c = enrichedMessage.Create_Transaction__c;
        Trigger.new[0].Payment_Reference__c = enrichedMessage.Payment_Reference__c;
        Trigger.new[0].Payment_Via__c = enrichedMessage.Payment_Via__c;
        Trigger.new[0].SA_Available_Balance__c = enrichedMessage.SA_Available_Balance__c;
        Trigger.new[0].Savings_or_CC_Account__c = enrichedMessage.Savings_or_CC_Account__c;
        Trigger.new[0].Transaction_Date__c = enrichedMessage.Transaction_Date__c;
        Trigger.new[0].Type__c = enrichedMessage.Type__c;
        Trigger.new[0].UPI_Reference__c = enrichedMessage.UPI_Reference__c;
        Trigger.new[0].UPI__c = enrichedMessage.UPI__c;
    }
    if(Trigger.isAfter){
        String response = FinPlanSyncSMSAPIController.createTransactions(Trigger.new);
        System.debug('Response is => ' + response);
    }
}
/*
trigger triggerOnSMSMessage on FinPlan__SMS_Message__c (before insert, before update) {

   // Standard lists to do further actions
    List<FinPlan__SMS_Message__c> listToCreateBankAccountTransacations = new List<FinPlan__SMS_Message__c>();
    List<FinPlan__SMS_Message__c> listToCreateInvestmentTransacations = new List<FinPlan__SMS_Message__c>();
    List<FinPlan__SMS_Message__c> listOfRejectedRecords = new List<FinPlan__SMS_Message__c>();
    List<FinPlan__SMS_Message__c> listOfAllowedRecords = new List<FinPlan__SMS_Message__c>();
    FinPlan__SMS_Message__c lastBalanceUpdateSMS;
    
    // Make a map of code vs Id to set Bank account info later
    Map<String, Bank_Account__c> allBankAccountsMap = new Map<String, Bank_Account__c>();
    for(Bank_Account__c ba : [SELECT Id, Finplan__Account_Code__c, FinPlan__Last_Balance__c, FinPlan__CC_Available_Limit__c, FinPlan__CC_Max_Limit__c from Bank_Account__c]){
        allBankAccountsMap.put(ba.Finplan__Account_Code__c, ba);
    }
    
    // The main loop starts
    for(FinPlan__SMS_Message__c sms : Trigger.new){
        
        // set the date;
        String rawDateString = sms.FinPlan__Received_At__c?.split(' ')[0];
        Integer yyyy = Integer.valueOf(rawDateString.split('-')[0]);
        Integer mm = Integer.valueOf(rawDateString.split('-')[1]);
        Integer dd = Integer.valueOf(rawDateString.split('-')[2]);
        sms.FinPlan__Transaction_Date__c = Date.newInstance(yyyy, mm, dd);
            
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
        if(sms.content__c?.contains('OTP') || sms.sender__c?.contains('OTP') || sms.content__c?.contains('Verification') || sms.content__c?.contains('verification')){
            sms.Type__c = 'otp';
        }

        //set credit debit balance_update types
        ////////////////////////////////////////////////////////////////////////////////////////
        else{ 
            // HDFC
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
                    // TBC
                    // sms.Payment_Reference__c= content.split('to ')[1].split('. Not you?')[0].split('UPI Ref No ')[1];
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
                }
                else if(sms.content__c.startsWith('Available Bal in HDFC Bank A/c XX9560 on')){
                    sms.SA_available_balance__c = contentArray[10].substring(0, contentArray[10].length()-1);
                    sms.SA_available_balance__c =  sms.SA_available_balance__c.replace('.Cheque', ''); // further check added
                    sms.type__c = 'balance_update';
                }
            }
            // SBI
            else if(sms.Sender__c.contains('SBI')){
                sms.savings_or_cc_account__c = allBankAccountsMap.get('SBI-SA').Id;

                // balance update
                if(sms.content__c.startsWith('Available Bal in HDFC Bank')){
                    sms.amount_value__c = contentArray[12];
                    sms.type__c = 'balance_update';
                }
            }
            // ICICI
            else if(sms.Sender__c.contains('ICICI')){
                if(sms.content__c.contains('spent on ICICI Credit Card XX9006')){
                    // billed limit is to be implemented
                    sms.savings_or_cc_account__c = allBankAccountsMap.get('ICICI-CC').Id;
                    sms.amount_value__c = contentArray[1];
                    sms.CC_Available_Balance__c = sms.content__c.split('Avl Lmt: INR')[1].split('To dispute')[0];
                    sms.type__c = 'debit';
                    sms.beneficiary__c = sms.content__c.split('at')[1].split('Avl Lmt')[0];
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
                    }
                    if(sms.content__c.contains('RTGS')){
                        sms.Payment_Via__c = 'RTGS';
                    }
                }
            }
        }

        // setting promotional
        ////////////////////////////////////////////////////////////////////////////////////////
        if(sms.type__c == null || sms.type__c == ''){
            sms.type__c = 'promotional';
        }

        // A final check to see if this sms is related to a financial transaction
        ////////////////////////////////////////////////////////////////////////////////////////
        if(sms.amount_value__c != null){
            sms.Create_Transaction__c = true;
        }

        // handle all type scenarios
        if(sms.Type__c == 'balance_update'){
            // sms.addError('test');
            lastBalanceUpdateSMS = sms;
        }
    }

    if(lastBalanceUpdateSMS != null){
        handleBalanceUpdate(lastBalanceUpdateSMS);
    }

    // This method updates the balance for savigns account or credit card account from the last balanace update sms
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public void handleBalanceUpdate(FinPlan__SMS_Message__c latestBalanceUpdateSMS){
        Bank_Account__c bankAccountRecord = new Bank_Account__c();

        // Get Bank Account Record from the Map
        String sender = latestBalanceUpdateSMS.sender__c != null ? latestBalanceUpdateSMS.sender__c : '';
        if(latestBalanceUpdateSMS.FinPlan__SA_Available_Balance__c != null && latestBalanceUpdateSMS.FinPlan__SA_Available_Balance__c != ''){
            if(sender.contains('HDFC')){ 
                //To be implemented Bank_Account__c.Allowed_Senders__c implmentation
                bankAccountRecord = allBankAccountsMap.get('HDFC-SA');
            }
            else if(sender.contains('ICICI')){
                bankAccountRecord = allBankAccountsMap.get('ICICI-SA');
            }
            else if(sender.contains('SBI')){
                bankAccountRecord = allBankAccountsMap.get('SBI-SA');
            }
            bankAccountRecord.FinPlan__Last_Balance__c = Double.valueOf(latestBalanceUpdateSMS.FinPlan__SA_Available_Balance__c.replace(',', '').replace(' ', '')); //to avoid values like 12,34,45.00
        }
        else if(latestBalanceUpdateSMS.CC_Available_Balance__c != null && latestBalanceUpdateSMS.CC_Available_Balance__c != ''){
            if(sender.contains('HDFC')){ 
                //To be implemented Bank_Account__c.Allowed_Senders__c implmentation
                bankAccountRecord = allBankAccountsMap.get('HDFC-SA');
            }
            else if(sender.contains('ICICI')){
                bankAccountRecord = allBankAccountsMap.get('ICICI-SA');
            }
            else if(sender.contains('SBI')){
                bankAccountRecord = allBankAccountsMap.get('SBI-SA');
            }
            bankAccountRecord.FinPlan__CC_Available_Limit__c = Double.valueOf(latestBalanceUpdateSMS.CC_Available_Balance__c.replace(',', '').replace(' ', ''));
        }
        update bankAccountRecord;
    }
    
}
*/