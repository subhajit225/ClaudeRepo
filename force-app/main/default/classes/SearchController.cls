public with sharing class SearchController{

     //Page Size
     private Static Final Integer PAGE_NUMBER = 10;
     
     //Search String used in ArticleList tag
     public String searchstring { get; set; }
     public String searchText {get; set;}
     public String workspaceID {get; set;} 
     public string scope {get; set;}
     public string pagescope {get; set;}
     public string usertype {get; set;}
     public integer kaSizes {get; set;}
     
     public String getworkspaceID() {
          scope = pagescope!=null ? pagescope : ApexPages.currentPage().getParameters().get('scope');
          return workspaceID = scope == null ? null : scope == 'Technical' ? label.technicalworkspace : scope == 'Marketing' ? label.marketingworkspace : scope == 'Sales' ? label.salesworkspace : null ;
       }
     
     public string getuserType() {
        usertype = Util.UserType;
        return usertype;
     }   
     
       String urlscope;
       List<Idea> iresults;
       List<Node__c> nResults;   
       List<Case> cresults;  
       List<Releases__c> rResults;
        
       List<ContentVersion> contentdocs;
       List<Incentives__c> incents;
       List<CCR__c> ccrResults;
       List<Lead> lResults;

        public List<Idea> getiResults() {
          return iresults;
       }
       
       public List<Case> getcResults() {
          return cresults;
       }


       public List<Node__c> getnResults() {
          return nResults;
       }   

       public List<Releases__c> getrResults() {
          return rResults;
       }   

       public List<ContentVersion> getContentdocs() {
                return Contentdocs;
       }   

       public List<Incentives__c> getincents() {
                return incents;
       }  

       public List<CCR__c> getccrResults() {
                return ccrResults;
       } 

       public List<Lead> getlResults() {
                return lResults;
       }       

            
       public String getSearchText() {
          return searchText;
       }
    
       public void setSearchText(String s) {
        searchText = s;
       }

       public String geturlscope() {
          return scope;
       }
     
     public SearchController() {
        kasizes=0;
        getuserType();
        urlscope = ApexPages.currentPage().getParameters().get('scope');
        workspaceID = urlscope == null ? null : urlscope == 'Technical' ? label.technicalworkspace : urlscope == 'Marketing' ? label.marketingworkspace : urlscope == 'Sales' ? label.salesworkspace : null ;
        
        searchstring = searchstring==null && ApexPages.CurrentPage().getParameters().get('search')!=null ? ApexPages.CurrentPage().getParameters().get('search') : '';
        searchText = searchstring!=null ? searchstring : ApexPages.CurrentPage().getParameters().get('search')!=null ? ApexPages.CurrentPage().getParameters().get('search') : '';
        
        String qryString = 'SELECT Id, title, UrlName, LastPublishedDate,LastModifiedById FROM KnowledgeArticleVersion WHERE (PublishStatus = \'online\' and Language = \'en_US\')';
        List<KnowledgeArticleVersion> articleList= Database.query(qryString);
        maxSize = articleList.size() ;
     
     
        if (searchText == null) searchText = '';
        if (searchText.length() >= 2) {
           
        }   
     
     }
     
    public PageReference doSearchOnload() {
        getuserType();
        getworkspaceID();
        urlscope = ApexPages.currentPage().getParameters().get('scope');
        workspaceID = urlscope == null ? null : urlscope == 'Technical' ? label.technicalworkspace : urlscope == 'Marketing' ? label.marketingworkspace : urlscope == 'Sales' ? label.salesworkspace : null ;

        searchText = ApexPages.CurrentPage().getParameters().get('search')==null ? '' : ApexPages.CurrentPage().getParameters().get('search');

        if (searchText.length() < 2 || searchText == null) {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Search string must be at least 2 or more characters.'));          
            return null;    
        }
        
       system.debug('### querystring '+ searchText);
       String queryText = '%' + searchText + '%';
       iresults = usertype=='partner' ? null : (List<Idea>)[FIND :searchstring RETURNING Idea(CreatedDate,Title,Status,Categories,VoteTotal,id ORDER BY VoteTotal desc) LIMIT 10][0];
       cresults = usertype=='partner' ? null : [select Id, Contact.Id, Contact.Name, Priority, Type, CaseNumber, CreatedDate, ClosedDate, Status, Subject from Case where (Subject LIKE :queryText or CaseNumber LIKE :queryText)  ORDER BY CreatedDate LIMIT 10];         
       nresults = usertype=='partner' ? null : [select Id,Name, cluster__r.Name, cluster__r.software_version__c from Node__c where (cluster__r.Name LIKE :queryText OR Name LIKE :queryText OR cluster__r.software_version__c LIKE :queryText) ORDER BY CreatedDate LIMIT 10];        
       rresults = usertype=='partner' ? null : [select Id,Name, Release_Type__c, Version__c, Release_Date__c  from Releases__c where (Name LIKE :queryText OR Version__c LIKE :queryText) and Release_Type__c = 'Generally Available' ORDER BY CreatedDate LIMIT 10];        
       incents = usertype!='partner' ? null : [select Id,Name from Incentives__c where Name LIKE :queryText ORDER BY CreatedDate LIMIT 10];        
       ccrResults = usertype!='partner' ? null : [select Id,Name, CCR_Type__c, CreatedDate, User__c from CCR__c where Name LIKE :queryText ORDER BY CreatedDate LIMIT 10];        
       lresults = usertype!='partner' ? null : [select Id,Name,Status,Company,Email,LeadSource,CreatedDate from Lead where (Name LIKE :queryText OR email LIKE :queryText OR Company LIKE :queryText) ORDER BY CreatedDate LIMIT 10];        
       
       String queryContentString = 'select ';
              queryContentString += 'OwnerId, Title, ContentDocumentId, FileType, CreatedDate, CreatedBy.Name ';
              queryContentString += ' from ContentVersion where IsLatest=true ';
              if(scope!=null) queryContentString += ' and ContentDocument.ParentId = :workspaceId ';
              queryContentString += ' and (Description LIKE :queryText OR Title LIKE :queryText) LIMIT 5 ';

       contentdocs = usertype=='partner' ? database.query(queryContentString) : null;

       caseSize = cResults!=null ? cResults.size() : 0;
       ideaSize = iResults!=null ? iResults.size() : 0;
       relSize = rResults!=null ? rResults.size() : 0;
       nodeSize = nResults!=null ? nResults.size() : 0;
       contentSize = contentdocs!=null ? contentdocs.size() : 0;
       leadsize = lresults!=null ? lresults.size() : 0;
       ccrsize = ccrResults!=null ? ccrResults.size() : 0;
       incentsize = incents!=null ? incents.size() : 0;
       

       
       return null;
       }
     
      public PageReference doSearch() {
        getuserType();
        getworkspaceID();
        searchText = searchstring ;

        if (searchText.length() < 2 || searchText == null) {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Search string must be at least 2 or more characters.'));          
            return null;    
        }
        
       system.debug('### querystring '+ searchText);
       String queryText = '%' + searchText + '%';
       iresults = usertype=='partner' ? null : (List<Idea>)[FIND :searchstring RETURNING Idea(CreatedDate,Title,Status,Categories,VoteTotal,id ORDER BY VoteTotal desc) LIMIT 10][0];
       cResults = usertype=='partner' ? null : [select Id, Contact.Id, Contact.Name, Priority, Type, CaseNumber, CreatedDate, ClosedDate, Status, Subject from Case where (Subject LIKE :queryText or CaseNumber LIKE :queryText) ORDER BY CreatedDate LIMIT 10];         
       nResults = usertype=='partner' ? null : [select Id,Name, cluster__r.Name, cluster__r.software_version__c from Node__c where (cluster__r.Name LIKE :queryText OR Name LIKE :queryText OR cluster__r.software_version__c LIKE :queryText) ORDER BY CreatedDate LIMIT 10];        
       rResults = usertype=='partner' ? null : [select Id,Name, Release_Type__c, Version__c, Release_Date__c  from Releases__c where (Name LIKE :queryText OR Version__c LIKE :queryText) ORDER BY CreatedDate LIMIT 10];        
       incents = usertype!='partner' ? null : [select Id,Name from Incentives__c where Name LIKE :queryText ORDER BY CreatedDate LIMIT 10];        
       ccrResults = usertype!='partner' ? null : [select Id,Name, CCR_Type__c, CreatedDate, User__c from CCR__c where Name LIKE :queryText ORDER BY CreatedDate LIMIT 10];        
       lresults = usertype!='partner' ? null : [select Id,Name,Status,Company,Email,LeadSource,CreatedDate from Lead where (Name LIKE :queryText OR email LIKE :queryText OR Company LIKE :queryText) ORDER BY CreatedDate LIMIT 10];        

       String qryString = 'SELECT Id, title, UrlName, LastPublishedDate,LastModifiedById FROM KnowledgeArticleVersion WHERE (PublishStatus = \'online\' and Language = \'en_US\')';
       List<KnowledgeArticleVersion> articleList= Database.query(qryString);
       kaSizes = articleList.size() ;

       String queryContentString = 'select ';
              queryContentString += 'OwnerId, Title, ContentDocumentId, FileType, CreatedDate, CreatedBy.Name ';
              queryContentString += ' from ContentVersion where IsLatest=true ';
              if(scope!=null) queryContentString += ' and ContentDocument.ParentId = :workspaceId ';
              queryContentString += ' and (Description LIKE :queryText OR Title LIKE :queryText) LIMIT 5 ';

       contentdocs = usertype=='partner' ? database.query(queryContentString) : null;
       
       
       caseSize = cResults!=null ? cResults.size() : 0;
       ideaSize = iResults!=null ? iResults.size() : 0;
       relSize = rResults!=null ? rResults.size() : 0;
       nodeSize = nResults!=null ? nResults.size() : 0;
       contentSize = contentdocs!=null ? contentdocs.size() : 0;
       leadsize = lresults!=null ? lresults.size() : 0;
       ccrsize = ccrResults!=null ? ccrResults.size() : 0;
       incentsize = incents!=null ? incents.size() : 0;
       
        PageReference redirectPage = Page.UnifiedSearch;
        redirectPage.setRedirect(true);
        redirectPage.getParameters().put('search',searchText);
        return redirectPage;
       }
     
     
     //Keeps track of current page & max size of article list
     Integer currentPage = 1;
     Integer maxSize = 1;
     Integer caseSize = 0;
     Integer relSize = 0;
     Integer ideaSize = 0;
     Integer nodeSize = 0;
     Integer contentSize = 0;
     Integer leadsize = 0;
     Integer ccrsize = 0;
     Integer incentsize = 0;

     // Returns whether we need to see previous button or not
     public boolean getPrevRequired() {
      return currentPage > 1;
     }
    
     // Returns whether we need to see next button or not
     public boolean getNextRequired() {
      return currentPage * PAGE_NUMBER < maxSize;
     }
     
     //Returns current page number 
     public Decimal getCurrentPageNumber() {
      return this.currentPage;
     }

 
     public Integer getkaSize() {
          return kaSizes;
       } 
 
     public Integer getiSize() {
          return ideaSize;
       }

     public Integer getcSize() {
          return caseSize;
       }

     public Integer getrSize() {
          return relSize;
       }

     public Integer getnSize() {
          return nodeSize;
       }

     public Integer getcontentSize() {
          return contentSize;
       }

     public Integer getleadsize() {
          return leadsize;
       }

     public Integer getccrsize() {
          return ccrsize;
       }     
       
     public Integer getincentsize() {
          return incentsize;
       }       

     //action for next click
     public PageReference next() {
      if(maxSize > this.currentPage * PAGE_NUMBER) {
       this.currentPage = this.currentPage + 1;
      }
      return null;
     }    
     
     //action for previous click
     public PageReference previous() {        
      if(this.currentPage > 1)
       this.currentPage = this.currentPage - 1;
      return null;
     }
    

}