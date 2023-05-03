trigger triggerOnStock on FinPlan__Stock__c (after delete) {
    delete [SELECT Id from FinPlan__Investment_Transaction__c where FinPlan__Stock_Details__c =: Trigger.new[0].Id];
}