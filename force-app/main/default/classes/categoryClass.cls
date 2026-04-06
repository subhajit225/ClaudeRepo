public class categoryClass {
    
    
    public Map<String,String> getDescribeDataCategoryGroupStructureResults(){
        Map<String,String> categoryList = new Map<String,String>();
        List<DescribeDataCategoryGroupResult> describeCategoryResult;
        List<DescribeDataCategoryGroupStructureResult> describeCategoryStructureResult;
        try {
            //Making the call to the describeDataCategoryGroups to
            //get the list of category groups associated
            List<String> objType = new List<String>();
            objType.add('KnowledgeArticleVersion');
            describeCategoryResult = Schema.describeDataCategoryGroups(objType);
            
            //Creating a list of pair objects to use as a parameter
            //for the describe call
            List<DataCategoryGroupSobjectTypePair> pairs = new List<DataCategoryGroupSobjectTypePair>();
            
            //Looping throught the first describe result to create
            //the list of pairs for the second describe call
            //
            for(DescribeDataCategoryGroupResult singleResult : describeCategoryResult){
                DataCategoryGroupSobjectTypePair p = new DataCategoryGroupSobjectTypePair();
                p.setSobject(singleResult.getSobject());
                p.setDataCategoryGroupName(singleResult.getName());
                pairs.add(p);
            }
            
            //describeDataCategoryGroupStructures()
            describeCategoryStructureResult = Schema.describeDataCategoryGroupStructures(pairs, false);
            
            //Getting data from the result
            for(DescribeDataCategoryGroupStructureResult singleResult : describeCategoryStructureResult){
                //Get name of the associated Sobject
                
                //Get the name of the data category group
                singleResult.getName();
                
                //Get the top level categories
                DataCategory [] toplevelCategories =  singleResult.getTopCategories();
                
                //Recursively get all the categories
                List<DataCategory> allCategories = getAllCategories(toplevelCategories);
                for(DataCategory category : allCategories) {
                    //Get the name of the category
                    //
                        categoryList.put(category.getLabel(),category.getName());
                }
            }
        } 
        catch (Exception e){
            
        }
        return categoryList;
    }
    
    public Map<String,String> getDescribeDataCategoryGroupStructureResultsSingle(){
        Map<String,String> categoryList = new Map<String,String>();
        List<DescribeDataCategoryGroupResult> describeCategoryResult;
        List<DescribeDataCategoryGroupStructureResult> describeCategoryStructureResult;
        try {
            //Making the call to the describeDataCategoryGroups to
            //get the list of category groups associated
            List<String> objType = new List<String>();
            objType.add('KnowledgeArticleVersion');
            describeCategoryResult = Schema.describeDataCategoryGroups(objType);
            
            //Creating a list of pair objects to use as a parameter
            //for the describe call
            List<DataCategoryGroupSobjectTypePair> pairs = new List<DataCategoryGroupSobjectTypePair>();
            
            //Looping throught the first describe result to create
            //the list of pairs for the second describe call
            for(DescribeDataCategoryGroupResult singleResult : describeCategoryResult){
                DataCategoryGroupSobjectTypePair p = new DataCategoryGroupSobjectTypePair();
                p.setSobject(singleResult.getSobject());
                p.setDataCategoryGroupName(singleResult.getName());
                pairs.add(p);
            }
            
            //describeDataCategoryGroupStructures()
            describeCategoryStructureResult = Schema.describeDataCategoryGroupStructures(pairs, false);
            
            //Getting data from the result
            for(DescribeDataCategoryGroupStructureResult singleResult : describeCategoryStructureResult){
                //Get name of the associated Sobject
                
                //Get the name of the data category group
                singleResult.getName();
                
                //Get the top level categories
                DataCategory [] toplevelCategories =  singleResult.getTopCategories();
                
                //Recursively get all the categories
                List<DataCategory> allCategories = getAllCategories(toplevelCategories);
                for(DataCategory category : allCategories) {
                    //Get the name of the category
                    //
                        categoryList.put(category.getName(),category.getLabel());
                }
            }
        } 
        catch (Exception e){
            
        }
        return categoryList;
    }
    
    public  DataCategory[] getAllCategories(DataCategory [] categories){
        if(categories.isEmpty()){
            return new DataCategory[]{};
                } else {
                    DataCategory [] categoriesClone = categories.clone();
                    DataCategory category = categoriesClone[0];
                    DataCategory[] allCategories = new DataCategory[]{category};
                        categoriesClone.remove(0);
                    categoriesClone.addAll(category.getChildCategories());
                    allCategories.addAll(getAllCategories(categoriesClone));
                    return allCategories;
                }
    }
}