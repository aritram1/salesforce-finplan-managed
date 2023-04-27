trigger triggerOnInvestmentTransaction on Investment_Transaction__c (before Insert) {
    InvestmentTransactionTriggerHandler.beforeInsert(Trigger.new);
}