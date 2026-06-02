# PDF Download — Invoice Manager (PDF Generation App)

Salesforce business-use-case solution to create an **Invoice** from an **Opportunity**, add **line items**, save in one transaction, **download a PDF**, and open the new invoice record.

---

## Overview

- **Business goal:** Create customer invoice from Opportunity and export as PDF
- **User entry:** **Invoice Manager** app + **Generate Invoice** quick action on Opportunity
- **UI:** Multi-step LWC `invoiceGenerator` (Step 1: customer/opportunity, Step 2: line items)
- **Backend:** Apex saves invoice + line items with savepoint rollback
- **PDF:** Visualforce `InvoicePDF` opens in a new browser tab
- **Navigation:** After save, user lands on the new **Invoice__c** record

---

## Solution overview

### Data model

- **Invoice__c**
  - Customer (Account)
  - Opportunity
  - Status
  - Total Amount
  - Auto-number Name
- **Invoice_Line_Item__c**
  - Master-detail to Invoice
  - Product Name, Quantity, Unit Price
  - Formula: Line Total

### Key components

- **UI:** `lwc/invoiceGenerator` — 2-step wizard, LDS, line items, grand total
- **Apex:** `InvoiceController` — load opportunities, `saveInvoice` (single transaction)
- **Apex:** `InvoicePDFController` — load invoice and lines for PDF
- **PDF:** `InvoicePDF.page` — Visualforce PDF (`renderAs="pdf"`)
- **Action:** **Generate Invoice** on Opportunity (screen quick action, modal)
- **App:** **Invoice Manager** — Opportunities and Invoices tabs
- **Security:** `Invoice_App_Access` permission set

### End-to-end flow

1. Open Opportunity → click **Generate Invoice**
2. **Step 1:** Confirm opportunity and customer → **Next**
3. **Step 2:** Add line items → review grand total
4. **Save Invoice & Download PDF** → Apex save → PDF tab → navigate to Invoice record

### Technical highlights

- Lightning Data Service (`getRecord`) from quick action
- Imperative Apex for opportunity list from app page
- Single Apex transaction with savepoint
- SLDS UI, validation, error toasts
- Tests: `InvoiceControllerTest`, `InvoicePDFControllerTest`, LWC Jest

---

## Prerequisites

- Salesforce CLI (`sf`) installed
- Dev Hub enabled (for scratch org)
- Node.js 18+ (optional, for LWC unit tests)

---

## Deployment steps (Salesforce CLI)

### Step 1 — Clone the repository

```bash
git clone https://github.com/Akshatha0303/Task-PDF-Download-.git
cd Task-PDF-Download-
```

### Step 2 — Create a scratch org

```bash
sf org create scratch -f config/project-scratch-def.json -a InvoiceApp -s
```

### Step 3 — Deploy source to org

```bash
sf project deploy start
```

### Step 4 — Open the org

```bash
sf org open
```

---

## Recommended approach (no manual credentials)

- After deploy, run: `sf org open`
- CLI logs you into the scratch org automatically
- **Note:** No manual username/password needed for scratch org session

---

## How to use the application

1. **App Launcher** → **Invoice Manager**
2. **Opportunities** tab → open an opportunity (with account)
3. Click **Generate Invoice** (modal opens)
4. **Step 1:** Confirm opportunity and customer → **Next**
5. **Step 2:** Enter product, quantity, unit price → **Add Row** / **Remove** as needed
6. Click **Save Invoice & Download PDF**
7. Allow browser pop-up for PDF
8. Review new **Invoice** record and line items

**Tip:** Enable pop-ups for your Salesforce org URL.

---

## Run tests

**Apex**

```bash
sf apex run test --class-names InvoiceControllerTest,InvoicePDFControllerTest --result-format human --code-coverage --wait 10
```

**LWC**

```bash
npm install
npm run test:unit
```

---

## Project structure

- `force-app/main/default/objects/Invoice__c/`
- `force-app/main/default/objects/Invoice_Line_Item__c/`
- `force-app/main/default/classes/InvoiceController.cls`
- `force-app/main/default/classes/InvoicePDFController.cls`
- `force-app/main/default/pages/InvoicePDF.page`
- `force-app/main/default/lwc/invoiceGenerator/`
- `force-app/main/default/quickActions/Opportunity.Generate_Invoice.quickAction-meta.xml`
- `force-app/main/default/applications/Invoice_Manager.app-meta.xml`
- `force-app/main/default/permissionsets/Invoice_App_Access.permissionset-meta.xml`
- `scripts/apex/createInvoiceTestData.apex`

---

## Repository

- **URL:** https://github.com/Akshatha0303/Task-PDF-Download-
- **Branch:** `main`
- **Browse:** `force-app/main/default/`
  - `lwc/invoiceGenerator/` — UI
  - `classes/` — Apex
  - `objects/` — Invoice and line items
  - `pages/InvoicePDF.page` — PDF
  - `applications/Invoice_Manager.app-meta.xml` — app
