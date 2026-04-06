/***********************************************************************************************************
      * Class Name          : ReplacementFieldMetadata
      * Date Created/Modified: 24/05/2024
      * Author               : Rahul
      * @description         : This method fetches the mock custom metadata details
/**********************************************************************************************************/
public virtual class ReplacementFieldMetadata {
  static ReplacementFieldMetadata service = new ReplacementFieldMetadata();
  /***********************************************************************************************************
    * Method Name          : setMock
    * Date Created/Modified: 24/05/2024
    * Author               : Rahul
    * @description         : This method fetches the mock custom metadata details
    * @param mock
  /**********************************************************************************************************/
  @TestVisible
  static void setMock(ReplacementFieldMetadata mock) {
      service = mock;
  }
  /***********************************************************************************************************
    * Method Name          : getAll
    * Date Created/Modified: 24/05/2024
    * Author               : Rahul
    * @description         : This method fetches the quote details
    * @return              : getAllInternal
  /**********************************************************************************************************/
  public static List<Replacement_Field_Mapping__mdt> getAll() {
      return service.getAllInternal();
  }
  /***********************************************************************************************************
    * Method Name          : getQuoteDetails
    * Date Created/Modified: 24/05/2024
    * Author               : Shivani
    * @description         : This method fetches the quote details
    * @return              : List of custom metadata records
  /**********************************************************************************************************/
  @TestVisible
  protected virtual List<Replacement_Field_Mapping__mdt> getAllInternal() {
      return [SELECT Id, Product_Type_Sub_Type__c, SKU_Attribute_Fields__c FROM Replacement_Field_Mapping__mdt];
  }
}