import { LightningElement, api, track } from 'lwc';
import { registerListener, fireEvent, makeSearchCall } from 'c/supubsub';
import { NavigationMixin } from 'lightning/navigation';

export default class SU_BannerComponent extends NavigationMixin(LightningElement) {
    xmlHttp = new XMLHttpRequest();
    @api recordId
    @track toShowModal = false;
    @track ccaseId;
    @track currentCaseSubject;
    @api pagesize;
    @api eventCode;
    @api urlsopensinnewtab;
    searchString2;
    directionText = 'LTR';
    searchStringFromBanner = '';
    CustSetting;
    customSettingsFilled = true;
    defaultlanguage = 'en';
    @api bearer;
    @api uid;
    @api endPoint;
    @api resultPerPage
    @api withwildsearch
    buttonPress = false;
    linkToOpen;
    timer = 0;
    PlaceHolderText = 'Search here';
    @track currentString = '';
    delayCounter = 0;
    index = -1;
    @track autosuggestList = [];
    sIndex = -1;
    lastSuggestionIndex = -1;
    baseSearchString = '';
    @api translationObject;
    @api casesubject;
    @api isWildCardEnabled;
    _searchString = '';
    _autoSuggestionActive = false;
    _selectedTypeFilter;
    _sendDataAttributes;
    @api
    get sendDataAttributes() {
        return this._sendDataAttributes;
    }

    set sendDataAttributes(value) {
        this._sendDataAttributes = value;
    }
    @api
    get selectedTypeFilter() {
        return this._selectedTypeFilter;
    }

    set selectedTypeFilter(value) {
        this._selectedTypeFilter = value;
    }
    @api
    get searchString() {
        return this._searchString;
    }

    set searchString(value) {
        this._searchString = value;
    }
    @api
    get autoSuggestionActive() {
        return this._autoSuggestionActive;
    }

    set autoSuggestionActive(value) {
        this._autoSuggestionActive = value;
    }
    get autosuggestListLength() {
        return this.autosuggestList.Length;
    }
    get getCurrentStringLength() {
        return this.currentString.length > 0 ? true : false;
    }
    handleSearchStringChange(event) {
        this._searchString = event.target.value;
        this.searchString2 = this.searchString;
        this.baseSearchString = event.target.value;
        this.sIndex = -1;
        fireEvent(null, 'stringChangedFromBanner'+this.eventCode, event.target.value);
    }

    starClicked() {
        this.toShowModal = true;
        fireEvent(null, 'starclickedbookmark'+this.eventCode, true);
    }

