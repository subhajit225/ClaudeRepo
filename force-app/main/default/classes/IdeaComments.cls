public without sharing class IdeaComments {

    public Id ideaID {get; set;}
    public integer limitRecords {get; set;}

        public List<IdeaComment> getIdeaComments() {
          if (ideaID != null) {
        string querystring='SELECT CommentBody,CommunityId,CreatedById,CreatedBy.Name, CreatedBy.CommunityNickName,CreatedDate,CreatorFullPhotoUrl,CreatorName,CreatorSmallPhotoUrl,Id,IdeaId,IsDeleted,IsHtml,SystemModstamp,UpVotes FROM IdeaComment where IdeaId = :ideaId';
             querystring+=' order by SystemModstamp desc';
             if(limitRecords!=null) querystring+=' limit :limitRecords ';
             List<IdeaComment> cseCC = Database.query(querystring);
             return cseCC;
      }
          return new List<IdeaComment> ();
  }
}