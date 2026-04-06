import { LightningElement } from 'lwc';
import getDataByObject from '@salesforce/apex/su_vf_console.AgentHelper.getDataByObject';
export default class SU_AiqDataRepository extends LightningElement { }

let objectFieldsMap = {
    'case': {
        sObject: 'Case',
        fields: {
            Id: 'Id',
            CaseNumber: 'CaseNumber',
            CreatedDate: 'CreatedDate',
            Description: 'Description',
            Subject: 'Subject',
            Priority: 'Priority',
            Status: 'Status',
            ContactEmail: 'ContactEmail',
            CreatedById: 'CreatedById',
            ContactId: 'ContactId',
            OwnerId: 'OwnerId',
            LastModifiedDate: 'LastModifiedDate',
            ClosedDate: 'ClosedDate',
            IsClosed: 'IsClosed',
            JiraIds: 'JIRA_References_URL__c'
        }
    },
    'feedComments': {
        sObject: 'CaseFeed',
        fields: {
            Id: 'Id',
            Body: 'Body',
            CommentCount: 'CommentCount',
            CreatedDate: 'CreatedDate',
            ParentId: 'ParentId',
            CreatedById: 'CreatedById',
            Type: 'Type',
            LastModifiedDate: 'LastModifiedDate'
        }
    },
    'caseComments': {
        sObject: 'CaseComment',
        fields: {
            Id: 'Id',
            CommentBody: 'CommentBody',
            CreatedDate: 'CreatedDate',
            IsDeleted: 'IsDeleted',
            IsPublished: 'IsPublished',
            ParentId: 'ParentId',
            CreatedById: 'CreatedById',
            LastModifiedDate: 'LastModifiedDate'
        }
    },
    'caseAgentHistory': {
        sObject: 'CaseHistory',
        fields: {
            NewValue: 'NewValue',
            OldValue: 'OldValue',
            CaseId: 'CaseId',
            CreatedDate: 'CreatedDate',
            DataType: 'DataType',
            Field: 'Field',
            Id: 'Id',
            IsDeleted: 'IsDeleted',
            CreatedById: 'CreatedById'
        }
    },
    'caseStatusHistory': {
        sObject: 'CaseHistory',
        fields: {
            NewValue: 'NewValue',
            OldValue: 'OldValue',
            CaseId: 'CaseId',
            CreatedDate: 'CreatedDate',
            DataType: 'DataType',
            Field: 'Field',
            Id: 'Id',
            IsDeleted: 'IsDeleted',
            CreatedById: 'CreatedById'
        }
    },
    'user': {
        sObject: 'User',
        fields: {
            Id: 'Id',
            Name: 'Name',
            FirstName: 'FirstName',
            Email: 'su_vf_console__UserEmail__c',
            UserType: 'su_vf_console__UserUserType__c',
            Title: 'Title',
            Department: 'Department',
            FullPhotoUrl:'FullPhotoUrl',
            IsActive: 'IsActive',
            TimeZoneSidKey: 'TimeZoneSidKey'
        }
    },
    'contact': {
        sObject: 'Contact',
        fields: {
            Id: 'Id',
            Name: 'Name',
            FirstName: 'FirstName',
            Email: 'Email',
            Title: 'Title',
            Department: 'Department'
        }
    },
    'group': {
        sObject: 'Group',
        fields: {
            Id: 'Id',
            Name: 'Name',
            Email: 'Email',
            Type: 'Type'
        }
    },
    'knowledgeArticleVersion': {
        sObject: 'how_to__kav',
        fields: {
            Id: 'Id',
            knowledgearticleid: 'knowledgearticleid',
            OwnerId: 'OwnerId',
            Title: 'Title',
            CreatedDate: 'CreatedDate',
            LastModifiedDate: 'LastModifiedDate'
        }
    },
    'threadComments': {
        sObject: 'FeedComment',
        fields: {
            Id: 'Id',
            CommentBody: 'CommentBody',
            CreatedDate: 'CreatedDate',
            ParentId: 'ParentId',
            CreatedById: 'CreatedById',
            FeedItemId: 'FeedItemId',
            IsDeleted: 'IsDeleted',
            LastModifiedDate: 'LastEditDate'
        }
    },
    'emailMessage': {
        sObject: 'EmailMessage',
        fields: {
            Id: 'Id',
            TextBody: 'TextBody',
            CreatedDate: 'CreatedDate',
            ParentId: 'ParentId',
            CreatedById: 'CreatedById',
            IsDeleted: 'IsDeleted',
            LastModifiedDate: 'LastModifiedDate',
            HtmlBody: 'HtmlBody',
            FromAddress: 'FromAddress',
            FromName: 'FromName',
            Incoming: 'Incoming'
        }
    }


};

