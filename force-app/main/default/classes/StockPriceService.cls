public with sharing class StockPriceService {

    public static final String YAHOO_STOCK_BASE_URL = GlobalConstants.YAHOO_STOCK_BASE_URL; // 'https://query1.finance.yahoo.com/v8/finance/chart/'
    public static final String YAHOO_STOCK_INTERVAL_1DAY = GlobalConstants.YAHOO_STOCK_INTERVAL_1DAY; // '?interval=1d'
    public static final String HTTP_GET = GlobalConstants.HTTP_GET; //'GET'

    public static Decimal getLatestStockPrice(String code){
        String endpoint =  YAHOO_STOCK_BASE_URL + code + YAHOO_STOCK_INTERVAL_1DAY;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(HTTP_GET);
        Httpresponse res = h.send(req);
        String body = res.getBody();
        YahooStockPriceResponseParser yp = YahooStockPriceResponseParser.parse(body);
        String price = yp.chart.result[0].indicators.quote[0].close[0];
        System.debug('Latest Price retrieved for ' + code + ' : ' + price);
        return Decimal.valueOf(price);
    }   
}