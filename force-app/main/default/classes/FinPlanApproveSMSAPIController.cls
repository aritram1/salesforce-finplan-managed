@RestResource(urlMapping='/api/sms/approve/*')
global with sharing class FinPlanApproveSMSAPIController {

    @HttpPost
    global static String updateApprovedField(Map<String, List<String>> input) {
        List<String> recordIds = input.get('data');
        List<finplan__sms_message__c> recordsToUpdate = [SELECT id, Approved__c from SMS_Message__c where id in :recordIds];

        for (SMS_Message__c rec : recordsToUpdate) {
            rec.Approved__c = true;
        }

        try {
            update recordsToUpdate;
            return 'Records updated successfully.' + String.join(recordIds, ' - ');
        } catch (DmlException e) {
            return 'Error updating records: ' + e.getMessage();
        }
    }
}