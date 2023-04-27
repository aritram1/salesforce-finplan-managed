public with sharing class Logger {
    public Logger() {}

    public static void logError(Exception e){
        insert new FinPlan__System_Log__c(
            FinPlan__Type__c = 'Error',
            FinPlan__Message__c = e.getMessage(),
            FinPlan__Stack_Trace__c = e.getStackTraceString()
        );
    }

    public static void logError(Exception e, String recordId){
        insert new FinPlan__System_Log__c(
            FinPlan__Type__c = 'Error',
            FinPlan__Message__c = e.getMessage(),
            FinPlan__Stack_Trace__c = e.getStackTraceString(),
            FinPlan__Record_Id__c = recordId
        );
    }

    public static void logSuccess(){
        insert new FinPlan__System_Log__c(
            FinPlan__Type__c = 'Success',
            FinPlan__Message__c = 'Success : ' + DateTime.now()
        );
    }

    public static void logSuccess(String recordId){
        insert new FinPlan__System_Log__c(
            FinPlan__Type__c = 'Success',
            FinPlan__Message__c = 'Success : ' + DateTime.now(),
            FinPlan__Record_Id__c = recordId
        );
    }
}