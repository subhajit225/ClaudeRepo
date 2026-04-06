/**@description
 * Copyright (c) 2012, FinancialForce.com, inc
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 *      this list of conditions and the following disclaimer in the documentation
 *      and/or other materials provided with the distribution.
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors
 *      may be used to endorse or promote products derived from this software without
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/

/**
 * This is a dummy test class to obtain 100% coverage for the generated WSDL2Apex code, it is not a funcitonal test class
 **/
@isTest
public class MetadataServiceTest
{
    /**
     * Dummy Metadata API web service mock class (see MetadataCreateJobTest.cls for a better example)
     **/
    public class WebServiceMockImpl implements WebServiceMock
    {
        public void doInvoke(
            Object stub, Object request, Map<String, Object> response,
            String endpoint, String soapAction, String requestName,
            String responseNS, String responseName, String responseType)
        {
            if(request instanceof MetadataService.updateMetadata_element)
                //response.put('response_x', new MetadataService.updateMetadataResponse_element());
                response.put('response_x', updateMetadataSaveResults());
            else if(request instanceof MetadataService.readMetadata_element){
                MetadataService.readMetadata_element requestReadMetadata_element  = (MetadataService.readMetadata_element)request;

                if(requestReadMetadata_element.type_x == 'CustomField'){
                    MetadataService.readCustomFieldResponse_element mockRes = new MetadataService.readCustomFieldResponse_element();
                    mockRes.result = new MetaDataService.ReadCustomFieldResult();
                    mockRes.result.records = createCustomField(requestReadMetadata_element.fullNames);
                    response.put('response_x', mockRes);
                }
                else if(requestReadMetadata_element.type_x == 'GlobalValueSet'){
                    MetadataService.readGlobalValueSetResponse_element mockRes = new MetadataService.readGlobalValueSetResponse_element();
                    mockRes.result = new MetaDataService.ReadGlobalValueSetResult();
                    mockRes.result.records = createGlobalValueSet(requestReadMetadata_element.fullNames);
                    response.put('response_x', mockRes);
                }
            }  
            return;
        }

        private List<MetadataService.CustomField> createCustomField(List<String> fieldNameList){
            List<MetadataService.CustomField> customFieldList = new List<MetadataService.CustomField>();
            for(String eachField : fieldNameList){
                MetadataService.CustomField customField = new MetadataService.CustomField();
                customField.fullName = eachField;
                customField.label = eachField;
                customField.valueSet = new MetadataService.ValueSet();
                customField.valueSet.valueSettings = new List<MetadataService.ValueSettings>();
                customField.valueSet.valueSetDefinition = new MetadataService.ValueSetValuesDefinition();
                customField.valueSet.valueSetDefinition.value = new List<MetadataService.CustomValue>();
                customFieldList.add(customField);
            }
            return customFieldList;
        }

        private List<MetadataService.GlobalValueSet> createGlobalValueSet(List<String> fieldNameList){
            List<MetadataService.GlobalValueSet> globalValueSetList = new List<MetadataService.GlobalValueSet>();
            for(String eachField : fieldNameList){
                MetadataService.GlobalValueSet globalValueSet = new MetadataService.GlobalValueSet();
                globalValueSet.fullName = eachField;
                globalValueSet.customValue = new List<MetadataService.CustomValue>();
                globalValueSetList.add(globalValueSet);
            }
            return globalValueSetList;
        }

        private MetadataService.updateMetadataResponse_element updateMetadataSaveResults(){
            MetadataService.updateMetadataResponse_element metadataResponse = new MetadataService.updateMetadataResponse_element();
            MetadataService.SaveResult saveresult = new MetadataService.SaveResult();
            saveresult.errors = new List<MetadataService.Error>();
            saveresult.fullName = 'Test response';
            saveresult.success = true;
            metadataResponse.result = new List<MetadataService.SaveResult>();
            metadataResponse.result.add(saveresult);

            return metadataResponse;
        }
    }

    @IsTest
    private static void coverGeneratedCodeCRUDOperations()
    {
        // Null Web Service mock implementation
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        // Only required to workaround a current code coverage bug in the platform
        MetadataService metaDataService = new MetadataService();
        User usrTest = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        // Invoke operations
        System.runAs(usrTest) {
            Test.startTest();
            MetadataService.MetadataPort metaDataPort = new MetadataService.MetadataPort();
            System.assert(metaDataPort!=null, 'it should not be null.');
            Test.stopTest();
        }
    }

