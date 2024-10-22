public with sharing class FinPlanSMSMessageTriggerHandler {
    
    static final String TAG = 'FinPlanSMSMessageTriggerHandler';

    public static void beforeInsertUpdate(List<FinPlan__SMS_Message__c> triggerNewList, List<FinPlan__SMS_Message__c> triggerOldList){
        
        try{
            // List<FinPlan__SMS_Message__c> oldList = triggerOldList; // To be used later
            List<FinPlan__SMS_Message__c> newList = triggerNewList;

            // Get the enriched data and create a map from it. The key will be message receive time, 
            // as populated from the android broadcast receiver
            List<FinPlan__SMS_Message__c> enrichedMessageList = FinPlanSMSHandler.enrichData(newList);
            
            Map<String, FinPlan__SMS_Message__c> enrichedMessageMap = new Map<String, FinPlan__SMS_Message__c>();
            for(FinPlan__SMS_Message__c sms : enrichedMessageList){
                enrichedMessageMap.put(sms.FinPlan__Received_At__c, sms); // key is received time
            }

            // A. Enrich the SMS Data
            for(FinPlan__SMS_Message__c currentMessage : newList){
                FinPlan__SMS_Message__c enrichedMessage = enrichedMessageMap.get(currentMessage.FinPlan__Received_At__c);
                if(enrichedMessage != null){
                    currentMessage.Amount_Value__c = enrichedMessage.Amount_Value__c;
                    currentMessage.Beneficiary__c = enrichedMessage.Beneficiary__c;
                    currentMessage.Payment_Reference__c = enrichedMessage.Payment_Reference__c;
                    currentMessage.Payment_Via__c = enrichedMessage.Payment_Via__c;
                    currentMessage.SA_Available_Balance__c = enrichedMessage.SA_Available_Balance__c;
                    currentMessage.CC_Available_Balance__c = enrichedMessage.CC_Available_Balance__c;
                    currentMessage.Savings_or_CC_Account__c = enrichedMessage.Savings_or_CC_Account__c;
                    currentMessage.Transaction_Date__c = enrichedMessage.Transaction_Date__c;
                    currentMessage.Type__c = enrichedMessage.Type__c;
                    currentMessage.Approved__c = enrichedMessage.Approved__c;
                    currentMessage.Related_To_Investment__c = enrichedMessage.Related_To_Investment__c;
                    currentMessage.Investment_Type__c = enrichedMessage.Investment_Type__c;
                    currentMessage.INV_Available_Balance__c = enrichedMessage.INV_Available_Balance__c;
                    currentMessage.Beneficiary_Type__c = enrichedMessage.Beneficiary_Type__c;

                    // If the Payment reference is not available or applicable to the specific sms,
                    // assign a 6 character long random string as unique identifer of the sms
                    if(String.isBlank(currentMessage.Payment_Reference__c)){
                        currentMessage.Payment_Reference__c = 'random' + String.valueOf((Integer)(Math.random() * 900000) + 100000);
                    }
                    
                    // Populate an external id for the sms records from available
                    currentMessage.External_Id__c = currentMessage.Payment_Reference__c + '|' + currentMessage.Transaction_Date__c;

                    currentMessage.Masked_Content__c = FinPlanUtil.getMaskedContent(currentMessage);
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
        catch(Exception e){
            // Get the detail error Info and Log the error
            String errorMessage = FinPlanLogger.getDetailedErrorMessage(e);
            FinPlanLogger.logError(new FinPlanException(errorMessage), TAG);
        }
    
    }
}