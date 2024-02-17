public with sharing class FinPlanSMSHandlerOthers {

    public static FinPlan__SMS_Message__c processForOthers(FinPlan__SMS_Message__c sms, Map<String, Bank_Account__c> allBankAccountsMap){
        
        if(sms.content__c.toUpperCase().contains('AMAZON PAY')){
            sms.type__c = 'balance_update';
            sms.Balance_Update__c = true;
            sms.savings_or_cc_account__c = allBankAccountsMap.get('AMAZON-WA').Id;
            
            if(sms.content__c.contains('added to Amazon Pay balance')){
                sms.SA_Available_Balance__c = sms.content__c.split(' ')[9];
                sms.amount_value__c = sms.content__c.split(' ')[1];
            }
            else if(sms.content__c.contains('added to Amazon Pay Wallet')){
                sms.SA_Available_Balance__c = sms.content__c.split(' ')[9];
                sms.amount_value__c = sms.content__c.split(' ')[1];
            }
            else if(sms.content__c.contains('Refund')){
                sms.SA_Available_Balance__c = sms.content__c.split(' ')[18];
                sms.amount_value__c = sms.content__c.split(' ')[7];
            }
        }

        if((sms.amount_value__c != null) && (sms.amount_value__c.endsWith('.'))){
            sms.amount_value__c = sms.amount_value__c.substring(0, sms.amount_value__c.length() - 1);
        }
        if((sms.SA_Available_Balance__c != null) && sms.SA_Available_Balance__c.endsWith('.')){
            sms.SA_Available_Balance__c = sms.SA_Available_Balance__c.substring(0, sms.SA_Available_Balance__c.length() - 1);
        }

        return sms;
    }

        
        
}