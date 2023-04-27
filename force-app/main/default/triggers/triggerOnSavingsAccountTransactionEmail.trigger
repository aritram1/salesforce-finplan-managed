trigger triggerOnSavingsAccountTransactionEmail on FinPlan__Savings_Account_Transaction_Email__c (after insert) {
    
    try{
        SavingsAccountTransactionEmailHandler.processEmail(Trigger.newMap, Trigger.oldMap);
    }
    catch(Exception e){
        Logger.logError(e);
    }
    finally{}

}