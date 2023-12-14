public with sharing class FinPlanTransactionHandler {
    
    public static List<FinPlan__Bank_Transaction__c> bankTransactionsList;
    public static List<FinPlan__Investment_Transaction__c> investmentTransactionsList;

    public static String createTransactions(List<FinPlan__SMS_Message__c> messageList){
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
                tr.FinPlan__Created_From__c = 'SMS';
                tr.FinPlan__SMS_Content__c = sms.FinPlan__content__c.length() <=255 ? sms.FinPlan__content__c :  sms.FinPlan__content__c.substring(0,255);
                tr.FinPlan__Beneficiary_Name__c = sms.Beneficiary__c;
                tr.FinPlan__From_Account__c = sms.savings_or_cc_account__c;
                tr.FinPlan__Transaction_Date__c = sms.FinPlan__Transaction_Date__c;
                tr.FinPlan__Payment_Via__c = sms.Payment_Via__c;
                tr.FinPlan__Payment_Reference__c = sms.Payment_Reference__c;
                tr.Type__c = (sms.Type__c == 'credit') ? 'Credit' : 'Debit';
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

}