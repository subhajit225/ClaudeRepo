({
	checkSurveyInvitationAccess : function(component) {
		var action = component.get("c.isInvitationCreationAllowed");

        action.setCallback(this, function(response) {
        	var hasCreateAccess = response.getReturnValue();
            console.log("hasCreateAccess",hasCreateAccess);
            component.set("v.hasCreateAccess", hasCreateAccess);
            if(!hasCreateAccess) {
                this.setAccessErrorMessage(component);
            }
            else {
                this.checkAccount(component);
            }
        });

        $A.enqueueAction(action);
	},
    setAccessErrorMessage : function(component) {
        var message = $A.get("$Label.c.Survey_Invitation_Error_Message");
        var variant = "error";
        var header = "Insufficient Privileges";
        this.showMessage(component, message, variant, header);
    },
    setColumns : function(component) {
        var tableColumns = ['Name', 'Email', 'Last Survey Sent Date', 'Disable reason'];
		component.set("v.tableColumns", tableColumns);
    },
    showMessage : function(component, message, variant, header) {
        component.set("v.showSpinner", false);
		var recId = component.get("v.psProjectId");
        var theme = component.get("v.UITheme");
        component.find('messagePanel').showNotice({
            "variant": variant,
            "header": header,
            "message": message,
            closeCallback: function() {
                //Write code to go back to PS project
                if(theme == 'Theme4d'){
                    window.location.href="/"+recId;
                }else{
                    window.close();
                }
            }
        });
    },
    checkAccount : function(component) {
        var action = component.get("c.getPSProjectRecord");

        action.setParams({
            psProjectId : component.get("v.psProjectId")
        });

        action.setCallback(this, function(response) {
        	var psProjectRecord = response.getReturnValue();
            component.set("v.accountId", psProjectRecord.Account__c);
            console.log("psProjectRecord==",psProjectRecord);
            if(psProjectRecord.Account__c == null) {
                this.setBlankAccountErrorMessage(component);
            }
            else {
                //component.find("accountName").set("v.value", psProjectRecord.Account__r.Name);
                //component.find("psProjectName").set("v.value", psProjectRecord.Name);
                this.fetchContacts(component);
            }
        });

        $A.enqueueAction(action);
    },
    setBlankAccountErrorMessage : function(component) {
    	var message = $A.get("$Label.c.Blank_Account_error_message");
        var variant = "error";
        var header = "Account is empty";
        this.showMessage(component, message, variant, header);
	},
    fetchContacts : function(component) {
        var action = component.get("c.getContacts");

        action.setParams({
            accountId : component.get("v.accountId")
        });

        action.setCallback(this, function(response) {
            var contacts = response.getReturnValue();

            if(contacts.length > 0) {
                this.filterContacts(component, contacts);
                //this.setColumns(component);
                this.prepareForPagination(component);
                component.set("v.showSpinner", false);
            }
            else {
                this.setNoContactMessage(component);
            }
        });

        $A.enqueueAction(action);
    },
    filterContacts : function(component, contacts) {
        var contactsLength = contacts.length;
        var allContacts = [];
        var isRowDisabled = false;
        var disableReason = '';
        var lastSurveySentDate;

        for(var i = 0; i < contactsLength; i++) {
            isRowDisabled = false;
            disableReason = '';
            lastSurveySentDate = '';

            if(contacts[i].Email == null || contacts[i].Email == "") {
                isRowDisabled = true;
                disableReason = $A.get("$Label.c.No_Email_on_Contacts_Message");
            }

            else if(contacts[i].Last_Survey_Sent_Date_Time__c != null) {

                lastSurveySentDate = new Date(contacts[i].Last_Survey_Sent_Date_Time__c).toLocaleDateString(undefined, {
                    day : 'numeric',
                    month : 'long',
                    year : 'numeric'
                }) + " " + new Date(contacts[i].Last_Survey_Sent_Date_Time__c).toLocaleTimeString();

                var daysDifference = 0;
                var currentTime = new Date();
                var lastSurveySentDateTime = Date.parse(contacts[i].Last_Survey_Sent_Date_Time__c);
                var daysDifference = (currentTime - lastSurveySentDateTime) / (1000 * 3600 * 24);

                if(daysDifference < 7) {
                    isRowDisabled = true;
                    disableReason = $A.get("$Label.c.Last_Survey_Sent_Date_within_7_days");
                }
            }

            allContacts.push({
                id : contacts[i].Id,
                name : contacts[i].Name,
                email : contacts[i].Email,
                accountId : contacts[i].AccountId,
                lastSurveySentDate : lastSurveySentDate,/*(contacts[i].Last_Survey_Sent_Date_Time__c != null ? new Date(contacts[i].Last_Survey_Sent_Date_Time__c) : null),*/
                isRowDisabled : isRowDisabled,
                disableReason : disableReason,
                isSelected : false
            });
        }
        component.set("v.allContactsList", allContacts);
    },
    setNoContactMessage : function(component) {
    	var message = $A.get("$Label.c.No_contacts_message");
        var variant = "warning";
        var header = "No Contacts";
        this.showMessage(component, message, variant, header);
	},
    prepareForPagination : function(component) {
        var contactsLength = component.get("v.allContactsList").length;
        component.set("v.allContactsLength", contactsLength);

        var pageLimit = parseInt($A.get("$Label.c.Survey_Page_Contacts_Limit"));
        component.set("v.pageLimit", pageLimit);

        var totalPages = Math.ceil(contactsLength/pageLimit);
        component.set("v.totalPages", totalPages);

        var headerCheckboxArray = Array(totalPages).fill(false);
        component.set("v.headerCheckboxArray", headerCheckboxArray);

        this.getContactsForCurrentPage(component);
    },
    sendSurvey : function(component) {
        var action = component.get("c.sendSurveyInvitations");

        action.setParams({
            contactList : component.get("v.selectedContactsList"),
            selectedSurvey : component.get("v.selectedSurvey"),
            psProjectId : component.get("v.psProjectId")
        });

        action.setCallback(this, function(response) {
        	console.log("inside send survey callback");
            var message = response.getReturnValue();
            var variant = "info";
            var header = "Sucess";

            if(message.startsWith('The following error has occurred')) {
                var variant = "error";
                var header = "Error";
            } else if(message.includes('The following error has occurred')) {
                var header = "Success with error";
            } else {
                //Do nothing
            }
            this.showMessage(component, message, variant, header);
        });

        $A.enqueueAction(action);
    },
    getContactsForCurrentPage : function(component) {
        var endIndex = 0;
        var contactsList = [];
        var allContacts = component.get("v.allContactsList");
        var pageLimit = component.get("v.pageLimit");
        var currentPage = component.get("v.currentPage");
        var contactsLength = component.get("v.allContactsLength");

        var startIndex = (currentPage - 1) * pageLimit;
        var tempEndIndex = startIndex + pageLimit;

        endIndex = contactsLength <= tempEndIndex ? contactsLength : tempEndIndex;

        for(var i = startIndex; i < endIndex; i++) {
            contactsList.push(allContacts[i]);
        }
        component.set("v.contactsList", contactsList);

        this.setHeaderCheckboxValueOnPageChange(component);
        this.setHeaderCheckboxDisabled(component);
    },
    setHeaderCheckboxValueOnPageChange : function(component) {
        var currentPage = component.get("v.currentPage");
        component.set("v.headerCheckboxValueForCurrentPage", component.get("v.headerCheckboxArray")[currentPage - 1]);
    },
    setHeaderCheckboxDisabled : function(component) {
        var contactsList = component.get("v.contactsList");
        var contactListLength = contactsList.length;
        var isHeaderDisabled = true;

        for(var i = 0; i < contactListLength; i++) {
            if(!contactsList[i].isRowDisabled) {
                isHeaderDisabled = false;
                break;
            }
        }
        component.set("v.isHeaderCheckboxDisabled", isHeaderDisabled);
    },
    setHeaderCheckboxValueOnHeaderChange : function(component, isSelected) {
        var headerCheckboxArray = component.get("v.headerCheckboxArray");
        var currentPage = component.get("v.currentPage");
        headerCheckboxArray[currentPage - 1] = isSelected;
        component.set("v.headerCheckboxArray", headerCheckboxArray);
    },
    setHeaderCheckboxValueOnRowChange : function(component, isSelected) {
        var isHeaderSelected = true;

        if(isSelected) {
            var contactsList = component.get("v.contactsList");
            var contactsListLength = contactsList.length;

            for(var i = 0; i < contactsListLength; i++) {
                if(!contactsList[i].isRowDisabled && !contactsList[i].isSelected) {
                    isHeaderSelected = false;
                    break;
                }
            }
        }
        else {
            isHeaderSelected = false;
        }

        var headerCheckboxArray = component.get("v.headerCheckboxArray");
        var currentPage = component.get("v.currentPage");
        headerCheckboxArray[currentPage - 1] = isHeaderSelected;
        component.set("v.headerCheckboxArray", headerCheckboxArray);
        component.set("v.headerCheckboxValueForCurrentPage", headerCheckboxArray[currentPage - 1]);
    },
    updateCurrentPageContactsList : function(component, isSelected) {
        var currentPageContacts = component.get("v.contactsList");
        var currentPageContactsLength  = currentPageContacts.length;

        for(var i = 0; i < currentPageContactsLength; i++) {
            if(!currentPageContacts[i].isRowDisabled) {
                currentPageContacts[i].isSelected = isSelected;
            }
        }

        component.set("v.contactsList", currentPageContacts);
    },
    updateAllContactsList : function(component, isSelected) {
        var endIndex = 0;
        var allContacts = component.get("v.allContactsList");
        var allContactsLength  = allContacts.length;
        var currentPage = component.get("v.currentPage");
        var pageLimit = component.get("v.pageLimit");
        var startIndex = (currentPage - 1) * pageLimit;
        var tempEndIndex = startIndex + pageLimit;

        endIndex = allContactsLength <= tempEndIndex ? allContactsLength : tempEndIndex;

        for(var i = startIndex; i < endIndex; i++) {
            if(!allContacts[i].isRowDisabled) {
                allContacts[i].isSelected = isSelected;
            }
        }

        component.set("v.allContactsList", allContacts);
    },
    prepareSelectedContactsList : function(component) {
        var allContactsList = component.get("v.allContactsList");
        var allContactsLength = allContactsList.length;
        var selectedContactsList = [];

        for(var i = 0; i < allContactsLength; i++) {
            if(!allContactsList[i].isRowDisabled && allContactsList[i].isSelected) {
                selectedContactsList.push({
                    Id : allContactsList[i].id,
                    Name : allContactsList[i].name,
                    Email : allContactsList[i].email,
                    AccountId : allContactsList[i].accountId
                });
            }
        }
        component.set("v.selectedContactsList", selectedContactsList);
    },
    isAtleastOneRowSelected : function(component, isSelected) {
        component.set("v.isAtleastOneRowSelected", false);

        if(isSelected) {
            component.set("v.isAtleastOneRowSelected", true);
        }
        else {
            var allContactsList = component.get("v.allContactsList");
            var allContactsLength = allContactsList.length;

            for(var i = 0; i < allContactsLength; i++) {
                if(!allContactsList[i].isRowDisabled && allContactsList[i].isSelected) {
                    component.set("v.isAtleastOneRowSelected", true);
                    break;
                }
            }
        }
    },
    gotoRecord : function (component, recId) {
        if(component.get("v.UITheme") == 'Theme4d'){
            window.location.href="/"+recId;
        }else{
        	window.close();
        }
        
    },
    getUItheme : function (component, event, helper) {
    	var action = component.get("c.getUIThemeDescription");
        action.setCallback(this, function(a) {
            component.set("v.UITheme", a.getReturnValue());
        });
        $A.enqueueAction(action);
    }
})