<aura:application extends="force:slds" controller="AssignTasksCmpController">
    <aura:attribute name="projectId" type="String" />
    <aura:attribute name="selectedLookUpRecords" type="List" default="[]" />
    <aura:attribute name="subTaskResults" type="List" default="[]" />
    <aura:attribute name="TotalsubTaskResults" type="List" default="[]" />
    <aura:attribute name="totalSubTaskIds" type="List" default="[]" />
    <aura:attribute name="data" type="List" default="[]" />
    <aura:attribute name="columns" type="List"/>
    <aura:attribute name="selection" type="List" />
    <aura:attribute name="Message" type="Boolean" default="false"/>
    <aura:attribute name="messageString" type="String"/>
    <aura:attribute name="isSuccess" type="Boolean"/>
    <aura:attribute name="selectedtaskId" type="String"/>
    <aura:attribute name="rowIndex" type="Integer"/>
    <aura:attribute name="prevrowIndex" type="Integer"/>
    <aura:attribute name="superSelectAll" type="Boolean"/>
    
    <aura:attribute name="sortedBy" type="String" default="Name"/>
	<aura:attribute name="sortedDirection" type="String" default="asc"/>


    <aura:handler name="init" action="{!c.doInit}" value="{!this}"/>

                    <aura:if isTrue="{!v.Message}">
                        <c:showPageMessages messageString="{!v.messageString}" isSuccess="{!v.isSuccess}"/>
                    </aura:if>
	
	<lightning:card title="">
        <lightning:layout multipleRows="true" horizontalAlign="center">
            <lightning:layoutItem padding="around-small" size="12">
                
                <c:ReusableMultiLookup objectAPIName="user"
                                       IconName="standard:user" lstSelectedRecords="{!v.selectedLookUpRecords}"
                                       label="Team Members" whereclause="isContactId=null"></c:ReusableMultiLookup>
            </lightning:layoutItem>
            <lightning:layoutItem padding="around-small" size="12">
                <ui:inputCheckbox value="{!v.superSelectAll}" label="Select ALL" change="{!c.handlesuperSelectAll}" />
			</lightning:layoutItem>
            <lightning:layoutItem padding="around-small" size="12">  
                                    <div class="container">
                        <table class="slds-table slds-table_bordered">
                            <thead>
                                <tr class="slds-text-title_caps">
                                    <th> Task Name <div class="slds-float--right " style="cursor: pointer;"   ></div></th>
                                </tr>    
                            </thead>
                            <tbody>
                                <aura:iteration items="{!v.data}" var="item" indexVar="indx">
                                    <tr>
                                        <td class="slds-size_2-of-12 slds-hyphenate"  style="cursor: pointer;"  data-recId="{!item.Id}" data-index="{!indx}" onclick="{! c.section }">
                                            <div class="slds-float--left ">
                                                <div class="{!indx}" style="display:block"><lightning:icon iconName="utility:chevronright" size="xx-small" alternativeText="Indicates add" /></div>
                                                <div class="{!indx}" style="display:none"><lightning:icon iconName="utility:chevrondown" size="xx-small" alternativeText="Indicates add" /></div>
                                            </div>&nbsp;{!item.TaskName}
                                        </td>
                                    </tr>  
                                    
                                    <aura:if isTrue="{!indx == v.rowIndex}">
                                         <table class="slds-table slds-table_bordered">
                                            <thead>
                                                <tr class="slds-text-title_caps">
                                                     <label class="slds-checkbox">
                                                        <ui:inputCheckbox value="{!item.selectAll}" change="{!c.handleSelectAllInner}" class="{!indx+'check'}" name="{!indx}"/>
                                                        <span class="slds-checkbox--faux" />
                                                        <span class="slds-form-element__label"></span>
                                                    </label>
                                                    <th> Sub Task Type <div class="slds-float--right " style="cursor: pointer;"   ></div></th>
                                                </tr>    
                                            </thead>
                                            <tbody>
                                                <aura:iteration items="{!v.subTaskResults}" var="sub" indexVar="innerindx">
                                    			<tr>
                                                    <td class="slds-size_2-of-12 slds-hyphenate"  style="cursor: pointer;" data-recId="{!sub.Id}">
                                                      <!-- <lightning:input type="checkbox" Checked="{!sub.Selected}" aura:id="{!indx+'-'+innerindx}" name="{!indx+'-'+innerindx}" onchange="{!c.handleSelect}"/> -->
                                                       <ui:inputCheckbox value="{!sub.Selected}"  change="{!c.handleSelect}" aura:id="checkId" name="{!indx+'-'+innerindx}"/>
                                                    </td>
                                                    <td class="slds-size_2-of-12 slds-hyphenate"  style="cursor: pointer;" >
                                                       {!sub.SubtaskType}
                                                    </td>
                                                </tr>  
                                                </aura:iteration>
                                             </tbody>
                                        </table>
                                    </aura:if>
                                </aura:iteration>
                            </tbody>
                        </table>
                        <br/>
                        <br/>
                        
                    </div>
            </lightning:layoutItem>
            
            <lightning:layoutItem padding="around-small" size="12">
                <lightning:button label="Assign Users to Subtask" class="slds-m-center_small slds-align--absolute-center"  onclick="{!c.makeSelection}"/>
                <lightning:button label="Cancel" class="slds-m-center_small slds-align--absolute-center"  onclick="{!c.cancel}"/>
            </lightning:layoutItem>
		</lightning:layout>
	</lightning:card>
</aura:application>