    connectedCallback() {
        var url = window.location.href;
        var split = url.split("/");
        this.ccaseId = split[split.length - 2];
        var searchVal = sessionStorage.getItem('searchValue');
        this._searchString = searchVal;
        var translation = { "en": { "type": "LTR", "mapping": { "Top Searches": "Top Searches", "Sources": "Sources", "Search here": "Search here", "Advanced Search Options": "Advanced Search Options", "With the exact phrase": "With the exact phrase", "With one or more words": "With one or more words", "Without the words": "Without the words", "Results per page": "Results per page", "Results": "Results", "results": "results", "Refine Search": "Refine Search", "The sequence of words you enter here will be in the same order and together in the search results. You may leave this field empty.": "The sequence of words you enter here will be in the same order and together in the search results. You may leave this field empty.", "Any one, but not necessarily all of the words you enter here will appear in the search results.": "Any one, but not necessarily all of the words you enter here will appear in the search results.", "All Content": "All Content", "Search Tips": "Search Tips", "Enter just a few key words related to your question or problem": "Enter just a few key words related to your question or problem", "Add Key words to refine your search as necessary": "Add Key words to refine your search as necessary", "Do not use punctuation": "Do not use punctuation", "Search is not case sensitive": "Search is not case sensitive", "": "", "If you do not find what you are looking for the first time,reduce the number of key words you enter and try searching again.": "If you do not find what you are looking for the first time,reduce the number of key words you enter and try searching again.", "Minimum supported Internet Explorer version is IE9": "Minimum supported Internet Explorer version is IE9", "Sort by Relevance": "Sort by Relevance", "Sort by Created Date": "Sort by Created Date", "Back to Top": "Back to Top", "List View": "List View", "Grid View": "Grid View", "Next": "Next", "Previous": "Previous", "Showing page": "Showing page", "seconds": "seconds", "Did you mean": "Did you mean", "Show more": "Show more", "We're sorry. We Cannot find any matches for your search term.": "We're sorry. We Cannot find any matches for your search term.", "Showing results using some of your recent search terms": "Showing results using some of your recent search terms", "Top keywords searched": "Top keywords searched", "Ask the Community!": "Ask the Community!", "Let our amazing customer community help": "Let our amazing customer community help", "Need More Help?": "Need More Help?", "Vist the solution finder today": "Vist the solution finder today", "Post a Question": "Post a Question", "Contact Support": "Contact Support", "SOLVED": "SOLVED", "Show less": "Show less", "Narrow your search": "Narrow your search", "Was above result helpful?": "Was above result helpful?", "Recommended Learning": "Recommended Learning", "Thank you for your response!": "Thank you for your response!", "Recommendations": "Recommendations", "Useful Articles": "Useful Articles", "Sort by": "Sort by", "Relevance": "Relevance", "Created Date": "Created Date" } }, "de": { "type": "LTR", "mapping": { "Top Searches": "Top-Suchanfragen", "Sources": "Quellen", "Search here": "Suche hier", "Advanced Search Options": "Erweiterte Suchoptionen", "With the exact phrase": "Mit der exakten Phrase", "With one or more words": "Mit einem oder mehreren Wörtern", "Without the words": "Ohne die Worte", "Results per page": "Ergebnisse pro Seite", "Results": "Ergebnisse", "results": "Ergebnisse", "Refine Search": "Suche einschränken", "The sequence of words you enter here will be in the same order and together in the search results. You may leave this field empty.": "Die Reihenfolge der Wörter, die Sie hier eingeben, wird in der gleichen Reihenfolge und in den Suchergebnissen angezeigt. Sie können dieses Feld leer lassen.", "Any one, but not necessarily all of the words you enter here will appear in the search results.": "Alle, aber nicht unbedingt alle hier eingegebenen Wörter werden in den Suchergebnissen angezeigt.", "All Content": "Alle Inhalte", "Search Tips": "Suchtipps", "Enter just a few key words related to your question or problem": "Geben Sie nur einige Schlüsselwörter ein, die sich auf Ihre Frage oder Ihr Problem beziehen", "Add Key words to refine your search as necessary": "Fügen Sie Schlüsselwörter hinzu, um Ihre Suche nach Bedarf zu verfeinern", "Do not use punctuation": "Verwenden Sie keine Interpunktion", "Search is not case sensitive": "Die Suche unterscheidet nicht zwischen Groß- und Kleinschreibung", "": "", "If you do not find what you are looking for the first time,reduce the number of key words you enter and try searching again.": "Wenn Sie das, was Sie zum ersten Mal suchen, nicht finden, reduzieren Sie die Anzahl der eingegebenen Suchbegriffe und versuchen Sie es erneut.", "Minimum supported Internet Explorer version is IE9": "Minimale unterstützte Internet Explorer-Version ist IE9", "Sort by Relevance": "Sortieren nach Relevanz", "Sort by Created Date": "Nach Erstellungsdatum sortieren", "Back to Top": "Zurück nach oben", "List View": "Listenansicht", "Grid View": "Rasteransicht", "Next": "Nächster", "Previous": "Bisherige", "Showing page": "Seite anzeigen", "seconds": "Sekunden", "Did you mean": "Meintest du", "Show more": "Zeig mehr", "We're sorry. We Cannot find any matches for your search term.": "Es tut uns leid. Wir können keine Übereinstimmungen für Ihren Suchbegriff finden.", "Showing results using some of your recent search terms": "Ergebnisse werden mit einigen Ihrer letzten Suchbegriffe angezeigt", "Top keywords searched": "Top Suchbegriffe gesucht", "Ask the Community!": "Fragen Sie die Gemeinde!", "Let our amazing customer community help": "Lassen Sie sich von unserer großartigen Kundengemeinschaft helfen", "Need More Help?": "Benötigen Sie weitere Hilfe?", "Vist the solution finder today": "Besuchen Sie noch heute den Lösungsfinder", "Post a Question": "Frage stellen", "Contact Support": "Kontaktieren Sie Support", "SOLVED": "Gelöst", "Show less": "Zeige weniger", "Narrow your search": "Grenzen Sie Ihre Suche ein", "Was above result helpful?": "War das Ergebnis hilfreich?", "Recommended Learning": "Empfohlenes Lernen", "Thank you for your response!": "Danke für Ihre Antwort!", "Recommendations": "Empfehlungen", "Useful Articles": "Nützliche Artikel", "Sort by": "Sortiere nach", "Relevance": "Relevanz", "Created Date": "Erstellungsdatum" } }, "fr": { "type": "LTR", "mapping": { "Top Searches": "Top recherches", "Sources": "Sources", "Search here": "Cherche ici", "Advanced Search Options": "Options de recherche avancée", "With the exact phrase": "Avec la phrase exacte", "With one or more words": "Avec un ou plusieurs mots", "Without the words": "Sans les mots", "Results per page": "résultats par page", "Results": "Résultats", "results": "résultats", "Refine Search": "Affiner votre recherche", "The sequence of words you enter here will be in the same order and together in the search results. You may leave this field empty.": "La séquence de mots que vous entrez ici sera dans le même ordre et ensemble dans les résultats de la recherche. Vous pouvez laisser ce champ vide.", "Any one, but not necessarily all of the words you enter here will appear in the search results.": "Tous les mots que vous entrez ici, mais pas nécessairement tous, apparaîtront dans les résultats de la recherche.", "All Content": "Tout le contenu", "Search Tips": "Astuces de recherche", "Enter just a few key words related to your question or problem": "Entrez seulement quelques mots clés liés à votre question ou à votre problème", "Add Key words to refine your search as necessary": "Ajoutez des mots-clés pour affiner votre recherche si nécessaire", "Do not use punctuation": "Ne pas utiliser la ponctuation", "Search is not case sensitive": "La recherche n'est pas sensible à la casse", "": "", "If you do not find what you are looking for the first time,reduce the number of key words you enter and try searching again.": "Si vous ne trouvez pas ce que vous cherchez pour la première fois, réduisez le nombre de mots-clés que vous avez saisis et relancez la recherche.", "Minimum supported Internet Explorer version is IE9": "La version minimale prise en charge d'Internet Explorer est IE9.", "Sort by Relevance": "Trier par pertinence", "Sort by Created Date": "Trier par date de création", "Back to Top": "Retour au sommet", "List View": "Voir la liste", "Grid View": "Vue grille", "Next": "Suivant", "Previous": "Précédent", "Showing page": "Afficher la page", "seconds": "seconds", "Did you mean": "Vouliez-vous dire", "Show more": "Montre plus", "We're sorry. We Cannot find any matches for your search term.": "Nous sommes désolés. Nous ne trouvons aucune correspondance pour votre terme de recherche.", "Showing results using some of your recent search terms": "Afficher les résultats en utilisant certains de vos termes de recherche récents", "Top keywords searched": "Top mots-clés recherchés", "Ask the Community!": "Demandez à la communauté!", "Let our amazing customer community help": "Laissez notre incroyable communauté de clients aider", "Need More Help?": "Besoin d'aide?", "Vist the solution finder today": "Visitez le solutionneur dès aujourd'hui", "Post a Question": "Publier une question", "Contact Support": "Contactez le support", "SOLVED": "Résolu", "Show less": "Montre moins", "Narrow your search": "Affinez votre recherche", "Was above result helpful?": "Le résultat ci-dessus a-t-il été utile?", "Recommended Learning": "Apprentissage recommandé", "Thank you for your response!": "Merci pour votre réponse!", "Recommendations": "Recommandations", "Useful Articles": "Articles utiles", "Sort by": "Trier par", "Relevance": "Pertinence", "Created Date": "Date de création" } }, "sp": { "type": "LTR", "mapping": { "Top Searches": "", "Sources": "", "Search here": "", "Advanced Search Options": "", "With the exact phrase": "", "With one or more words": "", "Without the words": "", "Results per page": "", "Results": "", "results": "", "Refine Search": "", "The sequence of words you enter here will be in the same order and together in the search results. You may leave this field empty.": "", "Any one, but not necessarily all of the words you enter here will appear in the search results.": "", "All Content": "", "Search Tips": "", "Enter just a few key words related to your question or problem": "", "Add Key words to refine your search as necessary": "", "Do not use punctuation": "", "Search is not case sensitive": "", "": "", "If you do not find what you are looking for the first time,reduce the number of key words you enter and try searching again.": "", "Minimum supported Internet Explorer version is IE9": "", "Sort by Relevance": "", "Sort by Created Date": "", "Back to Top": "", "List View": "", "Grid View": "", "Next": "", "Previous": "", "Showing page": "", "seconds": "", "Did you mean": "", "Show more": "", "We're sorry. We Cannot find any matches for your search term.": "", "Showing results using some of your recent search terms": "", "Top keywords searched": "", "Ask the Community!": "", "Let our amazing customer community help": "", "Need More Help?": "", "Vist the solution finder today": "", "Post a Question": "", "Contact Support": "", "SOLVED": "", "Show less": "", "Narrow your search": "", "Was above result helpful?": "", "Recommended Learning": "", "Thank you for your response!": "", "Recommendations": "", "Useful Articles": "", "Sort by": "", "Relevance": "", "Created Date": "" } }, "zh": { "type": "LTR", "mapping": { "Top Searches": "热门搜索", "Sources": "来源", "Search here": "在这里搜索", "Advanced Search Options": "高级搜索选项", "With the exact phrase": "用确切的短语", "With one or more words": "用一个或多个单词", "Without the words": "没有话语", "Results per page": "每页结果", "Results": "结果", "results": "结果", "Refine Search": "优化搜索", "The sequence of words you enter here will be in the same order and together in the search results. You may leave this field empty.": "您在此处输入的单词序列将在搜索结果中以相同的顺序排列。 您可以将此字段留空。", "Any one, but not necessarily all of the words you enter here will appear in the search results.": "您输入的任何一个，但不一定是所有单词都将出现在搜索结果中。", "All Content": "所有内容", "Search Tips": "搜索提示", "Enter just a few key words related to your question or problem": "输入与您的问题或问题相关的几个关键词", "Add Key words to refine your search as necessary": "添加关键字以根据需要优化搜索", "Do not use punctuation": "不要使用标点符号", "Search is not case sensitive": "搜索不区分大小写", "": "", "If you do not find what you are looking for the first time,reduce the number of key words you enter and try searching again.": "如果您第一次找不到所需内容，请减少您输入的关键字数量，然后重新尝试搜索。", "Minimum supported Internet Explorer version is IE9": "支持的最低Internet Explorer版本是IE9", "Sort by Relevance": "按相关性排序", "Sort by Created Date": "按创建日期排序", "Back to Top": "回到顶部", "List View": "列表显示", "Grid View": "网格视图", "Next": "下一个", "Previous": "以前", "Showing page": "显示页面", "seconds": "秒", "Did you mean": "你的意思是", "Show more": "显示更多", "We're sorry. We Cannot find any matches for your search term.": "我们很抱歉。 我们找不到您搜索字词的匹配项。", "Showing results using some of your recent search terms": "使用您最近的一些搜索字词显示结果", "Top keywords searched": "搜索热门关键词", "Ask the Community!": "问社区！", "Let our amazing customer community help": "让我们惊人的客户社区帮助", "Need More Help?": "需要更多帮助？", "Vist the solution finder today": "立即访问解决方案查找器", "Post a Question": "发表一个问题", "Contact Support": "联系支持", "SOLVED": "解决了", "Show less": "显示较少", "Narrow your search": "缩小搜索范围", "Was above result helpful?": "以上结果有用吗？", "Recommended Learning": "推荐学习", "Thank you for your response!": "感谢您的答复！", "Recommendations": "建议", "Useful Articles": "有用的文章", "Sort by": "排序方式", "Relevance": "关联", "Created Date": "创建日期" } }, "hi": { "type": "LTR", "mapping": { "Top Searches": "", "Sources": "", "Search here": "", "Advanced Search Options": "", "With the exact phrase": "", "With one or more words": "", "Without the words": "", "Results per page": "", "Results": "", "results": "", "Refine Search": "", "The sequence of words you enter here will be in the same order and together in the search results. You may leave this field empty.": "", "Any one, but not necessarily all of the words you enter here will appear in the search results.": "", "All Content": "", "Search Tips": "", "Enter just a few key words related to your question or problem": "", "Add Key words to refine your search as necessary": "", "Do not use punctuation": "", "Search is not case sensitive": "", "": "", "If you do not find what you are looking for the first time,reduce the number of key words you enter and try searching again.": "", "Minimum supported Internet Explorer version is IE9": "", "Sort by Relevance": "", "Sort by Created Date": "", "Back to Top": "", "List View": "", "Grid View": "", "Next": "", "Previous": "", "Showing page": "", "seconds": "", "Did you mean": "", "Show more": "", "We're sorry. We Cannot find any matches for your search term.": "", "Showing results using some of your recent search terms": "", "Top keywords searched": "", "Ask the Community!": "", "Let our amazing customer community help": "", "Need More Help?": "", "Vist the solution finder today": "", "Post a Question": "", "Contact Support": "", "SOLVED": "", "Show less": "", "Narrow your search": "", "Was above result helpful?": "", "Recommended Learning": "", "Thank you for your response!": "", "Recommendations": "", "Useful Articles": "", "Sort by": "", "Relevance": "", "Created Date": "" } }, "ar": { "type": "RTL", "mapping": { "Top Searches": "أعلى عمليات البحث", "Sources": "مصادر", "Search here": "ابحث هنا", "Advanced Search Options": "خيارات البحث المتقدم", "With the exact phrase": "مع العبارة بالضبط", "With one or more words": "مع كلمة واحدة أو أكثر", "Without the words": "دون كلام", "Results per page": "النتائج لكل صفحة", "Results": "النتائج", "results": "النتائج", "Refine Search": "خيارات البحث", "The sequence of words you enter here will be in the same order and together in the search results. You may leave this field empty.": "سيكون تسلسل الكلمات التي تدخلها بنفس الترتيب ومعاينة نتائج البحث. بأمكانك ترك هذا الحقل فارغا.", "Any one, but not necessarily all of the words you enter here will appear in the search results.": "أي واحد ، ولكن ليس بالضرورة جميع الكلمات التي تدخلها هنا سوف تظهر في نتائج البحث.", "All Content": "كل المحتوى", "Search Tips": "نصائح البحث", "Enter just a few key words related to your question or problem": "أدخل فقط بضع كلمات رئيسية متعلقة بسؤالك أو مشكلتك", "Add Key words to refine your search as necessary": "أضف كلمات مفتاحية لتنقيح بحثك حسب الضرورة", "Do not use punctuation": "لا تستخدم علامات الترقيم", "Search is not case sensitive": "البحث ليس حساسًا لحالة الأحرف", "": "", "If you do not find what you are looking for the first time,reduce the number of key words you enter and try searching again.": "إذا لم تجد ما تبحث عنه لأول مرة ، فقم بتخفيض عدد الكلمات الرئيسية التي أدخلتها وحاول البحث مرة أخرى.", "Minimum supported Internet Explorer version is IE9": "الحد الأدنى من إصدار Internet Explorer المدعوم هو IE9", "Sort by Relevance": "فرز حسب الصلة", "Sort by Created Date": "فرز حسب تاريخ الإنشاء", "Back to Top": "العودة إلى الأعلى", "List View": "عرض القائمة", "Grid View": "عرض الشبكة", "Next": "التالى", "Previous": "سابق", "Showing page": "عرض الصفحة", "seconds": "ثواني", "Did you mean": "هل تعني", "Show more": "أظهر المزيد", "We're sorry. We Cannot find any matches for your search term.": "نحن آسفون. لا يمكننا العثور على أي تطابقات لعبارة البحث الخاصة بك.", "Showing results using some of your recent search terms": "عرض النتائج باستخدام بعض مصطلحات البحث الأخيرة", "Top keywords searched": "أهم الكلمات الرئيسية التي تم البحث عنها", "Ask the Community!": "اسأل المجتمع!", "Let our amazing customer community help": "دع مجتمعنا المدهش يساعد المجتمع", "Need More Help?": "هل تريد المزيد من المساعدة؟", "Vist the solution finder today": "زيارة مكتشف الحلول اليوم", "Post a Question": "ارسل سؤال", "Contact Support": "اتصل بالدعم", "SOLVED": "تم حلها", "Show less": "عرض أقل", "Narrow your search": "تضييق نطاق البحث", "Was above result helpful?": "كانت النتيجة أعلاه مفيدة؟", "Recommended Learning": "التعلم الموصى به", "Thank you for your response!": "شكرا لردكم!", "Recommendations": "توصيات", "Useful Articles": "مقالات مفيدة", "Sort by": "ترتيب حسب", "Relevance": "ملاءمة", "Created Date": "تاريخ الإنشاء" } }, "config": { "defaultLanguage": { "code": "en", "name": "English", "label": "English" }, "selectedLanguages": [{ "code": "en", "name": "English", "label": "English" }] } };
        if (translation[window.localStorage.getItem("language")]) {
            this.directionText = translation[window.localStorage.getItem("language")].type;
        }

        registerListener('closeIcon'+this.eventCode, this.closeIcon, this);
        registerListener('setsearchstring'+this.eventCode, this.setSearchString2, this);

    }
    setSearchString2(data) {
            this.searchString2 = data;
            this.searchStringFromBanner = this.searchString2;
            fireEvent(null,'setGPTValue'+this.eventCode,this.searchStringFromBanner);
    }
    closeIcon() {
        this.toShowModal = false;
        fireEvent(null, 'starclickedbookmark'+this.eventCode, false);
    }

