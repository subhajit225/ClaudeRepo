trigger Territory2ObjTrigger  on Territory2 (before update,after insert, after update) {
    new Territory2TriggersHandler().run();
}