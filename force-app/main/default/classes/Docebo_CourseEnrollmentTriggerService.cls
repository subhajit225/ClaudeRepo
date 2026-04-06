/********************************************************************
* $Id$: Docebo_CourseEnrollmentTriggerService 
* $Created Date$: 24-Sept-2019
* $Author$: Santosh Gore
* $Description$ : Service class for the CourseEnrollmentTrigger
********************************************************************/
public class Docebo_CourseEnrollmentTriggerService {
    
    //public static final string PAR_C_ESSENTIAL = 'PAR_C_Essentials';
    //public static final string PAR_C_FOUNDATION = 'PAR_C_Foundations';
    public static final string PAR_E_RTPTEST = 'PAR_E_RTP_Test';
    public static final string RTP_Test_Out = 'RTP_Test_Out';
    public static final string Par_E_RCIE_Test = 'Par_E_RCIE_Test';
    public static final string RCIE_TestOut = 'RCIE_TestOut';
    public static final string COURSE_C64 = 'C64';
    public static final string COURSE_C83 = 'C83';
    public static final string RTP_L1 = 'RTP_L1';
    public static final string RSP_Test = 'RSP_Test';
    public static final string RTA_Test= 'RTA_Test';
    public static final string RRE_Test = 'RRE_Test';
    public static final string RRS_Test= 'RRS_Test';
    // PRIT25-725 & PRIT25-732
    public static final string RRSA_Test= 'Rubrik_Rewards_Sales_Accreditation_2024';
    public static final string RCDP_Test= 'RCDP_Technical_OCT_2024';
    // PRIT26-116
    public static final string RCDP_S_Test= 'RCDP Sales OCT 2024';
    // PRIT25-758 & PRIT25-759
    public static final string RCRS_Test = 'RU-RCRS -V1-FinalExam';
    public static final string RCCS_Test = 'RU-RCCS -V1-FinalExam';    
    

    
    public static final string CE_STATUS_COMPLETED = 'Completed';
    //public static final string PAR_C_ESSENTIAL_STR = '%PAR_C_Essentials%';
    //public static final string PAR_C_FOUNDATION_STR = '%PAR_C_Foundations%';
    public static final string PAR_E_RTPTEST_STR = '%PAR_E_RTP_Test%';
    public static final string RTP_Test_Out_STR = '%RTP_Test_Out%';
    
    public static final string Par_E_RCIE_Test_STR = '%Par_E_RCIE_Test%';
    public static final string RCIE_TestOut_STR = '%RCIE_TestOut%';
    
    
    public static final string RSP_Test_STR = '%RSP_Test%';
    public static final string RTA_Test_STR = '%RTA_Test%';
    public static final string RTP_Renewal = 'RTP_Renewal';
    public static final string RCIE_Renewal = 'RCIE_Renewal';
    public static final string RSP_Renewal = 'RSP_Renewal';
    public static final string RTP_Renewal_STR = '%RTP_Renewal%';
    public static final string RCIE_Renewal_STR = '%RCIE_Renewal%';
    public static final string RSP_Renewal_STR = '%RSP_Renewal%';
    public static final string RRS_Test_STR = '%RRS_Test%';
    public static final string RRS_TestOut_STR = '%RRS_TestOut%';
    public static final string RRE_Test_STR = '%RRE_Test%';
    public static final string RRE_TestOut_STR = '%RRE_TestOut%';
    // PRIT25-725 & PRIT25-732
    public static final string RRSA_Test_STR = '%Rubrik_Rewards_Sales_Accreditation_2024%';
    public static final string RCDP_Test_STR = '%RCDP_Technical_OCT_2024%';
    // PRIT26-116
    public static final string RCDP_S_Test_STR = '%RCDP Sales OCT 2024%';
    // PRIT25-758 & PRIT25-759
    public static final string RCRS_Test_STR = '%RU-RCRS -V1-FinalExam%';
    public static final string RCCS_Test_STR = '%RU-RCCS -V1-FinalExam%';
    
