global class RubrikSupportUrlWriterClass  implements Site.UrlRewriter{
    String oldKbPage = '/articles/How_To/';
    String newKbUrl = '/s/article/';

    
    global PageReference mapRequestUrl(PageReference yourFriendlyUrl){
        String url = yourFriendlyUrl.getUrl();
        
        if(url.startsWith(oldKbPage)){
            url.replace(oldKbPage,newKbUrl);
        }
        return new PageReference(url);
    }
    global PageReference[] generateUrlFor(PageReference[] yourSalesforceUrls){
        return null;
    }
}