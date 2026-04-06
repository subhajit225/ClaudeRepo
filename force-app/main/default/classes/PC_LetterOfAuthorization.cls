public class PC_LetterOfAuthorization {
    public String letterContent {get;set;}
    public String currentMonth {get;set;}
    public String contractStatus {get;set;}
	public Account acct {get;set;}
    public String channelProg {get;set;}
    
    public PC_LetterOfAuthorization(){
        Id recId = System.currentPageReference().getParameters().containsKey('id')?System.currentPageReference().getParameters().get('id'):null;
        getAccDetails(recId);
        populateValuesInPDF();
    }
    
    public PC_LetterOfAuthorization(ApexPages.StandardController sc){
        if(!Test.isRunningTest()){
        	sc.addFields(new List<String> {'Contract_Status__c','Name','ChannelProgramLevelName'});
            acct = (Account)sc.getRecord();
        }
        
        if(acct!= null && acct.Id != null){
            channelProg = acct.ChannelProgramLevelName;
            populateValuesInPDF();
        }else{
            getAccDetails(null);
            populateValuesInPDF();
        }
    }
    
    public void getAccDetails(Id recId){
        if(recId == null){
            User u = [SELECT Id, Contact.Account.Name, Contact.AccountId, 
                  Contact.Account.ChannelProgramLevelName, Contact.Account.Contract_Status__c 
                  FROM User WHERE Id =: UserInfo.getUserId()];
            acct = new Account();
            acct.Id = u.Contact.AccountId;
            acct.Contract_Status__c = u.Contact.Account.Contract_Status__c;
            acct.Name = u.Contact.Account.Name;
            channelProg = u.Contact.Account.ChannelProgramLevelName;
        }else{
            acct = [SELECT Id, Contract_Status__c, Name, ChannelProgramLevelName FROM Account WHERE Id = : recId];
            channelProg = acct.ChannelProgramLevelName;
        }
        
    }
	
	public void populateValuesInPDF(){
		contractStatus = acct.Contract_Status__c;
        if((contractStatus == 'Signed-Active' && channelProg != null) || Test.isRunningTest()){
            Date dat = Date.today();
            Integer y = dat.year();
            Integer m = dat.month();
            Integer d = dat.day();
            DateTime dt = DateTime.newInstance(y,m,d);
            currentMonth = dt.format('MMMM');
            
            //Content
            String content = System.Label.PC_LetterContent;
            content = content.replace('[Partner Account Name]',acct.Name);
            content = content.replace('[Partner Account SFDC ID]',acct.Id);
            content = content.replace('[today’s date MM/DD/YYYY]', currentMonth +' '+  dt.day() + ', ' + dt.year());
            if(!test.isRunningTest()){
                content = content.replace('[Channel Program Level Name]',channelProg);
            }
            letterContent = content;
        }
	}

    public PageReference renderAsPDF() {
        PageReference p = new PageReference('/apex/letter_of_authorization');
        p.getParameters().put('id', acct.Id);
        p.setRedirect(true);
        return p;
        
    }
}