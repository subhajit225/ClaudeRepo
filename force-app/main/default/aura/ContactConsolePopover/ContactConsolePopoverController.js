({
 

  onFilterClick: function( component, event, helper ) {
    component.set('v.isFilterClosed', false);
      if(!component.get( 'v.isFilterClosed' )){
          window.setTimeout(
              $A.getCallback(function() {
                  component.find('filterIdTop').getElement().focus();
              }), 7
          );
          
      }
  },


    cancel: function( component, event, helper ) {
        window.setTimeout(
            $A.getCallback(function() {
                component.set('v.isFilterClosed', true);
            }), 200
        );
        
    },

 
})