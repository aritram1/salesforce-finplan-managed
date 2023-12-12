@RestResource(urlMapping='/api/sms/delete/*')
global with sharing class FinPlanDeleteSMSAPIController {

    @HttpPost
    global static String deleteSMSAndEmptyRecycleBin() {
        try {
            List<SMS_Message__c> messagesToDelete = [SELECT Id FROM SMS_Message__c];
            if(messagesToDelete != null && messagesToDelete.size() > 0){
                Database.DeleteResult[] deleteResults = Database.delete(messagesToDelete, false);
                Database.emptyRecycleBin(messagesToDelete);
                return 'SUCCESS : ' + messagesToDelete.size() + ' records deleted successfully.';
            }
            else{
                return 'SUCCESS : Nothing to delete';
            }
        } catch (DmlException e) {
            return 'Failed : Error deleting messages: ' + e.getMessage();
        }
    }
}