@IsTest
public class PostMetaDataUpdateCallbackTest {
    @IsTest
    static void testDeloyMethod() { 
        Metadata.DeployCallback callback = new PostMetaDataUpdateCallback();
        Metadata.DeployResult result = new Metadata.DeployResult();
        result.numberComponentErrors = 1;
        Metadata.DeployCallbackContext context = new Metadata.DeployCallbackContext();
        callback.handleResult(result, context);
    }
}