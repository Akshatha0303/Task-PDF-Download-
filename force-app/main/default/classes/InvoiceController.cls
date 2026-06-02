public with sharing class InvoiceController {
  // Returns recent opportunities with account for Step 1 combobox (app page context).
  @AuraEnabled(cacheable=true)
  public static List<Opportunity> getOpportunities() {
    return [
      SELECT Id, Name, AccountId, Account.Name, StageName, Amount
      FROM Opportunity
      WHERE AccountId != NULL
      ORDER BY CreatedDate DESC
      LIMIT 50
    ];
  }

  // Inserts invoice header and line items in one transaction; rolls back on any failure.
  @AuraEnabled
  public static Id saveInvoice(
    Invoice__c invoice,
    List<Invoice_Line_Item__c> lineItems
  ) {
    validateSaveRequest(invoice, lineItems);

    Savepoint sp = Database.setSavepoint();
    try {
      insert invoice;

      for (Invoice_Line_Item__c lineItem : lineItems) {
        lineItem.Invoice__c = invoice.Id;
      }
      insert lineItems;

      return invoice.Id;
    } catch (Exception e) {
      Database.rollback(sp);
      throw new AuraHandledException(e.getMessage());
    }
  }

  // Validates required fields, line items, and aligns Total_Amount__c with line totals.
  private static void validateSaveRequest(
    Invoice__c invoice,
    List<Invoice_Line_Item__c> lineItems
  ) {
    if (invoice == null) {
      throw new AuraHandledException('Invoice record is required.');
    }
    if (invoice.Customer__c == null) {
      throw new AuraHandledException('Customer is required.');
    }
    if (invoice.Opportunity__c == null) {
      throw new AuraHandledException('Opportunity is required.');
    }
    if (lineItems == null || lineItems.isEmpty()) {
      throw new AuraHandledException('At least one line item is required.');
    }

    Decimal calculatedTotal = 0;
    for (Invoice_Line_Item__c lineItem : lineItems) {
      if (String.isBlank(lineItem.Product_Name__c)) {
        throw new AuraHandledException(
          'Product name is required on all line items.'
        );
      }
      if (lineItem.Quantity__c == null || lineItem.Quantity__c < 1) {
        throw new AuraHandledException(
          'Quantity must be at least 1 on all line items.'
        );
      }
      if (lineItem.Unit_Price__c == null || lineItem.Unit_Price__c < 0) {
        throw new AuraHandledException(
          'Unit price must be zero or greater on all line items.'
        );
      }
      calculatedTotal += lineItem.Quantity__c * lineItem.Unit_Price__c;
    }

    if (
      invoice.Total_Amount__c != null &&
      invoice.Total_Amount__c != calculatedTotal
    ) {
      throw new AuraHandledException(
        'Total amount does not match line item totals.'
      );
    }

    invoice.Total_Amount__c = calculatedTotal;
    if (String.isBlank(invoice.Status__c)) {
      invoice.Status__c = 'Draft';
    }
  }
}
