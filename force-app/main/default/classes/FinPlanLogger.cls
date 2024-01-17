public with sharing class FinPlanLogger {

    static final String TAG = 'FinPlanLogger';
    
    // The following methods/overloaded methods serve the purpose of logging info/success/errors scenarios
    public static void logError(Exception e, String relatedTo){
        logError(e, relatedTo, null);
    }
    
    public static void logError(Exception e, String relatedTo, String content){
        
        FinPlan__System_Log__c log = new FinPlan__System_Log__c();
        
        log.FinPlan__Exception_Type__c = e.getTypeName();
        log.FinPlan__Message__c = e.getMessage().length() <= 255 ? e.getMessage() : e.getMessage().substring(0, 255);
        log.FinPlan__Stack_Trace__c = e.getStackTraceString().length() <= 255 ? e.getStackTraceString() : e.getStackTraceString().substring(0, 255);
        log.FinPlan__Content__c = String.isNotBlank(content) ? (content.length() <= 255 ? content : content.substring(0, 255))
                                                             : 'SMS Content Not Provided';
        log.FinPlan__Related_To__c = String.isNotBlank(relatedto) ? (relatedto.length() <= 255 ? relatedto : relatedto.substring(0, 255))
                                                                  : 'Related Info Not Provided';
        insert log;
    }

}