    submitForm(event) {
        event.preventDefault();
        this.buttonPress = true;
        this.autosuggestList = [];
        this.searchStringFromBanner = this.searchString2;
        fireEvent(null,'setGPTValue'+this.eventCode,this.searchStringFromBanner);
        if(!this.autoSuggestionActive){
             fireEvent(this.pageRef, 'searchPage'+this.eventCode, { searchString: this.searchString2, isFreshSearch: -1 , isActiveSearch:true});
        }
    }
    invokeWorkspaceAPI(methodName, methodArgs) {
        return new Promise((resolve, reject) => {
            const apiEvent = new CustomEvent("internalapievent", {
                bubbles: true,
                composed: true,
                cancelable: false,
                detail: {
                    category: "workspaceAPI",
                    methodName: methodName,
                    methodArgs: methodArgs,
                    callback: (err, response) => {
                        if (err) {
                            return reject(err);
                        } 
                        return resolve(response);
                    }
                }
            });
            window.dispatchEvent(apiEvent);
        });
    }

    autoSuggestionClick(e) {
        if (typeof this.selectedTypeFilter == 'string') {
            this._selectedTypeFilter = JSON.parse(this.selectedTypeFilter);
        }
        var sendData ={
            'page_no': 0,
            'filter': this.selectedTypeFilter ? this.selectedTypeFilter : [],
            'result_count': this.autosuggestList && this.autosuggestList.length,
            'conversion': [{
                rank: parseInt(e.currentTarget && e.currentTarget.dataset ? e.currentTarget.dataset.rank : e.rank,10) + 1,
                url: e.currentTarget && e.currentTarget.dataset ? e.currentTarget.dataset.url : e.url,
                subject:e.currentTarget && e.currentTarget.dataset ?  (e.currentTarget.dataset.subject || e.currentTarget.dataset.url) : e.convSub ,
                es_id: (e.currentTarget && e.currentTarget.dataset ? e.currentTarget.dataset.index : e.index) + '/' + (e.currentTarget ? e.currentTarget.dataset.type : e.type) + '/'+ encodeURIComponent(e.currentTarget ? e.currentTarget.dataset.value : e.value)

            }]
        }
        fireEvent(null, 'trackAnalytics' + this.eventCode, {
            type: 'autocomplete', objToSend: sendData
        });

        if (e.value || (e.currentTarget && e.currentTarget.dataset)) {
            var href = e.url || e.currentTarget.dataset.url;
            if (e.value || (e.currentTarget && e.currentTarget.dataset && e.currentTarget.dataset.value)) {
                var id
                if (e.currentTarget) {
                    id = e.currentTarget.dataset.value.split('__')[0];
                }
                if (e.value) {
                    id = e.value.split('__')[0];
                }
            }
            var object = e.currentTarget && e.currentTarget.dataset ? e.currentTarget.dataset.type : e.type;
        }
        if (this.urlsopensinnewtab) {
            this.setAugoSuggestFalse(href);

        }
        else if (object === 'case' || object.toLowerCase().slice(-5) === '__kav') {
            this.invokeWorkspaceAPI('isConsoleNavigation').then(isConsole => {
                if (isConsole) {
                    this.invokeWorkspaceAPI('getFocusedTabInfo').then(focusedTab => {
                        this.invokeWorkspaceAPI('openSubtab', {
                            parentTabId: focusedTab.isSubtab ? focusedTab.parentTabId : focusedTab.tabId,
                            recordId: id,
                            focus: true
                        }).then(() => { })
                        .catch(() => {
                            this.invokeWorkspaceAPI('openTab', {
                                recordId: id,
                                focus: true
                            }).then(() => { });
                        });
                    });
                }
            });
        } else {
            this.setAugoSuggestFalse(href);
        }
    }

