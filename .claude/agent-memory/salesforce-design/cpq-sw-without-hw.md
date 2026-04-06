# CPQ "SW Without HW" Validation Logic

## Location
The validation lives in TWO places:

### Client-Side (Aura)
- `force-app/main/default/aura/Custom_Submit_For_Approval_Ltng/Custom_Submit_For_Approval_LtngHelper.js`
  - CPQ22-3975 block, ~lines 1493-1627
  - Three check points that set `showalertforSWWOHW = true`
  - Uses dynamic SOQL from `Custom_Submit_For_Approval_LtngController.js` (lines ~20-40)
  - Condition: `quote.Quoting_Desk_Exception__c.includes('Quoting Exception - SW without HW')`
  - Also checks: `quoteLine.Quote_Line_Type__c == 'New'` and `quote.ProcessType__c != 'Aspen'`

### Server-Side (Apex)
- `force-app/main/default/classes/QuoteExtController.cls`
  - Method: `getQuoteLines(String quoteId)` (~lines 840-912)
  - Returns quote lines to show in the details popup
  - Has its own SOQL query (~line 845)

## Fields Checked
Three fields are checked for emptiness (on both line and RequiredBy__r):
1. `Subscribed_Asset_Name__c`
2. `SubscribedAssetNames__c`
3. `Arroyo_Subsumed_Old_Contract_Line_Items__c`

Current logic: popup fires if ANY ONE is empty (OR logic).

## Bypass Mechanisms
- `Bypass SW Without HW Validation` in `SBQQ__Product__r.Restrict_Quoting_For__c` (CPQ22-4680)
- `IsHardwareNotRequiredForHybridLicense__c` on Product
- Marketplace distributors are excluded (CPQ22-4361, CPQ22-5991)
- Aspen process type excluded

## Related POItemValidation.cls
- `isSupportBundle()` method (~line 1822) references "SW without HW" but only as bypass condition
- Does NOT check asset fields -- no modification needed for asset-field changes

## Key Jira Tickets in Code Comments
- CPQ22-3975: Original SW/HW validation
- CPQ22-4361: Marketplace exclusion
- CPQ22-4680: Product-level bypass
- CPQ22-5144: New Sale bypass
- CPQ22-5991: Distributor name fallback
- CPQ22-6547: Add Converted/Refreshed Assets field (pending)
