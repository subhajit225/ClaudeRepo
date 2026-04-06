const phoneRegEx =  /^\+?\d{1,4}?[-.\s]?\(?\d{1,3}?\)?[-.\s]?\d{1,4}[-.\s]?\d{1,4}[-.\s]?\d{1,9}$/;
const rubrikEmailValidation = new RegExp(
  "^[a-zA-Z][a-zA-Z0-9]*(?:[.|-|_][a-zA-Z0-9]+)*@[rR][uU][bB][rR][iI][kK].[cC][oO][mM](?:,[a-zA-Z][a-zA-Z0-9]*(?:[.|-|_][a-zA-Z0-9]+)*@[rR][uU][bB][rR][iI][kK].[cC][oO][mM])*$"
);
let rmaId;

const urlParams = new URLSearchParams(location.search);
const caseId = urlParams.get("id");
const accId = urlParams.get("accId");
const csNum = urlParams.get("csNum");
const accountDetails = {};
let accountId;
let caseNumber;
let clusterUuid;
let allFailures;
let selectedComponent;
const dataTableRowSize = 1000;
const dataTableInstances = {
  appliance: false,
  chassis: false,
  hdd: false,
  ssd: false,
  memory: false,
  node: false,
  psu: false,
  cmos: false,
};
const componentNames = {
  appliance: "Appliance",
  chassis: "Chassis",
  hdd: "HDD",
  ssd: "SSD",
  memory: "Memory",
  node: "Node",
  psu: "Power Supply Unit",
  cmos: "CMOS Battery",
};

const isDataRetrieved = {
  appliance: false,
  chassis: false,
  hdd: false,
  ssd: false,
  memory: false,
  node: false,
  psu: false,
  cmos: false,
};

let dataTableInstance;

const retrievedData = {
  appliance: [],
  chassis: [],
  hdd: [],
  ssd: [],
  memory: [],
  node: [],
  psu: [],
  cmos: [],
};

const dataTableInstancesInfo = {
  appliance: {
    hasFilter: false,
    filterInfo: {
      By: "cluster",
      forValue: "",
    },
    totalSize: 0,
  },
  chassis: {
    hasFilter: false,
    filterInfo: {
      By: "cluster",
      forValue: "",
    },
    totalSize: 0,
  },
  psu: {
    hasFilter: false,
    filterInfo: {
      By: "cluster",
      forValue: "",
    },
    totalSize: 0,
  },
  hdd: {
    hasFilter: false,
    filterInfo: {
      By: "cluster",
      forValue: "",
    },
    totalSize: 0,
  },
  ssd: {
    hasFilter: false,
    filterInfo: {
      By: "cluster",
      forValue: "",
    },
    totalSize: 0,
  },
  memory: {
    hasFilter: false,
    filterInfo: {
      By: "cluster",
      forValue: "",
    },
    totalSize: 0,
  },
  node: {
    hasFilter: false,
    filterInfo: {
      By: "cluster",
      forValue: "",
    },
    totalSize: 0,
  },
  cmos: {
    hasFilter: false,
    filterInfo: {
      By: "cluster",
      forValue: "",
    },
    totalSize: 0,
  },
};

let availabelCluster = {};
let tempSelectedComponentData = {};

let selectedComponentData = {};
const removeFromSelection = new Set();

let isApplianceOnly = false;
let isSsdOnly = false;

let smartsHandsEligibleAssets = new Set();
let smartsHandsEligibleCountry = {};
let smartHandsEligibility = true;

let hasNrdPolicy;
let hasValidSupport;

const cssStyleBgBlackFgWhite = [
  "color: #fff",
  "background-color: #444",
  "padding: 2px 4px",
  "border-radius: 2px",
].join(";");

const cssStyleBgGreenFgWhite = [
  "color: #fff",
  "background-color: green",
  "padding: 2px 4px",
  "border-radius: 2px",
].join(";");

const cssStyle0 = [
  "color: #012a4a",
  "background-color: #f8edeb",
  "padding: 2px 4px",
  "border-radius: 2px",
].join(";");

console.info(`CaseId: ${caseId}`);

let varResult;

const hideDomElement = (domElement) => (domElement.style.display = "none");
const unHideDomElement = (domElement) => (domElement.style.display = "");
const getQuantityAllowed = () =>
  parseInt(domElements.componentQuantityInput.value);
const toTitleCase = (str) => {
  str = str.toLowerCase().split(" ");
  for (let i = 0; i < str.length; i++) {
    str[i] = str[i].charAt(0).toUpperCase() + str[i].slice(1);
  }
  return str.join(" ");
};

const peelingDataLayers = (onionObject, ...args) => {
  let result = onionObject;
  try {
    for (const arg of args) {
      result = result[arg];
    }
  } catch {}
  return result || "";
};
const redirectToRma = () => {
  if (sforce.console.isInConsole()) {
    console.log("Is In Console");

    sforce.console.getEnclosingPrimaryTabId((x) =>
      sforce.console.openSubtab(
        x.id,
        `/${rmaId}`,
        true,
        "RMA Order",
        null,
        () => console.log("success"),
        "salesforceSubtab"
      )
    );
  } else {
    window.top.location.href = `/${rmaId}`;
  }
};

const backToCase = () => {
  if (sforce.console.isInConsole()) {
    console.log("Is In Console");

    sforce.console.getEnclosingTabId((result) =>
      sforce.console.closeTab(result.id)
    );
  } else {
    history.length > 1
      ? history.back()
      : (window.top.location.href = `/${caseId}`);
  }
};
const showQuantityAndSearchBlock = (component) => {
  domElements.componentQuantityLabel.innerText = `${component} Quantity`;
  domElements.componentSearchButtonLabel.innerText = `Search ${component}`;
  domElements.componentQuantityInput.value = "";
  unHideDomElement(domElements.componentQuantityAndSearchBlock);
};

const disableElem = (elem) => (elem.disabled = true);
const enableElem = (elem) => (elem.disabled = false);

const openSearchModal = () => {
  domElements.backdrop.classList.add("slds-backdrop_open");
  domElements.searchComponentModal.classList.add("slds-fade-in-open");
  domElements.body.classList.add("body-overflow");
  /**js for other option for failure reason**/
  if (
    j$("#select-component-dropdown").val() == "Chassis" ||
    j$("#select-component-dropdown").val() == "PSU"
  ) {
    var cols = dataTableInstance.column(3).nodes();
    for (var i = 0; i < cols.length; i += 1) {
      var failureSelectCol = cols[i].querySelector(".failure-select");
      j$(failureSelectCol).change(function () {
        var tableRow = j$(this).closest("tr");
        if (j$(this).val() == "Other") {
          j$(tableRow).find(".other-input").removeClass("slds-hide");
        } else {
          j$(tableRow).find(".other-input").addClass("slds-hide");
        }
      });
    }
  } else if (
    j$("#select-component-dropdown").val() == "HDD" ||
    j$("#select-component-dropdown").val() == "SSD" ||
    j$("#select-component-dropdown").val() == "Memory"
  ) {
    var cols = dataTableInstance.column(6).nodes();
    for (var i = 0; i < cols.length; i += 1) {
      var failureSelectCol = cols[i].querySelector(".failure-select");
      j$(failureSelectCol).change(function () {
        var tableRow = j$(this).closest("tr");
        if (j$(this).val() == "Other") {
          j$(tableRow).find(".other-input").removeClass("slds-hide");
        } else {
          j$(tableRow).find(".other-input").addClass("slds-hide");
        }
      });
    }
  } else if (
    j$("#select-component-dropdown").val() == "Node" ||
    j$("#select-component-dropdown").val() == "CMOS"
  ) {
    var cols = dataTableInstance.column(5).nodes();
    for (var i = 0; i < cols.length; i += 1) {
      var failureSelectCol = cols[i].querySelector(".failure-select");
      j$(failureSelectCol).change(function () {
        var tableRow = j$(this).closest("tr");
        if (j$(this).val() == "Other") {
          j$(tableRow).find(".other-input").removeClass("slds-hide");
        } else {
          j$(tableRow).find(".other-input").addClass("slds-hide");
        }
      });
    }
  }
};
const closeSearchModal = () => {
  domElements.searchModalFooterToastClose.click();
  domElements.backdrop.classList.remove("slds-backdrop_open");
  domElements.searchComponentModal.classList.remove("slds-fade-in-open");
  domElements.body.classList.remove("body-overflow");
};

const fetchComponentData = async (component) => {
  if (component === "cmos") {
    if (!isDataRetrieved["node"]) {
      await fetchComponentData("node");
    }
    dataTableInstancesInfo[component] = dataTableInstancesInfo["node"];
    retrievedData[component] = retrievedData["node"];
  } else {
    const methodToCall = `GET_${component.toUpperCase()}_DATA`;
    console.log(methodToCall);
    let data = await callServer({ accountId }, methodToCall);
    console.log(data);

    dataTableInstancesInfo[component]["totalSize"] = data.length;
    retrievedData[component] = data;
  }
  isDataRetrieved[component] = true;
  console.log(`retrieved Data for ${component}`);
  return true;
};

const setDataTableHeader = async (component) => {
  const header =
    domElements.searchModalDataTable.firstElementChild.firstElementChild;
  header.innerHTML = "";

  const frag = document.createDocumentFragment();
  // const fragChildren = [];

  const checkBoxHeader = document.createElement("th");
  checkBoxHeader.innerHTML = "&nbsp;";
  checkBoxHeader.classList.add("no-sort");
  checkBoxHeader.width = "10%";

  frag.append(checkBoxHeader);

  if (["appliance"].includes(component)) {
    const applianceHeader = document.createElement("th");
    applianceHeader.width = "45%";
    applianceHeader.innerText = "Appliance";

    const failureReasonHeader = document.createElement("th");
    failureReasonHeader.width = "45%";
    failureReasonHeader.classList.add("no-sort");
    failureReasonHeader.innerText = "Failure Reason";

    frag.append(applianceHeader);
    frag.append(failureReasonHeader);
  } else if (["chassis", "psu"].includes(component)) {
    const applianceHeader = document.createElement("th");
    applianceHeader.width = "20%";
    applianceHeader.innerText = "Appliance";

    const componentHeader = document.createElement("th");
    componentHeader.width = "20%";
    componentHeader.innerText =
      component === "psu" ? "PSU" : toTitleCase(component);

    const failureReasonHeader = document.createElement("th");
    failureReasonHeader.width = "30%";
    failureReasonHeader.classList.add("no-sort");
    failureReasonHeader.innerText = "Failure Reason";

    const OtherReasonHeader = document.createElement("th");
    OtherReasonHeader.width = "20%";
    OtherReasonHeader.classList.add("no-sort");
    OtherReasonHeader.innerText = "";

    frag.append(applianceHeader);
    frag.append(componentHeader);
    frag.append(failureReasonHeader);
    frag.append(OtherReasonHeader);
  } else if (["cmos"].includes(component)) {
    checkBoxHeader.width = "5%";

    const clusterHeader = document.createElement("th");
    clusterHeader.width = "20%";
    clusterHeader.innerText = "Cluster UUID";

    const applianceHeader = document.createElement("th");
    applianceHeader.width = "15%";
    applianceHeader.innerText = "Appliance";

    const chassisHeader = document.createElement("th");
    chassisHeader.width = "13%";
    chassisHeader.innerText = "Chassis";

    const componentHeader = document.createElement("th");
    componentHeader.width = "12%";
    componentHeader.innerText = toTitleCase(component);

    const failureReasonHeader = document.createElement("th");
    failureReasonHeader.width = "20%";
    failureReasonHeader.classList.add("no-sort");
    failureReasonHeader.innerText = "Failure Reason";

    const OtherReasonHeader = document.createElement("th");
    OtherReasonHeader.width = "15%";
    OtherReasonHeader.classList.add("no-sort");
    OtherReasonHeader.innerText = "";

    frag.append(clusterHeader);
    frag.append(applianceHeader);
    frag.append(chassisHeader);
    frag.append(componentHeader);
    frag.append(failureReasonHeader);
    frag.append(OtherReasonHeader);
  } else if (["hdd", "ssd", "memory"].includes(component)) {
    checkBoxHeader.width = "3%";
    const clusterHeader = document.createElement("th");
    clusterHeader.width = "20%";
    clusterHeader.innerText = "Cluster UUID";

    const applianceHeader = document.createElement("th");
    applianceHeader.width = "12%";
    applianceHeader.innerText = "Appliance";

    const chassisHeader = document.createElement("th");
    chassisHeader.width = "12%";
    chassisHeader.innerText = "Chassis";

    const nodeHeader = document.createElement("th");
    nodeHeader.width = "12%";
    nodeHeader.innerText = "Node";

    const componentHeader = document.createElement("th");
    componentHeader.width = "10%";
    componentHeader.innerText =
      component === "memory" ? toTitleCase(component) : component.toUpperCase();

    const failureReasonHeader = document.createElement("th");
    failureReasonHeader.width = "15%";
    failureReasonHeader.classList.add("no-sort");
    failureReasonHeader.innerText = "Failure Reason";

    const OtherReasonHeader = document.createElement("th");
    OtherReasonHeader.width = "16%";
    OtherReasonHeader.classList.add("no-sort");
    OtherReasonHeader.innerText = "";

    frag.append(clusterHeader);
    frag.append(applianceHeader);
    frag.append(chassisHeader);
    frag.append(nodeHeader);
    frag.append(componentHeader);
    frag.append(failureReasonHeader);
    frag.append(OtherReasonHeader);
  } else if (["node"].includes(component)) {
    checkBoxHeader.width = "5%";

    const clusterHeader = document.createElement("th");
    clusterHeader.width = "20%";
    clusterHeader.innerText = "Cluster UUID";

    const applianceHeader = document.createElement("th");
    applianceHeader.width = "15%";
    applianceHeader.innerText = "Appliance";

    const chassisHeader = document.createElement("th");
    chassisHeader.width = "13%";
    chassisHeader.innerText = "Chassis";

    const componentHeader = document.createElement("th");
    componentHeader.width = "12%";
    componentHeader.innerText = toTitleCase(component);

    const failureReasonHeader = document.createElement("th");
    failureReasonHeader.width = "20%";
    failureReasonHeader.classList.add("no-sort");
    failureReasonHeader.innerText = "Failure Reason";

    const OtherReasonHeader = document.createElement("th");
    OtherReasonHeader.width = "15%";
    OtherReasonHeader.classList.add("no-sort");
    OtherReasonHeader.innerText = "";

    frag.append(clusterHeader);
    frag.append(applianceHeader);
    frag.append(chassisHeader);
    frag.append(componentHeader);
    frag.append(failureReasonHeader);
    frag.append(OtherReasonHeader);
  }
  header.appendChild(frag);
  return "Table Header construct Complete";
};