function fetchTimelineData(caseId, commentsLimit = null) {
    return new Promise((resolve, reject) => {
        if (!caseId) {
            return reject(responseDto(false, "Case Id is required!!"));
        }
        let timelineData = {};
        return fetchCaseFeedData(caseId).then((caseFeedData)=>{
            return Promise.all([
                fetchCaseData(caseId),
                fetchCaseComments(caseId, commentsLimit),
                fetchCaseFeed(caseId, commentsLimit),
                fetchFeedComments(caseId, commentsLimit, caseFeedData).catch((error)=>{
                    console.log('<---- error occured fetching CaseFeedComment for Case Timeline continuing without it ---> ', error);
                    return [];
                }),
                fetchEmailComments(caseId, commentsLimit)
            ])
            .then(([caseData, comments, feed, threadComments, emailComments]) => {
                return Promise.all([
                    fetchCaseAgentsHistory(caseId, caseData?.ownerId, caseData?.createdDate),
                    fetchCaseStatusHistory(caseId, caseData?.status, caseData?.createdDate),
                    Promise.resolve({ caseData, comments, feed, threadComments, emailComments })
                ]);
            })
            .then(([agentsHistoryData, statusHistoryData, { caseData, comments, feed, threadComments, emailComments }]) => {
                // Rubrik customization to remove email comments 
                // let combinedData = [...comments, ...feed, ...threadComments, ...emailComments].sort((a, b) => new Date(a.ts) - new Date(b.ts));
                let combinedData = [...comments, ...feed, ...threadComments].sort((a, b) => new Date(a.ts) - new Date(b.ts));
                if (commentsLimit && combinedData.length > commentsLimit) {
                    combinedData.splice(0, combinedData.length - commentsLimit);
                }
                let uniqueUserIds = [
                    caseData?.ownerId,
                    caseData?.createdById,
                    caseData?.contactId,
                    ...combinedData.map((item) => item.createdById)
                ];
                if (agentsHistoryData.hasAccess) {
                    uniqueUserIds = [...uniqueUserIds, ...agentsHistoryData.agents.map((item) => item.Id),]
                }

                uniqueUserIds = [...new Set(uniqueUserIds)].filter((id) => id !== null && id !== undefined);

                return usersDataFactory(uniqueUserIds).then((usersData) => {
                    caseData = updateCaseDetails(caseData, usersData);

                    let caseCreateActivity = getCaseCreateActivity(caseData);
                    timelineData.activities = [caseCreateActivity, ...combinedData];
                    timelineData.activities = addActorDetails(timelineData.activities, usersData);
                    if (agentsHistoryData.hasAccess) {
                        timelineData.agents = addAgentDetails(agentsHistoryData.agents, usersData);
                    }
                    if (statusHistoryData.hasAccess) {
                        timelineData.statusHistory = statusHistoryData.statusHistory;
                    }
                    timelineData = {
                        caseId: caseId,
                        agentsHistoryAvailable: agentsHistoryData.hasAccess,
                        ...caseData,
                        customer_name: caseCreateActivity.contactName,
                        ...timelineData
                    };
                    return resolve(
                        responseDto(true, "Data fetched Successfully", timelineData)
                    );
                });
            })
            .catch((error) => {
                console.log("--fetchTimelineData-- Something went wrong:", error);
                return reject(
                    responseDto(false, "Error fetching timeline data!!", null, error)
                );
            });
        }).catch((error)=>{
            console.log('<---- error occured fetching CaseFeedData ---> ', error);
        })
    });
}

function fetchResponseAssistData(caseId, commentsLimit = null) {
    return new Promise((resolve, reject) => {
        if (!caseId) {
            return reject(responseDto(false, "Case Id is required!!"));
        }
        let responseAssistData = {};
        return Promise.all([
            fetchCaseData(caseId),
            fetchCaseComments(caseId, commentsLimit),
            fetchCaseFeed(caseId, commentsLimit),
            fetchFeedComments(caseId, commentsLimit).catch((error)=>{
                console.log('<---- error occured fetching CaseFeedComment for Resposne Assist continuing without it ---> ', error);
                return [];
            })
        ])
            .then(([caseData, comments, feed, threadComments]) => {
                let combinedData = [...comments, ...feed, ...threadComments].sort((a, b) => new Date(a.ts) - new Date(b.ts));
                if (commentsLimit && combinedData.length > commentsLimit) {
                    combinedData.splice(0, combinedData.length - commentsLimit);
                }

                let uniqueUserIds = [
                    caseData.ownerId,
                    caseData.createdById,
                    caseData.contactId,
                    ...combinedData.map((item) => item.createdById)
                ];
                uniqueUserIds = [...new Set(uniqueUserIds)].filter((id) => id !== null && id !== undefined);

                return usersDataFactory(uniqueUserIds).then((usersData) => {
                    caseData = updateCaseDetails(caseData, usersData);

                    let caseCreateActivity = getCaseCreateActivity(caseData);
                    responseAssistData.activities = [caseCreateActivity, ...combinedData];
                    responseAssistData.activities = addActorDetails(responseAssistData.activities, usersData);
                    responseAssistData = {
                        caseId: caseId,
                        ...caseData,
                        customer_name: caseCreateActivity.contactName,
                        ...responseAssistData
                    };
                    return resolve(
                        responseDto(true, "Data fetched Successfully", responseAssistData)
                    );
                });
            })
            .catch((error) => {
                console.log("--fetchResponseAssistData-- Something went wrong:", error);
                return reject(
                    responseDto(false, "Error fetching ResponseAssist data!!", null, error)
                );
            });
    });
}

function fetchCaseSummaryData(caseId, commentsLimit = null) {
    return new Promise((resolve, reject) => {
        if (!caseId) {
            return reject(responseDto(false, "Case Id is required!!"));
        }
        let caseSummaryData = {};

        return Promise.all([
            fetchCaseData(caseId),
            fetchCaseComments(caseId, commentsLimit),
            fetchCaseFeed(caseId, commentsLimit),
            fetchFeedComments(caseId, commentsLimit).catch((error)=>{
                console.log('<---- error occured fetching CaseFeedComment for Case Summary continuing without it ---> ', error);
                return [];
            })
        ])
            .then(([caseData, comments, feed, threadComments]) => {
                let combinedData = [...comments, ...feed, ...threadComments].sort((a, b) => new Date(a.ts) - new Date(b.ts));
                if (commentsLimit && combinedData.length > commentsLimit) {
                    combinedData.splice(0, combinedData.length - commentsLimit);
                }
                let uniqueUserIds = [
                    caseData.ownerId,
                    caseData.createdById,
                    caseData.contactId,
                    ...combinedData.map((item) => item.createdById)
                ];
                uniqueUserIds = [...new Set(uniqueUserIds)].filter((id) => id !== null && id !== undefined);

                return usersDataFactory(uniqueUserIds).then((usersData) => {
                    caseData = updateCaseDetails(caseData, usersData);

                    caseSummaryData.comments = addActorDetails(combinedData, usersData);
                    caseSummaryData = {
                        Id: caseId,
                        ...caseData,
                        ...caseSummaryData
                    };
                    return resolve(
                        responseDto(true, "Data fetched Successfully", caseSummaryData)
                    );
                });
            })
            .catch((error) => {
                console.log("--fetchCaseSummaryData-- Something went wrong:", error);
                return reject(
                    responseDto(false, "Error fetching CaseSummary data!!", null, error)
                );
            });
    });
}

