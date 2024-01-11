public with sharing class FinPlanLogger {

    static final String TAG = 'FinPlanLogger';
    
    // The following methods/overloaded methods serve the purpose of logging info/success/errors scenarios
    public static void logError(Exception e, String relatedTo){
        logError(e, relatedTo, null);
    }
    
    public static void logError(Exception e, String relatedTo, String content){
        insert new FinPlan__System_Log__c(
            FinPlan__Exception_Type__c = e.getTypeName(),
            FinPlan__Message__c = e.getMessage()?.left(255),
            FinPlan__Related_To__c = String.isNotBlank(relatedTo) ? relatedTo.substring(0,255) : 'Not Provided', // relatedto can be component name, record Id etc
            FinPlan__Stack_Trace__c = e.getStackTraceString().left(255),
            FinPlan__Content__c = String.isNotBlank(content) ? content.substring(0,255) : 'Not Provided'
        );
    }

}