const returnDataTableRow = async (
  component,
  cmpInstance,
  index,
  isInstanceSelected,
  selectedReason
) => {
  const row = document.createElement("tr");
  if (["appliance"].includes(component)) {
    const checkboxData = document.createElement("td");
    const componentData = document.createElement("td");
    const failureData = document.createElement("td");

    const checkBoxDiv1 = document.createElement("div");
    const checkBoxDiv2 = document.createElement("div");
    const checkBoxDiv3 = document.createElement("div");
    const checkBoxElem = document.createElement("input");
    const checkBoxLabel = document.createElement("label");
    const checkBoxSpan1 = document.createElement("span");
    const checkBoxSpan2 = document.createElement("span");

    checkBoxDiv1.classList.add("slds-form-element");
    checkBoxDiv2.classList.add("slds-form-element__control");
    checkBoxDiv3.classList.add("slds-checkbox");

    checkBoxElem.type = "checkbox";
    checkBoxElem.name = "options";
    checkBoxElem.name = "options";
    checkBoxElem["data-id"] = cmpInstance.Id;
    checkBoxElem["data-serial-number"] = cmpInstance.serial_number__c;
    checkBoxElem["data-asset-id"] = cmpInstance.Id;
    checkBoxElem["data-asset-serial-number"] = cmpInstance.serial_number__c;
    checkBoxElem["data-node-serial-number"] = "NA";

    checkBoxElem.id = `checkbox${index}`;

    checkBoxLabel.classList.add("slds-checkbox__label");
    checkBoxLabel.htmlFor = `checkbox${index}`;
    checkBoxSpan1.classList.add("slds-checkbox_faux");
    checkBoxSpan2.classList.add("slds-slds-form-element__label");

    checkBoxLabel.appendChild(checkBoxSpan1);
    checkBoxLabel.appendChild(checkBoxSpan2);

    checkBoxDiv3.appendChild(checkBoxElem);
    checkBoxDiv3.appendChild(checkBoxLabel);

    checkBoxDiv2.appendChild(checkBoxDiv3);
    checkBoxDiv1.appendChild(checkBoxDiv2);
    checkboxData.appendChild(checkBoxDiv1);

    componentData.innerText = cmpInstance.serial_number__c;

    const failureDataDiv1 = document.createElement("div");
    const failureDataDiv2 = document.createElement("div");
    const failureDataSelect = document.createElement("select");

    failureDataSelect["data-id"] = cmpInstance.Id;
    failureDataSelect.classList.add("slds-select");
    failureDataDiv2.classList.add("slds-select_container");
    failureDataDiv1.classList.add("slds-form-element__control");

    const defaultOption = document.createElement("option");
    defaultOption.selected = true;
    defaultOption.value = "Select";
    defaultOption.innerText = "Select";

    failureDataSelect.appendChild(defaultOption);

    for (const failureOption of allFailures[component]) {
      const option = document.createElement("option");
      option.value = failureOption;
      option.innerText = failureOption;
      failureDataSelect.appendChild(option);
    }
    failureDataDiv2.appendChild(failureDataSelect);
    failureDataDiv1.appendChild(failureDataDiv2);
    failureData.appendChild(failureDataDiv1);

    row.appendChild(checkboxData);
    row.appendChild(componentData);
    row.appendChild(failureData);
  } else if (["chassis", "psu"].includes(component)) {
    const checkboxData = document.createElement("td");
    const componentData = document.createElement("td");
    const applianceData = document.createElement("td");
    const failureData = document.createElement("td");
    const otherReasonData = document.createElement("td");

    const checkBoxDiv1 = document.createElement("div");
    const checkBoxDiv2 = document.createElement("div");
    const checkBoxDiv3 = document.createElement("div");
    const checkBoxElem = document.createElement("input");
    const checkBoxLabel = document.createElement("label");
    const checkBoxSpan1 = document.createElement("span");
    const checkBoxSpan2 = document.createElement("span");

    checkBoxDiv1.classList.add("slds-form-element");
    checkBoxDiv2.classList.add("slds-form-element__control");
    checkBoxDiv3.classList.add("slds-checkbox");

    checkBoxElem.type = "checkbox";
    checkBoxElem.name = "options";
    checkBoxElem.name = "options";
    checkBoxElem["data-id"] = cmpInstance.Id;
    checkBoxElem["data-serial-number"] = cmpInstance.serial_number__c;
    checkBoxElem["data-asset-id"] = peelingDataLayers(
      cmpInstance,
      "asset__r",
      "Id"
    );
    checkBoxElem["data-asset-serial-number"] = peelingDataLayers(
      cmpInstance,
      "asset__r",
      "serial_number__c"
    );
    checkBoxElem["data-node-serial-number"] = "NA";
    checkBoxElem.id = `checkbox${index}`;

    checkBoxLabel.classList.add("slds-checkbox__label");
    checkBoxLabel.htmlFor = `checkbox${index}`;
    checkBoxSpan1.classList.add("slds-checkbox_faux");
    checkBoxSpan2.classList.add("slds-slds-form-element__label");

    checkBoxLabel.appendChild(checkBoxSpan1);
    checkBoxLabel.appendChild(checkBoxSpan2);

    checkBoxDiv3.appendChild(checkBoxElem);
    checkBoxDiv3.appendChild(checkBoxLabel);

    checkBoxDiv2.appendChild(checkBoxDiv3);
    checkBoxDiv1.appendChild(checkBoxDiv2);
    checkboxData.appendChild(checkBoxDiv1);

    componentData.innerText = cmpInstance.serial_number__c;
    applianceData.innerText = peelingDataLayers(
      cmpInstance,
      "asset__r",
      "serial_number__c"
    );

    const failureDataDiv1 = document.createElement("div");
    const failureDataDiv2 = document.createElement("div");
    const failureDataSelect = document.createElement("select");
    const OtherInput = document.createElement("input");

    failureDataSelect["data-id"] = cmpInstance.Id;
    failureDataSelect.classList.add("slds-select", "failure-select");
    failureDataDiv2.classList.add("slds-select_container");
    failureDataDiv1.classList.add("slds-form-element__control");
    OtherInput.classList.add("slds-input", "other-input", "slds-hide");
    otherReasonData.appendChild(OtherInput);
    const defaultOption = document.createElement("option");
    defaultOption.selected = true;
    defaultOption.value = "Select";
    defaultOption.innerText = "Select";

    failureDataSelect.appendChild(defaultOption);

    for (const failureOption of allFailures[component]) {
      const option = document.createElement("option");
      option.value = failureOption;
      option.innerText = failureOption;
      failureDataSelect.appendChild(option);
    }
    failureDataDiv2.appendChild(failureDataSelect);
    failureDataDiv1.appendChild(failureDataDiv2);
    failureData.appendChild(failureDataDiv1);

    row.appendChild(checkboxData);
    row.appendChild(applianceData);
    row.appendChild(componentData);
    row.appendChild(failureData);
    row.appendChild(otherReasonData);
  } else if (["cmos"].includes(component)) {
    const checkboxData = document.createElement("td");
    const componentData = document.createElement("td");
    const applianceData = document.createElement("td");
    const clusterData = document.createElement("td");
    const chassisData = document.createElement("td");
    // const nodeData = document.createElement("td");
    const failureData = document.createElement("td");
    const otherReasonData = document.createElement("td");

    const checkBoxDiv1 = document.createElement("div");
    const checkBoxDiv2 = document.createElement("div");
    const checkBoxDiv3 = document.createElement("div");
    const checkBoxElem = document.createElement("input");
    const checkBoxLabel = document.createElement("label");
    const checkBoxSpan1 = document.createElement("span");
    const checkBoxSpan2 = document.createElement("span");

    checkBoxDiv1.classList.add("slds-form-element");
    checkBoxDiv2.classList.add("slds-form-element__control");
    checkBoxDiv3.classList.add("slds-checkbox");

    checkBoxElem.type = "checkbox";
    checkBoxElem.name = "options";
    checkBoxElem.name = "options";
    checkBoxElem["data-id"] = cmpInstance.Id;
    checkBoxElem["data-serial-number"] = cmpInstance.serial_number__c;
    checkBoxElem["data-node-serial-number"] = cmpInstance.serial_number__c;
    checkBoxElem["data-asset-id"] = peelingDataLayers(
      cmpInstance,
      "asset__r",
      "Id"
    );
    checkBoxElem["data-asset-serial-number"] = peelingDataLayers(
      cmpInstance,
      "asset__r",
      "serial_number__c"
    );

    checkBoxElem.id = `checkbox${index}`;

    checkBoxLabel.classList.add("slds-checkbox__label");
    checkBoxLabel.htmlFor = `checkbox${index}`;
    checkBoxSpan1.classList.add("slds-checkbox_faux");
    checkBoxSpan2.classList.add("slds-slds-form-element__label");

    checkBoxLabel.appendChild(checkBoxSpan1);
    checkBoxLabel.appendChild(checkBoxSpan2);

    checkBoxDiv3.appendChild(checkBoxElem);
    checkBoxDiv3.appendChild(checkBoxLabel);

    checkBoxDiv2.appendChild(checkBoxDiv3);
    checkBoxDiv1.appendChild(checkBoxDiv2);
    checkboxData.appendChild(checkBoxDiv1);

    componentData.innerText = cmpInstance.serial_number__c;

    applianceData.innerText = peelingDataLayers(
      cmpInstance,
      "asset__r",
      "serial_number__c"
    );

    clusterData.innerText = peelingDataLayers(
      cmpInstance,
      "cluster__r",
      "uuid__c"
    );

    chassisData.innerText = peelingDataLayers(
      cmpInstance,
      "chassis__r",
      "serial_number__c"
    );

    const failureDataDiv1 = document.createElement("div");
    const failureDataDiv2 = document.createElement("div");
    const failureDataSelect = document.createElement("select");
    const OtherInput = document.createElement("input");

    failureDataSelect["data-id"] = cmpInstance.Id;
    failureDataSelect.classList.add("slds-select", "failure-select");
    failureDataDiv2.classList.add("slds-select_container");
    failureDataDiv1.classList.add("slds-form-element__control");

    OtherInput.classList.add("slds-input", "other-input", "slds-hide");
    otherReasonData.appendChild(OtherInput);

    const defaultOption = document.createElement("option");
    defaultOption.selected = true;
    defaultOption.value = "Select";
    defaultOption.innerText = "Select";

    failureDataSelect.appendChild(defaultOption);

    for (const failureOption of allFailures[component]) {
      const option = document.createElement("option");
      option.value = failureOption;
      option.innerText = failureOption;
      failureDataSelect.appendChild(option);
    }
    failureDataDiv2.appendChild(failureDataSelect);
    failureDataDiv1.appendChild(failureDataDiv2);
    failureData.appendChild(failureDataDiv1);

    row.appendChild(checkboxData);
    row.appendChild(clusterData);
    row.appendChild(applianceData);
    row.appendChild(chassisData);
    row.appendChild(componentData);
    row.appendChild(failureData);
    row.appendChild(otherReasonData);
  } else if (["hdd", "ssd", "memory"].includes(component)) {
    const checkboxData = document.createElement("td");
    const componentData = document.createElement("td");
    const applianceData = document.createElement("td");
    const clusterData = document.createElement("td");
    const chassisData = document.createElement("td");
    const nodeData = document.createElement("td");
    const failureData = document.createElement("td");
    const otherReasonData = document.createElement("td");

    const checkBoxDiv1 = document.createElement("div");
    const checkBoxDiv2 = document.createElement("div");
    const checkBoxDiv3 = document.createElement("div");
    const checkBoxElem = document.createElement("input");
    const checkBoxLabel = document.createElement("label");
    const checkBoxSpan1 = document.createElement("span");
    const checkBoxSpan2 = document.createElement("span");

    checkBoxDiv1.classList.add("slds-form-element");
    checkBoxDiv2.classList.add("slds-form-element__control");
    checkBoxDiv3.classList.add("slds-checkbox");

    checkBoxElem.type = "checkbox";
    checkBoxElem.name = "options";
    checkBoxElem.name = "options";
    checkBoxElem["data-id"] = cmpInstance.Id;
    checkBoxElem["data-serial-number"] = cmpInstance.serial_number__c;
    checkBoxElem["data-node-serial-number"] = peelingDataLayers(
      cmpInstance,
      "node__r",
      "serial_number__c"
    );
    checkBoxElem["data-asset-serial-number"] = peelingDataLayers(
      cmpInstance,
      "asset__r",
      "serial_number__c"
    );
    checkBoxElem["data-asset-id"] = peelingDataLayers(
      cmpInstance,
      "asset__r",
      "Id"
    );

    checkBoxElem.id = `checkbox${index}`;

    checkBoxLabel.classList.add("slds-checkbox__label");
    checkBoxLabel.htmlFor = `checkbox${index}`;
    checkBoxSpan1.classList.add("slds-checkbox_faux");
    checkBoxSpan2.classList.add("slds-slds-form-element__label");

    checkBoxLabel.appendChild(checkBoxSpan1);
    checkBoxLabel.appendChild(checkBoxSpan2);

    checkBoxDiv3.appendChild(checkBoxElem);
    checkBoxDiv3.appendChild(checkBoxLabel);

    checkBoxDiv2.appendChild(checkBoxDiv3);
    checkBoxDiv1.appendChild(checkBoxDiv2);
    checkboxData.appendChild(checkBoxDiv1);

    componentData.innerText = cmpInstance.serial_number__c;
    applianceData.innerText = peelingDataLayers(
      cmpInstance,
      "asset__r",
      "serial_number__c"
    );
    nodeData.innerText = peelingDataLayers(
      cmpInstance,
      "node__r",
      "serial_number__c"
    );
    clusterData.innerText = peelingDataLayers(
      cmpInstance,
      "node__r",
      "cluster__r",
      "uuid__c"
    );

    chassisData.innerText = peelingDataLayers(
      cmpInstance,
      "node__r",
      "chassis__r",
      "serial_number__c"
    );

    const failureDataDiv1 = document.createElement("div");
    const failureDataDiv2 = document.createElement("div");
    const failureDataSelect = document.createElement("select");
    const OtherInput = document.createElement("input");

    failureDataSelect["data-id"] = cmpInstance.Id;
    failureDataSelect.classList.add("slds-select", "failure-select");
    failureDataDiv2.classList.add("slds-select_container");
    failureDataDiv1.classList.add("slds-form-element__control");

    OtherInput.classList.add("slds-input", "other-input", "slds-hide");
    otherReasonData.appendChild(OtherInput);

    const defaultOption = document.createElement("option");
    defaultOption.selected = true;
    defaultOption.value = "Select";
    defaultOption.innerText = "Select";

    failureDataSelect.appendChild(defaultOption);

    for (const failureOption of allFailures[component]) {
      const option = document.createElement("option");
      option.value = failureOption;
      option.innerText = failureOption;

      failureDataSelect.appendChild(option);
    }
    failureDataDiv2.appendChild(failureDataSelect);
    failureDataDiv1.appendChild(failureDataDiv2);
    failureData.appendChild(failureDataDiv1);

    row.appendChild(checkboxData);
    row.appendChild(clusterData);
    row.appendChild(applianceData);
    row.appendChild(chassisData);
    row.appendChild(nodeData);
    row.appendChild(componentData);
    row.appendChild(failureData);
    row.appendChild(otherReasonData);
  } else if (["node"].includes(component)) {
    const checkboxData = document.createElement("td");
    const componentData = document.createElement("td");
    const applianceData = document.createElement("td");
    const clusterData = document.createElement("td");
    const chassisData = document.createElement("td");
    // const nodeData = document.createElement("td");
    const failureData = document.createElement("td");
    const otherReasonData = document.createElement("td");

    const checkBoxDiv1 = document.createElement("div");
    const checkBoxDiv2 = document.createElement("div");
    const checkBoxDiv3 = document.createElement("div");
    const checkBoxElem = document.createElement("input");
    const checkBoxLabel = document.createElement("label");
    const checkBoxSpan1 = document.createElement("span");
    const checkBoxSpan2 = document.createElement("span");

    checkBoxDiv1.classList.add("slds-form-element");
    checkBoxDiv2.classList.add("slds-form-element__control");
    checkBoxDiv3.classList.add("slds-checkbox");

    checkBoxElem.type = "checkbox";
    checkBoxElem.name = "options";
    checkBoxElem.name = "options";
    checkBoxElem["data-id"] = cmpInstance.Id;
    checkBoxElem["data-serial-number"] = cmpInstance.serial_number__c;
    checkBoxElem["data-node-serial-number"] = cmpInstance.serial_number__c;
    checkBoxElem["data-asset-id"] = peelingDataLayers(
      cmpInstance,
      "asset__r",
      "Id"
    );
    checkBoxElem["data-asset-serial-number"] = peelingDataLayers(
      cmpInstance,
      "asset__r",
      "serial_number__c"
    );

    checkBoxElem.id = `checkbox${index}`;

    checkBoxLabel.classList.add("slds-checkbox__label");
    checkBoxLabel.htmlFor = `checkbox${index}`;
    checkBoxSpan1.classList.add("slds-checkbox_faux");
    checkBoxSpan2.classList.add("slds-slds-form-element__label");

    checkBoxLabel.appendChild(checkBoxSpan1);
    checkBoxLabel.appendChild(checkBoxSpan2);

    checkBoxDiv3.appendChild(checkBoxElem);
    checkBoxDiv3.appendChild(checkBoxLabel);

    checkBoxDiv2.appendChild(checkBoxDiv3);
    checkBoxDiv1.appendChild(checkBoxDiv2);
    checkboxData.appendChild(checkBoxDiv1);

    componentData.innerText = cmpInstance.serial_number__c;

    applianceData.innerText = peelingDataLayers(
      cmpInstance,
      "asset__r",
      "serial_number__c"
    );

    clusterData.innerText = peelingDataLayers(
      cmpInstance,
      "cluster__r",
      "uuid__c"
    );

    chassisData.innerText = peelingDataLayers(
      cmpInstance,
      "chassis__r",
      "serial_number__c"
    );

    const failureDataDiv1 = document.createElement("div");
    const failureDataDiv2 = document.createElement("div");
    const failureDataSelect = document.createElement("select");
    const OtherInput = document.createElement("input");

    failureDataSelect["data-id"] = cmpInstance.Id;
    failureDataSelect.classList.add("slds-select", "failure-select");
    failureDataDiv2.classList.add("slds-select_container");
    failureDataDiv1.classList.add("slds-form-element__control");

    OtherInput.classList.add("slds-input", "other-input", "slds-hide");
    otherReasonData.appendChild(OtherInput);

    const defaultOption = document.createElement("option");
    defaultOption.selected = true;
    defaultOption.value = "Select";
    defaultOption.innerText = "Select";

    failureDataSelect.appendChild(defaultOption);

    for (const failureOption of allFailures[component]) {
      const option = document.createElement("option");
      option.value = failureOption;
      option.innerText = failureOption;
      failureDataSelect.appendChild(option);
    }
    failureDataDiv2.appendChild(failureDataSelect);
    failureDataDiv1.appendChild(failureDataDiv2);
    failureData.appendChild(failureDataDiv1);

    row.appendChild(checkboxData);
    row.appendChild(clusterData);
    row.appendChild(applianceData);
    row.appendChild(chassisData);
    row.appendChild(componentData);
    row.appendChild(failureData);
    row.appendChild(otherReasonData);
  }

  return row;
};

