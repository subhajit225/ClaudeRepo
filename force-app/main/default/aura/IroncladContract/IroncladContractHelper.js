({
    downloadSoftware: function (component, event, helper, embeddedContract) {
        var releaseSoft = component.get("v.releaseId");
        
        var ironcladDownloadAgreed = component.getEvent("downloadEvent");
        ironcladDownloadAgreed.setParams({"releaseId": releaseSoft,
                                          "embeddedContract": JSON.stringify(embeddedContract)});
        ironcladDownloadAgreed.fire();
    },
    getSubString: function(startValue, endValue, response) {
        let subString = '';
        let startIdx = response.indexOf(startValue);
        let endIdx = response.indexOf(endValue, startIdx);
        if (startIdx !== -1 && endIdx !== -1 && startIdx < endIdx) {
            const valueStartIdx = startIdx + startValue.length;
            subString = response.substring(valueStartIdx, endIdx);
        }
        return subString;
    },
    getOperatingSystemDetail: function () {
        let userAgent = navigator.userAgent.toLowerCase();
 
        if (userAgent.includes("win")) {
            return "Windows";
        } else if (userAgent.includes("mac")) {
            return "Mac OS";
        } else if (userAgent.includes("linux")) {
            return "Linux";
        } else if (/android/.test(userAgent)) {
            return "Android";
        } else if (/iphone|ipad|ipod/.test(userAgent)) {
            return "iOS";
        } else {
            return "Unknown";
        }
    }, 
    detectDeviceType: function () {
        let userAgent = navigator.userAgent.toLowerCase();
        let screenWidth = window.innerWidth;

        if (/mobile|android|iphone|ipad|iemobile|wpdesktop/i.test(userAgent)) {
            return "Mobile";
        } else if (screenWidth >= 768 && screenWidth < 1024) {
            return "Tablet";
        } else {
            return "Desktop";
        }
    },
    applyCustomCSS: function () {
        var parentElement = document.querySelector('.ps-contract');
        var contractBody = parentElement.querySelector('.ps-contract-body');
        contractBody.style.maxHeight = '400px';
        contractBody.style.minHeight = 'auto';
        contractBody.style.overflow = 'auto';
        let expandCollapseBtn = document.querySelector(".ps-expand-button");
        expandCollapseBtn.style.display = "none";
        let downLoadLink = document.querySelector(".ps-download-link");
        downLoadLink.style.display = "none";
        let labelElements = document.querySelectorAll('.ps-checkbox-container');
        if (labelElements.length >= 2) {
            var secondLabelElement = labelElements[1];
            secondLabelElement.style.display = "none";
            var firstLabelElement = labelElements[0];
            firstLabelElement.style.textAlign = "center";
        }
    }
})