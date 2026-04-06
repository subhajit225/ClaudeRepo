import { gql } from 'lightning/uiGraphQLApi'

export default class RetentionCaseGraphQueries {

    getGraphQuery() {
        return gql`query getRiskProfile($recordId: ID) {
                    uiapi {
                        query {
                            ${this.getQuery()}
                        }
                        objectInfos(apiNames: ["Risk_Profile_Component__c", "Risk_Profile_Watcher__c"]) {
                            ApiName                            
                            createable
                            deletable
                            keyPrefix
                            label
                            updateable
                        }
                    }
                }`
    }

    getQuery() {
        return `Risk_Profile__c(where: { Id: { eq: $recordId } }) {
                    edges {
                        node {
                            Id
                            Name {
                                value
                            }
                            Risk_Origin__c {
                                value
                            }
                            Risk_Type__c {
                                value
                            }
                            Primary_Risk_Reason__c {
                                value
                            }
                            Opportunity__c {
                                value
                            }
                            Risk_Reason_Additional_Comments__c {
                                value
                            }                            
                            Comments__c {
                                value
                            }
                            Account__c {
                                value
                            }
                            Do_Not_Trigger__c {
                                value
                            }
                            DNT_Reason__c {
                                value
                            }
                            DNT_Snooze__c {
                                value
                            }
                            OwnerId {
                                value
                            }
                            CreatedById {
                                value
                            }

                            Entitlement__r {
                                Id
                                Name {
                                    value
                                }
                            }
                            Risk_Profile_Entitlements__r {
                                edges {
                                    node {
                                        Id
                                        Entitlement__r {
                                            Id
                                            Name {
                                                value
                                            }                                           
                                        }
                                    }
                                }
                            }
                            Risk_Profile_Components__r {
                                edges {
                                    node {
                                        Id
                                        Name {
                                            value
                                        }
                                        Bundle_Components_Allocation__r {
                                            Id
                                            Name {
                                                value
                                            }
                                            Product_SKU__c{
                                                value
                                            }
                                            Component_sku_Parsed__c{
                                                value
                                            }                                           
                                        }
                                        Entitlement__r {
                                            Id
                                            Name {
                                                value
                                            }
                                        }
                                    }
                                }
                            }
                            Risk_Profile_Watchers__r {
                                edges {
                                    node {
                                        Id
                                        Watcher__r {
                                            Id
                                            Name {
                                                value
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }`
    }
}