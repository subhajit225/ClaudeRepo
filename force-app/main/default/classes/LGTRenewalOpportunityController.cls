/**
 * @author       :   Raveesh Layal
 * @createdDate  :   16-01-2025
 * @description  :   CS21-3043 - Issue with the Currency fields in Edit Opportunity button on Renewals Cases
 * @testClass    :   LGTRenewalOpportunityController_Test.cls
 */
public class LGTRenewalOpportunityController {
    
    /**
     * @description Retrieves the list of accessible Opportunity fields from the assigned page layout.
     * @return List of accessible Opportunity field API names.
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getAccessibleOpportunityFields() {
        List<String> accessibleFields = new List<String>();
        List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(
            Metadata.MetadataType.Layout,
            new List<String>{'Opportunity-' + Label.Opportunity_Page_Layout_Assigned_to_Support_Manager}
        );

        if (!layouts.isEmpty()) {
            Metadata.Layout layoutMd = (Metadata.Layout) layouts.get(0);
            
            for (Metadata.LayoutSection section : layoutMd.layoutSections) {
                for (Metadata.LayoutColumn column : section.layoutColumns) {
                    if (column.layoutItems != null) {
                        for (Metadata.LayoutItem item : column.layoutItems) {
                            accessibleFields.add(String.valueOf(item.field));
                        }
                    }
                }
            }
        }
        return accessibleFields;
    }
}