trigger triggerOnSavingsAccountTransactionEmail on FinPlan__Savings_Account_Transaction_Email__c (after insert, after update) {
    
    try{
        SavingsAccountTransactionEmailHandler.processEmail(Trigger.newMap, Trigger.oldMap);
    }
    catch(Exception e){
        insert new FinPlan__System_Log__c(
            FinPlan__Type__c = 'Error',
            FinPlan__Message__c = e.getMessage(),
            FinPlan__Stack_Trace__c = e.getStackTraceString(),
            FinPlan__Exception_Type__c = e.getTypeName()
        );
    }
    finally{}

}