const fuzzyMatch = (baseString = "", stringToCompare) =>
  baseString.toLowerCase().includes(stringToCompare);

let currentInstanceData = {
  data: [],
  component: "",
  filterInfo: {
    forValue: 0,
    By: "",
  },
  curStart: 0,
  curEnd: 0,
  totalSize: 0,
  selectedInstances: "",
};
const resetCurrentInstanceData = () => {
  currentInstanceData = {
    data: [],
    component: "",
    filterInfo: {
      forValue: 0,
      By: "",
    },
    curStart: 0,
    curEnd: 0,
    totalSize: 0,
  };
};

const makeCurrentInstanceData = async (component) => {
  const selectList = domElements.searchModalFilterSelectList;
  let optionToBeSelected;
  let By;
  let forValue;

  if (
    !["appliance", "chassis", "psu"].includes(component) &&
    !dataTableInstancesInfo[component]["hasFilter"]
  ) {
    optionToBeSelected = Array.from(selectList.children).find(
      (elem) => elem.value === "cluster"
    );
    dataTableInstancesInfo[component]["filterInfo"]["By"] =
      optionToBeSelected.value;
    dataTableInstancesInfo[component]["filterInfo"]["forValue"] =
      domElements.clusterUuid.value.trim();

    dataTableCurrentFilterValues["cluster"] =
      dataTableInstancesInfo[component]["filterInfo"]["forValue"];
    dataTableInstancesInfo[component]["hasFilter"] = true;
  }
  const currentSelectedCmp = [];
  for (const id of Object.keys(selectedComponentData)) {
    currentSelectedCmp.push(id);
  }
  let selectedInstances = currentSelectedCmp.sort().join(",");
  let equalSelectedInstance =
    selectedInstances === currentInstanceData.selectedInstances;

  if (dataTableInstancesInfo[component]["hasFilter"]) {
    By = dataTableInstancesInfo[component]["filterInfo"]["By"];

    forValue = dataTableInstancesInfo[component]["filterInfo"]["forValue"];

    const { searchModalFilterByValue: filterByInputBlock } = domElements;
    optionToBeSelected = Array.from(selectList.children).find(
      (elem) => elem.value === By
    );
    optionToBeSelected.selected = true;
    domElements.searchModalFilterLabel.innerText =
      optionToBeSelected["data-value-for-label"];
    filterByInputBlock.value = forValue;
    forValue = forValue.toLowerCase();

    if (
      currentInstanceData.component === component &&
      currentInstanceData.filterInfo.By === By &&
      currentInstanceData.filterInfo.forValue === forValue &&
      equalSelectedInstance
    ) {
      return;
    }
  }
  if (!dataTableInstancesInfo[component]["hasFilter"]) {
    if (currentInstanceData.component === component && equalSelectedInstance) {
      return;
    }
  }
  const data = [];
  for (const cmpInstance of retrievedData[component]) {
    if (
      selectedComponentData.hasOwnProperty(`${cmpInstance.Id}-${component}`)
    ) {
      continue;
    }
    if (dataTableInstancesInfo[component]["hasFilter"]) {
      if (component === "appliance") {
        if (By === "appliance") {
          if (!fuzzyMatch(cmpInstance.serial_number__c, forValue)) {
            continue;
          }
        }
      } else if (component === "chassis") {
        if (By === "appliance") {
          if (
            !fuzzyMatch(
              peelingDataLayers(cmpInstance, "asset__r", "serial_number__c"),
              forValue
            )
          ) {
            continue;
          }
        } else if (By === "chassis") {
          if (!fuzzyMatch(cmpInstance.serial_number__c, forValue)) {
            continue;
          }
        }
      } else if (component === "hdd") {
        if (By === "appliance") {
          if (
            !fuzzyMatch(
              peelingDataLayers(cmpInstance, "asset__r", "serial_number__c"),
              forValue
            )
          ) {
            continue;
          }
        } else if (By === "chassis") {
          if (
            !fuzzyMatch(
              peelingDataLayers(
                cmpInstance,
                "node__r",
                "chassis__r",
                "serial_number__c"
              ),
              forValue
            )
          ) {
            continue;
          }
        } else if (By === "cluster") {
          if (
            !fuzzyMatch(
              peelingDataLayers(
                cmpInstance,
                "node__r",
                "cluster__r",
                "uuid__c"
              ),
              forValue
            )
          ) {
            continue;
          }
        } else if (By === "node") {
          if (
            !fuzzyMatch(
              peelingDataLayers(cmpInstance, "node__r", "serial_number__c"),
              forValue
            )
          ) {
            continue;
          }
        } else if (By === "hdd") {
          if (!fuzzyMatch(cmpInstance.serial_number__c, forValue)) {
            continue;
          }
        }
      } else if (component === "ssd") {
        if (By === "appliance") {
          if (
            !fuzzyMatch(
              peelingDataLayers(cmpInstance, "asset__r", "serial_number__c"),
              forValue
            )
          ) {
            continue;
          }
        } else if (By === "chassis") {
          if (
            !fuzzyMatch(
              peelingDataLayers(
                cmpInstance,
                "node__r",
                "chassis__r",
                "serial_number__c"
              ),
              forValue
            )
          ) {
            continue;
          }
        } else if (By === "cluster") {
          if (
            !fuzzyMatch(
              peelingDataLayers(
                cmpInstance,
                "node__r",
                "cluster__r",
                "uuid__c"
              ),
              forValue
            )
          ) {
            continue;
          }
        } else if (By === "node") {
          if (
            !fuzzyMatch(
              peelingDataLayers(cmpInstance, "node__r", "serial_number__c"),
              forValue
            )
          ) {
            continue;
          }
        } else if (By === "ssd") {
          if (!fuzzyMatch(cmpInstance.serial_number__c, forValue)) {
            continue;
          }
        }
      } else if (component === "memory") {
        if (By === "appliance") {
          if (
            !fuzzyMatch(
              peelingDataLayers(cmpInstance, "asset__r", "serial_number__c"),
              forValue
            )
          ) {
            continue;
          }
        } else if (By === "chassis") {
          if (
            !fuzzyMatch(
              peelingDataLayers(
                cmpInstance,
                "node__r",
                "chassis__r",
                "serial_number__c"
              ),
              forValue
            )
          ) {
            continue;
          }
        } else if (By === "cluster") {
          if (
            !fuzzyMatch(
              peelingDataLayers(
                cmpInstance,
                "node__r",
                "cluster__r",
                "uuid__c"
              ),
              forValue
            )
          ) {
            continue;
          }
        } else if (By === "node") {
          if (
            !fuzzyMatch(
              peelingDataLayers(cmpInstance, "node__r", "serial_number__c"),
              forValue
            )
          ) {
            continue;
          }
        } else if (By === "memory") {
          if (!fuzzyMatch(cmpInstance.serial_number__c, forValue)) {
            continue;
          }
        }
      } else if (component === "node") {
        if (By === "appliance") {
          if (
            !fuzzyMatch(
              peelingDataLayers(cmpInstance, "asset__r", "serial_number__c"),
              forValue
            )
          ) {
            continue;
          }
        } else if (By === "chassis") {
          if (
            !fuzzyMatch(
              peelingDataLayers(cmpInstance, "chassis__r", "serial_number__c"),
              forValue
            )
          ) {
            continue;
          }
        } else if (By === "cluster") {
          if (
            !fuzzyMatch(
              peelingDataLayers(cmpInstance, "cluster__r", "uuid__c"),
              forValue
            )
          ) {
            continue;
          }
        } else if (By === "node") {
          if (!fuzzyMatch(cmpInstance.serial_number__c, forValue)) {
            continue;
          }
        }
      } else if (component === "psu") {
        if (By === "appliance") {
          if (
            !fuzzyMatch(
              peelingDataLayers(cmpInstance, "asset__r", "serial_number__c"),
              forValue
            )
          ) {
            continue;
          }
        } else if (By === "psu") {
          if (!fuzzyMatch(cmpInstance.serial_number__c, forValue)) {
            continue;
          }
        }
      } else if (component === "cmos") {
        if (By === "appliance") {
          if (
            !fuzzyMatch(
              peelingDataLayers(cmpInstance, "asset__r", "serial_number__c"),
              forValue
            )
          ) {
            continue;
          }
        } else if (By === "chassis") {
          if (
            !fuzzyMatch(
              peelingDataLayers(cmpInstance, "chassis__r", "serial_number__c"),
              forValue
            )
          ) {
            continue;
          }
        } else if (By === "cluster") {
          if (
            !fuzzyMatch(
              peelingDataLayers(cmpInstance, "cluster__r", "uuid__c"),
              forValue
            )
          ) {
            continue;
          }
        } else if (By === "node") {
          if (!fuzzyMatch(cmpInstance.serial_number__c, forValue)) {
            continue;
          }
        }
      }
    }

    data.push(cmpInstance);
  }
  const hasFilter = dataTableInstancesInfo[component]["hasFilter"];
  if (!hasFilter) {
    forValue = "";
    By = "";
  }
  const totalSize = data.length;
  currentInstanceData = {
    data,
    component,
    totalSize,
    curEnd: Math.min(totalSize, 1000),
    curStart: 0,
    hasFilter,
    filterInfo: {
      forValue,
      By,
    },
    selectedInstances,
  };
};

