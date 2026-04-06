/**
 * @description Response DTO with success/error message and data
 */ 
public class ResponseDTO{
    @AuraEnabled public Boolean Success;
    @AuraEnabled public String Message;
    @AuraEnabled public Object Data;
    /**
     * @description wrapper constructor
     * @param Success
     * @param Message
     * @param Data
	*/
    public ResponseDTO(Boolean Success, String Message, Object Data){
        this.Success = Success;
        this.Message = Message;
        this.Data = Data;
    }
}