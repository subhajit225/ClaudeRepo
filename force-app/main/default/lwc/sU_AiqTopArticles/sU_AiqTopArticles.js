import { LightningElement, track, api } from 'lwc';
import {fetchKnowledgeArticles} from 'c/sU_AiqDataRepository';
import {convertToTimezone, trackEvent} from 'c/sU_AiqUtils';

export default class SU_AiqTopArticles extends LightningElement {
    @api caseIds;    
    @api topArticlesIds;
    @api topArticlesData;
    @api loggedInUserData;
    @api metaData;
    @api isDataError;
    @api refinedQuery;
    @api token;
    @api endPoint;
    @api uid;
    @api recordId;
    @api s3endpoint;
    @track articlesSourceFilter = 'all';

    @track items = [];
    knowledgeArticleRecords;//variable used to store and iterate over the fetched Knowledge articles related to current case
    allKnowledgeArticleRecords;//variable used to store all articles
    knowledgeArticleRecordsFiltered; // to keep backup with filters 
    topArticlesLoader=true;
    @track showArticles = true;//flag variable used to toggle display of data in Top Articles tab
    @track DateModalFlag = false;//flag variable used to toggle display of date modal popup in the component 
    @track createdChecked = false;//variable used to store value of created date checkbox in date modal popup
    @track updatedChecked = false;//variable used to store value of updated date checkbox in date modal popup
    @api maincontainerwidth;
    tabName;
    loadItemsCount = 10;
    @api
    set sectionName(value) {
        if (value === 'Top Articles') {
            this.resetDates();
            if (this.knowledgeArticleRecords && this.knowledgeArticleRecords.length < this.allKnowledgeArticleRecords.length) {
                this.knowledgeArticleRecords = this.allKnowledgeArticleRecords.slice(0, this.loadItemsCount);
                this.showArticles = this.knowledgeArticleRecords.length > 0;
            }
            this.tabName = value;
        }
    }
    get sectionName() {
        return this.tabName;
    }
    get caseId() {
        return this.isUtility ? this.caseIdForUtility : this.recordId;
    }
    get processedKnowledgeArticles() {
    return this.knowledgeArticleRecords.map((article) => {
        return {
            ...JSON.parse(JSON.stringify(article)), 
            localKey: article.Title + '_' + article.LastModifiedDate + '_' + Math.random() // unique key
        };
    });
}
    todaysDate;
    startDate;
    createdStartDate;
    createdEndDate;
    updatedStartDate;
    updatedEndDate;
    origin;
    caseFields;
    agentMap = new Map();


    getAttachCase(num) {
        let digits = 1;           //used for decimal digits
        const lookup = [
            { value: 1, symbol: "" },
            { value: 1e3, symbol: "k" },
            { value: 1e6, symbol: "M" },
            { value: 1e9, symbol: "G" },
            { value: 1e12, symbol: "T" },
            { value: 1e15, symbol: "P" },
            { value: 1e18, symbol: "E" }
        ];
        const rx = /\.0+$|(\.[0-9]*[1-9])0+$/;
        let lookupArr = lookup.slice().reverse();
        let itemIndex = -1;
        lookupArr.some((item, i) => (num >= item.value) && (itemIndex = i));
        return itemIndex > -1 ? (num / lookupArr[itemIndex].value).toFixed(digits).replace(rx, "$1") + lookupArr[itemIndex].symbol : "0";
    }
    getDateTime(dateTime, setToUtc = false) {
        if (dateTime) {
            var date = new Date(dateTime);
            if(setToUtc){
                date = new Date(date.getTime() + date.getTimezoneOffset() * 60000);
            }
            if (!date.getTime()) {
                let str = dateTime.replace(/-/g, '/');
                date = new Date(str);
            }
            var dates = date.getDate()
            var month = date.getMonth() + 1;
            if (month < 10) {
                month = "0" + month;
            }
            if (dates < 10) {
                dates = "0" + dates;
            }
            var date_appointment = dates + '-' + month + '-' + date.getFullYear();
            var hours = date.getHours();
            var minutes = date.getMinutes();
            if (minutes < 10)
                minutes = "0" + minutes;
            var suffix = "AM";
            if (hours >= 12) {
                suffix = "PM";
                hours = hours - 12;
            }
            if (hours === 0) {
                hours = 12;
            }
            var current_time = hours + ":" + minutes + " " + suffix;
            return `${date_appointment} | ${current_time}`
        }
        return '';

    }

    //connectedCallback called on component load used to load results into variable by using case ids fetched from parent component
    async connectedCallback() {
        this.loadArticles();
    }

