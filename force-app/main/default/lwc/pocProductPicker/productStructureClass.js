//class for Page Product Structure
class ProductClass {
    
    productName;
    productFields; 
    isMultiple;  
    extraAccessories;
    instances;
    accessories;
    allowMultiProductDeletion;
    allowAccessoryDeletion;
    doesProductHaveFields;
    quantity;
    accessoryOptional;
    isAccordionOpen;
    accessoryAccMap;
    productAccMap;
    validPOCTypes = [];

    constructor( productName, productFields, isMultiple,  extraAccessories, validPOCTypes ) {
        this.productName = productName;
        this.productFields = productFields;
        this.isMultiple = isMultiple;
        this.extraAccessories = extraAccessories;
        this.accessories = [];
        this.instances = [];
        this.allowMultiProductDeletion = false;
        this.allowAccessoryDeletion = false;
        this.doesProductHaveFields = productFields.length > 0;
        this.quantity = 1;
        this.accessoryOptional = true;
        this.isAccordionOpen = true;
        this.productAccMap = {};
        this.accessoryAccMap = {};
        this.validPOCTypes = validPOCTypes.split(';');
        
        
        if( isMultiple ) {
            const instanceName = newInstanceId();
            this.instances.push(instanceName);
            this.productAccMap[instanceName] = false;
        }
    }
}

class ProductAttributes {
    productCategories;
    products;
    poc;
}

//@track decorator converts Class instance to Object. Hence declared outside of class and exported
const addNewInstance = (prodClassObject) => {
    const newInstanceIdS = newInstanceId();
    prodClassObject.instances.push(newInstanceIdS);
    prodClassObject.productAccMap[newInstanceIdS] = true;
    computeProductButtonVisibility(prodClassObject);
}

//@track decorator converts Class instance to Object. Hence declared outside of class and exported
const addNewSubInstance = ( prodClassObject) => {
    const newInstanceIdS = newInstanceId();
    prodClassObject.accessories.push(newInstanceIdS);
    prodClassObject.accessoryAccMap[newInstanceId] = true;
    computeAccessoryButtonVisibility(prodClassObject);
}

const computeProductButtonVisibility = (prodClassObject) => {
    prodClassObject.allowMultiProductDeletion = prodClassObject.instances.length > 1;
}

const computeAccessoryButtonVisibility = (prodClassObject) => {
    prodClassObject.allowAccessoryDeletion = true;
    computeAddAccessory(prodClassObject);
}

const computeAddAccessory = (prodClassObject) => {
    prodClassObject.accessoryOptional = prodClassObject.accessories.length === 0;
}

const newInstanceId = () => {
    return (new Date()).getTime().toString();
}

export {ProductClass, addNewInstance as addProduct, addNewSubInstance as addAccessory, computeAccessoryButtonVisibility as setAccessoryVisibility, computeProductButtonVisibility as setProductVisibility, computeAddAccessory as computeAddAccessoryBtn};