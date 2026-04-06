public class SpecialistRequestTriggerHelper {
    static final String SPECIALIST_REQUEST_OBJ = 'Specialist_Request__c';

    public SpecialistRequestTriggerHelper() {
    }
    
    public static void updateSpecialRequest(List<Specialist_Request__c> listSpecialistRequest) {
        
        Set<String> setPrimaryFocusArea = new Set<String>();
        Set<String> setSecondaryFocusArea = new Set<String> {null};
        Set<String> setRecordTypeName = new Set<String>();
        Set<Id> setRecordTypeId = new Set<Id>();
        
        List<Specialist_Request__c> listEligibleSpecialistRequest = new List<Specialist_Request__c>();
        
        Map<Id, String> mapSpecialistRecordTypeIdWithName = new Map<Id, String>();
        
        for (
            RecordType objSpecialistRecordType :
                [Select Id
                      , Name
                 From RecordType
                 WHERE SobjectType = :SPECIALIST_REQUEST_OBJ
                ]
        ) {
            mapSpecialistRecordTypeIdWithName.put(objSpecialistRecordType.Id, objSpecialistRecordType.Name.toLowercase());
        }
        
        for (Specialist_Request__c objSpecialistRequest : listSpecialistRequest) {
            if (
                    objSpecialistRequest.RecordTypeId != null
                    && objSpecialistRequest.Primary_Focus_Area__c != null
            ) {
                setPrimaryFocusArea.add(objSpecialistRequest.Primary_Focus_Area__c);
                
                if (objSpecialistRequest.Secondary_Focus_Area__c != null) {
                    setSecondaryFocusArea.add(objSpecialistRequest.Secondary_Focus_Area__c);
                }
                
                if (
                        setRecordTypeId.add(objSpecialistRequest.RecordTypeId)
                        && mapSpecialistRecordTypeIdWithName.containsKey(objSpecialistRequest.RecordTypeId)
                ) {
                    setRecordTypeName.add(mapSpecialistRecordTypeIdWithName.get(objSpecialistRequest.RecordTypeId));
                }
                
                listEligibleSpecialistRequest.add(objSpecialistRequest);
            } else if (objSpecialistRequest.Approver_1__c != null || objSpecialistRequest.Approver_2__c != null) {
                objSpecialistRequest.Approver_1__c = null;
                objSpecialistRequest.Approver_2__c = null;
            }
        }
        
        if (!listEligibleSpecialistRequest.isEmpty()) {
            Map<String, List<Id>> mapAreaRecordTypeWithApprovers = new Map<String, List<Id>>();
            
            for (
                    Specialist_Request_Approval_Mapping__mdt objSpecialistRequestApprovalMapping :
                        [SELECT Id
                              , Approvers__c
                              , Primary_Focus_Area__c
                              , Secondary_Focus_Area__c
                              , Specialist_Record_Type_Name__c
                         FROM Specialist_Request_Approval_Mapping__mdt
                         WHERE Primary_Focus_Area__c IN :setPrimaryFocusArea
                         AND Secondary_Focus_Area__c IN :setSecondaryFocusArea
                         AND Specialist_Record_Type_Name__c IN :setRecordTypeName
                         AND Approvers__c != NULL
                        ]
            ) {
                String strFocusAreaRecordType = objSpecialistRequestApprovalMapping.Primary_Focus_Area__c.toLowercase();
                
                if (objSpecialistRequestApprovalMapping.Secondary_Focus_Area__c != NULL) {
                    strFocusAreaRecordType += '-' + objSpecialistRequestApprovalMapping.Secondary_Focus_Area__c.toLowercase();
                }
                
                strFocusAreaRecordType += '-' + objSpecialistRequestApprovalMapping.Specialist_Record_Type_Name__c.toLowercase();
                
                mapAreaRecordTypeWithApprovers.put(
                    strFocusAreaRecordType,
                    objSpecialistRequestApprovalMapping.Approvers__c.remove(' ').split(',')
                );
            }

            for (Specialist_Request__c objSpecialistRequest : listEligibleSpecialistRequest) {
                String strFocusAreaRecordType =
                    objSpecialistRequest.Primary_Focus_Area__c.toLowercase()
                    + '-' + objSpecialistRequest.Secondary_Focus_Area__c.toLowercase()
                    + '-' + mapSpecialistRecordTypeIdWithName.get(objSpecialistRequest.RecordTypeId);

                String strPrimaryAreaRecordType =
                    objSpecialistRequest.Primary_Focus_Area__c.toLowercase()
                    + '-' + mapSpecialistRecordTypeIdWithName.get(objSpecialistRequest.RecordTypeId);
                
                List<Id> listApprovers =
                    mapAreaRecordTypeWithApprovers.containsKey(strFocusAreaRecordType)
                        ? mapAreaRecordTypeWithApprovers.get(strFocusAreaRecordType)
                        : mapAreaRecordTypeWithApprovers.containsKey(strPrimaryAreaRecordType)
                            ? mapAreaRecordTypeWithApprovers.get(strPrimaryAreaRecordType)
                            : null;

                if (listApprovers != null && !listApprovers.isEmpty()) {
                    objSpecialistRequest.Approver_1__c = listApprovers[0];
                    objSpecialistRequest.Approver_2__c = listApprovers.size() > 1 ? listApprovers[1] : null;
                } else {
                    objSpecialistRequest.Approver_1__c = null;
                    objSpecialistRequest.Approver_2__c = null;
                }
            }
        }
    }
}