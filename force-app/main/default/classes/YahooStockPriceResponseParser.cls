public class YahooStockPriceResponseParser{
	public cls_chart chart;
	public class cls_chart {
		public cls_result[] result;
		public cls_error error;
	}
	public class cls_result {
		public cls_meta meta;
		//public cls_timestamp[] timestamp;
		public cls_indicators indicators;
	}
	public class cls_meta {
		//public String currency;	//INR
		public String symbol;	//HINDUNILVR.NS
		public String exchangeName;	//NSI
		public String instrumentType;	//EQUITY
		public Integer firstTradeDate;	//820467900
		public Integer regularMarketTime;	//1682675999
		public Integer gmtoffset;	//19800
		public String timezone;	//IST
		public String exchangeTimezoneName;	//Asia/Kolkata
		public Double regularMarketPrice;	//2457.3
		public Double chartPreviousClose;	//2468.95
		public Integer priceHint;	//2
		public cls_currentTradingPeriod currentTradingPeriod;
		public String dataGranularity;	//1d
		public String range;	//1d
		//public cls_validRanges[] validRanges;
	}
	public class cls_currentTradingPeriod {
		public cls_pre pre;
		public cls_regular regular;
		public cls_post post;
	}
	public class cls_pre {
		public String timezone;	//IST
		public Integer start;	//1682653500
		//public Integer end;	//1682653500
		public Integer gmtoffset;	//19800
	}
	public class cls_regular {
		public String timezone;	//IST
		public Integer start;	//1682653500
		//public Integer end;	//1682676000
		public Integer gmtoffset;	//19800
	}
	public class cls_post {
		public String timezone;	//IST
		public Integer start;	//1682676000
		//public Integer end;	//1682676000
		public Integer gmtoffset;	//19800
	}
	// class cls_validRanges {
	// 	public String 0;	//1
	// 	public String 1;	//d
	// }
	//public class cls_timestamp {
	//}
	public class cls_indicators {
		public cls_quote[] quote;
		//public cls_adjclose[] adjclose;
	}
	public class cls_quote {
	    public String[] high;
        public String[] close;
        public String[] open;
        public String[] volume;
        public String[] low;

		// public cls_close[] close;
		// public cls_open[] open;
		// public cls_volume[] volume;
		// public cls_low[] low;
	}
	// public class cls_high {
	// }
	// public class cls_close {
	// }
	// public class cls_open {
	// }
	// public class cls_volume {
	// }
	// public class cls_low {
	// }
	// public class cls_adjclose {
	// 	public cls_adjclose[] adjclose;
	// }
	public class cls_error {
	}
	public static YahooStockPriceResponseParser parse(String json){
		return (YahooStockPriceResponseParser) System.JSON.deserialize(json, YahooStockPriceResponseParser.class);
	}

	/*
    static testMethod void testParse() {
		String json=		'{'+
		'    "chart": {'+
		'        "result": ['+
		'            {'+
		'                "meta": {'+
		'                    "currency": "INR",'+
		'                    "symbol": "HINDUNILVR.NS",'+
		'                    "exchangeName": "NSI",'+
		'                    "instrumentType": "EQUITY",'+
		'                    "firstTradeDate": 820467900,'+
		'                    "regularMarketTime": 1682675999,'+
		'                    "gmtoffset": 19800,'+
		'                    "timezone": "IST",'+
		'                    "exchangeTimezoneName": "Asia/Kolkata",'+
		'                    "regularMarketPrice": 2457.3,'+
		'                    "chartPreviousClose": 2468.95,'+
		'                    "priceHint": 2,'+
		'                    "currentTradingPeriod": {'+
		'                        "pre": {'+
		'                            "timezone": "IST",'+
		'                            "start": 1682653500,'+
		'                            "end": 1682653500,'+
		'                            "gmtoffset": 19800'+
		'                        },'+
		'                        "regular": {'+
		'                            "timezone": "IST",'+
		'                            "start": 1682653500,'+
		'                            "end": 1682676000,'+
		'                            "gmtoffset": 19800'+
		'                        },'+
		'                        "post": {'+
		'                            "timezone": "IST",'+
		'                            "start": 1682676000,'+
		'                            "end": 1682676000,'+
		'                            "gmtoffset": 19800'+
		'                        }'+
		'                    },'+
		'                    "dataGranularity": "1d",'+
		'                    "range": "1d",'+
		'                    "validRanges": ['+
		'                        "1d",'+
		'                        "5d",'+
		'                        "1mo",'+
		'                        "3mo",'+
		'                        "6mo",'+
		'                        "1y",'+
		'                        "2y",'+
		'                        "5y",'+
		'                        "10y",'+
		'                        "ytd",'+
		'                        "max"'+
		'                    ]'+
		'                },'+
		'                "timestamp": ['+
		'                    1682675999'+
		'                ],'+
		'                "indicators": {'+
		'                    "quote": ['+
		'                        {'+
		'                            "high": ['+
		'                                2467.800048828125'+
		'                            ],'+
		'                            "close": ['+
		'                                2457.300048828125'+
		'                            ],'+
		'                            "open": ['+
		'                                2436.050048828125'+
		'                            ],'+
		'                            "volume": ['+
		'                                3761028'+
		'                            ],'+
		'                            "low": ['+
		'                                2419'+
		'                            ]'+
		'                        }'+
		'                    ],'+
		'                    "adjclose": ['+
		'                        {'+
		'                            "adjclose": ['+
		'                                2457.300048828125'+
		'                            ]'+
		'                        }'+
		'                    ]'+
		'                }'+
		'            }'+
		'        ],'+
		'        "error": null'+
		'    }'+
		'}';
		YahooStockPriceJsonParser obj = parse(json);
		System.assert(obj != null);
	}
    */
}