    @IsTest
    private static void coverGeneratedCodeFileBasedOperations1()
    {
        // Null Web Service mock implementation
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        // Only required to workaround a current code coverage bug in the platform
        MetadataService metaDataService = new MetadataService();
        User usrTest = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        // Invoke operations
        System.runAs(usrTest) {
            Test.startTest();
            MetadataService.MetadataPort metaDataPort = new MetadataService.MetadataPort();
            MetadataService.SaveResult[] res = metaDataPort.updateMetadata(null);
            System.assert(res!=null, 'it should not be null.');
            Test.stopTest();
        }
    }

    @IsTest
    private static void coverGeneratedCodeFileBasedOperations2()
    {
        // Null Web Service mock implementation
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        // Only required to workaround a current code coverage bug in the platform
        MetadataService metaDataService = new MetadataService();
        User usrTest = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        // Invoke operations
        System.runAs(usrTest) {
            Test.startTest();
            MetadataService.MetadataPort metaDataPort = new MetadataService.MetadataPort();
            System.assert(metaDataPort!=null, 'it should not be null.');
            Test.stopTest();
        }
    }

    @IsTest
    private static void coverGeneratedCodeTypes()
    {
        // Reference types
        User usrTest = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(usrTest) {
            Test.startTest();
            MetadataService metaDataService = new MetadataService();
            new MetadataService.CustomField();
            new MetadataService.GlobalValueSet();
            new MetadataService.ValueSettings();
            new MetadataService.DebuggingInfo_element();
            new MetadataService.DebuggingHeader_element();
            new MetadataService.SaveResult();
            new MetadataService.CallOptions_element();
            new MetaDataService.AllOrNoneHeader_element();
            new MetadataService.updateMetadata_element();
            new MetadataService.readMetadata_element();
            new MetadataService.ValueSet();
            new MetadataService.LogInfo();
            new MetadataService.updateMetadataResponse_element();
            new MetadataService.LookupFilter();
            new MetadataService.FilterItem();
            new MetadataService.ValueSetValuesDefinition();
            new MetadataService.Error();
            new MetadataService.readCustomFieldResponse_element();
            new MetadataService.ReadCustomFieldResult();
            new MetadataService.ReadRecordTypeResult();
            System.assert(metaDataService!=null, 'it should not be null.');
            Test.stopTest();
        }
    }

    @IsTest
    private static void elfMissingGetRecordsTest() { // elf patch
        User usrTest = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(usrTest) {
            Test.startTest();
            MetadataService.Metadata[] metaRes = new MetadataService.ReadGlobalValueSetResult().getRecords();
            System.assert(metaRes==null, 'it should be null as we are sending null.');
            Test.stopTest();
        }
    }

    @IsTest
    private static void elfMissingGetResultTest() { // elf patch
        User usrTest = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(usrTest) {
            Test.startTest();
            MetadataService.IReadResult result = new MetadataService.ReadGlobalValueSetResponse_element().getResult();
            System.assert(result==null, 'it should be null as we are sending null.');
            Test.stopTest();
        }
    }
    @IsTest
    private static void recordTypeResultTest() { // elf patch
        User usrTest = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(usrTest) {
            Test.startTest();
            MetadataService.RecordType record1 = new MetadataService.RecordType();
            MetadataService.RecordType record2 = new MetadataService.RecordType();
            MetadataService.RecordType[] recordArray = new MetadataService.RecordType[]{record1, record2};
                
            MetadataService.ReadRecordTypeResult readResult = new MetadataService.ReadRecordTypeResult();
            readResult.records = recordArray;
            
            MetadataService.Metadata[] result = readResult.getRecords();
           
            System.assertEquals(2, result.size(), 'Result size should be 2');
            Test.stopTest();
        }
    }
    @isTest
    public static void testRecordTypePicklistValue() {
        // Arrange
        MetadataService.PicklistValue value1 = new MetadataService.PicklistValue();
        MetadataService.PicklistValue value2 = new MetadataService.PicklistValue();
        MetadataService.PicklistValue[] picklistValues = new MetadataService.PicklistValue[]{value1, value2};
        User usrTest = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(usrTest) {
            Test.startTest();
            MetadataService.RecordTypePicklistValue picklistValue = new MetadataService.RecordTypePicklistValue();
            picklistValue.picklist = 'TestPicklist';
            picklistValue.values = picklistValues;
            
            // Act & Assert
            System.assertEquals('TestPicklist', picklistValue.picklist, 'Picklist name should match');
            Test.stopTest();
        }
    }
}