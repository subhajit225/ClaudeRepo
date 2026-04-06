@isTest 
public class FuzzyMethod_test {
    
   static testMethod void testMethod_1() {
        
        String s1='Test Fuzzy ness';
        String s2='Test';
        decimal test=FuzzyMethod.JaroFuzzyMethod(s1,s2);
        
   }
   static testMethod void testMethod_2() {
        
        String s1='Test Fuzzy ness';
        String s2='Test Fuzzy ness';
        decimal test=FuzzyMethod.JaroFuzzyMethod(s1,s2);
        
   }
}