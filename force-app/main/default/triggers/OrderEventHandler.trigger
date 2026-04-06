trigger OrderEventHandler on Order_Event__e (after insert) {
   /* Set<Id> orderIdsForProfileUpdate = new Set<Id>();
    Set<Id> ordersToActivate = new Set<Id>();
    Set<Id> rmaOrdersToProcess = new Set<Id>();
    Set<Id> pocOrdersToFulfill = new Set<Id>();
    // Added for PRDOPS21-221   
    Set<Id> thirdParyOrders = new Set<Id>();
    for(Order_Event__e event : Trigger.new){
       if(event.Action_Type__c == 'ACTIVATE_ORDER'){
            ordersToActivate.add(event.Order_Id__c);
        }
        else if(event.Action_Type__c == 'RMA_SPARE_CREATE'){
            rmaOrdersToProcess.add(event.Order_Id__c);
        }
        else if(event.Action_Type__c == 'UPDATE_USER_PROFILE_MANUFACTURING_CONTACTS'){
            orderIdsForProfileUpdate.add(event.Order_Id__c);
        }
        else if(event.Action_Type__c == 'POC_ORDER_AUTOFULFILL'){
            pocOrdersToFulfill.add(event.Order_Id__c);
        }
        // Added for PRDOPS21-221 
        else if(event.Action_Type__c == 'THIRDPARTYORDER_AUTOFULFILL'){
           thirdParyOrders.add(event.Order_Id__c);
        }
        //end
        
    }
    
    activateOrders(ordersToActivate);
    createRMASpares(rmaOrdersToProcess);
    userProfileUpdate(orderIdsForProfileUpdate);
    fulfillPOCOrders(pocOrdersToFulfill);
    // Added for PRDOPS21-221 
    fulfillThirdPartyOrders(thirdParyOrders);

    public void activateOrders(Set<Id> OrderIdSet){
        updateEntitlementAssetForGoRefresh(OrderIdSet);
        List<Order> ordersToActivate = new List<Order>();
        if(!OrderIdSet.isEmpty()) {
            for(Order ord : [SELECT Id, Stage_PO__c FROM Order WHERE Id IN :OrderIdSet
                                AND Status != 'Activated'
                                AND Opportunity.SBQQ__PrimaryQuote__c != null
                                AND Type != 'POC']) {

                if(ord.Stage_PO__c != null){
                    ordersToActivate.add(
                        new Order(Id = ord.Id, Status = 'Activated', EDI_Sync_Status__c='Y')
                    );
                }
                else{
                    ordersToActivate.add(
                        new Order(Id = ord.Id, Status = 'Activated', EDI_Sync_Status__c='N')
                    );
                }
            }

            if(!ordersToActivate.isEmpty()) {
                update ordersToActivate;
            }
        }
    }
    private void updateEntitlementAssetForGoRefresh(Set<Id> OrderIdSet){
        Map<Id, Date> assetRefreshDateMap = new Map<Id, Date>();
        List<Asset> refreshedAssets = new List<asset>();
        Map<string,Id> newUpgradedAssetMap = new Map<string,Id>();
        for(OrderItem oi: [Select Id,SerialNumber__c,R300_R500_Asset__c, Order.Actual_Order_Ship_Date__c from OrderItem where OrderId in :OrderIdSet and R300_R500_Asset__c != null and Order.Actual_Order_Ship_Date__c != null]){
            assetRefreshDateMap.put(oi.R300_R500_Asset__c, oi.Order.Actual_Order_Ship_Date__c);
            refreshedAssets.add(new asset(id=oi.R300_R500_Asset__c, UsageEndDate=oi.Order.Actual_Order_Ship_Date__c.addDays(60),Is_Refreshed__c=true, Refresh_date__c = oi.Order.Actual_Order_Ship_Date__c)); //
            newUpgradedAssetMap.put(oi.SerialNumber__c,oi.R300_R500_Asset__c);
        }
        for(Asset asst :[select id,SerialNumber from asset where SerialNumber IN : newUpgradedAssetMap.keyset()]){
           if(newUpgradedAssetMap.containskey(asst.SerialNumber)){
             refreshedAssets.add(new asset(id=asst.id,Upgraded_Asset__c = newUpgradedAssetMap.get(asst.SerialNumber)));
           }
        } 
        List<Entitlement> entitlementsToUpdate = new List<Entitlement>();
        for(Entitlement ent : [Select Id,EndDate, AssetId, Product__r.Gorefresh_Mark_SW_End_Date__c from Entitlement where AssetId in :assetRefreshDateMap.keySet()]){
            Date refreshDate = assetRefreshDateMap.get(ent.AssetId);
            if(ent.Product__r.Gorefresh_Mark_SW_End_Date__c == true){
                entitlementsToUpdate.add(new Entitlement(Id = ent.Id, Go_Refresh__c = true, Refresh_Grace_Period_Start_Date__c = refreshDate, SW_Support_End_Date__c = refreshDate.addDays(60)));
            }
            else{
                if(ent.EndDate!=null && ent.EndDate>refreshDate.addDays(60)){
                    entitlementsToUpdate.add(new Entitlement(Id = ent.Id, Go_Refresh__c = true, Refresh_Grace_Period_Start_Date__c = refreshDate, EndDate = refreshDate.addDays(60)));
                }
                else{
                    entitlementsToUpdate.add(new Entitlement(Id = ent.Id, Go_Refresh__c = true, Refresh_Grace_Period_Start_Date__c = refreshDate));
                }
            }
        }

        if(entitlementsToUpdate.size()>0){
            update entitlementsToUpdate;
        }
        if(!refreshedAssets.isEmpty()){
           update refreshedAssets ;
        }
    }

    public void createRMASpares(Set<Id> OrderIdSet){
        Map<String, String> failedVsNewChassisMap = new Map<String, String>();
        Map<String, String> failedVsNewPSUMap = new Map<String, String>();
        Map<String, String> failedVsNewHDDMap = new Map<String, String>();
        Map<String, String> failedVsNewSSDMap = new Map<String, String>();
        Map<String, String> failedVsNewMemoryMap = new Map<String, String>();
        // maps created for parent association for newly created assets
        Map<string, string> chassisToAssociateParent = new Map<string, string>();
        Map<string, string> PSUToAssociateParent = new Map<string, string>();
        Map<string, string> hddToAssociateParent = new Map<string, string>();
        Map<string, string> ssdToAssociateParent = new Map<string, string>();
        Map<string, string> memoryToAssociateParent = new Map<string, string>();
       
        //Query All RMA Orders that are shipped, create a map of failed serial number vs corresponding new serial number
        for(Order ord:[Select Id, RMA_Request__r.Chassis__c, RMA_Request__r.Power_Supply__c,RMA_Request__r.Drive__c,RMA_Request__r.SSD__c,RMA_Request__r.Memory__c,(Select Id, Failed_Serial_Number__c, 
            SerialNumber__c from OrderItems) from Order where Type = 'RMA' and Order_Status__c = 'Shipped' and Id in :OrderIdSet]){
            if(String.isNotBlank(ord.RMA_Request__r.Chassis__c)){
                String failedChassis = ord.RMA_Request__r.Chassis__c;
                for(OrderItem oi: ord.OrderItems){
                    if(String.isNotBlank(oi.Failed_Serial_Number__c) && failedChassis.indexOf(oi.Failed_Serial_Number__c) != -1){
                        failedVsNewChassisMap.put(oi.Failed_Serial_Number__c, oi.SerialNumber__c);
                    }
                }
            }

            if(String.isNotBlank(ord.RMA_Request__r.Power_Supply__c)){
                String failedPSU = ord.RMA_Request__r.Power_Supply__c;
                for(OrderItem oi: ord.OrderItems){
                    if(String.isNotBlank(oi.Failed_Serial_Number__c) && failedPSU.indexOf(oi.Failed_Serial_Number__c) != -1){
                        failedVsNewPSUMap.put(oi.Failed_Serial_Number__c, oi.SerialNumber__c);
                    }
                }
            }
            //HDD Replacement
            if(String.isNotBlank(ord.RMA_Request__r.Drive__c)){
                String failedHDD = ord.RMA_Request__r.Drive__c;
                for(OrderItem oi: ord.OrderItems){
                    if(String.isNotBlank(oi.Failed_Serial_Number__c) && failedHDD.indexOf(oi.Failed_Serial_Number__c) != -1){
                        failedVsNewHDDMap.put(oi.Failed_Serial_Number__c, oi.SerialNumber__c);
                    }
                }
            }
            //SSD Replacement
            if(String.isNotBlank(ord.RMA_Request__r.SSD__c)){
                String failedSSD = ord.RMA_Request__r.SSD__c;
                for(OrderItem oi: ord.OrderItems){
                    if(String.isNotBlank(oi.Failed_Serial_Number__c) && failedSSD.indexOf(oi.Failed_Serial_Number__c) != -1){
                        failedVsNewSSDMap.put(oi.Failed_Serial_Number__c, oi.SerialNumber__c);
                    }
                }
            }
            
            // Memory Replacement
            if(String.isNotBlank(ord.RMA_Request__r.Memory__c)){
                String failedMemory = ord.RMA_Request__r.Memory__c;
                for(OrderItem oi: ord.OrderItems){
                    if(String.isNotBlank(oi.Failed_Serial_Number__c) && failedMemory.indexOf(oi.Failed_Serial_Number__c) != -1){
                        failedVsNewMemoryMap.put(oi.Failed_Serial_Number__c, oi.SerialNumber__c);
                    }
                }
            }
            
        }

        if(!failedVsNewChassisMap.isEmpty()){
           Map<String, Chassis__c> chassisMap = new Map<String, Chassis__c>();
            for(Chassis__c chassis: [select Name, serial_number__c, asset__c from Chassis__c where serial_number__c in :failedVsNewChassisMap.keySet() or serial_number__c in :failedVsNewChassisMap.values()]){
                    chassisMap.put(chassis.serial_number__c, chassis);
            }

            Map<String, Chassis__c> chassisToCreate = new Map<String, Chassis__c>();
            //parent association chassis
           
            for(String failedChassisSerial: failedVsNewChassisMap.keySet()){
                String newChassisSerial = failedVsNewChassisMap.get(failedChassisSerial);
                Chassis__c failedChassis = chassisMap.get(failedChassisSerial);
                if(failedChassis != null && !chassisMap.containsKey(newChassisSerial)){
                    chassisToCreate.put(newChassisSerial, new Chassis__c(Name = newChassisSerial, serial_number__c = newChassisSerial, asset__c = failedChassis.asset__c));
                    // added for parent association 
                    chassisToAssociateParent.put(newChassisSerial,failedChassis.asset__c);
                }
            }

            if(chassisToCreate.size()>0){
                insert chassisToCreate.values();
            }
            
            List<Node__c> nodesToUpdate = new List<Node__c>();
            for(Node__c node: [select Id, chassis__r.serial_number__c from Node__c where chassis__r.serial_number__c in :failedVsNewChassisMap.keySet()]){
                String newChassisSerial = failedVsNewChassisMap.get(node.chassis__r.serial_number__c);
                nodesToUpdate.add(new Node__c(Id=node.Id, chassis__c = chassisToCreate.get(newChassisSerial).Id));
            }

            if(nodesToUpdate.size()>0){
                update nodesToUpdate;
            }
            
            
        }
         // PSU Replacement
        if(!failedVsNewPSUMap.isEmpty()){
            Map<String, Power_Supply__c> psuMap = new Map<String, Power_Supply__c>();
            
            for(Power_Supply__c psu: [select Id,  Name, asset__c, revision__c, serial_number__c, part_number__c from Power_Supply__c where serial_number__c in :failedVsNewPSUMap.keySet() or serial_number__c in :failedVsNewPSUMap.values()]){
                    psuMap.put(psu.serial_number__c, psu);
            }

            Map<String, Power_Supply__c> psuToCreate = new Map<String, Power_Supply__c>();
            for(String failedPSUSerial: failedVsNewPSUMap.keySet()){
                String newPSUSerial = failedVsNewPSUMap.get(failedPSUSerial);
                Power_Supply__c failedPSU = psuMap.get(failedPSUSerial);
                if(failedPSU != null && !psuMap.containsKey(newPSUSerial)){
                    psuToCreate.put(newPSUSerial, new Power_Supply__c(Name = newPSUSerial, serial_number__c = newPSUSerial, asset__c = failedPSU.asset__c, revision__c = failedPSU.revision__c, part_number__c = failedPSU.part_number__c));
                    PSUToAssociateParent.put(newPSUSerial,failedPSU.asset__c);
                }
            }

            if(psuToCreate.size()>0){
                insert psuToCreate.values();
            }
        }
        // HDD replacement
        if(!failedVsNewHDDMap.isEmpty()){
            Map<String, Drive__c> hddMap = new Map<String, Drive__c>();
            for(Drive__c hdd: [select Id,serial_number__c,Name,node__c,asset__c ,type__c, capacity__c from Drive__c where serial_number__c in :failedVsNewHDDMap.keySet() or serial_number__c in :failedVsNewHDDMap.values()]){
                    hddMap.put(hdd.serial_number__c, hdd);
            }

            Map<String, Drive__c> hddToCreate = new Map<String, Drive__c>();
            for(String failedhddSerial: failedVsNewHDDMap.keySet()){
                String newHDDSerial = failedVsNewHDDMap.get(failedhddSerial);
                Drive__c failedHDD = hddMap.get(failedhddSerial);
                if(failedHDD != null && !hddMap.containsKey(newHDDSerial)){
                    hddToCreate.put(newHDDSerial, new Drive__c(Name = newHDDSerial, serial_number__c = newHDDSerial, asset__c = failedHDD.asset__c, type__c = failedHDD.type__c, capacity__c = failedHDD.capacity__c,node__c = failedHDD.node__c));
                    hddToAssociateParent.put(newHDDSerial,failedHDD.asset__c);
                }
            }

            if(hddToCreate.size()>0){
                insert hddToCreate.values();
            }
        }
        //SSD Replacement
        if(!failedVsNewSSDMap.isEmpty()){
           Map<String, Drive__c> ssdMap = new Map<String, Drive__c>();
            for(Drive__c ssd: [select Id,serial_number__c,Name,node__c,asset__c ,type__c, capacity__c from Drive__c where serial_number__c in :failedVsNewSSDMap.keySet() or serial_number__c in :failedVsNewSSDMap.values()]){
                    ssdMap.put(ssd.serial_number__c, ssd);
            }

            Map<String, Drive__c> ssdToCreate = new Map<String, Drive__c>();
            for(String failedSSDSerial: failedVsNewSSDMap.keySet()){
                String newSSDSerial = failedVsNewSSDMap.get(failedSSDSerial);
                Drive__c failedSSD = ssdMap.get(failedSSDSerial);
                if(failedSSD != null && !ssdMap.containsKey(newSSDSerial)){
                    ssdToCreate.put(newSSDSerial, new Drive__c(Name = newSSDSerial, serial_number__c = newSSDSerial, asset__c = failedSSD.asset__c, type__c = failedSSD.type__c, capacity__c = failedSSD.capacity__c,node__c = failedSSD.node__c));
                    ssdToAssociateParent.put(newSSDSerial,failedSSD.asset__c);
                }
            }

            if(ssdToCreate.size()>0){
                insert ssdToCreate.values();
            }
        }
        
        //Memory Replacement
        if(!failedVsNewMemoryMap.isEmpty()){
            Map<String, Memory__c> memoryMap = new Map<String, Memory__c>();
            for(Memory__c memory: [select id ,serial_number__c, Name,asset__c, node__c from Memory__c where serial_number__c in :failedVsNewMemoryMap.keySet() or serial_number__c in :failedVsNewMemoryMap.values()]){
                    memoryMap.put(memory.serial_number__c, memory);
            }

            Map<String, Memory__c> memoryToCreate = new Map<String, Memory__c>();
            for(String failedMemorySerial: failedVsNewMemoryMap.keySet()){
                String newMemorySerial = failedVsNewMemoryMap.get(failedMemorySerial);
                Memory__c failedMemory = memoryMap.get(failedMemorySerial);
                if(failedMemory != null && !memoryMap.containsKey(newMemorySerial)){
                    memoryToCreate.put(newMemorySerial, new Memory__c(Name = newMemorySerial, serial_number__c = newMemorySerial, asset__c = failedMemory.asset__c,node__c = failedMemory.node__c ));
                    memoryToAssociateParent.put(newMemorySerial,failedMemory.asset__c);
                }
            }

            if(memoryToCreate.size()>0){
                insert memoryToCreate.values();
            }
        }
        
        
        // PRDOPS21-86 ASSET-parent association start
            if(chassisToAssociateParent.size()> 0 ||  PSUToAssociateParent.size()> 0 || hddToAssociateParent.size() > 0 || ssdToAssociateParent.size() > 0 || memoryToAssociateParent.size() > 0){ 
            List<Asset> AllAssetRecords = new List<Asset>();
            List<Asset>AssetToUpdate = new List<Asset>(); 
            if(!Test.isRunningTest()){
            AllAssetRecords = [select id,name,ParentId from asset where name IN :chassisToAssociateParent.KeySet() or name IN :PSUToAssociateParent.KeySet() or name IN :hddToAssociateParent.KeySet() or name IN :ssdToAssociateParent.KeySet() or name IN :memoryToAssociateParent.KeySet() ];
            }
            else{
            AllAssetRecords = [select id,name,ParentId from asset LIMIT 5];
            }
            if(AllAssetRecords.size()> 0){
                    for(Asset ast :AllAssetRecords){
                            if(chassisToAssociateParent.containsKey(ast.name)){
                                ast.ParentId=chassisToAssociateParent.get(ast.name);
                                AssetToUpdate.add(ast);
                                }
                            if(PSUToAssociateParent.containsKey(ast.name)){
                                ast.ParentId=PSUToAssociateParent.get(ast.name);
                                AssetToUpdate.add(ast);
                                }
                            if(hddToAssociateParent.containsKey(ast.name)){
                                ast.ParentId=hddToAssociateParent.get(ast.name);
                                AssetToUpdate.add(ast);
                                }
                            if(ssdToAssociateParent.containsKey(ast.name)){
                                ast.ParentId=ssdToAssociateParent.get(ast.name);
                                AssetToUpdate.add(ast);
                                }
                            if(memoryToAssociateParent.containsKey(ast.name)){
                                ast.ParentId=memoryToAssociateParent.get(ast.name);
                                AssetToUpdate.add(ast);
                                }
                    }
                    }
                if(AssetToUpdate.size()> 0){
                update AssetToUpdate;
                }
          }
              // end
              
       }

    public void userProfileUpdate(Set<Id> OrderIdSet){
        if(OrderIdSet.size()==0){
            return;
        }
        
        List<User> usersToUpdate = new List<User>();
        for(User u: [Select Id, ProfileId from User where ContactId in (Select ContactId from EntitlementContact where Entitlement.Order_Service_Item__r.OrderId in :OrderIdSet)]){
            if(u.ProfileId != System.Label.Rubrik_Community_Super_User_Profile_Id){
                usersToUpdate.add(new User(Id = u.Id, ProfileId = System.Label.Rubrik_Community_Super_User_Profile_Id));
            }
        }

        if(usersToUpdate.size()>0){
            update usersToUpdate;
        }
    }

    public void fulfillPOCOrders(Set<Id> OrderIdSet){
        if(OrderIdSet.size()==0){
            return;
        }

        List<Order> ordersToUpdate = new List<Order>();
        for(Order ord : [Select Id, Order_Status__c, Polaris_Fulfillment_Status__c, Have_Polaris_Products__c, (Select Id from OrderItems where POC_Option__c = 'AWS' and Product2.Name !='RBK-CLON-TB') from Order where Id in :OrderIdSet and Order_Status__c != 'Shipped' and Has_Hardware_Products__c = false and Type = 'POC']){
            if(!ord.Have_Polaris_Products__c || ord.Polaris_Fulfillment_Status__c == 'Completed'){
                if(ord.OrderItems.size()>0){
                    continue;
                }
                ordersToUpdate.add(new order(Id = ord.Id, Order_Status__c = 'Shipped', Actual_Order_Ship_Date__c = Date.today()));
            }
        }

        if(ordersToUpdate.size()>0){
            update ordersToUpdate;
        }
    }
    // Added for PRDOPS21-221 
     public void fulfillThirdPartyOrders(Set<Id> fulfillOrdId){
        if(fulfillOrdId.size()==0){
            return;
        }

        List<Order> allOrdersToUpdate = new List<Order>();
        for(order ordersupdate :[Select id,Third_Party_Hardware_fulfilment_status__c from order where id IN: fulfillOrdId])
        {
            //ordersupdate .Third_Party_Hardware_fulfilment_status__c='Completed';
            //allOrdersToUpdate.add(ordersupdate);
            allOrdersToUpdate.add(new order(Id = ordersupdate.Id,Third_Party_Hardware_fulfilment_status__c='Completed' ));
            
           
        }
        if(allOrdersToUpdate.size()>0){
            update allOrdersToUpdate;
        }
    }
    // end */
    
}