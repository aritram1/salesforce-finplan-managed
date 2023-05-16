// A public class to hold data for constant string values
public with sharing class GlobalConstants {
    public static final String INVESTING_FUND_BASE_URL = 'https://www.investing.com/funds/';
    public static final String INVESTING_FUND_MATCHING_TEXT = '<span class="arial_26 inlineblock pid-';

    public static final String YAHOO_STOCK_BASE_URL = 'https://query1.finance.yahoo.com/v8/finance/chart/';
    public static final String YAHOO_STOCK_INTERVAL_1DAY = '?interval=1d';

    public static final String HTTP_GET = 'GET';
    public static final String HTTP_POST = 'POST';

    public static final String BOND = 'Bond';
    public static final String EPF = 'EPF';
    public static final String FD = 'FD';
    public static final String MF = 'MF';
    public static final String METAL = 'Metal';
    public static final String PPF = 'PPF';
    public static final String SIP = 'SIP';
    public static final String SMALLCASE = 'SmallCase';
    public static final String STOCK = 'Stock';
    public static final String TREASURYBILL = 'TreasuryBill';
    public static final String ULIP = 'ULIP';
    public static final String NPS = 'NPS';
    public static final String NONE = 'None';

    public static final List<String> ALL_INVESTMENT_TYPES = new List<String>{
        BOND, EPF,  FD, MF, METAL, PPF, SIP, SMALLCASE, STOCK, TREASURYBILL, ULIP, NPS
    };

}