function fetchKnowledgeArticles(articleIds) {
    return new Promise((resolve, reject) => {
        // Define fields to fetch
        let fieldsToFetch = ['Id', 'knowledgearticleid', 'OwnerId', 'Title', 'CreatedDate', 'LastModifiedDate'];
        
        // Define the where clause
        let whereClause = {
            "and": [
                {
                    "operator": "in",
                    "key": "Id",
                    "value": articleIds
                },
                {
                    "operator": "equals",
                    "key": "PublishStatus",
                    "value": "Online"
                }
            ]
        };

        let fieldsMapObj = objectFieldsMap.knowledgeArticleVersion;
        let sObjectName = fieldsMapObj.sObject;
        ({ fieldsToFetch, whereClause } = convertFieldNames(fieldsMapObj, fieldsToFetch, whereClause));

        getDataByObject({
            sObjectName,
            fieldsToFetch,
            whereClause: JSON.stringify(whereClause),
            orderBy: '',
            recordsLimit: null
        })
        .then(result => {
            return convertBackFieldsName(JSON.parse(result[sObjectName]), fieldsMapObj.fields);
        })
        .then((articlesData) => {
            // Extract owner IDs
            let ownerIds = articlesData.map(article => article.OwnerId);

            // Fetch user data
            return usersDataFactory(ownerIds).then(userData => {
                resolve({
                    articles: articlesData,
                    users: userData
                });
            });
        })
        .catch(error => {
            console.error('--fetchKnowledgeArticles-- Error fetching knowledge article versions:', error);
            reject('--fetchKnowledgeArticles-- Error fetching knowledge article versions: ' + error);
        });
    });
}

function fetchSentimentData(caseId, commentsLimit = null) {
    return new Promise((resolve, reject) => {
        if (!caseId) {
            return reject(responseDto(false, "Case Id is required!!"));
        }
        let caseSummaryData = {};

        return Promise.all([
            fetchCaseData(caseId),
            fetchCaseComments(caseId),
            fetchCaseFeed(caseId),
            fetchFeedComments(caseId).catch((error)=>{
                console.log('<---- error occured fetching CaseFeedComment for Case Sentiment continuing without it ---> ', error);
                return [];
            })
        ])
            .then(([caseData, caseComments, feed, threadComments]) => {
                let combinedData = [...caseComments, ...feed, ...threadComments].sort((a, b) => new Date(a.lastModifiedDate) - new Date(b.lastModifiedDate));
                let uniqueUserIds = [
                    caseData.ownerId,
                    caseData.createdById,
                    caseData.contactId,
                    ...combinedData.map((item) => item.createdById)
                ];
                uniqueUserIds = [...new Set(uniqueUserIds)].filter((id) => id !== null && id !== undefined);

                return usersDataFactory(uniqueUserIds).then((usersData) => {
                    let comments = addActorDetails(combinedData, usersData);
                    comments = comments.filter((comment)=> comment.actorType === 'user');
                    if (commentsLimit && comments.length > commentsLimit) {
                        comments.splice(0, comments.length - commentsLimit);
                    }
                    caseSummaryData = {
                        Id: caseId,
                        description: caseData.description,
                        subject: caseData.subject,
                        comments 
                    };
                    return resolve(
                        responseDto(true, "Data fetched Successfully", caseSummaryData)
                    );
                });
            })
            .catch((error) => {
                console.log("--fetchCaseSummaryData-- Something went wrong:", error);
                return reject(
                    responseDto(false, "Error fetching CaseSummary data!!", null, error)
                );
            });
    });
}

function convertBackFieldsName(data, mapObject) {
    let reverseObjMap = {};
    for (let key in mapObject) {
        if (Object.prototype.hasOwnProperty.call(mapObject, key)) {
            reverseObjMap[mapObject[key]] = key;
        }
    }
    return data.map(record => {
        let temp = {};
        Object.keys(record).forEach((key) => {
            if (reverseObjMap[key]) {
                temp[reverseObjMap[key]] = record[key];
            } else {
                temp[key] = record[key];
            }
        })
        return temp;
    })
}

function convertFieldNames(fieldsMap, fieldsToFetch, whereClause={}, orderBy={}){
    fieldsToFetch = fieldsToFetch.map(key => {
        if(fieldsMap && fieldsMap.fields[key]){
            return fieldsMap.fields[key];
        }
        return key;
    });
    whereClause = replaceKeysInJson(whereClause, fieldsMap);
    orderBy = replaceKeysInJson(orderBy, fieldsMap);

    return { fieldsToFetch, whereClause, orderBy };
}
function replaceKeysInJson(jsonObj, mapObject) {
    function replaceKeys(obj) {
        for (let key in obj) {
            if (key === 'key' && mapObject.fields[obj[key]]) {
                obj[key] = mapObject.fields[obj[key]];
            } else if (typeof obj[key] === 'object' && obj[key] !== null) {
                if (Array.isArray(obj[key])) {
                    obj[key].forEach(item => replaceKeys(item));
                } else {
                    replaceKeys(obj[key]);
                }
            }
        }
    }

    replaceKeys(jsonObj);
    return jsonObj;
}

function fetchCaseData(caseId) {
    return new Promise((resolve, reject) => {
        let fieldsToFetch = ['Id', 'CaseNumber', 'CreatedDate', 'ClosedDate', 'Description', 'Subject', 'Priority', 'Status', 'ContactEmail', 'CreatedById', 'ContactId', 'OwnerId', 'LastModifiedDate', 'JiraIds'];
        let whereClause = {
            "operator": "equals",
            "key": "Id",
            "value": `${caseId}`
        }

        let fieldsMap = objectFieldsMap.case;
        let sObjectName = fieldsMap.sObject;
        ({ fieldsToFetch, whereClause } = convertFieldNames(fieldsMap, fieldsToFetch, whereClause));
        getDataByObject({
            sObjectName,
            fieldsToFetch,
            whereClause: JSON.stringify(whereClause),
            orderBy: '',
            recordsLimit: null })
            .then(result => {
                return convertBackFieldsName(JSON.parse(result[sObjectName]), fieldsMap.fields)
            })
            .then(result => {
                try{
                    let caseData = result[0];
                    let caseObj = {}
                    caseObj.caseNumber = caseData.CaseNumber;
                    caseObj.createdDate = caseData.CreatedDate;
                    caseObj.closedDate = caseData.ClosedDate;
                    caseObj.description = caseData.Description;
                    caseObj.subject = caseData.Subject;
                    caseObj.priority = caseData.Priority;
                    caseObj.status = caseData.Status;
                    caseObj.contactId = caseData.ContactId;
                    caseObj.createdById = caseData.CreatedById;
                    caseObj.ownerId = caseData.OwnerId;
                    caseObj.contactEmail = caseData.ContactEmail;
                    caseObj.lastModifiedDate = caseData.LastModifiedDate;
                    caseObj.jiraIds = caseData.JiraIds;
                    caseObj.ownerName = '';
                    caseObj.ownerEmail = '';
                    caseObj.contactName = '';
                    resolve(caseObj);
                }catch(err){
                    console.error('--fetchCaseData-- Error fetching case Data:', err);
                    reject('--fetchCaseData-- Error fetching case Data:' + err);
                }
            })
            .catch(error => {
                console.error('--fetchCaseData-- Error fetching case Data:', error);
                reject('--fetchCaseData-- Error fetching case Data:' + error);
            });
    });
}

