public with sharing class FinPlanSMSHandlerInvestment {

    public static FinPlan__SMS_Message__c processForInvestments(FinPlan__SMS_Message__c sms, Map<String, Bank_Account__c> allBankAccountsMap){
        if(sms.Sender__c == 'VK-NSESMS'){
            sms = processForNSE(sms, allBankAccountsMap);
        }
        return sms;
    }

    public static FinPlan__SMS_Message__c processForNSE(FinPlan__SMS_Message__c sms, Map<String, Bank_Account__c> allBankAccountsMap){
        List<String> contentArray = new List<String>();
        contentArray = sms.content__c?.split(' ');
        if(sms.Sender__c == 'VK-NSESMS'){
            sms.Related_To_Investment__c = true;
        }
        return sms;
    }

}