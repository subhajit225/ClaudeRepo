# OVF Marketplace Details Custom Fields

**Date:** 2026-04-02
**Author:** Documentation Agent
**Status:** Completed

---

## Overview

### Original Request
Create 5 new Text(100) custom fields on the OVF__c object, add them to the OVF page layout in a new "Marketplace Details" section, and grant read/edit field-level security to sales rep permission sets.

### Business Objective
Sales reps working with marketplace transactions (AWS Marketplace via Tackle) needed dedicated fields on the Order Verification Form (OVF) to capture marketplace-specific data: the customer's AWS account, purchase amount, company name as it appears in Tackle, billing subaccount, and the customer name as recorded in the Partner Order Acknowledgment (POA). These fields were previously absent from OVF__c, forcing reps to store this information elsewhere or leave it untracked.

### Summary
Five Text(100) custom fields were added to the `OVF__c` (Order Verification Form) object to support AWS Marketplace data capture. All five fields were placed on the `OVF__c-OVF Layout` page layout under a new "Marketplace Details" section with two-column layout. Field-level security granting full read and edit access was applied to the `RubrikFieldSalesUserNew` and `Tackle_User` permission sets and deployed to the RubrikClaudePOC sandbox.

---

## Components Created

### Admin Components (Declarative)

#### Custom Object (Existing — Modified)
| Object API Name | Label | Description |
|-----------------|-------|-------------|
| `OVF__c` | OVF | Order Verification Form submitted via Rubrik Quote Portal |

#### Custom Fields (New)
| Object | Field API Name | Type | Length | Required | Label |
|--------|----------------|------|--------|----------|-------|
| `OVF__c` | `Customer_AWS_Account_ID__c` | Text | 100 | No | Customer AWS Account ID |
| `OVF__c` | `Purchase_Amount__c` | Text | 100 | No | Purchase Amount |
| `OVF__c` | `Company_Name_in_Tackle__c` | Text | 100 | No | Company Name in Tackle |
| `OVF__c` | `Billing_Subaccount__c` | Text | 100 | No | Billing Subaccount |
| `OVF__c` | `Customer_Name_in_POA__c` | Text | 100 | No | Customer Name in POA |

All five fields share the same configuration: `externalId=false`, `required=false`, `trackHistory=false`, `trackTrending=false`, `unique=false`.

Note: `Company_Name_in_Tackle__c` is a separate field from the pre-existing `Company_Name__c` (Text 255) field. They serve distinct purposes — `Company_Name__c` is the general company name; `Company_Name_in_Tackle__c` captures the company name exactly as it appears in the Tackle marketplace platform.

#### Page Layout (Updated)
| Layout API Name | Object | Change |
|-----------------|--------|--------|
| `OVF__c-OVF Layout` | `OVF__c` | New "Marketplace Details" section added containing all 5 fields |

#### Permission Sets (Updated)
| Permission Set API Name | Label | Change |
|-------------------------|-------|--------|
| `RubrikFieldSalesUserNew` | Rubrik Field Sales User New | Added editable+readable FLS for all 5 OVF fields |
| `Tackle_User` | Tackle User | Added editable+readable FLS for all 5 OVF fields |

#### Permission Sets (Not Modified)
| Permission Set / Group | Reason Not Modified |
|------------------------|---------------------|
| `PSG_Field_Sales_User` | PermissionSetGroup — OVF access flows through its member permission sets (including `RubrikFieldSalesUserNew`) |
| `Tackle_Full_Access_Marketplace` | Managed package permission set — cannot be modified |
| `Tackle_Sales_Operator` | Managed package permission set — cannot be modified |

---

## Page Layout Configuration

### "Marketplace Details" Section

The new section uses a two-column `TwoColumnsTopToBottom` style and is positioned between the existing "Information" section and the "System Information" section on the layout.

| Column | Fields (top to bottom) |
|--------|------------------------|
| Left | Customer AWS Account ID, Purchase Amount, Company Name in Tackle |
| Right | Billing Subaccount, Customer Name in POA |

All five fields are set to `Edit` behavior (user can read and write in edit mode).

The section header is visible on both detail and edit views (`detailHeading=true`, `editHeading=true`).

---

## Field-Level Security Details

Both permission sets received identical FLS entries for all five fields:

```xml
<fieldPermissions>
    <editable>true</editable>
    <field>OVF__c.<FieldAPIName></field>
    <readable>true</readable>
</fieldPermissions>
```

Fields granted: `Billing_Subaccount__c`, `Company_Name_in_Tackle__c`, `Customer_AWS_Account_ID__c`, `Customer_Name_in_POA__c`, `Purchase_Amount__c`.

---

## Data Flow

### How It Works

```
1. A sales rep opens or creates an OVF record.
2. The "Marketplace Details" section appears on the OVF Layout.
3. The rep populates fields with data from their Tackle/AWS Marketplace transaction.
4. Permissions flow: PSG_Field_Sales_User → RubrikFieldSalesUserNew (member PS) → FLS grants read/edit.
5. Tackle_User permission set independently grants the same access for Tackle-assigned users.
```

### Architecture Overview