    setAugoSuggestFalse(href){
        window.open(href, "_blank");
        this._autoSuggestionActive = false;
    }

    searchButtonPressFunc() {
        var SearchQuery = this.searchString;
        if (SearchQuery != null && SearchQuery !== '' && SearchQuery !== undefined) {
            SearchQuery = SearchQuery.trim();
            if (SearchQuery.length > 1 &&  this.template.querySelector('[data-id="su-suggestions"]')&&this.template.querySelector('[data-id="su-suggestions"]').classList) {
                this.template.querySelector('[data-id="su-suggestions"]').classList.add('su-hidePanel');
                this.index = -1;
                clearTimeout(this.timer);
            }
        }
    }
    
    enterKeySearch(event) {
        this.index = -1;
        let self = this;
        sessionStorage.setItem('searchValue', event.target.value);
        var SearchQuery = this.searchString;
        if (SearchQuery != null && SearchQuery !== '' && SearchQuery !== undefined) {
            SearchQuery = SearchQuery.trim();
        }
        if (SearchQuery != null && SearchQuery !== '' && SearchQuery !== undefined && SearchQuery.length > 1) {
            if (event.keyCode === 13) {
                if(this.currentString !== this.searchString){ 
                    if(this.isWildCardEnabled){
                        this.currentString = this.withwildsearch;
                    }
                    this._searchString = this.currentString;
                    fireEvent(null, 'setsearchstring'+this.eventCode, this.searchString);
                    this.autoSuggestionClick(this.sendDataAttributes);
                }else{
                    this.submitForm(event) ;
                }
                if(this.template.querySelector(`[data-id="su-suggestions"]`) && this.template.querySelector(`[data-id="su-suggestions"]`).classList ){
                    this.template.querySelector(`[data-id="su-suggestions"]`).classList.add('su-hidePanel');
                }

                clearTimeout(this.timer);
            } else if (event.keyCode !== 37 && event.keyCode !== 38 && event.keyCode !== 39 && event.keyCode !== 40) {
                this.currentString = this.searchString;
                this._autoSuggestionActive = false;
                this.linkToOpen = null;
                var delayCounter = this.delayCounter;
                var timer = this.timer;
                this.buttonPress = false;
                clearTimeout(timer);
                if (delayCounter === 0) {
                    this.delayCounter = 1;
                    self.xmlHttp.abort();
                    timer = window.setTimeout(function () {
                        SearchQuery = self.searchString;
                        if(SearchQuery){
                            SearchQuery = SearchQuery.trim();
                        }
                        if (SearchQuery !== '' && self.customSettingsFilled && self.bearer) {
                            self.autosearchFunc('autosuggestion', 'false');
                        }
                        clearTimeout(timer);
                        this.timer = null;
                    }, 1000);
                    this.index = -1;
                    this.timer = timer;
                    this.delayCounter = 0;
                }
            } 
        }
    }
    async autosearchFunc(searchType) {
        this._autoSuggestionActive = false;
        this.sIndex = -1;
        let self = this;
        self.autosuggestList = [];
        if (typeof this.selectedTypeFilter === 'string') {
            try {
                this._selectedTypeFilter = JSON.parse(this.selectedTypeFilter);
            } catch (error) {
                console.error("An error occurred while parsing the JSON:", error);
            }
        }
        var searchText = this.searchString && this.searchString.length && this.searchString.trim();
        var data = {
            "searchString": searchText,
            "from": 0,
            "pageNum": 1,
            "sortby": "_score",
            "orderBy": "desc",
            "resultsPerPage": this.resultPerPage ? parseInt(this.resultPerPage,10): "10",
            "aggregations": this.selectedTypeFilter ? this.selectedTypeFilter : [],
            "referrer": document.referrer,
            "exactPhrase": "",
            "withOneOrMore": "",
            "withoutTheWords": "",
            "recommendResult": "",
            "indexEnabled": false,
            "sid": window._gr_utility_functions.getCookie("_gz_taid"),
            "language": localStorage.getItem('language') || 'en',
            "autocomplete": true
        };
        let query = JSON.parse(JSON.stringify(data));
        if(this.casesubject !== this.searchString  && this.isWildCardEnabled){
            query.searchString = this.searchString;
            let hashExists = query.searchString.charAt(0)
            if(hashExists === '#'){
                query.searchString = searchText
            }else{
                query.searchString = '#' + searchText;
            }
            data = JSON.parse(JSON.stringify(query));
        }
        let result = await makeSearchCall(data);
        if (result.statusCode !== 402) {
            var total = result.result.total;
            self.totalResults = total;
            if (searchType === 'autosuggestion' && !self.buttonPress) {
                self.autosuggestList = result.result.hits;
                if(self.autosuggestList) {
                    for (var i = 0; i < self.autosuggestList.length; i++) {
                        for (var j = 0; j < self.autosuggestList[i].autosuggestData.length; j++) {
                            if(self.autosuggestList[i]?.autosuggestData[j]?.value?.[0]?.length === 0) {
                                Object.assign(self.autosuggestList[i].autosuggestData[j], {'metaValue':false})
                            }else{
                                Object.assign(self.autosuggestList[i].autosuggestData[j], {'metaValue':true})
                            }
                            
                            if (self.autosuggestList[i].autosuggestData[j].key === 'post_time') {
                                Object.assign(self.autosuggestList[i].autosuggestData[j], { 'metaKeyValBoolean': true });// {!if(metadata.key == 'post_time',true,false)}
                                Object.assign(self.autosuggestList[i].autosuggestData[j], { 'metaKeyVal': 'Created Date' });// {!if(metadata.key == 'post_time','Created Date',metadata.key)}
                            }
                            else {
                                if(self.autosuggestList[i].autosuggestData[j].key !== 'Title' && self.autosuggestList[i].autosuggestData[j].key !== 'Description'){
                                    Object.assign(self.autosuggestList[i].autosuggestData[j], { 'metaKeyValBoolean': false });// {!if(metadata.key == 'post_time',true,false)}
                                    Object.assign(self.autosuggestList[i].autosuggestData[j], { 'metaKeyVal': self.autosuggestList[i].autosuggestData[j].key });// {!if(metadata.key == 'post_time','Created Date',metadata.key)}
                                }
                                if(self.autosuggestList[i].autosuggestData[j].key === 'Title' || self.autosuggestList[i].autosuggestData[j].key === 'Description'){
                                    self.autosuggestList[i].autosuggestData[j].value.splice(0);  //why ?
                                }
                            }
                        }
                        Object.assign(self.autosuggestList[i], { 'autosuggestTitleToDisplay': self.autosuggestList[i].highlight.TitleToDisplay[0] || self.autosuggestList[i].href });//{!autosuggestItem.highlight.TitleToDisplay[0] || autosuggestItem.href}
                    }
                }

                if (self.autosuggestList.length > 0 && self.template.querySelector(`[data-id="autosuggestElement"]`) !== null &&  self.template.querySelector(`[data-id="autosuggestElement"]`) !== undefined && self.template.querySelector(`[data-id="su-suggestions"]`).classList ) {//!$A.util.isEmpty("v.autosuggestList") && document.getElementById('autosuggestElement') !== null && document.getElementById('autosuggestElement') !== undefined
                    self.template.querySelector(`[data-id="su-suggestions"]`).classList.remove('su-hidePanel');
                    self.template.querySelector(`[data-id="autosuggestElement"]`).style.display = 'block';
                    if (self.template.querySelector(`[data-id="autosuggestAutoElement"]`) !== null && self.template.querySelector(`[data-id="autosuggestAutoElement"]`) !== undefined) {
                        self.template.querySelector(`[data-id="autosuggestAutoElement"]`).style.display = 'block';
                    }
                }
            }
        } 
    }
    mouseleft() {
        let self = this;
        setTimeout(function () {
            if (self.template.querySelector('[data-id="autosuggestElement"]') !== null && self.template.querySelector('[data-id="autosuggestElement"]') !== undefined) {
                self.template.querySelector('[data-id="autosuggestElement"]').style.display = 'none';
                self.autosuggestList = [];
            }
        }, 500);
    }
    onfocus() {
        var input = this.template.querySelector('[data-id="form-search"]');
        if (input.getAttribute("autocomplete") !== "off") {
            input.setAttribute("autocomplete", "off");
        }
    }
    deleteSearch() {
        this.searchString2 = '';
        this._searchString = '';
        this.autosuggestList = [];
        fireEvent(this.pageRef, 'clearSearch'+this.eventCode);
    }
    setFocus(element){
        setTimeout(() => {
            element && element.focus && element.focus();
        })
    }

