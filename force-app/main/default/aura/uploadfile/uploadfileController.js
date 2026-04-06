({
     doInit: function(component, event, helper) {
         var url_string = window.location.href;
         var url = new URL(url_string);
         var caseId = url.searchParams.get("id");
         var casenumber = url.searchParams.get("casenumber");
         component.set("v.parentId", caseId);
         component.set("v.casenumber", casenumber);
    },
    handleUploadFinished: function (component, event) {
        // This will contain the List of File uploaded data and status
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/viewcase?id="+component.get("v.parentId")
        });
        urlEvent.fire();
    },
    attachfile: function(component, event, helper) {
        var action = component.get("c.getPickListValuesIntoList");
        action.setCallback(this, function(a) {
            component.set("v.caseObj", a.getReturnValue().caseObj.id);
        });
        $A.enqueueAction(action);
    },
    awsLoad : function(component, event, helper) {
        try{
             component.set("v.attfiles",event.getSource().get("v.files"));
        }
        catch(e){
        }
        
    },
    handleFilesChange : function (cmp, event,helper) {
        cmp.set("v.showUpload",true);
        var FileBucketName  = 'support-case-attachments';
        var bucketRegion = 'us-west-1';
        var bucketDomain = 'https://s3-us-west-1.amazonaws.com/';
        
        var creds = new AWS.Credentials('', '', '');   
        var url_string = window.location.href;
        var url = new URL(url_string);
        var caseId = url.searchParams.get("id");
        var CaseFolderName = caseId;
        var securityNum = Math.floor((Math.random() * 1000000) + 1);
        
        AWS.config.update({
            region: bucketRegion,
            credentials: creds              
        });
        
        AWS.config.credentials.get(function(err) {
            if (err) {
                alert('Error Connecting to File Services');
            }
            
            else console.log();
        });
        
        var s3 = new AWS.S3({
            apiVersion: '2006-03-01',
            params: {Bucket: FileBucketName }
        });     
        var files = cmp.get("v.attfiles");
        var file = files[0];
        var fileSize=file.size;
        var fileName = file.name;
        
        fileSize = fileSize.toString();        
        var url_string = window.location.href;
        var url = new URL(url_string);
        var caseId = url.searchParams.get("id");
        //alert(caseid);
        
        var FolderKey = encodeURIComponent(CaseFolderName) + '/';
        
        var fileKey = FolderKey + securityNum +'/' + fileName;
        var uploadStatus = "unknown";
        var fullPath = bucketDomain + FileBucketName+"/"+fileKey;
        var options = {partSize: 5 * 1024 * 1024, queueSize: 4};
        helper.attachfileHelper(cmp,event,helper , cmp.get("v.parentId"), fileSize, fileName, fullPath, "Upload Successful");   
        var request = s3.upload({
            Key: fileKey,
            Body: file,
            ACL: 'public-read'
        },options, function(err, data) {
            //call back if uploaded really fast, not very useful
            if (err) {
                
                //return alert('There was an error uploading: ', err.message);
            }else{
                //alert('Success.');
             //helper.attachfileHelper(cmp,event,helper , cmp.get("v.parentId"), fileSize, fileName, fullPath, "Upload Successful");   
            }
        });
        request.on('httpUploadProgress', function (progress) {
             
            //console.log(progress.loaded + " of " + progress.total + " bytes");
            //document.getElementById('result_nav').innerHTML = "Upload Status: "+ ((progress.loaded / progress.total)*100).toFixed(4)+"% <br/><button onclick='request.abort();'>Abort</button><br/>Uploads are in 40 mb chunks, Abort will trigger on the next chucnk)"; 
            document.getElementById('result_nav').innerHTML = "Upload Status: "+ ((progress.loaded / progress.total)*100).toFixed(4)+"%";
            document.getElementById('result_nav').innerHTML = "Upload Status: "+ ((progress.loaded / progress.total)*100).toFixed(4)+"%";
            document.getElementById('progressbar1').style.width = ((progress.loaded / progress.total)*100).toFixed(4)+"%";
            
            
        });
        request.send(function(err, data) {
            
            var spinner = cmp.find("fileSpinner");
            $A.util.removeClass(spinner,'slds-hide');
            if (err) {
                uploadStatus = "Upload Failed";
               // passFileSizeToController2(caseid, fileSize, fileName, fullPath, uploadStatus); 

                //alert('call from error');
                document.getElementById('result_nav').innerHTML = "Upload Status: Failed"; 
                //return alert('There was an error uploading: ', err.message);
            }else{
                uploadStatus = "Upload Successful";
                //helper.attachfileHelper(cmp,event,helper , cmp.get("v.parentId"), fileSize, fileName, fullPath, uploadStatus);
                
                if(cmp.get("v.isUploaded") == true){
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": "/viewcase?id="+cmp.get("v.parentId")
                    });
                    urlEvent.fire();
                }else{
                    cmp.set("v.isUploaded",true);
                }
            }
        });
    }
})