trigger triggerOnSMSMessage on FinPlan__SMS_Message__c (before insert, before update) {
    if(Trigger.isBefore){
        if(Trigger.isInsert || Trigger.isUpdate){
            FinPlanSMSMessageTriggerHandler.beforeInsertUpdate(Trigger.new, null); // Trigger.old = null
        }
    }
    // else if(Trigger.isAfter){
    //     // TBD
    // }
}