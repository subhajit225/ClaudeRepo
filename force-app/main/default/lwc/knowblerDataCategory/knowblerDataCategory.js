import { api, LightningElement, track, wire } from 'lwc';
import describeDataCateogryGroupStructuresSample from '@salesforce/apex/SU_Knowbler.DataCategoryController.describeDataCateogryGroupStructuresSample';
import getDataCategories from '@salesforce/apex/SU_Knowbler.DataCategoryController.getDataCategories';

export default class KnowblerDataCategory extends LightningElement {
  @api recordid;

  @api selectedcategorytree;

  @api iseditarticle;

  @api flexipageregionwidth;

  @track categoryData = [];

  @track itensAll = [];

  @track ikea = [];

  @track dataCategory = [];

  @track categories = [];

  @track firstTimeLoad = true;

  @api alldatacategories;

  @track refreshdataCat;

  @track dataCategoryBck;

  @api
  get refreshdata() {}

  set refreshdata(data) {
    const ob = [];
    if (data?.length)
      data.forEach((res) => {
        ob.push({
          DataCategoryName: res.name,
          DataCategoryGroupName: res.categoryGroup
        });
      });
    this.categories = [...ob];
    if (this.flexipageregionwidth && this.firstTimeLoad == false) {
      this.dataCategory = [];
      this.firstTimeLoad = true;
      this.getUpdate(JSON.parse(JSON.stringify(this.dataCategoryBck)));
      this.firstTimeLoad = false;
    }
  }

  @wire(describeDataCateogryGroupStructuresSample, {
    allCategories: '$alldatacategories'
  })
  categories({ error, data }) {
    if (data) {
      this.itensAll = [...data];
      const itemArr = [];
      this.itensAll.forEach((res) => {
        itemArr.push(this.recursiveCategory(JSON.parse(res)));
      });
      const arr = [];
      itemArr.forEach((res) => {
        arr.push(res[0]);
      });
      this.dataCategoryBck = JSON.parse(JSON.stringify(arr));
      if (this.categories) {
        this.getUpdate(arr);
      } else if (!this.iseditarticle) this.ikea = [...arr];
      if (this.iseditarticle) {
        this.getSelectedDataCategory(arr);
      }
      if (this.selectedcategorytree && this.selectedcategorytree.length) {
        this.ikea = JSON.parse(this.selectedcategorytree);
      }
    } else if (error) {
      this.error = error;
      this.template
        .querySelector('c-knowbler-modal-component')
        .showError(error);
    }
  }

  async getSelectedDataCategory(arr) {
    try {
      const result = await getDataCategories({
        parentId: this.recordid
      });
      if (result) {
        this.categories = [...new Set(result.map((item) => item))];
        this.getUpdate(arr);
        this.firstTimeLoad = false;
      }
    } catch (error) {
      this.template
        .querySelector('c-knowbler-modal-component')
        .showError(error);
    }
  }

  @api
  editForm() {
    if (!this.flexipageregionwidth) {
      this.dispatchEvent(
        new CustomEvent('savecategory', {
          detail: {
            dataCategory: this.dataCategory,
            selectedCategoryTree: this.ikea
          }
        })
      );
    }
  }

  getUpdate(arr) {
    const allCategory = this.recursivedataCategory(arr, false);
    this.editForm();
    this.ikea = [];
    this.ikea = [...allCategory];
  }

  recursiveCategory(data) {
    data.map((res) => {
      res.expanded = false;
      res.checked = false;
      res.disabled = false;

      if (res.listChildCategory.length) {
        res.listChildCategory = this.recursiveCategory(res.listChildCategory);
      }
    });

    return data;
  }

  recursivedataCategory(data, checked) {
    data.map((res) => {
      if (
        (this.iseditarticle && this.firstTimeLoad) ||
        (this.firstTimeLoad && this.categories?.length)
      ) {
        const isContain = this.categories.find(
          (el) =>
            el.DataCategoryName == res.name &&
            el.DataCategoryGroupName == res.categoryGroup
        );
        if (isContain) {
          res.checked = true;
          res.expanded = true;
        }
      }
      if (res.checked || checked) {
        if (res.checked)
          this.dataCategory.push({
            name: res.name,
            label: res.label,
            categoryGroup: res.categoryGroup,
            listChildCategory: res.listChildCategory
          });
        if (res.listChildCategory.length) {
          res.listChildCategory.map((elm) => {
            elm.disabled = true;
            elm.checked = false;
          });
          res.listChildCategory = this.recursivedataCategory(
            res.listChildCategory,
            true
          );
        }
      } else if (res.listChildCategory.length) {
        res.listChildCategory.map((elm) => {
          elm.disabled = false;
        });
        res.listChildCategory = this.recursivedataCategory(
          res.listChildCategory,
          false
        );
      }
      if (this.firstTimeLoad) {
        res.isparent = res.listChildCategory.some((elm) => {
          return elm.checked == true || elm?.isparent == true;
        });
        if (res.isparent) res.expanded = true;
      }
    });

    return data;
  }

  changeValue(event) {
    if (!event.detail.parent) {
      this.dataCategory = [];
      const allCategory = this.recursivedataCategory(
        event.detail.item,
        false,
        false
      );
      this.ikea = [];
      this.ikea = [...allCategory];

      this.dispatchEvent(
        new CustomEvent('savecategory', {
          detail: {
            dataCategory: this.dataCategory,
            selectedCategoryTree: this.ikea
          }
        })
      );
    }
  }
}