/**
 * @author Sushant Arora
 * @date 2024-11-19
 * @description A helper class that implements the Comparable interface for comparing objects based on the 'value' field of type Decimal. 
 * The class is designed to allow sorting or ordering of objects that hold a key-value pair, where the key is a String and the value is a Decimal.
 * It overrides the compareTo method to compare the value between two instances of the class.
 */
public class CS_GenericValueCompareClass implements Comparable {
    public String key;
    public Decimal value;
    
    /**
     * @description Constructor to initialize the key and value for the object.
     * @param key A String key.
     * @param value A Decimal value.
     */
    public CS_GenericValueCompareClass(String key, Decimal value) {
        this.key = key;
        this.value = value;
    }
    
    /**
     * @description Compares this object with another object based on the 'value' field.
     * @param obj The object to be compared.
     * @return Integer A negative integer, zero, or a positive integer as this object is less than, equal to, or greater than the specified object.
     */
    public Integer compareTo(Object obj) {
        CS_GenericValueCompareClass other = (CS_GenericValueCompareClass)obj;
        
        if (this.value == other.value) {
            return 0;
        } else if (this.value < other.value) {
            return -1;
        } else {
            return 1;
        }
    }
}