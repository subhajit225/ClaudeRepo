public with sharing class IdeasViewController {

    Public Integer noOfRecords{get; set;}
    Public Integer size{get;set;}
    public string category {get; set;}
    
    public ApexPages.StandardSetController standardSetCtrl {
        get{
            if(standardSetCtrl == null){
                size = 50;
                system.debug('### category ' +category);
                if(category==null) category='';
                system.debug('### category ' +category);
                string ideaFieldString = String.join(new List<String>(Idea.sObjectType.getDescribe().fields.getMap().keySet()), ',');
                string queryString = 'Select '+ ideaFieldString;
                queryString += ' , CreatedBy.Id, CreatedBy.Name, CreatedBy.CommunityNickname from Idea ' ;
                //if(category!='') queryString +=  ' where Categories =: category ';
                if(category!='') queryString +=  ' where Categories in (\''+ category +'\'';
                if(category!='') queryString += ')';
                
                ///select id, Categories from Idea where Categories in ('Cluster Operations')

                queryString +=  ' order by CreatedDate desc';
                standardSetCtrl =  new ApexPages.StandardSetController(Database.getQueryLocator(queryString));
                
                system.debug('### query String ' + queryString);
                standardSetCtrl.setPageSize(size);
                noOfRecords = standardSetCtrl.getResultSize();
            }
            return standardSetCtrl;
        }set;
    }
     
    Public List<Idea> getIdeas(){
        List<Idea> ideaList = new List<Idea>();
        for(Idea a : (List<Idea>)standardSetCtrl.getRecords())
            ideaList.add(a);
        return ideaList;
    }
    
    public void searchIdeas() {
        standardSetCtrl = null;
        getIdeas();
        standardSetCtrl.setPageNumber(1);
    }
 
     // Get the categories
    public list<selectOption> getCategories() {
      list<SelectOption> options = new list<SelectOption>();

          Schema.DescribeFieldResult fieldResult = Idea.Categories.getDescribe();
                          options.add(new SelectOption('', ' '));

            for (Schema.PicklistEntry pe : fieldResult.getPicklistValues()) {
                options.add(new SelectOption(pe.getValue(), pe.getLabel()));
            }
                      
          return options;
    }
     
    public pageReference refresh() {
        standardSetCtrl = null;
        getIdeas();
        standardSetCtrl.setPageNumber(1);
        return null;
    }
     
    public Boolean hasNext {
        get {
            return standardSetCtrl.getHasNext();
        }
        set;
    }
    public Boolean hasPrevious {
        get {
            return standardSetCtrl.getHasPrevious();
        }
        set;
    }
  
    public Integer pageNumber {
        get {
            return standardSetCtrl.getPageNumber();
        }
        set;
    }
  
    public void first() {
        //any custom logic
        standardSetCtrl.first();
    }
  
    public void last() {
        //any custom logic
        standardSetCtrl.last();
    }
  
    public void previous() {
        //any custom logic
        standardSetCtrl.previous();
    }
  
    public void next() {
        //any custom logic
        standardSetCtrl.next();
    }
}