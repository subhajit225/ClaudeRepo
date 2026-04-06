public class PolarisTokenResponse {
    public String access_token;
	public Integer expires_in;
	public String token_type;

	
	public static PolarisTokenResponse parse(String json) {
		return (PolarisTokenResponse) System.JSON.deserialize(json, PolarisTokenResponse.class);
	}
}