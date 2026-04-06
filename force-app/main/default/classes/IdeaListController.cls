public class IdeaListController{
    public static string ideaSql =  'SELECT Id, CreatorName, Title, IsDeleted , Categories, CreatedDate, lastmodifieddate, CreatedById, Idea.NumComments,CommunityId, Body,CreatedBy.username , CreatedBy.name, CreatorSmallPhotoUrl, createdby.lastname, Status, voteTotal , voteScore, ParentIdeaId from idea '; 
    
    
    @AuraEnabled
    public static list<IdeasWrapperPost> getIdeas(String zoneId , String selectedfilter, String selectedCateg){
        List<IdeasWrapperPost> wpp = new List<IdeasWrapperPost>();
        string fetchideaSoql = '';
        string sorting ='';
        string ideaType ='';
        // string whereis = ideaSql +'where  Id IN :';
        
        Map<id, vote> voteMap = new Map<id, vote>();
        set<Id> votedIdea = new set<Id>();
        List<Vote> votes = [SELECT Id, ParentId, Type, CreatedById FROM Vote where parent.type = 'idea' AND CreatedById =:UserInfo.getUserId()];
        system.debug('fil==' + votes + votes.size());
        for(vote vt : votes){
            if(vt.CreatedById ==  UserInfo.getUserId()){
                voteMap.put(vt.parentid, vt); 
                votedIdea.add(vt.ParentId);
            } 
        }
        ideaType = 'WHERE Id != null ';
        if(selectedCateg != '' && selectedCateg != null ){
            ideaType = 'WHERE Categories includes (\''+selectedCateg +'\') ';
        }
        if(selectedCateg == 'All'){
            ideaType = 'WHERE Id != null ';
        }
        if(selectedfilter == 'Browse All Ideas'){
              sorting ='ORDER BY CreatedDate  DESC ';
        }else{
            if(selectedfilter == 'Popular Ideas'){
                sorting ='ORDER BY voteScore  DESC ';
            }
            if(selectedfilter == 'Recent Ideas'){
                sorting = ' ORDER BY  CreatedDate DESC  ';
            }
            if(selectedfilter == 'Recent Comments'){
                sorting = ' ORDER BY  LastCommentDate   DESC NULLS LAST ';
            }
            if(selectedfilter == 'Top Ideas'){
                sorting = ' ORDER BY  VoteTotal   DESC  ';
            }
            if(selectedfilter == 'My Ideas'){
                ideaType += 'AND CreatedById =\''+ UserInfo.getUserId()+'\' ORDER BY CreatedDate  DESC';
            }
         
            if(selectedfilter == 'My Votes'){
                sorting = 'AND Id IN :votedIdea ORDER BY CreatedDate  DESC';
            }
        }
        system.debug('fil==' + selectedfilter);
        
        /*  if(selectedfilter == 'Popular Ideas'){
List<Idea> ideasList = [select id,title,status,body,createdby.name,createddate,NumComments,Categories,VoteTotal from Idea  ORDER BY  VoteTotal DESC];
return ideasList;
}else{
List<Idea> ideasList = [select id,title,status,body,createdby.name,createddate,NumComments,Categories,VoteTotal,(select id,type from votes where createdbyid=:userinfo.getuserId()) from idea where CommunityId =:zoneId order by createddate desc];
return ideasList;
}*/
        
        fetchideaSoql = ideaSql +ideaType+ sorting;
        system.debug('ideList==' + fetchideaSoql);
        list<Idea> ideList = Database.query(fetchideaSoql);
        
        for(idea ide : ideList){
            IdeasWrapperPost wp = new IdeasWrapperPost();
            if(ide.Body != null && ide.Body.length() > 400)
                ide.Body = ide.Body.left(400)+'...';
            wp.oneidea = ide;
            if(voteMap.containsKey(ide.id)){
                vote v = voteMap.get(ide.id);
                wp.iscurrentlyvotedbyuser = true;
                if(v.type == 'up'){ 
                    wp.liked = true;
                }else{
                    wp.liked = false;
                }
            }else{
                wp.iscurrentlyvotedbyuser = false;
            }
            wpp.add(wp);
        }
        // wp.idealist = idealist;
        return wpp;    
    }
    
    @AuraEnabled
    public static List<String> getCategories(){
        List<String> options = new List<String>();
        Schema.sObjectType sobject_type = Idea.getSObjectType();
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe();
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();
        List<Schema.PicklistEntry> pick_list_values = field_map.get('Categories').getDescribe().getPickListValues();
        options.add('All');
        for (Schema.PicklistEntry a : pick_list_values) {
            if(a.getValue() != 'unknown' )         
                options.add( a.getLabel());
        }
        return options;
    }
    
    @AuraEnabled
    public static List<IdeasWrapperPost> getFilteredIdeas(String zoneId, String selectedCateg){
        List<Idea> ideasList = new List<Idea>();
        if(selectedCateg.tolowerCase() == 'all'){
            ideasList = [select id,title,status,body,createdby.name,createddate,NumComments,Categories,VoteTotal from idea where CommunityId =:zoneId order by createddate desc];
        }else{
            ideasList = [select id,title,status,body,createdby.name,createddate,NumComments,Categories,VoteTotal from idea where CommunityId =:zoneId and Categories includes (:selectedCateg) order by createddate desc];
        }
        List<IdeasWrapperPost> wpp = new List<IdeasWrapperPost>();
        string fetchideaSoql = '';
        string sorting ='';
        string ideaType ='';
        // string whereis = ideaSql +'where  Id IN :';
        
        Map<id, vote> voteMap = new Map<id, vote>();
        set<Id> votedIdea = new set<Id>();
        List<Vote> votes = [SELECT Id, ParentId, Type, CreatedById FROM Vote where parent.type = 'idea' AND CreatedById =:UserInfo.getUserId()];
        system.debug('fil==' + votes + votes.size());
        for(vote vt : votes){
            if(vt.CreatedById ==  UserInfo.getUserId()){
                voteMap.put(vt.parentid, vt); 
                votedIdea.add(vt.ParentId);
            } 
        }
        for(idea ide : ideasList){
            IdeasWrapperPost wp = new IdeasWrapperPost();
            if(ide.Body != null && ide.Body.length() > 400)
                ide.Body = ide.Body.left(400)+'...';
            wp.oneidea = ide;
            if(voteMap.containsKey(ide.id)){
                vote v = voteMap.get(ide.id);
                wp.iscurrentlyvotedbyuser = true;
                if(v.type == 'up'){ 
                    wp.liked = true;
                }else{
                    wp.liked = false;
                }
            }else{
                wp.iscurrentlyvotedbyuser = false;
            }
            wpp.add(wp);
        }
        // wp.idealist = idealist;
        return wpp;    
    }
    
    @AuraEnabled
    public static List<IdeasWrapperPost> addVote(String parentId, String type,String zoneId){
        system.debug('parentId===' +parentId);
        system.debug('type===' +type);
        system.debug('zoneId===' +zoneId);
        List<Vote> existingVote = [select id,type from vote where parentid =:parentid and createdbyid =:Userinfo.getUserId()];
        Boolean createVote = false;
        if(existingVote != null && !existingVote.isEmpty() && existingVote[0].type != type){
            delete existingVote;
            createVote = true;
        }else if(existingVote.isEmpty()){
            createVote = true;
        }
        if(createVote){
            vote vt= new vote();
            system.debug('vote type is '+vt.Type);
            
            try{
                vt.type= type;
                
                vt.parentid = parentId;
                insert vt;
                
            }
            catch(Exception e){
                
                system.debug('e--->'+e);
            }
        }
        String fetchideaSoql = ideaSql+ ' WHere id =: parentId';
        list<Idea> ideList = Database.query(fetchideaSoql);
        Map<id, vote> voteMap = new Map<id, vote>();
        set<Id> votedIdea = new set<Id>();
        List<Vote> votes = [SELECT Id, ParentId, Type, CreatedById FROM Vote where parent.type = 'idea' AND CreatedById =:UserInfo.getUserId() AND ParentId =: parentId];
        system.debug('fil==' + votes + votes.size());
        for(vote vt : votes){
            if(vt.CreatedById ==  UserInfo.getUserId()){
                voteMap.put(vt.parentid, vt); 
                votedIdea.add(vt.ParentId);
            } 
        }
        List<IdeasWrapperPost> wpp = new List<IdeasWrapperPost>();
        for(idea ide : ideList){
            IdeasWrapperPost wp = new IdeasWrapperPost();
            if(ide.Body != null && ide.Body.length() > 400)
                ide.Body = ide.Body.left(400)+'...';
            wp.oneidea = ide;
            if(voteMap.containsKey(ide.id)){
                vote v = voteMap.get(ide.id);
                wp.iscurrentlyvotedbyuser = true;
                if(v.type == 'up'){ 
                    wp.liked = true;
                }else{
                    wp.liked = false;
                }
            }else{
                wp.iscurrentlyvotedbyuser = false;
            }
            wpp.add(wp);
        }
        // wp.idealist = idealist;
        return wpp;    
    }
    
    public class IdeasWrapperPost{
        @AuraEnabled
        public idea oneidea;
        @AuraEnabled
        public boolean liked;
        @AuraEnabled
        public boolean iscurrentlyvotedbyuser;
        
    }
    
}