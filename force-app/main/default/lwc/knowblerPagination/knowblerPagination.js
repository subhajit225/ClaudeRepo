import { LightningElement, api, track } from 'lwc';

export default class KnowblerSuPagination extends LightningElement {
  currentPage = 1;

  totalRecords;

  recordSize;

  totalPage = 0;

  get records() {
    return this.query;
  }

  @api
  set records(data) {
    if (data) {
      this.currentPage = data.currentPage;
      this.totalRecords = data.count;
      this.recordSize = Number(data.numPerPage);
      this.totalPage = Math.ceil(data.count / this.recordSize);
      this.pageArr = this.pagination(this.currentPage, this.totalPage);
    }
  }

  renderedCallback() {
    if (this.totalRecords <= this.recordSize) {
      if (this.template.querySelector('.su_pagination'))
        this.template.querySelector('.su_pagination').style = `display:none;`;
    }
    this.addRemoveClass();
  }

  get disablePrevious() {
    return this.currentPage <= 1;
  }

  get disableNext() {
    return this.currentPage >= this.totalPage;
  }

  previousHandler() {
    if (this.currentPage > 1) {
      this.currentPage -= 1;
      this.updateRecords();
    }
  }

  nextHandler() {
    if (this.currentPage < this.totalPage) {
      this.currentPage += 1;
      this.updateRecords();
    }
  }

  updateRecords() {
    this.dispatchEvent(
      new CustomEvent('update', {
        detail: {
          records: this.currentPage
        }
      })
    );
  }

  changePage(event) {
    if (isNaN(event.target.name)) {
      return;
    }

    this.currentPage = event.target.name;
    this.updateRecords();
  }

  getRange(start, end) {
    return Array(end - start + 1)
      .fill()
      .map((_, idx) => start + idx);
  }

  addRemoveClass() {
    const badgeClass = this.template.querySelectorAll('lightning-button');
    badgeClass &&
      badgeClass.forEach((element) => {
        if (element.classList.contains('active'))
          element.classList.remove('active');
      });
    const currentId = this.template.querySelector(
      `[data-id="${this.currentPage}"]`
    );
    if (currentId) currentId.className = 'active';
  }

  pagination = (currentPage, pageCount) => {
    let delta;
    if (pageCount <= 3) {
      delta = 3;
    } else {
      delta = currentPage > 4 && currentPage < pageCount - 3 ? 3 : 4;
    }

    const range = {
      start: Math.round(currentPage - delta / 2),
      end: Math.round(currentPage + delta / 2)
    };

    if (range.start - 1 === 1 || range.end + 1 === pageCount) {
      range.start += 1;
      range.end += 1;
    }

    let pages =
      currentPage > delta
        ? this.getRange(
            Math.min(range.start, pageCount - delta),
            Math.min(range.end, pageCount)
          )
        : this.getRange(1, Math.min(pageCount, delta + 1));

    const withDots = (value, pair) =>
      pages.length + 1 !== pageCount ? pair : [value];

    if (pages[0] !== 1) {
      pages = withDots(1, [1, '...']).concat(pages);
    }

    if (pages[pages.length - 1] < pageCount) {
      pages = pages.concat(withDots(pageCount, ['...', pageCount]));
    }
    const arr = [];
    pages.forEach((elm) => {
      arr.push({ value: elm, isDisabled: isNaN(elm) });
    });

    return arr;
  };
}