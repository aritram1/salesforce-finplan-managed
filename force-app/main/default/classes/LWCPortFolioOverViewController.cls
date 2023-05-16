// The main controller class for Portfolio OVerview LWC

public with sharing class LWCPortFolioOverViewController {

    public static final List<String> ALL_INVESTMENT_TYPES = GlobalConstants.ALL_INVESTMENT_TYPES;
    
    @AuraEnabled
    public static List<PortfolioOverviewDataWrapper> getPortfolioOverviewData(String portfolioId){
        try {
            List<FinPlan__Investment_Portfolio__c> allPortfolios 
                          = [SELECT Id, FinPlan__SmallCase_Invested_Amount__c, FinPlan__Bond_Investment_Amount__c, FinPlan__SIP_Invested_Amount__c,
                                FinPlan__Stock_Invested_Amount__c, FinPlan__Treasury_Bills_Invested_Amount__c,FinPlan__NPS_Invested_Amount__c,
                                FinPlan__Ulip_Invested_Amount__c, FinPlan__MF_Invested_Amount__c, FinPlan__EPF_Invested_Amount__c, 
                                FinPlan__PPF_Invested_Amount__c, FinPlan__FD_Invested_Amount__c, FinPlan__Metal_Invested_Amount__c
                                FROM FinPlan__Investment_Portfolio__c // Add the user/system context running mode
                                WHERE Id = :portfolioId];
            System.debug('allPortfolios=>' + allPortfolios);
            System.debug('convertToWrapper(allPortfolios)=>' + convertToWrapper(allPortfolios));

            return convertToWrapper(allPortfolios);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static List<PortfolioOverviewDataWrapper> convertToWrapper(List<FinPlan__Investment_Portfolio__c> allPortfolios){
        List<PortfolioOverviewDataWrapper> wrapperRecords = new List<PortfolioOverviewDataWrapper>();
        for(FinPlan__Investment_Portfolio__c portfolio : allPortfolios){
            
            if(portfolio.FinPlan__Bond_Investment_Amount__c > 0){
                PortfolioOverviewDataWrapper wrapper = new PortfolioOverviewDataWrapper();
                wrapper.id = portfolio.Id;
                wrapper.name = GlobalConstants.BOND;
                wrapper.value = portfolio.FinPlan__Bond_Investment_Amount__c;
                wrapperRecords.add(wrapper);
            }

            if(portfolio.FinPlan__EPF_Invested_Amount__c > 0){
                PortfolioOverviewDataWrapper wrapper = new PortfolioOverviewDataWrapper();
                wrapper.id = portfolio.Id;
                wrapper.name = GlobalConstants.EPF;
                wrapper.value = portfolio.FinPlan__EPF_Invested_Amount__c;
                wrapperRecords.add(wrapper);
            }

            if(portfolio.FinPlan__FD_Invested_Amount__c > 0){
                PortfolioOverviewDataWrapper wrapper = new PortfolioOverviewDataWrapper();
                wrapper.id = portfolio.Id;
                wrapper.name = GlobalConstants.FD;
                wrapper.value = portfolio.FinPlan__FD_Invested_Amount__c;
                wrapperRecords.add(wrapper);
            }

            if(portfolio.FinPlan__MF_Invested_Amount__c > 0){
                PortfolioOverviewDataWrapper wrapper = new PortfolioOverviewDataWrapper();
                wrapper.id = portfolio.Id;
                wrapper.name = GlobalConstants.MF;
                wrapper.value = portfolio.FinPlan__MF_Invested_Amount__c;
                wrapperRecords.add(wrapper);
            }

            if(portfolio.FinPlan__Metal_Invested_Amount__c > 0){
                PortfolioOverviewDataWrapper wrapper = new PortfolioOverviewDataWrapper();
                wrapper.id = portfolio.Id;
                wrapper.name = GlobalConstants.METAL;
                wrapper.value = portfolio.FinPlan__Metal_Invested_Amount__c;
                wrapperRecords.add(wrapper);
            }

            if(portfolio.FinPlan__PPF_Invested_Amount__c > 0){
                PortfolioOverviewDataWrapper wrapper = new PortfolioOverviewDataWrapper();
                wrapper.id = portfolio.Id;
                wrapper.name = GlobalConstants.PPF;
                wrapper.value = portfolio.FinPlan__PPF_Invested_Amount__c;
                wrapperRecords.add(wrapper);
            }

            if(portfolio.FinPlan__SmallCase_Invested_Amount__c > 0){
                PortfolioOverviewDataWrapper wrapper = new PortfolioOverviewDataWrapper();
                wrapper.id = portfolio.Id;
                wrapper.name = GlobalConstants.SMALLCASE;
                wrapper.value = portfolio.FinPlan__SmallCase_Invested_Amount__c;
                wrapperRecords.add(wrapper);
            }

            if(portfolio.FinPlan__SIP_Invested_Amount__c > 0){
                PortfolioOverviewDataWrapper wrapper = new PortfolioOverviewDataWrapper();
                wrapper.id = portfolio.Id;
                wrapper.name = GlobalConstants.SIP;
                wrapper.value = portfolio.FinPlan__SIP_Invested_Amount__c;
                wrapperRecords.add(wrapper);
            }

            if(portfolio.FinPlan__Stock_Invested_Amount__c > 0){
                PortfolioOverviewDataWrapper wrapper = new PortfolioOverviewDataWrapper();
                wrapper.id = portfolio.Id;
                wrapper.name = GlobalConstants.STOCK;
                wrapper.value = portfolio.FinPlan__Stock_Invested_Amount__c;
                wrapperRecords.add(wrapper);
            }

            if(portfolio.FinPlan__NPS_Invested_Amount__c > 0){
                PortfolioOverviewDataWrapper wrapper = new PortfolioOverviewDataWrapper();
                wrapper.id = portfolio.Id;
                wrapper.name = GlobalConstants.NPS;
                wrapper.value = portfolio.FinPlan__NPS_Invested_Amount__c;
                wrapperRecords.add(wrapper);
            }

            if(portfolio.FinPlan__Ulip_Invested_Amount__c > 0){
                PortfolioOverviewDataWrapper wrapper = new PortfolioOverviewDataWrapper();
                wrapper.id = portfolio.Id;
                wrapper.name = GlobalConstants.ULIP;
                wrapper.value = portfolio.FinPlan__Ulip_Invested_Amount__c;
                wrapperRecords.add(wrapper);
            }

            if(portfolio.FinPlan__Treasury_Bills_Invested_Amount__c > 0){
                PortfolioOverviewDataWrapper wrapper = new PortfolioOverviewDataWrapper();
                wrapper.id = portfolio.Id;
                wrapper.name = GlobalConstants.TREASURYBILL;
                wrapper.value = portfolio.FinPlan__Treasury_Bills_Invested_Amount__c;
                wrapperRecords.add(wrapper);
            }
        }
        return wrapperRecords;
    }

    class PortfolioOverviewDataWrapper{
        @AuraEnabled public String id{get;set;}
        @AuraEnabled public String name{get;set;}
        @AuraEnabled public Decimal value{get;set;}
        PortfolioOverviewDataWrapper(){
            this.id = '';
            this.name = '';
            this.value = 0;
        }
    }
}