const failureReasonColIndexMap = {
  appliance: 2,
  chassis: 3,
  hdd: 6,
  ssd: 6,
  memory: 6,
  node: 5,
  psu: 3,
  cmos: 5,
};

const fillComponentDataTable = async (component) => {
  await setDataTableSearchOptions(component);
  await makeCurrentInstanceData(component);
  const frag = document.createDocumentFragment();

  const { totalSize, curStart, curEnd, data } = currentInstanceData;

  for (let index = curStart; index < curEnd; index++) {
    const cmpInstance = data[index];
    const row = await returnDataTableRow(component, cmpInstance, index);
    frag.appendChild(row);
  }
  domElements.searchModalDataTable.lastElementChild.appendChild(frag);

  const { searchModalNext1000, searchModalPrev1000 } = domElements;

  curStart ? enableElem(searchModalPrev1000) : disableElem(searchModalPrev1000);
  curEnd < totalSize
    ? enableElem(searchModalNext1000)
    : disableElem(searchModalNext1000);

  return "Data Table Filled";
};

let unFilterDataTable = false;

const destroyDataTable = () => {
  closeSearchModal();
  dataTableInstance.destroy();
  if (unFilterDataTable) {
    dataTableCurrentFilterValues = {};
    dataTableInstancesInfo[selectedComponent.toLowerCase()][
      "hasFilter"
    ] = false;
  }
  domElements.searchComponentModalHeader.innerText = "";
  domElements.searchModalDataTable.lastElementChild.innerHTML = "";
};

const showModalErrorToast = (text) => {
  domElements.searchModalFooterToastText.innerText = text;
  unHideDomElement(domElements.searchModalFooterToast);
};

const searchOptions = {
  appliance: [
    {
      label: "Appliance",
      value: "appliance",
      valueForLabel: "Appliance Serial Number",
    },
  ],
  chassis: [
    {
      label: "Appliance",
      value: "appliance",
      valueForLabel: "Appliance Serial Number",
    },
    {
      label: "Chassis",
      value: "chassis",
      valueForLabel: "Chassis Serial Number",
    },
  ],
  hdd: [
    {
      label: "Cluster",
      value: "cluster",
      valueForLabel: "Cluster UUID",
    },
    {
      label: "Appliance",
      value: "appliance",
      valueForLabel: "Appliance Serial Number",
    },
    {
      label: "Chassis",
      value: "chassis",
      valueForLabel: "Chassis Serial Number",
    },
    {
      label: "Node",
      value: "node",
      valueForLabel: "Node Serial Number",
    },
    {
      label: "HDD",
      value: "hdd",
      valueForLabel: "HDD Serial Number",
    },
  ],
  ssd: [
    {
      label: "Cluster",
      value: "cluster",
      valueForLabel: "Cluster UUID",
    },
    {
      label: "Appliance",
      value: "appliance",
      valueForLabel: "Appliance Serial Number",
    },
    {
      label: "Chassis",
      value: "chassis",
      valueForLabel: "Chassis Serial Number",
    },
    {
      label: "Node",
      value: "node",
      valueForLabel: "Node Serial Number",
    },
    {
      label: "SSD",
      value: "ssd",
      valueForLabel: "SSD Serial Number",
    },
  ],
  memory: [
    {
      label: "Cluster",
      value: "cluster",
      valueForLabel: "Cluster UUID",
    },
    {
      label: "Appliance",
      value: "appliance",
      valueForLabel: "Appliance Serial Number",
    },
    {
      label: "Chassis",
      value: "chassis",
      valueForLabel: "Chassis Serial Number",
    },
    {
      label: "Node",
      value: "node",
      valueForLabel: "Node Serial Number",
    },
    {
      label: "Memory",
      value: "memory",
      valueForLabel: "Memory Serial Number",
    },
  ],
  node: [
    {
      label: "Cluster",
      value: "cluster",
      valueForLabel: "Cluster UUID",
    },
    {
      label: "Appliance",
      value: "appliance",
      valueForLabel: "Appliance Serial Number",
    },
    {
      label: "Chassis",
      value: "chassis",
      valueForLabel: "Chassis Serial Number",
    },
    {
      label: "Node",
      value: "node",
      valueForLabel: "Node Serial Number",
    },
  ],
  psu: [
    {
      label: "Appliance",
      value: "appliance",
      valueForLabel: "Appliance Serial Number",
    },
    {
      label: "PSU",
      value: "psu",
      valueForLabel: "PSU Serial Number",
    },
  ],
  cmos: [
    {
      label: "Cluster",
      value: "cluster",
      valueForLabel: "Cluster UUID",
    },
    {
      label: "Appliance",
      value: "appliance",
      valueForLabel: "Appliance Serial Number",
    },
    {
      label: "Chassis",
      value: "chassis",
      valueForLabel: "Chassis Serial Number",
    },
    {
      label: "Node",
      value: "node",
      valueForLabel: "Node Serial Number",
    },
  ],
};

let dataTableCurrentFilterValues = {};

const setDataTableSearchOptions = async (cmp) => {
  console.log("setDataTableSearchOptions: ", cmp);
  const selectList = domElements.searchModalFilterSelectList;
  console.log("selectList: ", selectList, selectList.children);
  let optionToSelected;
  const frag = document.createDocumentFragment();
  searchOptions[cmp].forEach((optionAttributes) => {
    console.log("optionAttributes: ", optionAttributes);
    const option = document.createElement("option");
    option["data-value-for-label"] = optionAttributes.valueForLabel;
    option.innerText = optionAttributes.label;
    option.value = optionAttributes.value;
    console.log("option: ", option);
    frag.appendChild(option);
    if (optionAttributes.value === "cluster") {
      option.selected = true;
    }
  });
  console.log("selectList.children: ", selectList.children);
  Array.from(selectList.children).forEach((option) => option.remove());
  console.log("selectList.children: ", selectList.children);

  console.log("frag: ", frag);

  selectList.appendChild(frag);

  if (!optionToSelected) {
    optionToSelected =
      domElements.searchModalFilterSelectList.firstElementChild;
  }

  optionToSelected.selected = true;
  domElements.searchModalFilterLabel.innerText =
    optionToSelected["data-value-for-label"];
  domElements.searchModalFilterByValue.value = "";
  console.log("selectList.children: ", selectList.children);
};

const initiatedDataTable = () => {
  dataTableInstance = j$("#searchDataTable").DataTable({
    pageLength: 10,
    pagingType: "full_numbers",
    columnDefs: [
      {
        targets: "no-sort",
        orderable: false,
      },
    ],
  });
};

const addQuantityAllowedInfo = () => {
  document.querySelector(
    "#selected-component-type-for-showing-quantity"
  ).innerText = `${domElements.componentQuantityLabel.innerText}: `;
  document.querySelector("#allowed-component-quantity").innerText =
    domElements.componentQuantityInput.value.trim();
};

const createDataTable = async (cmp) => {
  await Promise.all([setDataTableHeader(cmp), fillComponentDataTable(cmp)]);
  initiatedDataTable();

  dataTableInstances[cmp] = true;
  const showEntriesLabel = document.querySelector(
    "#searchDataTable_length > label"
  );
  const selectListShowEntries = showEntriesLabel.firstElementChild;
  showEntriesLabel.innerHTML = "Show ";
  showEntriesLabel.appendChild(selectListShowEntries);

  openSearchModal();
  hideSpinner();
  addQuantityAllowedInfo();
  /**js for other option for failure reason**/
  j$(".failure-select").change(function () {
    var tableRow = j$(this).closest("tr");
    if (j$(this).val() == "Other") {
      console.log("in if", tableRow);
      j$(tableRow).find(".other-input").removeClass("slds-hide");
    } else {
      j$(tableRow).find(".other-input").addClass("slds-hide");
    }
  });
};

const getSelectedComponents = (cmp) => {
  console.log("Save Selected Data");
  const selectedCmpData = {};
  for (const [id, data] of Object.entries(selectedComponentData)) {
    if (data.component === cmp) {
      selectedCmpData[id] = data;
    }
  }
  const tempObject = {};

  const checkBoxCol = dataTableInstance.column(0).nodes();
  let failureReasonCol;
  let otherFailureReasonCol;

  failureReasonCol = dataTableInstance
    .column(failureReasonColIndexMap[cmp])
    .nodes();
  otherFailureReasonCol = dataTableInstance
    .column(failureReasonColIndexMap[cmp] + 1)
    .nodes();
  for (let i = 0; i < checkBoxCol.length; i++) {
    const checkBoxWrapper = checkBoxCol[i];

    if (
      !checkBoxWrapper.firstElementChild.firstElementChild.firstElementChild
        .firstElementChild.checked
    ) {
      continue;
    }

    const cb =
      checkBoxWrapper.firstElementChild.firstElementChild.firstElementChild
        .firstElementChild;
    const dataId = cb["data-id"];
    const selectionId = `${dataId}-${cmp}`;
    const selectList =
      failureReasonCol[i].firstElementChild.firstElementChild.firstElementChild;
    if (!selectList.selectedIndex) {
      continue;
    }
    let currentRowInfo = {};
    currentRowInfo["id"] = dataId;
    currentRowInfo["serialNumber"] = cb["data-serial-number"];
    currentRowInfo["assetId"] = cb["data-asset-id"];
    currentRowInfo["nodeSerialNumber"] = cb["data-node-serial-number"];
    currentRowInfo["assetSerialNumber"] = cb["data-asset-serial-number"];
    currentRowInfo["component"] = cmp;
    currentRowInfo["reason"] = selectList.selectedOptions[0].value;
    currentRowInfo["otherFailReason"] = null;
    if (currentRowInfo["reason"] === "Other") {
      const otherFailReason =
        otherFailureReasonCol[i].firstElementChild.value.trim();
      if (!otherFailReason.length) {
        continue;
      }
      currentRowInfo["otherFailReason"] = otherFailReason;
    }
    tempObject[selectionId] = currentRowInfo;
  }
  console.log(tempObject);
  return tempObject;
};

const renderSelectedComponentsSection = () => {
  const numberOfSelectedCmp = Object.keys(selectedComponentData).length;
  console.log("Number Of Selected Components", numberOfSelectedCmp);
  if (numberOfSelectedCmp) {
    unHideDomElement(domElements.selectedComponentsSection);
    domElements.selectedComponentsSectionCount.innerText = `(${numberOfSelectedCmp})`;
    fillSelectedComponentsTable(selectedComponentData);
    enableElem(domElements.saveRma);
  } else {
    hideDomElement(domElements.selectedComponentsSection);
    disableElem(domElements.saveRma);
  }
};

const fillSelectedComponentsTable = (selectedComponentData) => {
  domElements.selectedComponentsSection.removeEventListener(
    "input",
    changeInputSelectionModalTable
  );
  document
    .querySelectorAll("i.fa.fa-trash:not(.selection-modal)")
    .forEach((elem) =>
      elem.removeEventListener("click", removeCmpFromSelectedSection)
    );

  const frag = document.createDocumentFragment();
  const fragForSection = document.createDocumentFragment();
  let count = 0;
  for (let [id, data] of Object.entries(selectedComponentData)) {
    count++;

    const row = document.createElement("tr");
    row.classList.add("slds-hint-parent");

    const cmpType = document.createElement("td");
    const cmpSerialNumber = document.createElement("td");

    const cmpDeleteAction = document.createElement("td");
    const deleteActionIconContainer = document.createElement("a");
    const deleteActionIcon = document.createElement("i");

    const cmpFailureReason = document.createElement("td");
    const selectListContainer1 = document.createElement("div");
    const selectListContainer2 = document.createElement("div");
    const selectList = document.createElement("select");

    const otherReasonData = document.createElement("td");
    const otherFailReason = document.createElement("input");

    cmpType.innerText = componentNames[data["component"]];
    cmpSerialNumber.innerText = data.serialNumber;

    selectListContainer1.classList.add("slds-form-element__control");
    selectListContainer2.classList.add("slds-select_container");

    selectList.classList.add("slds-select", "failure-select");
    let hasOtherReasonEntered = false;
    if (data["component"] == "cmos") {
      cmpSerialNumber.innerText = "CMOS Battery";
    }
    for (let failReason of allFailures[data["component"]]) {
      const option = document.createElement("option");
      option.value = failReason;
      option.innerText = failReason;
      if (failReason === data["reason"]) {
        option.selected = true;
        if (failReason === "Other") {
          hasOtherReasonEntered = true;
          otherFailReason.value = data.otherFailReason;
        }
      }
      selectList.appendChild(option);
    }

    selectListContainer2.appendChild(selectList);
    selectListContainer1.appendChild(selectListContainer2);
    cmpFailureReason.appendChild(selectListContainer1);

    otherFailReason.classList.add("slds-input", "other-input");
    otherFailReason.classList.add(
      hasOtherReasonEntered ? "slds-show" : "slds-hide"
    );
    otherReasonData.appendChild(otherFailReason);

    cmpDeleteAction.classList.add("slds-text-align_center");
    deleteActionIconContainer.classList.add("delete-row");
    deleteActionIcon.classList.add("fa");
    deleteActionIcon.classList.add("fa-trash");

    deleteActionIconContainer.appendChild(deleteActionIcon);
    cmpDeleteAction.appendChild(deleteActionIconContainer);

    row.appendChild(cmpType);
    row.appendChild(cmpSerialNumber);
    row.appendChild(cmpFailureReason);
    row.appendChild(otherReasonData);
    row.appendChild(cmpDeleteAction);

    console.log(row);
    if (count <= 3) {
      let rowClone = row.cloneNode(true);

      for (const option of rowClone.children[2].firstElementChild
        .firstElementChild.firstElementChild.children) {
        if (option.value === data["reason"]) {
          option.selected = true;
          break;
        }
      }

      rowClone["data-id"] = id;
      rowClone.children[2].firstElementChild.firstElementChild.firstElementChild.classList.add(
        "fail-reason-select-list"
      );
      rowClone.children[3].firstElementChild.classList.add(
        "fail-other-reason-input"
      );
      rowClone.classList.add("selected-component-section-table");
      fragForSection.appendChild(rowClone);
    }

    row["data-id"] = id;
    row.lastElementChild.firstElementChild.firstElementChild.classList.add(
      "selection-modal"
    );
    row.children[2].firstElementChild.firstElementChild.firstElementChild.classList.add(
      "fail-reason-select-list",
      "selection-modal"
    );
    row.children[3].firstElementChild.classList.add(
      "fail-other-reason-input",
      "selection-modal"
    );
    frag.appendChild(row);
  }
  // const fragForModal = frag.cloneNode(true);
  domElements.selectedComponentsSectionTableBody.innerHTML = "";
  domElements.selectedComponentsSectionTableBody.appendChild(fragForSection);
  domElements.selectedComponentsSectionCount.innerText = `(${count})`;
  domElements.selectedComponentsModalTableBody.innerHTML = "";
  domElements.selectedComponentsModalTableBody.appendChild(frag);

  domElements.selectedComponentsSection.addEventListener(
    "change",
    changeInputSelectionModalTable
  );

  document
    .querySelectorAll("i.fa.fa-trash:not(.selection-modal)")
    .forEach((elem) =>
      elem.addEventListener("click", removeCmpFromSelectedSection)
    );
};

