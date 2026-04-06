public class DealREgHomeExtnClass { 
    public String sortOrder {get; set;}
    public String ascDesc {get;set;}
    private integer counter=0;  //keeps track of the offset
    private integer list_size=20; //sets the page size or number of rows
    private String conditions='';
    public integer total_size; //used to show user the total size of the list
    public DealREgHomeExtnClass degExt {get;set;}
    public String searchBy {get;set;}
    public String searchText {get;set;}
    public static Boolean isTriggered = false;
    String partnerAccount;
    Id partnerAccountId;
   
    public DealREgHomeExtnClass(ApexPages.StandardSetController controller) {
    	system.debug('Calling Constructor');
		partnerAccount= '';
    	sortOrder = 'Id';
    	ascDesc = 'ASC';
 		system.debug('UserInfo.getUserID()'+UserInfo.getUserID());
   
		if(UserInfo.getUserType() =='PowerPartner'){
     		User partnerUser = [select id, Name, Contact.Account.Name, Contact.Account.Id from User where ID=:UserInfo.getUserID() limit 1];
     		partnerAccount = partnerUser.Contact.Account.Name;
     		partnerAccountId = partnerUser.Contact.Account.Id;
     		system.debug('partnerAccount--'+partnerAccount);
     		//total_size = [select count() from Deal_Registration__c where Partner__c=: partnerAccount];  
     		//total_size = [select count() from Deal_Registration__c where Partner_Lookup__c=: partnerUser.Contact.Account.Id and createdById=:UserInfo.getUserID()];    //createdByID=:UserInfo.getUserID()]; //set the total size in the constructor
     		total_size = [select count() from Deal_Registration__c where createdById=:UserInfo.getUserID()];   
		} else {
    		partnerAccount = 'Rubrik';
     		system.debug('partnerAccount--'+partnerAccount);
     		Account rubrikAccount = [select Id from Account where Name='Rubrik' Limit 1];
     		partnerAccountId=rubrikAccount.Id;
			total_size = [select count() from Deal_Registration__c where createdById=:UserInfo.getUserID()];  
		}
    }
    
   public Deal_Registration__c[] getDealRegs() {
       system.debug('total_size=>'+total_size);
       if(sortOrder == 'fName'){
           sortOrder = (ascDesc == 'ASC') ? 'FirstName__c' : 'LastName__c';
       } 
      try {
          Deal_Registration__c[] vDealRegList;
          if(searchText == null && sortOrder == 'Id') {
				String query = 'select Id, Name, Owner.Name, Owner.Email, CreatedDate, CreatedById, CreatedBy.LastName, Distributor_Company_Name__c, Company__C,Deal_Registration_Status__c,Partner_Rep__c, Partner_Rep_Email_Address__c, FirstName__c, LastName__c from Deal_Registration__c where createdById=\'' + String.escapeSingleQuotes(UserInfo.getUserID()) + '\' order by ' + String.escapeSingleQuotes(sortOrder) + ' ' + String.escapeSingleQuotes(ascDesc) + ' NULLS LAST limit ' + list_size + ' offset ' + counter;          	
          	 	system.debug('query==? '+query);
              	vDealRegList = Database.query(query);
          } else {
          		searchManagers();          		
            	String query = 'select Id, Owner.Name, Owner.Email, CreatedDate, CreatedById, CreatedBy.LastName, Name,Company__C,Deal_Registration_Status__c,Partner_Rep__c, Partner_Rep_Email_Address__c, FirstName__c, LastName__c,Distributor_Company_Name__c from Deal_Registration__c where (createdById=\''+ String.escapeSingleQuotes(UserInfo.getUserID()) +'\') '+ conditions + ' order by ' + String.escapeSingleQuotes(sortOrder) + ' ' + String.escapeSingleQuotes(ascDesc) + ' NULLS LAST limit ' + list_size + ' offset ' +counter; 
              	system.debug('query=: '+query);
            	vDealRegList = Database.query(query);
            	total_size = vDealRegList.size();
          }
	      
	      if(vDealRegList != null && vDealRegList.size()>0){
	         	system.debug('leads=='+vDealRegList);
	         	return vDealRegList;
         } else {
         		return null;
	      }
	      
      } catch (QueryException e) {
         ApexPages.addMessages(e);   
         return null;
      }
   }
    

   public PageReference Beginning() { //user clicked beginning
      counter = 0;
      return null;
   }

   public PageReference Previous() { //user clicked previous button
      counter -= list_size;
      return null;
   }

   public PageReference Next() { //user clicked next button
      counter += list_size;
      return null;
   }

   public PageReference End() { //user clicked end
      counter = total_size - math.mod(total_size, list_size);
      return null;
   }

   public Boolean getDisablePrevious() { 
      //this will disable the previous and beginning buttons
      if (counter>0) return false; else return true;
   }

   public Boolean getDisableNext() { //this will disable the next and end buttons
       system.debug('counter'+counter);
       system.debug('list_size'+list_size);
       system.debug('total_size'+total_size);
      if (counter + list_size < total_size) return false; else return true;
   }

   public Integer getTotal_size() {
      return total_size;
   }

   public Integer getPageNumber() {
      return counter/list_size + 1;
   }

   public Integer getTotalPages() {
   		Integer totalPages =1;
      	if (math.mod(total_size, list_size) > 0) {
      		totalPages=total_size/list_size + 1; 
      	} else if(total_size/list_size>1){
      		totalPages=total_size/list_size;       
      	}
      	return totalPages;
   }
    
    public List<SelectOption> getsearchByList(){
        List<SelectOption> selOp = new List<SelectOption>();
        //selOp.add(new SelectOption('','Search By'));
        selOp.add(new SelectOption('Company__c','Company'));
        selOp.add(new SelectOption('Name','Name'));
        selOp.add(new SelectOption('FirstName__c','FirstName'));
        selOp.add(new SelectOption('LastName__c','LastName'));
        selOp.add(new SelectOption('Deal_Registration_Status__c','DealReg Status'));
        selOp.add(new SelectOption('Owner.Name','Owner.Name'));
        selOp.add(new SelectOption('Owner.Email','Owner.Email'));
        return selOp;
    }
    
    
    public void searchManagers(){
        system.debug('@@searchBy'+searchBy);
        conditions='';       
        for(SelectOption so : getsearchByList()){
            String item = so.getValue();
            String searchItem = searchText.trim();
            searchItem = String.escapeSingleQuotes(searchItem);
            conditions +=' OR '+ item + ' like \'%' + searchItem + '%\'';
        }
        
        conditions = conditions.removeStart(' OR ');
        conditions = ' AND (' + conditions + ')';
        system.debug('conditions=> '+conditions);
    }
         

}