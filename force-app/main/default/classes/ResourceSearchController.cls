public with sharing class ResourceSearchController {

     public string workspaceId;
     public string scope {get; set;}
     public string pagescope {get; set;}
     
       public String getworkspaceID() {
          scope = pagescope!=null ? pagescope : ApexPages.currentPage().getParameters().get('scope');
          return workspaceID = scope == null ? null : scope == 'Technical' ? label.technicalworkspace : scope == 'Marketing' ? label.marketingworkspace : scope == 'Sales' ? label.salesworkspace : null ;
       }

        
      public List<ContentVersion> getFeatured() {    
      getworkspaceID();
      String queryContentString = 'select ';
              queryContentString += 'OwnerId, Title, ContentDocumentId, FileType, CreatedBy.Name, CreatedDate ';
              queryContentString += ' from ContentVersion where IsLatest=true and FeaturedContentBoost>0 ';
              if(scope!=null) queryContentString += ' and ContentDocument.ParentId = :workspaceId ';
              queryContentString += ' LIMIT 5 ';

              List<ContentVersion> featuredList = database.query(queryContentString);

          if (featuredList.isEmpty()) {
            return null;
          } 
          return featuredList;
       }


      public List<ContentVersion> getRecent() {
      
      getworkspaceID();
           
           String queryContentString = 'select ';
              queryContentString += 'OwnerId, Title, ContentDocumentId, CreatedBy.Name, FileType, CreatedDate ';
              queryContentString += ' from ContentVersion where IsLatest=true ';
              if(scope!=null) queryContentString += ' and ContentDocument.ParentId = :workspaceId ';
              queryContentString += ' order by ContentModifiedDate desc LIMIT 5 ';

              List<ContentVersion> recentList = database.query(queryContentString);

          if (recentList.isEmpty()) {
            return null;
          } 
          return recentList;
       }

    public List<ContentVersion> getAll() {
      
      getworkspaceID();
           
           String queryContentString = 'select ';
              queryContentString += 'OwnerId, Title, ContentDocumentId, CreatedBy.Name, FileType, CreatedDate, ContentModifiedDate';
              queryContentString += ' from ContentVersion where IsLatest=true ';
              if(scope!=null) queryContentString += ' and ContentDocument.ParentId = :workspaceId ';
              queryContentString += ' order by Title asc LIMIT 100 ';

              List<ContentVersion> recentList = database.query(queryContentString);

          if (recentList.isEmpty()) {
            return null;
          } 
          return recentList;
       }


}