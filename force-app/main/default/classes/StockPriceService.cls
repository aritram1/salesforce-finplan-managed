public with sharing class StockPriceService {
    public static Decimal getLatestStockPrice(String code){
        String endpoint = 'https://query1.finance.yahoo.com/v8/finance/chart/' + code + '?interval=1d';
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        Httpresponse res = h.send(req);
        String body = res.getBody();
        YahooStockPriceResponseParser yp = YahooStockPriceResponseParser.parse(body);
        String price = yp.chart.result[0].indicators.quote[0].close[0];
        System.debug('Latest Price retrieved for ' + code + ' : ' + price);
        return Decimal.valueOf(price);
    }   
}