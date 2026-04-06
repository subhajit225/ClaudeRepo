/*--
  Related PAGE NAME:    OrderEditPage
  CONTROLLER:           OrderExtensionCntllr
  RELATED OBJECT:       Order
  PURPOSE:              To provide UI to Clone Order and Split the quantity for Order items.
  DEVELOPER:            SHADAB HUSSAIN
  DATE OF CREATION:     25/11/2016
  LAST MODIFIED DATE:   26/11/2016
*/
    public class OrderExtensionCntllr {
        public void testCoverage(){
            Integer i = 0;
        }
//         Public Order newSalesOrder{get;set;}
//         Public Order order{get;set;}
//         Public Boolean renderOrderBool{get;set;}

//         Public List< SelectOption > shippingAddressesOptions{get;set;}
//         Public List< SelectOption > shippingCountryOptions{get;set;}
//         Public List< SelectOption > shippingStateOptions{get;set;}
//         Public String selectedShippingAddress{get;set;}
//         public Id existingOrderId;
//         public OrderExtensionCntllr(ApexPages.StandardController controller) {
//             try{
//             order= New Order();
//             contact = new Contact();

//             shippingAddressesOptions = new List< SelectOption >();
//             shippingCountryOptions = new List< SelectOption >();
//             shippingStateOptions = new List< SelectOption >();
//             shippingAddressesOptions.add(new SelectOption('','--None--'));
//             shippingCountryOptions.add(new SelectOption('','--None--'));
//             shippingStateOptions.add(new SelectOption('','--None--'));
//              //Schema.DescribeFieldResult fieldResult =Order.ShippingCountry.getDescribe();
//              //List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
//             for(Countries__c country : Countries__c.getAll().values()){
//                  shippingStateOptions.add(new SelectOption(country.Name,country.Name));
//             }
//             for(States__c country : states__c.getAll().values()){
//                  shippingStateOptions.add(new SelectOption(country.Name,country.Name));
//             }
//             selectedShippingAddress ='';
//             String OppId =apexpages.currentpage().getparameters().get('oppid');
//             if(apexpages.currentpage().getparameters().get('id') != null){
//                 existingOrderId = apexpages.currentpage().getparameters().get('id');
//             }


//             //system.debug('existingOrderId=='+existingOrderId);
//             if(existingOrderId != null){
//             order existingOrder = [select id ,AccountId,Type,OpportunityId,Status,ShiptoName__C,ShiptoContactName__C,EffectiveDate,Change_Needed_Reasons__c,NetSuite_Order__c,Change_Needed_Reason_Other__c,
//                                    PoNumber,Po_Number__c,Shipping_Carrier__c,PoDate,Shipping_Carrier_Other__c,End_User_PO__c,Ship_Method__c,Payment_Terms__c,Shipping_Terms_Other__c,Bill_To_Name__c,
//                                    Ship_To_Name__c,Ship_To_Contact_Name__c,ShippingCountry,ShippingCountryCode,ShippingStateCode,ShippingStreet,ShippingCity,ShippingState,ShippingPostalCode,Ship_to_Email__c,Ship_To_Phone_Number__c,Order_Status__c,
//                                    //Est_Ship_Date__c,Shipping_Method__c,recordTypeId, RMA_Request__c, Shipping_Address_Label__c, Service_Level__c, Cancellation_Reason__c ,Actual_Order_Ship_Date__c,Tracking_No__c from Order where id=:existingOrderId];
//                                    Est_Ship_Date__c,Shipping_Method__c,recordTypeId, Shipping_Address_Label__c, Service_Level__c, Cancellation_Reason__c ,Actual_Order_Ship_Date__c,Tracking_No__c,Description from Order where id=:existingOrderId];
//             order=  existingOrder;
//             system.debug('order  =='+order.Status);
//             if(String.isbLank(order.Shipping_Address_Label__c) || order.Shipping_Address_Label__c == null){}
//             getShippingAddress(order);

//             System.debug('order=='+order.Shipping_Address_Label__c);
//             //if(order.Shipping_Address_Label__c != '')
//             selectedShippingAddress =order.Shipping_Address_Label__c;
//             System.debug('order=='+selectedShippingAddress);
//             if(order.Ship_To_Name__c != null)
//             contact.AccountId =order.Ship_To_Name__c;
//             if(apexpages.currentpage().getparameters().get('isClone') != null){
//                 order.id = null;
//                 //order.Status = 'Pending';
//                 order.Order_Status__c = 'Pending';
//             }
//             else
//             order.id = existingOrder.Id;


//             if(String.isBlank(order.PONumber)){
//                 order.PONumber ='n/a';
//             }
//             if(Order.Ship_To_Name__c != null){
//                      selectShippingAddress();
//                      system.debug('test=='+Order.Ship_To_Name__c);
//                 Map<String,Id> mapShippingAddress = new Map<String,Id>();
//                 for(Shipping_Address__c sddrs : [select id,name,Shipping_Address_Full_Name__c from Shipping_Address__c where Account__C =: order.Ship_To_Name__c ]){
//                     mapShippingAddress.put(sddrs.Shipping_Address_Full_Name__c,sddrs.id);
//                 }
//                 String Name = '';
//                    Name += (Order.ShippingStreet!= null && Order.ShippingStreet.Length() >0) ? Order.ShippingStreet +',':'';
//                    Name += (Order.ShippingCity!= null && Order.ShippingCity.Length() >0) ? Order.ShippingCity +',':'';

//                    Name += (Order.ShippingState!= null && Order.ShippingState.Length() >0) ? Order.ShippingState +',':'';
//                    Name += (Order.ShippingCountry!= null && Order.ShippingCountry.Length() >0) ? Order.ShippingCountry +',':'';
//                    Name += (Order.ShippingPostalCode!= null && Order.ShippingPostalCode.Length() >0) ? Order.ShippingPostalCode:'';
//                    Name = Name.endsWith(',')? Name.removeEnd(','):Name;
//                    system.debug('mapShippingAddress =='+mapShippingAddress);
//                 if(mapShippingAddress.containsKey(Name)){
//                     system.debug('Name =='+Name);
//                     //order.Shipping_Address_Label__c = 'test109876,Test City1230987,Austria,123459';//Name;
//                     selectedShippingAddress = name.length()> 80?Name.substring(0,79):name;
//                     system.debug('order.Shipping_Address_Label__c  =='+selectedShippingAddress);
//                 }

//             }


//             }
//             else if(OppId != null && OppId != ''){

//             //System.debug('controller=='+controller);
//             List<Opportunity> relatedOpp = [select id, name ,AccountId,Account.Name,Account.IOR_Received__c,Partner_Lookup__r.Payment_Term__c, Partner_Lookup__c,Partner_Lookup__r.Name,Partner_Lookup__r.Id,Partner_Lookup__r.ShippingStreet,Partner_Lookup__r.ShippingCity,Partner_Lookup__r.ShippingState,Partner_Lookup__r.ShippingCountry,Partner_Lookup__r.ShippingPostalCode,
//             Distributor_Lookup__r.Payment_Term__c,Partner_Lookup__r.Distributor__r.Payment_Term__c,
//             Partner_Lookup__r.Shipping_Carrier__c , Partner_Lookup__r.Shipping_Method__c , Partner_Lookup__r.Shipping_Account_Number__c,Partner_Lookup__r.IncoTerms__c,Partner_Lookup__r.Distributor__c,
//                                     Distributor_Lookup__r.Shipping_Carrier__c , Distributor_Lookup__r.Shipping_Method__c , Distributor_Lookup__r.Shipping_Account_Number__c,Distributor_Lookup__r.IncoTerms__c,
//                                     Partner_Lookup__r.Distributor__r.Shipping_Carrier__c,Partner_Lookup__r.Distributor__r.Shipping_Method__c,Partner_Lookup__r.Distributor__r.Shipping_Account_Number__c,Partner_Lookup__r.Distributor__r.IncoTerms__c,
//             Partner_Lookup__r.ShippingAddress from opportunity where id=:OppId];
//                 if(!relatedOpp.isEmpty())
//                  order.Opportunityid=relatedOpp[0].Id;
//                  order.Accountid=relatedOpp[0].AccountId;
//                  order.EffectiveDate = Date.Today();

//                  //order.Bill_To_Name__c = relatedOpp[0].Partner_Lookup__c;
//                  //order.Payment_Terms__c = relatedOpp[0].Partner_Lookup__r.Payment_Term__c;
//                  /*order.Shippingcountry = relatedOpp[0].Partner_Lookup__r.ShippingCountry;
//                  order.Shippingcity = relatedOpp[0].Partner_Lookup__r.ShippingCity;
//                  order.Shippingstreet=relatedOpp[0].Partner_Lookup__r.Shippingstreet;
//                  order.Shippingstate=relatedOpp[0].Partner_Lookup__r.ShippingState;
//                  order.ShippingPostalCode=relatedOpp[0].Partner_Lookup__r.ShippingPostalCode;*/
//                  //order.Status='Received';
//                  order.Order_Status__c = 'Received';

//                  /*if(relatedOpp[0].Partner_Lookup__c != null && relatedOpp[0].Partner_Lookup__r.Distributor__c != null )
//                   order.Bill_To_Name__c = relatedOpp[0].Partner_Lookup__r.Distributor__c;
//               else if(relatedOpp[0].Partner_Lookup__c != null && relatedOpp[0].Partner_Lookup__r.Distributor__c == null )
//                   order.Bill_To_Name__c = relatedOpp[0].Partner_Lookup__c;
//               else if(relatedOpp[0].Partner_Lookup__c == null && relatedOpp[0].Distributor_lookup__c != null)
//                    order.Bill_To_Name__c = relatedOpp[0].Distributor_lookup__c;

//               if(relatedOpp[0].Partner_Lookup__c != null && relatedOpp[0].Partner_Lookup__r.Distributor__c != null )
//                   order.Payment_Terms__c = relatedOpp[0].Partner_Lookup__r.Distributor__r.Payment_Term__c;
//               else if(relatedOpp[0].Partner_Lookup__c != null && relatedOpp[0].Partner_Lookup__r.Distributor__c == null )
//                   order.Payment_Terms__c = relatedOpp[0].Partner_Lookup__r.Payment_Term__c;
//               else if(relatedOpp[0].Partner_Lookup__c == null && relatedOpp[0].Distributor_lookup__c != null )
//                   order.Payment_Terms__c = relatedOpp[0].Distributor_Lookup__r.Payment_Term__c;

//                   if(relatedOpp[0].Partner_Lookup__c != null && relatedOpp[0].Partner_Lookup__r.Distributor__c != null )
//                   order.Shipping_Carrier__c = relatedOpp[0].Partner_Lookup__r.Distributor__r.Shipping_Carrier__c;
//               else if(relatedOpp[0].Partner_Lookup__c != null && relatedOpp[0].Partner_Lookup__r.Distributor__c == null )
//                   order.Shipping_Carrier__c = relatedOpp[0].Partner_Lookup__r.Shipping_Carrier__c;
//               else if(relatedOpp[0].Partner_Lookup__c == null && relatedOpp[0].Distributor_lookup__c != null )
//                   order.Shipping_Carrier__c = relatedOpp[0].Distributor_Lookup__r.Shipping_Carrier__c;

//                   if(relatedOpp[0].Partner_Lookup__c != null && relatedOpp[0].Partner_Lookup__r.Distributor__c != null )
//                   order.Shipping_Method__c = relatedOpp[0].Partner_Lookup__r.Distributor__r.Shipping_Method__c;
//               else if(relatedOpp[0].Partner_Lookup__c != null && relatedOpp[0].Partner_Lookup__r.Distributor__c == null )
//                   order.Shipping_Method__c = relatedOpp[0].Partner_Lookup__r.Shipping_Method__c;
//               else if(relatedOpp[0].Partner_Lookup__c == null && relatedOpp[0].Distributor_lookup__c != null )
//                   order.Shipping_Method__c = relatedOpp[0].Distributor_Lookup__r.Shipping_Method__c;

//                   if(relatedOpp[0].Partner_Lookup__c != null && relatedOpp[0].Partner_Lookup__r.Distributor__c != null )
//                   order.Shipping_Account_Number__c = relatedOpp[0].Partner_Lookup__r.Distributor__r.Shipping_Account_Number__c;
//               else if(relatedOpp[0].Partner_Lookup__c != null && relatedOpp[0].Partner_Lookup__r.Distributor__c == null )
//                   order.Shipping_Account_Number__c = relatedOpp[0].Partner_Lookup__r.Shipping_Account_Number__c;
//               else if(relatedOpp[0].Partner_Lookup__c == null && relatedOpp[0].Distributor_lookup__c != null )
//                   order.Shipping_Account_Number__c = relatedOpp[0].Distributor_Lookup__r.Shipping_Account_Number__c;

//               if(relatedOpp[0].Partner_Lookup__c != null && relatedOpp[0].Partner_Lookup__r.Distributor__c != null )
//                   order.IncoTerms__c = relatedOpp[0].Partner_Lookup__r.Distributor__r.IncoTerms__c;
//               else if(relatedOpp[0].Partner_Lookup__c != null && relatedOpp[0].Partner_Lookup__r.Distributor__c == null )
//                   order.IncoTerms__c = relatedOpp[0].Partner_Lookup__r.IncoTerms__c;
//               else if(relatedOpp[0].Partner_Lookup__c == null && relatedOpp[0].Distributor_lookup__c != null )
//                   order.IncoTerms__c = relatedOpp[0].Distributor_Lookup__r.IncoTerms__c;
// */
//             }
//             renderOrderBool=true;
//             }
//             catch(Exception ex){
//                 ApexPages.addMessages(ex);
//             }
//         }
//         public pagereference saveOrderAndAddProducts(){
//             try{
//             upsert order;
//             Id newOrderId = order.id;
//             Id OppId =order.Opportunityid;
//             Pagereference ref = new Pagereference('/apex/AddOrderLineItems');
//             ref.getParameters().put('oldOrderId',existingOrderId);
//             ref.getParameters().put('Id',newOrderId);
//             ref.getParameters().put('oppid',OppId);
//             ref.getParameters().put('action','edit');
//             return ref;
//             }
//             catch(Exception ex){
//                 ApexPages.addMessages(ex);
//                 return null;
//             }
//         }
//         public void selectShippingAddress(){
//             try{
//             if(order.Ship_To_Name__c != null){
//                 shippingAddressesOptions = new List< SelectOption >();
//                     shippingAddressesOptions.add(new SelectOption('','--None--'));
//                 for(Shipping_Address__c address : [Select id,Name,Shipping_Address_Full_Name__c,Account__C from Shipping_Address__c where Account__C =: order.Ship_To_Name__c]){

//                     shippingAddressesOptions.add(new SelectOption(address.Name,address.Name));
//                 }
//                 contact.AccountId =order.Ship_To_Name__c;
//             }
//             }
//             catch(Exception ex){
//                 ApexPages.addMessages(ex);

//             }
//         }
//         public void resetCountryCode(){
//             Map<String, CodeWithCountry__c> mapStatusCounrtyCodeCustomSetting = CodeWithCountry__c.getAll();
//             system.debug('mapStatusCounrtyCodeCustomSetting =='+order.ShippingcountryCode);
//             order.Shippingcountry = mapStatusCounrtyCodeCustomSetting.get(order.ShippingcountryCode).Country__c;
//             system.debug('order.ShippingcountryCode =='+order.Shippingcountry);
//         }
//         public void onSelectShippingAddress(){
//             try{
//             if(selectedShippingAddress != ''){
//                 system.debug('selectedShippingAddress'+selectedShippingAddress);
//                 selectedShippingAddress = selectedShippingAddress.length()> 80?selectedShippingAddress.substring(0,79):selectedShippingAddress;
//                 for(Shipping_Address__C address : [Select id,Name, Shipping_Address_Full_Name__c, Account__C, Shipping_City__c, Shipping_Country__c, Shipping_Postal_Zip_Code__c, Shipping_State__c, Shipping_Street__c from Shipping_Address__c where name =: selectedShippingAddress AND Account__C =: order.Ship_To_Name__c ]){
//                     system.debug('address'+address);
//                     order.Shippingcountry = address.Shipping_Country__c;
//                     Map<String, CountryWithCode__c> mapStatusCodeCustomSetting = CountryWithCode__c.getAll();
//                     Map<String, StateNameCode__c > mapStateCodeCustomSetting = StateNameCode__c.getAll();
//                     system.debug('mapStatusCodeCustomSetting =='+order.ShippingcountryCode);
//                     order.ShippingcountryCode = mapStatusCodeCustomSetting.get(address.Shipping_Country__c).Code__c;
//                     system.debug('order.ShippingcountryCode =='+order.ShippingcountryCode);
//                  order.Shippingcity = address.Shipping_City__c;
//                  order.Shippingstreet= address.Shipping_Street__c;
//                  if(address.Shipping_State__c != null){
//                        string uniqueCode='';
//                         if(address.Shipping_Country__c =='USA' || address.Shipping_Country__c =='United States' || address.Shipping_Country__c =='US' || address.Shipping_Country__c =='Canada'){
//                             system.debug('address.Shipping_State__c=='+address.Shipping_State__c);
//                             //system.debug('map value=='+mapStateCodeCustomSetting.get(address.Shipping_State__c).code__C.substring(3,4));
//                             order.ShippingstateCode = address.Shipping_State__c ;//mapStateCodeCustomSetting.get(address.Shipping_State__c).code__C.substring(3,4);
//                         }else{
//                              order.ShippingstateCode = null;
//                          }
//                         // Account acc = [Select Id, ShippingCountryCode, ShippingStateCode,ShippingState from Account Where ShippingCountryCode =: order.ShippingcountryCode Limit 1];

//                      //order.Shippingstate= acc.ShippingState;
//                      //order.ShippingstateCode= acc.ShippingStateCode;
//                  }
//                  else{
//                      order.ShippingstateCode=null;
//                  }

//                  order.ShippingPostalCode= address.Shipping_Postal_Zip_Code__c;

//                  order.Shipping_Address_Label__c = address.Shipping_Address_Full_Name__c;
//                 }
//             }

//             }
//             catch(Exception ex){
//                 ApexPages.addMessages(ex);

//             }
//         }

//         public pagereference saveOrder(){
//            try{
//             system.debug('test order--'+order);
//             Map<String, CodeWithCountry__c> mapStatusCounrtyCodeCustomSetting = CodeWithCountry__c.getAll();
//             Map<String, StateCodeName__C> mapStatusStateCodeCustomSetting = StateCodeName__C.getAll();
//             system.debug('mapStatusCounrtyCodeCustomSetting =='+order.ShippingcountryCode);
//             system.debug('mapStatusStateCodeCustomSetting =='+mapStatusStateCodeCustomSetting);
//             order.Shippingcountry = mapStatusCounrtyCodeCustomSetting.get(order.ShippingcountryCode).Country__c;
//             system.debug('order.ShippingcountryCode =='+order.Shippingcountry);
//             system.debug('test order 22--'+order);
//             if(order.ShippingStateCode != null){
//                         string uniqueCode='';
//                         if(order.ShippingcountryCode =='USA'){
//                             uniqueCode = order.ShippingcountryCode.Substring(0,order.ShippingcountryCode.length()-1)+'-'+order.ShippingStateCode;
//                         }else{
//                             uniqueCode = order.ShippingcountryCode+'-'+order.ShippingStateCode;
//                         }
//                         system.debug('state code =='+uniqueCode);
//                         System.debug('Map State'+mapStatusStateCodeCustomSetting);
//                         StateCodeName__C myCS2 = StateCodeName__C.getInstance(uniqueCode);
//                         system.debug('myCS2 =='+myCS2);
//                         System.debug('Map Value'+mapStatusStateCodeCustomSetting.get(uniqueCode).State_Name__c);
//                         if(mapStatusStateCodeCustomSetting.get(uniqueCode).State_Name__c != null){
//                             if(order.ShippingcountryCode != 'USA' || order.ShippingcountryCode != 'US'){
//                             order.Shippingstate= mapStatusStateCodeCustomSetting.get(uniqueCode).State_Name__c;
//                             }else{
//                              order.Shippingstate=order.ShippingStateCode;
//                             // system.debug('StateName'+mapStatusStateCodeCustomSetting.get(uniqueCode).State_Name__c);
//                              // order.Shippingstate= mapStatusStateCodeCustomSetting.get(uniqueCode).State_Name__c;
//                             }
//                         }
//                          else{
//                              order.Shippingstate= null;
//                          }
//                         // Account acc = [Select Id, ShippingCountryCode, ShippingStateCode,ShippingState from Account Where ShippingStateCode =: order.ShippingStateCode Limit 1];

//                      //order.Shippingstate= acc.ShippingState;
//                      //order.Shippingstate= acc.ShippingState;
//             }else{
//                 order.Shippingstate= null;
//             }
//             order.Shipping_Address_Label__c =selectedShippingAddress;
//             system.debug('test order 3333--'+order);

//             upsert order;
//             Id newOrderId =order.id;
//             Id OppId =order.Opportunityid;
//             Pagereference ref = new Pagereference('/'+newOrderId);
//             //ref.getParameters().put('oldOrderId',existingOrderId);
//             //ref.getParameters().put('newOrderId',newOrderId);
//             //ref.getParameters().put('OppID',OppId);
//             return ref;
//             }
//             catch(Exception ex){
//                 ApexPages.addMessages(ex);
//                 return null;
//             }
//         }
//         public void updateContactText(){
//             system.debug('order.Ship_To_Contact_Name__C =='+order.Ship_To_Contact_Name__C);
//             contact.LastName= order.Ship_To_Contact_Name__C;
//         }

//         public Contact contact {get;set;} // new account to create
//         // save the new account record
//           public void saveContact() {
//               system.debug('contact =='+contact);
//               Contact.LeadSource='Email';
//               Contact.AccountID= order.Ship_To_Name__c;
//             insert contact;
//             order.Ship_To_Contact_Name__c = contact.Id;
//             /*if(Contact.Email != null){
//             order.Ship_To_Email__c = contact.Email;
//             }
//             if(Contact.phone != null){
//                 order.Ship_To_Phone_Number__c = contact.Phone;
//             }*/
//             // reset the account
//             contact = new Contact();
//             //return null;
//           }
//         public void getShippingAddress(Order ordr){
//             List<ID> ShipToIds = new List<ID>();

//                 if(ordr.ship_To_Name__C != null)
//                 ShipToIds.add(ordr.ship_To_Name__C);

//             Map<String,Id> mapShippingAddress = new Map<String,Id>();
//             for(Shipping_Address__c sddrs : [select id,name, Shipping_Address_Full_Name__c from Shipping_Address__c where Account__c IN:ShipToIds ]){
//                 mapShippingAddress.put(sddrs.Shipping_Address_Full_Name__c,sddrs.id);
//             }
//             String Name = '';
//                 Name += (ordr.ShippingStreet!= null && ordr.ShippingStreet.Length() >0) ? ordr.ShippingStreet +',':'';
//                 Name += (ordr.ShippingCity!= null && ordr.ShippingCity.Length() >0) ? ordr.ShippingCity +',':'';
//                 if(ordr.ShippingCountry!= null && (ordr.ShippingCountry =='USA' || ordr.ShippingCountry =='US' || ordr.ShippingCountry =='United States' || ordr.ShippingCountry =='Canada'))
//                 Name += (ordr.ShippingState!= null && ordr.ShippingState.Length() >0) ? ordr.ShippingState +',':'';
//                 else
//                 Name += '';
//                 Name += (ordr.ShippingCountry!= null && ordr.ShippingCountry.Length() >0) ? ordr.ShippingCountry +',':'';
//                 Name += (ordr.ShippingPostalCode!= null && ordr.ShippingPostalCode.Length() >0) ? ordr.ShippingPostalCode:'';
//                 Name = Name.endsWith(',')? Name.removeEnd(','):Name;
//                 system.debug('Name value ==='+Name);
//                 system.debug('mapShippingAddress.containsKey(Name) value ==='+mapShippingAddress.containsKey(Name));
//                 if(mapShippingAddress.containsKey(Name)){

//                     ordr.Shipping_Address_Label__c = name.length()> 80?Name.substring(0,79):name;
//                     system.debug('ordr.Shipping_Address_Label__c ==='+Name);
//                 }
//                 system.debug('Name value ==='+Name);
//             }
//             //return

    }