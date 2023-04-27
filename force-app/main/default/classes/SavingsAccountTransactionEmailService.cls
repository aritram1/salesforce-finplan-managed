global class SavingsAccountTransactionEmailService implements Messaging.InboundEmailHandler {
 
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
 
        // Parse the subject and body of the email
        String emailSubject = email.subject;
        String emailHTMLBody = email.htmlBody;
        String fromAddress = email.fromAddress;

        FinPlan__Savings_Account_Transaction_Email__c sate = new Savings_Account_Transaction_Email__c();
        sate.FinPlan__Subject__c = emailSubject;
        sate.FinPlan__From__c = fromAddress;
        sate.FinPlan__Raw_HTML_Body__c = emailHTMLBody;

        try{
            insert sate;
            Logger.logSuccess(sate.id);
        }
        catch(Exception e){
            Logger.logError(e);
        }
        finally{}

       
        return result;
    }
}