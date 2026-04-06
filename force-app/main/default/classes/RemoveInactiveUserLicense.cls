public without sharing class RemoveInactiveUserLicense  implements Queueable{ //SAL23-839
    public Set<Id> inactivatedUsers; 
    public RemoveInactiveUserLicense(Set<Id> inactivatedUsers1){
        inactivatedUsers = new Set<Id>();
        this.inactivatedUsers = inactivatedUsers1;
    }
    
    public void execute(QueueableContext context){
        List<PermissionSetLicenseAssign> licenseAsgnList = new List<PermissionSetLicenseAssign>();
        List<PermissionSetAssignment> permSetGrpAsgnList = new List<PermissionSetAssignment>();
        
        permSetGrpAsgnList = [select Id,AssigneeId,PermissionSetGroupId,PermissionSetId,PermissionSet.IsOwnedByProfile from PermissionSetAssignment where AssigneeId IN: inactivatedUsers AND PermissionSet.IsOwnedByProfile = false];
        if(!permSetGrpAsgnList.isEmpty()){       
            delete permSetGrpAsgnList;               
        } 
        licenseAsgnList = [select Id,AssigneeId,PermissionSetLicenseId from PermissionSetLicenseAssign where AssigneeId IN: inactivatedUsers];
        if(!licenseAsgnList.isEmpty()){       
            delete licenseAsgnList;               
        }
    }
}