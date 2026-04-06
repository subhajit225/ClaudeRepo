public class LMSCourseEnrollmentTriggerHandler {
    //This method set accediated field value on contact object
    public static void setAccreditation(Map<Id,DOCEBO2_CO__c> mapDoceboRec){
        List<Contact> finalListContact = new List<Contact>();
        Map<String,String> mapCourseName = new Map<String,String>();
        Map<String,String> mapCourseNameById = new Map<String,String>();
        Set<Id> courseId = new Set<Id>();
        for(DOCEBO1_CO__c dCourseRec: [Select Id,Name from DOCEBO1_CO__c where Name In ('C64','C83','C82','C66')])
        {
            courseId.add(dCourseRec.Id);
            mapCourseName.put(dCourseRec.Name,dCourseRec.Id);
            mapCourseNameById.put(dCourseRec.Id, dCourseRec.Name);
        }
        System.debug('mapCourseName****'+mapCourseName);
        Set<Id> setContactId = new Set<Id>();
        for(Id dId: mapDoceboRec.keyset()){
            setContactId.add(mapDoceboRec.get(dId).Contact__c);
        }
        System.debug('setContactId****'+setContactId);
        Map<Id,Contact> mapContact = new Map<Id,Contact>([SELECT Id,PSE_Shadow_Completed__c,Name,RTP_Accredited__c,RTP_Expiration__c,RSP_Accredited__c,RSP_Expiration__c,RPSE_Accredited__c,RPSE_Expiration__c
                                                          FROM Contact where Id in: setContactId]);
        System.debug('mapContact****'+mapContact);
        List<DOCEBO2_CO__c> lstDoRec = [Select Id,Contact__c,C_DC_COURSE_STATUS__c,C_DC_COURSE_ID__c,D_DC_COURSE_COMP__c 
                                        from DOCEBO2_CO__c where (C_DC_COURSE_STATUS__c = 'COMPLETED' OR C_DC_COURSE_STATUS__c = 'COMPLETE') 
                                        AND C_DC_COURSE_ID__c In: courseId AND 
                                        D_DC_COURSE_COMP__c != null AND Contact__c IN: setContactId
                                        order by D_DC_COURSE_COMP__c DESC];
        System.debug('lstDoRec***'+lstDoRec);
        
        Map<Id,Set<String>> mapContactCourse = new Map<Id,Set<String>>();
        Map<Id,List<DOCEBO2_CO__c>> mapContactDocebo = new Map<Id,List<DOCEBO2_CO__c>>();
        for(DOCEBO2_CO__c db:lstDoRec){
            if(mapContactCourse.containsKey(db.Contact__c)){
                Set<String> allCourse = mapContactCourse.get(db.Contact__c);
                allCourse.add(db.C_DC_COURSE_ID__c);
                mapContactCourse.put(db.Contact__c,allCourse);
                
                List<DOCEBO2_CO__c> allDRecord = mapContactDocebo.get(db.Contact__c);
                allDRecord.add(db);
                mapContactDocebo.put(db.Contact__c,allDRecord);
            }
            else{
                Set<String> allCourse = new Set<String>();
                allCourse.add(db.C_DC_COURSE_ID__c);
                mapContactCourse.put(db.Contact__c,allCourse);
                
                List<DOCEBO2_CO__c> allDRecord = new List<DOCEBO2_CO__c>();
                allDRecord.add(db);
                mapContactDocebo.put(db.Contact__c,allDRecord);                
            }
        }
        System.debug('mapContactCourse****'+mapContactCourse);
        System.debug('mapContactDocebo****'+mapContactDocebo);
        for(Id conId:mapContactDocebo.keyset()){
            Contact conRec = mapContact.get(conId);
            Set<String> allCourses = mapContactCourse.get(conId);
            //RSP Calculation
            if(allCourses.contains(mapCourseName.get('C64')) && allCourses.contains(mapCourseName.get('C83'))){
                SYstem.debug('RSP True');
                for(DOCEBO2_CO__c doRec:mapContactDocebo.get(conId)){
                    if(doRec.C_DC_COURSE_ID__c == mapCourseName.get('C64') || doRec.C_DC_COURSE_ID__c == mapCourseName.get('C83')){
                        conRec.RSP_Accredited__c = doRec.D_DC_COURSE_COMP__c.date();
                        conRec.RSP_Expiration__c = conRec.RSP_Accredited__c + 365;
                        break;
                    }
                }
            }
            //RTP && RPSE Calculation
            if(allCourses.contains(mapCourseName.get('C82')) && allCourses.contains(mapCourseName.get('C66'))){
                for(DOCEBO2_CO__c doRec:mapContactDocebo.get(conId)){
                    if(doRec.C_DC_COURSE_ID__c == mapCourseName.get('C82') || doRec.C_DC_COURSE_ID__c == mapCourseName.get('C66')){
                        SYstem.debug('RTP True');
                        conRec.RTP_Accredited__c = doRec.D_DC_COURSE_COMP__c.date();
                        conRec.RTP_Expiration__c = conRec.RTP_Accredited__c + 730;
                        if(conRec.PSE_Shadow_Completed__c != null)
                        {
                            SYstem.debug('RPSE True');
                            conRec.RPSE_Accredited__c = doRec.D_DC_COURSE_COMP__c.date();
                            conRec.RPSE_Expiration__c = conRec.RPSE_Accredited__c + 730;
                        }
                        break;
                    }
                }
            }
            finalListContact.add(conRec);
        }
        System.debug('finalListContact***'+finalListContact);
        if(finalListContact.size()>0)
        {
            try{
                update finalListContact;
            }
            catch(Exception e)
            {
                System.debug('Error in Contact Updation'+e.getMessage());                
            }
        }
    }
}