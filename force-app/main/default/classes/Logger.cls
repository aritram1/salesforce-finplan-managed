public with sharing class Logger {
    
    // The following methods/overloaded methods serve the purpose of logging success/errors scenarios

    @AuraEnabled
    public static void logError(String error, String componentName){
        insert new FinPlan__System_Log__c(
            FinPlan__Type__c = 'Error',
            FinPlan__Message__c = error?.left(255),
            FinPlan__Exception_Type__c = componentName
        );
    }

    public static void logError(Exception e){
        insert new FinPlan__System_Log__c(
            FinPlan__Type__c = 'Error',
            FinPlan__Message__c = e.getMessage().left(255),
            FinPlan__Stack_Trace__c = e.getStackTraceString().left(255),
            FinPlan__Exception_Type__c = e.getTypeName()
        );
    }

    public static void logError(Exception e, String recordId){
        insert new FinPlan__System_Log__c(
            FinPlan__Type__c = 'Error',
            FinPlan__Message__c = e.getMessage().left(255),
            FinPlan__Stack_Trace__c = e.getStackTraceString().left(255),
            FinPlan__Exception_Type__c = e.getTypeName(),
            FinPlan__Related_Record_Id__c = recordId
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
            FinPlan__Related_Record_Id__c = recordId
        );
    }
}