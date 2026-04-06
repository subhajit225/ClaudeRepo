public class ShGl_CommonUtility {
    
    public static Map<Id, List<SObject>> convertListToMap (List<SObject> sObjList, String groupByField) {
        Map<Id, List<SObject>> sObjMap = new Map<Id, List<SObject>> ();
        List<SObject> tempList;
        for(SObject sObj : sObjList) {
            if(sObjMap.containsKey((String)sObj.get(groupByField))) {
                tempList = sObjMap.get((String)sObj.get(groupByField));
            } else {
                tempList = new List<SObject>();
            }
            tempList.add(sObj);
            sObjMap.put((String)sObj.get(groupByField), tempList);
        }
        return sObjMap;
    }
    
    public static Map<Id, SObject> convertListToIdMap (List<SObject> sObjList) {
        Map<Id, SObject> sObjMap = new Map<Id, SObject> ();
        for(SObject sObj : sObjList) {
            sObjMap.put(sObj.Id, sObj);
        }
        return sObjMap;
    }

    public static Map<String, SObject> convertListToFieldMap (List<SObject> sObjList, String groupByField) {
        Map<String, SObject> sObjMap = new Map<String, SObject> ();
        for(SObject sObj : sObjList) {
            if(!sObjMap.containsKey((String)sObj.get(groupByField))) {
            	sObjMap.put((String)sObj.get(groupByField), sObj);
            }
        }
        return sObjMap;
    }


}