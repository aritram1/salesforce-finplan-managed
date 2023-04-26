public with sharing class SavingsAccountTransactionEmailHandler {
    public SavingsAccountTransactionEmailHandler() {}

    public static String bankName = 'HDFC Bank Savings Account';

    public static void processEmail(Map<Id, FinPlan__Savings_Account_Transaction_Email__c> newMap, Map<Id, FinPlan__Savings_Account_Transaction_Email__c> oldMap){
        
        FinPlan__Savings_Account_Transaction_Email__c record = newMap.values()[0];
        System.debug('record.FinPlan__Raw_HTML_Body__c=>' + record.FinPlan__Raw_HTML_Body__c);
        
        if(record.FinPlan__Raw_HTML_Body__c.contains('Your A/c xxxxxxxxxx9560 is')){
            processBankTransaction(record);
        }
        else if(record.FinPlan__Raw_HTML_Body__c.contains('from account **9560') || record.FinPlan__Raw_HTML_Body__c.contains('Your UPI transaction reference number')){
            processUPITransaction(record);
        }
    }


    public static void processUPITransaction(FinPlan__Savings_Account_Transaction_Email__c record){

        String emailHTMLBody = record.FinPlan__Raw_HTML_Body__c;
        String savingsAccountName = 'HDFC Bank Savings Account';
        
        Integer startPosition = emailHTMLBody?.indexOf('Rs.');
        Integer endPositon = emailHTMLBody?.indexOf('Please call on');
        
        System.debug('startPosition=>' + startPosition);
        System.debug('endPositon=>' + endPositon);

        if(startPosition == -1 || endPositon == -1){
            throw new DMLException('Email Format is invalid for UPI transaction');
        }
        else{
            String formattedContent = emailHTMLBody.substring(startPosition, endPositon)
                                        ?.replace('<br/>', '')?.replace('<br />', '')
                                        ?.replace('<br>', '')?.replace('<br >', '');
            System.debug('formattedContent=>' + formattedContent);
            
            List<String> words = formattedContent.split(' ');
            System.debug('words processUPITransaction=>' + words);
            
            // Rs.100.00 has been debited from account **9560 to VPA amazonupi@apl on 26-04-23.
            // Your UPI transaction reference number is 311672192542.
            
            String txnAmount = words[0].replace(',', '').subString(3, words[0].length()); // Rs.100.00
            Boolean isDebit = words[3].contains('debit') ? true : false; //debited
            String txnIMPSRef = words[18].substring(0, words[18].length()-1); // 311672192542.

            System.debug('txnAmount=>' + txnAmount + ' txnIMPSRef=>' + txnIMPSRef + ' isDebit=>' + isDebit);
            
            FinPlan__Savings_Account_Transaction__c sat = new FinPlan__Savings_Account_Transaction__c();
            sat.FinPlan__Data_Source__c = 'Email';
            // sat.Savings_Account__c = [SELECT id, FinPlan__Bank__r.FinPlan__Email__c FROM FinPlan__Savings_Account__c WHERE FinPlan__Bank__r.FinPlan__Email__c = :fromAddress LIMIT 1]?.id;
            FinPlan__Savings_Account__c savingsAccount = [SELECT Id, FinPlan__Last_Balance__c, FinPlan__Bank__r.FinPlan__Email__c FROM FinPlan__Savings_Account__c WHERE name = :bankName LIMIT 1];
            sat.FinPlan__Savings_Account__c = savingsAccount.Id;//'a065i00000JvVEsAAN';    //HDFC Bank Savings Account
            sat.FinPlan__Amount__c = Double.valueOf(txnAmount);
            sat.FinPlan__IMPS_Referene__c = txnIMPSRef;
            sat.FinPlan__Type__c = isDebit ? 'Debit' : 'Credit';
            sat.FinPlan__Payment_Type__c = 'UPI';
            sat.FinPlan__Balance__c = savingsAccount.FinPlan__Last_Balance__c - Double.valueOf(txnAmount);
            sat.FinPlan__Email_Content__c = formattedContent;
            insert sat;

            // Also pass on last balance to update at the Savings account level
            update new FinPlan__Savings_Account__c (
                id = savingsAccount.Id,
                FinPlan__Last_Balance__c = sat.FinPlan__Balance__c
            );
            
        }           
    }

    public static void processBankTransaction(FinPlan__Savings_Account_Transaction_Email__c record){

        String emailHTMLBody = record.FinPlan__Raw_HTML_Body__c;
        String fromAddress = record.FinPlan__From__c;

        System.debug('fromAddress=>' + fromAddress);

        Integer startPosition = emailHTMLBody?.indexOf('Your A/c xxxxxxxxxx9560 is');
        Integer endPositon = emailHTMLBody?.indexOf('Did you know?');
        
        System.debug('startPosition=>' + startPosition);
        System.debug('endPositon=>' + endPositon);

        if(startPosition == -1 || endPositon == -1){
            throw new DMLException('Email Format is invalid for Bank transaction');
        }
        else{
            String formattedContent = emailHTMLBody.substring(startPosition, endPositon)
                                        ?.replace('<br/>', '')?.replace('<br />', '')
                                        ?.replace('<br>', '')?.replace('<br >', '');
            System.debug('formattedContent=>' + formattedContent);
            
            List<String> words = formattedContent.split(' ');
            
            // Your A/c xxxxxxxxxx9560 is debited for INR 1.00 on 26-04-23 and A/c xxxxxxx6414 is credited
            // (IMPS Ref No. 311615377190)
            // Available balance is INR 2,83,538.55

            String txnAmount = words[7];
            Boolean isDebit = words[4].contains('debit') ? true : false;
            String txnIMPSRef = words[17].replace(')', ' ').split(' ')[0]; // ( does not work with SF regex)
            List<String> txnBalanceList = words[words.size()-1].replace(',','').replace('.',' ').split(' '); // similarly . does not work as SF regex
            String txnBalance = txnBalanceList[0] + '.' + txnBalanceList[1];
            
            System.debug('txnAmount=>' + txnAmount);
            System.debug('txnIMPSRef=>' + txnIMPSRef);
            System.debug('txnBalance=>' + txnBalance);
            System.debug('isDebit=>' + isDebit);

            FinPlan__Savings_Account_Transaction__c sat = new FinPlan__Savings_Account_Transaction__c();
            sat.FinPlan__Data_Source__c = 'Email';
            sat.FinPlan__Type__c = isDebit ? 'Debit' : 'Credit';
            sat.FinPlan__Payment_Type__c = 'Bank';
            String savingsAccountId = [SELECT Id, FinPlan__Bank__r.FinPlan__Email__c FROM FinPlan__Savings_Account__c WHERE name = :bankName limit 1]?.id;
            sat.FinPlan__Savings_Account__c = savingsAccountId;//'a065i00000JvVEsAAN';    //HDFC Bank Savings Account
            sat.FinPlan__Amount__c = Double.valueOf(txnAmount);
            sat.FinPlan__IMPS_Referene__c = txnIMPSRef;
            sat.FinPlan__Balance__c = Double.valueOf(txnBalance);
            sat.FinPlan__Email_Content__c = formattedContent;
            insert sat;

            // Also pass on last balance to update at the Savings account level
            update new FinPlan__Savings_Account__c (
                id = savingsAccountId,
                FinPlan__Last_Balance__c = sat.FinPlan__Balance__c
            );
        }           
    }
}