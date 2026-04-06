({
    doInitialization: function (component, event, helper) {
        var assignNested = component.get("v.assignNested");
        var loadingResult = component.get("v.assignNested") ? 1 : 0;
        var iterateNested = Object.assign([], assignNested);
        component.set("v.loadingResult", 1);
        component.set("v.iterateNested", iterateNested);
    },
    checkCheckbox: function (component, event, helper) {
        var vx = component.get("v.parent");
        var sr = {};
        sr["Contentname"]= event.target.getAttribute('name');
        sr["immediateParent"]= event.target.getAttribute('min');
        sr["parent"]= event.target.getAttribute('step');
        sr["level"]= event.target.getAttribute('accessKey');
        sr["path"]= event.target.getAttribute('data-path') ? event.target.getAttribute('data-path').split(',') : '';
        sr["checkedProp"]= document.getElementById(event.target.id).checked;
        sr["checked"]= document.getElementById(event.target.id).checked;

        vx.typeSelect(sr);
    }
})