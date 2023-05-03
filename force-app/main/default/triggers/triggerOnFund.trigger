trigger triggerOnFund on FinPlan__Fund__c (before delete) {
    delete [SELECT Id from FinPlan__Investment_Transaction__c where FinPlan__Fund_Details__c =: Trigger.old[0].Id];
}