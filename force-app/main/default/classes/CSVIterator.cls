/**
* @Author      : Vijay Kumar K R
* @CreatedDate : 24 June, 2023
* @TstClass    : OktaUserMigrationCsvBatchableTest
* @Description : To process Okta Migrated Users csv file and return rows back to OktaUserMigrationCsvBatchableTest
* -------------------------- @History -------------------------------------
* Story Number       Modified By              Date           Description
* 
* -------------------------------------------------------------------------
*/
global with sharing class CSVIterator implements Iterator<String>, Iterable<String>
{
   private String m_CSVData;
   private String m_introValue;

   /**
     * Params  :   String fileData, String introValue
    */
   public CSVIterator(String fileData, String introValue)
   {
      m_CSVData = fileData;
      m_introValue = introValue; 
   }

   /**
     * Params  :  
    */
   global Boolean hasNext()
   {
      return m_CSVData.length() > 1 ? true : false;
   }

   /**
     * Params  :  
    */
   global String next()
   {
      String row = '';
      if(m_CSVData.indexOf(m_introValue) != -1){
         row = m_CSVData.subString(0, m_CSVData.indexOf(m_introValue));
         m_CSVData = m_CSVData.subString(m_CSVData.indexOf(m_introValue) + m_introValue.length(),m_CSVData.length());
      }else{
         row = m_CSVData;
         m_CSVData = '';
      }
      return row;
   }

   /**
     * Params  : 
    */
   global Iterator<String> Iterator()
   {
      return this;   
   }
}