===============================================================================
                    DESIGN REQUIREMENTS
===============================================================================

TARGET OBJECT: OVF__c (Order Verification Form)
  - Confirmed: Object exists at force-app/main/default/objects/OVF__c/
  - Description: "Order Verification Form submitted via Rubrik Quote Portal"
  - Name field: AutoNumber (OVF-{0000})
  - Existing fields: 15 Text(255) fields + Quote__c lookup
  - No existing page layout files in local source

API VERSION: 66.0
PACKAGE DIRECTORY: force-app/main/default
DATE: 2026-04-02

-------------------------------------------------------------------------------
WHAT USER REQUESTED:
-------------------------------------------------------------------------------

  1. Five new custom Text fields (length 100) on OVF__c
  2. Add all fields to page layouts
  3. Grant field-level security so sales reps can read/edit the fields

-------------------------------------------------------------------------------
                    ADMIN WORK (salesforce-admin)
-------------------------------------------------------------------------------

All work for this request is declarative (Admin). No Apex/LWC/code is needed.

A. CUSTOM FIELDS (5 fields on OVF__c, all Text, length 100):

  API names follow existing OVF__c naming convention (underscore-separated):

  | # | Label                     | Proposed API Name              | Type | Length |
  |---|---------------------------|--------------------------------|------|--------|
  | 1 | Customer AWS Account ID   | Customer_AWS_Account_ID__c     | Text | 100    |
  | 2 | Purchase Amount           | Purchase_Amount__c             | Text | 100    |
  | 3 | Company Name in Tackle    | Company_Name_in_Tackle__c      | Text | 100    |
  | 4 | Billing Subaccount        | Billing_Subaccount__c          | Text | 100    |
  | 5 | Customer Name in POA      | Customer_Name_in_POA__c        | Text | 100    |

  All fields: externalId=false, required=false, trackHistory=false,
  trackTrending=false, unique=false

  NOTE: Existing field Company_Name__c (Text 255) already exists on OVF__c.
  Field #3 (Company_Name_in_Tackle__c) is a SEPARATE field.

B. PAGE LAYOUT:
  Add all 5 new fields to the OVF__c page layout(s). No layout file currently
  exists in the local source repository. The admin agent should retrieve the
  existing layout from the org first, then add the new fields to it.

C. FIELD-LEVEL SECURITY:
  Grant read and edit access on all 5 fields for sales rep profiles/permission
  sets. The admin agent should identify the appropriate sales-related profile
  or permission set from the org and set field visibility to Visible + Editable.

-------------------------------------------------------------------------------
                    DEVELOPMENT WORK (salesforce-developer)
-------------------------------------------------------------------------------

No development work required for this request.

-------------------------------------------------------------------------------
                    EXECUTION ORDER
-------------------------------------------------------------------------------

All items are Admin work. Deploy order:

  1. Create the 5 custom field metadata files (no dependencies)
  2. Add fields to page layout (depends on step 1)
  3. Set field-level security (depends on step 1)

Steps 2 and 3 can run in parallel after step 1. All can be deployed
together in a single metadata package since SFDX handles dependency
resolution within a single deployment.

-------------------------------------------------------------------------------
                    ASSUMPTIONS
-------------------------------------------------------------------------------

  1. FIELD API NAMES: Derived from user-provided labels using standard
     Salesforce convention (spaces to underscores). If different API names
     are desired, user should specify.

  2. EXISTING FIELD SETS: OVF__c has 3 field sets (AWSOVFFieldSet,
     AzureOVFFieldSet, GCPOVFFieldSet) used by the Rubrik Quote Portal.
     User did NOT request adding the new fields to these field sets, so
     they will NOT be modified.

  3. "Sales reps" -- the specific profile or permission set name was not
     provided. The admin agent will need to identify the correct one from
     the org.

-------------------------------------------------------------------------------
                    PROMPTS FOR SPECIALIST AGENTS
-------------------------------------------------------------------------------

PROMPT FOR salesforce-admin:
"""
Create the following metadata for the OVF__c object (Order Verification Form).
API version: 66.0. Package directory: force-app/main/default.
Do not deploy -- just create the metadata files.

1. CUSTOM FIELDS (5 new fields on OVF__c, all Text, length 100, not required):
   - Customer_AWS_Account_ID__c (label: "Customer AWS Account ID")
   - Purchase_Amount__c (label: "Purchase Amount")
   - Company_Name_in_Tackle__c (label: "Company Name in Tackle")
   - Billing_Subaccount__c (label: "Billing Subaccount")
   - Customer_Name_in_POA__c (label: "Customer Name in POA")

   Follow the same XML structure as existing fields on OVF__c (e.g.,
   Buyer_Name__c.field-meta.xml) but use length 100 instead of 255.
   All other properties match existing fields: externalId=false,
   required=false, trackHistory=false, trackTrending=false, unique=false.
   Files go in: force-app/main/default/objects/OVF__c/fields/

2. PAGE LAYOUT:
   Add all 5 new fields to the OVF__c page layout(s). No layout file
   exists in local source -- retrieve the existing layout from the org
   if needed, then add the new fields. Layout files go in:
   force-app/main/default/layouts/

3. FIELD-LEVEL SECURITY:
   Grant read and edit access on all 5 new fields for sales rep
   profiles/permission sets. Identify the appropriate sales rep
   profile or permission set from the org and set field visibility
   to Visible and Editable. Use profile metadata or permission set
   metadata as appropriate. If creating a permission set, place it in:
   force-app/main/default/permissionsets/
"""

PROMPT FOR salesforce-developer:
"""
No development work required for this request.
"""

===============================================================================
