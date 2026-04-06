({
    // Your renderer method overrides go here
    afterRender: function(component, helper) {
        var svg = component.find("svg_content");
        svg.forEach(function(field) {
            var value = field.getElement().innerText;
            value = value.replace("<![CDATA[", "").replace("]]>", "");
            field.getElement().innerHTML = value;
        })
        
    }
})