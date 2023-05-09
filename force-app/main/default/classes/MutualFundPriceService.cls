public with sharing class MutualFundPriceService {
    
    public static Decimal getLatestNAV(String code){
        String endpoint = 'https://www.investing.com/funds/' + code;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        Httpresponse res = h.send(req);
        String responseBody = res.getBody();
        String textToMatch = '<span class="arial_26 inlineblock pid-';
        String strNav = '';
        if(!responseBody.contains(textToMatch)){
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