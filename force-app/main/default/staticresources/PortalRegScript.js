$j = jQuery.noConflict();
    var domains=[
  "aol.com",
  "att.net",
  "comcast.net",
  "facebook.com",
  "gmail.com",
  "gmx.com",
  "googlemail.com",
  "google.com",
  "hotmail.com",
  "hotmail.co.uk",
  "mac.com",
  "me.com",
  "mail.com",
  "msn.com",
  "live.com",
  "sbcglobal.net",
  "verizon.net",
  "yahoo.com",
  "yahoo.co.uk",
  "email.com",
  "games.com",
  "gmx.net",
  "hush.com",
  "hushmail.com",
  "icloud.com",
  "inbox.com",
  "lavabit.com",
  "love.com",
  "outlook.com",
  "pobox.com",
  "rocketmail.com",
  "safe-mail.net",
  "wow.com",
  "ygm.com",
  "ymail.com",
  "zoho.com",
  "fastmail.fm",
  "yandex.com",
  "bellsouth.net",
  "charter.net",
  "comcast.net",
  "cox.net",
  "earthlink.net",
  "juno.com",
  "btinternet.com",
  "virginmedia.com",
  "blueyonder.co.uk",
  "freeserve.co.uk",
  "live.co.uk",
  "ntlworld.com",
  "o2.co.uk",
  "orange.net",
  "sky.com",
  "talktalk.co.uk",
  "tiscali.co.uk",
  "virgin.net",
  "wanadoo.co.uk",
  "bt.com",
  "sina.com",
  "qq.com",
  "naver.com",
  "hanmail.net",
  "daum.net",
  "nate.com",
  "yahoo.co.jp",
  "yahoo.co.kr",
  "yahoo.co.id",
  "yahoo.co.in",
  "yahoo.com.sg",
  "yahoo.com.ph",
  "hotmail.fr",
  "live.fr",
  "laposte.net",
  "yahoo.fr",
  "wanadoo.fr",
  "orange.fr",
  "gmx.fr",
  "sfr.fr",
  "neuf.fr",
  "free.fr",
  "gmx.de",
  "hotmail.de",
  "live.de",
  "online.de",
  "t-online.de",
  "web.de",
  "yahoo.de",
  "mail.ru",
  "rambler.ru",
  "yandex.ru",
  "ya.ru",
  "list.ru",
  "hotmail.be",
  "live.be",
  "skynet.be",
  "voo.be",
  "tvcablenet.be",
  "telenet.be",
  "hotmail.com.ar",
  "live.com.ar",
  "yahoo.com.ar",
  "fibertel.com.ar",
  "speedy.com.ar",
  "arnet.com.ar",
  "hotmail.com",
  "gmail.com",
  "yahoo.com.mx",
  "live.com.mx",
  "yahoo.com",
  "hotmail.es",
  "live.com",
  "hotmail.com.mx",
  "prodigy.net.mx",
  "msn.com",
  "yahoo.com.br",
  "hotmail.com.br",
  "outlook.com.br",
  "uol.com.br",
  "bol.com.br",
  "terra.com.br",
  "ig.com.br",
  "itelefonica.com.br",
  "r7.com",
  "zipmail.com.br",
  "globo.com",
  "globomail.com",
  "oi.com.br"
];
    var btn;
    var validateData = function() {
        var isValid = true;
        var isErrorShown = false;
        $j(".required").each(function() {
            if(!$j(this).prop("value")) {
                if(isErrorShown == false) {
                    validateField(this);
                    isErrorShown = true;
                }
                isValid = false;
                $j(this).css("border-color", "#8C0005");
            } else {
                $j(this).css("border-color", "#aeb0b6");
            }
        });
        console.log('isValid'+isValid);
        if(isValid == true) {
            
            if(validateEmailField() && validateCheckboxField() ){
                console.log('in save button');
                saveRecord();
                
            }
            else
                return false;
        }
        else{
            console.log('in else');
            console.log(btn);
            btn.disabled = false;
            btn.value = 'Submit';
            return false;
        } 

    }
    
    var hideError = function() {
        $j(".dealRError").fadeOut(500);
        $j(".dealRError").remove();
    }
    
    var validateField = function(thisComponent) {
        $j(".dealRError").fadeOut(500);
        $j(".dealRError").remove();

        if( ! $j(thisComponent).prop("value") ) {
            $j(thisComponent).css("border-color", "#8C0005");
            
            var errorContent = "<div class='dealRError' style='right: 5.5px; margin-bottom: -34px; z-index: 100; position: relative;'><div class='dealRErrorArrowWrap' style='position: initial;'><div class='dealRErrorArrow'></div></div><div class='dealRErrorMsg' style=''>This field is required.</div></div>";

            if($j(thisComponent).hasClass("email")) {
                errorContent = "<div class='dealRError' style='right: 5.5px; margin-bottom: -34px; position: relative;'><div class='dealRErrorArrowWrap' style='position: initial;'><div class='dealRErrorArrow'></div></div><div class='dealRErrorMsg'>Please use your corporate email, e.g. <span class='dealRErrorDetail'>example@companyname.com</span></div></div>";
            }
            
            if($j(thisComponent).hasClass("phone")) {
                errorContent = "<div class='dealRError' style='right: 5.5px; margin-bottom: -34px; position: relative;'><div class='dealRErrorArrowWrap' style='position: initial;'><div class='dealRErrorArrow'></div></div><div class='dealRErrorMsg'>Must be a phone number. <span class='dealRErrorDetail'>503-555-1212</span></div></div>";
            }

            if(! $j(thisComponent).parent().find(".dealRError").length)
                $j(thisComponent).after($j(errorContent).fadeIn(500));
            
            
        } else {
            $j(thisComponent).css("border-color", "#aeb0b6");
        }
        
    }
    
    var validateEmailField = function() {
        $j(".dealRError").fadeOut(500);
        $j(".dealRError").remove();
        
        var isValidEmail =true;
    $j(".email").each(function() {
        var errorContent ;
            if($j(this).hasClass("email")) {
                console.log('in email loop');
                console.log('value--'+$j(this).prop("value"));
                console.log('substr--'+$j(this).prop("value").substr($j(this).prop("value")));
                console.log('substr index--'+$j(this).prop("value").substr($j(this).prop("value").indexOf('@')+1));
               if($j.inArray( $j(this).prop("value").substr($j(this).prop("value").indexOf('@')+1), domains )> -1){
                   $j(this).css("border-color", "#8C0005");
                var errorContent = "<div class='dealRError' style='right: 5.5px; margin-bottom: -34px; z-index: 100; position: relative;'><div class='dealRErrorArrowWrap' style='position: initial;'><div class='dealRErrorArrow'></div></div><div class='dealRErrorMsg'>Please use your corporate email, e.g. <span class='dealRErrorDetail'>example@companyname.com</span></div></div>";
                   if(! $j(this).parent().find(".dealRError").length)
                   $j(this).after($j(errorContent).fadeIn(500));
                    isValidEmail= false;   
                } 
                else {
                    $j(this).css("border-color", "#aeb0b6");
                }
            }
        });
        return isValidEmail;
     }
    
    var validateCheckboxField = function() {
        //$j(".dealRError").fadeOut(500);
        //$j(".dealRError").remove();
        console.log('in checkbox loop');
        var ischecked =true;
    $j(".checkbox").each(function() {
        var errorContent ;
            if($j(this).hasClass("checkbox")) {
                console.log('in checkbox loop 22');
                console.log('value--'+$j(this).is(":checked"));
               if($j(this).is(":checked")){
                   $j(this).css("border-color", "#aeb0b6");
                } 
                else {
                    console.log('value--inside ');
                    $j(this).css("border-color", "#8C0005");
                var errorContent = "<div class='dealRError' style='right: 5.5px; margin-bottom: -34px; z-index: 100; position: relative;'><div class='dealRErrorArrowWrap' style='position: initial;'><div class='dealRErrorArrow'></div></div><div class='dealRErrorMsg'>Please select the checkbox <span class='dealRErrorDetail'></span></div></div>";
                
                   if(! $j(this).parent().find(".dealRError").length)
                   $j(this).after($j(errorContent).fadeIn(500));
                    ischecked= false; 
                }
            }
        });
        return ischecked;
     }