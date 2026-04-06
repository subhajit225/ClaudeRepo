({
    doInit: function(component, event, helper) { 
        console.log('ssss');
        helper.getValue(component,event,helper);
    },
    
    slideRight : function(component, event, helper) {
        var sizeVideo = 4;
        var isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
		if (isMobile) {
  			sizeVideo = 2;
		} 
        var button = document.getElementById('slide');
        var e = document.getElementById('container').scrollLeft += (document.getElementById('container').offsetWidth/sizeVideo);
        var sW = document.getElementById('container').scrollWidth;
        var oSW = document.getElementById('container').offsetWidth;
        var sL = document.getElementById('container').scrollLeft;
        component.set("v.disright", false);
        component.set("v.disLeft", false);
        if(sW <= (2*sL)+oSW){
            component.set("v.disright", true);
        }
    },
    
    slideLft  : function(component, event, helper) {
        var sizeVideo = 4;
        var isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
        if (isMobile) {
            sizeVideo = 2;
        } 
        var button = document.getElementById('slideleft');
        console.log(document.getElementById('container').scrollLeft);
        var e = document.getElementById('container').scrollLeft -= (document.getElementById('container').offsetWidth/sizeVideo);
       var sW = document.getElementById('container').scrollWidth;
        var oSW = document.getElementById('container').offsetWidth;
        var sL = document.getElementById('container').scrollLeft;
        component.set("v.disLeft", false);
        component.set("v.disright", false);
        if(sL- (oSW/sizeVideo) < 1){
             component.set("v.disLeft", true);
        }
    },
    openModal : function(component, event, helper) {
        component.set("v.ModalOpen", true);
        component.set("v.VideosSummary", event.target.id);
         component.set("v.videoTitle", event.target.title);
    },
    closeModal : function(component, event, helper) {
      component.set("v.ModalOpen", false);
    }
})