function updateCaseDetails(caseData, usersData) {
    try {
        if (usersData[caseData.ownerId]) {
            caseData.ownerName = usersData[caseData.ownerId].Name;
            caseData.ownerEmail = usersData[caseData.ownerId].Email;
        }
        if (usersData[caseData.contactId]) {
            caseData.contactName = usersData[caseData.contactId].Name;
        }
        caseData.ownerTitle = usersData[caseData.ownerId].Title;
        caseData.ownerDepartment = usersData[caseData.ownerId].Department;
        return caseData;
    } catch (error) {
        console.error('Error updating owner name:', error);
        throw new Error('Error updating case details:' + error);
    }
}

function getCaseCreateActivity(caseInfo) {
    try {
        return {
            id: caseInfo.caseNumber,
            ts: caseInfo.createdDate,
            type: 'caseCreate',
            ...caseInfo
        };
    } catch (error) {
        console.error('Error in getCaseCreateActivity:', error);
        throw new Error('Error in getCaseCreateActivity: ' + error.message);
    }
}

async function usersDataFactory(userIds) {
    try {
        const userIdsToFetch = userIds.filter(id => id.startsWith('005'));
        const contactIdsToFetch = userIds.filter(id => id.startsWith('003'));
        const groupIdsToFetch = userIds.filter(id => id.startsWith('00G'));

        const [usersMap, contactsMap, groupsMap] = await Promise.all([
            fetchUsersData(userIdsToFetch),
            fetchContactsData(contactIdsToFetch),
            fetchGroupData(groupIdsToFetch)
        ]);

        return { ...usersMap, ...contactsMap, ...groupsMap };
    } catch (error) {
        console.error('Error fetching user or contact data:', error);
        throw error;
    }
}

function fetchUsersData(userIds) {
    return new Promise((resolve, reject) => {
        if (userIds && userIds.length) {
            let fieldsToFetch = ['Id', 'Name', 'FirstName', 'Email', 'UserType', 'Title', 'Department', 'FullPhotoUrl', 'IsActive', 'TimeZoneSidKey'];
            let whereClause = {
                "operator": "in",
                "key": "Id",
                "value": userIds
            };

            let fieldsMapObj = objectFieldsMap.user;
            let sObjectName = fieldsMapObj.sObject;
            ({ fieldsToFetch, whereClause } = convertFieldNames(fieldsMapObj, fieldsToFetch, whereClause));

            getDataByObject({
                sObjectName,
                fieldsToFetch,
                whereClause: JSON.stringify(whereClause),
                orderBy: '',
                recordsLimit: null 
                })
                .then(result => {
                    return convertBackFieldsName(JSON.parse(result[sObjectName]), fieldsMapObj.fields)
                })
                .then(usersData => {
                    let usersMap = {};
                    usersData.forEach(user => {
                        const { Id, Name, FirstName, Email, UserType, Title, Department, FullPhotoUrl, IsActive, TimeZoneSidKey } = user;
                        usersMap[Id] = {
                            Id,
                            Name,
                            FirstName,
                            Email,
                            Title,
                            Department,
                            actorType: getActorType(UserType),
                            FullPhotoUrl, 
                            IsActive,
                            TimeZoneSidKey
                        };
                    });
                    resolve(usersMap);
                })
                .catch(error => {
                    console.error('--fetchUsersData-- Error fetching user data:', error);
                    reject(error);
                });
        } else {
            resolve({});
        }
    });
}

function fetchGroupData(groupIds) {
    return new Promise((resolve, reject) => {
        if (groupIds && groupIds.length) {
            let fieldsToFetch = ['Id', 'Name', 'Email', 'Type'];
            let whereClause = {
                "operator": "in",
                "key": "Id",
                "value": groupIds
            };

            let fieldsMapObj = objectFieldsMap.group;
            let sObjectName = fieldsMapObj.sObject;
            ({ fieldsToFetch, whereClause } = convertFieldNames(fieldsMapObj, fieldsToFetch, whereClause));

            getDataByObject({
                sObjectName,
                fieldsToFetch,
                whereClause: JSON.stringify(whereClause),
                orderBy: '',
                recordsLimit: null 
                })
                .then(result => {
                    return convertBackFieldsName(JSON.parse(result[sObjectName]), fieldsMapObj?.fields)
                })
                .then(groupsData => {
                    let groupsMap = {};
                    groupsData.forEach(user => {
                        const { Id, Name, Email, Type } = user;
                        groupsMap[Id] = {
                            Id,
                            Name,
                            Email,
                            Title: Type,
                            Department: "",
                            actorType: "agent" //TODO: This need to be handled in future, actorType to be as group
                        };
                    });
                    resolve(groupsMap);
                })
                .catch(error => {
                    console.error('--fetchGroupData-- Error fetching group data:', error);
                    reject(error);
                });
        } else {
            resolve({});
        }
    });
}