    async loadArticles(){
        this.topArticlesLoader = true;
        this.resetDates();
        this.caseFields = {
            'knowledgeArticle': 'Title,CreatedDate,LastModifiedDate',
            'userFields': 'FullPhotoUrl,Title,IsActive,Name'
        };
        this.origin = window.location.origin;
       
        // Top articles from article IDs from the search results.
        if (this.topArticlesIds) {

            if((this.topArticlesIds && this.topArticlesIds.length) || (this.topArticlesData && this.topArticlesData.length)){

                console.log("Found all topArticlesIds ===> ", JSON.stringify(this.topArticlesIds));
                console.log("Found all topArticle : ", JSON.stringify(this.topArticlesData));
    
                let allArticlesData = JSON.stringify(this.topArticlesData);
    
                // Parse allArticlesData if it's a string
                let allData = Array.isArray(allArticlesData)
                ? allArticlesData
                : JSON.parse(allArticlesData);
    
                let articlesData = [];
                let usersData = [];
    
                // Fetch the articles properly
                try {
                    console.log("Fetching the KB Articles...");
                    const response = await fetchKnowledgeArticles(this.topArticlesIds);
                    usersData = response?.users || [];
                    articlesData = response?.articles || [];
    
                    console.log("articlesData Array from Inside ===> ", JSON.stringify(articlesData));
                } catch (error) {
                    console.error("No KB Articles found", error);
                }
                articlesData.forEach(article => article.sourceLabel = 'Salesforce');
                console.log("articlesData Array ===> ", JSON.stringify(articlesData));
    
                let mergedData = [...allData, ...articlesData];
                
                    console.log("mergedData ===> ", JSON.stringify(mergedData))
    
                    let formattedData = mergedData.map((article, index) => {
                        try {
                            const ownerInfo = usersData[article.OwnerId] || {};
                            const highlight = article.highlight || {};
                            const metadata = article.metadata || [];
    
                            // Safe fetch of values from metadata (for non-SFDC data)
                            const getMetaValue = (key) => {
                                try {
                                    const item = metadata.find(m => m.key === key);
                                    return item?.value?.[0] || '';
                                } catch (metaError) {
                                    console.error(`Metadata error at index ${index} for key: ${key}`, metaError);
                                    return '';
                                }
                            };
    
                            const createdDate = article.CreatedDate || getMetaValue('Published Date') || highlight['Created Date']?.[0] || highlight['Published Date']?.[0] || '';
                            const lastModifiedDate = article.LastModifiedDate || highlight['Updated Date']?.[0] || highlight['Published Date']?.[0] || '';
    
                            let caseCreatedDate = '';
                            let finalLastModifiedDate = '';
    
                            try {
                                caseCreatedDate = createdDate ? this.getDateTime(createdDate) : highlight['Published Date']?.[0] || '';
                            } catch (err) {
                                console.error(`Error processing caseCreatedDate at index ${index}:`, err);
                                caseCreatedDate = createdDate || '';
                            }
    
                            try {
                                finalLastModifiedDate = article.LastModifiedDate
                                    ? this.getDateTime(convertToTimezone(article.LastModifiedDate, this.loggedInUserData.TimeZoneSidKey), true)
                                    : highlight['Updated Date']?.[0] || highlight['Published Date']?.[0] || '';
                            } catch (err) {
                                console.error(`Error processing lastModifiedDate at index ${index}:`, err);
                                finalLastModifiedDate = lastModifiedDate || '';
                            }
    
                            return {
                                Title: article.Title || highlight.TitleToDisplayString?.[0] || '',
                                CreatedDate: createdDate,
                                LastModifiedDate: lastModifiedDate,
                                OwnerId: article.OwnerId || null,
                                OwnerName: ownerInfo.Name || highlight['Reporter']?.[0] || getMetaValue('author Name'),
                                Icon: ownerInfo.FullPhotoUrl || 'https://r041902s.searchunify.com/resources/Asset-Library/1e2b824f923c31731b047dd1a8b783f7/photo.png',
                                Role: ownerInfo.Title || '',
                                isActive: ownerInfo.IsActive ?? false,
                                caseCreatedDate: caseCreatedDate,
                                lastModifiedDate: finalLastModifiedDate,
                                previewUrl: article.href || `${this.origin}/${article.Id}`,
                                articleCount: 0,
                                listClass: 'list',
                                sourceLabel: article.sourceLabel
                            };
                        } catch (err) {
                            console.error(`Error formatting article at index ${index}:`, err, article);
                            return null;  // Return null if article fails, so it won't break whole list
                        }
                    }).filter(Boolean); // Remove any null entries
    
    
    
                    console.log("formattedData ===> ", JSON.stringify(formattedData))
    
    
                    
                    // this.knowledgeArticleRecords = responseData.slice(0, this.loadItemsCount);
                    this.knowledgeArticleRecords = formattedData;
                //     this.allKnowledgeArticleRecords = formattedData;
                    this.knowledgeArticleRecordsFiltered = formattedData;
                    this.showArticles = formattedData.length !== 0;
                    this.topArticlesLoader=false;
                    this.lastUpdatedSortHandler(false);
                    this.sortByButtonHandler();
                    this.agentsMapsHandler(this.knowledgeArticleRecords);
                    this.knowledgeArticleRecords =  this.knowledgeArticleRecords.map((item)=>{
                        const count=item.articleCount;
                        let thousands;
                        if(count >=1000){
                            thousands=parseInt(count,10)/1000;
                            thousands = Math.floor(thousands);
                            thousands+="k";
                        }else{
                            thousands=item.articleCount;
                        }
                        return {
                            ...item,
                            articleCountInThousands:thousands,
                        }
                    })
            }else{
                this.showArticles = false;
                console.log("No Related Articles found");
            }
        }
    }

