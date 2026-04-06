<aura:application extends="force:slds">
	<aura:attribute name="StartDate" type="string"/>
    <c:PSTimeEntryComponent weekStartDate="{!v.StartDate}"/>
</aura:application>