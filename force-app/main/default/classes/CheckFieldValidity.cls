/***************************************************************************
Author : Chaitra
Date : 17/9/2019
Used in : Company Master
Desc : Valid the dependant picklist value based on picklist/field dependancy
****************************************************************************/


public class CheckFieldValidity{
 
/******************************************************************************************************************************************
 Sample checkFieldValidity.validatedependantPicklist(Account.Industry_Subcategory__c,'Natural Resources','agricultural production crops')
 Input : dependant field,Controlpicklistvalue ,dependantpicklist value
 Output : IsValid (true/false)
*******************************************************************************************************************************************/

  public static boolean validatedependantPicklist( Schema.sObjectField DependantField, string controllingVal , string dependantVal)
{
    
    system.debug('DependantField'+DependantField+'controllingVal'+controllingVal+'dependantVal'+dependantVal);
    boolean IsValid = false; // Valid dependant picklist value
    Schema.DescribeFieldResult depend = DependantField.getDescribe(); // dependant field
    Schema.sObjectField controlToken = depend.getController();
    if ( controlToken == null ) return null;
    Schema.DescribeFieldResult control = controlToken.getDescribe();
     system.debug('control'+control); //Controlling field
   
    List<Schema.PicklistEntry> controlEntries =
    (   control.getType() == Schema.DisplayType.Boolean
    ?   null
    :   control.getPicklistValues()
    );
        

    String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    for ( Schema.PicklistEntry entry : depend.getPicklistValues() ) 
    if ( entry.isActive() && entry.getValue().equalsIgnoreCase(dependantVal))
    {
        List<String> base64chars =  String.valueOf(((Map<String,Object>) JSON.deserializeUntyped( JSON.serialize( entry ))).get('validFor')).split('');
        for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++)
        {
            if(controlEntries[index].getValue().equalsIgnoreCase(controllingVal)){
            Object controlValue = (controlEntries == null ? (Object) (index == 1):(Object) (controlEntries[ index ].isActive() ? controlEntries[ index ].getLabel() : null));
            system.debug('controlValue'+controlValue+ 'index'+index);
            Integer bitIndex = index / 6, bitShift = 5 - Math.mod( index, 6 );
             if  ( controlValue != null &&  (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) != 0)
             IsValid = true;
            break;
           } 
        }
    }
    return IsValid;
}
   
  }