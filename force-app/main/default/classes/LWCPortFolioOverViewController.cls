public with sharing class LWCPortFolioOverViewController {
    
    @AuraEnabled
    public static List<FinPlan__Investment_Portfolio__c> getPortfolioOverviewData(String portfolioId){
        try {
            List<FinPlan__Investment_Portfolio__c> allPortfolios = [SELECT 
                                    Id, FinPlan__SmallCase_Invested_Amount__c, FinPlan__Bond_Investment_Amount__c, 
                                    FinPlan__Stock_Invested_Amount__c, FinPlan__Treasury_Bills_Invested_Amount__c,
                                    FinPlan__Ulip_Invested_Amount__c, FinPlan__MF_Invested_Amount__c, FinPlan__EPF_Invested_Amount__c, 
                                    FinPlan__PPF_Invested_Amount__c, FinPlan__FD_Invested_Amount__c, FinPlan__Metal_Invested_Amount__c 
                                    FROM FinPlan__Investment_Portfolio__c 
                                    WHERE Id = :portfolioId];
            return allPortfolios;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}