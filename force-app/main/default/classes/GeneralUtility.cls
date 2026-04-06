public with sharing class GeneralUtility { //...

    public static Date getLastDateOfQuarter(Integer givenYear, Integer givenQuarter) {
        // 2021, 4
        Financial_Year__mdt fyMd = Financial_Year__mdt.getInstance('Q' + String.valueOf(givenQuarter));
        Date lastDateOfQuarter = Date.newInstance(givenYear, fyMd.Quarter_End_Month__c.intValue() + 1, 1);
        lastDateOfQuarter.addDays(-1);
        return lastDateOfQuarter;
    }
    public static String determineFinancialYearAndQuarter(Date givenDate) {

        Map<String, Financial_Year__mdt> fyMdMap = Financial_Year__mdt.getAll();
        Integer givenMonth = givenDate.month();
        Integer givenYear = givenDate.year();

        Integer givenFinancialYear;
        Integer givenFinancialQuarter;

        givenFinancialYear = (givenMonth < fyMdMap.get('Q1').Quarter_Start_Month__c) ? givenYear - 1 : givenYear;
        for (Financial_Year__mdt fyMD : fyMdMap.values()) {
            if (givenMonth >= fyMdMap.get('Q4').Quarter_Start_Month__c || givenMonth <= fyMdMap.get('Q4').Quarter_End_Month__c) {
                givenFinancialQuarter = Integer.valueOf(fyMdMap.get('Q4').Quarter__c);
                break;
            }
            if (givenMonth >= fyMD.Quarter_Start_Month__c && givenMonth <= fyMD.Quarter_End_Month__c) {
                givenFinancialQuarter = Integer.valueOf(fyMD.Quarter__c);
                break;
            }
        }
        return 'FY' + String.valueOf(givenFinancialYear) + 'Q' + String.valueOf(givenFinancialQuarter);
    }
    
}