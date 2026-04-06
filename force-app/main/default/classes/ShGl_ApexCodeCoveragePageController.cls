//Display Apex Class and Trigger Code Coverage in a readable table format.
public without sharing class ShGl_ApexCodeCoveragePageController {
    private String instance;
    transient public String soql { get; set; }
    transient public String retJSON { get; set; }
    
    public List<Coverage> coverages { get; set; }
    public TotalCoverage tc {get;set;}
    
    //determine what URL prefix we're removing, c for unmanaged, soql-explain for managed.
    private static String currentPrefix{
        get{
            String prefix = ShGl_ApexCodeCoveragePageController.class.getName().substringBefore('ShGl_ApexCodeCoveragePageController');
            if(prefix.endsWith('.'))
                prefix = prefix.removeEnd('.');
            if(String.isEmpty(prefix)){
                return 'c';
            }else{
                return prefix.replaceAll('_','-'); //underscores in namespaces are converted to hypens in domain names
            }
        }
    }
    
    //visualforce domains aren't API-enabled, so we need to figure out what the proper endpoint
    public ShGl_ApexCodeCoveragePageController() {
        // retrieve the instance used to create endpoint URL
        instance = URL.getSalesforceBaseUrl().getHost();

        // check for my domain
        if (instance.contains('--'+currentPrefix+'.') && !instance.startsWith(currentPrefix+'.')) {
            instance = instance.replace('--'+currentPrefix, '');
            instance = instance.replace('.visual.force.com', '.my.salesforce.com');
        } else {
            // strip out the starting 'c.' values
            instance = instance.removeStart(currentPrefix+'.');
            instance = instance.replace('.visual.force.com', '.my.salesforce.com');
        }

        instance = 'https://' + instance;
        if(!runningInASandbox()) {
            instance = Label.SFDC_URL;
        }

        //instance = 'https://test.salesforce.com';
        try {
            HTTPRequest req = new HTTPRequest();
            req.setHeader('Authorization','Bearer ' + UserInfo.getSessionID());
            req.setHeader('Content-Type','application/json');
            soql = 'SELECT '+
                'ApexClassorTriggerId, ApexClassorTrigger.Name, NumLinesCovered, NumLinesUncovered '+
                'FROM ApexCodeCoverageAggregate';
            req.setEndpoint(instance + '/services/data/v31.0/tooling/query/?q=' + EncodingUtil.urlEncode(soql, 'UTF-8'));
            req.setMethod('GET');
            
            Http h = new Http();
            HttpResponse res = h.send(req);
            String status = res.getStatus();
            Integer statusCode = res.getStatusCode();
            retJSON = res.getBody();
            coverages = new List<Coverage>(); 
            tc = new TotalCoverage();
            tc.NumLinesCovered = 0;
            tc.NumLinesUncovered = 0;
            String text = '';
            
            // check if we had an error
            if (statusCode != 200) { 
                for(CoverageErrorResponse error : (List<CoverageErrorResponse>) JSON.deserialize(retJSON, List<CoverageErrorResponse>.class)){ 
                    String err = error.errorCode +' '+ error.message;
                    
                    ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, status + ' - ' + err);
                    ApexPages.addMessage(msg);
                }
            }
            else {           
                CoverageResponse response = (CoverageResponse) JSON.deserialize(retJSON, CoverageResponse.class);
                List<sequencer> coverageSoqL = New List<sequencer>();
                for(Coverage c : response.records) 
                	  coverageSoqL.add(new sequencer(c));
                coverageSoqL.sort();
                for(sequencer cs : coverageSoqL) {
                	coverages.add(cs.c);
                	if(cs.c.NumLinesCovered!=null) tc.NumLinesCovered = tc.NumLinesCovered + cs.c.NumLinesCovered;
                	if(cs.c.NumLinesUncovered!=null) tc.NumLinesUncovered = tc.NumLinesUncovered + cs.c.NumLinesUncovered;
                }
            }   
        } catch(Exception e) {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Error - ' + e.getMessage());
            ApexPages.addMessage(msg);
        }
        System.debug(coverages);
        
    }    
    
    public class CoverageErrorResponse{
        String errorCode {get; set;}
        String message {get; set;}
    }
    
    public class CoverageResponse{
        public List<Coverage> records {get; set;}
    }
    
    public class TotalCoverage {
    	public Integer NumLinesCovered { get; set; }
        public Integer NumLinesUncovered { get; set; }
        public Decimal getCodeCoveragePercentage() {
        	if(NumLinesCovered==null || NumLinesUncovered==null) return 0.00;
        	Decimal totalLines = NumLinesCovered+NumLinesUncovered;
        	if(totalLines==0) return 0.00;
	        return ((Decimal)(NumLinesCovered/totalLines)*100).setScale(2);
	    }
    }
    
    public class Coverage {
        //public String ApexTestClassId { get; set; }
        //public String TestMethodName { get; set; }
        public String ApexClassorTriggerId { get; set; }
        public ApexClassOrTriggerClass ApexClassOrTrigger {get;set;}
        public Integer NumLinesCovered { get; set; }
        public Integer NumLinesUncovered { get; set; }
        
        public Decimal getCodeCoveragePercentage() {
        	if(NumLinesCovered==null || NumLinesUncovered==null) return 0.00;
        	Decimal totalLines = NumLinesCovered+NumLinesUncovered;
        	if(totalLines==0) return 0.00;
	        return ((Decimal)(NumLinesCovered/totalLines)*100).setScale(2);
	    }
	    
        //public List<List<Integer>> Coverage { get; set;}
    }
    
    public class ApexClassOrTriggerClass {
    	public String Name {get;set;}	
    }
    
    public class sequencer implements Comparable {
        public Coverage c;
        
        public sequencer(Coverage c1) {
            c = c1;
        }
        
        public Integer compareTo(Object compareTo) {
        	sequencer cS = (sequencer)compareTo;
            Integer returnValue = 0;
            if (c.getCodeCoveragePercentage() > cS.c.getCodeCoveragePercentage()) {
                // Set return value to a positive value. 
                returnValue = 1;
            } else if (c.getCodeCoveragePercentage() < cS.c.getCodeCoveragePercentage()) {
                // Set return value to a negative value. 
                returnValue = -1;
            }
            return returnValue;  
        }
    }
    
    public static Boolean runningInASandbox() {
        return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }
}