    /**
        @Name : populateContactOn Cource Enrollment
        @Description : populate Contact On CE
    */
    public static void populateContactOnCE(List<docebo_v3__CourseEnrollment__c> newCourceEnrollList) {
        Set<Id> doceboUserId = new Set<Id>();
        for(docebo_v3__CourseEnrollment__c ce : newCourceEnrollList) {
            if(String.isNotBlank(ce.docebo_v3__DoceboUser__c)) {
                doceboUserId.add(ce.docebo_v3__DoceboUser__c);
            }
        }
        if(!doceboUserId.isEmpty()) {
            Map<Id, docebo_v3__DoceboUser__c> mapDoceboUser = new Map<Id, docebo_v3__DoceboUser__c>([SELECT Id,Contact_Id__c 
                    FROM docebo_v3__DoceboUser__c WHERE Id IN :doceboUserId]);
                    
            for(docebo_v3__CourseEnrollment__c ce : newCourceEnrollList) {
                if(String.isNotBlank(ce.docebo_v3__DoceboUser__c)) {
                    ce.Contact__c = mapDoceboUser.containsKey(ce.docebo_v3__DoceboUser__c) ? mapDoceboUser.get(ce.docebo_v3__DoceboUser__c).Contact_Id__c : null;
                }
            }
        }
    
    }
    
