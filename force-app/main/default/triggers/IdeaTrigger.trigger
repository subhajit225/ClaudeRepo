trigger IdeaTrigger on Idea (after update) {
    
   for(Idea idc : Trigger.new) {
       system.debug('\n ### NumComments ' + idc.NumComments); 
       if(idc.NumComments >0) {
            IdeaComUtils.sendIdeaCommentEmail(idc.Id, idc.createdById);
        }
    }
}