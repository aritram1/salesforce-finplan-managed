public with sharing class FinPlanLogger {

    static final String TAG = 'FinPlanLogger';
    
    // The following methods/overloaded methods serve the purpose of logging info/success/errors scenarios
    public static void logError(Exception e, String relatedTo){
        insert new FinPlan__System_Log__c(
            FinPlan__Message__c = e.getMessage()?.left(255),
            FinPlan__Related_To__c = relatedTo, // relatedto can be component name, record Id etc
            FinPlan__Stack_Trace__c = e.getStackTraceString().left(255)
        );
    }

}