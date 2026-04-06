public class CS_CX_Chart { 
    
    @AuraEnabled(cacheable=true)
    public static AccountScore  getAccountScore(Id accountId) {
        Account act = [SELECT ID,name,ETM_Theatre__c,Account_Preference__c,US_Federal_Account__c,Annual_Revenue_Range__c,Type,Account_SAM__c,Account_SAM__r.Name,Rubrik_Sales_Engineer__c,Rubrik_Sales_Engineer__r.Name,
                       OwnerId,Owner.Name
                       FROM Account WHERE Id =: accountId WITH SYSTEM_MODE];
        List<Account_Score__b> accountScore = [SELECT
                                               Id,Account__c, Account_type__c, Activation_Status__c, Adoption_Score__c, CX_Score_Status__c,
                                               CX_Score__c, Entitlement__c, OnBoarding_Score__c, PDM_Feature__c, Product_Score__c, Product__c, Support_Score__c, CEM__c,
                                               Account_Owner_Name__c, ANNUAL_REVENUE__c, SALES_ENGINEER_NAME__c, ENT_START_DATE__c, ENT_END_DATE__c, ONB_VAL__c, ADP_VAL__c,
                                               DEF_CNT__c, RF_CNT__c, ADOPTION_VALUE__c, DEFECT_SCORE__c, RFE_SCORE__c, DEFECT_FIXED__c, DEFECT_UNRESOLVED__c, RFES_PENDING_COMMIT__c,
                                               RFES_COMMIT__c, AVG_TTR_WITH_JIRA__c, AVG_TTR_WITHOUT_JIRA__c, TTR_WITH_JIRA_SCORE__c, TTR_WITHOUT_JIRA_SCORE__c, P1_CASE_COUNT__c,
                                               P2_CASE_COUNT__c, P1_P2_CASE_COUNT__c, P1_P2_CASECOUNT_SCORE__c, ESC_CNT__c, ESCALATIONS_SCORE__c, CATEGORY__c, Product_Pillar_1__c, 
                                               Product_Pillar_2__c, Table_type__c, MIN_ENT_START_DATE__c, MIN_ENT_START_QTR__c, MIN_ENT_END_DATE__c, MIN_ENT_END_QTR__c, ENT_COUNT__c,
                                               SNAPSHOT_DATE__c, SNAPSHOT_TYPE__c, FISCAL_YEAR__c, FIS_QTR_ID__c, START_DATE__c, END_DATE__c, ENT_PRODUCT_CODE__c, BOOKING__c,
                                               PIPELINE__c, LTV_BOOKING__c, OPEN_OPPORTUNITIES__c ,PRODUCTS__c ,PRODUCT_CATEGORY__c
                                               FROM Account_Score__b 
                                               WHERE Account__c =: accountId WITH SYSTEM_MODE];
        if(Test.isRunningTest()){
            Map<String, List<Account_Score__b>> scoreMap = createTestScoreData(accountId);
            accountScore = scoreMap.get(accountId);

        }
        Map<Id,Account_Score__b> accountScoreMap = new Map<Id,Account_Score__b>();
        for(Account_Score__b score : accountScore){
            if(!accountScoreMap.containsKey(score.Entitlement__c)){
                accountScoreMap.put(score.Entitlement__c, score);
            }
        }
        //List<Account_Score__b> filteredScoreList = accountScoreMap.values();
        AccountScore score = new AccountScore();
        score.account = act;
        score.score = accountScore[0];
        List<scoreByProducts> onboardingScoreDetails = new List<scoreByProducts>();
        List<scoreByProducts> adoptionScoreDetails = new List<scoreByProducts>();
        Map<String,List<scoreByProducts>> onboardingCatergoryMap = new Map<String,List<scoreByProducts>>();
         Map<String,List<scoreByProducts>> adoptionCatergoryMap = new Map<String,List<scoreByProducts>>();
        for(Account_Score__b scoreRecord : accountScore){
            if(scoreRecord.CATEGORY__c == 'Activation' && scoreRecord.PRODUCTS__c !='NA'){// && !onbaordingEnt.contains(scoreRecord.Entitlement__c)
                //onboardingScoreDetails.add(new scoreByProducts(scoreRecord));
                if(!onboardingCatergoryMap.containsKey(scoreRecord.PRODUCT_CATEGORY__c))
                    onboardingCatergoryMap.put(scoreRecord.PRODUCT_CATEGORY__c,new List<scoreByProducts>());
                onboardingCatergoryMap.get(scoreRecord.PRODUCT_CATEGORY__c).add(new scoreByProducts(scoreRecord));
            }
            if(scoreRecord.CATEGORY__c == 'Adoption'  && scoreRecord.PRODUCTS__c !='NA'){// && !adotionEnt.contains(scoreRecord.Entitlement__c)
                if(!adoptionCatergoryMap.containsKey(scoreRecord.PRODUCT_CATEGORY__c))
                    adoptionCatergoryMap.put(scoreRecord.PRODUCT_CATEGORY__c,new List<scoreByProducts>());
                adoptionCatergoryMap.get(scoreRecord.PRODUCT_CATEGORY__c).add(new scoreByProducts(scoreRecord));
            }
            if(scoreRecord.CATEGORY__c == 'Support'){
                score.scoreSupport = scoreRecord;
            }
            if(scoreRecord.CATEGORY__c == 'Product'){
                score.scoreProduct = scoreRecord;
            }
        }
        for(List<scoreByProducts> innerMap : onboardingCatergoryMap.values()){
            onboardingScoreDetails.addAll(innerMap);
        }
        for(List<scoreByProducts> innerMap : adoptionCatergoryMap.values()){
            adoptionScoreDetails.addAll(innerMap);
        }
        score.onboardingScoreDetails = onboardingScoreDetails;
        score.adoptionScoreDetails = adoptionScoreDetails;
        return score;
    }
    
    public class AccountScore{
        @AuraEnabled public Account account;
        @AuraEnabled public Account_Score__b score;
        @AuraEnabled public Account_Score__b scoreSupport;
        @AuraEnabled public Account_Score__b scoreProduct;
        @AuraEnabled public List<scoreByProducts> onboardingScoreDetails;
        @AuraEnabled public List<scoreByProducts> adoptionScoreDetails;
    }
    
    public class scoreByProducts{
        @AuraEnabled public String productCategory;
        @AuraEnabled public String products;
        @AuraEnabled public String activationStatus;
        @AuraEnabled public Decimal entitlements;
        @AuraEnabled public Decimal bufferDays;
        @AuraEnabled public Decimal onboardingValue;
        @AuraEnabled public Decimal adoptionValue;
        @AuraEnabled public Decimal adoptionValueScore;
        @AuraEnabled public Date startDate;
        public scoreByProducts(Account_Score__b score){
            this.productCategory = score.PRODUCT_CATEGORY__c;
            this.products = score.PRODUCTS__c ;
            this.activationStatus = score.Activation_Status__c  == 'true' ? 'Activated' : 'Pending Activation';
            this.entitlements = score.ENT_COUNT__c;
            this.bufferDays = score.Support_Score__c;
            if(score.ONB_VAL__c != null)
                this.onboardingValue = Math.round(Decimal.valueOf(score.ONB_VAL__c));
            this.adoptionValue = score.ADOPTION_VALUE__c == null ? 0: Math.round(Decimal.valueof(score.ADOPTION_VALUE__c));
            this.adoptionValueScore = score.ADP_VAL__c  == null ? 0:  Math.round(Decimal.valueof(score.ADP_VAL__c));
            this.startDate = Date.valueOf(score.MIN_ENT_START_DATE__c);
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static dataSegment  getHistoricalCharts(Id accountId) {
        dataSegment dataSegement = new dataSegment(); 
        dataSegement.monthlyCharts =  new dataColoumn();
        dataSegement.weeklyCharts =  new dataColoumn();
        dataSegement.quaterlyCharts =  new dataColoumn();
        List<Account_Historical_View__b> records = [SELECT id,SNAPSHOT_DATE__c,SNAPSHOT_TYPE__c ,Adoption_Score__c,CX_Score__c,Support_Score__c,Product_Score__c,OnBoarding_Score__c from Account_Historical_View__b WHERE Account__c =: accountId  WITH SYSTEM_MODE];
        if(Test.isRunningTest()){
            Map<String, List<Account_Historical_View__b>> scoreMap = createTestHistScoreData(accountId);
            records = scoreMap.get(accountId);
            
        }
        records.sort(new AccountDateComparator());
        Set<String> monthSet = new Set<String>();
        Set<String> weekSet = new Set<String>();
        Set<String> quaterSet = new Set<String>();
        for(Account_Historical_View__b record : records){
            DateTime snapShotDate = record.SNAPSHOT_DATE__c;
            Integer year = snapShotDate.year(); 
            Integer month = snapShotDate.month(); 
            if(record.SNAPSHOT_TYPE__c  == 'Monthly'){
                String formattedDate = snapShotDate.format('MMM yyyy');
                Date todayDate = System.today().addMonths(-12);
                if(monthSet.contains(formattedDate) || snapShotDate < todayDate ){
                    continue;
                }
                monthSet.add(formattedDate);
                dataSegement.monthlyCharts.labelsList.add(formattedDate);
                dataSegement.monthlyCharts.dataRowList.add(new dataRow(record));
            }else if(record.SNAPSHOT_TYPE__c  == 'Weekly'){
                Integer dayOfYear = snapShotDate.dayOfYear(); 
                Integer weekNumber = (dayOfYear - 1) / 7 + 1;
                String formattedWeek = year + ' wk-' + String.valueOf(weekNumber).leftPad(2, '0'); 
                Date todayDate = System.today().addMonths(-5);
                if(weekSet.contains(formattedWeek) || snapShotDate < todayDate ){
                    continue;
                }
                weekSet.add(formattedWeek);
                dataSegement.weeklyCharts.labelsList.add(formattedWeek);
                dataSegement.weeklyCharts.dataRowList.add(new dataRow(record));
            }else if(record.SNAPSHOT_TYPE__c  == 'Quarterly'){
                Integer quarterNum;
                switch on month {
                    when 2, 3, 4 {
                        quarterNum = 1; // Q1: Feb-Apr
                    }
                    when 5, 6, 7 {
                        quarterNum = 2; // Q2: May-Jul
                    }
                    when 8, 9, 10 {
                        quarterNum = 3; // Q3: Aug-Oct
                    }
                    when 11, 12, 1 {
                        quarterNum = 4; // Q4: Nov-Jan
                        if(month == 1){
                            year--;
                        }
                    }
                    when else {
                        quarterNum = 0; // Handle an invalid month (this should never happen)
                    }
                }
                String formatetdQuarter = year+1 + '-Q' + String.valueOf(quarterNum);
                Date todayDate = System.today().addMonths(-24);
                if(quaterSet.contains(formatetdQuarter) || snapShotDate < todayDate ){
                    continue;
                }
                quaterSet.add(formatetdQuarter);
                dataSegement.quaterlyCharts.labelsList.add(formatetdQuarter);
                dataSegement.quaterlyCharts.dataRowList.add(new dataRow(record));

            }
        }
        return dataSegement;
    }
    
    
    public class dataSegment{
        @AuraEnabled
        public dataColoumn monthlyCharts;
        @AuraEnabled
        public dataColoumn weeklyCharts;
        @AuraEnabled
        public dataColoumn quaterlyCharts;
    }
    
    public class dataColoumn{
        @AuraEnabled
        public List<dataRow> dataRowList;
        @AuraEnabled
        public List<String> labelsList;
        public dataColoumn(){
            this.dataRowList = new List<dataRow>();
            this.labelsList = new List<String>();
        }
    }
    
    public class dataRow{
        @AuraEnabled
        public Decimal cxScore;
        @AuraEnabled
        public Decimal onboardingScore;
        @AuraEnabled
        public Decimal adoptionScore;
        @AuraEnabled
        public Decimal supportScore;
        @AuraEnabled
        public Decimal productScore;
        public dataRow(Account_Historical_View__b record){
            this.cxScore = Math.round(record.CX_Score__c);
            this.onboardingScore = Math.round(record.OnBoarding_Score__c);
            this.adoptionScore = Math.round(record.Adoption_Score__c);
            this.supportScore = Math.round(record.Support_Score__c);
            this.productScore = Math.round(record.Product_Score__c);
        }
    }
     // Custom Comparator for sorting accounts by CreatedDate
    public class AccountDateComparator implements System.Comparator<Account_Historical_View__b> {
        public Integer compare(Object obj1, Object obj2) {
            // Cast to Account objects
            Account_Historical_View__b acc1 = (Account_Historical_View__b) obj1;
            Account_Historical_View__b acc2 = (Account_Historical_View__b) obj2;
            if(Date.valueOf(acc1.SNAPSHOT_DATE__c) > Date.valueOf(acc2.SNAPSHOT_DATE__c)){
                return 1;
            }else{
                return -1;
            }
        }
    }
     @TestVisible private static Map<String, List<Account_Score__b>> createTestScoreData(Id accountID){
         List<Account_Score__b> NewScoreList = new List<Account_Score__b>();
         Account_Score__b NewScore = new Account_Score__b();
         NewScore.Account__c = accountID;
         NewScore.MIN_ENT_START_DATE__c = system.now();
         NewScore.ADP_VAL__c = '5.0';
         NewScore.ADOPTION_VALUE__c = '5.0';
         NewScore.OnBoarding_Score__c = 5.0;
         String entId = '550' + String.valueOf(Math.abs(Crypto.getRandomInteger())).leftPad(12, '0');

         NewScore.Entitlement__c = entId;
         NewScoreList.add(NewScore);
         
         Map<String, List<Account_Score__b>> clusterAttributeMap = new Map<String, List<Account_Score__b>>();
         for(Account_Score__b eachAtt : NewScoreList){
             if(!String.isBlank(eachAtt.Account__c)){
                 if(clusterAttributeMap.containsKey(eachAtt.Account__c)){
                     clusterAttributeMap.get(eachAtt.Account__c).add(eachAtt);
                 }
                 else{
                     clusterAttributeMap.put(eachAtt.Account__c, new List<Account_Score__b>{eachAtt});
                 }
             }
                }
         return clusterAttributeMap;
    }
    
     @TestVisible private static Map<String, List<Account_Historical_View__b>> createTestHistScoreData(Id accountID){
         List<Account_Historical_View__b> NewScoreList = new List<Account_Historical_View__b>();
         Account_Historical_View__b NewScore = new Account_Historical_View__b();
         NewScore.Account__c = accountID;
         NewScore.SNAPSHOT_TYPE__c = 'Monthly';
         NewScore.SNAPSHOT_DATE__c = System.Now();
         NewScore.CX_Score__c = 5.0;
         NewScore.Adoption_Score__c = 5.0;
         NewScore.OnBoarding_Score__c = 5.0;
         NewScore.Product_Score__c = 5.0;
         NewScore.Support_Score__c = 5.0;
         NewScoreList.add(NewScore);
         NewScore = new Account_Historical_View__b();
         NewScore.Account__c = accountID;
         NewScore.SNAPSHOT_TYPE__c = 'Weekly';
         NewScore.SNAPSHOT_DATE__c = System.Now();
         NewScore.CX_Score__c = 5.0;
         NewScore.Adoption_Score__c = 5.0;
         NewScore.OnBoarding_Score__c = 5.0;
         NewScore.Product_Score__c = 5.0;
         NewScore.Support_Score__c = 5.0;
         NewScoreList.add(NewScore);
         NewScore = new Account_Historical_View__b();
         NewScore.Account__c = accountID;
         NewScore.SNAPSHOT_TYPE__c = 'Quarterly';
                  NewScore.SNAPSHOT_DATE__c = System.Now();

         NewScore.CX_Score__c = 5.0;
         NewScore.Adoption_Score__c = 5.0;
         NewScore.OnBoarding_Score__c = 5.0;
         NewScore.Product_Score__c = 5.0;
         NewScore.Support_Score__c = 5.0;
         NewScoreList.add(NewScore);
         
         Map<String, List<Account_Historical_View__b>> clusterAttributeMap = new Map<String, List<Account_Historical_View__b>>();
         for(Account_Historical_View__b eachAtt : NewScoreList){
             if(!String.isBlank(eachAtt.Account__c)){
                 if(clusterAttributeMap.containsKey(eachAtt.Account__c)){
                     clusterAttributeMap.get(eachAtt.Account__c).add(eachAtt);
                 }
                 else{
                     clusterAttributeMap.put(eachAtt.Account__c, new List<Account_Historical_View__b>{eachAtt});
                 }
             }
                }
         return clusterAttributeMap;
    }

}