    agentsMapsHandler(data) {
        data.map((item) => {
            let value = 1;
            if (this.agentMap.has(item.OwnerName)) {
                value = value + this.agentMap.get(item.OwnerName);
            }
            this.agentMap.set(item.OwnerName, value);
            return item;
        })
    }

    resetDates() {
        let todaysDate = new Date(new Date().setHours(23, 59, 59, 999));
        let startDate = new Date((new Date).setDate(todaysDate.getDate() - 30));

        startDate = new Date(startDate).getFullYear() + '-' + (
            (new Date(startDate).getMonth() + 1) < 10 ? '0' + (new Date(startDate).getMonth() + 1) : (new Date(startDate).getMonth() + 1)
        ) + '-' + (
                (new Date(startDate).getDate()) < 10 ? '0' + (new Date(startDate).getDate()) : (new Date(startDate).getDate())
            );

        todaysDate = new Date(todaysDate).getFullYear() + '-' + (
            (new Date(todaysDate).getMonth() + 1) < 10 ? '0' + (new Date(todaysDate).getMonth() + 1) : (new Date(todaysDate).getMonth() + 1)
        ) + '-' + (
                (new Date(todaysDate).getDate()) < 10 ? '0' + (new Date(todaysDate).getDate()) : (new Date(todaysDate).getDate())
            );
        this.createdStartDate = startDate;
        this.createdEndDate = todaysDate;
        this.updatedStartDate = startDate;
        this.updatedEndDate = todaysDate;

        this.startDate = startDate;
        this.todaysDate = todaysDate;
        this.createdChecked = false;
        this.updatedChecked = false;
    }

    handleScroll(event) {
        if (event.target.scrollHeight - event.target.clientHeight < event.target.scrollTop + 20) {
            if (this.loadItemsCount < this.knowledgeArticleRecordsFiltered.length) {
                this.loadItemsCount = this.loadItemsCount + 2;
                this.knowledgeArticleRecords = this.knowledgeArticleRecords.concat(this.knowledgeArticleRecordsFiltered.slice(this.knowledgeArticleRecords.length, this.loadItemsCount));
            }
        }
    }

