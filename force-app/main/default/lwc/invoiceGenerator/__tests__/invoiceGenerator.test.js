import { createElement } from "lwc";
import InvoiceGenerator from "c/invoiceGenerator";
import getOpportunities from "@salesforce/apex/InvoiceController.getOpportunities";

jest.mock(
  "@salesforce/apex/InvoiceController.getOpportunities",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/InvoiceController.saveInvoice",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

describe("c-invoice-generator", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  async function flushPromises() {
    return Promise.resolve();
  }

  it("renders step 1 and loads opportunities", async () => {
    getOpportunities.mockResolvedValue([
      {
        Id: "006000000000001AAA",
        Name: "Opp 1",
        AccountId: "001000000000001AAA",
        Account: { Name: "Acme" }
      }
    ]);

    const element = createElement("c-invoice-generator", {
      is: InvoiceGenerator
    });
    document.body.appendChild(element);

    await flushPromises();

    const card = element.shadowRoot.querySelector("lightning-card");
    expect(card).not.toBeNull();
    expect(getOpportunities).toHaveBeenCalled();
  });

  it("shows opportunity combobox on app page context", async () => {
    getOpportunities.mockResolvedValue([]);

    const element = createElement("c-invoice-generator", {
      is: InvoiceGenerator
    });
    document.body.appendChild(element);

    await flushPromises();

    const combobox = element.shadowRoot.querySelector("lightning-combobox");
    expect(combobox).not.toBeNull();
  });

  it("hides opportunity combobox when launched from record page", async () => {
    getOpportunities.mockResolvedValue([]);

    const element = createElement("c-invoice-generator", {
      is: InvoiceGenerator
    });
    element.recordId = "006000000000001AAA";
    document.body.appendChild(element);

    await flushPromises();

    const combobox = element.shadowRoot.querySelector("lightning-combobox");
    expect(combobox).toBeNull();
  });
});
