/*  
Test Class For: SearchUnifyEndpoint
Developer Name: Grazitti
Created Date: 13/01/2021
*/
@isTest
public class SearchUnifyEndpointTest {
    
    public static testMethod void  SearchResults(){
        SearchUnifyEndpoint.SearchResults('{"resultsPerPage":"6","selectedType":"","pageNum": "1","pageNo":1,"orderBy":"desc","sortby":"_score","from":0,"searchString":""}');
    }

}