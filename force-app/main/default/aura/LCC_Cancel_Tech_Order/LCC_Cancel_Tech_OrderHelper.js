({
  getOrder: function (action, rmaId, orderType, orderSubType) {
    return new Promise((resolve, reject) => {
      action.setParams({ rmaId, orderType, orderSubType });
      action.setCallback(this, function (response) {
        let state = response.getState(); 
        if (state === 'SUCCESS') {
          resolve(response.getReturnValue());
        } else if (state === 'ERROR') {
          let errors = response.getError();
          let message = 'Unknown error';
          if (errors && Array.isArray(errors) && errors.length > 0) {
            message = errors[0].message;
          }
          console.error(message);
          reject(message);
        } else {
          console.error('Failed with state: ' + state);
        }
      });
      $A.enqueueAction(action);
    });
  },
  cancelOrder: function (action, orderId, component) {
    return new Promise((resolve, reject) => {
      action.setParams({ orderId });
      action.setCallback(this, function (response) {
        let state = response.getState();
        if (state === 'SUCCESS') {
          resolve();
          $A.get('e.force:showToast')
            .setParams({
              title: 'Success',
              duration: 1000,
              type: 'success',
              message: 'Order Cancelled'
            })
            .fire();
          $A.get('e.force:closeQuickAction').fire();
        } else if (state === 'ERROR') {
          let errors = response.getError();
          let message = 'Unknown error';
          if (errors && Array.isArray(errors) && errors.length > 0) {
            message = errors[0].message;
          }
          console.error(message);
          reject(message);
        } else {
          console.error('Failed with state: ' + state);
        }
      });
      $A.enqueueAction(action);
    });
  },
  showErrorToast: function () {
    let toastEvent = $A.get('e.force:showToast');
    toastEvent.setParams({
      mode: 'sticky',
      type: 'error',
      title: 'Error!',
      message: 'Contact Admin Unexpected Error'
    });
    toastEvent.fire();
  }
});