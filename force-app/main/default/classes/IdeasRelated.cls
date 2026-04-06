public with sharing class IdeasRelated {

    public Id ideaID {get; set;}
    public integer limitRecords {get; set;}
    public string relatedString {get; set;}
    public string relatedTitle {get; set;}

        public List<Idea> getRelatedIdeas() {
        
        system.debug('### relatedString ' + relatedString);
        List<String> splitRelatedString = new List<String>{};
        
        if(relatedString!=null) splitRelatedString = relatedString.split(',');
        system.debug('### splitRelatedString ' + splitRelatedString);
        
        Set<String> relatedSet = new set<String>();
        for(String s : splitRelatedString) {
        string cleantitle = s.normalizeSpace();
        relatedSet.add(cleantitle);
        }
        
          if (relatedSet!=null) {
                  system.debug('### relatedSet ' + relatedSet);

             string querystring=' SELECT Body,Categories,CreatedById,CreatedDate,CreatorFullPhotoUrl,CreatorName,CreatorSmallPhotoUrl,Id,';
                    querystring+=' IsDeleted,IsHtml,IsMerged,LastCommentDate,LastCommentId,LastModifiedById,LastModifiedDate,LastReferencedDate,LastViewedDate,';
                    querystring+=' NumComments,Owner__c,ParentIdeaId,RecordTypeId,Related_Ideas__c,Status,SystemModstamp,Title,VoteScore,VoteTotal ';
                    querystring+=' FROM Idea where Title in : relatedSet ';
                    
             querystring+=' order by SystemModstamp desc';
          
             List<Idea> cseCC = Database.query(querystring);
             system.debug('### cseCC.size() ' + cseCC.size());
             return cseCC;
           } 
          return new List<Idea> ();
        }   
    
    
    public List<Idea> getRelatedIdeas2() {
        
        if(ideaId!=null) {
          Idea id = [select id, Title from Idea where id=:ideaId];
          
          relatedTitle = id.Title;
          if(relatedTitle!=null) {
           String likeString = relatedTitle;
           system.debug('### likestring '+ likeString);
           string   querystring= 'SELECT Body,Categories,CreatedById,CreatedDate,CreatorFullPhotoUrl,CreatorName,CreatorSmallPhotoUrl,Id,';
                    querystring+=' IsDeleted,IsHtml,IsMerged,LastCommentDate,LastCommentId,LastModifiedById,LastModifiedDate,LastReferencedDate,LastViewedDate,';
                    querystring+=' NumComments,Owner__c,ParentIdeaId,RecordTypeId,Related_Ideas__c,Status,SystemModstamp,Title,VoteScore,VoteTotal ';
                    querystring+=' FROM Idea where Related_Ideas__c Like \'%'+String.escapeSingleQuotes(likeString)+'%\'';

             querystring+=' and id !=:ideaID order by SystemModstamp desc';
        
             List<Idea> cseCC = Database.query(querystring);
             system.debug('### cseCC.size() ' + cseCC.size());
             return cseCC;
           } 
           }
          return new List<Idea> ();
        }   

    
    

}