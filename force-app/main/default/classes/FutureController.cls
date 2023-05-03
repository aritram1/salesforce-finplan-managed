public with sharing class FutureController {
    
    @future (callout = true)
    public static void updateMFLatestPrices(){
        System.debug('Inside updateMFLatestPrices');
        List<FinPlan__Fund__c> toBeUpdatedMFs = new List<FinPlan__Fund__c>();
        List<FinPlan__Fund__c> allMFs = [SELECT Id, Name, FinPlan__Latest_NAV__c, FinPlan__Fund_Code__c from FinPlan__Fund__c];
        for(FinPlan__Fund__c mf : allMFs){
            System.debug('Inside MF Loop!');
            Decimal nav = MutualFundPriceService.getLatestNAV(stock.FinPlan__Fund_Code__c);//('HINDUNILVR.NS');
            System.debug('NAV => ' + mf.Name + '=>' + nav);
            toBeUpdatedMFs.add(new FinPlan__Fund__c(
                Id = mf.Id,
                FinPlan__Latest_NAV__c = nav
            ));
        }
        update toBeUpdatedMFs;
        System.debug('toBeUpdatedMFs=>' + toBeUpdatedMFs);
    }

    @Future(callout=true)
    public static void updateStockLatestPrices(){
        System.debug('Inside updateStockLatestPrices');
        List<FinPlan__Stock__c> toBeUpdatedStocks = new List<FinPlan__Stock__c>();
        List<FinPlan__Stock__c> allStocks = [SELECT Id, Name, FinPlan__Ticker_Code__c, FinPlan__Latest_Stock_Price__c from FinPlan__Stock__c];
        for(FinPlan__Stock__c stock : allStocks){
            System.debug('Inside Loop!');
            Decimal price = StockPriceService.getLatestStockPrice(stock.FinPlan__Ticker_Code__c);//('HINDUNILVR.NS');
            System.debug('Price => ' + stock.Name + '=>' + price);
            toBeUpdatedStocks.add(new FinPlan__Stock__c(
                Id = stock.Id,
                FinPlan__Latest_Stock_Price__c = price
            ));
        }
        update toBeUpdatedStocks;
        System.debug('toBeUpdatedStocks=>' + toBeUpdatedStocks);
    }
}