public with sharing class FinPlanTransactionHandler {
    
    static final String TAG = 'FinPlanTransactionHandler';

    public static List<FinPlan__Bank_Transaction__c> bankTransactionsList;
    public static List<FinPlan__Investment_Transaction2__c> investmentTransactionsList;
    public static Map<String, FinPlan__Investment__c> toBeUpdatedInvestmentsMap = new Map<String, FinPlan__Investment__c>();
    public static List<String> bankTransactionRecordsIds = new List<String>();
    public static List<String> investmentTransactionRecordsIds = new List<String>();
    public static List<String> investmentRecordIds = new List<String>();
    public static Map<String, List<String>> dataMap = new Map<String, List<String>>();
    public static Map<String, FinPlan__Investment__c> existingInvestments = new Map<String, FinPlan__Investment__c>();


    public static Map<String, Map<String, List<String>>> createTransactions(List<FinPlan__SMS_Message__c> messageList){
        // Get a list of existing investments and pass to next call : `processTransactions`
        for(FinPlan__Investment__c inv : [SELECT Id, Investment_Code__c, FinPlan__Current_Value_of_Investment__c, 
                                                 FinPlan__Invested_Amount__c, FinPlan__Last_Investment_Date__c, 
                                                 FinPlan__Status__c, FinPlan__Type__c 
                                                 FROM FinPlan__Investment__c 
                                                 WHERE Status__c != null])
        {
            existingInvestments.put(inv.Investment_Code__c, inv);
        }
        System.debug('existingInvestments=>' + existingInvestments);
        Map<String, Map<String, List<String>>> data = processTransactions(messageList, existingInvestments);
        return data;
    }
    
    public static Map<String, Map<String, List<String>>> processTransactions(List<FinPlan__SMS_Message__c> messageList, Map<String, FinPlan__Investment__c> existingInvestments){
        
        Map<String, Map<string, List<String>>> result = new Map<String, Map<string, List<String>>>();
        Map<String, Integer> txnToMessageMap = new Map<String, Integer>();
        
        try{
            bankTransactionsList = new List<FinPlan__Bank_Transaction__c>();
            investmentTransactionsList = new List<FinPlan__Investment_Transaction2__c>();
            // List<FinPlan__Beneficiary__c> beneficiaries = new List<FinPlan__Beneficiary__c>();
            
            // TBC later
            // Integer btIndex = 0;
            // Integer invIndex = 0;
            for(Integer index = 0; index < messageList.size(); index++){
                FinPlan__SMS_Message__c sms = messageList.get(index);
                if(sms.Related_To_Investment__c == true){
                    FinPlan__Investment_Transaction2__c ivt = new FinPlan__Investment_Transaction2__c();
                    ivt.FinPlan__Created_From__c = 'SMS';
                    ivt.Type__c = sms.Investment_Type__c;
                    ivt.FinPlan__Device__c = sms.FinPlan__Device__c;
                    ivt.FinPlan__Content__c = sms.FinPlan__content__c.length() <=255 ? sms.FinPlan__content__c :  sms.FinPlan__content__c.substring(0,255);
                    ivt.FinPlan__Beneficiary_Name__c = sms.Beneficiary__c;
                    ivt.FinPlan__Transaction_Date__c = sms.FinPlan__Transaction_Date__c;
                    ivt.FinPlan__Payment_Via__c = sms.Payment_Via__c;
                    ivt.FinPlan__Payment_Reference__c = sms.Payment_Reference__c;
                    ivt.FinPlan__Amount__c = Double.valueOf(sms.amount_value__c.replace(',', ''));

                    // Set the following two things at the transaction and investment level for different type of investments
                    if(sms.Investment_Type__c == 'EPF' || sms.Investment_Type__c == 'PPF' || sms.Investment_Type__c == 'NPS'){
                        
                        // 1 - Update the Current Value at the Investment Level
                        FinPlan__Investment__c investment = existingInvestments.get(sms.Investment_Type__c);
                        ivt.FinPlan__Investment__c = investment.Id;

                        // 2 - Update the Parent Investment Information
                        if(String.isNotBlank(sms.INV_Available_Balance__c)){ // && sms.INV_Available_Balance__c > 0){
                            investment.FinPlan__Current_Value_of_Investment__c = Double.valueOf(sms.INV_Available_Balance__c);
                            toBeUpdatedInvestmentsMap.put(investment.FinPlan__Investment_Code__c, investment);
                        }
                    }
                    // Other Type Investments like FD, MF, Stocks, ULIP to be added here later
                    // else if{
                    // }
                    
                    investmentTransactionsList.add(ivt);
                    
                    // TBC later
                    // orderMap.put('bt-'+btIndex, index);
                    // btIndex = btIndex + 1;
                }
                else{
                    FinPlan__Bank_Transaction__c tr = new FinPlan__Bank_Transaction__c();
                    tr.FinPlan__Created_From__c = 'SMS';
                    tr.FinPlan__Type__c = (sms.Type__c == 'credit') ? 'Credit' : 'Debit';
                    tr.FinPlan__Device__c = sms.FinPlan__Device__c;
                    tr.FinPlan__Content__c = sms.FinPlan__content__c.length() <=255 ? sms.FinPlan__content__c :  sms.FinPlan__content__c.substring(0,255);
                    tr.FinPlan__Beneficiary_Name__c = sms.Beneficiary__c;
                    tr.FinPlan__From_Account__c = sms.savings_or_cc_account__c;
                    tr.FinPlan__Transaction_Date__c = sms.FinPlan__Transaction_Date__c;
                    tr.FinPlan__Payment_Via__c = sms.Payment_Via__c;
                    tr.FinPlan__Payment_Reference__c = sms.Payment_Reference__c;
                    tr.FinPlan__Amount__c = Double.valueOf(sms.amount_value__c.replace(',', ''));
                    tr.FinPlan__Beneficiary_Type__c = sms.Beneficiary_Type__c;

                    bankTransactionsList.add(tr);

                    // TBC later
                    // orderMap.put('inv-'+btIndex, index);
                    // invIndex = invIndex + 1;
                }
            }
            if(bankTransactionsList != null && bankTransactionsList.size() > 0){
                insert bankTransactionsList;
                bankTransactionRecordsIds = processBankTransactions(bankTransactionsList);
                dataMap.put('bt', bankTransactionRecordsIds);
            }
            if(investmentTransactionsList != null && investmentTransactionsList.size() > 0){
                insert investmentTransactionsList;
                investmentTransactionRecordsIds = processInvestmentTransactions(investmentTransactionsList);
                dataMap.put('iv', investmentTransactionRecordsIds);
            }
            if(toBeUpdatedInvestmentsMap.values() != null && toBeUpdatedInvestmentsMap.values().size() > 0){
                update toBeUpdatedInvestmentsMap.values();
                investmentRecordIds = processInvestments(toBeUpdatedInvestmentsMap.values());
                dataMap.put('investments', investmentRecordIds);
            }
            result.put('data', dataMap);
        }
        catch(Exception e){

            // Get the detail error Info and Log the error
            String errorMessage = FinPlanLogger.getDetailedErrorMessage(e);
            FinPlanLogger.logError(new FinPlanException(errorMessage), TAG);

            // TBC Later
            // String errorMessage = '';
            // if(e.getTypeName().contains('DMLException')){
            //     for (Integer i = 0; i < e.getNumDml(); i++) {
            //         // Process exception here
            //         errorMessage += e.getDMLType(i) + ' || ' + e.getDmlMessage(i) + ' || ' + e.getDmlFields(i) + '|'; 
            //         errorMessage += (messageList.get('inv-'+i)!=null) ? messageList.get('inv-'+i) : 'inv_not_found';
            //         errorMessage += (messageList.get('bt-'+i)!=null) ? messageList.get('bt-'+i) : 'bt_not_found'; 
            //     }
            // }
            // else{
            //     errorMessage = e.getMessage();
            // }

            // Also send the response back from this `api` accordingly
            Map<String,List<String>> errorMap = new Map<String,List<String>>();
            List<String> errorList = new List<String>();
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
    static List<String> processInvestments(List<FinPlan__Investment__c> investmentList){
        List<String> processedResponse = new List<String>();
        for(FinPlan__Investment__c investment : investmentList){
            processedResponse.add(investment.id);
        }
        return processedResponse;
    }
}