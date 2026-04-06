public class EmailAlertJSONParser {
    public class EntityDefinition {
		public Attributes attributes {get;set;} 
		public String DeveloperName {get;set;} 
	}
	
	public Integer size {get;set;} 
	public Integer totalSize {get;set;} 
	public Boolean done {get;set;} 
	public Object queryLocator {get;set;} 
	public String entityTypeName {get;set;} 
	public List<Records> records {get;set;} 

	public class Attributes {
		public String type {get;set;} 
		public String url {get;set;} 	
	}
	
	public class Records {
		public Attributes attributes {get;set;} 
		public String Id {get;set;} 
		public String EntityDefinitionId {get;set;} 
		public EntityDefinition EntityDefinition {get;set;} 
		public String DeveloperName {get;set;} 
		public String CcEmails {get;set;} 
        public String SenderType {get;set;} 
        public String TemplateId {get;set;} 
        public String Description {get;set;} 
	}
}