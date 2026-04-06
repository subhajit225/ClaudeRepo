# Salesforce Admin Agent Memory

## Key Org Facts
- **Connected Org Alias**: RubrikClaudePOC
- **Org URL**: https://rubrikinc--claudepoc.sandbox.my.salesforce.com
- **API Version**: 66.0
- **Package Directory**: `force-app/main/default`

## FLS Strategy
- Profiles in the project (`Rubrik Quote Portal Profile`, `Rubrik Quote VF Profile`) are Guest User licenses for the Quote Portal — do NOT use these for sales rep FLS
- Sales rep FLS should go into permission sets, not profiles
- Key sales rep permission sets in the org:
  - `RubrikFieldSalesUserNew` — primary field sales rep PS
  - `PSG_Field_Sales_User` — PSG group field sales
  - `Tackle_Full_Access_Marketplace` — marketplace full access
  - `Tackle_Sales_Operator` — Tackle sales operators
  - `Tackle_User` — general Tackle users
- NEVER create stub permission set files with only the new fieldPermissions — always retrieve the full PS from org first, then append new entries. Stubs are a destructive overwrite risk.
- Correct fieldPermissions XML uses `<editable>` and `<readable>` tags (NOT `<allowCreate>/<allowEdit>/<allowRead>` — those are wrong for source format)
- `PSG_Field_Sales_User` is a **PermissionSetGroup** (Type=Group in SOQL), NOT a PermissionSet — retrieve with `--metadata "PermissionSetGroup:PSG_Field_Sales_User"` and it lands in `permissionsetgroups/` as `.permissionsetgroup-meta.xml`. PermissionSetGroups do not hold fieldPermissions directly.
- `Tackle_Full_Access_Marketplace` (namespace: tackleio) and `Tackle_Sales_Operator` (namespace: tackle) are managed package permission sets — cannot be retrieved or modified. Delete any stub files for these.
- `Tackle_User` (no namespace) is a standard custom PS — retrievable and modifiable normally.

## Layout Retrieval Pattern
- There is only ONE OVF layout: `OVF__c-OVF Layout`
- Retrieve layouts before editing: `sf project retrieve start --metadata "Layout:ObjectName__c-Layout Name"`
- The layouts directory is empty in source control until retrieved

## Field XML Pattern (Text fields)
```xml
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Field_Name__c</fullName>
    <externalId>false</externalId>
    <label>Field Label</label>
    <length>100</length>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Text</type>
    <unique>false</unique>
</CustomField>
```

## OVF__c Object Notes
- OVF = Order Verification Form for Rubrik Quote Portal (marketplace/Tackle integration)
- One layout: `OVF__c-OVF Layout`
- Three field sets exist (DO NOT MODIFY): `AWSOVFFieldSet`, `AzureOVFFieldSet`, `GCPOVFFieldSet`
- 16 existing fields as of Apr 2026

## See Also
- [deployment-issues.md](deployment-issues.md) — deployment troubleshooting
