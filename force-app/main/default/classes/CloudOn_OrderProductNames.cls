public with sharing class CloudOn_OrderProductNames {
    
    public String productNames { get; set; }
    
    public ID ordid;
    
    public ID getordid(){ return ordid; }
    
    public void setordid(ID s){
        
        ordid = s;
        
        CloudOn_OrderProductNames();
        
    }
    
    
    public void CloudOn_OrderProductNames(){
        productNames = '';
        system.debug('-----ordid---'+ordid);
        for(orderitem item: [select product2.Name from orderitem where orderid=:ordid and product2.Family = 'CLON']){
            productNames += item.product2.Name+',';
            
        }
        productNames = productNames.removeEnd(',');
        
    }
    
    
}