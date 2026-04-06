({
    doInit : function(component, event, helper) {
        var params = window.location.search;
        params = params.replace('?','');
        params = params.split('&');
        var parammap = new Object();
        for(var i = 0; i < params.length; i++){
            var data = params[i].split('=');
            parammap[data[0]] = data[1].replaceAll('+',' ');
        }
        var categ = parammap["type"];

        //Commented this as we are decoding the parameter in the next line
        /*if(categ == 'GettingStarted')
            categ = 'Getting Started';*/

        component.set("v.clickedCateg", decodeURIComponent(categ));
        helper.getannouncements(component, event, helper);
    },

    pageChange : function(component,event,helper){
        helper.pageFunc(component,event,helper);
    },

    nextPage : function(component,event,helper){
        helper.nextPageFunc(component,event,helper);
    },

    getCategFilter : function(component, event, helper){
        var catg = event.getParam("CategFilter");
        var typeClicked = document.getElementById(catg);

        component.set("v.selectedcateg", catg);
        var m  = window;
        var hrefNew = m.location.search;
        hrefNew = hrefNew.split('=');
        m.location.search = hrefNew[0]+"="+catg;
        var catg = event.getParam("CategFilter");
        helper.getarticlevalue(component);
    },

    openCateg : function(component, event, helper) {
        var sideBarOpen = document.getElementById("myCategbar").style.width = "337px";
    },

    closeCateg : function(component, event, helper) {
        var sideBarOpen = document.getElementById("myCategbar").style.width = "0";
    },

    changeCateg : function(component, event, helper){
       var  category = event.target.id;
       var cat = category;
        console.log('cat---' , cat);
        var typeClicked = document.getElementById(category);
        if(!$A.util.isEmpty(typeClicked)){
            typeClicked.classList.add('activeImages')
            typeClicked.classList.remove('icons')
        }
        component.set("v.clickedCateg", cat);
        helper.getannouncements(component, event, helper);
        /*var communityBaseURL = $A.get("$Label.c.Community_Base_URL");
        var newURL= communityBaseURL+'announcements?type='+cat;
        location.replace(newURL);*/
    },

    //CS21-696 - Using announcement filters on the Support Portal results in "No Records Found"
    changeCategWithoutReloading : function(component, event, helper){
        //Fetch the category clicked
        let category = event.target.id;
        component.set("v.clickedCateg", category);

        //Retrieve the portal news belonging to the selected category
        component.set('v.pageNum', 1);
        helper.getannouncements(component, event, helper);

        //Push the new URL to history so that window doesn't need to be refreshed to update the URL
        let url = new URL(window.location);
        url.searchParams.set('type', category);
        window.history.pushState({}, '', encodeURI(url));
    },

    closeBttn :function(component, event, helper) {
        component.set("v.ModalOpen", false);
    },
})