    expandInfoDiv(event) {
        let index = event.currentTarget.dataset.index;
        if (index > -1) {
            this.knowledgeArticleRecords[index].expanded = this.knowledgeArticleRecords[index].expanded ? false : true;
            let knowledgeArticleRecordsBck = this.knowledgeArticleRecords;
            this.knowledgeArticleRecords = [];
            this.knowledgeArticleRecords = knowledgeArticleRecordsBck;
            this.knowledgeArticleRecords.forEach((obj, i) => {
                if (index !== i)
                    obj.expanded = false;
                obj.listClass = obj.expanded ? 'article-expanded list' : 'list'
                return obj;
            });
        }
    }
    //method that toggles the display of date modal popup in the component
    openDateModal() {
        this.DateModalFlag = !this.DateModalFlag ? true : false;
        let r = this.template.querySelector("[data-id='createdStartDate']");
        console.log('created adte ', r);
    }
    //method that is used when Created Date checkbox value is changed in date modal popup
    handleChangeCreatedDate(event) {
        this.createdChecked = event.target.checked;
        let pass = event.target.checked ? 'createSelect' : 'createDeselect';
        let r = this.template.querySelector('[data-id="createdStartDate"]');
        console.log('created adte ', r);
        this.updateRecords(pass);
    }
    //method that is used when Updated Date checkbox value is changed in date modal popup
    handleChangeUpdatedDate(event) {
        this.updatedChecked = event.target.checked;
        let pass = event.target.checked ? 'updateSelect' : 'updateDeselect';
        this.updateRecords(pass);
    }
    //method that filters the data being displayed when value of checkbox is toggled in Date Modal Popup using the values in the date fields
    updateRecords() {
        this.knowledgeArticleRecords = [];
        this.knowledgeArticleRecordsFiltered = this.allKnowledgeArticleRecords;

        let createdEndD = new Date(new Date(this.createdEndDate).setHours(23, 59, 59, 999));
        let createdStartD = new Date(new Date(this.createdStartDate).setHours(0, 0, 0, 0));

        let updatedEndD = new Date(new Date(this.updatedEndDate).setHours(23, 59, 59, 999));
        let updatedStartD = new Date(new Date(this.updatedStartDate).setHours(0, 0, 0, 0));
        this.knowledgeArticleRecordsFiltered = this.knowledgeArticleRecordsFiltered.filter(c => {
            if (!this.createdChecked && !this.updatedChecked) return true;
            else if (this.createdChecked && this.updatedChecked)
                return (new Date(c.CreatedDate) > createdStartD && new Date(c.CreatedDate) < createdEndD && new Date(c.LastModifiedDate) > updatedStartD && new Date(c.LastModifiedDate) < updatedEndD);
            else if (this.createdChecked)
                return new Date(c.CreatedDate) > createdStartD && new Date(c.CreatedDate) < createdEndD;

            return new Date(c.LastModifiedDate) > updatedStartD && new Date(c.LastModifiedDate) < updatedEndD;
        });
        this.loadItemsCount = 10;
        this.knowledgeArticleRecords = this.knowledgeArticleRecordsFiltered.slice(0, this.loadItemsCount);
        if (this.createdChecked && this.updatedChecked && this.maincontainerwidth < 500)
            this.template.querySelector('.filter-fixed-height').style = 'height: 57px;';
        else this.template.querySelector('.filter-fixed-height').style = 'height: unset;';
        this.showArticles = this.knowledgeArticleRecords.length > 0;
    }
    //method called when value of start or end date is changed in date modal popup for either Created Date or Updated Date
    handleCreatedDateChange(event) {
        let date = event.currentTarget.value;
        let type = event.currentTarget.dataset.id;
        if (type === 'createdStartDate') {
            this.createdStartDate = date;
            this.createdEndDate = new Date(date) > new Date(this.createdEndDate) ? date : this.createdEndDate;
        } else this.createdEndDate = date;
        this.updateRecords();
    }

    handleUpdatedDateChange(event) {
        let date = event.currentTarget.value;
        let type = event.currentTarget.dataset.id;
        if (type === 'updatedStartDate') {
            this.updatedStartDate = date;
            this.updatedEndDate = new Date(date) > new Date(this.updatedEndDate) ? date : this.updatedEndDate;
        } else this.updatedEndDate = date;
        this.updateRecords();
    }
    sortByButtonHandler() {
        const sortMenuHolder = this.template.querySelector('.sort-menu-holder');
        sortMenuHolder.style.display = (sortMenuHolder.style.display === 'block') ? 'none' : 'block';
    }

    //function to handle sort for the most attached sort button
    mostAttachedSortHandler(){
        let mostAttachedSort=[...this.knowledgeArticleRecords];
        mostAttachedSort=mostAttachedSort.map((item)=>{
            return {
                ...item,
                articleCount:parseInt(item.articleCount,10),
            }
        })

        mostAttachedSort.sort((a, b) => {
            return b.articleCount - a.articleCount;
        });
        this.knowledgeArticleRecords = mostAttachedSort;
        this.sortByButtonHandler(); //closing the sort menu 

        trackEvent({
            ...this.metaData,
            feature_category: "Top Articles",
            feature_name: "Sort By Most attached",
            interaction_type: 'click',   
            feature_description: "Articles data sorted by most attached.",
            metric: {}
        }, this.loggedInUserData);
    }

