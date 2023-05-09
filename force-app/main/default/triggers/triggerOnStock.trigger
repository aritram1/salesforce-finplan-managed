trigger triggerOnStock on FinPlan__Stock__c (before delete) {
    delete [SELECT Id, FinPlan__Stock_Details__c from FinPlan__Investment_Transaction__c where FinPlan__Stock_Details__c =: Trigger.old[0].Id];
}