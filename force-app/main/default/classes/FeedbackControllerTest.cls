@isTest
public class FeedbackControllerTest {
    static testmethod void test1(){
        feedbackController.FieldsWrapper Fields = feedbackController.getFields();
        feedbackController.getEmailTemplate(Fields);
        feedbackController.SaveForm(JSON.serialize(Fields));
    }
}