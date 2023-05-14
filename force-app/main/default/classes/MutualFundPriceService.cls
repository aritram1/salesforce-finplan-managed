public with sharing class MutualFundPriceService {

    public static final String INVESTING_FUND_BASE_URL = GlobalConstants.INVESTING_FUND_BASE_URL; // 'https://www.investing.com/funds/'
    public static final String INVESTING_FUND_MATCHING_TEXT = GlobalConstants.INVESTING_FUND_MATCHING_TEXT; // '<span class="arial_26 inlineblock pid-'

    public static Decimal getLatestNAV(String code){
        String endpoint = INVESTING_FUND_BASE_URL + code;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        Httpresponse res = h.send(req);
        String responseBody = res.getBody();
        String strNav = '';
        if(!responseBody.contains(INVESTING_FUND_MATCHING_TEXT)){
            throw new FinPlanException('Price matching tag not present in Payload for MF - ' + code);
        }
        else{
            Integer start = responseBody.indexOf(textToMatch) + textToMatch.length() + 39;
            strNav = responseBody.substring(start, start + 6);
            System.debug('strNav=>' + strNav);
        }
        System.debug('strNav=>' + strNav);
        return Decimal.valueOf(strNav);
    }
}