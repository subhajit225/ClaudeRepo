public class PostMetaDataUpdateCallback implements Metadata.DeployCallback {
  
    public void handleResult(Metadata.DeployResult result,
        Metadata.DeployCallbackContext context) {
        
        if (result.status == Metadata.DeployStatus.Succeeded) {
            System.debug('Deployment Succeeded!');
        } else {
           
        System.debug('Deployment Failed! because'+result.errorMessage);
        System.debug('result msg'+result);
        }
    }
}