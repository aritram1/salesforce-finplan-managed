public with sharing class InvestmentTransactionTriggerHandler {
    
    public static void beforeInsert(List<FinPlan__Investment_Transaction__c> newList){
        for(FinPlan__Investment_Transaction__c each : newList){
            InvestmentTransactionTriggerHandler.populateInvestmentType(each);
        }
    }

    public static void populateInvestmentType(FinPlan__Investment_Transaction__c it){
        if(it.FinPlan__Bond_Details__c != null){ it.Investment_Type__c = GlobalConstants.BOND;}
        else if(it.FinPlan__EPF_Details__c != null){ it.Investment_Type__c = GlobalConstants.EPF;}
        else if(it.FinPlan__FD_Details__c != null){ it.Investment_Type__c = GlobalConstants.FD;}
        else if(it.FinPlan__Fund_Details__c != null){ it.Investment_Type__c = GlobalConstants.MF;}
        else if(it.FinPlan__Metal_Investment_Details__c != null){ it.Investment_Type__c = GlobalConstants.METAL;}
        else if(it.FinPlan__PPF_Details__c != null){ it.Investment_Type__c = GlobalConstants.PPF;}
        else if(it.FinPlan__SIP_Details__c != null){ it.Investment_Type__c = GlobalConstants.SIP;}
        else if(it.FinPlan__SmallCase_Details__c != null){ it.Investment_Type__c = GlobalConstants.SMALLCASE;}
        else if(it.FinPlan__Stock_Details__c != null){ it.Investment_Type__c = GlobalConstants.STOCK;}
        else if(it.FinPlan__Treasury_Bill_Details__c != null){ it.Investment_Type__c = GlobalConstants.TREASURYBILL;}
        else if(it.FinPlan__ULIP_Details__c != null){ it.Investment_Type__c = GlobalConstants.ULIP;}
        else if(it.FinPlan__NPS_Details__c != null){ it.Investment_Type__c = GlobalConstants.NPS;}
        else { it.Investment_Type__c = GlobalConstants.NONE;}
    }
}