const changeInSelectedComponentsModalTable = (componentId, reason) => {
  for (const row of domElements.selectedComponentsModalTableBody.children) {
    if (row["data-id"] === componentId) {
      const otherFailReason =
        selectedComponentData[componentId]["otherFailReason"];
      const otherReasonInputElem = row.children[3].firstElementChild;
      if (reason === "Other") {
        if (otherReasonInputElem.classList.contains("slds-hide")) {
          otherReasonInputElem.classList.remove("slds-hide");
        }
        if (!otherReasonInputElem.classList.contains("slds-show")) {
          otherReasonInputElem.classList.add("slds-show");
        }
        otherReasonInputElem.classList.add("slds-show");
        otherReasonInputElem.value = otherFailReason;
      } else {
        if (otherReasonInputElem.classList.contains("slds-show")) {
          otherReasonInputElem.classList.remove("slds-show");
        }
        if (!otherReasonInputElem.classList.contains("slds-hide")) {
          otherReasonInputElem.classList.add("slds-hide");
        }
      }
      for (const option of row.children[2].firstElementChild.firstElementChild
        .firstElementChild.children) {
        if (option.value === reason) {
          option.selected = true;
          break;
        }
      }
    }
  }
};

const changeInputSelectionModalTable = (e) => {
  console.log(e.target);
  let componentId;
  let reason;
  if (e.target.classList.contains("fail-reason-select-list")) {
    componentId =
      e.target.parentNode.parentNode.parentNode.parentNode["data-id"];
    for (const option of e.target.children) {
      if (option.selected) {
        reason = option.value;
        break;
      }
    }
    selectedComponentData[componentId]["reason"] = reason;
    selectedComponentData[componentId]["otherFailReason"] = null;
  } else if (e.target.classList.contains("fail-other-reason-input")) {
    console.log("changed other reason");
    const componentId = e.target.parentNode.parentNode["data-id"];
    const newOtherReason = e.target.value.trim();
    if (!newOtherReason.length) {
      selectedComponentData[componentId]["otherFailReason"] = null;
      const cmpTypeName =
        componentNames[selectedComponentData[componentId]["component"]];
      const cmpSerialNumber =
        selectedComponentData[componentId]["serialNumber"];
      showHeaderErrorToast(
        `Enter valid other reason for ${cmpTypeName}  ${
          cmpTypeName !== "CMOS Battery"
            ? "with SR No.: " + cmpSerialNumber
            : ""
        }.`
      );
    } else {
      selectedComponentData[componentId]["otherFailReason"] = newOtherReason;
    }
  }

  /**js for other option for failure reason**/
  if (j$(".failure-select").val() == "Other") {
    j$(this).closest("tr").find(".other-input").removeClass("slds-hide");
  } else {
    j$(this).closest("tr").find(".other-input").addClass("slds-hide");
  }
  j$(".failure-select").change(function () {
    var tableRow = j$(this).closest("tr");
    if (j$(this).val() == "Other") {
      j$(tableRow).find(".other-input").removeClass("slds-hide");
    } else {
      j$(tableRow).find(".other-input").addClass("slds-hide");
    }
  });

  renderSelectedComponentsSection();
};

const removeCmpFromSelectedSection = (e) => {
  console.log(e.target);
  let row = e.target.parentNode.parentNode.parentNode;
  const componentId = row["data-id"];
  row.remove();
  removeCmpFromSelectedModalTable(componentId);
  const selectionSectionFooterCount =
    domElements.selectedComponentsSectionCount.innerText.split("");
  let count = selectionSectionFooterCount.slice(
    1,
    selectionSectionFooterCount.length - 1
  );
  count = parseInt(count) - 1;
  domElements.selectedComponentsSectionCount.innerText = `(${count})`;
  if (count < 1) {
    hideDomElement(domElements.selectedComponentsSection);
    disableElem(domElements.saveRma);
  } else {
    enableElem(domElements.saveRma);
  }
  delete selectedComponentData[componentId];
};

const removeCmpFromSelectedModalTable = (componentId) => {
  for (const row of domElements.selectedComponentsModalTableBody.children) {
    if (row["data-id"] === componentId) {
      row.remove();
    }
  }
};

const getAccountDataInfo = async () => {
  console.group("getAccountDataInfo");
  const [
    {
      CaseNumber,
      AccountId,
      Account: { attributes, ...Account },
      ...optionalData
    },
  ] = await callServer({ caseId }, "GET_CASE_NUMBER");

  caseNumber = CaseNumber;
  accountId = AccountId;
  clusterUuid =
    "Cluster__r" in optionalData ? optionalData.Cluster__r.uuid__c : "";

  accountDetails.name = Account.Name;
  accountDetails["shippingInfo"] = {};
  accountDetails.shippingInfo.street = Account.ShippingStreet || "";
  accountDetails.shippingInfo.city = Account.ShippingCity || "";
  accountDetails.shippingInfo.state = Account.ShippingState || "";
  accountDetails.shippingInfo.postalCode = Account.ShippingPostalCode || "";
  accountDetails.shippingInfo.country = Account.ShippingCountry || "";

  console.info(
    `%c${JSON.stringify({
      "Case Number": caseNumber,
      "Cluster UUID": clusterUuid,
      "Account Id": AccountId,
      "Account Shipping Info": accountDetails.shippingInfo,
    })}`,
    cssStyle0
  );

  domElements.clusterUuid.value = clusterUuid;
  domElements.caseNumber.innerText = caseNumber;
  domElements.accountName.innerText = accountDetails.name;
  //domElements.shippingContactName.value = accountDetails.name;
  console.groupEnd("getAccountDataInfo");
};

const getAccountDataDetails = async () => {            
  console.group("getAccountDataDetails");
  accountId = getElementByIdCS('RMAForm:shippingInformation:account_lookup_lkid').value;
  let AccountRec = await callServer({ accountId }, "GET_ACCOUNT_INFO");
  for (const account of AccountRec) {
      accountId = account.Id;            
      accountDetails.name = account.Name;
      accountDetails["shippingInfo"] = {};
      accountDetails.shippingInfo.street = account.ShippingStreet || "";
      accountDetails.shippingInfo.city = account.ShippingCity || "";
      accountDetails.shippingInfo.state = account.ShippingState || "";
      accountDetails.shippingInfo.postalCode = account.ShippingPostalCode || "";
      accountDetails.shippingInfo.country = account.ShippingCountry || "";
  }
  console.info(
    `%c${JSON.stringify({
      "Account Name": accountDetails.name,
      "Account Shipping Info": accountDetails.shippingInfo,
    })}`,
    cssStyle0
  );
  domElements.accountName.innerText = accountDetails.name; 
  domElements.caseNumber.innerText = csNum;
  console.groupEnd("getAccountDataDetails");
};

const getClusterDataInfo = async () => {
  const clusters = await callServer({ accountId }, "GET_CLUSTER_DATA");
  for (const cluster of clusters) {
    availabelCluster[cluster.uuid__c] = cluster.Id;
  }
};

const getFailuresInfo = async () => {
  const failures = await callServer({ accountId }, "GET_RMA_FAILURE_LIST");
  allFailures = {};
  for (const failure of failures) {
    const failureReasons = failure.Failure_Type__c.split(";");
    allFailures[failure.Name.toLowerCase()] = failureReasons;
  }
  allFailures["ssd"] = allFailures["hdd"];
};

const getSmartHandsAssetInfo = async () => {
  const rawData = await callServer(
    { accountId },
    "GET_SMART_HAND_ELIGIBLE_ASSET_DATA"
  );
  for (const { Id } of rawData) {
    smartsHandsEligibleAssets.add(Id);
  }
};
const getSmartHandsCountriesInfo = async () => {
  const rawData = await callServer({}, "GET_SMART_HAND_ELIGIBLE_COUNTRY_DATA");
  for (const { country, dateNow } of rawData) {
    smartsHandsEligibleCountry[country] = dateNow;
  }
};

const setStatePicklist = async (countrySelected = "") => {
  console.log(countrySelected);
  await setPicklistOptions(
    "shippingState",
    shippingStateDataWithDependency[countrySelected] || []
  );
};

const setSmartHandsEligibility = async () => {
  const country = await checkSmartHandsEligibilityCountry();
  const assets = await checkSmartHandsEligibilityAsset();
  smartHandsEligibility = country && assets;

  domElements.isEntitlementForSmartHands.checked = smartHandsEligibility;

  console.log("setSmartHandsEligibility", smartHandsEligibility);
  if (!country) {
    disableElem(domElements.sendSmartHandsServices);
    hideDomElement(domElements.sendSmartHandsServicesSection);
    domElements.sendSmartHandsServices.checked = false;
  } else {
    enableElem(domElements.sendSmartHandsServices);
  }
  return country && assets;
};

const checkSmartHandsEligibilityCountry = async (e) =>
  smartsHandsEligibleCountry.hasOwnProperty(
    domElements.shippingCountry.children[
      domElements.shippingCountry.selectedIndex
    ].value
  );

const checkSmartHandsEligibilityAsset = async () => {
  let hasAllEligibleComponents = Object.entries(selectedComponentData).length
    ? true
    : false;

  for (const [, { assetId }] of Object.entries(selectedComponentData)) {
    hasAllEligibleComponents =
      hasAllEligibleComponents && smartsHandsEligibleAssets.has(assetId);
  }
  return hasAllEligibleComponents;
};

const validityAllFields = async () => {
  console.log("get validity fields");
  let allValid;
  allValid =
    checkValiditySelectedComponentData() &
    checkValidityShippingStreet() &
    checkValidityShippingCity() &
    checkValidityShippingState() &
    checkValidityShippingCountry() &
    checkValidityShippingPostalCode() &
    checkValidityAdditionalInterestedEmails() &
    checkValidityShippingContactEmail() &
    checkValidityShippingContactPhone() &
    checkValidityShippingServiceType() &    
    checkValidityshippingContactName() &
    true;

  if (domElements.sendSmartHandsServices.checked) {
    allValid =
      allValid && checkValiditySmartHandsDate() & checkValiditySmartHandsTime();
  }
  const smartHandsEligible = await setSmartHandsEligibility();
  let reason;
  if (
    domElements.sendSmartHandsServices.checked &&
    (!hasValidSupport || !smartHandsEligible)
  ) {
    reason = domElements["sendSmartHandsServicesCommentReason"].value;
    if (!(reason.length > 0 && reason.length < 131000)) {
      smartHandsReason(
        smartHandsEligible,
        domElements.sendSmartHandsServices.checked
      );
      allValid = false;
    }
  }

  return allValid;
};

const getAssetSerialNumberByNodeSerialNumber = async (nodeSerialNumber) => {
  if (!isDataRetrieved["node"]) {
    await fetchComponentData("node");
  }
  return peelingDataLayers(
    retrievedData["node"].find(
      (node) => node.serial_number__c === nodeSerialNumber
    ),
    "asset__r",
    "serial_number__c"
  );
};

const getAssetSerialNumberByAssetId = async (assetId) => {
  if (!isDataRetrieved["appliance"]) {
    await fetchComponentData("appliance");
  }
  return retrievedData["appliance"].find((asset) => asset.Id === assetId)
    .serial_number__c;
};

