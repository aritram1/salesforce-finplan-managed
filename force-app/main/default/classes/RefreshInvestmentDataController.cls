public with sharing class RefreshInvestmentDataController {
    
    public static void refresh(){
        try{
            refreshMFData();
            refreshStockData();
        }
        catch(Exception e){
            Logger.logError(e);
        }
    }

    public static void refreshMFData(){
        List<FinPlan__Fund__c> toBeUpdatedFunds = new List<FinPlan__Fund__c>();
        List<FinPlan__Fund__c> allMF = [SELECT Id, Name, FinPlan__Latest_NAV__c, FinPlan__Google_Code__c, FinPlan__Total_Units__c, FinPlan__Total_Invested_Amount__c, (SELECT Id, FinPlan__MF_Buy_Units__c, FinPlan__Amount__c from Investment_Transactions__r) from FinPlan__Fund__c];
        for(FinPlan__Fund__c mf : allMF){
            Double totalAmount = 0;
            Double totalUnits = 0;
            for(FinPlan__Investment_Transaction__c fit : mf.Investment_Transactions__r){
                totalAmount = totalAmount + fit.FinPlan__Amount__c;
                totalUnits = totalUnits + fit.FinPlan__MF_Buy_Units__c;
            }
            toBeUpdatedFunds.add(new FinPlan__Fund__c(
                Id = mf.Id,
                FinPlan__Total_Invested_Amount__c = totalAmount,
                FinPlan__Total_Units__c = totalUnits//,
                //FinPlan__Latest_NAV__c = MutualFundPriceService.getLatestNAV(mf.FinPlan__Latest_NAV__c)
            ));
            System.debug(mf.Name + '=>' + totalAmount);
        }
        System.debug('toBeUpdatedFunds=>' + toBeUpdatedFunds);
        update toBeUpdatedFunds;
    }

    public static void refreshStockData(){
        List<FinPlan__Stock__c> toBeUpdatedStocks = new List<FinPlan__Stock__c>();
        List<FinPlan__Stock__c> allStocks = [SELECT Id, Name, FinPlan__Ticker_Code__c, FinPlan__Latest_Stock_Price__c, FinPlan__Total_Units__c, FinPlan__Total_Invested_Amount__c, (SELECT Id, FinPlan__Stock_Units__c, FinPlan__Amount__c from Investment_Transactions__r) from FinPlan__Stock__c];
        for(FinPlan__Stock__c stock : allStocks){
            Double totalAmount = 0;
            Double totalUnits = 0;
            for(FinPlan__Investment_Transaction__c fit : stock.Investment_Transactions__r){
                totalAmount = totalAmount + fit.FinPlan__Amount__c;
                totalUnits = totalUnits + fit.FinPlan__Stock_Units__c;
            }
            toBeUpdatedStocks.add(new FinPlan__Stock__c(
                Id = stock.Id,
                FinPlan__Total_Invested_Amount__c = totalAmount,
                FinPlan__Total_Units__c = totalUnits//,
                //FinPlan__Latest_Stock_Price__c = StockPriceService.getLatestStockPrice(stock.FinPlan__Ticker_Code__c)
            ));
            System.debug(stock.Name + '=>' + totalAmount);
        }
        System.debug('toBeUpdatedStocks=>' + toBeUpdatedStocks);
        update toBeUpdatedStocks;
    }

    // public static void refreshData(){}

}