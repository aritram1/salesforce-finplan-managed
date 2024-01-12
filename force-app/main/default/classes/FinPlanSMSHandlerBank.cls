public with sharing class FinPlanSMSHandlerBank {

    public static FinPlan__SMS_Message__c processForBanks(FinPlan__SMS_Message__c sms, Map<String, Bank_Account__c> allBankAccountsMap){
        if(sms.Sender__c.contains('HDFC')){
            sms = processForHDFCBank(sms, allBankAccountsMap);
        }
        else if(sms.Sender__c.contains('ICICI')){
            sms = processForICICIBank(sms, allBankAccountsMap);
        }
        else if(sms.Sender__c.contains('SBI')){
            sms = processForSBIBank(sms, allBankAccountsMap);
        }
        return sms;
    }


    // This method enriches the sms record if it's from HDFC
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static FinPlan__SMS_Message__c processForHDFCBank(FinPlan__SMS_Message__c sms, Map<String, Bank_Account__c> allBankAccountsMap){
        
        List<String> contentArray = new List<String>();
        contentArray = sms.content__c?.split(' ');
        
        sms.savings_or_cc_account__c = allBankAccountsMap.get('HDFC-SA').Id;

        // credit 1
        if(sms.content__c.contains('deposited')){
            sms.amount_value__c = contentArray[2].replace(',' , '');
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
        // credit 2
        else if(sms.content__c.startsWith('Money Received')){
            sms.amount_value__c = contentArray[4].replace(',' , '');
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
        // credit 3
        else if(sms.content__c.startsWith('HDFC Bank: Rs.') && sms.content__c.contains('credited to a/c XXXXXX9560') && sms.content__c.contains('UPI Ref No')){
            sms.amount_value__c = contentArray[3].replace(',' , '');
            String upiRef = sms.content__c.split('UPI Ref No')[1];
            sms.Payment_Reference__c = upiRef.substring(0, upiRef.length()-2);
            sms.Payment_Via__c = 'UPI';
            String beneficiary = sms.content__c.split(' by ')[1].split('UPI Ref No')[0];
            sms.beneficiary__c = beneficiary.substring(0, beneficiary.length()-2);
            sms.type__c = 'credit';
        }
        // debit1 bank transfer
        else if(sms.content__c.contains('debited from a/c **9560') && sms.content__c.contains('UPI')){
            sms.amount_value__c = contentArray[3].replace(',' , '');
            sms.type__c = 'debit';
            sms.Payment_Via__c = 'UPI';
            String content = sms.content__c.replace('(', '').replace(')', '');
            sms.Beneficiary__c = content.split(' to ')[1].split('. Not you?')[0].split('UPI Ref')[0];
            sms.Beneficiary__c = toCamelCase(sms.Beneficiary__c); // convert to camel case for better readability

            String paymentReferenceString = sms.content__c.replace('(', 'START_BRACKET').replace(')', 'END_BRACKET');
            sms.Payment_Reference__c = paymentReferenceString.split('START_BRACKET')[1].split('END_BRACKET')[0].replace('UPI Ref No.', '').trim();
        }
        // debit2 UPI
        else if(sms.content__c.startswith('Money Transfer:Rs') && sms.content__c.contains('UPI')){
            sms.amount_value__c = contentArray[2].replace(',' , '');
            sms.type__c = 'debit';
            sms.Payment_Via__c = 'UPI';
            sms.Payment_Reference__c = sms.content__c.split(' UPI:')[1].split('Not you?')[0];
            sms.Beneficiary__c = sms.content__c.split(' UPI')[0].split(' to ')[1];
            sms.Beneficiary__c = toCamelCase(sms.Beneficiary__c); // convert to camel case for better readability
        }
        // debit3 UPI where sms starts like 
        // UPDATE: ....
        else if(sms.content__c.contains('debited from HDFC Bank XX9560')){
            sms.amount_value__c = contentArray[2].replace(',', '');
            sms.type__c = 'debit';
            sms.Payment_Via__c = 'UPI';
            sms.SA_available_balance__c = sms.content__c.split('Avl bal:INR ')[1].replace(',', '');
            sms.beneficiary__c = sms.content__c.split('Info: UPI-')[1].split('Avl bal:INR')[0];
            if(sms.beneficiary__c.length() > 255){
                sms.beneficiary__c = sms.beneficiary__c.substring(0,255);
            }
            sms.Beneficiary__c = toCamelCase(sms.Beneficiary__c); // convert to camel case for better readability
        }
        // debit4 via NEFT/IMPS where sms starts like
        // Thanks for paying ...
        else if(sms.content__c.startswith('Thanks for paying Rs.')){
            sms.amount_value__c = contentArray[3].replace(',', '').replace('Rs.', '');
            sms.type__c = 'debit';
            sms.Payment_Via__c = 'IMPS';
            sms.Beneficiary__c = sms.content__c.split('from A/c XXXX9560 to')[1].split('via HDFC Bank NetBanking')[0];
            sms.Beneficiary__c = toCamelCase(sms.Beneficiary__c); // convert to camel case for better readability
        }
        // debit 5
        else if(sms.content__c.startswith('Alert!') && sms.content__c.contains('spent Rs')){
            sms.amount_value__c = contentArray[2].replace(',', '').replace('Rs.', '');
            sms.type__c = 'debit';
            sms.Payment_Via__c = 'DEBITCARD';
            sms.SA_Available_Balance__c = sms.content__c.split('Avl bal: ')[1].split('Not you?')[0].replace(',', '');
            sms.Beneficiary__c = sms.content__c.split('At ')[1].split('On ')[0].replace('.', ' ').replace('_', '').trim();
            sms.Beneficiary__c = toCamelCase(sms.Beneficiary__c); // convert to camel case for better readability
        }
        // debit 6
        else if(sms.content__c.startsWith('Money Transferred - ')){
            sms.amount_value__c = contentArray[4].replace(',', '');
            sms.SA_available_balance__c = sms.content__c.split('Avl bal:INR ')[1].split(' Not you')[0].replace(',', '');
            sms.type__c = 'debit';
            String content = sms.content__c.replace('(', 'STARTBRACKET').replace(')', 'ENDBRACKET').replace('.', '');
            sms.beneficiary__c = content.split(' to ')[1].split('STARTBRACKET')[0].trim();
            if(sms.content__c.contains('IMPS')){
                sms.Payment_Via__c = 'IMPS';
            }
        }
        // atm withdrawal
        else if(sms.content__c.contains('ve withdrawn Rs.')){
            sms.amount_value__c = contentArray[2].replace(',' , '').replace('Rs.', '');
            sms.type__c = 'debit';
            sms.Payment_Via__c = 'ATM';
            sms.Beneficiary__c = 'HDFC ATM withdrawal';
            sms.Beneficiary__c = toCamelCase(sms.Beneficiary__c);
        }
        // balance update
        else if(sms.content__c.startsWith('Available Bal in HDFC Bank A/c XX9560 as on')){
            sms.SA_available_balance__c = contentArray[12].substring(0, contentArray[12].length()-1);
            sms.SA_available_balance__c =  sms.SA_available_balance__c.replace('.Cheque', ''); // further check added
            sms.Type__c = 'balance_update';
        }
        else if(sms.content__c.startsWith('Available Bal in HDFC Bank A/c XX9560 on')){
            sms.SA_available_balance__c = contentArray[10].substring(0, contentArray[10].length()-1);
            sms.SA_available_balance__c =  sms.SA_available_balance__c.replace('.Cheque', ''); // further check added
            sms.Type__c = 'balance_update';
        }
        
        return sms;
    }
    // End method

    // This method enriches the sms record if it's from SBI
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static FinPlan__SMS_Message__c processForSBIBank(FinPlan__SMS_Message__c sms, Map<String, Bank_Account__c> allBankAccountsMap){
        List<String> contentArray = new List<String>();
        contentArray = sms.content__c?.split(' ');
        sms.savings_or_cc_account__c = allBankAccountsMap.get('SBI-SA').Id;
        
        // credit 1
        if(sms.content__c.contains('Your a/c no. XXXXXXXX6414 is credited by')){
            sms.amount_value__c = contentArray[9].replace(',' , '').replace('Rs.', '');
            String modifiedContent = sms.content__c.replace('(', 'START_BRACKET').replace(')', 'END_BRACKET');
            sms.beneficiary__c = modifiedContent.split('by')[2].split('START_BRACKET')[0];
            sms.Beneficiary__c = toCamelCase(sms.Beneficiary__c); // convert to camel case for better readability
            if(modifiedContent.contains('IMPS')){
                sms.Payment_Via__c = 'IMPS';
                sms.Payment_Reference__c = modifiedContent.split('START_BRACKET')[1].split('END_BRACKET')[0].replace('IMPS Ref no', '').trim();
            }
            sms.type__c = 'credit';
        }
        // credit 2
        else if(sms.content__c.startsWith('Your A/C XXXXX816414 has credit')){
            sms.amount_value__c = sms.content__c.split('of Rs ')[1].split(' on ')[0].replace(',', '');
            sms.SA_Available_Balance__c = sms.content__c.split('Avl Bal Rs ')[1].split('.-')[0].replace(',' ,'');
            if(sms.content__c.contains('IMPS')) { 
                sms.Payment_Via__c = 'IMPS'; 
            }
            sms.Beneficiary__c = sms.content__c.split(' of Rs ')[0].split('has credit for')[1];
            sms.type__c = 'credit';
        }
        // credit 3
        else if(sms.content__c.startsWith('Your A/C XXXXX816414 has credit for')){
            sms.type__c = 'credit';
            sms.beneficiary__c = sms.content__c.split(' of Rs ')[0].split('has credit for ')[1].trim();
            sms.beneficiary__c = sms.content__c.split(' of Rs ')[1].split(' on ')[0].replace(',', '').trim();

        }
        // debit 1
        else if(sms.content__c.contains('Your a/c no. XXXXXXXX6414 is debited for')){
            sms.amount_value__c = contentArray[9].replace(',' , '').replace('Rs.', '');
            sms.beneficiary__c = sms.content__c.split('and')[1].split('credited')[0].trim();
            sms.Beneficiary__c = toCamelCase(sms.Beneficiary__c); // convert to camel case for better readability
            sms.type__c = 'debit';
        }
        // debit 2
        else if(sms.content__c.startsWith('Dear Customer, Your A/C XXXXX816414 has a debit')){
            sms.type__c = 'debit';
            sms.amount_value__c = contentArray[12].replace(',', '');
            sms.SA_Available_Balance__c = sms.content__c.split('Avl Bal Rs ')[1].split('.-')[0].replace(',', '');
            sms.beneficiary__c = 'Not Available';
        }
        // debit via yono app
        else if(sms.content__c.contains('Your A/C XXXXX816414 Debited INR')){
            sms.amount_value__c = contentArray[5].replace(',', '');
            sms.SA_available_balance__c = sms.content__c.split('Avl Balance INR')[1].split('-')[0].replace(',', '');
            sms.beneficiary__c = sms.content__c.split('Avl Balance INR')[0].split('Transferred to')[1].trim();
            if(sms.beneficiary__c.endsWith('.')){
                sms.beneficiary__c = sms.beneficiary__c.substring(0, sms.beneficiary__c.length()-1);
            }
            sms.Beneficiary__c = toCamelCase(sms.Beneficiary__c); // convert to camel case for better readability
            sms.Payment_Via__c = 'IMPS';
            sms.type__c = 'debit';
        }
        // atm withdrawal
        else if(sms.content__c.contains('withdrawn at SBI ATM')){
            sms.amount_value__c = contentArray[3].replace(',' , '').replace('Rs.', '');
            sms.Payment_Via__c = 'ATM';
            sms.type__c = 'debit';
            
            sms.beneficiary__c = 'SBI ATM withdrawal';
            sms.Beneficiary__c = toCamelCase(sms.Beneficiary__c); // convert to camel case for better readability
            
            sms.SA_available_balance__c = contentArray[18].replace('Rs.', '');
            if(sms.SA_available_balance__c.endsWith('.')){
                sms.SA_available_balance__c = sms.SA_available_balance__c.substring(0, sms.SA_available_balance__c.length()-1);
            }
            sms.Payment_Reference__c = contentArray[15];
            if(sms.Payment_Reference__c.endsWith('.')){
                sms.Payment_Reference__c = sms.Payment_Reference__c.substring(0, sms.Payment_Reference__c.length()-1);
            }
        }
        return sms;
    }
    // End method

    // This method enriches the sms record if it's from ICICI
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static FinPlan__SMS_Message__c processForICICIBank(FinPlan__SMS_Message__c sms, Map<String, Bank_Account__c> allBankAccountsMap){
        List<String> contentArray = new List<String>();
        contentArray = sms.content__c?.split(' ');
        // Credit card blocks
        if(sms.content__c.contains('spent on ICICI Bank Card XX9006')){
            sms.savings_or_cc_account__c = allBankAccountsMap.get('ICICI-CC').Id;
            sms.type__c = 'debit';
            sms.beneficiary__c = sms.content__c.split(' at ')[1].split('. Avl Lmt')[0];
            sms.Beneficiary__c = toCamelCase(sms.Beneficiary__c); // convert to camel case for better readability
            sms.amount_value__c = contentArray[1].replace(',' , '');
            sms.CC_Available_Balance__c = sms.content__c.split('Avl Lmt: INR')[1].split('. To dispute')[0];
        }
        // -- This part is not required since the bill paid sms is already tracked -- //
        // else if(sms.content__c.contains('received on your ICICI Bank Credit Card Account 4xxx9006')){
        //     sms.savings_or_cc_account__c = allBankAccountsMap.get('ICICI-CC').Id;
        //     sms.Balance_Update__c = true;
        //     sms.type__c = 'balance_update';
        //     sms.amount_value__c = contentArray[5].replace(',' , '');
        //     sms.beneficiary__c = 'Payment Received ICICI CC';
        //     sms.Beneficiary__c = toCamelCase(sms.Beneficiary__c); // convert to camel case for better readability
        // }
        
        // Savings account block
        // Credit
        else if(sms.content__c.startsWith('ICICI Bank Account XX360 credited')){
            sms.savings_or_cc_account__c = allBankAccountsMap.get('ICICI-SA').Id;
            sms.type__c = 'credit';
            sms.amount_value__c = contentArray[5].replace(',' , '');
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
                }
            }
        }
        // debit 1
        else if(sms.content__c.startsWith('ICICI Bank Acct XX360 debited with')){
            sms.savings_or_cc_account__c = allBankAccountsMap.get('ICICI-SA').Id;
            sms.type__c = 'debit';
            sms.amount_value__c = contentArray[7].replace(',' , '');
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
        // debit 2
        else if(sms.content__c.startsWith('ICICI Bank Acc XX360 debited Rs.')){
            sms.savings_or_cc_account__c = allBankAccountsMap.get('ICICI-SA').Id;
            sms.type__c = 'debit';
            sms.amount_value__c = contentArray[6].replace(',', '');
            sms.SA_Available_Balance__c = sms.content__c.split('.Avl Bal Rs. ')[1].split('To dispute call')[0].replace(',', '');
            if(sms.SA_Available_Balance__c.endsWith('.')){
                sms.SA_Available_Balance__c = sms.SA_Available_Balance__c.substring(0, sms.SA_Available_Balance__c.length()-1);
            } 
            if(sms.content__c.contains('InfoBIL*')){
                sms.beneficiary__c = 'Bill Paid ICICI CC';
            }
            else{
                sms.beneficiary__c = 'XXXXXXXXXXX';
            }
            sms.Payment_Via__c = 'IMPS';
        }
        // debit 3
        else if(sms.content__c.startsWith('ICICI Bank Acc XX360 is debited with')){
            sms.savings_or_cc_account__c = allBankAccountsMap.get('ICICI-SA').Id;
            sms.amount_value__c = contentArray[8].replace(',' , '');
            sms.SA_Available_Balance__c = sms.content__c.split('. Available bal: Rs. ')[1].split('. For dispute call')[0].replace(',','');
            sms.type__c = 'debit';
            sms.beneficiary__c = sms.content__c.split('. Available bal:')[0].split(' on ')[1].trim();
            sms.beneficiary__c = sms.beneficiary__c.substring(9, sms.beneficiary__c.length());
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
            List<String> modifiedWords = new List<String>();
            inputString = inputString.trim();

            // Split the string into words
            List<String> words = inputString.trim().split(' ');
            
            for (String word : words) {
                word = word.trim(); // trim the whitespaces
                if(word.length() == 1){
                    modifiedWords.add(word.toUpperCase());  // if there is only one character in the word
                }
                else if(word.length() > 1){ // if there are atleast 2 characters in a word
                    String firstAlphabet = word.substring(0, 1).toUpperCase();
                    String rest = word.substring(1, word.length()).toLowerCase();
                    modifiedWords.add(firstAlphabet + rest);
                }
            }

            // Join the words back together
            return String.join(modifiedWords, ' ');
            
        }
    }
}