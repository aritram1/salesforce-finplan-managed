trigger triggerOnFund on FinPlan__Fund__c (after delete) {
    delete [SELECT id from FinPlan__Investment_Transaction__c where FinPlan__Fund_Details__c =: Trigger.new[0].Id];
}