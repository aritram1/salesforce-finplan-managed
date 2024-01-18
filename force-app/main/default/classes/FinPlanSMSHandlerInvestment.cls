public with sharing class FinPlanSMSHandlerInvestment {

    public static FinPlan__SMS_Message__c processForInvestments(FinPlan__SMS_Message__c sms, Map<String, Bank_Account__c> allBankAccountsMap){
        
        sms.Related_To_Investment__c = true;
        
        if(sms.Sender__c.contains('NSE')){
            sms = processForNSE(sms, allBankAccountsMap);
        }
        else if(sms.Sender__c.contains('EPF')){
            sms = processForEPF(sms, allBankAccountsMap);
        }
        else if(sms.Sender__c.contains('NPS')){
            sms = processForNPS(sms, allBankAccountsMap);
        }
        else if(sms.sender__c.contains('ITDCPC')){
            sms = processForTax(sms, allBankAccountsMap);
        }
        else if(sms.Investment_Type__c == 'PPF'){
            sms = processForPPF(sms, allBankAccountsMap);
        }
        // else if(sms.Sender__c.contains('PPF')){

        // }
        return sms;
    }

    public static FinPlan__SMS_Message__c processForTax(FinPlan__SMS_Message__c sms, Map<String, Bank_Account__c> allBankAccountsMap){
        sms.type__c = 'income_tax';
        return sms;
    }

    public static FinPlan__SMS_Message__c processForPPF(FinPlan__SMS_Message__c sms, Map<String, Bank_Account__c> allBankAccountsMap){
        sms.type__c = 'ppf';
        sms.amount_value__c = sms.content__c.split(' ')[5];
        sms.INV_Available_Balance__c = sms.content__c.split('Avl Bal INR')[1].split('-')[0].replace(',', '').trim();
        sms.beneficiary__c = 'PPF';
        return sms;
    }

    public static FinPlan__SMS_Message__c processForNSE(FinPlan__SMS_Message__c sms, Map<String, Bank_Account__c> allBankAccountsMap){
        List<String> contentArray = sms.content__c?.split(' ');
        return sms;
    }

    public static FinPlan__SMS_Message__c processForEPF(FinPlan__SMS_Message__c sms, Map<String, Bank_Account__c> allBankAccountsMap){
        List<String> contentArray = sms.content__c?.split(' ');
        if(sms.content__c.contains('your passbook balance against')){
            sms.Investment_Type__c = 'EPF';
            sms.type__c = 'epf';
            sms.amount_value__c = contentArray[12].replace(',', '').replace('/', '').replace('-', '');
            
            sms.INV_Available_Balance__c = contentArray[8].replace(',', '').replace('/', '').replace('-', '');
            if(sms.INV_Available_Balance__c.endsWith('.')){
                sms.INV_Available_Balance__c = sms.INV_Available_Balance__c.substring(0, sms.INV_Available_Balance__c.length() - 1);
            }
            
            sms.Beneficiary__c = 'EPF For ' + contentArray[16].substring(2,6) + '/' + contentArray[16].substring(0,2);
        }
        return sms;
    }

    public static FinPlan__SMS_Message__c processForNPS(FinPlan__SMS_Message__c sms, Map<String, Bank_Account__c> allBankAccountsMap){
        List<String> contentArray = sms.content__c?.split(' ');
        if(sms.content__c.startsWith('Investment value in Tier I (PRANXX8815)')){
            sms.Investment_Type__c = 'NPS';
            sms.type__c = 'balance_update';
            sms.INV_Available_Balance__c = contentArray[11].replace(',', '');
            if(sms.INV_Available_Balance__c.endsWith('.')){ // if there is a dot in the end, remove it
                sms.INV_Available_Balance__c = sms.INV_Available_Balance__c.substring(0, sms.INV_Available_Balance__c.length() - 1);
            }
            sms.Related_To_Investment__c = true;
        }
        return sms;
    }
}