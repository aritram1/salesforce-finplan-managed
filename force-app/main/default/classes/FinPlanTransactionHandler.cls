public with sharing class FinPlanTransactionHandler {
    
    static final String TAG = 'FinPlanTransactionHandler';

    public static List<FinPlan__Bank_Transaction__c> bankTransactionsList;
    public static List<FinPlan__Investment_Transaction2__c> investmentTransactionsList;
    public static List<String> btRecordsIds = new List<String>();
    public static List<String> ivRecordsIds = new List<String>();
    public static Map<String, List<String>> dataMap = new Map<String, List<String>>();
    
    public static Map<String, Map<String, List<String>>> createTransactions(List<FinPlan__SMS_Message__c> messageList){
        
        Map<String, Map<string, List<String>>> result = new Map<String, Map<string, List<String>>>();
        
        try{
            bankTransactionsList = new List<FinPlan__Bank_Transaction__c>();
            investmentTransactionsList = new List<FinPlan__Investment_Transaction2__c>();
            // List<FinPlan__Beneficiary__c> beneficiaries = new List<FinPlan__Beneficiary__c>();
            for(FinPlan__SMS_Message__c sms : messageList){
                if(sms.FinPlan__Beneficiary__c?.contains('Fund')){
                    FinPlan__Investment_Transaction2__c ivt = new FinPlan__Investment_Transaction2__c();
                    ivt.FinPlan__Amount__c = Double.valueOf(sms.amount_value__c.replace(',', ''));
                    // To be implemented
                }
                else{
                    FinPlan__Bank_Transaction__c tr = new FinPlan__Bank_Transaction__c();
                    tr.FinPlan__Created_From__c = 'SMS';
                    tr.Type__c = (sms.Type__c == 'credit') ? 'Credit' : 'Debit';
                    tr.FinPlan__Device__c = sms.FinPlan__Device__c;
                    tr.FinPlan__Content__c = sms.FinPlan__content__c.length() <=255 ? sms.FinPlan__content__c :  sms.FinPlan__content__c.substring(0,255);
                    tr.FinPlan__Beneficiary_Name__c = sms.Beneficiary__c;
                    tr.FinPlan__From_Account__c = sms.savings_or_cc_account__c;
                    tr.FinPlan__Transaction_Date__c = sms.FinPlan__Transaction_Date__c;
                    tr.FinPlan__Payment_Via__c = sms.Payment_Via__c;
                    tr.FinPlan__Payment_Reference__c = sms.Payment_Reference__c;
                    tr.FinPlan__Amount__c = Double.valueOf(sms.amount_value__c.replace(',', ''));
                    bankTransactionsList.add(tr);
                }
            }
            if(bankTransactionsList != null && bankTransactionsList.size() > 0){
                insert bankTransactionsList;
                btRecordsIds = processBankTransactions(bankTransactionsList);
                dataMap.put('bt', btRecordsIds);
            }
            if(investmentTransactionsList != null && investmentTransactionsList.size() > 0){
                insert investmentTransactionsList;
                ivRecordsIds = processInvestmentTransactions(investmentTransactionsList);
                dataMap.put('iv', ivRecordsIds);
            }
            result.put('data', dataMap);
        }
        catch(Exception e){
            
            // Log the error
            FinPlanLogger.logError(e, TAG);

            Map<String,List<String>> errorMap = new Map<String,List<String>>();
            List<String> errorList = new List<String>();
            String errorMessage = 'Error occurred : ' + e.getMessage();
            errorList.add(errorMessage);
            errorMap.put('message', errorList);
            result.put('errors', errorMap);
        }
        return result;
    }

    static List<String> processBankTransactions(List<FinPlan__Bank_Transaction__c> btList){
        List<String> processedResponse = new List<String>();
        for(FinPlan__Bank_Transaction__c bt : btList){
            processedResponse.add(bt.id);
        }
        return processedResponse;
    }
    static List<String> processInvestmentTransactions(List<FinPlan__Investment_Transaction2__c> ivList){
        List<String> processedResponse = new List<String>();
        for(FinPlan__Investment_Transaction2__c iv : ivList){
            processedResponse.add(iv.id);
        }
        return processedResponse;
    }
}