import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import OPPORTUNITY_NAME from "@salesforce/schema/Opportunity.Name";
import OPPORTUNITY_ACCOUNT_ID from "@salesforce/schema/Opportunity.AccountId";
import OPPORTUNITY_ACCOUNT_NAME from "@salesforce/schema/Opportunity.Account.Name";
import getOpportunities from "@salesforce/apex/InvoiceController.getOpportunities";
import saveInvoice from "@salesforce/apex/InvoiceController.saveInvoice";

const OPPORTUNITY_FIELDS = [
  OPPORTUNITY_NAME,
  OPPORTUNITY_ACCOUNT_ID,
  OPPORTUNITY_ACCOUNT_NAME
];

let rowCounter = 1;

// Creates a blank line-item row with a stable unique id for template keys.
function createLineItemRow() {
  rowCounter += 1;
  return {
    id: `row-${rowCounter}`,
    productName: "",
    quantity: 1,
    unitPrice: 0
  };
}

// Extracts a user-friendly message from Apex or LDS error objects.
function reduceErrors(error) {
  if (!error) {
    return "Unknown error";
  }
  if (Array.isArray(error.body)) {
    return error.body.map((e) => e.message).join(", ");
  }
  if (typeof error.body?.message === "string") {
    return error.body.message;
  }
  if (typeof error.message === "string") {
    return error.message;
  }
  return "Unknown error";
}