    /**
        @Name : setAccreditationOnContact
        @Description : populate Contact On CE
    */
    public static void setAccreditationOnContact(Map<Id,docebo_v3__CourseEnrollment__c> newCourseEnrolList) {
        system.debug('Called setAccreditationOnContact___________________');
        Set<Id> courseId = new Set<Id>();
        Map<String,Id> mapCourseIdByName = new Map<String,String>();
        Set<Id> contactIds = new Set<Id>();
        List<Contact> contactListUpdate = new List<Contact>();//list to update
        // PRIT25-725 & PRIT25-732 Added new codes RRSA_Test_STR & RCDP_Test_STR //PRIT26-116 Added RCDP_S_Test_STR
        List<String> courseCodes = new List<String>{PAR_E_RTPTEST_STR,RTP_L1,Par_E_RCIE_Test_STR,RSP_Test_STR,RCIE_TestOut_STR,RTA_Test_STR,RTP_Test_Out_STR,RTP_Renewal_STR,RCIE_Renewal_STR,RSP_Renewal_STR,RRS_Test_STR,RRS_TestOut_STR,RRE_Test_STR,RRE_TestOut_STR,RRSA_Test_STR,RCDP_Test_STR,RCRS_Test_STR,RCCS_Test_STR,RCDP_S_Test_STR};        
        
        system.debug('courseCodes___________________'+courseCodes);
        //Get all accredated Courses detail
        for(docebo_v3__Course__c dCourse: [SELECT Id,docebo_v3__Name__c,docebo_v3__Type__c, docebo_v3__Code__c FROM docebo_v3__Course__c WHERE docebo_v3__Name__c IN ('C64','C83') OR docebo_v3__Code__c LIKE :courseCodes]) {
            courseId.add(dCourse.Id);
            if(dCourse.docebo_v3__Name__c == COURSE_C64 || dCourse.docebo_v3__Name__c == COURSE_C83) {
                mapCourseIdByName.put(dCourse.docebo_v3__Name__c, dCourse.Id);
            } else {
                mapCourseIdByName.put(dCourse.docebo_v3__Code__c, dCourse.Id);
            }
            
        }
        system.debug('mapCourseIdByName ___________________'+mapCourseIdByName);
        
        //Get contact Associated with  course enrollment 
        for(docebo_v3__CourseEnrollment__c dCourseEnrol : newCourseEnrolList.values()) {
            if( dCourseEnrol.docebo_v3__Status__c == CE_STATUS_COMPLETED) {
                contactIds.add(dCourseEnrol.Contact__c);
            }
        }
        system.debug('contactIds ___________________'+contactIds);
        
        Map<Id,Contact> mapContact = new Map<Id,Contact>([SELECT    Id,PSE_Shadow_Completed__c,Name,RTP_Accredited__c,RTP_Expiration__c,RSP_Accredited__c,RSP_Expiration__c,RPSE_Accredited__c,RPSE_Expiration__c,RRSA_Accredited__c,RRSA_Expiration__c,RCDP_Accredited__c,RCDP_Expiration__c FROM Contact where Id IN :contactIds]);
        system.debug('mapContact ___________________'+mapContact);
        List<docebo_v3__CourseEnrollment__c> allCourseEnrollList = 
            [SELECT Id,Contact__c, docebo_v3__Status__c, docebo_v3__EnrollmentCompletionDate__c,  docebo_v3__Course__c,docebo_v3__Course__r.docebo_v3__Code__c,docebo_v3__EnrollmentStartDate__c, docebo_v3__EnrolmentId__c 
            FROM docebo_v3__CourseEnrollment__c 
            WHERE Contact__c IN :contactIds AND docebo_v3__Course__c IN :courseId AND docebo_v3__Status__c = 'Completed' 
                  AND docebo_v3__EnrollmentCompletionDate__c != null ORDER BY docebo_v3__EnrollmentCompletionDate__c ASC];
        system.debug('allCourseEnrollList ___________________'+allCourseEnrollList);
        Map<Id,Set<String>> mapCourseIdsByContact = new Map<Id,Set<String>>();
        Map<Id,List<docebo_v3__CourseEnrollment__c>> mapCourseEnrollByContact = new Map<Id,List<docebo_v3__CourseEnrollment__c>>();
        
        //populate contact with its course enrollment
        for(docebo_v3__CourseEnrollment__c dCourseEnrol : allCourseEnrollList) {
            if(mapCourseIdsByContact.containsKey(dCourseEnrol.Contact__c)) {
                mapCourseIdsByContact.get(dCourseEnrol.Contact__c).add(dCourseEnrol.docebo_v3__Course__c);
                mapCourseEnrollByContact.get(dCourseEnrol.Contact__c).add(dCourseEnrol);
            }else {
                mapCourseIdsByContact.put(dCourseEnrol.Contact__c, new Set<String> {dCourseEnrol.docebo_v3__Course__c});
                mapCourseEnrollByContact.put(dCourseEnrol.Contact__c, new List<docebo_v3__CourseEnrollment__c>{dCourseEnrol});
            }
        
        }
        system.debug('mapCourseEnrollByContact ___________________'+mapCourseEnrollByContact);
        //Update Contact Accredation date and Expiration date
        for(Id conId : mapCourseEnrollByContact.keySet()) {
            Contact conRec = mapContact.get(conId);
            Set<String> allCourses = mapCourseIdsByContact.get(conId);
            
            //RSP Calculation
            if(allCourses.contains(mapCourseIdByName.get('C64')) && allCourses.contains(mapCourseIdByName.get('C83'))){
                SYstem.debug('RSP True');
                for(docebo_v3__CourseEnrollment__c dCourseEnrol : mapCourseEnrollByContact.get(conId)){
                    if(dCourseEnrol.docebo_v3__Course__c == mapCourseIdByName.get('C64') || dCourseEnrol.docebo_v3__Course__c == mapCourseIdByName.get('C83')){
                        conRec.RSP_Accredited__c = dCourseEnrol.docebo_v3__EnrollmentCompletionDate__c.date();
                        //PRIT24-330 -- Changed Expiration from 1 yr to 2 yrs
                        conRec.RSP_Expiration__c = conRec.RSP_Accredited__c + 730;
                        break;
                    }
                }
            }
            
            //RTP && RPSE Calculation
            //boolean pareEssential = false;
            //boolean parcFoundation = false;
            boolean parERtp = false;
            boolean RTP_L1_flag = false;
            //boolean Par_E_RCIE_Test_flag = false;
            boolean RSP_Test_flag = false;
            //boolean RTA_Test_flag = false;
            //boolean RRS_Test_flag = false;
            //boolean RRE_Test_flag = false;
            // PRIT25-725 & PRIT25-732
            boolean RRSA_Test_flag = false;
            boolean RCDP_Test_flag = false;
            //PRIT26-116
            boolean RCDP_S_Test_flag = false;
            // PRIT25-758 & PRIT25-759
            boolean RCRS_Test_flag = false;
            boolean RCCS_Test_flag = false;

            docebo_v3__CourseEnrollment__c dCE = null;
            for(docebo_v3__CourseEnrollment__c dCourseEnrol : mapCourseEnrollByContact.get(conId)){
                dCE = dCourseEnrol;
                parERtp = false;
                RTP_L1_flag = false;
                //Par_E_RCIE_Test_flag = false;
                RSP_Test_flag = false;
                //RTA_Test_flag = false;
                //RRS_Test_flag = false;
                //RRE_Test_flag = false;
                //PRIT25-725 & PRIT25-732
                RRSA_Test_flag = false;
                RCDP_Test_flag = false;
                //PRIT26-116
                RCDP_S_Test_flag = false;
                // PRIT25-758 & PRIT25-759
                RCRS_Test_flag = false;
                RCCS_Test_flag = false;
                system.debug('dCE ___________________'+dCE);
                if(dCourseEnrol.docebo_v3__Course__r.docebo_v3__Code__c.containsIgnoreCase(PAR_E_RTPTEST) || dCourseEnrol.docebo_v3__Course__r.docebo_v3__Code__c.containsIgnoreCase(RTP_Test_Out) || dCourseEnrol.docebo_v3__Course__r.docebo_v3__Code__c.containsIgnoreCase(RTP_Renewal)) {
                    parERtp = true;
                    //dCE = (dCE == null) ? dCourseEnrol : dCE;
                }
                /*if(dCourseEnrol.docebo_v3__Course__r.docebo_v3__Code__c.containsIgnoreCase(RTA_Test)){
                    RTA_Test_flag = true;
                    //dCE = (dCE == null) ? dCourseEnrol : dCE;
                }*/
                /*if(dCourseEnrol.docebo_v3__Course__r.docebo_v3__Code__c.containsIgnoreCase(Par_E_RCIE_Test) || dCourseEnrol.docebo_v3__Course__r.docebo_v3__Code__c.containsIgnoreCase(RCIE_TestOut) || dCourseEnrol.docebo_v3__Course__r.docebo_v3__Code__c.containsIgnoreCase(RCIE_Renewal)){
                    Par_E_RCIE_Test_flag = true;
                    //dCE = (dCE == null) ? dCourseEnrol : dCE;
                }*/
                if(dCourseEnrol.docebo_v3__Course__r.docebo_v3__Code__c.containsIgnoreCase(RSP_Test) || dCourseEnrol.docebo_v3__Course__r.docebo_v3__Code__c.containsIgnoreCase(RSP_Renewal)){
                    RSP_Test_flag = true;
                    //dCE = (dCE == null) ? dCourseEnrol : dCE;
                }
                /*if(dCourseEnrol.docebo_v3__Course__r.docebo_v3__Code__c.containsIgnoreCase(RRS_Test_STR) || dCourseEnrol.docebo_v3__Course__r.docebo_v3__Code__c.containsIgnoreCase(RRS_TestOut_STR) || dCourseEnrol.docebo_v3__Course__r.docebo_v3__Code__c.containsIgnoreCase(RRS_Test)){
                    RRS_Test_flag = true;
                }*/
                /*if(dCourseEnrol.docebo_v3__Course__r.docebo_v3__Code__c.containsIgnoreCase(RRE_Test_STR) || dCourseEnrol.docebo_v3__Course__r.docebo_v3__Code__c.containsIgnoreCase(RRE_TestOut_STR) || dCourseEnrol.docebo_v3__Course__r.docebo_v3__Code__c.containsIgnoreCase(RRE_Test)){
                    RRE_Test_flag = true;
                }*/
                
                // PRIT25-725 & PRIT25-732
                if(dCourseEnrol.docebo_v3__Course__r.docebo_v3__Code__c.containsIgnoreCase(RRSA_Test_STR) || dCourseEnrol.docebo_v3__Course__r.docebo_v3__Code__c.containsIgnoreCase(RRSA_Test)){
                    RRSA_Test_flag = true;
                }
                if(dCourseEnrol.docebo_v3__Course__r.docebo_v3__Code__c.containsIgnoreCase(RCDP_Test_STR) || dCourseEnrol.docebo_v3__Course__r.docebo_v3__Code__c.containsIgnoreCase(RCDP_Test)){
                    RCDP_Test_flag = true;
                }
                //PRIT26-116
                if(dCourseEnrol.docebo_v3__Course__r.docebo_v3__Code__c.containsIgnoreCase(RCDP_S_Test_STR) || dCourseEnrol.docebo_v3__Course__r.docebo_v3__Code__c.containsIgnoreCase(RCDP_S_Test)){
                    RCDP_S_Test_flag = true;
                }
                
                // PRIT25-758 & PRIT25-759
                if(dCourseEnrol.docebo_v3__Course__r.docebo_v3__Code__c.containsIgnoreCase(RCRS_Test_STR) || dCourseEnrol.docebo_v3__Course__r.docebo_v3__Code__c.containsIgnoreCase(RCRS_Test)){
                    RRSA_Test_flag = true;
                }
                if(dCourseEnrol.docebo_v3__Course__r.docebo_v3__Code__c.containsIgnoreCase(RCCS_Test_STR) || dCourseEnrol.docebo_v3__Course__r.docebo_v3__Code__c.containsIgnoreCase(RCCS_Test)){
                    RCCS_Test_flag = true;
                }
                
				SYstem.debug('flags '+parERtp+' '+RSP_Test_flag);
                if(parERtp) {
                    SYstem.debug('RTP True');
                    conRec.RTP_Accredited__c = dCE.docebo_v3__EnrollmentCompletionDate__c.date();
                    //PRIT24-330 -- Changed Expiration from 1 yr to 2 yrs
                    conRec.RTP_Expiration__c = conRec.RTP_Accredited__c + 730;
                    if(conRec.PSE_Shadow_Completed__c != null) {
                        SYstem.debug('RPSE True');
                        conRec.RPSE_Accredited__c = dCE.docebo_v3__EnrollmentCompletionDate__c.date();
                        conRec.RPSE_Expiration__c = conRec.RPSE_Accredited__c + 730;
                    }
                }
                /*if(RTA_Test_flag) {
                    SYstem.debug('RTA_Test_flag True');
                    conRec.RTA_Accredited__c = dCE.docebo_v3__EnrollmentCompletionDate__c.date();
                    //PRIT24-330 -- Changed Expiration from 1 yr to 2 yrs
                    conRec.RTA_Expiration__c = conRec.RTA_Accredited__c + 730;
                }*/
                /* if(Par_E_RCIE_Test_flag) {
                    SYstem.debug('Par_E_RCIE_Test_flag True');
                    conRec.RCIE_Certified__c = dCE.docebo_v3__EnrollmentCompletionDate__c.date();
                    conRec.RCIE_Expiration__c = conRec.RCIE_Certified__c + 730;
                }*/
                if(RSP_Test_flag) {
                    SYstem.debug('RSP_Test_flag True ');
                    conRec.RSP_Accredited__c = dCE.docebo_v3__EnrollmentCompletionDate__c.date();
                    //PRIT24-330 -- Changed Expiration from 1 yr to 2 yrs
                    conRec.RSP_Expiration__c = conRec.RSP_Accredited__c + 730;
                }
                /*if(RRS_Test_flag) {
                    SYstem.debug('RRS_Test_flag True ');
                    conRec.RRS_Accredited__c = dCE.docebo_v3__EnrollmentCompletionDate__c.date();
                    //PRIT24-330 -- Changed Expiration from 1 yr to 2 yrs
                    conRec.RRS_Expiration__c = conRec.RRS_Accredited__c + 730;
                }*/
                /*if(RRE_Test_flag) {
                    SYstem.debug('RRE_Test_flag True ');
                    conRec.RRE_Accredited__c = dCE.docebo_v3__EnrollmentCompletionDate__c.date();
                    //PRIT24-330 -- Changed Expiration from 1 yr to 2 yrs
                    conRec.RRE_Expiration__c = conRec.RRE_Accredited__c + 730;
                }*/
                // PRIT25-725 & PRIT25-732
                if(RRSA_Test_flag) {
                    conRec.RRSA_Accredited__c = dCE.docebo_v3__EnrollmentCompletionDate__c.date();
                    conRec.RRSA_Expiration__c = conRec.RRSA_Accredited__c + 730;
                }
                if(RCDP_Test_flag) {
                    conRec.RCDP_Accredited__c = dCE.docebo_v3__EnrollmentCompletionDate__c.date();
                    conRec.RCDP_Expiration__c = conRec.RCDP_Accredited__c + 730;
                }
                //PRIT26-116
                if(RCDP_S_Test_flag) {
                    conRec.RCDP_S_Accredited__c = dCE.docebo_v3__EnrollmentCompletionDate__c.date();
                    conRec.RCDP_S_Expiration__c = conRec.RCDP_S_Accredited__c + 730;
                }
                // PRIT25-758 & PRIT25-759
                if(RCRS_Test_flag) {
                    conRec.RCRS_Accredited__c = dCE.docebo_v3__EnrollmentCompletionDate__c.date();
                    conRec.RCRS_Expiration__c = conRec.RCRS_Accredited__c + 730;
                }
                if(RCCS_Test_flag) {
                    conRec.RCCS_Accredited__c = dCE.docebo_v3__EnrollmentCompletionDate__c.date();
                    conRec.RCCS_Expiration__c = conRec.RCCS_Accredited__c + 730;
                }
                
            }
            contactListUpdate.add(conRec);
        }
        system.debug('contactListUpdate ___________________'+contactListUpdate);
        if(!contactListUpdate.isEmpty()) {
            try {
                update contactListUpdate;
            }catch(Exception e) {
                System.debug('Error in Contact Updation'+e.getMessage());    
            }
        }
        
    }
    
}