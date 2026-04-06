public class OrderShippingAddressExtn {
    
    private List<Shipping_Address__c> sAdd;
    private Order order;
    public string selectedAddress{get;set;}
    public List<Shipping_address__c> listAddress{get;set;}
    public OrderShippingAddressExtn(ApexPages.StandardController controller) {
        this.order= (Order)controller.getRecord();
        listAddress= new List<Shipping_Address__c>();  
        listAddress.add(new Shipping_Address__c()) ;
        selectedAddress = ''; 
    }
    
    public List<SelectOption> getSAddresses() {
        try{
            Order orderObj = [Select id, Account.id, ship_To_Name__c FROM Order where id = :order.id];
            order.ship_To_Name__c = orderObj.Ship_To_Name__c;
            order.AccountId = orderObj.AccountId;
            if (orderObj.Ship_To_Name__c == null){
                return null;
            } 
            system.debug('orderObj.Ship_To_Name__c =='+orderObj.Ship_To_Name__c);
            sAdd = [Select id, Name,Account__c , Account__r.Name, Shipping_Address_Full_Name__c, Shipping_Country__c, Shipping_Postal_Zip_Code__c,
                    Shipping_State__c, Shipping_Street__c, Shipping_City__c from Shipping_Address__c where Account__r.Name = :orderObj.Ship_To_Name__c];
            
            
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('','Select'));
            for(Shipping_Address__c sAddress : sAdd){
                
                options.add(new SelectOption(sAddress.id,sAddress.Shipping_Address_Full_Name__c));
            }
            return options;
        }
        catch(Exception ex){
            ApexPages.addMessages(ex);
            return null;
        }
    }
    
    public void setAddress(){
        listAddress.clear();
        system.debug('selectedAddress =='+selectedAddress);
        if(selectedAddress ==null || selectedAddress ==''){
            listAddress.add(new Shipping_Address__c()) ; 
        }
        else{
            Shipping_Address__c address = [Select id, Name,Account__c , Account__r.Name, Shipping_Address_Full_Name__c, Shipping_Country__c, Shipping_Postal_Zip_Code__c,
                                           Shipping_State__c, Shipping_Street__c, Shipping_City__c from Shipping_Address__c where id = :selectedAddress LIMIT 1];
            if(address != null){
                listAddress.add(address) ; 
            }
        }
    }
    
    public pagereference updateOrder(){
        try{
            Shipping_Address__c addressFromPage = listAddress[0];
            system.debug('selectedAddress=='+selectedAddress);
            if(selectedAddress !=null && selectedAddress !=''){
                
                updateNameOnAddress(addressFromPage);
                system.debug('address==upadted =='+addressFromPage);
                update listAddress;
            }
            else{
                system.debug('Shipping address'+ listAddress);
                
                updateNameOnAddress(addressFromPage);
                addressFromPage.Account__c = order.AccountId ;
                system.debug('address==upadted =='+addressFromPage);
                
                insert listAddress;
                selectedAddress= addressFromPage.id;
            }
            Shipping_Address__c address = [Select id, Name,Account__c ,Account__r.Name, Shipping_Address_Full_Name__c, Shipping_Country__c, Shipping_Postal_Zip_Code__c,
                                           Shipping_State__c, Shipping_Street__c, Shipping_City__c from Shipping_Address__c where id = :selectedAddress LIMIT 1];
            if(address != null){
                system.debug('address'+address);
                order.Shippingcountry = address.Shipping_Country__c;
                Map<String, CountryWithCode__c> mapStatusCodeCustomSetting = CountryWithCode__c.getAll();
                Map<String, StateNameCode__c > mapStateCodeCustomSetting = StateNameCode__c.getAll();
                system.debug('mapStatusCodeCustomSetting =='+order.ShippingcountryCode);
                order.ShippingcountryCode = mapStatusCodeCustomSetting.get(address.Shipping_Country__c).Code__c;
                system.debug('order.ShippingcountryCode =='+order.ShippingcountryCode);
                order.Shippingcity = address.Shipping_City__c;
                order.Shippingstreet= address.Shipping_Street__c;
                if(address.Shipping_State__c != null){
                    string uniqueCode='';
                    if(address.Shipping_Country__c =='USA' || address.Shipping_Country__c =='United States' || address.Shipping_Country__c =='US' || address.Shipping_Country__c =='Canada'){
                        system.debug('address.Shipping_State__c=='+address.Shipping_State__c);
                        order.ShippingstateCode = address.Shipping_State__c ;//mapStateCodeCustomSetting.get(address.Shipping_State__c).code__C.substring(3,4);
                    }else{
                        order.ShippingstateCode = null;
                    }
               }
                else{
                    order.ShippingstateCode=null;
                }
                
                order.ShippingPostalCode= address.Shipping_Postal_Zip_Code__c;
                
                order.Shipping_Address_Label__c = address.Shipping_Address_Full_Name__c;
            }
            system.debug('order =='+order);
            update order;
            PageReference pg = new PageReference('/'+order.Id);
            String uiThemeDisplayed = UserInfo.getUiThemeDisplayed();
            if(uiThemeDisplayed != 'Theme3'){  // Lightning Theme Value          
                   aura.redirect(pg);
            }else{
                pg.setRedirect(true);
            }
            return pg;
        }
        catch(Exception ex){
            ApexPages.addMessages(ex);
            return null;
        }
    }
    
    public pagereference closePopup(){
       String uiThemeDisplayed = UserInfo.getUiThemeDisplayed();
        PageReference pg = new PageReference('/'+order.Id);
        if(uiThemeDisplayed=='Theme4d'){  // Lightning Theme Value          
               aura.redirect(pg);
        }else{
            pg.setRedirect(true);
        }
        return pg;
    }
    
    private void updateNameOnAddress(Shipping_Address__c address){
        
        String Name = '';
        Name += (address.Shipping_Street__c!= null && address.Shipping_Street__c.Length() >0) ? address.Shipping_Street__c +',':'';
        Name += (address.Shipping_City__c!= null && address.Shipping_City__c.Length() >0) ? address.Shipping_City__c +',':'';
        
        Name += (address.Shipping_State__c!= null && address.Shipping_State__c.Length() >0) ? address.Shipping_State__c +',':'';
        Name += (address.Shipping_Country__c!= null && address.Shipping_Country__c.Length() >0) ? address.Shipping_Country__c +',':'';
        Name += (address.Shipping_Postal_Zip_Code__c!= null && address.Shipping_Postal_Zip_Code__c.Length() >0) ? address.Shipping_Postal_Zip_Code__c:'';
        Name = Name.endsWith(',')? Name.removeEnd(','):Name;
        address.Name = name.length()> 80?Name.substring(0,79):name;
        address.Shipping_Address_Full_Name__c = name;
        
    }        
    
}