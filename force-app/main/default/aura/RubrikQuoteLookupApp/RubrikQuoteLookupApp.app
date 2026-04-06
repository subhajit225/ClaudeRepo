<!-- Lightning Out app — bridges Visualforce to the rubrikQuoteLookup LWC via Aura wrapper.
     Uses ltng:outAppUnsafe for guest/unauthenticated Force.com Site access. -->
<aura:application access="GLOBAL" extends="ltng:outAppUnsafe">
    <aura:dependency resource="c:rubrikQuoteLookupWrapper"/>
    <aura:dependency resource="c:rubrikQuoteLookup"/>
</aura:application>
