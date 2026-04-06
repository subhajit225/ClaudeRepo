({
  onRecordIdChange: function (component, event, helper) {
    var newRecordId = component.get('v.recordId');
    if (newRecordId) {
      component.set('v.recordIdAvailable', true);
      component.set('v.recordId', newRecordId);
    } else {
      component.set('v.recordIdAvailable', false);
    }
    console.log('RecordId :', newRecordId);
  }
});