function fetchContactsData(contactIds) {
    return new Promise((resolve, reject) => {
        if (contactIds && contactIds.length) {
            let fieldsToFetch = ['Id', 'Name', 'FirstName', 'Email', 'Title', 'Department'];
            let whereClause = {
                "operator": "in",
                "key": "Id",
                "value": contactIds
            };
            let fieldsMapObj = objectFieldsMap.contact;
            let sObjectName = fieldsMapObj.sObject;
            ({ fieldsToFetch, whereClause } = convertFieldNames(fieldsMapObj, fieldsToFetch, whereClause));
    
            getDataByObject({
                sObjectName,
                fieldsToFetch,
                whereClause: JSON.stringify(whereClause),
                orderBy: '',
                recordsLimit: null 
                })
                .then(result => {
                    return convertBackFieldsName(JSON.parse(result[sObjectName]), fieldsMapObj.fields)
                })
                .then(contactsData => {
                    let contactsMap = {};
                    contactsData.forEach(contact => {
                        const { Id, Name, FirstName, Email, Title, Department } = contact;
                        contactsMap[Id] = {
                            Id,
                            Name,
                            FirstName,
                            Email,
                            Title,
                            Department,
                            actorType: 'contact',
                        };
                    });
                    resolve(contactsMap);
                })
                .catch(error => {
                    console.error('Error fetching created by data:', error);
                    reject('Error fetching created by data:' + error)
                });
        }
        else {
            resolve({});
        }
    });
}

function fetchCaseComments(caseId, limit = null) {
    return new Promise((resolve, reject) => {
        let fieldsToFetch = ['Id', 'CommentBody', 'CreatedDate', 'IsDeleted', 'IsPublished', 'ParentId', 'CreatedById', 'LastModifiedDate'];
        let whereClause = {
            "and": [
                {
                    "operator": "equals",
                    "key": "ParentId",
                    "value": `${caseId}`
                },
                {
                    "operator": "equals",
                    "key": "IsDeleted",
                    "value": false
                }
            ]
        }

        let orderBy = [{
            "field": "CreatedDate",
            "direction": "ASC",
            "nulls": "FIRST"
        }];

        let fieldsMapObj = objectFieldsMap.caseComments;
        let sObjectName = fieldsMapObj.sObject;
        ({ fieldsToFetch, whereClause, orderBy } = convertFieldNames(fieldsMapObj, fieldsToFetch, whereClause, orderBy));
        getDataByObject({ sObjectName, fieldsToFetch, whereClause: JSON.stringify(whereClause), orderBy: JSON.stringify(orderBy), recordsLimit: limit })
            .then(result => {
                return convertBackFieldsName(JSON.parse(result[sObjectName]), fieldsMapObj.fields)
            })
            .then(commentsData => {
                let returnData = [];
                commentsData.forEach((comment) => {
                    returnData.push({
                        id: comment.Id,
                        type: 'CaseCommentPost',
                        ts: comment.CreatedDate,
                        body: comment.CommentBody,
                        createdById: comment.CreatedById,
                        lastModifiedDate: comment.LastModifiedDate,
                        createdDate: comment.CreatedDate,
                        visibility: comment.IsPublished ? 'AllUsers' : 'InternalUsers'
                    });
                });
                resolve(returnData);
            })
            .catch(error => {
                console.error('--fetchCaseComments--Error fetching case comments:', error);
                reject('--fetchCaseComments-- Error fetching case comments:' + error);
            });
    });
}

function fetchCaseFeed(caseId, limit = null) {
    return new Promise((resolve, reject) => {
        let fieldsToFetch = ['Id', 'Body', 'CommentCount', 'CreatedDate', 'ParentId', 'CreatedById', 'Type', 'LastModifiedDate', 'Visibility'];
        let whereClause = {
            "and": [
                {
                    "operator": "equals",
                    "key": "ParentId",
                    "value": `${caseId}`
                },
                {
                    "operator": "in",
                    "key": "Type",
                    "value": ["LinkPost", "TextPost"]
                }
            ]
        };

        let orderBy = [{
            "field": "CreatedDate",
            "direction": "ASC",
            "nulls": "FIRST"
        }];

        let fieldsMapObj = objectFieldsMap.feedComments;
        let sObjectName = fieldsMapObj.sObject;
        ({ fieldsToFetch, whereClause, orderBy } = convertFieldNames(fieldsMapObj, fieldsToFetch, whereClause, orderBy));


        getDataByObject({
            sObjectName,
            fieldsToFetch,
            whereClause: JSON.stringify(whereClause),
            orderBy: JSON.stringify(orderBy),
            recordsLimit: limit
            })
            .then(result => {
                return convertBackFieldsName(JSON.parse(result[sObjectName]), fieldsMapObj.fields)
            })
            .then(textPostCommentsData => {
                let returnData = []
                textPostCommentsData.forEach((comment) => {
                        returnData.push({
                            id: comment.Id,
                            type: 'TextPost',
                            commentcount: comment.CommentCount,
                            ts: comment.CreatedDate,
                            body: comment.Body,
                            createdById: comment.CreatedById,
                            lastModifiedDate: comment.LastModifiedDate,
                            createdDate: comment.CreatedDate,
                            visibility: comment.Visibility
                        });
                });
                resolve(returnData);
            })
            .catch(error => {
                console.error('--fetchCaseFeed-- Error fetching case feed:', error);
                reject('-- fetchCaseFeed-- Error fetching case comments:' + error);
            });
    });
}

