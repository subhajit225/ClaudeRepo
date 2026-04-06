@RestResource(urlMapping='/validateAsset')
global class RefreshConversionAssetValidation {
 
    @HttpGet
    global static String assetValidation() {
        RestRequest request = RestContext.request;
        String saasAssets = request.params.get('ba');
        String supportAssets = request.params.get('sa');
        String errorMessage = '';

        List<String> saasAssetsDuplicate = saasAssets.split(',');
        Set<String> saasAssetsUnique = new Set<String>();

        List<String> supportAssetsDuplicate = supportAssets.split(',');
        Set<String> supportAssetsUnique = new Set<String>();

        for (String aName : saasAssetsDuplicate) {
            aName = aName.trim();
            
            if (String.isBlank(aName)) continue;
            
            if (aName != 'undefined' && aName != 'null') {
                if (saasAssetsUnique.contains(aName)) {
                    return 'The same asset may not be selected for both refresh and conversion. Please remove one of them from the quote before proceeding.';
                }

                saasAssetsUnique.add(aName);
            }
        }

        for (String aName : supportAssetsDuplicate) {
            aName = aName.trim();
            
            if (String.isBlank(aName)) continue;
        
            if (aName != 'undefined' && aName != 'null') {
                if (supportAssetsUnique.contains(aName)) {
                    return 'The same asset may not be selected for both refresh and conversion. Please remove one of them from the quote before proceeding.';
                }

                supportAssetsUnique.add(aName);
            }
        }
        
        return '';
    }

    
}