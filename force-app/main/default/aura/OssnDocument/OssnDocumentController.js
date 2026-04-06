({
    doinit: function (component, event, helper) {
        document.addEventListener("keyup", function (ev) {
            return false;
        });  
        document.addEventListener('copy', function (e) {
            e.preventDefault();
        });
        document.addEventListener('keydown', function (e) {
            if (e.key == 123) {
                e.preventDefault();
            }
            if (e.ctrlKey && e.shiftKey && e.key == 'I') {
                e.preventDefault();
            }
            if (e.ctrlKey && e.shiftKey && e.key == 'C') {
                e.preventDefault();
            }
            if (e.ctrlKey && e.shiftKey && e.key == 'J') {
                e.preventDefault();
            }
            if (e.ctrlKey && e.key == 'U') {
                e.preventDefault();
            }
        });
        document.addEventListener("beforeprint", function (event) {});
        window.addEventListener("beforeprint", function (event) {});
        window.addEventListener('contextmenu', (e) => {
            e.preventDefault();
        }, false);
            document.addEventListener('contextmenu', (e) => {
                e.preventDefault();
            }, false);
       

        /// Get the user-agent string
        let userAgentString =
            navigator.userAgent;
        let chromeAgent =
            userAgentString.indexOf("Chrome") > -1;
        // Detect Firefox
        let firefoxAgent =
            userAgentString.indexOf("Firefox") > -1;
        if (chromeAgent) {
            component.set("v.isChrome", true);
        }
        if (!chromeAgent && !firefoxAgent) {
            component.set("v.isSafari", true);
        }

        var pageName = window.location.pathname;

        if (pageName != null && pageName.includes('/s/')) {
            pageName = pageName.split('/s/')[1];
            if (pageName != null && pageName.includes('/')) {
                pageName = pageName.split('/')[0];

            }
        }
        var action = component.get("c.getOssnDocument");
        action.setParams({
            pageName: pageName
        });
        action.setCallback(this, function (resp) {
            console.log(' resp.getReturnValue()', resp.getReturnValue());
            component.set("v.URL", resp.getReturnValue());
        });
        $A.enqueueAction(action);
    },
    frameLoad: function (component, event, helper) {
        if (component.get("v.isLoad")) {
            setInterval(function () {
                var frame = document.getElementById("frameBlock");
                if (!frame) {
                    location.reload();
                } else {
                    var enableClick = component.get("v.enableClick");
                    frame.addEventListener("contextmenu", (e) => {
                        e.preventDefault()
                    });
                    if (!enableClick) {
                        frame.style = 'width: 99%;height: 700px;position: absolute;';
                    }
                    try {
                        frame.focus();
                        frame.click();
                    } catch (e){}
                }
                var logo = document.getElementById("logoClass");
                if (!logo) {
                    location.reload();
                } else {
                    let userAgentString =
                        navigator.userAgent;
                    let chromeAgent =
                        userAgentString.indexOf("Chrome") > -1;
                    if (chromeAgent) {
                        logo.style = 'position: absolute;width: 98.6%;height: 35px;';
                    } else {
                        logo.style = 'position: absolute;width: 100%;height: 35px;';
                    }
                }

            }, 1000);

        } else {
            component.set("v.isLoad", true);
        }
    },
    select: function (component, event, helper) {
        event.preventDefault();
        return null;
    }
})