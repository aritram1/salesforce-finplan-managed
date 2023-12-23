trigger triggerOnSMSMessage on FinPlan__SMS_Message__c (before insert, before update) {
    if(Trigger.isBefore){
        
        List<FinPlan__SMS_Message__c> newList = Trigger.new;

            
        // Manually one record is getting inserted and it's not getting in due to sync in process fired up from flutter app
        if(newList.size() == 1 && newList[0].Created_From__c != 'Sync'){

            // A. Enrich the SMS Data and copy enriched data to current record
            List<FinPlan__SMS_Message__c> enrichedMessageList = FinPlanSMSHandler.enrichData(Trigger.new);
            // System.debug('enrichedMessageList in SMS Trigger =>' + enrichedMessageList);

            if(enrichedMessageList != null && enrichedMessageList.size() == 1){

                // Get the source and target records for data copy
                FinPlan__SMS_Message__c currentMessage = newList[0];
                FinPlan__SMS_Message__c enrichedMessage = enrichedMessageList[0];
                
                currentMessage.Amount_Value__c = enrichedMessage.Amount_Value__c;
                currentMessage.Beneficiary__c = enrichedMessage.Beneficiary__c;
                currentMessage.CC_Available_Balance__c = enrichedMessage.CC_Available_Balance__c;
                currentMessage.Payment_Reference__c = enrichedMessage.Payment_Reference__c;
                currentMessage.Payment_Via__c = enrichedMessage.Payment_Via__c;
                currentMessage.SA_Available_Balance__c = enrichedMessage.SA_Available_Balance__c;
                currentMessage.Savings_or_CC_Account__c = enrichedMessage.Savings_or_CC_Account__c;
                currentMessage.Transaction_Date__c = enrichedMessage.Transaction_Date__c;
                currentMessage.Type__c = enrichedMessage.Type__c;
                currentMessage.Approved__c = enrichedMessage.Approved__c;

                // B. Update balance for bank accounts for this single record
                System.debug('FinPlanSMSHandler.lastBalanceUpdateSMSList (Default manual) : ' + FinPlanSMSHandler.lastBalanceUpdateSMSList);
                for(FinPlan__SMS_Message__c sms : FinPlanSMSHandler.lastBalanceUpdateSMSList){
                    System.debug('Last Balance SMS Sender (Default manual) : ' + sms.Sender__c);
                    System.debug('Last Balance SMS Balance (Default manual): ' + sms.SA_Available_Balance__c);
                    System.debug('Last Balance SMS Bank Account Id (Default manual): ' + sms.Savings_or_CC_Account__c);
                }
                String bankBalanceUpdateResponse = 'Default Manual Response';
                if(FinPlanSMSHandler.lastBalanceUpdateSMSList != null && FinPlanSMSHandler.lastBalanceUpdateSMSList.size() > 0){
                    bankBalanceUpdateResponse = FinPlanSMSHandler.handleBankAccountBalanceUpdate(FinPlanSMSHandler.lastBalanceUpdateSMSList);
                }
                System.debug('bankBalanceUpdateResponse (Default manual) => '+ bankBalanceUpdateResponse); 
            }
        }

        // Data is coming in bulk during sync process
        else {
            List<FinPlan__SMS_Message__c> enrichedMessageList = FinPlanSMSHandler.enrichData(Trigger.new);
            
            Map<String, FinPlan__SMS_Message__c> enrichedMessageMap = new Map<String, FinPlan__SMS_Message__c>();
            for(FinPlan__SMS_Message__c sms : enrichedMessageList){
                enrichedMessageMap.put(sms.FinPlan__Received_At__c, sms);
            }

            // A. Enrich the SMS Data
            for(FinPlan__SMS_Message__c currentMessage : Trigger.new){
                FinPlan__SMS_Message__c enrichedMessage = enrichedMessageMap.get(currentMessage.FinPlan__Received_At__c);
                if(enrichedMessage != null){
                    currentMessage.Amount_Value__c = enrichedMessage.Amount_Value__c;
                    currentMessage.Beneficiary__c = enrichedMessage.Beneficiary__c;
                    currentMessage.CC_Available_Balance__c = enrichedMessage.CC_Available_Balance__c;
                    currentMessage.Payment_Reference__c = enrichedMessage.Payment_Reference__c;
                    currentMessage.Payment_Via__c = enrichedMessage.Payment_Via__c;
                    currentMessage.SA_Available_Balance__c = enrichedMessage.SA_Available_Balance__c;
                    currentMessage.Savings_or_CC_Account__c = enrichedMessage.Savings_or_CC_Account__c;
                    currentMessage.Transaction_Date__c = enrichedMessage.Transaction_Date__c;
                    currentMessage.Type__c = enrichedMessage.Type__c;
                    currentMessage.Approved__c = enrichedMessage.Approved__c;
                }
            }   
            
            // B. Update the bank balance
            System.debug('FinPlanSMSHandler.lastBalanceUpdateSMSList (Sync method) : ' + FinPlanSMSHandler.lastBalanceUpdateSMSList);
            for(FinPlan__SMS_Message__c sms : FinPlanSMSHandler.lastBalanceUpdateSMSList){
                System.debug('Last Balance SMS Sender (Sync method) : ' + sms.Sender__c);
                System.debug('Last Balance SMS Balance (Sync method): ' + sms.SA_Available_Balance__c);
                System.debug('Last Balance SMS Bank Account Id (Sync method) : ' + sms.Savings_or_CC_Account__c);
            }
            String bankBalanceUpdateResponse = 'Default Sync Response';
            if(FinPlanSMSHandler.lastBalanceUpdateSMSList != null && FinPlanSMSHandler.lastBalanceUpdateSMSList.size() > 0){
                bankBalanceUpdateResponse = FinPlanSMSHandler.handleBankAccountBalanceUpdate(FinPlanSMSHandler.lastBalanceUpdateSMSList);
            }
            System.debug('bankBalanceUpdateResponse (Sync method) => '+ bankBalanceUpdateResponse); 
        
        }
        
    }
}