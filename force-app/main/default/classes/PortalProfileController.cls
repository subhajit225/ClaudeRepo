public without sharing class PortalProfileController {

    /* 
    Allows Portal users to edit their details and updates their related Contact as well.
    */

    private User user;
    

    public boolean errorMessage {get;set;}
    public boolean successMessage {get;set;}
    
    public User getUser() {
        return user;
    }
                                                                            
    public PortalProfileController() {
        user = [SELECT id, email, username, usertype, communitynickname, timezonesidkey, languagelocalekey, firstname, lastname, phone, title,
                street, city, country, postalcode, Community_Notifications__c, state, localesidkey, mobilephone, extension, fax, contact.firstname, contact.lastname, contact.email, contact.title, contact.phone
                FROM User
                WHERE id = :UserInfo.getUserId()];
        // guest users should never be able to access this page
        if (user.usertype == 'GUEST') {
            throw new NoAccessException();
        }
    }

    public void saveRecord() {
        if (user.contact != null) {
            setContactFields(user.contact, user);
        }

        try {
            update user;
            if (user.contact != null) {
                update user.contact;
  
                successMessage=true;

            }
        } catch(DmlException e) {
            ApexPages.addMessages(e);
               errorMessage=true;
        }
    }


    public void cancel() {
    
       
    }

    public static void setContactFields(Contact c, User u) {
        
        c.title = u.title;
        c.firstname = u.firstname;
        c.lastname = u.lastname;
        c.email = u.email;
        c.phone = u.phone;

    }
}