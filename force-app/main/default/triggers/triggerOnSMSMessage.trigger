trigger triggerOnSMSMessage on FinPlan__SMS_Message__c (before insert, before update, after insert, after update) {
    if(Trigger.isBefore && Trigger.new[0].Created_From__c != 'Sync'){
        List<FinPlan__SMS_Message__c> all = FinPlanSMSHandler.enrichData(Trigger.new);
        System.debug('all=>' + all);
        FinPlan__SMS_Message__c enrichedMessage = all[0];
        FinPlan__SMS_Message__c firstRecord = Trigger.new[0];
        firstRecord.Amount_Value__c = enrichedMessage.Amount_Value__c;
        firstRecord.Beneficiary__c = enrichedMessage.Beneficiary__c;
        firstRecord.CC_Available_Balance__c = enrichedMessage.CC_Available_Balance__c;
        firstRecord.Payment_Reference__c = enrichedMessage.Payment_Reference__c;
        firstRecord.Payment_Via__c = enrichedMessage.Payment_Via__c;
        firstRecord.SA_Available_Balance__c = enrichedMessage.SA_Available_Balance__c;
        firstRecord.Savings_or_CC_Account__c = enrichedMessage.Savings_or_CC_Account__c;
        firstRecord.Transaction_Date__c = enrichedMessage.Transaction_Date__c;
        firstRecord.Type__c = enrichedMessage.Type__c;
        firstRecord.UPI_Reference__c = enrichedMessage.UPI_Reference__c;
        firstRecord.UPI__c = enrichedMessage.UPI__c;
        // firstRecord.Create_Transaction__c = enrichedMessage.Create_Transaction__c;
        // firstRecord.Amount__c = enrichedMessage.Amount__c;
        // firstRecord.Approved__c = enrichedMessage.Approved__c;
    }
    // if(Trigger.isAfter){
        // String response = FinPlanSyncSMSAPIController.createTransactions(Trigger.new);
        // System.debug('Response is => ' + response);
    // }
}