const saveRmaForm = async (
  isSmartHandsRequested,
  isSmartHandsQualified,
  hasValidSupport,
  reason
) => {
  const sendFailures = new Array();
  const applianceSN = new Array();
  const chassisSN = new Array();
  const hddSN = new Array();
  const ssdSN = new Array();
  const memorySN = new Array();
  const nodeSN = new Array();
  const psuSN = new Array();
  const cmosSN = new Array();
  let clusterId = availabelCluster[domElements.clusterUuid.value];
  let clusterUuid = domElements.clusterUuid.value;
  let assets = new Set();
  for (const [, data] of Object.entries(selectedComponentData)) {
    const failureRec = {};
    failureRec.idComponent = data.id;
    failureRec.strTypeComponent = data.component;
    failureRec.strReason = data.reason || "";
    failureRec.assetId = data.assetId;
    assets.add(data.assetSerialNumber);
    failureRec.strSerialNumber = data.serialNumber;
    failureRec.strOtherFailReason = data.otherFailReason;
    sendFailures.push(failureRec);

    if (data.component === "appliance") {
      applianceSN.push(data.serialNumber);
    }

    if (data.component === "chassis") {
      chassisSN.push(data.serialNumber);
    }

    if (data.component === "hdd") {
      hddSN.push(data.serialNumber);
    }
    if (data.component === "ssd") {
      ssdSN.push(data.serialNumber);
    }
    if (data.component === "memory") {
      memorySN.push(data.serialNumber);
    }
    if (data.component === "node") {
      nodeSN.push(data.serialNumber);
    }

    if (data.component === "psu") {
      psuSN.push(data.serialNumber);
    }
    if (data.component === "cmos") {
        cmosSN.push(`CMOS-${data.serialNumber}`);
    }
  }
  assets = [...assets].join(",");
  let smartHandsDate;
  {
    const [month,day, year ] = domElements.smartHandsDate.value.split('/');
    smartHandsDate = {month,day,year};
  }
  const customerReferenceNum = domElements.customerReferenceNum.value.trim();
  return await callServer(
    {
      caseId,
      clusterId,
      customerReferenceNum,
      clusterUuid,
      assets,
      lstFailure: sendFailures,
      setStrSerialNumberAppliance: applianceSN,
      setStrSerialNumberChassis: chassisSN,
      setStrSerialNumberHdd: hddSN,
      setStrSerialNumberSsd: ssdSN,
      setStrSerialNumberMemory: memorySN,
      setStrSerialNumberNode: nodeSN,
      setStrSerialNumberPsu: psuSN,
      setStrSerialNumberCmos: cmosSN,
      isSmartHandsRequested: isSmartHandsRequested,
      isSmartHandsQualified: isSmartHandsQualified,
      hasValidSupport,
      hasNrdPolicy,
      smartHandsReason: reason,
      additionalInterestedParties: domElements.additionalInterestedMails.value,
      shippingStreet: domElements.shippingStreet.value,
      shippingCity: domElements.shippingCity.value,
      shippingState: getValueForSelectList(domElements.shippingState),
      shippingCountry: getValueForSelectList(domElements.shippingCountry),
      shippingPostalCode: domElements.shippingPostalCode.value,
      copyShippingAddressFromAccount:
        domElements.shippingAddressCopyFromAccount.checked,
      shipToPhone: domElements.shippingContactPhone.value,
      shipToName: accountId,
      shipToContactName: domElements.shippingContactName.value,
      shipToEmail: domElements.shippingContactEmail.value,
      vendorMessage: domElements.vendorMessage.value,
      smartHandsServiceLevel: getValueForSelectList(domElements.serviceType),
      smartHandsDate,
      smartHandsTime: getValueForSelectList(domElements.smartHandsTime),
    },
    "SAVE_RMA"
  );
};
const getValueForSelectList = (selectList) => {
  console.log("selectList.children: ", selectList.children);
  console.log("selectList.selectedIndex: ", selectList.selectedIndex);
  console.log(
    "selectList.children[selectList.selectedIndex]: ",
    selectList.children[selectList.selectedIndex]
  );
  console.log(
    "selectList.children[selectList.selectedIndex].value: ",
    selectList.children[selectList.selectedIndex].value
  );
  return selectList.children[selectList.selectedIndex].value;
};

const checkDefaultValidity = (elem) => elem.checkValidity();

const checkValidityShippingContactPhone = () => {
  const valid = phoneRegEx.test(domElements.shippingContactPhone.value);
  errorTextHandling(
    domElements.shippingContactPhone,
    valid,
    "Enter a valid Phone number"
  );

  return valid;
};

const checkValidityShippingContactEmail = () => {
  const regExValidation = (email) =>
    /^[-!#$%&'*+\/0-9=?A-Z^_a-z`{|}~](\.?[-!#$%&'*+\/0-9=?A-Z^_a-z`{|}~])*@[a-zA-Z0-9](-*\.?[a-zA-Z0-9])*\.[a-zA-Z](-?[a-zA-Z0-9])+$/.test(
      email
    );
  const checkDomainValidity = (email) => {
    const reg = new RegExp(/(?<=@).*$/g);
    const domain = reg.exec(email)[0];
    return !invalidDomainNameSet.has(domain);
  };

  const checkAllFunctionsForEmail = (email, ...funcs) => {
    return funcs.every((func) => func(email));
  };

  const { shippingContactEmail } = domElements;
  let shipToEmail = shippingContactEmail.value;

  const valid =
    domElements.shippingContactEmail.checkValidity() &&
    checkAllFunctionsForEmail(
      shipToEmail,
      regExValidation,
      checkDomainValidity
    );

  errorTextHandling(
    domElements.shippingContactEmail,
    valid,
    "Enter a valid Company Domain Email Id, eg: example@yourDomain.com"
  );
  return valid;
};

const calculateMinDate = (f = 0) => (isNaN(f) || !f ? 1 : f + 1);
const getDateDiff = () => {
  const [country] = domElements.shippingCountry.selectedOptions;
  return (
    new Date(smartsHandsEligibleCountry[country.innerText]).getDate() -
    new Date(Date.now()).getDate()
  );
};

const checkValidityShippingCountry = () => {
  const valid = domElements.shippingCountry.selectedIndex > 0;
  errorTextHandling(
    domElements.shippingCountry,
    valid,
    "Select a valid Country"
  );

  if (domElements.shippingCountry.selectedIndex) {
    unHideDomElement(domElements.smartHandsSection);
    j$(".datepicker").datepicker(
      "option",
      "minDate",
      calculateMinDate(getDateDiff())
    );
  } else {
    hideDomElement(domElements.smartHandsSection);
  }
  return valid;
};

const checkValidityShippingServiceType = () => {
  const valid = domElements.serviceType.selectedIndex > 0;

  errorTextHandling(
    domElements.serviceType,
    valid,
    "Select a valid Service Type"
  );

  return valid;
};

const checkValidityShippingStreet = () => {
  const valid = checkDefaultValidity(domElements.shippingStreet);

  errorTextHandling(
    domElements.shippingStreet,
    valid,
    "Enter a valid Street value"
  );

  return valid;
};
const checkValidityShippingCity = () => {
  const valid = checkDefaultValidity(domElements.shippingCity);

  errorTextHandling(
    domElements.shippingCity,
    valid,
    "Enter a valid City value"
  );

  return valid;
};

const checkValidityCustomerReferenceNum = () => {
  const valid = checkDefaultValidity(domElements.customerReferenceNum);

  errorTextHandling(
    domElements.customerReferenceNum,
    valid,
    "Enter a valid Customer Reference Number"
  );

  return valid;
};
const checkValidityShippingPostalCode = () => {
  const valid = checkDefaultValidity(domElements.shippingPostalCode);

  errorTextHandling(
    domElements.shippingPostalCode,
    valid,
    "Enter a valid Zip-code value"
  );

  return valid;
};

const checkValidityshippingContactName = () => {
  const valid = checkDefaultValidity(domElements.shippingContactName);
  errorTextHandling(
    domElements.shippingContactName,
    valid,
    "Enter a valid Ship to Contact Name"
  );

  return valid;
};

const checkValidityShippingState = () => {
  const valid =
    (domElements.shippingCountry.selectedIndex > 0 &&
      !shippingStateDataWithDependency.hasOwnProperty(
        domElements.shippingCountry.children[
          domElements.shippingCountry.selectedIndex
        ].value
      )) ||
    domElements.shippingState.selectedIndex > 0;

  errorTextHandling(
    domElements.shippingState,
    valid,
    "Select a value for State"
  );

  return valid;
};

const checkValiditySmartHandsDate = () => {
  const valid = !!domElements.smartHandsDate.value.length;

  errorTextHandling(
    domElements.smartHandsDate,
    valid,
    "Select a date for smart Hands arrival"
  );

  return valid;
};

const checkValiditySmartHandsTime = () => {
  const valid = domElements.smartHandsTime.selectedIndex > 0;

  errorTextHandling(
    domElements.smartHandsTime,
    valid,
    "Select a time for smart Hands arrival"
  );

  return valid;
};

const checkValidityAdditionalInterestedEmails = () => {
  if (!domElements.additionalInterestedMails.value.trim().length) {
    return true;
  } else {
    let valid = true;
    const emails = domElements.additionalInterestedMails.value.split(",");
    emails.forEach(
      (email) =>
        (valid =
          valid && rubrikEmailValidation.test(email.trim().toLowerCase()))
    );
    errorTextHandling(
      domElements.additionalInterestedMails,
      valid,
      "Enter valid comma-separated, rubrik.com emails"
    );

    return valid;
  }
};

const onChangeSendSmartHandsServices = async () => {
  showSpinner();

  const selectedCmpDataEntries = Object.entries(selectedComponentData);

  let hasHdd;
  let setIdSelectedAppliance = new Set();
  for (const [, data] of selectedCmpDataEntries) {
    if (data.component == "hdd") {
      hasHdd = true;
    }
    setIdSelectedAppliance.add(data.assetId);
  }

  await getValidSupportDataFromServer(setIdSelectedAppliance, hasHdd);

  hideSpinner();
  if (domElements.sendSmartHandsServices.checked) {
    unHideDomElement(domElements.sendSmartHandsServicesSection);
  } else {
    hideDomElement(domElements.sendSmartHandsServicesSection);
  }
  return true;
};

const getValidSupportDataFromServer = async (
  setIdSelectedAppliance,
  hasHdd
) => {
  const isSmartHandsQualified = await setSmartHandsEligibility();
  let checkedValidSupportFromServer = false;
  const { validSupport, nrdPolicy } = await callServer(
    {
      setIdAppliance: Array.from(setIdSelectedAppliance),
      hasHdd: hasHdd,
      isSmartHandsRequested: domElements.sendSmartHandsServices.checked,
      isSmartHandsQualified: isSmartHandsQualified,
    },
    "GET_VALIDITY_AND_NRD_POLICY"
  );
  hasNrdPolicy = nrdPolicy;
  hasValidSupport = validSupport;
  checkedValidSupportFromServer = true;
  smartHandsReason(
    isSmartHandsQualified,
    domElements.sendSmartHandsServices.checked
  );
};

let openSmartHandsReasonModal = false;

const smartHandsReason = (isSmartHandsQualified, isSmartHandsRequested) => {
  let needToOpenModal;
  if ((isSmartHandsRequested && !isSmartHandsQualified) || !hasValidSupport) {
    needToOpenModal = true;
    domElements.sendSmartHandsServicesModalReason.textContent = `Assets related to the selected Serial Numbers,
          either do not have a valid support entitlement or are not qualified for Smart Hands (if selected).
          This RMA request will be processed after approval by Customer Support Management.
          Please enter the justification details.`;
  }
  let reason = domElements["sendSmartHandsServicesCommentReason"].value;

  if (needToOpenModal) {
    if (!(reason.length > 0 && reason.length < 131000)) {
      openCommentModal();
    }
  }
};

const openCommentModal = () => {
  openSmartHandsReasonModal = true;
  domElements.backdrop.classList.add("slds-backdrop_open");
  domElements.sendSmartHandsCommentModal.classList.add("slds-fade-in-open");
  document.querySelector("body").classList.add("body-overflow");
};
const closeCommentModal = () => {
  openSmartHandsReasonModal = false;
  domElements.sendSmartHandsCommentModal.classList.remove("slds-fade-in-open");
  domElements.backdrop.classList.remove("slds-backdrop_open");
  document.querySelector("body").classList.remove("body-overflow");
};

const errorTextHandling = (domElementRef, valid, errorText) => {
  let containsErrorText =
    domElementRef.parentNode.parentNode.classList.contains("slds-has-error");
  if (!valid && !containsErrorText) {
    domElementRef.parentNode.parentNode.classList.add("slds-has-error");
    const errorMsg = document.createElement("div");
    errorMsg.classList.add("slds-form-element__help");
    errorMsg.textContent = errorText;

    domElementRef.parentNode.parentNode.appendChild(errorMsg);
  } else if (valid && containsErrorText) {
    domElementRef.parentNode.parentNode.classList.remove("slds-has-error");
    domElementRef.parentNode.nextElementSibling.remove();
  }
};

const hideSpinner = () => hideDomElement(domElements.spinnerBrandOnLoad);
const showSpinner = () => unHideDomElement(domElements.spinnerBrandOnLoad);