```
                    OVF__c (Object)
                         |
              Fields created (Text 100)
                         |
         ┌───────────────┼───────────────┐
         |                               |
  OVF__c-OVF Layout            Permission Sets
  "Marketplace Details"    ┌──────────────────────┐
  section (new)            │ RubrikFieldSalesUserNew│
                           │ Tackle_User            │
                           └──────────────────────┘
                                     |
                            FLS: editable=true
                                readable=true
                            (all 5 OVF fields)
```

---

## File Locations

| Component Type | Path |
|----------------|------|
| Custom Field: Customer_AWS_Account_ID__c | `force-app/main/default/objects/OVF__c/fields/Customer_AWS_Account_ID__c.field-meta.xml` |
| Custom Field: Purchase_Amount__c | `force-app/main/default/objects/OVF__c/fields/Purchase_Amount__c.field-meta.xml` |
| Custom Field: Company_Name_in_Tackle__c | `force-app/main/default/objects/OVF__c/fields/Company_Name_in_Tackle__c.field-meta.xml` |
| Custom Field: Billing_Subaccount__c | `force-app/main/default/objects/OVF__c/fields/Billing_Subaccount__c.field-meta.xml` |
| Custom Field: Customer_Name_in_POA__c | `force-app/main/default/objects/OVF__c/fields/Customer_Name_in_POA__c.field-meta.xml` |
| Page Layout | `force-app/main/default/layouts/OVF__c-OVF Layout.layout-meta.xml` |
| Permission Set: RubrikFieldSalesUserNew | `force-app/main/default/permissionsets/RubrikFieldSalesUserNew.permissionset-meta.xml` |
| Permission Set: Tackle_User | `force-app/main/default/permissionsets/Tackle_User.permissionset-meta.xml` |

---

## Existing OVF__c Context

For reference, the OVF__c object had the following fields prior to this task:

| Field API Name | Type | Length | Notes |
|----------------|------|--------|-------|
| `Name` | AutoNumber | — | Format: OVF-{0000} |
| `Quote__c` | Lookup | — | Lookup to Quote object |
| `Buyer_Name__c` | Text | 255 | |
| `Buyer_Billing_ID__c` | Text | 255 | |
| `Buyer_Tenant_ID__c` | Text | 255 | |
| `Reseller_Name__c` | Text | 255 | |
| `Marketplace_Seller_ID__c` | Text | 255 | |
| `Company_Name__c` | Text | 255 | General company name — distinct from Company_Name_in_Tackle__c |
| `Address_1__c` | Text | 255 | |
| `Address_2__c` | Text | 255 | |
| `City__c` | Text | 255 | |
| `State__c` | Text | 255 | |
| `Zip_Code__c` | Text | 255 | |
| `Country__c` | Text | 255 | |
| `Contact_Name__c` | Text | 255 | |
| `Contact_Email__c` | Text | 255 | |
| `Contact_Phone__c` | Text | 255 | |

The object also has three field sets (`AWSOVFFieldSet`, `AzureOVFFieldSet`, `GCPOVFFieldSet`) used by the Rubrik Quote Portal. These field sets were intentionally not modified as the user did not request it.

---

## Security

### Sharing Model
- `OVF__c` sharing model: Private (both internal and external)
- No Apex classes were created for this task; no `with sharing` considerations apply.

### Required Permissions for Field Access
Users must be assigned one of the following to read and edit the new fields:
- `RubrikFieldSalesUserNew` permission set (directly, or via `PSG_Field_Sales_User` group)
- `Tackle_User` permission set

---

## Notes and Considerations

### Known Limitations
- `Purchase_Amount__c` is stored as Text(100), not a Currency/Number type. This was intentional per the original request. If numeric formatting, roll-up summaries, or currency conversion is needed in the future, the field type would need to change (which requires data migration if records exist).
- The five new fields were NOT added to the existing OVF field sets (`AWSOVFFieldSet`, `AzureOVFFieldSet`, `GCPOVFFieldSet`). If the Rubrik Quote Portal needs to display these fields dynamically, the relevant field set(s) must be updated separately.

### Future Enhancements
- Consider converting `Purchase_Amount__c` to a Currency field if financial reporting against this data is required.
- Evaluate whether `Customer_AWS_Account_ID__c` and `Billing_Subaccount__c` should be added to `AWSOVFFieldSet` for display in the Quote Portal.
- If POA-related fields are used for contract or provisioning workflows, automation (Flow or Apex) may be warranted to sync data to downstream objects.

### Dependencies
- `OVF__c` object must exist prior to deployment of fields.
- Fields must exist prior to deployment of the page layout update and permission set FLS entries.
- `RubrikFieldSalesUserNew` and `Tackle_User` permission sets must exist in the target org.
- `PSG_Field_Sales_User` PermissionSetGroup is not deployed via this task; it is assumed to already include `RubrikFieldSalesUserNew` as a member.

---

## Deployment Summary

| Detail | Value |
|--------|-------|
| Target Org | RubrikClaudePOC (Sandbox) |
| API Version | 66.0 |
| Deployment Tool | Salesforce MCP (`mcp__salesforce__deploy_metadata`) |
| Components Deployed | 5 CustomField files, 1 Layout file, 2 PermissionSet files |
| Total Files | 8 |

---

## Change History

| Date | Author | Change Description |
|------|--------|-------------------|
| 2026-04-02 | Documentation Agent | Initial creation |
