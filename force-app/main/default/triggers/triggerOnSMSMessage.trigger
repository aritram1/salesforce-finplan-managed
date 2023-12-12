trigger triggerOnSMSMessage on FinPlan__SMS_Message__c (before insert, before update) {

    
    List<Bank_Account__c> allAccounts = [SELECT id, name from Bank_Account__c];
    Map<String, String> allSavingsAccountsMap = new Map<String, String>();
    
    for(Bank_Account__c sa : allAccounts){
        String name = '';
        if(sa.name == 'ICICI Bank Credit Card Account') name = 'ICICI-CC';
        else if(sa.name == 'SBI Savings Account') name = 'SBI';
        else if(sa.name == 'ICICI Bank Savings Account') name = 'ICICI';
        else if(sa.name == 'HDFC Bank Savings Account') name = 'HDFC';
        allSavingsAccountsMap.put(name, sa.id);
    }
    
    // String CONST_NA = 'n/a';
    
    for(FinPlan__SMS_Message__c sms : Trigger.new){
    
        String rawDateString = sms.FinPlan__Received_At__c?.split(' ')[0];
        Integer yyyy = Integer.valueOf(rawDateString.split('-')[0]);
        Integer mm = Integer.valueOf(rawDateString.split('-')[1]);
        Integer dd = Integer.valueOf(rawDateString.split('-')[2]);
        sms.FinPlan__Transaction_Date__c = Date.newInstance(yyyy, mm, dd);
            
        // get the splitted content
        List<String> contentArray = new List<String>();
        contentArray = sms.content__c?.split(' ');
        
        // OTP
        if(sms.content__c?.contains('OTP') || sms.sender__c?.contains('OTP') || sms.content__c?.contains('Verification')){
            sms.Type__c = 'otp';
        }
        else{ 
            // HDFC
            if(sms.Sender__c.contains('HDFC')){
                sms.savings_or_cc_account__c = allSavingsAccountsMap.get('HDFC');
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
                    // sms.SA_available_balance__c = CONST_NA;
                }
                // balance update
                else if(sms.content__c.startsWith('Available Bal in HDFC Bank')){
                    // sms.amount_value__c = CONST_NA;
                    sms.SA_available_balance__c = contentArray[12].substring(0, contentArray[12].length()-1);
                    sms.type__c = 'balance_update';
                    // sms.Beneficiary__c = CONST_NA;
                }
                else{
                    sms.Type__c = 'promotional';
                }
            }
            // SBI
            else if(sms.Sender__c.contains('SBI')){
                sms.savings_or_cc_account__c = allSavingsAccountsMap.get('SBI');
                // balance update
                if(sms.content__c.startsWith('Available Bal in HDFC Bank')){
                    sms.amount_value__c = contentArray[12];
                    sms.type__c = 'balance_update';
                }
                else{
                    sms.Type__c = 'promotional';
                }
            }
            // ICICI
            else if(sms.Sender__c.contains('ICICI')){
                sms.savings_or_cc_account__c = allSavingsAccountsMap.get('ICICI');
                if(sms.content__c.contains('spent on ICICI Credit Card XX9006')){
                    // sms.savings_or_cc_account__c = allSavingsAccountsMap.get('ICICI-Card');//to be implemented
                    // billed limit is to be implemented
                    sms.amount_value__c = contentArray[1];
                    sms.CC_Available_Balance__c = sms.content__c.split('Avl Lmt: INR')[1].split('To dispute')[0];
                    sms.type__c = 'debit';
                    sms.beneficiary__c = sms.content__c.split('at')[1].split('Avl Lmt')[0];
                    sms.savings_or_cc_account__c = allSavingsAccountsMap.get('ICICI-CC');
                }
                else if(sms.content__c.startsWith('ICICI Bank Acct XX360 debited with')){
                    sms.type__c = 'debit';
                    sms.amount_value__c = contentArray[7];
                    // sms.SA_available_balance__c = CONST_NA;
                    if(sms.content__c.contains('UPI')) sms.Payment_Via__c = 'UPI';
                    if(sms.content__c.contains('IMPS')){
                        sms.Payment_Via__c = 'IMPS';
                        sms.Payment_Reference__c = sms.content__c.split('IMPS:')[1].split('. Call ')[0];
                        sms.beneficiary__c = sms.content__c.split('credited.')[0].split('&')[1];
                    }
                    if(sms.content__c.contains('RTGS')) sms.Payment_Via__c = 'RTGS';
                }
                else{
                    sms.Type__c = 'promotional';
                }
                
                
            }
            // Other - Something that is not a financial message, mark personal__c as true
            else{
                sms.type__c = 'personal';
            }
        }
        
        // A final check to see if this sms is related to a financial transaction
        if(sms.amount_value__c != null) sms.Create_Transaction__c = true;
        
        // if(!sms.Create_Transaction__c) sms.addError('Not a Txn message!');
        
        // Not required
        // if(sms.Type__c == 'otp' || sms.Type__c == 'personal'){
        //     sms.SA_available_balance__c = CONST_NA;
        //     sms.beneficiary__c = CONST_NA;
        //     //sms.amount_value__c = CONST_NA;
        // }
        
    }
    
}