trigger UserTerritory2AssociationTrigger on UserTerritory2Association (before insert, before update, after insert,after update,after delete) { //SAL21-320
   system.debug('In Delete trigger UTA');
    new UserTerritory2AssociationTriggerHandler().run();
}