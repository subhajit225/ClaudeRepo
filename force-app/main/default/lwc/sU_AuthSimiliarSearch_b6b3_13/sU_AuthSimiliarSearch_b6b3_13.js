import { LightningElement, api } from 'lwc';
import { fireEvent } from 'c/authsupubsub_b6b3_13';
export default class SU_AuthSimiliarSearch extends LightningElement {
    @api similiarSearchData;
    @api similarSearches;
    clickSearchSuggestion(event) {
        let similiarSearchString = event.target.dataset.val;
        fireEvent(null, 'setsearchstring', similiarSearchString);
        fireEvent(null, 'searchPage', { searchString: similiarSearchString, isFreshSearch: -1});
    }
}