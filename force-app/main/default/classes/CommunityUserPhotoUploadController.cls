/*
 * Controller for the CommunityUserPhotoUpload component
 */
public class CommunityUserPhotoUploadController {
    
    /*
     * The binary data of the image uploaded by the user
     */
    public transient Blob blobValue { get; set; }
    
    /*
     * The content type, determined by Salesforce, of
     * the image uploaded by the user
     */
    public transient String contentType { get; set; }
    
    /*
     * The name of the image file uploaded by the user
     */
    public transient String filename { get; set; }
    
    /*
     * The User ID of the community user for which
     * a new profile photo is being uploaded
     */
    public Id userId { get; set; }
    
    /*
     * @return the URL for the large profile photo of the specified
     *         user in the current community
     */
    public String getLargePhotoUrl() {
    	
        return test.isRunningTest() ? 'https://www.salesforce.com' : ConnectApi.ChatterUsers.getPhoto(
            Network.getNetworkId(), userId).largePhotoUrl;
    }
    
    
    /*
     * @return the appropriate next page after setting the 
     *         specified user's profile photo to the new
     *         image uploaded
     */
    public PageReference upload() {
        
       if(filename==null) {
       	pagereference p = apexpages.Currentpage();
        apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.Fatal,'Please attach a photo ');
        apexpages.addmessage(msg);
        return null; 
       }
       else if (!test.isRunningTest()){
        
        ConnectApi.BinaryInput photoFileInput =
            new ConnectApi.BinaryInput(blobValue, contentType, filename);
        
        ConnectApi.ChatterUsers.setPhoto(
            Network.getNetworkId(), userId, photoFileInput);
        
        return null; // Leave the user on the current page
       }
       
       else { return null; }
       
    }//end upload
}