export default class InvoiceGenerator extends NavigationMixin(
  LightningElement
) {
  @api recordId;

  currentStep = "1";
  isLoading = false;

  selectedOpportunityId;
  selectedCustomerId;
  customerName = "";
  opportunityName = "";

  opportunityOptions = [];
  opportunitiesLoaded = false;

  lineItems = [createLineItemRow()];

  // LDS wire: pre-fills opportunity and customer when opened from Opportunity quick action.
  @wire(getRecord, { recordId: "$recordId", fields: OPPORTUNITY_FIELDS })
  wiredOpportunity({ data, error }) {
    if (data) {
      this.applyOpportunitySelection(
        this.recordId,
        getFieldValue(data, OPPORTUNITY_NAME),
        getFieldValue(data, OPPORTUNITY_ACCOUNT_ID),
        getFieldValue(data, OPPORTUNITY_ACCOUNT_NAME)
      );
    } else if (error) {
      this.showErrorToast("Unable to load opportunity", reduceErrors(error));
    }
  }

  // Loads opportunity picklist options when component is inserted.
  connectedCallback() {
    this.loadOpportunityOptions();
  }

  // True when wizard is on Step 1 (customer and opportunity).
  get isStep1() {
    return this.currentStep === "1";
  }

  // True when wizard is on Step 2 (line items).
  get isStep2() {
    return this.currentStep === "2";
  }

  // Progress indicator style for Step 1 pill.
  get step1Variant() {
    return this.isStep1 ? "shade" : "base";
  }

  // Progress indicator style for Step 2 pill.
  get step2Variant() {
    return this.isStep2 ? "shade" : "base";
  }

  // True when launched from an Opportunity record (quick action provides recordId).
  get launchedFromOpportunity() {
    return Boolean(this.recordId);
  }

  // Opportunity field is read-only when recordId is set from quick action.
  get isOpportunityReadOnly() {
    return this.launchedFromOpportunity;
  }

  // Disables Next until both opportunity and customer account are selected.
  get isNextDisabled() {
    return !this.selectedOpportunityId || !this.selectedCustomerId;
  }

  // Getter: sums quantity × unit price across all line items.
  get grandTotal() {
    return this.lineItems.reduce((sum, item) => {
      const quantity = Number(item.quantity) || 0;
      const unitPrice = Number(item.unitPrice) || 0;
      return sum + quantity * unitPrice;
    }, 0);
  }

  // Formats grand total for display in the template.
  get formattedGrandTotal() {
    return this.grandTotal.toFixed(2);
  }

  // Disables save while loading or when any line item is invalid.
  get isSaveDisabled() {
    if (this.isLoading) {
      return true;
    }
    if (!this.lineItems.length) {
      return true;
    }
    return this.lineItems.some((item) => {
      const quantity = Number(item.quantity);
      const unitPrice = Number(item.unitPrice);
      return (
        !item.productName ||
        !quantity ||
        quantity < 1 ||
        unitPrice < 0 ||
        Number.isNaN(unitPrice)
      );
    });
  }

  // Adds per-row line total for display in Step 2 grid.
  get lineItemsWithTotals() {
    return this.lineItems.map((item) => {
      const quantity = Number(item.quantity) || 0;
      const unitPrice = Number(item.unitPrice) || 0;
      return {
        ...item,
        rowTotal: (quantity * unitPrice).toFixed(2)
      };
    });
  }

  // Imperative Apex: loads opportunities for combobox when not on a record page.
  async loadOpportunityOptions() {
    try {
      const opportunities = await getOpportunities();
      this.opportunityOptions = opportunities.map((opp) => ({
        label: `${opp.Name} — ${opp.Account?.Name || "No Account"}`,
        value: opp.Id,
        accountId: opp.AccountId,
        accountName: opp.Account?.Name,
        opportunityName: opp.Name
      }));
    } catch (error) {
      this.showErrorToast("Unable to load opportunities", reduceErrors(error));
    } finally {
      this.opportunitiesLoaded = true;
    }
  }

  // Sets customer and opportunity when user picks from combobox.
  handleOpportunityChange(event) {
    const opportunityId = event.detail.value;
    const selected = this.opportunityOptions.find(
      (opt) => opt.value === opportunityId
    );
    if (!selected) {
      return;
    }
    this.applyOpportunitySelection(
      selected.value,
      selected.opportunityName,
      selected.accountId,
      selected.accountName
    );
  }

  // Stores selected opportunity and related account on the component state.
  applyOpportunitySelection(opportunityId, oppName, accountId, accountName) {
    this.selectedOpportunityId = opportunityId;
    this.opportunityName = oppName || "";
    this.selectedCustomerId = accountId;
    this.customerName = accountName || "";
  }

  // Validates Step 1 and advances to line items step.
  handleNext() {
    if (this.isNextDisabled) {
      this.showErrorToast(
        "Validation",
        "Select an opportunity with a related customer account."
      );
      return;
    }
    this.currentStep = "2";
  }

  // Returns wizard to Step 1 without clearing selections.
  handleBack() {
    this.currentStep = "1";
  }

  // Appends a new empty line item row.
  handleAddRow() {
    this.lineItems = [...this.lineItems, createLineItemRow()];
  }

  // Removes a line item row; requires at least one row to remain.
  handleRemoveRow(event) {
    const rowId = event.target.dataset.id;
    if (this.lineItems.length === 1) {
      this.showErrorToast("Validation", "At least one line item is required.");
      return;
    }
    this.lineItems = this.lineItems.filter((item) => item.id !== rowId);
  }

  // Updates a line item field; uses spread for LWC reactivity.
  handleInputChange(event) {
    const rowId = event.target.dataset.id;
    const field = event.target.dataset.field;
    let value = event.target.value;

    if (field === "quantity" || field === "unitPrice") {
      value = value === "" ? "" : Number(value);
    }

    this.lineItems = this.lineItems.map((row) =>
      row.id === rowId ? { ...row, [field]: value } : row
    );
  }

  // Saves invoice via Apex, opens PDF, shows toast, and navigates to invoice record.
  async handleSave() {
    if (this.isSaveDisabled) {
      this.showErrorToast(
        "Validation",
        "Complete all line items before saving."
      );
      return;
    }

    this.isLoading = true;
    const invoiceRecord = {
      Customer__c: this.selectedCustomerId,
      Opportunity__c: this.selectedOpportunityId,
      Status__c: "Draft",
      Total_Amount__c: this.grandTotal
    };

    const lineItemRecords = this.lineItems.map((item) => ({
      Product_Name__c: item.productName,
      Quantity__c: Number(item.quantity),
      Unit_Price__c: Number(item.unitPrice)
    }));

    try {
      const invoiceId = await saveInvoice({
        invoice: invoiceRecord,
        lineItems: lineItemRecords
      });

      window.open(`/apex/InvoicePDF?id=${invoiceId}`, "_blank");

      this.dispatchEvent(
        new ShowToastEvent({
          title: "Success",
          message: "Invoice created and PDF opened in a new tab.",
          variant: "success"
        })
      );

      this[NavigationMixin.Navigate]({
        type: "standard__recordPage",
        attributes: {
          recordId: invoiceId,
          objectApiName: "Invoice__c",
          actionName: "view"
        }
      });
    } catch (error) {
      this.showErrorToast("Save failed", reduceErrors(error));
    } finally {
      this.isLoading = false;
    }
  }

  // Shows an error toast with the given title and message.
  showErrorToast(title, message) {
    this.dispatchEvent(
      new ShowToastEvent({
        title,
        message,
        variant: "error"
      })
    );
  }
}
