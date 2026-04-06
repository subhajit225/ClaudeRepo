import { LightningElement, api, track } from 'lwc';

export default class KcsknowblerarticleCards extends LightningElement {
  @api flexipageregionwidth;

  @api article = [];

  @api currentuserlanguage;

  @api contenthealthdata;

  names;

  lastname;

  initials;

  @api contentstandard;

  getLayoutSize = 12;

  clickData;

  cardLength = 0;

  @track querys;

  @api parameters;

  @track loadingCard;

  @track colorHexArray = [];

  @track articlesData = [];

  @api ispublisharticletab;

  @track contenthealthdatamap = new Map();

  @api newnumber;

  @api languagechanged;

  connectedCallback() {
    if (this.contenthealthdata && this.contenthealthdata.data) {
      for (let i = 0; i < this.contenthealthdata.data.length; i++) {
        if (this.contenthealthdata.data[i].article_id_prediction != null) {
          this.contenthealthdatamap.set(
            this.contenthealthdata.data[i].article_id_prediction,
            this.contenthealthdata.data[i]
          );
        }
        if (this.contenthealthdata.data[i].article_id != null) {
          this.contenthealthdatamap.set(
            this.contenthealthdata.data[i].article_id,
            this.contenthealthdata.data[i]
          );
        }
      }
    }
  }

  @api destobj;

  get showdropdown() {
    return this.clickData;
  }

  @api
  set showdropdown(data) {
    this.dotClick(data);
  }

  get articles() {
    return this.article;
  }

  @api
  set articles(data) {
    if (data.length) {
      this.articlesData = [];
      this.article = [...data];
      this.getData();
    }
  }

  get query() {
    return this.querys;
  }

  @api
  set query(data) {
    this.querys = {
      ...data
    };
  }

  renderedCallback() {}

  getData() {
    if (this.flexipageregionwidth) this.getSize(this.flexipageregionwidth);
    else if (window.innerWidth < 768) this.getSize('SMALL');
    else if (window.innerWidth >= 768 && window.innerWidth < 992)
      this.getSize('MEDIUM');
    else if (window.innerWidth >= 992) this.getSize('LARGE');
    else this.getSize('');
  }

  getSize(layout) {
    switch (layout) {
      case 'SMALL':
        this.getLayoutSize = 12;
        this.range(0, 1);
        break;
      case 'MEDIUM':
        this.getLayoutSize = 6;
        this.range(0, 2);
        break;
      case 'LARGE':
        this.getLayoutSize = 4;
        this.range(0, 3);
        break;
      default:
        this.getLayoutSize = 4;
        this.range(0, 3);
        break;
    }
  }

  get getSmallLayout() {
    return (
      this.flexipageregionwidth == 'SMALL' ||
      this.flexipageregionwidth == 'MEDIUM' ||
      this.flexipageregionwidth == 'LARGE'
    );
  }

  dotClick(event) {
    if (!event) return;
    this.articlesData = this.articlesData.map((res) => {
      res.values.map((elm) => {
        if (
          event?.detail?.ArticleNumber &&
          elm.ArticleNumber == event.detail?.ArticleNumber
        )
          elm.showDropdown = !elm.showDropdown;
        else elm.showDropdown = false;

        return elm;
      });

      return res;
    });
  }

  previewOpen(event) {
    if (event?.detail?.ArticleNumber) {
      this.articlesData = this.articlesData.map((res) => {
        res.values.map((elm) => {
          if (elm.ArticleNumber != event.detail?.ArticleNumber) {
            elm.open = false;
          }

          return elm;
        });

        return res;
      });
    }
  }

  updatePageHandler(event) {
    if (this.template.querySelector(`[data-id="top"]`)) {
      const topDiv = this.template.querySelector(`[data-id="top"]`);
      topDiv.scrollIntoView({
        behavior: 'smooth',
        block: 'start',
        inline: 'nearest'
      });
    }
    // Dispatched and handled at "articleList"
    this.dispatchEvent(
      new CustomEvent('updatelist', {
        detail: {
          records: event.detail.records
        }
      })
    );
  }

  range(start, end) {
    this.loadingCard = Array(end - start)
      .fill()
      .map(() => {
        return {
          key: 0,
          values: []
        };
      });
    this.changeArticlesData(end);
  }

  changeArticlesData(end) {
    const articlesDat = JSON.parse(JSON.stringify(this.article));
    let i = 0;

    while (i < articlesDat.length) {
      for (let j = 0; j < end; j++) {
        if (i < articlesDat.length) {
          this.loadingCard[j].key = `article${i}`;
          articlesDat[i].initials = `${articlesDat[i]?.Owner?.FirstName?.charAt(
            0
          )}${articlesDat[i]?.Owner?.LastName?.charAt(0)}`;
          articlesDat[i].showDropdown = false;
          articlesDat[i].open = false;
          const colorIndex = this.colorHexArray.findIndex(
            (res) => res.name == articlesDat[i].initials
          );
          if (colorIndex > -1)
            articlesDat[i].hexCode = this.colorHexArray[colorIndex]?.code;
          else {
            const randomColor = this.generateRandomColor();
            articlesDat[i].hexCode = randomColor;
            this.colorHexArray.push({
              name: articlesDat[i].initials,
              code: randomColor
            });
          }
          this.loadingCard[j].values.push(articlesDat[i]);
        }
        i++;
      }
    }

    this.articlesData = [...this.loadingCard];
    this.cardLength = this.articlesData.length;
  }

  generateRandomColor() {
    const letters = '0123456789ABCDEF';
    let color = '#';
    for (let i = 0; i < 6; i++) {
      color += letters[Math.floor(Math.random() * 16)];
    }

    return color;
  }

  openManageScreen(event) {
    // Dispatched and handled at "articleList"
    this.dispatchEvent(
      new CustomEvent('managearticle', {
        detail: JSON.parse(JSON.stringify(event.detail))
      })
    );
  }
}