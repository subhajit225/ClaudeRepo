import { LightningElement} from 'lwc';

export default class EntitlementReportsLWC extends LightningElement {
    
    activeTab = '1';
    /**
     * Handles the activation of a tab in the component.
     * @param {CustomEvent} event - The event object triggered by tab activation.
     * @param {string} event.target.value - The value of the activated tab.
     * @returns {void} This function does not return a value.
     */
    handleActive(event) {
        this.activeTab = event.target.value;
    }
    
    
}