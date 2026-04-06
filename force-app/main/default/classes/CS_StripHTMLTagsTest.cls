/**
* @name CS_StripHTMLTagsTest
* @description Test class for CS_StripHTMLTags. Ensures correct HTML stripping and whitespace cleanup.
* @author 
* @date 
* @version 1.0
*/
@isTest
private class CS_StripHTMLTagsTest {
    
    /**
* @description Tests stripHTMLTags with typical HTML content.
*/
    @isTest
    static void testHTMLStripping() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            
            List<String> inputTexts = new List<String>{
                '<p>This is a <strong>test</strong> paragraph.</p>',
                    'Line 1<br/>Line 2&nbsp;&lt;Note&gt;',
                    null,
                    '<div><p>Current Status:</p><p>Open</p><p>Next Steps:</p><p>Follow up tomorrow</p></div>'
                    };
                        
                        Test.startTest();
            List<String> results = CS_StripHTMLTags.stripHTMLTags(inputTexts);
            Test.stopTest();
            
            System.assertEquals(4, results.size(), 'Should return the same number of results as inputs');
            System.assertEquals('This is a test paragraph.', results[0], 'Should strip tags and keep text');
        }
    }
    
    /**
* @description Tests stripHTMLTags with plain text input (no HTML).
*/
    @isTest
    static void testPlainTextInput() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            List<String> inputTexts = new List<String>{ 'Just plain text with no HTML.' };
                List<String> results = CS_StripHTMLTags.stripHTMLTags(inputTexts);
            System.assertEquals(1, results.size());
            System.assertEquals('Just plain text with no HTML.', results[0], 'Plain text should remain unchanged');
        }
    }
}