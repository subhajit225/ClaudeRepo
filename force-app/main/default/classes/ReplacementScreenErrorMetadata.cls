/***********************************************************************************************************
      * Class Name          : ReplacementScreenErrorMetadata
      * Date Created/Modified: 11/07/2024
      * Author               : Ankita
      * @description         : This method fetches the mock custom metadata details
/**********************************************************************************************************/
public virtual class ReplacementScreenErrorMetadata {
    static ReplacementScreenErrorMetadata service = new ReplacementScreenErrorMetadata();
    /***********************************************************************************************************
      * Method Name          : setMock
      * Date Created/Modified: 11/07/2024
      * Author               : Ankita
      * @description         : This method fetches the mock custom metadata details
      * @param mock
    /**********************************************************************************************************/
    @TestVisible
    static void setMock(ReplacementScreenErrorMetadata mock) {
        service = mock;
    }
    /***********************************************************************************************************
      * Method Name          : getAll
      * Date Created/Modified: 11/07/2024
      * Author               : Ankita
      * @description         : This method fetches the quote details
      * @return              : getAllInternal
    /**********************************************************************************************************/
    public static List<SMS_Exceptions_Owner__mdt> getAll() {
        return service.getAllInternal();
    }
    /***********************************************************************************************************
      * Method Name          : getQuoteDetails
      * Date Created/Modified: 11/07/2024
      * Author               : Ankita
      * @description         : This method fetches the quote details
      * @return              : List of custom metadata records
    /**********************************************************************************************************/
    @TestVisible
    protected virtual List<SMS_Exceptions_Owner__mdt> getAllInternal() {
        return [SELECT Id, Profile_Name__c, Exception_Message__c FROM SMS_Exceptions_Owner__mdt];
    }
}