const getPicklistData = async () => {
  console.log("Getting picklist options");
  const instanceDomain = window.location.hostname;
  const apiVersion = "51.0";
  const headers = {
    Authorization: `OAuth ${sessionId}`,
    Accept: "application/json",
    "Content-Type": "application/json",
  };
  const rmaObjectInfoRequestResult = await fetch(
    `https://${instanceDomain}/services/data/v${apiVersion}/ui-api/object-info/RMA_Order__c/`,
    { headers }
  );
  const rmaObjectInfo = await rmaObjectInfoRequestResult.json();

  const { defaultRecordTypeId } = rmaObjectInfo;
  console.log("Default RecordTypeId: ", defaultRecordTypeId);
  const rmaObjectAllPicklistsRequestResult = await fetch(
    `https://${instanceDomain}/services/data/v${apiVersion}/ui-api/object-info/RMA_Order__c/picklist-values/${defaultRecordTypeId}/`,
    { headers }
  );
  const rmaObjectAllPicklists = (
    await rmaObjectAllPicklistsRequestResult.json()
  ).picklistFieldValues;
  console.log("rmaObjectAllPicklists: ", rmaObjectAllPicklists);
  const {
    Service_Type__c,
    ShippingCountry__c,
    ShippingState__c,
    Time_of_Smart_Hands_Tech_Arrival__c,
  } = rmaObjectAllPicklists;

  const timeOfSmartHandsArrivalData =
    Time_of_Smart_Hands_Tech_Arrival__c.values.map(({ value, label }) => ({
      value,
      label,
    }));

  const serviceTypeData = Service_Type__c.values.map(({ value, label }) => ({
    value,
    label,
  }));

  const shippingCountryData = ShippingCountry__c.values.map(
    ({ value, label }) => ({ value, label })
  );

  const { controllerValues: shippingStateControllerData } = ShippingState__c;

  const shippingStateData = {};

  const shippingCountryValidForReverse = {};
  Object.keys(shippingStateControllerData).forEach((key) => {
    shippingCountryValidForReverse[shippingStateControllerData[key]] = key;
  });

  console.log(shippingCountryValidForReverse);
  ShippingState__c.values.forEach((valueBundle) => {
    const { label, value, validFor } = valueBundle;

    validFor.forEach((dependentFieldIndex) => {
      if (
        !shippingStateData.hasOwnProperty(
          shippingCountryValidForReverse[dependentFieldIndex]
        )
      ) {
        shippingStateData[shippingCountryValidForReverse[dependentFieldIndex]] =
          [];
      }
      if (
        shippingStateData.hasOwnProperty(
          shippingCountryValidForReverse[dependentFieldIndex]
        )
      ) {
        shippingStateData[
          shippingCountryValidForReverse[dependentFieldIndex]
        ].push({ label, value });
      }
    });
  });

  console.group("received picklist options");
  console.log("timeOfSmartHandsArrivalData:", timeOfSmartHandsArrivalData);
  console.log("serviceTypeData:", serviceTypeData);
  console.log("shippingCountryData:", shippingCountryData);
  console.log("shippingStateData: ", shippingStateData);

  console.groupEnd("received picklist options");
  return {
    timeOfSmartHandsArrivalData,
    serviceTypeData,
    shippingCountryData,
    shippingStateData,
  };
};

const setPicklistOptions = async (
  selectListElementReference,
  optionData = []
) => {
  const selectList = domElements[selectListElementReference];
  selectList.innerHTML = "";
  const frag = document.createDocumentFragment();
  const emptyOption = document.createElement("option");
  emptyOption.setAttribute("value", "");
  emptyOption.innerText = "--None--";
  frag.appendChild(emptyOption);
  optionData.forEach(({ value, label }) => {
    const option = document.createElement("option");
    option.setAttribute("value", value);
    option.innerText = label;
    frag.appendChild(option);
  });
  selectList.appendChild(frag);
};

let shippingStateDataWithDependency;
const setEssentialDataForPage = async () => {
  console.group("getting essential data to load page");
  if(accId != undefined && accId != '' && accId != null){
    await getAccountDataDetails();
  }else{
    await getAccountDataInfo();   
  }
  await Promise.all([
    getClusterDataInfo(),
    getFailuresInfo(),
    getSmartHandsAssetInfo(),
    getSmartHandsCountriesInfo(),
  ]);
  const {
    timeOfSmartHandsArrivalData,
    serviceTypeData,
    shippingCountryData,
    shippingStateData,
  } = await getPicklistData();
  console.groupEnd("getting essential data to load page");

  console.group("setting essential data to load page");

  await setPicklistOptions("serviceType", serviceTypeData);
  await setPicklistOptions("shippingCountry", shippingCountryData);
  await setPicklistOptions("smartHandsTime", timeOfSmartHandsArrivalData);
  await setPicklistOptions("shippingState");
  shippingStateDataWithDependency = shippingStateData;
  console.groupEnd("setting essential data to load page");

  hideSpinner();
  domElements.selectComponentDropdown.focus();
};

const showHeaderErrorToast = (text) => {
  domElements.toastErrorHeaderText.innerText = text;
  unHideDomElement(domElements.toastErrorHeader);
};

const changeModalFilterList = ({ target }) => {
  const selectedOption = target.children[target.selectedIndex];
  const labelText = selectedOption["data-value-for-label"];
  domElements.searchModalFilterLabel.innerText = labelText;
  domElements.searchModalFilterByValue.value = "";
  if (dataTableCurrentFilterValues.hasOwnProperty(selectedOption.value)) {
    domElements.searchModalFilterByValue.value =
      dataTableCurrentFilterValues[selectedOption.value];
  }

  console.log("Change Filter by: ", labelText);
};

const clickModalFilterBtn = ({ target }) => {
  const selectList = domElements.searchModalFilterSelectList;
  console.log("clickModalFilterBtn, target:", target);
  console.log("clickModalFilterBtn, selectList: ", selectList);

  const filterBy = selectList.children[selectList.selectedIndex].value;

  const filterForVal = domElements.searchModalFilterByValue.value.trim();

  const cmp = selectedComponent.toLowerCase();

  dataTableInstancesInfo[cmp].hasFilter = true;
  dataTableInstancesInfo[cmp].filterInfo.By = filterBy;
  dataTableInstancesInfo[cmp].filterInfo.forValue = filterForVal;
  console.log(
    `filter ${selectedComponent}: `,
    dataTableInstancesInfo[cmp].hasFilter,
    dataTableInstancesInfo[cmp].filterInfo
  );
  unFilterDataTable = false;
  destroyDataTable();
  domElements.componentQuantityButton.click();
};

const handlePaginationNext100 = () => {
  console.group("handlePaginationNext100");

  showSpinner();

  const { curEnd, totalSize } = currentInstanceData;
  const { componentQuantityButton } = domElements;

  currentInstanceData.curStart = curEnd;
  currentInstanceData.curEnd = Math.min(totalSize, curEnd + 1000);

  UnFilterBeforeClosingDataTable(false);
  componentQuantityButton.click();

  console.groupEnd("handlePaginationNext100");
};

const handlePaginationPrev100 = () => {
  console.group("handlePaginationPrev100");
  showSpinner();

  const { curStart } = currentInstanceData;
  const { componentQuantityButton } = domElements;

  currentInstanceData.curStart = Math.max(0, curStart - 1000);
  currentInstanceData.curEnd = curStart;

  UnFilterBeforeClosingDataTable(false);
  componentQuantityButton.click();

  console.groupEnd("handlePaginationPrev100");
};

const openViewAllModal = () => {
  document
    .querySelectorAll("i.fa.fa-trash.selection-modal")
    .forEach((elem) =>
      elem.addEventListener("click", removeRowInSelectionModal)
    );

  /**js for other option for failure reason**/
  if (j$(".failure-select").val() == "Other") {
    j$(this).closest("tr").find(".other-input").removeClass("slds-hide");
  } else {
    j$(this).closest("tr").find(".other-input").addClass("slds-hide");
  }
  j$(".failure-select").change(function () {
    var tableRow = j$(this).closest("tr");
    if (j$(this).val() == "Other") {
      j$(tableRow).find(".other-input").removeClass("slds-hide");
    } else {
      j$(tableRow).find(".other-input").addClass("slds-hide");
    }
  });

  document.querySelector("#view-backdrop").classList.add("slds-backdrop_open");
  document.querySelector("#viewall-modal").classList.add("slds-fade-in-open");
  document.querySelector("body").classList.add("body-overflow");
};

const closeViewAllModal = () => {
  document
    .querySelectorAll("i.fa.fa-trash.selection-modal")
    .forEach((elem) =>
      elem.removeEventListener("click", removeRowInSelectionModal)
    );

  document
    .querySelector("#viewall-modal")
    .classList.remove("slds-fade-in-open");
  document
    .querySelector("#view-backdrop")
    .classList.remove("slds-backdrop_open");
  document.querySelector("body").classList.remove("body-overflow");
  fillSelectedComponentsTable(selectedComponentData);
};

const saveAndCloseViewAllModal = () => {
  const tableRows = domElements.selectedComponentsModalTableBody.children;

  let invalidateSaveOtherFailReason = false;
  const tableInstanceSelectedComponentData = {};

  if (!tableRows.length) {
    hideDomElement(domElements.selectedComponentsSection);
    disableElem(domElements.saveRma);
  } else {
    enableElem(domElements.saveRma);
    for (const row of tableRows) {
      console.log(row);
      console.log(row);
      const componentId = row["data-id"];

      tableInstanceSelectedComponentData[componentId] = {
        ...selectedComponentData[componentId],
      };
      const failureSelectList =
        row.children[2].firstElementChild.firstElementChild.firstElementChild;
      const [selectedOption] = failureSelectList.selectedOptions;
      tableInstanceSelectedComponentData[componentId]["reason"] =
        selectedOption.value;

      let inputElem = row.children[3].firstElementChild;
      console.log(inputElem);
      if (selectedOption.value == "Other") {
        const value = inputElem.value.trim();
        if (value.length) {
          tableInstanceSelectedComponentData[componentId]["otherFailReason"] =
            value;
        } else {
          tableInstanceSelectedComponentData[componentId]["otherFailReason"] =
            value.length ? value : null;
          invalidateSaveOtherFailReason = true;
        }
      } else {
        tableInstanceSelectedComponentData[componentId]["otherFailReason"] =
          null;
      }
    }
  }
  if (!invalidateSaveOtherFailReason) {
    selectedComponentData = tableInstanceSelectedComponentData;
    fillSelectedComponentsTable(selectedComponentData);
    checkSmartHandsEligibilityAsset();
    closeViewAllModal();
  } else {
    showHeaderErrorToast("Please Enter Valid Other Reason for all Components");
  }
};

function simulateChangeEvent(element) {
  console.log("simulateChangeEvent: ", element);
  const event = new Event("change", {
    view: window,
    bubbles: true,
    cancelable: false,
  });
  element.dispatchEvent(event);
}

const checkValiditySelectedComponentData = () => {
  const componentValidity = Object.values(selectedComponentData).reduce(
    (validity, data) => {
      if (data.reason === "Other" && !data.otherFailReason) {
        return validity && false;
      } else return validity && true;
    },
    true
  );
  if (!componentValidity) {
    showHeaderErrorToast(
      "Please Ensure all Components with Other as Failure reason have valid Fail reason entered"
    );
  }
  return componentValidity;
};

const onClickSaveRmaBtn = async () => {
  let res = await onChangeSendSmartHandsServices();
  console.log("-save RMA- getValidSupportDataFromServer=> res: ", res);
  const validity = await validityAllFields();
  console.log("-save RMA- validityAllFields=> validity: ", validity);
  if (validity) {
    sendSaveReq(validity);
  }
};

const sendSaveReq = async (validity) => {
  if (
    validity &&
    !openSmartHandsReasonModal &&
    Object.entries(selectedComponentData).length
  ) {
    showSpinner();
    saveRmaForm(
      domElements.sendSmartHandsServices.checked,
      await setSmartHandsEligibility(),
      hasValidSupport,
      domElements["sendSmartHandsServicesCommentReason"].value
    ).then((res) => {
      openSaveSuccessModal();
      rmaId = res.Id;
    });

    [
      domElements.selectComponentDropdown,
      domElements.componentQuantityButton,
      domElements.shippingAddressCopyFromAccount,
      domElements.shippingStreet,
      domElements.shippingCity,
      domElements.shippingCountry,
      domElements.shippingState,
      domElements.shippingPostalCode,
      domElements.shippingContactName,
      domElements.shippingContactEmail,
      domElements.shippingContactPhone,
      domElements.serviceType,
      domElements.additionalInterestedMails,
      domElements.sendSmartHandsServices,
      domElements.smartHandsDate,
      domElements.smartHandsTime,
    ].forEach((elem) => disableElem(elem));

    document
      .querySelectorAll("i.fa.fa-trash:not(.selection-modal)")
      .forEach((elem) =>
        elem.removeEventListener("click", removeCmpFromSelectedSection)
      );
  }
};

const openSaveSuccessModal = () => {
  hideSpinner();
  domElements.backdrop.classList.add("slds-backdrop_open");
  unHideDomElement(document.querySelector("#rma-save-success"));
  document
    .querySelector("#rma-save-success")
    .classList.add("slds-fade-in-open");
  document.querySelector("body").classList.add("body-overflow");
};

const resetInputField = (elem) => (elem.value = "");
const resetSelectListField = (elem) => (elem.selectedIndex = 0);

let justCopiedShippingDetailsFromAccount = false;

const removeRowInSelectionModal = (e) => {
  row = e.target.parentNode.parentNode.parentNode;
  row.remove();
};

const changeModalFilterByValue = ({ target }) => {
  value = target.value.trim();

  const selectList = domElements.searchModalFilterSelectList;
  dataTableCurrentFilterValues[
    selectList.children[selectList.selectedIndex].value
  ] = target.value;
};

const UnFilterBeforeClosingDataTable = (needToUnFilter = true) => {
  domElements.searchModalFooterToastClose.click();
  unFilterDataTable = needToUnFilter;
  if (unFilterDataTable) {
    resetCurrentInstanceData();
  }
  tempSelectedComponentData = {};
  destroyDataTable();
};