function fetchFeedComments(caseId, limit = null, caseFeedData = null) {
    return new Promise((resolve, reject) => {
        let fieldsToFetch = ['Id', 'CommentBody', 'CreatedDate', 'ParentId', 'CreatedById', 'FeedItemId', 'Type', 'LastModifiedDate'];
        let whereClause = {
            "and": [
                {
                    "operator": "equals",
                    "key": "ParentId",
                    "value": caseId
                },
                {
                    "operator": "equals",
                    "key": "IsDeleted",
                    "value": false
                }
            ]
        };

        let orderBy = [{
            "field": "CreatedDate",
            "direction": "ASC",
            "nulls": "FIRST"
        }];

        let fieldsMapObj = objectFieldsMap?.threadComments;
        let sObjectName = fieldsMapObj?.sObject;
        ({ fieldsToFetch, whereClause, orderBy } = convertFieldNames(fieldsMapObj, fieldsToFetch, whereClause, orderBy));

        getDataByObject({
            sObjectName,
            fieldsToFetch,
            whereClause: JSON.stringify(whereClause),
            orderBy: JSON.stringify(orderBy),
            recordsLimit: limit
        })
        .then(result => {
            return convertBackFieldsName(JSON.parse(result[sObjectName]), fieldsMapObj?.fields);
        })
        .then(feedCommentsData => {
            let returnData = [];
            feedCommentsData.forEach((comment) => {
                returnData.push({
                    id: comment?.Id,
                    type: 'TextPost',
                    ts: comment?.CreatedDate,
                    body: comment?.CommentBody,
                    createdById: comment?.CreatedById,
                    lastModifiedDate: comment?.LastModifiedDate ? comment?.LastModifiedDate : comment?.CreatedDate,
                    createdDate: comment?.CreatedDate,
                    feedItemId: comment.FeedItemId
                });
            });
            if(caseFeedData){
                caseFeedData = caseFeedData.filter(feedData => ["LinkPost", "TextPost", "CaseCommentPost"].includes(feedData.Type));
                let visibilityMap = {};
                caseFeedData.forEach((item) => {
                    visibilityMap[item.Id] = item.Visibility;
                });
                returnData.forEach((comment)=>{
                    comment.visibility =  visibilityMap[comment.feedItemId] ? visibilityMap[comment.feedItemId] : null;
                });
            }
            resolve(returnData);
        })
        .catch(error => {
            console.error('--fetchFeedComments-- Error fetching feed comments:', error);
            reject('--fetchFeedComments-- Error fetching feed comments:' + error);
        });
    });
}

function fetchCaseFeedData(caseId, limit = null) {
    return new Promise((resolve, reject) => {
        let fieldsToFetch = ['Id', 'Visibility', 'CreatedDate', 'Type', 'ParentId', 'CommentCount'];
        let whereClause = {
            "and": [
                {
                    "operator": "equals",
                    "key": "ParentId",
                    "value": `${caseId}`
                }
            ]
        };
        let orderBy = [{
            "field": "CreatedDate",
            "direction": "ASC",
            "nulls": "FIRST"
        }];
        let fieldsMapObj = objectFieldsMap.feedComments;
        let sObjectName = fieldsMapObj.sObject;
        ({ fieldsToFetch, whereClause, orderBy } = convertFieldNames(fieldsMapObj, fieldsToFetch, whereClause, orderBy));

        getDataByObject({
            sObjectName,
            fieldsToFetch,
            whereClause: JSON.stringify(whereClause),
            orderBy: JSON.stringify(orderBy),
            recordsLimit: limit
        })
        .then(result => {
            return convertBackFieldsName(JSON.parse(result[sObjectName]), fieldsMapObj.fields);
        })
        .then(data => {
            resolve(data);
        })
        .catch(error => {
            reject('-- fetchCaseFeedVisibility-- Error fetching case comments:' + error);
        });
    });
}

function fetchEmailComments(caseId, limit = null) {
    return new Promise((resolve, reject) => {
        let fieldsToFetch = ['Id', 'TextBody', 'CreatedDate', 'ParentId', 'CreatedById', 'IsDeleted', 'LastModifiedDate', 'HtmlBody', 'FromAddress', 'FromName', 'Incoming'];
        let whereClause = {
            "and": [
                {
                    "operator": "equals",
                    "key": "ParentId",
                    "value": `${caseId}`
                },
                {
                    "operator": "equals",
                    "key": "IsDeleted",
                    "value": false
                }
            ]
        };

        let orderBy = [{
            "field": "CreatedDate",
            "direction": "ASC",
            "nulls": "FIRST"
        }];

        let fieldsMapObj = objectFieldsMap?.emailMessage;
        let sObjectName = fieldsMapObj?.sObject;
        ({ fieldsToFetch, whereClause, orderBy } = convertFieldNames(fieldsMapObj, fieldsToFetch, whereClause, orderBy));

        getDataByObject({
            sObjectName,
            fieldsToFetch,
            whereClause: JSON.stringify(whereClause),
            orderBy: JSON.stringify(orderBy),
            recordsLimit: limit
        })
        .then(result => {
            return convertBackFieldsName(JSON.parse(result[sObjectName]), fieldsMapObj?.fields);
        })
        .then(emailCommentsData => {
            let returnData = [];
            emailCommentsData.forEach((comment) => {
                returnData.push({
                    id: comment?.Id,
                    type: 'EmailMessageEvent',
                    ts: comment?.CreatedDate,
                    body: comment?.TextBody,
                    createdById: comment?.CreatedById,
                    lastModifiedDate: comment?.LastModifiedDate ? comment?.LastModifiedDate : comment?.CreatedDate,
                    createdDate: comment?.CreatedDate,
                    htmlBody: comment.HtmlBody,
                    incoming: comment.Incoming,
                    fromAddress: comment.FromAddress,
                    fromName: comment.FromName
                });
            });
            resolve(returnData);
        })
        .catch(error => {
            console.error('--fetchEmailComments-- Error fetching feed comments:', error);
            reject('--fetchEmailComments-- Error fetching feed comments:' + error);
        });
    });
}