    decodeEntityCharacters(inputText){
        const parser = new DOMParser();
        const parsedData = parser.parseFromString(inputText,'text/html');
        let decodedValue = parsedData.body.textContent || '';
        this.searchString2 = decodedValue;
    }

    handleKeyDown(e) {
        if(this.template.querySelectorAll(".su-autoSuggest-element")){
            if(this.template.querySelectorAll(".su-autoSuggest-element").length !== 0) {
                var autoSuggestElement = this.template.querySelectorAll(".su-autoSuggest-element");
                this.lastSuggestionIndex = this.template.querySelectorAll(".su-autoSuggest-element").length - 1;
                if (e.keyCode === 40) {
                    if (this.sIndex === -1) {
                        var x = autoSuggestElement[++this.sIndex];
                    if(x && x.classList){
                            x.classList.add("su__autoSuggestion-active");
                            this._autoSuggestionActive = true;
                            this._sendDataAttributes = {
                                index: x.getAttribute('data-index'),
                                type: x.getAttribute('data-type'),
                                recordid: x.getAttribute('data-recordid'),
                                rank: x.getAttribute('data-rank'),
                                convUrl: x.getAttribute('data-url'),
                                convSub: x.getAttribute('data-subject'),
                                autoTuned: x.getAttribute('data-auto'),
                                url: x.getAttribute('data-url'),
                                value: x.getAttribute('data-value'),
                            }
                        }
                        this.onfocus();
                    if( this.template.querySelector(`[data-id="autosuggestElement"]`)&&this.template.querySelector(".su__autoSuggestion-active")&& this.template.querySelector(".su__autoSuggestion-active").offsetTop && this.template.querySelector(".su__autoSuggestion-active").offsetHeight ){
                            this.template.querySelector(`[data-id="autosuggestElement"]`).scrollTop = this.template.querySelector(".su__autoSuggestion-active").offsetTop + this.template.querySelector(".su__autoSuggestion-active").offsetHeight - this.template.querySelector(`[data-id="autosuggestElement"]`).offsetHeight / 2;///document.getElementById("autosuggestElement").scrollTop = document.querySelector(".su-autoSuggest-element.selected").offsetTop + document.querySelector(".su-autoSuggest-element.selected").offsetHeight -document.getElementById("autosuggestElement").offsetHeight;

                        }
                    if(x && x.getAttribute('data-id')){
                            this.searchString2 = x.getAttribute('data-id').replace(/(<([^>]+)>)/ig, '');
                            this.decodeEntityCharacters(this.searchString2);
                        }
                        this._searchString = this.searchString2;
                        if (this.template.querySelectorAll('lightning-input[data-id="searchBoxInput"]')) {
                        let searchInputbox   = this.template.querySelectorAll(`lightning-input[data-id="searchBoxInput"]`);
                            this.setFocus(searchInputbox);
                        }
                    }
                    else if (this.sIndex === this.lastSuggestionIndex) {
                        this.searchString2 = this.baseSearchString;
                        this._searchString = this.searchString2;
                         x = autoSuggestElement[this.sIndex];
                    if(x && x.classList){
                            x.classList.remove("su__autoSuggestion-active");
                            this._autoSuggestionActive = false;
                            this._sendDataAttributes = {
                                index: x.getAttribute('data-index'),
                                type: x.getAttribute('data-type'),
                                recordid: x.getAttribute('data-recordid'),
                                rank: x.getAttribute('data-rank'),
                                convUrl: x.getAttribute('data-url'),
                                convSub: x.getAttribute('data-subject'),
                                autoTuned: x.getAttribute('data-auto'),
                                url: x.getAttribute('data-url'),
                                value: x.getAttribute('data-value'),
                            }
                        }
                        this.sIndex = -1;
                     if( this.template.querySelector(`[data-id="autosuggestElement"]`)&& this.template.querySelector(".su__autoSuggestion-active") && this.template.querySelector(".su__autoSuggestion-active").offsetTop && this.template.querySelector(".su__autoSuggestion-active").offsetHeight ){
                            this.template.querySelector(`[data-id="autosuggestElement"]`).scrollTop = this.template.querySelector(".su__autoSuggestion-active").offsetTop + this.template.querySelector(".su__autoSuggestion-active").offsetHeight - this.template.querySelector(`[data-id="autosuggestElement"]`).offsetHeight / 2;///document.getElementById("autosuggestElement").scrollTop = document.querySelector(".su-autoSuggest-element.selected").offsetTop + document.querySelector(".su-autoSuggest-element.selected").offsetHeight -document.getElementById("autosuggestElement").offsetHeight;
                        }
                        if (this.template.querySelectorAll('lightning-input[data-id="searchBoxInput"]')) {
                            let searchInputbox = this.template.querySelectorAll('lightning-input[data-id="searchBoxInput"]');
                            this.setFocus(searchInputbox);

                        }
                    }
                    else {
                    if( autoSuggestElement && autoSuggestElement[this.sIndex] && autoSuggestElement[this.sIndex].classList ){
                            autoSuggestElement[this.sIndex].classList.remove("su__autoSuggestion-active");
                        }
                         x = autoSuggestElement[++this.sIndex];
                    if(x && x.classList){
                            x.classList.add("su__autoSuggestion-active");
                            this._autoSuggestionActive = true;
                            this._sendDataAttributes = {
                                index: x.getAttribute('data-index'),
                                type: x.getAttribute('data-type'),
                                recordid: x.getAttribute('data-recordid'),
                                rank: x.getAttribute('data-rank'),
                                convUrl: x.getAttribute('data-url'),
                                convSub: x.getAttribute('data-subject'),
                                autoTuned: x.getAttribute('data-auto'),
                                url: x.getAttribute('data-url'),
                                value: x.getAttribute('data-value'),
                            }
                        }
                        this.onfocus();
                   if(x && x.getAttribute('data-id')){
                            this.searchString2 = x.getAttribute('data-id').replace(/(<([^>]+)>)/ig, '');
                            this.decodeEntityCharacters(this.searchString2);
                        }
                        this._searchString = this.searchString2;
                     if( this.template.querySelector(`[data-id="autosuggestElement"]`)&& this.template.querySelector(".su__autoSuggestion-active") && this.template.querySelector(".su__autoSuggestion-active").offsetTop && this.template.querySelector(".su__autoSuggestion-active").offsetHeight ){
                            this.template.querySelector(`[data-id="autosuggestElement"]`).scrollTop = this.template.querySelector(".su__autoSuggestion-active").offsetTop + this.template.querySelector(".su__autoSuggestion-active").offsetHeight - this.template.querySelector(`[data-id="autosuggestElement"]`).offsetHeight / 2;///document.getElementById("autosuggestElement").scrollTop = document.querySelector(".su-autoSuggest-element.selected").offsetTop + document.querySelector(".su-autoSuggest-element.selected").offsetHeight -document.getElementById("autosuggestElement").offsetHeight;
                        }
                        if (this.template.querySelectorAll('lightning-input[data-id="searchBoxInput"]')) {
                            let searchInputbox = this.template.querySelectorAll('lightning-input[data-id="searchBoxInput"]');
                            this.setFocus(searchInputbox);
                        }
                    }

                } else if (e.keyCode === 38) {
                    if (this.sIndex === -1) {
                        this.sIndex = this.lastSuggestionIndex;
                         x = autoSuggestElement[this.sIndex];
                    if(x && x.classList){
                            x.classList.add("su__autoSuggestion-active");
                            this._autoSuggestionActive = true;
                            this._sendDataAttributes = {
                        index : x.getAttribute('data-index'),
                        type : x.getAttribute('data-type'),
                        recordid : x.getAttribute('data-recordid'),
                        rank : x.getAttribute('data-rank'),
                                convUrl: x.getAttribute('data-url'),
                                convSub: x.getAttribute('data-subject'),
                                autoTuned: x.getAttribute('data-auto'),
                                url: x.getAttribute('data-url'),
                                value: x.getAttribute('data-value'),
                            }
                        }
                        this.onfocus();
                    if(x && x.getAttribute('data-id') ){
                            this.searchString2 = x.getAttribute('data-id').replace(/(<([^>]+)>)/ig, '');
                            this.decodeEntityCharacters(this.searchString2);
                        }
                        this._searchString = this.searchString2;
                     if( this.template.querySelector(`[data-id="autosuggestElement"]`)&& this.template.querySelector(".su__autoSuggestion-active") && this.template.querySelector(".su__autoSuggestion-active").offsetTop && this.template.querySelector(".su__autoSuggestion-active").offsetHeight ){
                            this.template.querySelector(`[data-id="autosuggestElement"]`).scrollTop = this.template.querySelector(".su__autoSuggestion-active").offsetTop + this.template.querySelector(".su__autoSuggestion-active").offsetHeight - this.template.querySelector(`[data-id="autosuggestElement"]`).offsetHeight / 2;///document.getElementById("autosuggestElement").scrollTop = document.querySelector(".su-autoSuggest-element.selected").offsetTop + document.querySelector(".su-autoSuggest-element.selected").offsetHeight -document.getElementById("autosuggestElement").offsetHeight;
                        }
                        if (this.template.querySelectorAll('lightning-input[data-id="searchBoxInput"]')) {
                            let searchInputbox = this.template.querySelectorAll('lightning-input[data-id="searchBoxInput"]');
                            this.setFocus(searchInputbox);
                        }
                    }
                    else if (this.sIndex === 0) {
                         x = autoSuggestElement[this.sIndex];
                    if(x && x.classList){
                            x.classList.remove("su__autoSuggestion-active");
                            this._autoSuggestionActive = false;
                            this._sendDataAttributes = {
                        index : x.getAttribute('data-index'),
                        type : x.getAttribute('data-type'),
                        recordid : x.getAttribute('data-recordid'),
                        rank : x.getAttribute('data-rank'),
                                convUrl: x.getAttribute('data-url'),
                                convSub: x.getAttribute('data-subject'),
                                autoTuned: x.getAttribute('data-auto'),
                                url: x.getAttribute('data-url'),
                                value: x.getAttribute('data-value'),
                            }
                        }
                        this.sIndex = -1;
                        this.searchString2 = this.baseSearchString;
                        this._searchString = this.searchString2;
                     if( this.template.querySelector(`[data-id="autosuggestElement"]`)&& this.template.querySelector(".su__autoSuggestion-active") && this.template.querySelector(".su__autoSuggestion-active").offsetTop && this.template.querySelector(".su__autoSuggestion-active").offsetHeight ){
                    this.template.querySelector(`[data-id="autosuggestElement"]`).scrollTop = this.template.querySelector(".su__autoSuggestion-active").offsetTop + this.template.querySelector(".su__autoSuggestion-active").offsetHeight - this.template.querySelector(`[data-id="autosuggestElement"]`).offsetHeight / 2 ;///document.getElementById("autosuggestElement").scrollTop = document.querySelector(".su-autoSuggest-element.selected").offsetTop + document.querySelector(".su-autoSuggest-element.selected").offsetHeight -document.getElementById("autosuggestElement").offsetHeight;
                        }
                        if (this.template.querySelectorAll('lightning-input[data-id="searchBoxInput"]')) {
                            let searchInputbox = this.template.querySelectorAll('lightning-input[data-id="searchBoxInput"]');
                            this.setFocus(searchInputbox);
                        }
                    }
                    else {
                    if(autoSuggestElement &&  autoSuggestElement[this.sIndex] && autoSuggestElement[this.sIndex].classList ){
                            autoSuggestElement[this.sIndex].classList.remove("su__autoSuggestion-active");
                        }
                         x = autoSuggestElement[--this.sIndex];
                    if(x && x.classList){
                            x.classList.add("su__autoSuggestion-active");
                            this._autoSuggestionActive = true;
                            this._sendDataAttributes = {
                        index : x.getAttribute('data-index'),
                        type : x.getAttribute('data-type'),
                        recordid : x.getAttribute('data-recordid'),
                        rank : x.getAttribute('data-rank'),
                                convUrl: x.getAttribute('data-url'),
                                convSub: x.getAttribute('data-subject'),
                                autoTuned: x.getAttribute('data-auto'),
                                url: x.getAttribute('data-url'),
                                value: x.getAttribute('data-value'),
                            }
                        }
                        this.onfocus();
                    if(x && x.getAttribute('data-id') ){
                            this.searchString2 = x.getAttribute('data-id').replace(/(<([^>]+)>)/ig, '');
                            this.decodeEntityCharacters(this.searchString2);
                        }
                        this._searchString = this.searchString2;
                     if( this.template.querySelector(`[data-id="autosuggestElement"]`)&& this.template.querySelector(".su__autoSuggestion-active") &&  this.template.querySelector(".su__autoSuggestion-active").offsetTop && this.template.querySelector(".su__autoSuggestion-active").offsetHeight ){
                            this.template.querySelector(`[data-id="autosuggestElement"]`).scrollTop = this.template.querySelector(".su__autoSuggestion-active").offsetTop + this.template.querySelector(".su__autoSuggestion-active").offsetHeight - this.template.querySelector(`[data-id="autosuggestElement"]`).offsetHeight / 2;///document.getElementById("autosuggestElement").scrollTop = document.querySelector(".su-autoSuggest-element.selected").offsetTop + document.querySelector(".su-autoSuggest-element.selected").offsetHeight -document.getElementById("autosuggestElement").offsetHeight;
                        }
                        if (this.template.querySelectorAll('lightning-input[data-id="searchBoxInput"]')) {
                            let searchInputbox = this.template.querySelectorAll('lightning-input[data-id="searchBoxInput"]');
                            this.setFocus(searchInputbox);
                        }
                    }
                }
            }
        }
    }
}