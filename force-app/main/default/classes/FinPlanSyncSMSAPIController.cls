@RestResource(urlMapping='/api/sms/sync/*')
global with sharing class FinPlanSyncSMSAPIController {
    public FinPlanSyncSMSAPIController() {}

    @HttpPost
    global static Map<String, String> syncMessages(List<Map<String, String>> records) {
        Map<String, String> response = new Map<String, String>();
        try{
            List<FinPlan__SMS_Message__c> allMessages = new List<FinPlan__SMS_Message__c>();
            for(Map<String, String> messageData : records){
                FinPlan__SMS_Message__c sms = new FinPlan__SMS_Message__c();
                sms.FinPlan__Content__c = messageData.get('FinPlan__Content__c');
                sms.FinPlan__Sender__c = messageData.get('FinPlan__Sender__c');
                sms.FinPlan__Received_At__c = messageData.get('FinPlan__Received_At__c');
                sms.FinPlan__Device__c = messageData.get('FinPlan__Device__c');
                allMessages.add(sms);
            }
            List<FinPlan__SMS_Message__c> processedMessages = FinPlanSMSHandler.enrichData(allMessages);
            
            insert processedMessages;

            if(FinPlanSMSHandler.lastBalanceUpdateSMS != null){
                FinPlanSMSHandler.handleBankAccountBalanceUpdate(FinPlanSMSHandler.lastBalanceUpdateSMS);
            }

            response.put('statusCode', '200');
            response.put('data', 'SUCCESS : ' + processedMessages.size() + ' messages are processed');
            response.put('error', '');
        }
        catch(Exception ex){
            response.put('statusCode', '400');
            response.put('data', '');
            response.put('error', 'Error : ' + ex.getMessage());
        }
        return response;
    }
}