@isTest
public class splitStringTest {
    
    testmethod static void splitTest(){
        splitString.Input input = new splitString.Input();
        input.text = 'Test,TEST,test';
        input.action = 'Split';
        input.delimiter = ',';
        
        splitString.processString(new List<splitString.Input> { input });
    }
    
     testmethod static void richTest(){
        splitString.Input input = new splitString.Input();
        input.text = '<a href="/005AAB" target="_blank">Rubrik</a> , <a href="/0055g000" target="_blank">Rubrik</a> , <a href="/0055pe6AAB" target="_blank">Rubrik</a>';
        input.action = 'Rich';
        input.delimiter = ',';
        
        splitString.processString(new List<splitString.Input> { input });
    }

}