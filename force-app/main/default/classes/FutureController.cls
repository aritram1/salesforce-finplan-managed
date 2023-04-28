public with sharing class FutureController {
    
    @future
    public static void updateMFLatestPrices(){
        System.debug('Inside updateMFLatestPrices');
    }

    @Future(callout=true)
    public static void updateStockLatestPrices(){
        System.debug('Inside updateMFLatestPrices');
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