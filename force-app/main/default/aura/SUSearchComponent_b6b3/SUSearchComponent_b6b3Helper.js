({

    redirectFunc: function(component, SearchQuery, eventHit, helper) {

        var urlEvent = $A.get("e.force:navigateToURL");

        urlEvent.setParams({

            "isredirect": false,

            "url": component.get("v.currentCommunityURL") + "?searchString=" + encodeURIComponent(SearchQuery)

        });

        urlEvent.fire();

        if (eventHit === 'suggest') {

            helper.fillSearchBoxEventFire(helper);

        }

    },

    fillSearchBoxEventFire: function(helper) {

        var SearchQuery = helper.getURLParameter('searchString');

        var searchBoxEvent = $A.get("e.SU_Ltng:fillSearchBox");

        searchBoxEvent.setParams({ "searchString": SearchQuery });

        searchBoxEvent.fire();

    },

    filtersPopupFunc: function(component, event, helper) {

        var resultIndex = event.target.id;
        var aggregationsData = component.get("v.aggregationsData");
        if (resultIndex) {
            aggregationsData[resultIndex].isCollapsed = !aggregationsData[resultIndex].isCollapsed;
            component.set("v.aggregationsData", aggregationsData);
        } else {
            for (var i = 0; i < aggregationsData.length; i++) {
                aggregationsData[i].isCollapsed = false;
            }
            component.set("v.aggregationsData", aggregationsData);
        }

    },

    sortByName: function(component, field) {
        field.sort(function(a, b) {
            if (typeof a.displayName == "string" || typeof a.Contentname == "string") {
                if (a.displayName && b.displayName) {
                    var textA = a.displayName.toUpperCase();
                    var textB = b.displayName.toUpperCase();
                } else {
                    var textA = a.Contentname.toUpperCase();
                    var textB = b.Contentname.toUpperCase();
                }
                return (textA < textB) ? -1 : (textA > textB) ? 1 : 0;
            } else {
                if (a.displayName && b.displayName) {
                    return parseFloat(a.displayName) - parseFloat(b.displayName);
                } else {
                    return parseFloat(a.Contentname) - parseFloat(b.Contentname);
                }
            }
        });
    },
    sortByDesc: function(component, field) {
        field.sort(function(a, b) {
            if (typeof a.value == "number") {
                if (a.value) {
                    return parseFloat(a.value) - parseFloat(b.value);
                } else {
                    return parseFloat(a.value) - parseFloat(b.value);
                }
            }
        });
    },
    sortByAsc: function(component, field) {
        field.sort(function(a, b) {
            if (typeof a.value == "number") {
                if (a.value) {
                    return parseFloat(b.value) - parseFloat(a.value);
                } else {
                    return parseFloat(b.value) - parseFloat(a.value);
                }
            }
        });
    },

    refineButtonpressFunc: function(component, event, helper) {

        var pageSize = component.get("v.pageSizeAdvFiltr");

        component.set("v.pageSize", pageSize);

        component.set("v.pageNum", "1");

        //window.location.hash = encodeURIComponent("pageNum=1&sortBy="+component.get("v.sortByCheck")+"&orderBy=desc&resultsPerPage="+component.get("v.pageSize")+"&exactPhrase="+decodeURIComponent(component.get("v.exactPhrase"))+"&withOneOrMore="+decodeURIComponent(component.get("v.withOneOrMore"))+"&withoutTheWords="+decodeURIComponent(component.get("v.withoutTheWords"))+"&selectedType="+helper.getURLParameter('selectedType')+"&contentSources="+helper.getURLParameter('contentSources')+"&active="+helper.getURLParameter('active'));
        window.location.hash = encodeURIComponent("pageNum=1&sortBy=" + component.get("v.sortByCheck") + "&orderBy=desc&resultsPerPage=" + component.get("v.pageSize") + "&pageSizeAdv=" + component.get("v.pageSizeAdvFiltr") + "&exactPhrase=" + encodeURIComponent(component.get("v.exactPhrase")) + "&withOneOrMore=" + encodeURIComponent(component.get("v.withOneOrMore")) + "&withoutTheWords=" + encodeURIComponent(component.get("v.withoutTheWords")) + "&selectedType=" + encodeURIComponent(helper.getURLParameter('selectedType')));
        helper.getValue(component, 'search', 'true', helper);
    },

    clientSettingsFunc: function(component, event, searchQuery, helper) {

        var action = component.get("c.getCommunityCustomSettings");

        action.setCallback(this, function(response) {

            if (response.getState() == "SUCCESS") {

                var result = response.getReturnValue();
                if (result.isCustomSettingFilled) {

                    component.set("v.endPoint", result.endPoint);

                    component.set("v.uid", result.uid);

                    component.set("v.currentCommunityURL", result.currentCommURL);

                    component.set("v.customSettingErrorMessage", "");

                    component.set("v.commBaseURL", result.commBaseURL);

                    //component.set("v.selectedTypeFilter","");

                    component.set("v.selectedTypeFilter", localStorage.getItem("selectedFilter") || "");

                    component.set("v.pageNum", "1");

                    component.set("v.searchString", searchQuery);
                    var c = JSON.parse(localStorage.getItem('theme' + component.get("v.uid")));
                    if (c) {
                        component.set("v.toggleDisplayKeys[0].hideEye", c.hideTitle);
                        component.set("v.toggleDisplayKeys[1].hideEye", c.hideSummary);
                        component.set("v.toggleDisplayKeys[3].hideEye", c.hideMetadata);
                        component.set("v.toggleDisplayKeys[2].hideEye", c.hideUrl);
                        component.set("v.toggleDisplayKeys[4].hideEye", c.hideIcon);
                        component.set("v.filterToRight", c.filters);
                        if (c.hideTitle == true) {
                            component.get("v.hiddenKeys").push("Title");
                        }
                        if (c.hideSummary == true) {
                            component.get("v.hiddenKeys").push("Summary");
                        }
                        if (c.hideMetadata == true) {
                            component.get("v.hiddenKeys").push("Metadata");
                        }
                        if (c.hideUrl == true) {
                            component.get("v.hiddenKeys").push("Url");
                        }
                        if (c.hideIcon == true) {
                            component.get("v.hiddenKeys").push("Icon");
                        }
                        if(c['hiddenFacets']){
                            component.set("v.hiddenFacets", c["hiddenFacets"]);
                         }
                    }
                    component.set("v.caller", false);
                    component.set("v.setFlag", true);
                    helper.makeSearchCall(component);
                    var interval = setInterval(function() {
                        if (component.get('v.filtersArray') && component.get('v.filtersArray')[0]) {
                            helper.getValue(component, 'search', 'true', helper);
                            clearInterval(interval);
                        }
                    }, 200);
                    helper.getAdv(component, event);
                } else {
                    component.set("v.customSettingErrorMessage", 'Please configure your SearchUnify and try again.');
                }
            } else {

                $A.log("Errors", response.getState());

            }

        });
        $A.enqueueAction(action);

    },
    makeSearchCall: function(component) {
        var actionBach = window;
        var action = component.get("c.SearchResults");
        action.setParams({
            "searchParams": {
                "searchString": "",
                "pageNum": "1",
                "sortBy": '_score',
                "orderBy": "desc",
                "resultsPerPage": "10",
                "exactPhrase": "",
                "withOneOrMore": "",
                "withoutTheWords": "",
                "selectedType": "",
                "referrer": "",
                "recommendResult": "",
                "indexEnabled": true,
                "language":localStorage.getItem('language')
            }
        });
        let query = JSON.parse(JSON.stringify(action.getParam("searchParams")));
        action.setCallback(this, function(response) {
            var actionBachHref = actionBach.document.URL;
            if (response.getState() == "SUCCESS") {
                var result = response.getReturnValue();
                var aggrData = result.aggregationsArray[0];
                component.set("v.filtersArray", aggrData);
                component.set('v.emptyResponseAggregations', result.aggregationsArray);
                var c = JSON.parse(localStorage.getItem('theme' + component.get("v.uid")));
                if (c && c.activeTabIndex != undefined) {
                    component.set('v.contentSourceExists', component.get('v.filtersArray')[0].values.some(function(el) { return el.Contentname == c.activeTabIndex }));
                }
            }
        });
        $A.enqueueAction(action);
    },

    getAdv: function(component, event) {
        const xhr = new XMLHttpRequest();
        const url = component.get("v.endPoint") + "/admin/searchClient/readAdHTML/" + component.get("v.uid") + "?phrase=" + component.get("v.searchString");
        xhr.open('GET', url, true);
        xhr.onload = function() {
            if (this.status === 200) {
                const response = JSON.parse(this.responseText).htmlString;
                component.set("v.advertisement", response);
            }
        };
        xhr.send();
    },

    goToTopFunc: function(component, event) {

        document.body.scrollTop = 0;

        document.documentElement.scrollTop = 0;

    },

    getURLParameter: function(param) {

        var m = window;

        var s = m.document.URL;
        //var result = decodeURIComponent((new RegExp('[#|?|&]' + param + '=' + '([^&;#]+?)(&|#|;|$)').exec(decodeURIComponent(s)) || [, ""])[1].replace(/\+/g, '%20'))
        var result;
        let str = s;

        if (window.location.hash != "") {
            str = s.slice(0, s.indexOf(window.location.hash));
        }

        if (param == "searchString") {

            result = decodeURIComponent((new RegExp('[?|&]' + param + '=' + '([^&;]+?)(&|#|;|$)').exec(str) || [, ""])[1].replace(/\+/g, '%20'))
        } else
            result = decodeURIComponent((new RegExp('[#|s?|&]' + param + '=' + '([^&;]+?)(&|#|;|$)').exec(decodeURIComponent(s)) || [, ""])[1].replace(/\+/g, '%20'))

        return result;

    },

    doInitialization: function(component, event, helper) {

        var searchQuery = '';

        var sortings = [{
                "method_name": "Relevance",
                "value": "_score"
            },
            {
                "method_name": "Created Date",
                "value": "post_time"
            }
        ];
        component.set("v.sortByValues", sortings);
        var filterValue = '[{"type":"_index","filter":c.activeTabIndex}]';
        component.set("v.defaultPageSize", component.get("v.pageSize"));
        component.set("v.selectedTypeFilter", "");
        var toggleKeys = [{ 'key': 'Title', 'hideEye': false }, { 'key': 'Summary', 'hideEye': false }, { 'key': 'Url', 'hideEye': false }, { 'key': 'Metadata', 'hideEye': false }, { 'key': 'Icon', 'hideEye': false }];
        component.set("v.toggleDisplayKeys", toggleKeys);
        component.set("v.selectedTypeFilter", "");

        component.set("v.bookmarkSearches", JSON.parse(localStorage.getItem('bookmark_searches_' + component.get("v.uid")) || "[]"));

        searchQuery = helper.getURLParameter('searchString');

        if (searchQuery != null && searchQuery != undefined) {

            helper.clientSettingsFunc(component, event, searchQuery, helper);
            component.set("v.caller", true);

        } else {

            component.set("v.totalResults", 0);

            component.set("v.errorMessage", "Please enter a valid search term.");

        }
        //Handle Right and Middle Click
        document.addEventListener('mousedown', function(e) {
            helper.runScriptMethodFunc(component, e, helper);
        });

        document.addEventListener('scroll', function(e) {

            if (window.pageYOffset > 100) {

                component.set("v.showScroll", true);
            } else

                component.set("v.showScroll", false);
        });
        component.set("v.componentLoaded", true);
        //component.set('v.treeIsVisible', true);
    },

    searchSuggestFunc: function(component, event, helper) {

        var searchQuery = event.target.text;

        if (searchQuery != null && searchQuery != '' && searchQuery != undefined) {

            searchQuery = searchQuery.trim();

        }

        helper.redirectFunc(component, searchQuery, 'suggest', helper);

    },

    sortCallFunc: function(component, event, helper) {
        if (component.find('mySelect')) {
            var sortByValue = component.find('mySelect').get('v.value');
            component.set("v.sortByCheck", sortByValue);
            // component.set("v.selectedTypeFilter","");
            component.set("v.pageNum", "1");
            helper.getValue(component, 'sortBy', 'true', helper);
        }

    },

    searchTipsToggleFunc: function(component, event, helper) {

        let flag = component.get("v.searchTipsTab");

        let element = document.getElementsByClassName('su__right-sidebar')[0];

        if (flag) {

            if (element.classList.contains("su__search-tip-toggle")) {

                element.classList.remove("su__search-tip-toggle");

                document.body.classList.remove('su__overflow-hide');
            } else {

                helper.viewMoreToggleFunc(component, event, helper);

                element.classList.add("su__search-tip-toggle");

                document.body.classList.add('su__overflow-hide');
            }

        } else {
            element.classList.remove("su__search-tip-toggle");

            document.body.classList.remove('su__overflow-hide');
        }

        component.set("v.searchTipsTab", false);

    },

    viewMoreToggleFunc: function(component, event, helper) {

        let flag = component.get("v.viewMoreTab");

        let element = document.getElementsByClassName('su__viewMore')[0];
        let secondElement = document.getElementsByClassName('su__viewMore-overlay')[0];
        if (flag) {

            if (element.classList.contains('su__top-toggle')) {

                element.classList.remove('su__top-toggle');
                secondElement.classList.remove('su__viewMore-block');
                document.body.classList.remove('su__overflow-hide');

            } else {
                element.classList.add('su__top-toggle');
                secondElement.classList.add('su__viewMore-block');
                document.body.classList.add('su__overflow-hide');
            }

        } else {
            element.classList.remove('su__top-toggle');
            secondElement.classList.remove('su__viewMore-block');
            document.body.classList.remove('su__overflow-hide');
        }

        component.set("v.viewMoreTab", false);
    },

    bookmarkList_toggleFunc: function(component, event, helper) {

        let flag = component.get("v.bookmarkTab");

        component.set("v.viewConfirmPopup", false);

        component.set("v.viewSavePopup", false);

        component.set("v.bookmark_list", !component.get("v.bookmark_list"));

        if (flag) {

            if (document.body.classList.contains('su__overflow-hide')) {

                document.body.classList.remove('su__overflow-hide');
            } else {

                helper.viewMoreToggleFunc(component, event, helper);

                document.body.classList.add('su__overflow-hide');

            }
        } else {
            document.body.classList.remove('su__overflow-hide');

            component.set("v.bookmark_list", false);

        }

        component.set("v.bookmarkTab", false);

    },

    collapseFiltersFunc: function(component, event, helper) {



        var currentId = event.target.id;

        var childId = currentId.split('_icon')[0];

        var divTocollapse = document.getElementById(childId);

        var openIcon = document.getElementById(childId + '_toggleIconOn');

        var closeIcon = document.getElementById(childId + '_toggleIconOff');

        if (divTocollapse.classList.contains('in')) {

            openIcon.classList.remove('su_displayBlock');

            openIcon.classList.add('su_displayHide');

            closeIcon.classList.remove('su_displayHide');

            closeIcon.classList.add('su_displayBlock');

            divTocollapse.classList.remove('in');



        } else {

            closeIcon.classList.remove('su_displayBlock');

            closeIcon.classList.add('su_displayHide');

            openIcon.classList.remove('su_displayHide');

            openIcon.classList.add('su_displayBlock');

            divTocollapse.classList.add('in');



        }

    },

    collapseShowHide: function(component, event, helper) {
        var translation = {
    "en": {
        "type": "LTR",
        "mapping": {
            "Top Searches": "Top Searches",
            "Sources": "Sources",
            "Search here": "Search here",
            "Advanced Search Options": "Advanced Search Options",
            "With the exact phrase": "With the exact phrase",
            "With one or more words": "With one or more words",
            "Without the words": "Without the words",
            "Results per page": "Results per page",
            "Results": "Results",
            "results": "results",
            "Refine Search": "Refine Search",
            "The sequence of words you enter here will be in the same order and together in the search results. You may leave this field empty.": "The sequence of words you enter here will be in the same order and together in the search results. You may leave this field empty.",
            "Any one, but not necessarily all of the words you enter here will appear in the search results.": "Any one, but not necessarily all of the words you enter here will appear in the search results.",
            "All Content": "All Content",
            "Search Tips": "Search Tips",
            "Enter just a few key words related to your question or problem": "Enter just a few key words related to your question or problem",
            "Add Key words to refine your search as necessary": "Add Key words to refine your search as necessary",
            "Do not use punctuation": "Do not use punctuation",
            "Search is not case sensitive": "Search is not case sensitive",
            "": "",
            "If you do not find what you are looking for the first time,reduce the number of key words you enter and try searching again.": "If you do not find what you are looking for the first time,reduce the number of key words you enter and try searching again.",
            "Minimum supported Internet Explorer version is IE9": "Minimum supported Internet Explorer version is IE9",
            "Sort by Relevance": "Sort by Relevance",
            "Sort by Created Date": "Sort by Created Date",
            "Back to Top": "Back to Top",
            "List View": "List View",
            "Grid View": "Grid View",
            "Next": "Next",
            "Previous": "Previous",
            "Showing page": "Showing page",
            "seconds": "seconds",
            "Did you mean": "Did you mean",
            "Show more": "Show more",
            "We're sorry. We Cannot find any matches for your search term.": "We're sorry. We Cannot find any matches for your search term.",
            "Showing results using some of your recent search terms": "Showing results using some of your recent search terms",
            "Top keywords searched": "Top keywords searched",
            "Ask the Community!": "Ask the Community!",
            "Let our amazing customer community help": "Let our amazing customer community help",
            "Need More Help?": "Need More Help?",
            "Vist the solution finder today": "Vist the solution finder today",
            "Post a Question": "Post a Question",
            "Contact Support": "Contact Support",
            "SOLVED": "SOLVED",
            "Show less": "Show less",
            "Narrow your search": "Narrow your search",
            "Was above result helpful?": "Was above result helpful?",
            "Recommended Learning": "Recommended Learning",
            "Thank you for your response!": "Thank you for your response!",
            "Recommendations": "Recommendations",
            "Useful Articles": "Useful Articles",
            "Sort by": "Sort by",
            "Relevance": "Relevance",
            "Created Date": "Created Date",
            "All Time": "",
            "Past Day": "",
            "Past Week": "",
            "Past Month": "",
            "Past Year": ""
        }
    },
    "de-de": {
        "type": "LTR",
        "mapping": {
            "Top Searches": "Top-Suchanfragen",
            "Sources": "Quellen",
            "Search here": "Suche hier",
            "Advanced Search Options": "Erweiterte Suchoptionen",
            "With the exact phrase": "Mit der exakten Phrase",
            "With one or more words": "Mit einem oder mehreren Wörtern",
            "Without the words": "Ohne die Worte",
            "Results per page": "Ergebnisse pro Seite",
            "Results": "Ergebnisse",
            "results": "Ergebnisse",
            "Refine Search": "Suche einschränken",
            "The sequence of words you enter here will be in the same order and together in the search results. You may leave this field empty.": "Die Reihenfolge der Wörter, die Sie hier eingeben, wird in der gleichen Reihenfolge und in den Suchergebnissen angezeigt. Sie können dieses Feld leer lassen.",
            "Any one, but not necessarily all of the words you enter here will appear in the search results.": "Alle, aber nicht unbedingt alle hier eingegebenen Wörter werden in den Suchergebnissen angezeigt.",
            "All Content": "Alle Inhalte",
            "Search Tips": "Suchtipps",
            "Enter just a few key words related to your question or problem": "Geben Sie nur einige Schlüsselwörter ein, die sich auf Ihre Frage oder Ihr Problem beziehen",
            "Add Key words to refine your search as necessary": "Fügen Sie Schlüsselwörter hinzu, um Ihre Suche nach Bedarf zu verfeinern",
            "Do not use punctuation": "Verwenden Sie keine Interpunktion",
            "Search is not case sensitive": "Die Suche unterscheidet nicht zwischen Groß- und Kleinschreibung",
            "": "",
            "If you do not find what you are looking for the first time,reduce the number of key words you enter and try searching again.": "Wenn Sie das, was Sie zum ersten Mal suchen, nicht finden, reduzieren Sie die Anzahl der eingegebenen Suchbegriffe und versuchen Sie es erneut.",
            "Minimum supported Internet Explorer version is IE9": "Minimale unterstützte Internet Explorer-Version ist IE9",
            "Sort by Relevance": "Sortieren nach Relevanz",
            "Sort by Created Date": "Nach Erstellungsdatum sortieren",
            "Back to Top": "Zurück nach oben",
            "List View": "Listenansicht",
            "Grid View": "Rasteransicht",
            "Next": "Nächster",
            "Previous": "Bisherige",
            "Showing page": "Seite anzeigen",
            "seconds": "Sekunden",
            "Did you mean": "Meintest du",
            "Show more": "Zeig mehr",
            "We're sorry. We Cannot find any matches for your search term.": "Es tut uns leid. Wir können keine Übereinstimmungen für Ihren Suchbegriff finden.",
            "Showing results using some of your recent search terms": "Ergebnisse werden mit einigen Ihrer letzten Suchbegriffe angezeigt",
            "Top keywords searched": "Top Suchbegriffe gesucht",
            "Ask the Community!": "Fragen Sie die Gemeinde!",
            "Let our amazing customer community help": "Lassen Sie sich von unserer großartigen Kundengemeinschaft helfen",
            "Need More Help?": "Benötigen Sie weitere Hilfe?",
            "Vist the solution finder today": "Besuchen Sie noch heute den Lösungsfinder",
            "Post a Question": "Frage stellen",
            "Contact Support": "Kontaktieren Sie Support",
            "SOLVED": "Gelöst",
            "Show less": "Zeige weniger",
            "Narrow your search": "Grenzen Sie Ihre Suche ein",
            "Was above result helpful?": "War das Ergebnis hilfreich?",
            "Recommended Learning": "Empfohlenes Lernen",
            "Thank you for your response!": "Danke für Ihre Antwort!",
            "Recommendations": "Empfehlungen",
            "Useful Articles": "Nützliche Artikel",
            "Sort by": "Sortiere nach",
            "Relevance": "Relevanz",
            "Created Date": "Erstellungsdatum",
            "All Time": "",
            "Past Day": "",
            "Past Week": "",
            "Past Month": "",
            "Past Year": ""
        }
    },
    "fr": {
        "type": "LTR",
        "mapping": {
            "Top Searches": "Top recherches",
            "Sources": "Sources",
            "Search here": "Cherche ici",
            "Advanced Search Options": "Options de recherche avancée",
            "With the exact phrase": "Avec la phrase exacte",
            "With one or more words": "Avec un ou plusieurs mots",
            "Without the words": "Sans les mots",
            "Results per page": "résultats par page",
            "Results": "Résultats",
            "results": "résultats",
            "Refine Search": "Affiner votre recherche",
            "The sequence of words you enter here will be in the same order and together in the search results. You may leave this field empty.": "La séquence de mots que vous entrez ici sera dans le même ordre et ensemble dans les résultats de la recherche. Vous pouvez laisser ce champ vide.",
            "Any one, but not necessarily all of the words you enter here will appear in the search results.": "Tous les mots que vous entrez ici, mais pas nécessairement tous, apparaîtront dans les résultats de la recherche.",
            "All Content": "Tout le contenu",
            "Search Tips": "Astuces de recherche",
            "Enter just a few key words related to your question or problem": "Entrez seulement quelques mots clés liés à votre question ou à votre problème",
            "Add Key words to refine your search as necessary": "Ajoutez des mots-clés pour affiner votre recherche si nécessaire",
            "Do not use punctuation": "Ne pas utiliser la ponctuation",
            "Search is not case sensitive": "La recherche n'est pas sensible à la casse",
            "": "",
            "If you do not find what you are looking for the first time,reduce the number of key words you enter and try searching again.": "Si vous ne trouvez pas ce que vous cherchez pour la première fois, réduisez le nombre de mots-clés que vous avez saisis et relancez la recherche.",
            "Minimum supported Internet Explorer version is IE9": "La version minimale prise en charge d'Internet Explorer est IE9.",
            "Sort by Relevance": "Trier par pertinence",
            "Sort by Created Date": "Trier par date de création",
            "Back to Top": "Retour au sommet",
            "List View": "Voir la liste",
            "Grid View": "Vue grille",
            "Next": "Suivant",
            "Previous": "Précédent",
            "Showing page": "Afficher la page",
            "seconds": "seconds",
            "Did you mean": "Vouliez-vous dire",
            "Show more": "Montre plus",
            "We're sorry. We Cannot find any matches for your search term.": "Nous sommes désolés. Nous ne trouvons aucune correspondance pour votre terme de recherche.",
            "Showing results using some of your recent search terms": "Afficher les résultats en utilisant certains de vos termes de recherche récents",
            "Top keywords searched": "Top mots-clés recherchés",
            "Ask the Community!": "Demandez à la communauté!",
            "Let our amazing customer community help": "Laissez notre incroyable communauté de clients aider",
            "Need More Help?": "Besoin d'aide?",
            "Vist the solution finder today": "Visitez le solutionneur dès aujourd'hui",
            "Post a Question": "Publier une question",
            "Contact Support": "Contactez le support",
            "SOLVED": "Résolu",
            "Show less": "Montre moins",
            "Narrow your search": "Affinez votre recherche",
            "Was above result helpful?": "Le résultat ci-dessus a-t-il été utile?",
            "Recommended Learning": "Apprentissage recommandé",
            "Thank you for your response!": "Merci pour votre réponse!",
            "Recommendations": "Recommandations",
            "Useful Articles": "Articles utiles",
            "Sort by": "Trier par",
            "Relevance": "Pertinence",
            "Created Date": "Date de création",
            "All Time": "",
            "Past Day": "",
            "Past Week": "",
            "Past Month": "",
            "Past Year": ""
        }
    },
    "Spanish": {
        "type": "LTR",
        "mapping": {
            "Top Searches": "",
            "Sources": "",
            "Search here": "",
            "Advanced Search Options": "",
            "With the exact phrase": "",
            "With one or more words": "",
            "Without the words": "",
            "Results per page": "",
            "Results": "",
            "results": "",
            "Refine Search": "",
            "The sequence of words you enter here will be in the same order and together in the search results. You may leave this field empty.": "",
            "Any one, but not necessarily all of the words you enter here will appear in the search results.": "",
            "All Content": "",
            "Search Tips": "",
            "Enter just a few key words related to your question or problem": "",
            "Add Key words to refine your search as necessary": "",
            "Do not use punctuation": "",
            "Search is not case sensitive": "",
            "": "",
            "If you do not find what you are looking for the first time,reduce the number of key words you enter and try searching again.": "",
            "Minimum supported Internet Explorer version is IE9": "",
            "Sort by Relevance": "",
            "Sort by Created Date": "",
            "Back to Top": "",
            "List View": "",
            "Grid View": "",
            "Next": "",
            "Previous": "",
            "Showing page": "",
            "seconds": "",
            "Did you mean": "",
            "Show more": "",
            "We're sorry. We Cannot find any matches for your search term.": "",
            "Showing results using some of your recent search terms": "",
            "Top keywords searched": "",
            "Ask the Community!": "",
            "Let our amazing customer community help": "",
            "Need More Help?": "",
            "Vist the solution finder today": "",
            "Post a Question": "",
            "Contact Support": "",
            "SOLVED": "",
            "Show less": "",
            "Narrow your search": "",
            "Was above result helpful?": "",
            "Recommended Learning": "",
            "Thank you for your response!": "",
            "Recommendations": "",
            "Useful Articles": "",
            "Sort by": "",
            "Relevance": "",
            "Created Date": "",
            "All Time": "",
            "Past Day": "",
            "Past Week": "",
            "Past Month": "",
            "Past Year": ""
        }
    },
    "zh": {
        "type": "LTR",
        "mapping": {
            "Top Searches": "热门搜索",
            "Sources": "来源",
            "Search here": "在这里搜索",
            "Advanced Search Options": "高级搜索选项",
            "With the exact phrase": "用确切的短语",
            "With one or more words": "用一个或多个单词",
            "Without the words": "没有话语",
            "Results per page": "每页结果",
            "Results": "结果",
            "results": "结果",
            "Refine Search": "优化搜索",
            "The sequence of words you enter here will be in the same order and together in the search results. You may leave this field empty.": "您在此处输入的单词序列将在搜索结果中以相同的顺序排列。 您可以将此字段留空。",
            "Any one, but not necessarily all of the words you enter here will appear in the search results.": "您输入的任何一个，但不一定是所有单词都将出现在搜索结果中。",
            "All Content": "所有内容",
            "Search Tips": "搜索提示",
            "Enter just a few key words related to your question or problem": "输入与您的问题或问题相关的几个关键词",
            "Add Key words to refine your search as necessary": "添加关键字以根据需要优化搜索",
            "Do not use punctuation": "不要使用标点符号",
            "Search is not case sensitive": "搜索不区分大小写",
            "": "",
            "If you do not find what you are looking for the first time,reduce the number of key words you enter and try searching again.": "如果您第一次找不到所需内容，请减少您输入的关键字数量，然后重新尝试搜索。",
            "Minimum supported Internet Explorer version is IE9": "支持的最低Internet Explorer版本是IE9",
            "Sort by Relevance": "按相关性排序",
            "Sort by Created Date": "按创建日期排序",
            "Back to Top": "回到顶部",
            "List View": "列表显示",
            "Grid View": "网格视图",
            "Next": "下一个",
            "Previous": "以前",
            "Showing page": "显示页面",
            "seconds": "秒",
            "Did you mean": "你的意思是",
            "Show more": "显示更多",
            "We're sorry. We Cannot find any matches for your search term.": "我们很抱歉。 我们找不到您搜索字词的匹配项。",
            "Showing results using some of your recent search terms": "使用您最近的一些搜索字词显示结果",
            "Top keywords searched": "搜索热门关键词",
            "Ask the Community!": "问社区！",
            "Let our amazing customer community help": "让我们惊人的客户社区帮助",
            "Need More Help?": "需要更多帮助？",
            "Vist the solution finder today": "立即访问解决方案查找器",
            "Post a Question": "发表一个问题",
            "Contact Support": "联系支持",
            "SOLVED": "解决了",
            "Show less": "显示较少",
            "Narrow your search": "缩小搜索范围",
            "Was above result helpful?": "以上结果有用吗？",
            "Recommended Learning": "推荐学习",
            "Thank you for your response!": "感谢您的答复！",
            "Recommendations": "建议",
            "Useful Articles": "有用的文章",
            "Sort by": "排序方式",
            "Relevance": "关联",
            "Created Date": "创建日期",
            "All Time": "整天",
            "Past Day": "过去的一天",
            "Past Week": "上周",
            "Past Month": "过去一个月",
            "Past Year": "过去的一年"
        }
    },
    "Japanese": {
        "type": "LTR",
        "mapping": {
            "Top Searches": "",
            "Sources": "",
            "Search here": "",
            "Advanced Search Options": "",
            "With the exact phrase": "",
            "With one or more words": "",
            "Without the words": "",
            "Results per page": "",
            "Results": "",
            "results": "",
            "Refine Search": "",
            "The sequence of words you enter here will be in the same order and together in the search results. You may leave this field empty.": "",
            "Any one, but not necessarily all of the words you enter here will appear in the search results.": "",
            "All Content": "",
            "Search Tips": "",
            "Enter just a few key words related to your question or problem": "",
            "Add Key words to refine your search as necessary": "",
            "Do not use punctuation": "",
            "Search is not case sensitive": "",
            "": "",
            "If you do not find what you are looking for the first time,reduce the number of key words you enter and try searching again.": "",
            "Minimum supported Internet Explorer version is IE9": "",
            "Sort by Relevance": "",
            "Sort by Created Date": "",
            "Back to Top": "",
            "List View": "",
            "Grid View": "",
            "Next": "",
            "Previous": "",
            "Showing page": "",
            "seconds": "",
            "Did you mean": "",
            "Show more": "",
            "We're sorry. We Cannot find any matches for your search term.": "",
            "Showing results using some of your recent search terms": "",
            "Top keywords searched": "",
            "Ask the Community!": "",
            "Let our amazing customer community help": "",
            "Need More Help?": "",
            "Vist the solution finder today": "",
            "Post a Question": "",
            "Contact Support": "",
            "SOLVED": "",
            "Show less": "",
            "Narrow your search": "",
            "Was above result helpful?": "",
            "Recommended Learning": "",
            "Thank you for your response!": "",
            "Recommendations": "",
            "Useful Articles": "",
            "Sort by": "",
            "Relevance": "",
            "Created Date": "",
            "All Time": "",
            "Past Day": "",
            "Past Week": "",
            "Past Month": "",
            "Past Year": ""
        }
    },
    "Dutch": {
        "type": "LTR",
        "mapping": {
            "Top Searches": "",
            "Sources": "",
            "Search here": "",
            "Advanced Search Options": "",
            "With the exact phrase": "",
            "With one or more words": "",
            "Without the words": "",
            "Results per page": "",
            "Results": "",
            "results": "",
            "Refine Search": "",
            "The sequence of words you enter here will be in the same order and together in the search results. You may leave this field empty.": "",
            "Any one, but not necessarily all of the words you enter here will appear in the search results.": "",
            "All Content": "",
            "Search Tips": "",
            "Enter just a few key words related to your question or problem": "",
            "Add Key words to refine your search as necessary": "",
            "Do not use punctuation": "",
            "Search is not case sensitive": "",
            "": "وما إلى ذلك.",
            "If you do not find what you are looking for the first time,reduce the number of key words you enter and try searching again.": "",
            "Minimum supported Internet Explorer version is IE9": "",
            "Sort by Relevance": "",
            "Sort by Created Date": "",
            "Back to Top": "",
            "List View": "",
            "Grid View": "",
            "Next": "",
            "Previous": "",
            "Showing page": "",
            "seconds": "",
            "Did you mean": "",
            "Show more": "",
            "We're sorry. We Cannot find any matches for your search term.": "",
            "Showing results using some of your recent search terms": "",
            "Top keywords searched": "",
            "Ask the Community!": "",
            "Let our amazing customer community help": "",
            "Need More Help?": "",
            "Vist the solution finder today": "",
            "Post a Question": "",
            "Contact Support": "",
            "SOLVED": "",
            "Show less": "",
            "Narrow your search": "",
            "Was above result helpful?": "",
            "Recommended Learning": "",
            "Thank you for your response!": "",
            "Recommendations": "",
            "Useful Articles": "",
            "Sort by": "",
            "Relevance": "",
            "Created Date": "",
            "All Time": "",
            "Past Day": "",
            "Past Week": "",
            "Past Month": "",
            "Past Year": ""
        }
    },
    "Korean": {
        "type": "LTR",
        "mapping": {
            "Top Searches": "",
            "Sources": "",
            "Search here": "",
            "Advanced Search Options": "",
            "With the exact phrase": "",
            "With one or more words": "",
            "Without the words": "",
            "Results per page": "",
            "Results": "",
            "results": "",
            "Refine Search": "",
            "The sequence of words you enter here will be in the same order and together in the search results. You may leave this field empty.": "",
            "Any one, but not necessarily all of the words you enter here will appear in the search results.": "",
            "All Content": "",
            "Search Tips": "",
            "Enter just a few key words related to your question or problem": "",
            "Add Key words to refine your search as necessary": "",
            "Do not use punctuation": "",
            "Search is not case sensitive": "",
            "": "",
            "If you do not find what you are looking for the first time,reduce the number of key words you enter and try searching again.": "",
            "Minimum supported Internet Explorer version is IE9": "",
            "Sort by Relevance": "",
            "Sort by Created Date": "",
            "Back to Top": "",
            "List View": "",
            "Grid View": "",
            "Next": "",
            "Previous": "",
            "Showing page": "",
            "seconds": "",
            "Did you mean": "",
            "Show more": "",
            "We're sorry. We Cannot find any matches for your search term.": "",
            "Showing results using some of your recent search terms": "",
            "Top keywords searched": "",
            "Ask the Community!": "",
            "Let our amazing customer community help": "",
            "Need More Help?": "",
            "Vist the solution finder today": "",
            "Post a Question": "",
            "Contact Support": "",
            "SOLVED": "",
            "Show less": "",
            "Narrow your search": "",
            "Was above result helpful?": "",
            "Recommended Learning": "",
            "Thank you for your response!": "",
            "Recommendations": "",
            "Useful Articles": "",
            "Sort by": "",
            "Relevance": "",
            "Created Date": "",
            "All Time": "",
            "Past Day": "",
            "Past Week": "",
            "Past Month": "",
            "Past Year": ""
        }
    },
    "Portuguese": {
        "type": "LTR",
        "mapping": {
            "Top Searches": "",
            "Sources": "",
            "Search here": "",
            "Advanced Search Options": "",
            "With the exact phrase": "",
            "With one or more words": "",
            "Without the words": "",
            "Results per page": "",
            "Results": "",
            "results": "",
            "Refine Search": "",
            "The sequence of words you enter here will be in the same order and together in the search results. You may leave this field empty.": "",
            "Any one, but not necessarily all of the words you enter here will appear in the search results.": "",
            "All Content": "",
            "Search Tips": "",
            "Enter just a few key words related to your question or problem": "",
            "Add Key words to refine your search as necessary": "",
            "Do not use punctuation": "",
            "Search is not case sensitive": "",
            "": "",
            "If you do not find what you are looking for the first time,reduce the number of key words you enter and try searching again.": "",
            "Minimum supported Internet Explorer version is IE9": "",
            "Sort by Relevance": "",
            "Sort by Created Date": "",
            "Back to Top": "",
            "List View": "",
            "Grid View": "",
            "Next": "",
            "Previous": "",
            "Showing page": "",
            "seconds": "",
            "Did you mean": "",
            "Show more": "",
            "We're sorry. We Cannot find any matches for your search term.": "",
            "Showing results using some of your recent search terms": "",
            "Top keywords searched": "",
            "Ask the Community!": "",
            "Let our amazing customer community help": "",
            "Need More Help?": "",
            "Vist the solution finder today": "",
            "Post a Question": "",
            "Contact Support": "",
            "SOLVED": "",
            "Show less": "",
            "Narrow your search": "",
            "Was above result helpful?": "",
            "Recommended Learning": "",
            "Thank you for your response!": "",
            "Recommendations": "",
            "Useful Articles": "",
            "Sort by": "",
            "Relevance": "",
            "Created Date": "",
            "All Time": "",
            "Past Day": "",
            "Past Week": "",
            "Past Month": "",
            "Past Year": ""
        }
    },
    "Italian": {
        "type": "LTR",
        "mapping": {
            "Top Searches": "",
            "Sources": "",
            "Search here": "",
            "Advanced Search Options": "",
            "With the exact phrase": "",
            "With one or more words": "",
            "Without the words": "",
            "Results per page": "",
            "Results": "",
            "results": "",
            "Refine Search": "",
            "The sequence of words you enter here will be in the same order and together in the search results. You may leave this field empty.": "",
            "Any one, but not necessarily all of the words you enter here will appear in the search results.": "",
            "All Content": "",
            "Search Tips": "",
            "Enter just a few key words related to your question or problem": "",
            "Add Key words to refine your search as necessary": "",
            "Do not use punctuation": "",
            "Search is not case sensitive": "",
            "": "usw.",
            "If you do not find what you are looking for the first time,reduce the number of key words you enter and try searching again.": "",
            "Minimum supported Internet Explorer version is IE9": "",
            "Sort by Relevance": "",
            "Sort by Created Date": "",
            "Back to Top": "",
            "List View": "",
            "Grid View": "",
            "Next": "",
            "Previous": "",
            "Showing page": "",
            "seconds": "",
            "Did you mean": "",
            "Show more": "",
            "We're sorry. We Cannot find any matches for your search term.": "",
            "Showing results using some of your recent search terms": "",
            "Top keywords searched": "",
            "Ask the Community!": "",
            "Let our amazing customer community help": "",
            "Need More Help?": "",
            "Vist the solution finder today": "",
            "Post a Question": "",
            "Contact Support": "",
            "SOLVED": "",
            "Show less": "",
            "Narrow your search": "",
            "Was above result helpful?": "",
            "Recommended Learning": "",
            "Thank you for your response!": "",
            "Recommendations": "",
            "Useful Articles": "",
            "Sort by": "",
            "Relevance": "",
            "Created Date": "",
            "All Time": "",
            "Past Day": "",
            "Past Week": "",
            "Past Month": "",
            "Past Year": ""
        }
    },
    "Swedish": {
        "type": "LTR",
        "mapping": {
            "Top Searches": "",
            "Sources": "",
            "Search here": "",
            "Advanced Search Options": "",
            "With the exact phrase": "",
            "With one or more words": "",
            "Without the words": "",
            "Results per page": "",
            "Results": "",
            "results": "",
            "Refine Search": "",
            "The sequence of words you enter here will be in the same order and together in the search results. You may leave this field empty.": "",
            "Any one, but not necessarily all of the words you enter here will appear in the search results.": "",
            "All Content": "",
            "Search Tips": "",
            "Enter just a few key words related to your question or problem": "",
            "Add Key words to refine your search as necessary": "",
            "Do not use punctuation": "",
            "Search is not case sensitive": "",
            "": "",
            "If you do not find what you are looking for the first time,reduce the number of key words you enter and try searching again.": "",
            "Minimum supported Internet Explorer version is IE9": "",
            "Sort by Relevance": "",
            "Sort by Created Date": "",
            "Back to Top": "",
            "List View": "",
            "Grid View": "",
            "Next": "",
            "Previous": "",
            "Showing page": "",
            "seconds": "",
            "Did you mean": "",
            "Show more": "",
            "We're sorry. We Cannot find any matches for your search term.": "",
            "Showing results using some of your recent search terms": "",
            "Top keywords searched": "",
            "Ask the Community!": "",
            "Let our amazing customer community help": "",
            "Need More Help?": "",
            "Vist the solution finder today": "",
            "Post a Question": "",
            "Contact Support": "",
            "SOLVED": "",
            "Show less": "",
            "Narrow your search": "",
            "Was above result helpful?": "",
            "Recommended Learning": "",
            "Thank you for your response!": "",
            "Recommendations": "",
            "Useful Articles": "",
            "Sort by": "",
            "Relevance": "",
            "Created Date": "",
            "All Time": "",
            "Past Day": "",
            "Past Week": "",
            "Past Month": "",
            "Past Year": ""
        }
    },
    "Danish": {
        "type": "LTR",
        "mapping": {
            "Top Searches": "",
            "Sources": "",
            "Search here": "",
            "Advanced Search Options": "",
            "With the exact phrase": "",
            "With one or more words": "",
            "Without the words": "",
            "Results per page": "",
            "Results": "",
            "results": "",
            "Refine Search": "",
            "The sequence of words you enter here will be in the same order and together in the search results. You may leave this field empty.": "",
            "Any one, but not necessarily all of the words you enter here will appear in the search results.": "",
            "All Content": "",
            "Search Tips": "",
            "Enter just a few key words related to your question or problem": "",
            "Add Key words to refine your search as necessary": "",
            "Do not use punctuation": "",
            "Search is not case sensitive": "",
            "": "",
            "If you do not find what you are looking for the first time,reduce the number of key words you enter and try searching again.": "",
            "Minimum supported Internet Explorer version is IE9": "",
            "Sort by Relevance": "",
            "Sort by Created Date": "",
            "Back to Top": "",
            "List View": "",
            "Grid View": "",
            "Next": "",
            "Previous": "",
            "Showing page": "",
            "seconds": "",
            "Did you mean": "",
            "Show more": "",
            "We're sorry. We Cannot find any matches for your search term.": "",
            "Showing results using some of your recent search terms": "",
            "Top keywords searched": "",
            "Ask the Community!": "",
            "Let our amazing customer community help": "",
            "Need More Help?": "",
            "Vist the solution finder today": "",
            "Post a Question": "",
            "Contact Support": "",
            "SOLVED": "",
            "Show less": "",
            "Narrow your search": "",
            "Was above result helpful?": "",
            "Recommended Learning": "",
            "Thank you for your response!": "",
            "Recommendations": "",
            "Useful Articles": "",
            "Sort by": "",
            "Relevance": "",
            "Created Date": "",
            "All Time": "",
            "Past Day": "",
            "Past Week": "",
            "Past Month": "",
            "Past Year": ""
        }
    },
    "ar-sa": {
        "type": "RTL",
        "mapping": {
            "Top Searches": "أعلى عمليات البحث",
            "Sources": "مصادر",
            "Search here": "ابحث هنا",
            "Advanced Search Options": "خيارات البحث المتقدم",
            "With the exact phrase": "مع العبارة بالضبط",
            "With one or more words": "مع كلمة واحدة أو أكثر",
            "Without the words": "دون كلام",
            "Results per page": "النتائج لكل صفحة",
            "Results": "النتائج",
            "results": "النتائج",
            "Refine Search": "خيارات البحث",
            "The sequence of words you enter here will be in the same order and together in the search results. You may leave this field empty.": "سيكون تسلسل الكلمات التي تدخلها بنفس الترتيب ومعاينة نتائج البحث. بأمكانك ترك هذا الحقل فارغا.",
            "Any one, but not necessarily all of the words you enter here will appear in the search results.": "أي واحد ، ولكن ليس بالضرورة جميع الكلمات التي تدخلها هنا سوف تظهر في نتائج البحث.",
            "All Content": "كل المحتوى",
            "Search Tips": "نصائح البحث",
            "Enter just a few key words related to your question or problem": "أدخل فقط بضع كلمات رئيسية متعلقة بسؤالك أو مشكلتك",
            "Add Key words to refine your search as necessary": "أضف كلمات مفتاحية لتنقيح بحثك حسب الضرورة",
            "Do not use punctuation": "لا تستخدم علامات الترقيم",
            "Search is not case sensitive": "البحث ليس حساسًا لحالة الأحرف",
            "": "",
            "If you do not find what you are looking for the first time,reduce the number of key words you enter and try searching again.": "إذا لم تجد ما تبحث عنه لأول مرة ، فقم بتخفيض عدد الكلمات الرئيسية التي أدخلتها وحاول البحث مرة أخرى.",
            "Minimum supported Internet Explorer version is IE9": "الحد الأدنى من إصدار Internet Explorer المدعوم هو IE9",
            "Sort by Relevance": "فرز حسب الصلة",
            "Sort by Created Date": "فرز حسب تاريخ الإنشاء",
            "Back to Top": "العودة إلى الأعلى",
            "List View": "عرض القائمة",
            "Grid View": "عرض الشبكة",
            "Next": "التالى",
            "Previous": "سابق",
            "Showing page": "عرض الصفحة",
            "seconds": "ثواني",
            "Did you mean": "هل تعني",
            "Show more": "أظهر المزيد",
            "We're sorry. We Cannot find any matches for your search term.": "نحن آسفون. لا يمكننا العثور على أي تطابقات لعبارة البحث الخاصة بك.",
            "Showing results using some of your recent search terms": "عرض النتائج باستخدام بعض مصطلحات البحث الأخيرة",
            "Top keywords searched": "أهم الكلمات الرئيسية التي تم البحث عنها",
            "Ask the Community!": "اسأل المجتمع!",
            "Let our amazing customer community help": "دع مجتمعنا المدهش يساعد المجتمع",
            "Need More Help?": "هل تريد المزيد من المساعدة؟",
            "Vist the solution finder today": "زيارة مكتشف الحلول اليوم",
            "Post a Question": "ارسل سؤال",
            "Contact Support": "اتصل بالدعم",
            "SOLVED": "تم حلها",
            "Show less": "عرض أقل",
            "Narrow your search": "تضييق نطاق البحث",
            "Was above result helpful?": "كانت النتيجة أعلاه مفيدة؟",
            "Recommended Learning": "التعلم الموصى به",
            "Thank you for your response!": "شكرا لردكم!",
            "Recommendations": "توصيات",
            "Useful Articles": "مقالات مفيدة",
            "Sort by": "ترتيب حسب",
            "Relevance": "ملاءمة",
            "Created Date": "تاريخ الإنشاء",
            "All Time": "",
            "Past Day": "",
            "Past Week": "",
            "Past Month": "",
            "Past Year": ""
        }
    },
    "config": {
        "defaultLanguage": {
            "code": "en",
            "name": "English",
            "label":"English"
        },
        "selectedLanguages": [
            {
                "code": "en",
                "name": "English",
                "label":"English"
            }
        ]
    }
}
;
        var showLess = 'Show less';
        var showMore = 'Show more';
        if (translation[window.localStorage.getItem("language")]) {
            if (translation[window.localStorage.getItem("language")].mapping[showLess]) {
                showLess = translation[window.localStorage.getItem("language")].mapping[showLess];
            }
            if (translation[window.localStorage.getItem("language")].mapping[showMore]) {
                showMore = translation[window.localStorage.getItem("language")].mapping[showMore];
            }
        }
        var id = event.target.id;

        var slittedId = id.split('_showMore')[0];

        var data = document.getElementById(slittedId);

        if (data.classList.contains('su_Expanded')) {

            data.classList.remove('su_Expanded');

            document.getElementById(id).innerHTML = showMore;

        } else {

            data.classList.add('su_Expanded');

            document.getElementById(id).innerHTML = showLess;

        }

    },

    typeSelectFunc: function (component, event, helper, flag, itemRemoved) {
        if(!flag){

            var value = document.getElementById(event.target.id).checked;

            var sr = {};
            sr["Contentname"]= event.target.name,
            sr["immediateParent"]= event.target.min,
            sr["parent"]= event.target.step,
            sr["level"]= event.target.max
            sr["checked"]= document.getElementById(event.target.id).checked;
            sr["label"]= event.target.getAttribute('data-label');
            sr["name"]= event.target.getAttribute('data-name');
        }
        else {
            var sr = itemRemoved;
            document.getElementById(sr.parent+'_checkType_'+sr.Contentname).checked = flag == 2 ? sr.checked : false;
        }

        var finalJson = [];
        var proceed = false;
        var parentAggregations = component.get("v.originalAggregationsData");

        var currentClickedOrder = Array.from(parentAggregations).filter(function (f) {return sr.parent == f.key; })[0];

        component.set("v.currentClickedOrder", currentClickedOrder);
        var customEvent = [];
        customEvent.push(sr);
        var uniqueRows = Array.from(component.get('v.selectedRows'));

        var n = -1;
        uniqueRows.some(function(c, i){ if (c.Contentname == sr.Contentname && c.parent == sr.parent) { n = i; return true; }});
        if(n > -1){
            uniqueRows.splice(n,1);
        }
        	uniqueRows.unshift(sr);

        var uniqueStr = JSON.stringify(uniqueRows);

        uniqueRows = JSON.parse(uniqueStr);

            for (var j = 0; j < uniqueRows.length; j++) {

                var filterList = [];

                var childList = [];

                var obj = {};

                if ( Object.keys(uniqueRows[j]).length == 0 ) continue;

                obj["type"] = uniqueRows[j].parent;

                var typeName = uniqueRows[j].Contentname;

                typeName = typeName.toString().trim();

                var thisObjectParent = {};

                var obj2 = {};

                var objChildren = [];

		        let mergedArray = component.get('v.mergedArray');

                //if (uniqueRows[j].Contentname) {

                    if (uniqueRows[j].Contentname.toString().indexOf('_nested') > -1 || uniqueRows[j].parent.indexOf('_nested') > -1 || uniqueRows[j].Contentname.toString().indexOf('_navigation') > -1 || uniqueRows[j].parent.indexOf('_navigation') > -1) {

                        proceed = true;

                        thisObjectParent = {};

                        var currentParent = Array.from(parentAggregations).filter(function (f) {return uniqueRows[j].parent == f.key; });
                        //getting parent of uniqueRows[j]
                        currentParent[0].values.some(function (f) {

                            if (f.Contentname == uniqueRows[j].immediateParent || f.key == uniqueRows[j].immediateParent) { thisObjectParent = f ; return true; }

                            else if (f.childArray && f.childArray.length)
                                thisObjectParent = helper.nestedParentFilter(helper, f.childArray, uniqueRows[j].immediateParent)
                                if (thisObjectParent.Contentname) { return true; }
                         });

                        if(currentParent[0].label) {uniqueRows[j].label = currentParent[0].label; }
                        var checkOnlyParent = [];
                        var cn = [];
                        cn.push(uniqueRows[j]);

                        //setting all children of uniqueRows[j] = true
                        if( uniqueRows[j].level == "1") {

                            let ind = -1;
                            currentParent[0].values.some(function(f, i) { if ( f.Contentname == uniqueRows[j].Contentname) { ind = i; return true; }});

                            thisObjectParent = currentParent[0].values[ind];

                            //set child array [] if not present
                            thisObjectParent.childArray = thisObjectParent.childArray? thisObjectParent.childArray : [];

                            helper.childArrayCheckbox(helper, currentParent[0].key, thisObjectParent.childArray, uniqueRows[j].checked, uniqueRows);

                            if (uniqueRows[j].hasOwnProperty('checked') && !uniqueRows[j].checked) {
                                thisObjectParent.childArray.forEach(function(child) {
                                    var index = -1;
                                    Array.from(uniqueRows).some(function (f, i) { if (f.parent == child.parent && f.Contentname == child.Contentname) { index = i; return true;}});
                                    if(index > -1) uniqueRows[index] = {};
                                });
                                uniqueRows[j] = {};
                                continue;
                            }
                            else{
                                thisObjectParent.childArray.forEach(function(child){
                                    var index = -1;

                                    Array.from(uniqueRows).some(function (f, i) { if (f.parent == child.parent && f.Contentname == child.Contentname) { index= i; return true;} });
                                    if(index > -1) uniqueRows[index] = {};
                                        // uniqueRows.push({"Contentname": child.Contentname, "immediateParent": child.immediateParent, "level": child.level, "parent" : currentParent[0].key, "checked" : uniqueRows[j].checked});
                                });
                                var ob = {};
                                ob["childName"] = thisObjectParent.Contentname;
                                ob["level"] = thisObjectParent.level;
                                ob["path"] = thisObjectParent.path;
                                objChildren.push(ob);
                            }
                        }
                        var ind = -1;
                        if(thisObjectParent.childArray) {
                            thisObjectParent.childArray.some(function(f, i) { if (f.Contentname == uniqueRows[j].Contentname) { ind = i; return true; } }) ;
                        }
                        if (ind > -1 && thisObjectParent.childArray[ind].childArray) {
                            uniqueRows[j].path = thisObjectParent.childArray[ind].path;
                            //uniqueRows[j].checkedProp = uniqueRows[j].checkedProp === undefined ? uniqueRows[j].checked : uniqueRows[j].checkedProp;
                            helper.childArrayCheckbox(helper, uniqueRows[j].parent, thisObjectParent.childArray[ind].childArray, uniqueRows[j].checked, uniqueRows);
                        }

                        if(thisObjectParent.level > 0){

                            if (uniqueRows[j].hasOwnProperty('checked') && !uniqueRows[j].checked) {
                                while(thisObjectParent.level > 0) {

                                    thisObjectParent.childArray.forEach(function (child){
                                        if(child.Contentname != cn[0].Contentname && document.getElementById(currentParent[0].key+'_checkType_'+child.Contentname).checked){
                                            var index = -1;
                                            Array.from(uniqueRows).some(function (f, i) { if (f.parent == child.parent && f.Contentname == child.Contentname) {  index = i; return true; } });
                                            if(index == -1) {
                                                child.checked = true;
                                                uniqueRows.push(child);
                                            }
                                        }
                                    });

                                    document.getElementById(currentParent[0].key+'_checkType_'+thisObjectParent.Contentname).checked = uniqueRows[j].checked;
                                    var index = -1;
                                    Array.from(uniqueRows).some(function (f, i) { if (f.parent == thisObjectParent.parent && f.Contentname == thisObjectParent.Contentname) { index = i; return true;} });
                                    if(index > -1) uniqueRows[index] = {};

                                    cn[0] = thisObjectParent;
                                    currentParent[0].values.some(function (f) {
                                        if (f.Contentname == cn[0].immediateParent || f.key == cn[0].immediateParent) {thisObjectParent = f; return true;}
                                        else if (f.childArray && f.childArray.length)
                                        thisObjectParent = helper.nestedParentFilter(helper, f.childArray, cn[0].immediateParent)
                                        if (thisObjectParent.Contentname) { return true; }
                                    });
                                    thisObjectParent.checked = false;
                                }
                            }

                            else {
                                if (thisObjectParent && thisObjectParent.childArray)
                                checkOnlyParent = thisObjectParent.childArray.filter(function (o) { if (!uniqueRows.find(function (o2) {
                                    if (o.Contentname === o2.Contentname && o.parent === o2.parent && o.immediateParent === o2.immediateParent)
                                        return o2 })) return o });

                                obj2["childName"] = cn[0].Contentname;
                                obj2["level"] = cn[0].level;
                                obj2["path"] = cn[0].path;
                            }
                        }

                    } else {
			            //if(uniqueRows[j].parent == facet_merged && uniqueRows[j].Contentname.includes('merged') ) {
                        if(uniqueRows[j].Contentname.indexOf('merged_') > -1 ) {
                            let rem = mergedArray.filter ( function (o) {
                                return (o.facetName == uniqueRows[j].parent && uniqueRows[j].Contentname == 'merged_'+o.filterNewName);
                            });

                            let k = -1;
                            parentAggregations.some(function (f, i) { if (f.key == uniqueRows[j].parent) { k = i; return true;} });
                            let i = -1;
                            if(k > -1) {
                                parentAggregations[k].values.some(function (f, index) { if (f.Contentname == uniqueRows[j].Contentname) { i = index; return true;} });
                            }
                            helper.childArrayCheckbox(helper, uniqueRows[j].parent, parentAggregations[k].values[i].childArray, uniqueRows[j].checked);
                            if(i > -1 ) parentAggregations[k].values[i].checked = true;
                            parentAggregations[k].values[i].childArray.forEach(function (d) {
                                var index = -1;
                                Array.from(uniqueRows).some(function (f, i) { if (f.parent == d.parent && f.Contentname == d.Contentname) { index = i; return true; }});
                                if(index > -1) uniqueRows[index] = {};
                            })

                            if( uniqueRows[j].checked){
                                let l  = parentAggregations[k].values[i].childArray.map(function (j) { return j.Contentname; });
                                filterList = filterList.concat(l);
                            }
                            else {
                                uniqueRows[j] = {}
                            }
                        }
                        else if( uniqueRows[j].immediateParent && uniqueRows[j].immediateParent.indexOf('merged_') > -1 && !uniqueRows[j].checked) {

                            let index = -1;
                            Array.from(uniqueRows).some(function (f, i) { if (f.parent == uniqueRows[j].parent && f.Contentname == uniqueRows[j].immediateParent) { index = i; return true;} });
                            if(index > -1) uniqueRows[index] = {};
                            uniqueRows[j] = {}
                        }
                        else {
                            if(uniqueRows[j].hasOwnProperty('checked') && !uniqueRows[j].checked) uniqueRows[j] = {};
                            else filterList.push(typeName);
                        }
                    }
                if (Object.keys(obj2).length > 0) {
                    childList.push(obj2);
                }

                if(objChildren && objChildren.length){

                    childList = objChildren;
                }
                obj["filter"] = filterList;
                if (childList.length > 0) {
                    obj["children"] = childList;
                }
                if (filterList.length > 0 || childList.length > 0) {

                    var ind = -1;
                    Array.from(finalJson).some(function (f, i) { if (f.type == obj.type) { ind = i; return true;} });
                    if(ind > -1){

                        finalJson[ind].filter = finalJson[ind].filter.concat(filterList);

                        if(finalJson[ind].children){

                         	finalJson[ind].children = finalJson[ind].children.concat(childList);
                        }
                    }
                    else
                        finalJson.push(obj);
                }
            }
            uniqueRows = uniqueRows.filter(function(value) { if(Object.keys(value).length !== 0) return value;});

        component.set('v.selectedRows', uniqueRows);
        var currentFilterOrder = Array.from(parentAggregations).find(function (f) { if (f.key == customEvent[0].parent) return f; })
        component.set('v.filterOrder', currentFilterOrder.order);

        let a = JSON.parse(component.get('v.selectedTypeFilter') || '[]').filter(function(c){return c.type == '_index'});

        if (finalJson.length > 0) {

            component.set('v.selectedTypeFilter', JSON.stringify(finalJson));
        } else {
            component.set('v.selectedTypeFilter', "");
        }
        component.set("v.pageNum", "1");
        helper.getValue(component, 'filterCheck', 'true', helper);
    },
    
    asArray: function(component, comp) {
        if (Array.isArray(comp)) return comp;
        else return comp ? [comp] : [];
    },

    pageFunc: function(component, event, helper) {

        var currentPage = parseInt(event.target.id);

        component.set("v.pageNum", "" + currentPage);

        helper.getValue(component, 'pageChange', 'true', helper);

        helper.goToTopFunc(component, event);

    },

    nextPageFunc: function(component, event, helper) {

        var currentPage = parseInt(component.get("v.pageNum")) + 1;

        component.set("v.pageNum", "" + currentPage);

        helper.getValue(component, 'pageChange', 'true', helper);

        helper.goToTopFunc(component, event);

    },

    modalviewFunc: function(component, event, helper) {
        if (document.getElementsByClassName("su__left-sidebar")[0]) {
            document.getElementsByClassName("su__left-sidebar")[0].classList.add("su__fillter-toggle");
            document.getElementsByTagName("body")[0].classList.add("su__overflow-hide");
        }
    },
    FilterModalviewFunc: function(component, event, helper) {
        if (component.get('v.topFiltersLayoutDiv')) {
            document.getElementsByClassName("su__left-sidebar-layout-2")[0].classList.add("su__fillter-toggle");
            document.getElementsByClassName("su__topFilters-overlay")[0].classList.add("su__viewMore-block");
        } else {
            document.getElementsByClassName("su__left-sidebar-layout-2")[0].classList.remove("su__fillter-toggle");
            document.getElementsByClassName("su__topFilters-overlay")[0].classList.remove("su__viewMore-block");
        }
    },
    dismiss_modalFunc: function(component, event, helper) {
        if (document.getElementsByClassName("su__left-sidebar")[0]) {
            document.getElementsByClassName("su__left-sidebar")[0].classList.remove("su__fillter-toggle");
        }
        if (document.getElementsByClassName("su__left-sidebar-layout-2")[0] || document.getElementsByClassName("su__topFilters-overlay")[0]) {
            document.getElementsByClassName("su__left-sidebar-layout-2")[0].classList.remove("su__fillter-toggle");
            document.getElementsByClassName("su__topFilters-overlay")[0].classList.remove("su__viewMore-block");
        }
        document.getElementsByClassName("su__right-sidebar")[0].classList.remove("su__search-tip-toggle");
        document.getElementsByClassName("su__viewMore")[0].classList.remove("su__top-toggle");
        document.getElementsByTagName("body")[0].classList.remove("su__overflow-hide");
        component.set("v.topFiltersLayoutDiv", false);
        component.set("v.showFilterLargeDiv", false);
    },
    runScriptMethodFunc: function (component, event, helper) {
        if(helper.getURLParameter('searchString') != ""){
            var target;
            if (event.target.closest('a')){
                target = event.target.closest('a');
                var data_Id = target.getAttribute("data-id") || "";
                var data_type = target.getAttribute("data-type") || "";
                var data_index = target.getAttribute("data-index") || "";
                var data_rank = target.getAttribute("data-rank") || "";
                var data_url = target.getAttribute("data-url") || "";
                var data_sub = target.getAttribute("data-sub") || "";
                var data_autotuned = target.getAttribute("data-autotuned") || false;
                if (data_rank != '') {
                    data_rank = (+data_rank) + 1;
                }
                var childCmp = component.find("SuAnalytics");
                if (data_Id != "" && data_sub != "") {
                    var auramethodResult = childCmp.analytics('conversion', { index: data_index, type: data_type, id: data_Id, rank: data_rank, convUrl: data_url, convSub: data_sub });
                }
                if (data_autotuned){
                    var auramethodResultAutoTune = childCmp.analytics('autoTuneConversion', { index: data_index, type: data_type, id: data_Id, rank: data_rank, convUrl: data_url, convSub: data_sub });
                }
            }
        }
    },
    toggleSearchTipsFunc: function(component, event, helper) {
        document.getElementsByClassName("su__right-sidebar")[0].classList.add("su__search-tip-toggle");
        document.getElementsByTagName("body")[0].classList.add("su__overflow-hide");
        component.set("v.topFiltersLayoutDiv", false);
        component.set("v.showFilterLargeDiv", false);
    },

    searchResultFunc: function(component, event, helper) {

        var params = event.getParam('arguments');

        var result;

        if (params && params !== undefined) {

            result = params.data;

        } else {

            result = component.get("v.advanceFilterData");

        }

        var totalResult = String(params.pageResult);

        if (result !== undefined && result !== null) {

            var finalJson = '[';

            var totalAggr = '';

            for (var i = 0; i < result.length; i++) {

                if (result[i].valueFilter !== '' && result[i].valueFilter !== undefined && result[i].valueFilter !== 'undefined') {

                    totalAggr += '{"type":"' + result[i].sourceType + '","filter":["' + result[i].valueFilter + '"]},';

                }

            }

            totalAggr = totalAggr.slice(0, totalAggr.length - 1);

            finalJson = finalJson + totalAggr + ']';

            if (finalJson != '') {

                component.set('v.selectedTypeFilter', finalJson);

            }

            if (totalResult !== undefined && totalResult !== '' && totalResult !== 'undefined') {

                component.set('v.pageSize', totalResult);

            }

        }

        helper.getValue(component, 'test', 'true', helper);

    },

    setNames: function(result, setArray) {

        for (var i = 0; i < setArray.length; i++) {

            for (var j = 0; j < setArray[i].values.length; j++) {

                if (!setArray[i].values[j].shortName) {
                    setArray[i].values[j].shortName = "";
                    if (!setArray[i].values[j].displayName) {
                        if (setArray[i].values[j].Contentname.length > 22) {
                            setArray[i].values[j].shortName = setArray[i].values[j].Contentname.substring(0, 22) + '...';
                        }
                    } else {
                        if (setArray[i].values[j].displayName.length > 22) {
                            setArray[i].values[j].shortName = setArray[i].values[j].displayName.substring(0, 22) + '...';
                        }
                    }
                }
            }
        }
        var mapSource = {};

        for (var i = 0; i < setArray[1].values.length; i++) {
            mapSource[setArray[1].values[i].Contentname] = setArray[1].values[i].displayName;
        }

        for (var i = 0; i < result.result.hits.length; i++) {
            result.result.hits[i].highlight.length_SummaryToDisplay = result.result.hits[i].highlight.SummaryToDisplay.join('').length;
            result.result.hits[i].objDisplayName = mapSource[result.result.hits[i].objName];
            result.result.hits[i].highlight.SummaryToDisplayList = [];
            result.result.hits[i].highlight.SummaryToDisplayGrid = [];

            for (var j = 0; j < result.result.hits[i].highlight.SummaryToDisplay.length; j++) {
                result.result.hits[i].highlight.SummaryToDisplayList[j] = result.result.hits[i].highlight.SummaryToDisplay[j];
            }

            for (var j = 0; j < result.result.hits[i].highlight.SummaryToDisplay.length; j++) {
                result.result.hits[i].highlight.SummaryToDisplayGrid[j] = result.result.hits[i].highlight.SummaryToDisplay[j];
            }

        }

        for (var i = 0; i < result.result.hits.length; i++) {
            if (result.result.hits[i].metadata) {
                for (var j = 0; j < result.result.hits[i].metadata.length; j++) {
                    for (var k in result.result.hits[i].metadata[j]) {
                        if (result.result.hits[i].metadata[j][k] == "Tag") {
                            result.result.hits[i].metadata[j].valueString = "";
                            result.result.hits[i].metadata[j].valueString = result.result.hits[i].metadata[j]["value"].join(", ").substring(0, 200);
                        }
                    }

                }
            }
        }
    },
    setCheckboxChecked: function(component, setArray, helper) {
        let selectedStickyFilters = [];
        let selectedRows = [];

        var selectedFilter = JSON.parse(component.get("v.selectedTypeFilter") || "[]");
        let mergedArray = component.get('v.mergedArray');
        let merged_flag = false;

        setArray.forEach(function(facet) {
            facet.tempValues = [];

            if (selectedFilter.length) {

                selectedFilter.some(function(sf) {

                    if (facet.key == sf.type) {

                        facet.values.forEach(function(child) {
                            child.checked = false;
                            merged_flag = false;

                            if (child.Contentname.indexOf('merged_') > -1) {

                                let q = mergedArray.filter(function(o) { return child.Contentname == 'merged_' + o.filterNewName });

                                let r = q[0].filterList.filter(function(f) {
                                    let q = child.childArray.map(function(h) { return h.Contentname });
                                    if (sf.filter.indexOf(f) > -1 && q.indexOf(f) > -1) {
                                        return true;
                                    }
                                    return false;
                                });
                                merged_flag = r.length == child.childArray.length ? true : false;
                            } else merged_flag = false;

                            if (sf.filter.indexOf(child.Contentname.toString()) != -1) {
                                child.checked = true;
                                child.parent = facet.key;
                                child.label = facet.label;
                                selectedRows.push(child);
                                facet.tempValues.push(child);
                            }
                            let selectedFilterArray;
                            if (sf.children) {
                                selectedFilterArray = sf.children.map(function(child) { return child.childName; });
                            }
                            if (sf.type.indexOf('_nested') > -1 || sf.type.indexOf('_navigation') > -1) {
                                if (selectedFilterArray.indexOf(child.Contentname) > -1) {
                                    if (!child.childArray || !child.childArray.length) {
                                        child.checked = true;
                                        child.parent = facet.key;
                                        child.label = facet.label;
                                        selectedRows.push(child);
                                        facet.tempValues.unshift(child);
                                    } else {
                                        child.childArray.forEach(function(f) {
                                            if (selectedFilterArray.indexOf(f.Contentname) == -1) {
                                                selectedFilterArray.push(f.Contentname);
                                            }
                                        })
                                    }
                                }
                            }
                            if (child.childArray && child.childArray.length && sf.children) {
                                child.open = false;
                                let cnt = helper.setchildCheckbox(component, child.childArray, selectedFilterArray, helper, selectedRows, (child.displayName || child.Contentname));
                                if (cnt.count === child.childArray.length && selectedFilterArray.indexOf(child.Contentname) > -1) {
                                    selectedRows = selectedRows.length ? selectedRows.slice(0, selectedRows.length - child.childArray.length) : selectedRows;
                                    selectedRows.push(child);
                                    child.checked = true;
                                    child.sticky_name = (child.displayName || child.Contentname);
                                    facet.tempValues.unshift(child);
                                }
                                child.open = cnt.open;
                                facet.tempValues = facet.tempValues.concat(cnt.tempValues);
                            }

                            if ((child.Contentname.indexOf('merged_') > -1 && child.childArray) || merged_flag) {
                                if (merged_flag) {
                                    child.checked = true;
                                    child.parent = facet.key;
                                    child.label = facet.label;
                                    selectedRows.push(child);
                                    facet.tempValues.push(child);
                                }
                                if (child.showChild == '1') {
                                    child.childArray.forEach(function(o) {
                                        o.checked = false;
                                        if (sf.filter.indexOf(o.Contentname) > -1 || merged_flag) {
                                            o.checked = true;
                                            o.sticky_name = child.displayName + " > " + (o.displayName || o.Contentname);
                                            selectedRows.push(o);
                                            facet.tempValues.push(o);
                                        }
                                    })
                                }
                            }
                        });
                        return true;
                    } else {
                        facet.values.forEach(function(child) { child.checked = false; });
                    }
                });
            } else {
                if (facet.values.length) { facet.values.forEach(function(child) { child.checked = false; }); }
            }
            if (facet.tempValues.length) {
                let x = JSON.parse(JSON.stringify(facet));
                x.values = facet.tempValues;
                if (x.key != '_index') {
                    selectedStickyFilters.push(x);
                }
                delete facet.tempValues;
                delete x.tempValues;
            }
        });
        component.set("v.selectedRows", selectedRows);
        return selectedStickyFilters;
    },

    setchildCheckbox : function (component, childArray, selectedFilterArray, helper, selectedRows, name){
        var count = 0;
        var tempValues = [];
        let open = false;
        for (var j = 0; j < childArray.length; j++) {
            childArray[j].checked = false;
            if (selectedFilterArray.indexOf(childArray[j].Contentname) > -1) {
                open = true;
                childArray[j].checked = true;
                childArray[j].sticky_name = name + " > " + (childArray[j].displayName || childArray[j].Contentname);
                selectedRows.push(childArray[j]);
                tempValues.push(childArray[j]);
                count++;
                if (childArray[j].childArray) {
                    helper.childArrayCheckbox(helper, '', childArray[j].childArray, true, [], true, tempValues, childArray[j].sticky_name);
                }
            } else {
                if (childArray[j].childArray && childArray[j].childArray.length) {
                    var cnt;
                    cnt = helper.setchildCheckbox(component, childArray[j].childArray, selectedFilterArray, helper, selectedRows, name + " > " + (childArray[j].displayName || childArray[j].Contentname));
                    if (cnt.count == childArray[j].childArray.length && selectedFilterArray.indexOf(childArray[j].Contentname) > -1) {
                        childArray[j].checked = true;
                        childArray[j].sticky_name = name + " > " + (childArray[j].displayName || childArray[j].Contentname);
                        tempValues.push(childArray[j]);
                        count++;
                        selectedRows.push(childArray[j]);
                    }
                    tempValues = tempValues.concat(cnt.tempValues);
                    childArray[j].open = cnt.open;
                    open = cnt.open ? cnt.open : open;
                }
            }

        }
        return { count: count, tempValues: tempValues, open: open };
    },

    knowledgeGraph: function(component, response) {

        var flag = false;

        try {
            if (response.metaGraph && Object.keys(response.metaGraph).length > 0) {
                flag = true;
            }

            component.set("v.metaStatus", flag);

            if (flag) {
                var meta = {};
                meta.metaFields = [];
                meta.metaFields = response.metaGraph.metaFields;

                for (var i = 0; i < meta.metaFields.length; i++) {
                    for (var k in meta.metaFields[i]) {
                        if (k == "value") {
                            meta.metaFields[i][k] = meta.metaFields[i][k] ? meta.metaFields[i][k].toString().substring(0, 200) : '';
                        }
                    }
                }

                meta.metaTitle = response.metaGraph.title ? response.metaGraph.title.toString().substring(0, 200) : '';
                meta.metaImg = response.metaGraph.img;
                meta.metaDescription = response.metaGraph.description ? response.metaGraph.description.toString().substring(0, 250) : '';
                meta.metaLink = response.metaGraph.link;
                meta.metaSubtitle = response.metaGraph.subtitle ? response.metaGraph.subtitle.toString().substring(0, 200) : '';

                component.set("v.meta_data", meta);
            }
        } catch (exception) {
            console.log(exception);
        }
        try {
            flag = false;

            if (response.relatedTiles && response.relatedTiles.length > 0) {
                flag = true;
            }

            component.set("v.relatedTilesStatus", flag);

            component.set("v.relatedTiles", response.relatedTiles);

        } catch (exception) {
            console.log(exception);
        }
    },
    featureSnippet: function(component, response) {
        component.set("v.featureSnippet", response.featuredSnippetResult);
        component.set("v.featureSnippetTitle", response.featuredSnippetResult.highlight.TitleToDisplay[0]);
        component.set("v.featureSnippetSteps", response.featuredSnippetResult.featuredSnippet);
    },
    similarSearchSuggestion: function(component, response) {
        try {
            component.set("v.similarSearchSuggestions", response.similarSearches ? response.similarSearches : null);
        } catch (exception) {
            console.log(exception);
        }
    },
    getValue: function(component, searchType, runLoader, helper) {
        var actionBach = window;

        // document.body.style.position ='relative';
        // document.body.style['overflow-y'] = 'unset';
        var c = JSON.parse(localStorage.getItem('theme' + component.get("v.uid")));
        if (c && c.activeTabIndex != 'all' && c.activeTabIndex != undefined && component.get("v.setFlag") && component.get("v.contentSourceExists")) {
            component.set("v.active", c.activeTabIndex);
            component.set("v.defaultTab", c.activeTabIndex);
            var filterValue = '[{"type":"_index","filter":["' + c.activeTabIndex + '"]}]';
            component.set("v.selectedTypeFilter", filterValue);
        }
        if (searchType == 'search' || searchType == 'similarSuggestion') {
            component.set("v.pageNum", "1");
            component.set("v.sortByCheck", helper.getURLParameter('sortBy') != "" ? helper.getURLParameter('sortBy') : '_score');
            component.set("v.pageSizeAdvFiltr", helper.getURLParameter('pageSizeAdv') != "" ? helper.getURLParameter('pageSizeAdv') : "10");
            component.set("v.pageSize", helper.getURLParameter('resultsPerPage') != "" ? helper.getURLParameter('resultsPerPage') : component.get("v.defaultPageSize"));
            component.set("v.exactPhrase", helper.getURLParameter('exactPhrase') != "" ? helper.getURLParameter('exactPhrase') : "");
            component.set("v.withOneOrMore", helper.getURLParameter('withOneOrMore') != "" ? helper.getURLParameter('withOneOrMore') : "");
            component.set("v.withoutTheWords", helper.getURLParameter('withoutTheWords') != "" ? helper.getURLParameter('withoutTheWords') : "");
            // component.set("v.selectedTypeFilter", helper.getURLParameter('selectedType') != "" ?  helper.getURLParameter('selectedType') :  "");
            if (!component.get("v.setFlag") || component.get("v.setFlag") && !c) {
                component.set("v.selectedTypeFilter", helper.getURLParameter('selectedType') != "" ? helper.getURLParameter('selectedType') : "");
            }
            var previousDymString = helper.getURLParameter('dym') ? helper.getURLParameter('dym') : "undefined" ;
        }


        var bodyCom = component.find('dvSpinner3');

        var analyticsCmp = component.find("SuAnalytics");

        var sid = analyticsCmp.analytics('_gz_taid', '');

        $A.util.removeClass(bodyCom, 'su_disSpiner');

        var startTime = new Date();

        if (runLoader == 'true') {

            component.set("v.loadingResult", 0);

        }
        var indexEnabled = component.get("v.contentSourceTab");

        var filterOrderPriority = component.get('v.filterOrder');

        var previousResultAggregation = component.get('v.originalAggregationsData');

        var searchText = '';

        var originalQuery = '';

        searchText = helper.getURLParameter('searchString');

        if (searchType == 'similarSuggestion') {

            searchText = component.get('v.searchString');

            searchType = 'search';
        }

        originalQuery = searchText.trim();

        var EmailregexSlash = '\\\\';

        var regexSlash = new RegExp("\\\\", 'g');

        searchText = searchText.replace(regexSlash, EmailregexSlash);

        var Emailregex = '\\"';

        var regex = new RegExp('\"', 'g');

        searchText = searchText.replace(regex, Emailregex);

        component.set("v.searchString", searchText);

        if (searchText != '') {

            searchText = searchText.trim();

        }

        var filterData = component.get("v.selectedTypeFilter");

        var pageNum = component.get("v.pageNum");

        var currentPageNumber = Number(pageNum);

        var pageSize = component.get("v.pageSize");

        var action = component.get("c.SearchResults");

        var currentClickedOrder = component.get("v.currentClickedOrder");

        var tempClientFilters = JSON.parse(JSON.stringify(previousResultAggregation));

        component.set('v.bookmark_list', false);
        component.set('v.viewSavePopup', false);
        component.set('v.viewConfirmPopup', false);

        JSON.parse(filterData || '[]').some(function(f) {
            if (f.type == '_index') {
                component.set('v.active', f.filter[0]);
            }
        });
        //window.location.hash = encodeURIComponent("pageNum="+pageNum+"&sortBy="+component.get("v.sortByCheck")+"&orderBy=desc&resultsPerPage="+pageSize+"&exactPhrase="+decodeURIComponent(component.get("v.exactPhrase"))+"&withOneOrMore="+decodeURIComponent(component.get("v.withOneOrMore"))+"&withoutTheWords="+decodeURIComponent(component.get("v.withoutTheWords"))+"&selectedType="+encodeURIComponent(filterData));
        action.setParams({
            "searchParams": {
                "searchString": searchText,
                "pageNum": pageNum,
                "sortBy": component.get("v.sortByCheck"),
                "orderBy": "desc",
                "resultsPerPage": pageSize,
                "exactPhrase": component.get("v.exactPhrase"),
                "withOneOrMore": component.get("v.withOneOrMore"),
                "withoutTheWords": component.get("v.withoutTheWords"),
                "selectedType": filterData,
                "referrer": document.referrer,
                "recommendResult": "",
                "indexEnabled": indexEnabled,
                "sid": sid + "$Enter$",
                "language":localStorage.getItem('language')

            }
        });
        //component.set("v.query", action.getParam("searchParams"));
        let query = JSON.parse(JSON.stringify(action.getParam("searchParams")));
        query.pageSizeAdv = component.get("v.pageSizeAdvFiltr");
        component.set("v.query", query);

        var setArray = [];
        action.setCallback(this, function(response) {
            var actionBachHref = actionBach.document.URL;
            if (response.getState() == "SUCCESS") {
                var endTime = new Date();
                var Seconds_from_T1_to_T2 = (endTime.getTime() - startTime.getTime()) / 1000;
                var seconds_Between_Dates = Math.abs(Seconds_from_T1_to_T2);
                var result = response.getReturnValue();
                var aggrData = result.aggregationsArray;
                var suggestData = '';
                //knowledgeGraph
                helper.knowledgeGraph(component, result);
                //featureSnippet
                if (result.featuredSnippetResult) {
                    helper.featureSnippet(component, result);
                } else {
                    component.set("v.featureSnippet", undefined);
                }
                helper.similarSearchSuggestion(component, result);
                if (result.searchDownStatus == false) {
                    var total = result.result.total;
                    var searchResult = result.result.searchQuery;
                    if (result.suggest.simple_phrase.length > 0) {
                        if (result.suggest.simple_phrase[0].options.length > 0) {
                            suggestData = result.suggest.simple_phrase[0].options[0].text;
                            component.set("v.suggestData", suggestData);
                        }
                    }
                    if (document.referrer != actionBachHref) {

                        component.set("v.totalResults", total);

                        var emptyArr = [];
                        
                        var isFreshSearch = false;
                        if (searchType == "search") {
                            isFreshSearch = true;
                            if(component.get("v.resetType")){
                                isFreshSearch = false;
                                component.set("v.resetType", false);
                            }
                        }

                        var auramethodResult = analyticsCmp.analytics('search', { searchString: originalQuery ? originalQuery : component.get("v.exactPhrase") ? component.get("v.exactPhrase") : '', "result_count": component.get("v.totalResults"), page_no: component.get("v.pageNum"), "platformId": component.get("v.uid"), "filter": component.get("v.selectedTypeFilter") != undefined && component.get("v.selectedTypeFilter") != null && component.get("v.selectedTypeFilter") != '' ? component.get("v.selectedTypeFilter") : emptyArr, "isFreshSearch" : isFreshSearch ,"exactPhrase": component.get("v.exactPhrase"),
                          "withOneOrMore": component.get("v.withOneOrMore"),
                          "withoutTheWords": component.get("v.withoutTheWords"),
                          "dym": previousDymString
                        });

                    }

                    var fromPage = currentPageNumber != 1 ? ((currentPageNumber - 1) * Number(pageSize)) + 1 : currentPageNumber;

                    var toPage = currentPageNumber != 1 ? ((currentPageNumber - 1) * Number(pageSize)) + Number(pageSize) : Number(pageSize);

                    if (total < toPage) {

                        toPage = total;

                    }



                    var pagination = [];

                    var index;

                    var totalNumberOfPages = Math.ceil(total / pageSize);

                    aggrData.filter(function(o) {
                        if (o.key.indexOf('_nested') > -1 || o.key.indexOf('_navigation') > -1) {
                            o.values.forEach(function(l) {
                                if (l.childArray && l.childArray.length) {
                                    let parent = [];
                                    parent.push(l.Contentname);
                                    helper.addPathName(component, parent,  l.childArray, helper);
                                }
                            });
                        }

                    });
		            if(result.merged_facets && result.merged_facets.length) {
                        component.set("v.mergedArray", JSON.parse(result.merged_facets) || '[]');
                        if (component.get("v.mergedArray")) {
                            Array.from(component.get("v.mergedArray")).forEach(function (o) {
                                helper.mergeFilters(component, o, aggrData, helper);
                            });
                        }
                    }

                    /* left hand side filter code starts here */

                    if (searchType == 'filterCheck' || searchType == 'pageChange' || searchType == 'sortBy' || searchType == 'indexCall') {

                        var resultObtained = "false";

                        for (var key in aggrData) {

                            if (aggrData.hasOwnProperty(key)) {

                                if (Object.getOwnPropertyNames(aggrData[key]).length != 0) {

                                    if (aggrData[key].order == filterOrderPriority && currentClickedOrder) {


                                        let selectedFilters = JSON.parse(filterData || '[]').filter(function(f) { return f.type == currentClickedOrder.key });

                                        if (!selectedFilters || !selectedFilters.length) {

                                            setArray.push(aggrData[key]);

                                        } else {

                                            if (!aggrData[key].values.length) {

                                                let p = previousResultAggregation.filter(function(f) { return f.key == currentClickedOrder.key })[0];

                                                p.values.map(function(f) {

                                                    f.value = 0;

                                                    if (f.childArray) {

                                                        helper.setChildArrayValue(helper, f.childArray);
                                                    }
                                                });

                                                setArray.push(p);
                                            }
                                            else {

                                                let p = previousResultAggregation.filter( function(f) { return f.key == currentClickedOrder.key} )[0];

                                                setArray.push(p);
                                            }

                                        }

                                    } else {

                                        if ( searchType == 'indexCall' ) {

                                            if (aggrData[key].key == '_index' && component.get('v.active') != 'all' ) { setArray.push(previousResultAggregation.filter( function(f) { return f.key == aggrData[key].key} )[0]); }
                                            else setArray.push(aggrData[key]);

                                        }

                                        else {
                                            if( aggrData[key].key != '_index')
                                                  setArray.push(aggrData[key]);
                                              else {
                                                //   let selectedFilters = JSON.parse(filterData || '[]').filter(function(f) { return f.type == '_type' } );
                                                //   if( !selectedFilters || !selectedFilters.length  ) {
                                                //       setArray.push(aggrData[key]);
                                                //   }
                                                  if( !filterData.length){
                                                    setArray.push(aggrData[key]);
                                                }
                                                  else
                                                      setArray.push(previousResultAggregation.filter( function(f) { return f.key == aggrData[key].key} )[0]);
                                              }
                                        }


                                    }

                                }

                            }

                        }

                        helper.appendTempClientFilters(component, helper, setArray, filterData, tempClientFilters);

                    } else {

                        for (var key in aggrData) {

                            if (aggrData.hasOwnProperty(key)) {

                                if (Object.getOwnPropertyNames(aggrData[key]).length != 0) {

                                    setArray.push(aggrData[key]);

                                }

                            }

                        }

                    }

                    /* filter code ends here */

                    /* code for pagination starts below */

                    if (currentPageNumber <= 4) {

                        for (index = currentPageNumber - 2; index < currentPageNumber; index += 1) {

                            if (index <= 0) {

                                continue;

                            }

                            pagination.push(index);

                        }

                        pagination.push(currentPageNumber);

                        var jIndex;

                        for (jIndex = currentPageNumber + 1; jIndex <= 5; jIndex += 1) {

                            if (jIndex >= totalNumberOfPages + 1) {

                                break;

                            }

                            pagination.push(jIndex);

                        }

                    } else if (currentPageNumber >= 4 && currentPageNumber < totalNumberOfPages - 2) {

                        for (index = currentPageNumber - 2; index < currentPageNumber; index += 1) {

                            if (index <= 0) {

                                continue;

                            }

                            pagination.push(index);

                        }

                        pagination.push(currentPageNumber);

                        for (var jindex = currentPageNumber + 1; jindex <= currentPageNumber + 2; jindex += 1) {

                            if (jindex > totalNumberOfPages) {

                                break;

                            }

                            pagination.push(jindex);

                        }

                    } else {

                        var tempNum;

                        if (currentPageNumber == (totalNumberOfPages - 3)) {

                            tempNum = 3;

                        }

                        if (currentPageNumber == (totalNumberOfPages - 2)) {

                            tempNum = 4;

                        }

                        if (currentPageNumber == (totalNumberOfPages - 1)) {

                            tempNum = 5;

                        }

                        if (currentPageNumber == totalNumberOfPages) {

                            tempNum = 6;

                        }

                        for (index = currentPageNumber - tempNum; index < currentPageNumber; index += 1) {

                            if (index <= 0) {

                                continue;

                            }

                            pagination.push(index);

                        }

                        pagination.push(currentPageNumber);

                        var jindex;

                        for (jindex = currentPageNumber + 1; jindex <= totalNumberOfPages + 2; jindex += 1) {

                            if (jindex > totalNumberOfPages) {

                                break;

                            }

                            pagination.push(jindex);

                        }

                    }


                    /* code for pagination ends */

                    helper.setNames(result, setArray);

                    component.set('v.bookmarkSearches', JSON.parse(localStorage.getItem('bookmark_searches_' + component.get("v.uid")) || "[]"));
                    var c = JSON.parse(localStorage.getItem('theme' + component.get("v.uid")));
                    if (c) {
                        component.set("v.toggleDisplayKeys[0].hideEye", c.hideTitle);
                        component.set("v.toggleDisplayKeys[1].hideEye", c.hideSummary);
                        component.set("v.toggleDisplayKeys[3].hideEye", c.hideMetadata);
                        component.set("v.toggleDisplayKeys[2].hideEye", c.hideUrl);
                        component.set("v.toggleDisplayKeys[4].hideEye", c.hideIcon);

                        if (c["hiddenFacets"]) {
                            component.get('v.emptyResponseAggregations').forEach(function(child) {
                                if (c.hiddenFacets.includes(child.label)) {
                                    child.hide = true;
                                    child.hideEye = true;
                                } else {
                                    child.hide = false;
                                    child.hideEye = false;
                                }
                            })
                        } else {
                            component.get('v.emptyResponseAggregations').forEach(function(child) {
                                child.hide = false;
                                child.hideEye = false;
                            })
                        }

                        if (c["hiddenFacets"]) {
                            setArray.forEach(function(child) {
                                if (c.hiddenFacets.includes(child.label)) {
                                    child.hide = true;
                                    child.hideEye = true;
                                } else {
                                    child.hide = false;
                                    child.hideEye = false;
                                }
                            })
                        } else {
                            setArray.forEach(function(child) {
                                child.hide = false;
                                child.hideEye = false;
                            })
                        }
                        component.set("v.filterToRight", c.filters);
                    }
                    if (component.get("v.filterToRight") == true) {
                        helper.addClasses(component, event, helper);
                    } else {
                        helper.removeClasses(component, event, helper);
                    }

                    var selectedStickyFilter = helper.setCheckboxChecked(component, setArray, helper);
                    var stickyFilter_label = selectedStickyFilter.map(function(c) { return c.label });
                    component.set("v.stickyFilter_label", stickyFilter_label);
                    component.set("v.activeSticky", stickyFilter_label[0]);

                    //if (JSON.parse(component.get("v.selectedTypeFilter") || "[]").length || component.get("v.exactPhrase") != "" || component.get("v.withOneOrMore") != "" || component.get("v.withoutTheWords")!= "" || component.get("v.pageSizeAdvFiltr") != "10") {
                    if (JSON.parse(component.get("v.selectedTypeFilter") || "[]").length || component.get("v.exactPhrase") != "" || component.get("v.withOneOrMore") != "" || component.get("v.withoutTheWords") != "" || component.get("v.defaultPageSize") != pageSize) {

                        component.set('v.showClearFiltersButton', true);
                    } else {

                        component.set('v.showClearFiltersButton', false);
                    }
                    if (c) {
                        component.set("v.hideTitle", c.hideTitle);
                        component.set("v.hideSummary", c.hideSummary);
                        component.set("v.hideMetadata", c.hideMetadata);
                        component.set("v.hideUrl", c.hideUrl);
                        component.set("v.hideIcon", c.hideIcon);
                        if (!component.get("v.setFlag")) {
                            if (c.activeTabIndex) {
                                component.set("v.activeTabIndex", c.activeTabIndex);
                            }
                            if (c.activeTabOrder) {
                                component.set("v.activeTabOrder", c.activeTabOrder);
                            }
                            if (c.accessKeyValue) {
                                component.set("v.accessKeyValue", c.accessKeyValue);
                            }
                        }
                    } else {
                        if(!component.get("v.setFlag")) {
                            component.set("v.values", []);

                            component.get('v.emptyResponseAggregations').forEach(function(child) {
                                child.hide = false;
                                child.hideEye = false;
                            })

                            component.get('v.emptyResponseAggregations').forEach(function(item) {
                                if(item.values.length) {
                                    component.get("v.values").push({ label: item.label, hideEye: item.hideEye, count: item.values.length });
                                }
                            })
                        }
                    }

                    if (component.get("v.setFlag")) {
                        if (c) {
                            component.get('v.emptyResponseAggregations').forEach(function(item) {
                                item.hide = false;
                                item.hideEye = false;
                            })
                            // setArray.forEach(function(child) {
                            //     child.hideEye = false;
                            // })
                            if (c.hiddenFacets.length) {
                                setArray.forEach(function(child) {
                                    if (c.hiddenFacets.includes(child.label)) {
                                        child.hide = true;
                                        child.hideEye = true;
                                    } else {
                                        child.hide = false;
                                        child.hideEye = false;
                                    }
                                })

                                component.get('v.emptyResponseAggregations').forEach(function(item) {
                                    if (c.hiddenFacets.includes(item.label)) {
                                        item.hide = true;
                                        item.hideEye = true;
                                    } else {
                                        item.hide = false;
                                        item.hideEye = false;
                                    }
                                })
                            } else {
                                setArray.forEach(function(child) {
                                    child.hide = false;
                                    child.hideEye = false;
                                })

                                component.get('v.emptyResponseAggregations').forEach(function(child) {
                                    child.hide = false;
                                    child.hideEye = false;
                                })
                            }
                            // setArray.forEach(function(child) {
                            //     component.get("v.values").push({ label: child.label, hideEye: child.hideEye , count: child.values.length});

                            // })

                            component.get('v.emptyResponseAggregations').forEach(function(item) {
                                if(item.values.length) {
                                    component.get("v.values").push({ label: item.label, hideEye: item.hideEye, count: item.values.length });
                                }
                            })

                            if (c.facetsOrder.length) {
                                var xyz = setArray;
                                xyz.forEach(function(d) {
                                    (c.facetsOrder).forEach(function(o) {
                                        if (d.label == o.value.label) {
                                            d.index = o.indexVal;
                                        }

                                    })
                                })

                                xyz.sort(function(a, b) {
                                    return parseFloat(a.index) - parseFloat(b.index);
                                });

                                setArray = xyz;
                                var sortArr = component.get("v.values");
                                sortArr.forEach(function(d) {
                                    (c.facetsOrder).forEach(function(o) {
                                        if (d.label == o.value.label) {
                                            d.index = o.indexVal;
                                        }
                                    })
                                })

                                sortArr.sort(function(a, b) {
                                    return parseFloat(a.index) - parseFloat(b.index);
                                });
                                // component.set("v.values", sortArr);
                            }
                        } else {
                            setArray.forEach(function(child) {
                                child.hide = false;
                                child.hideEye = false;
                            })
                            // setArray.forEach(function(child) {
                            //     component.get("v.values").push({ label: child.label, hideEye: child.hideEye, count: child.values.length });

                            // })

                            component.get('v.emptyResponseAggregations').forEach(function(item) {
                                item.hide = false;
                                item.hideEye = false;
                            })
                            component.get('v.emptyResponseAggregations').forEach(function(item) {
                                if(item.values.length) {
                                    component.get("v.values").push({ label: item.label, hideEye: item.hideEye, count: item.values.length });
                                }
                            })

                        }
                        // component.set("v.setFlag", false);
                    }

                    component.set("v.selectedStickyFilter", selectedStickyFilter);

                    component.set("v.lastPage", "" + totalNumberOfPages);

                    component.set("v.paginationList", pagination);

                    component.set("v.totalResults", total);

                    if (component.get("v.collapsibleSummary")) {
                        for (var i = 0; i < result.result.hits.length; i++) {
                            result.result.hits[i].isCollapsed = true;
                        }
                    } else {
                        for (var i = 0; i < result.result.hits.length; i++) {
                            result.result.hits[i].isCollapsed = false;
                        }
                    }

                    component.set("v.responseListData", result.result.hits);
                    /* Code commented to support showing all tabs to the top */                    
                    // if(component.get('v.setFlag'))
                    // {
                        setArray[0] = component.get('v.filtersArray')[0];
                    // }
                    component.set("v.aggregationsData", setArray);
                    component.set("v.setFlag", false);
                    if (c && c.facetsOrder.length) {
                        var xyz = component.get("v.aggregationsData");
                        xyz.forEach(function(d) {
                            (c.facetsOrder).forEach(function(o) {
                                if (d.label == o.value.label) {
                                    d.index = o.indexVal;
                                }

                            })
                        })

                        xyz.sort(function(a, b) {
                            return parseFloat(a.index) - parseFloat(b.index);
                        });

                        component.set("v.aggregationsData", xyz);
                        component.set("v.applyChanges", false);
                    }

                    component.set("v.originalAggregationsData", setArray);

                    component.set("v.pageNum", pageNum);

                    component.set("v.fromPage", fromPage);

                    component.set("v.toPage", toPage);

                    component.set("v.resultImgUrl", result.icon);

                    component.set("v.searchResultTime", seconds_Between_Dates);

                    if (total == 0) {
                        if (document.referrer != actionBachHref) {
                            var emptyArr = [];
                            // var auramethodResult = analyticsCmp.analytics('search', { searchString: originalQuery, "result_count": component.get("v.totalResults"), page_no: component.get("v.pageNum"), "platformId": component.get("v.uid"), "filter": component.get("v.selectedTypeFilter") != undefined && component.get("v.selectedTypeFilter") != null && component.get("v.selectedTypeFilter") != '' ? component.get("v.selectedTypeFilter") : emptyArr });
                        }
                        component.set("v.totalResults", total);
                        var noResultMsg = component.get("v.noSearchResultFoundMsg");
                        if (noResultMsg !== undefined) {
                            component.set("v.errorMessage", noResultMsg);
                        } else {
                            component.set("v.errorMessage", "Sorry, no results found.");
                        }

                        if (JSON.parse(component.get("v.selectedTypeFilter") || "[]").length || component.get("v.exactPhrase") != "" || component.get("v.withOneOrMore") != "" || component.get("v.withoutTheWords") != "" || component.get("v.pageSizeAdvFiltr") != "10") {

                            component.set('v.showClearFiltersButton', true);
                        } else {

                            component.set('v.showClearFiltersButton', false);
                        }
                    }
                    // window.location.hash = encodeURIComponent("pageNum="+pageNum+"&sortBy="+component.get("v.sortByCheck")+"&orderBy=desc&resultsPerPage="+pageSize+"&exactPhrase="+decodeURIComponent(component.get("v.exactPhrase"))+"&withOneOrMore="+decodeURIComponent(component.get("v.withOneOrMore"))+"&withoutTheWords="+decodeURIComponent(component.get("v.withoutTheWords"))+"&selectedType="+encodeURIComponent(filterData)+"&contentSources="+encodeURIComponent(JSON.stringify(setArray[0]))+"&active="+decodeURIComponent(component.get("v.active")));
                    window.location.hash = encodeURIComponent("pageNum=" + pageNum + "&sortBy=" + component.get("v.sortByCheck") + "&orderBy=desc&resultsPerPage=" + pageSize + "&pageSizeAdv=" + component.get("v.pageSizeAdvFiltr") + "&exactPhrase=" + encodeURIComponent(component.get("v.exactPhrase")) + "&withOneOrMore=" + encodeURIComponent(component.get("v.withOneOrMore")) + "&withoutTheWords=" + encodeURIComponent(component.get("v.withoutTheWords")) + "&selectedType=" + encodeURIComponent(filterData));
                } else {
                    component.set("v.searchUnifyDownStatus", result.searchDownStatus);
                    if (searchText == '') {
                        searchText = 'test';
                    }
                    if (result.searchCallFail != '') {
                        window.location.href = component.get("v.commBaseURL") + component.get("v.defaultSearchPage") + '/' + searchText;
                    }
                    if (result.searchDownStatus == true) {
                        window.location.href = component.get("v.commBaseURL") + component.get("v.defaultSearchPage") + '/' + searchText;
                    }
                }
                component.set("v.domWidth", document.body.clientWidth > 480);
                $A.util.addClass(bodyCom, 'su_disSpiner');
            } else {
                $A.log("Errors", response.getState());
            }
            component.set("v.loadingResult", 1);
        });
        $A.enqueueAction(action);
    },
    nestedParentFilter: function(helper, currentValue, key) {
        var thisObject = {};
        currentValue.some(function(f) {
            if (f.Contentname == key) {
                thisObject = f;
                return true;
            } else if (f.childArray && f.childArray.length) {
                thisObject = helper.nestedParentFilter(helper, f.childArray, key);
                if (Object.keys(thisObject).length) return true;
            }
        })
        return thisObject;
    },

    childArrayCheckbox : function (helper, parent, childArray, value, uniqueRows, renderResponse, tempValues, name) {
        childArray.forEach(function(c) {

            c.checked = value;
            if(uniqueRows && uniqueRows.length) {
                let index = -1;
                Array.from(uniqueRows).some(function(f, i) { if (f.parent == c.parent && f.Contentname == c.Contentname) { index = i; return true; } });
                if (index !== -1) { uniqueRows[index] = {}; }
            }

            if(renderResponse){ if(value) c.sticky_name = name + " > " + (c.displayName || c.Contentname); tempValues.push(c); }

            else{ if(document.getElementById(parent+'_checkType_'+c.Contentname)) document.getElementById(parent+'_checkType_'+c.Contentname).checked = value;  }

            if(c.childArray){

                helper.childArrayCheckbox(helper, parent, c.childArray, value, uniqueRows, renderResponse, tempValues, name + " > " + (c.displayName || c.Contentname));

            }

        });
    },

    addClasses: function(component, event, helper) {
        if (!document.getElementsByClassName('su__css-scope-layout-2')[0] || !document.getElementsByClassName('su__css-scope-layout-3')[0]) {
            if (document.getElementById('filtersSec')) {
                document.getElementById('filtersSec').classList.add('filtersToRight');
                document.getElementById('resultsSec').classList.add('filtersToLeft');
            }
        }
    },

    removeClasses: function(component, event, helper) {
        if (!document.getElementsByClassName('su__css-scope-layout-2')[0] || !document.getElementsByClassName('su__css-scope-layout-3')[0]) {
            if (document.getElementById('filtersSec')) {
                document.getElementById('filtersSec').classList.remove('filtersToRight');
                document.getElementById('resultsSec').classList.remove('filtersToLeft');
            }
        }

    },

    appendTempClientFilters : function (component, helper, setArray, filterData, tempClientFilters) {
        setArray.map(function (f, i) {
            let selectedFilter = JSON.parse(filterData || '[]').filter(function(t) { return t.type == f.key && t.type != '_index' } )[0];

            let mergedfilters = component.get("v.mergedArray") ? Array.from(component.get("v.mergedArray")).filter ( function (o) { return (o.facetName == f.key); }) : [];
            let filterList = mergedfilters.filter(function (o) {
                let array = o.filterList.filter(function(element) { if (selectedFilter && selectedFilter.filter) { return selectedFilter.filter.indexOf(element) > -1 ; } });
                if(array.length > 0){
                        selectedFilter.filter.push('merged_'+o.filterNewName);
                    return array;
                }
            });


            if (selectedFilter) {
                let childArr = [];
                if (selectedFilter.children) {
                    childArr = selectedFilter.children.map(function(f) { return f.childName });
                }
                selectedFilter = selectedFilter.filter.concat(childArr);

                for (var key in selectedFilter) {
                    var found = false;
                    let merged_index = -1;
                    f.values.filter(function(x, i) {
                        if ((x.contentName || x.Contentname).toString() === selectedFilter[key].toString()) {
                            found = true;
                            merged_index = i;
                            return found;
                        }
                    })
                    if (!found) {
                        f.values.some(function(s) {
                            if (s.childArray) {
                                found = helper.checkChildArrayValue(helper, s.childArray, selectedFilter[key]);
                                if (found) return found;
                            }
                        })
                    }
                    if (!found) {
                        tempClientFilters.map(function(m) {
                            if (f.key === m.key) {
                                m.values.map(function(z) {
                                    if ((z.contentName || z.Contentname).toString() === selectedFilter[key].toString()) {
                                        z.value = 0;
                                        if (z.Contentname.indexOf('merged_') > -1 && z.childArray) {
                                            let children = z.childArray.filter(function(h) {
                                                if (selectedFilter.indexOf(h.Contentname) > -1) {
                                                    h.value = 0;
                                                    return true;
                                                }
                                            });
                                            z.childArray = children || [];
                                        }
                                        f.values.push(z);
                                    } else if (z.childArray && !f.values.length) {
                                        z.value = 0;
                                        helper.setChildArrayValue(helper, z.childArray);
                                        f.values.push(z);
                                    }
                                })
                            }
                        })
                    } else if (selectedFilter[key].indexOf('merged_') > -1 && merged_index > -1) {
                        helper.updateMergeFilter(selectedFilter[key], filterList, f, selectedFilter, merged_index, tempClientFilters);
                    }
                }
            }
        })
    },

    setChildArrayValue: function(helper, childArray) {
        childArray.forEach(function(f) {
            f.value = 0;
            if (f.childArray) {
                helper.setChildArrayValue(helper, f.childArray);
            }
            f.value = f.checked ? 0 : f.value;
        })
    },
    updateMergeFilter: function(key, filterList, f, selectedFilter, merged_index, tempClientFilters) {
        let t = [];
        t = filterList.filter(function(j) {
        if(key == 'merged_'+j.filterNewName)
            return true;
        });
        let children = f.values[merged_index].childArray.map(function (g) { return g.Contentname});
        selectedFilter.forEach(function(p) {
            if (children.indexOf(p) == -1 && t.length && t[0].filterList.indexOf(p) > -1 && selectedFilter.indexOf(p)) {
                tempClientFilters.map(function(m) {
                    if (f.key === m.key) {
                        m.values.filter(function(o) {
                            if (o.Contentname == key) {
                                let i = -1;
                                o.childArray.some(function(u, index) { if (u.Contentname == p) { i = index; return true; } });
                                if (i > -1) {
                                    o.childArray[i].value = 0;
                                    f.values[merged_index].childArray.push(o.childArray[i]);
                                }
                            }
                        })
                    }
                })
            }
        })
    },
    checkChildArrayValue: function(helper, childArray, key, values) {
        for (var k in childArray) {
            let z = childArray[k];
            if ((z.contentName || z.Contentname).toString() === key.toString()) {

                return true
            } else if (z.childArray && z.childArray.length) {
                let t = helper.checkChildArrayValue(helper, z.childArray, key, values);
                if (t) return t;
            }
        }
    },

    pushSelected: function(helper, childArray, key, values) {

        for (var k in childArray) {
            let z = childArray[k];
            if ((z.contentName || z.Contentname).toString() === key.toString()) {
                z.value = 0;
                if (z.childArray && z.childArray.length) {
                    helper.setChildArrayValue(helper, z.childArray);
                }
                return true;
            } else if (z.childArray) {
                let t = helper.pushSelected(helper, z.childArray, key, values);
                if (t) {
                    z.value = 0;
                    return t;
                }
            }
        }
    },

    removeBookmarksList: function(component, deleteList, helper) {

        let uid = component.get("v.uid");

        for (var j = 0; j < deleteList.length; j++) {

            let item = deleteList[j];

            let a = JSON.parse(localStorage.getItem('bookmark_searches_' + uid) || '[]');

            let index = -1;

            for (var i = 0; i < a.length; i++) {

                if (a[i].title == item.title && a[i].href == item.href) {

                    index = i;

                    break;
                }
            }
            if (index > -1) a.splice(index, 1);

            localStorage.setItem("bookmark_searches_" + uid, JSON.stringify(a));
        }


        let c = JSON.parse(localStorage.getItem('bookmark_searches_' + uid) || "[]");

        component.set("v.bookmarkSearches", c);
    },
    addPathName: function(component, parent, childArray, helper) {

        childArray.forEach(function(o) {
            o.path = JSON.parse(JSON.stringify(parent));
            if (o.childArray && o.childArray.length) {
                let p = JSON.parse(JSON.stringify(parent));
                p.push(o.Contentname)
                helper.addPathName(component, p, o.childArray, helper);
            }
        });
    },

    mergeFilters : function ( component, h, aggrData, helper){
	    let k = -1;
        aggrData.some(function(f, i) { if(f.key == h.facetName) { k = i; return true;} });
        let l = k > -1 ? aggrData[k].values.filter(function (f) { return  h.filterList.indexOf(f.Contentname) > -1 }) : [];
        let v =0;
        l.forEach (function (f) {
            v += f.value;
        });

        if (l.length) {
            let place = aggrData[k].values.length;
            let childArray = [];
            let s = JSON.parse(JSON.stringify(l[0]));
            l.forEach(function(f) {
                let index = -1;
                aggrData[k].values.some(function(d, i) { if (d.Contentname == f.Contentname) { index = i; return true; } });
                childArray.push(aggrData[k].values[index]);
                if (index < place) place = index;
                if (index > -1) aggrData[k].values.splice(index, 1);
            });

            childArray.forEach(function(f) {
                f.immediateParent = 'merged_' + h.filterNewName;
                f.level = 2;
                f.parent = h.facetName;
                f.childName = f.Contentname;
            });
            s.displayName = h.filterNewName;
            s.Contentname = 'merged_' + h.filterNewName;
            s.Contentname_short = h.filterNewName;
            s.value = v;
            s.merged = true;
            s.showChild = h.showChild;
            s.childArray = JSON.parse(JSON.stringify(childArray));
            aggrData[k].values.splice(place, 0, s);
        }
        //console.log(Array.from(component.get("v.mergedArray")));
    },
    clickSearchSuggestion: function(component, event, helper, suggestionValue) {
        component.set("v.searchString", suggestionValue);
        var searchBoxEvent = $A.get("e.SU_Ltng:fillSearchBox");
        searchBoxEvent.setParams({ "searchString": suggestionValue });
        searchBoxEvent.fire();
        helper.getValue(component, 'similarSuggestion', 'true', helper);
    },
    dymClickHelper: function(component, event, helper, dymClickedString) {
        var previousDymString = component.get("v.searchString");
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "isredirect": false,
            "url": component.get("v.currentCommunityURL") + "?searchString=" + encodeURIComponent(dymClickedString)
        });
        urlEvent.fire();
        window.location.hash = encodeURIComponent("&pageNum=1&sortBy=" + component.get("v.sortByCheck") + "&orderBy=desc&resultsPerPage=" + component.get("v.pageSize") + "&pageSizeAdv=" + component.get("v.pageSizeAdvFiltr") + "&exactPhrase=" + encodeURIComponent(component.get("v.exactPhrase")) + "&withOneOrMore=" + encodeURIComponent(component.get("v.withOneOrMore")) + "&withoutTheWords=" + encodeURIComponent(component.get("v.withoutTheWords")) + "&selectedType=" + encodeURIComponent(helper.getURLParameter('selectedType')) + "&dym=" + encodeURIComponent(previousDymString));
        component.set("v.searchString", dymClickedString);
        var searchBoxEvent = $A.get("e.SU_Ltng:fillSearchBox");
        searchBoxEvent.setParams({ "searchString": dymClickedString });
        searchBoxEvent.fire();
        helper.getValue(component, 'search', 'true', helper)
    }
})