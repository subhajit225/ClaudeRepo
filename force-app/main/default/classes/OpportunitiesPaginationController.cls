public with sharing class OpportunitiesPaginationController 
{
    public Opportunity opp {get;set;}   
    public String originalId {get;set;}
    public Boolean searchClick {get;set;}
    public ApexPages.StandardSetController con{get; set;} 
    public OpportunitiesPaginationController ()
    {
        originalId = ApexPages.currentPage().getParameters().get('Id');
        opp = new Opportunity();
        lstOpportunity = new List<Opportunity>();
    }
    public List<Opportunity> lstOpportunity 
    {  
        get  
        {  
            if(con != null)  
                return (List<Opportunity>)con.getRecords();  
            else  
                return null ;  
        }  
        set;
    }  
    public PageReference Search()
    {
        searchClick = true;
        String query= '';
        String strFilter = '';
        if(opp.Name != null && (opp.Name ).trim() !='')
        {
            strFilter  = strFilter  +  ' where Name Like \'%'+ String.escapeSingleQuotes(opp.Name) +'%\' AND id != \''+ String.escapeSingleQuotes(originalId) + '\''; 
        }
        /*
        if(acc.Phone != null && (acc.Phone).trim() !='' )
        {
            if(strFilter == '')
            { 
                strFilter  = strFilter  +  ' where Phone like \''+acc.Phone+'%\'' ;
            }
            else
            {
                strFilter  = strFilter  +  ' And Phone like \''+acc.Phone+'%\'' ;
            }
        }
		*/
        if(strFilter != '')
        {
            query = 'select id,Name,Account.name,Amount,StageName,CloseDate from Opportunity '+strFilter+ ' limit 1000';
            System.debug('Query ---->'+ query );
            con = new ApexPages.StandardSetController(Database.getQueryLocator(query)); 
            con.setPageSize(50);
        }
        else
        {
        }
        return null;
    }
    public Boolean hasNext  
    {  
        get  
        {  
            return con.getHasNext();  
        }  
        set;  
    }  
    public Boolean hasPrevious  
    {  
        get  
        {  
            return con.getHasPrevious();  
        }  
        set;  
    }  
    public Integer pageNumber  
    {  
        get  
        {  
            return con.getPageNumber();  
        }  
        set;  
    }  
    public void previous()  
    {  
        con.previous();  
    }  
    public void next()  
    {  
        con.next();  
    }  
    
    
}