window.addEventListener("loadedDomMappings", () => {
  console.log("loadedDomMappings received.");

  domElements["caseNumber"] = document.querySelector("#case-number");
  domElements["accountName"] = document.querySelector("#account-name");
  domElements["clusterUuid"] = document.querySelector("#cluster-uuid");
  domElements["customerReferenceNum"] = document.querySelector("#customer-reference-number");
  domElements["toastErrorHeader"] = document.querySelector("#toast-header");
  domElements["toastErrorHeaderText"] =
    document.querySelector("#toast-header-text");
  domElements["spinnerBrandOnLoad"] = document.querySelector(
    "#spinner-brand-on-load"
  );
  domElements["selectComponentDropdown"] = document.querySelector(
    "#select-component-dropdown"
  );
  domElements["componentQuantityAndSearchBlock"] = document.querySelector(
    "#component-quantity-and-search"
  );
  domElements["componentQuantityLabel"] = document.querySelector(
    "#component-quantity-and-search > div > label"
  );
  domElements["componentQuantityInput"] = document.querySelector(
    "#component-quantity"
  );
  domElements["componentQuantityButton"] = document.querySelector(
    "#component-quantity-and-search > button"
  );
  domElements["componentSearchButtonLabel"] =
    document.querySelector("#search-btn-label");
  domElements["searchComponentModal"] = document.querySelector(
    "#search-component-modal"
  );
  domElements["searchModalFilterSelectList"] = document.querySelector(
    "#search-modal-filter-select-list"
  );
  domElements["searchModalFilterByValue"] = document.querySelector(
    "#search-modal-filter-block > div:nth-child(2) > div > input"
  );
  domElements["searchModalFilterBtn"] = document.querySelector(
    "#search-modal-filter-btn"
  );
  domElements["searchComponentModalHeader"] = document.querySelector(
    "#search-modal-heading"
  );
  domElements["searchModalFilterBlock"] = document.querySelector(
    "#search-modal-filter-block"
  );
  domElements["searchModalDataTable"] =
    document.querySelector("#searchDataTable");

  domElements["searchModalFooterToast"] = document.querySelector(
    "#search-modal-footer-toast"
  );
  domElements["searchModalFooterToastText"] = document.querySelector(
    "#search-modal-footer-toast-text"
  );
  domElements["searchModalFooterToastClose"] = document.querySelector(
    "#search-modal-footer-toast-close"
  );

  domElements["searchModalPrev1000"] = document.querySelector(
    "#search-modal-prev-1000"
  );

  domElements["searchModalNext1000"] = document.querySelector(
    "#search-modal-next-1000"
  );

  domElements["searchModalCancel"] = document.querySelector(
    "#search-modal-cancel"
  );

  domElements["searchModalFilterLabel"] = document.querySelector(
    "#search-modal-filter-label"
  );
  domElements["searchModalSave"] = document.querySelector("#search-modal-save");

  domElements["searchModalClose"] = document.querySelector("#searchModalClose");

  domElements["selectedComponentsSection"] = document.querySelector(
    "#selected-components-section"
  );
  domElements["selectedComponentsSectionTableBody"] = document.querySelector(
    "#selected-components-section-table-body"
  );
  domElements["selectedComponentsSectionCount"] = document.querySelector(
    "#selected-components-section-count"
  );

  domElements["selectedComponentsModalTableBody"] = document.querySelector(
    "#selected-components-modal-table-body"
  );

  domElements["shippingContactName"] = document.querySelector(
    "#shipping-contact-name"
  );

  domElements["smartHandsSection"] = document.querySelector(
    "#smart-hands-section"
  );
  domElements["isEntitlementForSmartHands"] = document.querySelector(
    "#entitled-for-smart-hands-service"
  );

  domElements["additionalInterestedMails"] = document.querySelector(
    "#additional-interested-parties-emails"
  );
  domElements["shippingCountry"] = document.querySelector(
    "#shippingAddressCountry"
  );
  domElements["serviceType"] = document.querySelector("#serviceType");
  domElements["shippingState"] = document.querySelector(
    "#shippingAddressState"
  );

  domElements["shippingStreet"] = document.querySelector(
    "#shipping-address-street"
  );
  domElements["shippingContactEmail"] = document.querySelector(
    "#shipping-contact-email"
  );
  domElements["shippingContactPhone"] = document.querySelector(
    "#shipping-contact-phone-number"
  );

  domElements["shippingAddressCopyFromAccount"] = document.querySelector(
    "#copy-address-from-account"
  );

  domElements["shippingPostalCode"] = document.querySelector(
    "#shipping-address-zipcode"
  );
  domElements["shippingCity"] = document.querySelector(
    "#shipping-address-city"
  );
  domElements["vendorMessage"] = document.querySelector(
    "#vendor-message"
  );
  domElements["sendSmartHandsServices"] = document.querySelector(
    "#send-smart-hand-service"
  );
  domElements["sendSmartHandsServicesSection"] = document.querySelector(
    "#send-smart-hand-service-section"
  );
  domElements["sendSmartHandsCommentModal"] = document.querySelector(
    "#smart-hands-comment-modal"
  );
  domElements["sendSmartHandsServicesModalReason"] = document.querySelector(
    "#smart-hands-comment-modal-reason"
  );
  domElements["sendSmartHandsServicesCommentReason"] = document.querySelector(
    "#smart-hands-comment-reason"
  );
  domElements["shippingContactName"] = document.querySelector(
    "#shipping-contact-name"
  );
    
  domElements["accountLookupId"] =  document.querySelector(
    ".account_lookup"
  );
  
  domElements["smartHandsDate"] = document.querySelector("input.datepicker");
  domElements["smartHandsTime"] = document.getElementById("smartHandsTime");

  domElements.body = document.querySelector("body");
  domElements.backdrop = document.querySelector("#backdrop");

  domElements["saveRma"] = document.querySelector("#rma-save");
  domElements["cancelRma"] = document.querySelector("#rma-cancel");

  setEssentialDataForPage();
  document
    .querySelector(
      "#toast-header > div > div > div.slds-notify__close > button"
    )
    .addEventListener(
      "click",
      () => (domElements.toastErrorHeader.style.display = "none")
    );

  domElements.clusterUuid.addEventListener(
    "change",
    ({ target: { value } }) => {
      console.log(`clusterUuid: ${value}`);
      value = value.trim();
      if (!value.length || Object.keys(availabelCluster).includes(value)) {
        clusterUuid = value;
      } else {
        showHeaderErrorToast(
          `Cluster UUID invalid for Account name: ${accountDetails.name}`
        );
      }
    }
  );

  domElements.selectComponentDropdown.addEventListener(
    "change",
    ({ target: { value } }) => {
      if (selectedComponent == value) {
        console.log(`Component not changed from ${value}`);
      } else {
        disableElem(domElements.componentQuantityButton);
        console.log(`Component changed from ${selectedComponent} to ${value} `);
        selectedComponent = value;

        console.log(
          `first Element Child:`,
          domElements.selectComponentDropdown.firstElementChild
        );
        console.log(`value: ${value}`);

        if (
          domElements.selectComponentDropdown.firstElementChild.value === value
        ) {
          hideDomElement(domElements.componentQuantityAndSearchBlock);
        } else {
          showQuantityAndSearchBlock(selectedComponent);
        }
      }
    }
  );

  domElements.componentQuantityInput.addEventListener(
    "input",
    ({ target: { value } }) => {
      if (/^\d{1,6}$/.test(value) && parseInt(value) > 0) {
        console.log("Enable Search button");
        enableElem(domElements.componentQuantityButton);
      } else {
        console.log("Disable Search button");
        disableElem(domElements.componentQuantityButton);
      }
    }
  );

  [domElements.searchModalCancel, domElements.searchModalClose].forEach(
    (elem) => elem.addEventListener("click", UnFilterBeforeClosingDataTable)
  );

  domElements.searchModalFooterToastClose.addEventListener(
    "click",
    () => (domElements.searchModalFooterToast.style.display = "none")
  );

  domElements.searchModalSave.addEventListener("click", () => {
    const cmp = selectedComponent.toLowerCase();
    tempSelectedComponentData = {};
    const selectedComponents = getSelectedComponents(cmp);

    countSelectedCurrentCmp = 0;
    for (const [id, data] of Object.entries(selectedComponents)) {
      tempSelectedComponentData[id] = data;
      countSelectedCurrentCmp++;
    }

    if (countSelectedCurrentCmp === getQuantityAllowed()) {
      console.log("save data ");
      console.log(selectedComponent);

      if (cmp === "appliance") {
        if (!isApplianceOnly) {
          selectedComponentData = {};
        }
        isApplianceOnly = true;
      } else if (cmp === "ssd") {
        if (!isSsdOnly) {
          selectedComponentData = {};
        }
        isSsdOnly = true;
      } else {
        if (isApplianceOnly || isSsdOnly) {
          selectedComponentData = {};
        }
        isSsdOnly = false;
        isApplianceOnly = false;
      }

      for (const [id, data] of Object.entries(tempSelectedComponentData)) {
        selectedComponentData[id] = data;
      }

      console.log("Close data table");
      unFilterDataTable = true;
      destroyDataTable();
      renderSelectedComponentsSection();
      setSmartHandsEligibility();
      tempSelectedComponentData = {};
    } else {
      showModalErrorToast(
        `Number of selected ${domElements.searchComponentModalHeader.innerText} is not equal to Quantity specified or the Failure Reasons are missing.`
      );
    }
  });

  domElements.searchModalFilterBtn.addEventListener(
    "click",
    clickModalFilterBtn
  );
  domElements.searchModalFilterSelectList.addEventListener(
    "change",
    changeModalFilterList
  );
  domElements.searchModalFilterByValue.addEventListener(
    "change",
    changeModalFilterByValue
  );

  domElements.componentQuantityButton.addEventListener("click", () => {
    showSpinner();
    console.log("Show Modal for Selected component: ", selectedComponent);
    if (
      [
        "Appliance",
        "Chassis",
        "PSU",
        "HDD",
        "SSD",
        "Memory",
        "Node",
        "CMOS",
      ].includes(selectedComponent)
    ) {
      console.log(`Show ${selectedComponent} Modal`);
      const cmp = selectedComponent.toLowerCase();
      domElements.searchComponentModalHeader.innerText = selectedComponent;

      if (isDataRetrieved[cmp]) {
        createDataTable(cmp);
      } else if (!isDataRetrieved[cmp]) {
        fetchComponentData(cmp).then((res) => createDataTable(cmp));
      }
    }
  });

  domElements.searchModalNext1000.addEventListener(
    "click",
    handlePaginationNext100
  );
  domElements.searchModalPrev1000.addEventListener(
    "click",
    handlePaginationPrev100
  );

  domElements.shippingCountry.addEventListener(
    "change",
    setSmartHandsEligibility
  );

  Array.from(document.querySelectorAll("form div.slds-form-element")).forEach(
    (elem) =>
      elem.addEventListener("focus", ({ target }) => {
        if (target.parentNode.parentNode.classList.contains("slds-has-error")) {
          target.parentNode.nextElementSibling.remove();
          target.parentNode.parentNode.classList.remove("slds-has-error");
        }
      })
  );

  domElements.shippingStreet.addEventListener("change", () => {
    if (justCopiedShippingDetailsFromAccount) {
      justCopiedShippingDetailsFromAccount = false;
      domElements.shippingAddressCopyFromAccount.checked = false;
    }
    checkValidityShippingStreet();
  });
  domElements.shippingCity.addEventListener("change", () => {
    if (justCopiedShippingDetailsFromAccount) {
      justCopiedShippingDetailsFromAccount = false;
      domElements.shippingAddressCopyFromAccount.checked = false;
    }
    checkValidityShippingCity();
  });
  domElements.shippingState.addEventListener("change", () => {
    if (justCopiedShippingDetailsFromAccount) {
      justCopiedShippingDetailsFromAccount = false;
      domElements.shippingAddressCopyFromAccount.checked = false;
    }
    checkValidityShippingState();
  });
  domElements.shippingCountry.addEventListener("change", () => {
    if (justCopiedShippingDetailsFromAccount) {
      justCopiedShippingDetailsFromAccount = false;
      domElements.shippingAddressCopyFromAccount.checked = false;
    }
    setStatePicklist(domElements.shippingCountry.value);
    checkValidityShippingCountry();
  });
  domElements.shippingPostalCode.addEventListener("change", () => {
    if (justCopiedShippingDetailsFromAccount) {
      justCopiedShippingDetailsFromAccount = false;
      domElements.shippingAddressCopyFromAccount.checked = false;
    }
    checkValidityShippingPostalCode();
  });

  domElements.shippingContactPhone.addEventListener(
    "change",
    checkValidityShippingContactPhone
  );
  domElements.shippingContactEmail.addEventListener(
    "change",
    checkValidityShippingContactEmail
  );
  domElements.additionalInterestedMails.addEventListener(
    "change",
    checkValidityAdditionalInterestedEmails
  );
  domElements.serviceType.addEventListener(
    "change",
    checkValidityShippingServiceType
  );

  domElements.shippingContactName.addEventListener(
    "change",
    checkValidityshippingContactName
  );
                
  domElements.accountLookupId.addEventListener(
    "change",
     getAccountDataDetails
  );

  domElements.shippingCountry.addEventListener("change", ({ target }) =>
    console.log("Change: ", target)
  );
  domElements.shippingState.addEventListener("change", ({ target }) =>
    console.log("Change: ", target)
  );
  
  domElements.shippingAddressCopyFromAccount.addEventListener(
    "change",
    async () => {
      const {
        shippingPostalCode,
        shippingCity,
        shippingStreet,
        shippingState,
        shippingCountry,
      } = domElements;
      if (domElements.shippingAddressCopyFromAccount.checked) {
        const { street, city, state, country, postalCode } =
          accountDetails.shippingInfo;
        shippingPostalCode.value = postalCode;
        shippingCity.value = city;
        shippingStreet.value = street;
        for (option of shippingCountry.children) {
          if (option.value === country) {
            option.selected = true;
            simulateChangeEvent(shippingCountry);
            await setStatePicklist(domElements.shippingCountry.value);
          }
        }
        for (option of shippingState.children) {
          if (option.value === state || option.innerText === state) {
            option.selected = true;
            simulateChangeEvent(shippingState);
          }
        }

        checkValidityShippingCountry();

        justCopiedShippingDetailsFromAccount = true;
      } else {
        [shippingPostalCode, shippingCity, shippingStreet].forEach((elem) =>
          resetInputField(elem)
        );
        [shippingState, shippingCountry].forEach((elem) => {
          resetSelectListField(elem);
          simulateChangeEvent(elem);
          errorTextHandling(elem, true, "");
        });
      }
    }
  );

  domElements.sendSmartHandsServices.addEventListener(
    "change",
    onChangeSendSmartHandsServices
  );

  document
    .querySelector("#smart-hands-modal-close")
    .addEventListener("click", closeCommentModal);
  document
    .querySelector("#smart-hands-modal-cancel")
    .addEventListener("click", closeCommentModal);

  domElements.saveRma.addEventListener("click", onClickSaveRmaBtn);
  domElements.cancelRma.addEventListener("click", backToCase);
  document
    .querySelector("#save-success-to-case")
    .addEventListener("click", backToCase);

  document
    .querySelector("#save-success-to-rma")
    .addEventListener("click", redirectToRma);

  disableElem(domElements.searchModalPrev1000);
  disableElem(domElements.searchModalNext1000);
});