function fetchCaseAgentsHistory(caseId, currentCaseOwner, caseCreatedDate) {
    return new Promise((resolve, reject) => {
        let fieldsToFetch = ['NewValue', 'OldValue', 'CaseId', 'CreatedDate', 'DataType', 'Field', 'Id', 'IsDeleted', 'CreatedById'];
        let whereClause = {
            "and": [
                {
                    "operator": "equals",
                    "key": "CaseId",
                    "value": `${caseId}`
                },
                {
                    "or": [
                        {
                            "and": [
                                {
                                    "operator": "equals",
                                    "key": "Field",
                                    "value": "Owner"
                                },
                                {
                                    "operator": "equals",
                                    "key": "DataType",
                                    "value": "EntityId"
                                }
                            ]
                        },
                        {
                            "operator": "equals",
                            "key": "Field",
                            "value": "Status"
                        }  
                    ]

                }
            ]
        };

        let orderBy = [
            {
                "field": "CreatedDate",
                "direction": "ASC",
                "nulls": "FIRST"
            }
        ];

        let fieldsMapObj = objectFieldsMap.caseAgentHistory;
        let sObjectName = fieldsMapObj.sObject;
        ({ fieldsToFetch, whereClause, orderBy } = convertFieldNames(fieldsMapObj, fieldsToFetch, whereClause, orderBy));

        getDataByObject({
            sObjectName,
            fieldsToFetch,
            whereClause: JSON.stringify(whereClause),
            orderBy: JSON.stringify(orderBy),
            recordsLimit: null
            })
            .then(result => {
                return convertBackFieldsName(JSON.parse(result[sObjectName]), fieldsMapObj.fields)
            })
            .then(historyItems => {
                let caseAgentsList = [];

                historyItems.forEach(historyItem => {
                    if (historyItem.Field === 'Owner'){
                        let fromDate = caseAgentsList.length > 0 ? caseAgentsList[caseAgentsList.length - 1].toDate : caseCreatedDate;
                        let toDate = historyItem.CreatedDate;
                        caseAgentsList.push({
                            fromDate,
                            toDate,
                            'Id': historyItem.OldValue,
                            ts: historyItem.CreatedDate,
                            timeInterval: new Date(toDate) - new Date(fromDate),
                            voidTime: 0,
                            activeTime: new Date(toDate) - new Date(fromDate),
                        });
                    }  
                });

                // Add current owner, there is no entry in casehistory for assigned owner while creating case
                // in above loop we have added all previous owner's but the last owner change( new user/ current owner is not added)
                let fromDate = caseAgentsList.length > 0 ? caseAgentsList[caseAgentsList.length - 1]?.toDate : caseCreatedDate;
                let toDate = getCurrentTimeFormatted();
                caseAgentsList.push({
                    fromDate,
                    toDate,
                    'Id': currentCaseOwner,
                    ts: caseCreatedDate,
                    timeInterval: new Date(toDate) - new Date(fromDate),
                    voidTime: 0,
                    activeTime: new Date(toDate) - new Date(fromDate),
                });


                let caseStatusIntervals = [];
                let caseClosedStartDate = null;
                let caseOpenStartDate = caseCreatedDate;

                historyItems.forEach((historyItem) => {
                    if (historyItem.Field === "Status") {
                        if (historyItem.NewValue === "Closed") {
                            // Case is closed
                            caseStatusIntervals.push({
                                isClose: false,
                                fromDate: caseOpenStartDate,
                                toDate: historyItem.CreatedDate
                            });

                            caseClosedStartDate = historyItem.CreatedDate;
                            caseOpenStartDate = null;
                        } else if (historyItem.OldValue === "Closed" && caseClosedStartDate) {
                            // Case is reopened
                            caseStatusIntervals.push({
                                isClose: true,
                                fromDate: caseClosedStartDate,
                                toDate: historyItem.CreatedDate
                            });

                            caseClosedStartDate = null;
                            caseOpenStartDate = historyItem.CreatedDate;
                        }
                    }
                });
                if (caseClosedStartDate) {
                caseStatusIntervals.push({
                    isClose: true,
                    fromDate: caseClosedStartDate,
                    toDate: new Date()
                });
                }else if(caseOpenStartDate){
                    caseStatusIntervals.push({
                    isClose: false,
                    fromDate: caseOpenStartDate,
                    toDate: new Date()
                    });
                }

                caseAgentsList.forEach(agent => {
                    let voidTime = 0;
                    caseStatusIntervals.forEach(status => {
                        if (status.isClose) {
                            const overlap = getOverlap(agent, status);
                            voidTime += overlap;
                        }
                    });
                    agent.voidTime = voidTime;
                    agent.activeTime = agent.activeTime - voidTime;
                });

                caseAgentsList = caseAgentsList.filter(agent => agent.activeTime > 0);
                resolve({ hasAccess: true, agents: caseAgentsList });
            })
            .catch(error => {
                console.error('--fetchCaseAgentsHistory-- Error fetching case agents history:', error);
                if (error.body.message === 'User does not have access to the specified object') {
                    resolve({ hasAccess: false, agents: [] })
                } else {
                    reject('--fetchCaseAgentsHistory-- Error fetching case agents history:' + error);
                }
            });
    });
}

function getOverlap(agentInterval, statusInterval) {
    const start = Math.max(new Date(agentInterval.fromDate).getTime(), new Date(statusInterval.fromDate).getTime());
    const end = Math.min(new Date(agentInterval.toDate).getTime(), new Date(statusInterval.toDate).getTime());
    return (start < end) ? (end - start) : 0;
}

function fetchCaseStatusHistory(caseId, currentCaseStatus, caseCreatedDate) {
    return new Promise((resolve, reject) => {
        let fieldsToFetch = ['NewValue', 'OldValue', 'CaseId', 'CreatedDate', 'DataType', 'Field', 'Id', 'IsDeleted', 'CreatedById'];
        let whereClause = {
            "and": [
                {
                    "operator": "equals",
                    "key": "CaseId",
                    "value": `${caseId}`
                },
                {
                    "operator": "equals",
                    "key": "Field",
                    "value": "Status"
                }
            ]
        };

        let orderBy = [
            {
                "field": "CreatedDate",
                "direction": "ASC",
                "nulls": "FIRST"
            }
        ];


        let fieldsMapObj = objectFieldsMap.caseStatusHistory;
        let sObjectName = fieldsMapObj.sObject;
        ({ fieldsToFetch, whereClause, orderBy } = convertFieldNames(fieldsMapObj, fieldsToFetch, whereClause, orderBy));

        getDataByObject({
            sObjectName,
            fieldsToFetch,
            whereClause: JSON.stringify(whereClause),
            orderBy: JSON.stringify(orderBy),
            recordsLimit: null
            })
            .then(result => {
                return convertBackFieldsName(JSON.parse(result[sObjectName]), fieldsMapObj.fields)
            })
            .then(historyItems => {
                let statusHistoryList = [];

                historyItems.forEach(historyItem => {
                    let fromDate = statusHistoryList.length > 0 ? statusHistoryList[statusHistoryList.length - 1].toDate : caseCreatedDate;
                    let toDate = historyItem.CreatedDate;
                    statusHistoryList.push({
                        fromDate,
                        toDate,
                        'status': historyItem.OldValue,
                        ts: historyItem.CreatedDate,
                        timeInterval: new Date(toDate) - new Date(fromDate)
                    });
                });

                // Add current status, there is no entry in casehistory for status while creating case
                // in above loop we have added all previous status's but the last status change( new status/ current status is not added)
                let fromDate = statusHistoryList.length > 0 ? statusHistoryList[statusHistoryList.length - 1].toDate : caseCreatedDate;
                let toDate = getCurrentTimeFormatted()
                statusHistoryList.push({
                    fromDate,
                    toDate,
                    'status': currentCaseStatus,
                    ts: caseCreatedDate,
                    timeInterval: new Date(toDate) - new Date(fromDate)
                });
                resolve({ hasAccess: true, statusHistory: statusHistoryList });
            })
            .catch(error => {
                console.error('--fetchCaseStatusHistory-- Error fetching case status history:', error);
                if (error?.body?.message === 'User does not have access to the specified object') {
                    resolve({ hasAccess: false })
                } else {
                    reject('--fetchCaseStatusHistory-- Error fetching case status history:', error);
                }
            });
    });
}

