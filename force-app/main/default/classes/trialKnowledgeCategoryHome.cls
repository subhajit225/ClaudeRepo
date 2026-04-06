public class trialKnowledgeCategoryHome {
    public trialKnowledgeCategoryHome(){}
    public Map<String,String> category;
   
    
    public Map<String,String> getDataCategoryName() {
        category = new Map<String,String>();
        categoryClass cc = new categoryClass();
        category = cc.getDescribeDataCategoryGroupStructureResults();
        return category;
    }
    
}