    //func to handle sort for the last updated sort 
    lastUpdatedSortHandler(isBySortClick = true) {
        let lastUpdatedSort = [...this.knowledgeArticleRecords];
        lastUpdatedSort.sort((a, b) => {
            return new Date(b.LastModifiedDate) - new Date(a.LastModifiedDate);
        });

        this.knowledgeArticleRecords = lastUpdatedSort;
        this.sortByButtonHandler();

        if(isBySortClick){
            trackEvent({
                ...this.metaData,
                feature_category: "Top Articles",
                feature_name: "Sort By Last Updated",
                interaction_type: 'click',   
                feature_description: "Articles data sorted by last updated.",
                metric: {}
            }, this.loggedInUserData);
        }
    }

    topAgentSortHandler() {
        const countByOwnerId = Object.fromEntries(this.agentMap);
        let topAgentSorted = [...this.knowledgeArticleRecords];
        topAgentSorted.sort((a, b) => {
            const countA = countByOwnerId[a.OwnerName] || 0;
            const countB = countByOwnerId[b.OwnerName] || 0;
            return countB - countA;
        });
       this.knowledgeArticleRecords = topAgentSorted;
       this.sortByButtonHandler();

       trackEvent({
            ...this.metaData,
            feature_category: "Top Articles",
            feature_name: "Sort By Top Agents",
            interaction_type: 'click',   
            feature_description: "Articles data sorted by top agents.",
            metric: {}
        }, this.loggedInUserData);

    }

    articlePreview(){
        trackEvent({
            ...this.metaData,
            feature_category: "Top Articles",
            feature_name: "Article Preview",
            interaction_type: 'click',   
            feature_description: "Clicked on preview icon",
            metric: {}
        }, this.loggedInUserData);
    }

    filterByButtonHandler() {
        const filterMenuHolder = this.template.querySelector('.filter-menu-holder');
        filterMenuHolder.style.display = (filterMenuHolder.style.display === 'block') ? 'none' : 'block';
    }

    handleFilterSelection(event) {
        const selectedFilter = event.currentTarget.dataset.filter;
        if(this.articlesSourceFilter !== selectedFilter){
            this.articlesSourceFilter = selectedFilter;
            // Highlight selected option
            const filterMenuHolder = event.currentTarget.closest('.filter-menu-holder');
            const allItems = filterMenuHolder.querySelectorAll('.dropdown-menu-list-holder > li');
            allItems.forEach(item => item.removeAttribute('data-selected'));
            event.currentTarget.setAttribute('data-selected', 'true');

            this.filterByButtonHandler(); // close dropdown
            this.topArticlesBySearch(selectedFilter)
        }
    }

    topArticlesBySearch(sourceFilter) {
        this.topArticlesLoader = true;
        return new Promise((resolve, reject) => {
            let data = JSON.stringify({
                "searchString": this.refinedQuery || '',
                "from": 0,
                "sortby": "_score",
                "orderBy": "desc",
                "resultsPerPage": 10,
                "uid": this.metaData.searchUidAH,
                "app": "agent-helper",
                "contextLimit": 2000,
                "resultsToConsider": 10,
                "aggregations": [
                    {
                        "type": "_type",
                        "filter": sourceFilter === 'all' ? ["how_to__kav", "page", "issue" ] : [sourceFilter] // how_to__kav -> salesforce, "page"-> confluence, "issue"-> jira
                    }
                ]
            });
            var xmlHttp = new XMLHttpRequest();
            var url = this.endPoint + "/search/SUSearchResults";
            xmlHttp.withCredentials = true;
            xmlHttp.open("POST", url, true);
            xmlHttp.setRequestHeader("Accept", "application/json");
            xmlHttp.setRequestHeader('Authorization', 'bearer ' + this.token);
            xmlHttp.setRequestHeader('Content-Type', 'application/json');

            xmlHttp.onload = () => {
                if (xmlHttp.readyState === 4) {
                    if (xmlHttp.status === 200) {
                        var searchResponse = JSON.parse(xmlHttp.response);

                        var kbIds = searchResponse?.result?.hits
                        ?.filter(x => x?.Id?.startsWith("ka"))
                        .map(e => e?.Id);

                        let jiraData = searchResponse?.result?.hits
                        ?.filter(x => x?.objName != 'how_to__kav');

                        this.topArticlesData = jiraData;
                        this.topArticlesIds = kbIds;
                        this.loadArticles();

                        resolve();
                    }
                    else {
                        console.log("Top Article failed: ", xmlHttp.status)
                        this.articleSearchError = true;
                        reject('HTTP Error: ' + xmlHttp.status);
                    }
                    this.articlesLoading = false;
                }
            }
            xmlHttp.onerror = () => {
                reject('Network Error');
                this.articlesLoading = false;
                this.articleSearchError = true;
            };
            xmlHttp.send(data);
        })
    }
}