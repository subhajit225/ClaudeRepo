/*
* Class Name :- CaseSugestionParser
* Author :- Shiva Sharma
* Created Date :- 27-04-2018
* Description : This Class is result Wrapper Parser class from Search Unify Component.
* 
// ********************Change Logs *****************************************************************************
* 
* Modified By          Date        Description 
* 
* 
* 
// ********************Change Logs Ends*************************************************************************
*/
global class CaseSugestionParser {

	
	
	public class Hits {
		public String href {get;set;} 
		public String icon {get;set;} 
		public Highlight highlight {get;set;} 
		public Double x_score {get;set;} // in json: _score
		public String x_id {get;set;} // in json: _id

		public Hits(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'href') {
							href = parser.getText();
						} else if (text == 'icon') {
							icon = parser.getText();
						} else if (text == 'highlight') {
							highlight = new Highlight(parser);
						} else if (text == '_score') {
							x_score = parser.getDoubleValue();
						} else if (text == '_id') {
							x_id = parser.getText();
						} else {
							System.debug(LoggingLevel.WARN, 'Hits consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public class Highlight {
		public List<String> TitleToDisplayString {get;set;} 
		public List<String> TitleToDisplay {get;set;}  

		public Highlight(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'TitleToDisplayString') {
							TitleToDisplayString = arrayOfString(parser);
						} else if (text == 'TitleToDisplay') {
							TitleToDisplay = arrayOfString(parser);
						}else {
							System.debug(LoggingLevel.WARN, 'Highlight consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public String searchCallFail {get;set;} 
	public Boolean searchDownStatus {get;set;} 
	public String message {get;set;} 
	public List<AggregationsArray> aggregationsArray {get;set;} 
	public Result result {get;set;} 

	public CaseSugestionParser(JSONParser parser) {
		while (parser.nextToken() != System.JSONToken.END_OBJECT) {
			if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
				String text = parser.getText();
				if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
					if (text == 'searchCallFail') {
						searchCallFail = parser.getText();
					} else if (text == 'searchDownStatus') {
						searchDownStatus = parser.getBooleanValue();
					} else if (text == 'message') {
						message = parser.getText();
					} else if (text == 'aggregationsArray') {
						aggregationsArray = arrayOfAggregationsArray(parser);
					} else if (text == 'result') {
						result = new Result(parser);
					} else {
						System.debug(LoggingLevel.WARN, 'JSON2Apex consuming unrecognized property: '+text);
						consumeObject(parser);
					}
				}
			}
		}
	}
	
	public class Values {
		public Integer value {get;set;} 
		public String Contentname {get;set;} 
		public String displayName {get;set;} 

		public Values(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'value') {
							value = parser.getIntegerValue();
						} else if (text == 'Contentname') {
							Contentname = parser.getText();
						} else if (text == 'displayName') {
							displayName = parser.getText();
						} else {
							System.debug(LoggingLevel.WARN, 'Values consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	
	
	
	
	public class Result {
		public List<Hits> hits {get;set;} 
		public Double max_score {get;set;} 
		public Integer total {get;set;} 

		public Result(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'hits') {
							hits = arrayOfHits(parser);
						} else if (text == 'max_score') {
							max_score = parser.getDoubleValue();
						} else if (text == 'total') {
							total = parser.getIntegerValue();
						} else {
							System.debug(LoggingLevel.WARN, 'Result consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	
	
	public class AggregationsArray {
		public String label {get;set;} 
		public List<Values> values {get;set;} 
		public String key {get;set;} 
		public Integer order {get;set;} 

		public AggregationsArray(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'label') {
							label = parser.getText();
						} else if (text == 'values') {
							values = arrayOfValues(parser);
						} else if (text == 'key') {
							key = parser.getText();
						} else if (text == 'order') {
							order = parser.getIntegerValue();
						} else {
							System.debug(LoggingLevel.WARN, 'AggregationsArray consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	
	public static CaseSugestionParser parse(String json) {
		System.JSONParser parser = System.JSON.createParser(json);
		return new CaseSugestionParser(parser);
	}
	
	public static void consumeObject(System.JSONParser parser) {
		Integer depth = 0;
		do {
			System.JSONToken curr = parser.getCurrentToken();
			if (curr == System.JSONToken.START_OBJECT || 
				curr == System.JSONToken.START_ARRAY) {
				depth++;
			} else if (curr == System.JSONToken.END_OBJECT ||
				curr == System.JSONToken.END_ARRAY) {
				depth--;
			}
		} while (depth > 0 && parser.nextToken() != null);
	}
	
    private static List<Values> arrayOfValues(System.JSONParser p) {
        List<Values> res = new List<Values>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new Values(p));
        }
        return res;
    }



    


    private static List<Hits> arrayOfHits(System.JSONParser p) {
        List<Hits> res = new List<Hits>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new Hits(p));
        }
        return res;
    }



    private static List<AggregationsArray> arrayOfAggregationsArray(System.JSONParser p) {
        List<AggregationsArray> res = new List<AggregationsArray>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new AggregationsArray(p));
        }
        return res;
    }






    private static List<String> arrayOfString(System.JSONParser p) {
        List<String> res = new List<String>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            String str = p.getText();            
            res.add(str);
        }
        //System.assert(false,res);
        return res;
    }


    public class caseWrapper{
        public String href {get;set;} 
		public String icon {get;set;} 
		public String caseNumber {get;set;} 
        public caseWrapper(String icon,String baseUrl , Case cs){
            this.href = baseUrl+cs.id;
            this.icon = icon;
            this.caseNumber = cs.CaseNumber+' ('+cs.Status+') - '+cs.Subject;
        }
    }
}