function addActorDetails(activityList, userData) {
    try {
        activityList.map(activity => {
            let userInfo = userData[activity.CreatedById] ? userData[activity.CreatedById] : userData[activity.createdById];
            if(activity.type === 'EmailMessageEvent' && activity.incoming){
                activity.actorName = activity.fromName;
                activity.actorFirstName = activity.fromName;
                activity.actorEmail = userInfo.fromAddress;
                activity.actorTitle = '';
                activity.actorDepartment = '';
                activity.actorType = 'user';
            }else{
                activity.actorName = userInfo.Name;
                activity.actorFirstName = userInfo.FirstName;
                activity.actorEmail = userInfo.Email;
                activity.actorTitle = userInfo.Title;
                activity.actorDepartment = userInfo.Department;
                activity.actorType = userInfo.actorType;
            }
            return activity
        })
        return activityList;
    } catch (error) {
        console.log('--addActorDetails-- Error occured', error);
        throw new Error('--addActorDetails-- Error occured' + error)
    }
}


function addAgentDetails(agentsList, userData) {
    try {
        agentsList.map(agent => {
            let userInfo = userData[agent.Id];
            agent.name = userInfo.Name;
            agent.firstName = userInfo.FirstName;
            agent.email = userInfo.Email;
            agent.actorTitle = userInfo.Title;
            agent.actorDepartment = userInfo.Department;
            agent.actorType = userInfo.actorType;
            return agent;
        })
        return agentsList;
    } catch (error) {
        console.log('--addAgentDetails-- Error occured', error);
        throw new Error('--addAgentDetails-- Error occured' + error)
    }
}


function getActorType(userType) {
    userType = userType ? userType.toLowerCase() : "";
    const customerTypes = ['powercustomersuccess', 'customersuccess', 'cspliteportal'];
    try {
        const isUser = customerTypes.indexOf(userType);
        let actorType = 'user';
        if (isUser === -1) {
            actorType = 'agent';
        }
        return actorType;
    } catch (error) {
        console.error('Error in getActorType:', error);
        throw new Error('Error in getActorType');
    }
}

function getCurrentTimeFormatted() {
    const now = new Date();
    const year = now.getUTCFullYear();
    const month = String(now.getUTCMonth() + 1).padStart(2, '0'); // months are 0-based
    const day = String(now.getUTCDate()).padStart(2, '0');
    const hours = String(now.getUTCHours()).padStart(2, '0');
    const minutes = String(now.getUTCMinutes()).padStart(2, '0');
    const seconds = String(now.getUTCSeconds()).padStart(2, '0');
    const milliseconds = String(now.getUTCMilliseconds()).padStart(3, '0');
    const timezoneOffset = '+0000';

    return `${year}-${month}-${day}T${hours}:${minutes}:${seconds}.${milliseconds}${timezoneOffset}`;
}


function responseDto(success, message, data = null, error = null) {
    return { success, message, data, error }
}

function fetchCaseRecord(caseId, fields ='') {
    return new Promise((resolve, reject) => {
        let fieldsToFetch = ['Id', 'CaseNumber', ...fields.split(',')];
        let whereClause = {
            "operator": "equals",
            "key": "Id",
            "value": `${caseId}`
        }

        let fieldsMap = objectFieldsMap.case;
        let sObjectName = fieldsMap.sObject;
        ({ fieldsToFetch, whereClause } = convertFieldNames(fieldsMap, fieldsToFetch, whereClause));
        getDataByObject({
            sObjectName,
            fieldsToFetch,
            whereClause: JSON.stringify(whereClause),
            orderBy: '',
            recordsLimit: null })
            .then(result => {
                return convertBackFieldsName(JSON.parse(result[sObjectName]), fieldsMap.fields)
            })
            .then(result => {
                let caseData = result[0];
                resolve(caseData);
            })
            .catch(error => {
                console.error('--fetchCaseData-- Error fetching case Data:', error);
                reject('--fetchCaseData-- Error fetching case Data:' + error);
            });
    });
}

function checkAccess(caseId) {
    return new Promise((resolve, reject) => {
        if (caseId) {
            let fieldsToFetch = ['Id'];
            let whereClause = {
                "operator": "equals",
                "key": "Id",
                "value": caseId
            };

            let fieldsMapObj = objectFieldsMap.case;
            let sObjectName = fieldsMapObj.sObject;
            ({ fieldsToFetch, whereClause } = convertFieldNames(fieldsMapObj, fieldsToFetch, whereClause));

            getDataByObject({
                sObjectName,
                fieldsToFetch,
                whereClause: JSON.stringify(whereClause),
                orderBy: '',
                recordsLimit: 1
            })
            .then(() => {
                resolve({hasAccess: true});
            })
            .catch(error => {
                if(error && error.body && error.body.message.includes("You do not have access to the Apex class")){
                    resolve({hasAccess: false});
                }else{
                    console.error('--checkAccess-- Error checking access:', error);
                    reject(error);
                }
            });
        } else {
            resolve(false);
        }
    });
}

export {
    fetchTimelineData,
    fetchResponseAssistData,
    fetchCaseSummaryData,
    fetchKnowledgeArticles,
    fetchCaseRecord,
    fetchSentimentData,
    fetchCaseData,
    fetchUsersData,
    usersDataFactory,
    checkAccess
};