trigger triggerOnInvestmentTransaction on Investment_Transaction__c (before Insert) {
    InvestmentTransactionTriggerHandler.populateInvestmentType(Trigger.newMap, Trigger.oldMap);
}