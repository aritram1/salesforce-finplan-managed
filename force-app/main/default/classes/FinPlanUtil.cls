public with sharing class FinPlanUtil {
    
    public static String clipTo255char(String str){
        return str.length() <= 255 ? str : str.substring(0, 255);
    }

    public static String getMaskedContent(SMS_Message__c sms){
        String maskedContent = sms.Content__c;
        return maskedContent;
    }
    
}