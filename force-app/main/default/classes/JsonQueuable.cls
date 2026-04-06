/**************************************************************************************************
 * @description       : JsonQueuable
 * @author            : Prashant Kumar
 * @last modified on  : 10-10-2025
 * Modifications Log
 * Ver   Date          Author        Modification
 ******************************************************************************/
public class JsonQueuable implements Queueable {
  String jsonInput;

  // Constructor to accept parameters
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description constructor to set jsonInput
   * @param jsonInput
   */
  public JsonQueuable(String jsonInput) {
    this.jsonInput = jsonInput;
  }
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description execute method for queuable.
   * @param context
   */
  public void execute(QueueableContext context) {
    Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(jsonInput);
    String sObjectType = (String) data.get('sObjectType');
    String recordId = (String) data.get('Id');
    Map<String, Object> fieldsToUpdate = (Map<String, Object>) data.get('fields');
    // Build dynamic SOQL
    SObject sObj = Database.query('SELECT Id FROM ' + sObjectType + ' WHERE Id = :recordId LIMIT 1');
    if (sObj != null && fieldsToUpdate != null) {
      for (String fieldName : fieldsToUpdate.keySet()) {
        sObj.put(fieldName, fieldsToUpdate.get(fieldName));
      }
      update sObj;
    }
  }
}