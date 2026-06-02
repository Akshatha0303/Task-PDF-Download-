public with sharing class InvoicePDFController {
  public Invoice__c invoice { get; private set; }
  public List<LineItemRow> displayLineItems { get; private set; }
  public Boolean hasInvoice { get; private set; }
  public String formattedGrandTotal { get; private set; }

  // Loads invoice and line items from URL id param; builds formatted rows for PDF table.
  public InvoicePDFController() {
    displayLineItems = new List<LineItemRow>();
    hasInvoice = false;

    String invoiceIdParam = ApexPages.currentPage().getParameters().get('id');
    if (String.isBlank(invoiceIdParam)) {
      return;
    }

    Id invoiceId;
    try {
      invoiceId = Id.valueOf(invoiceIdParam);
    } catch (Exception e) {
      return;
    }

    List<Invoice__c> invoices = [
      SELECT
        Id,
        Name,
        Status__c,
        Total_Amount__c,
        Customer__r.Name,
        Opportunity__r.Name,
        (
          SELECT Product_Name__c, Quantity__c, Unit_Price__c, Line_Total__c
          FROM Invoice_Line_Items__r
          ORDER BY Name ASC
        )
      FROM Invoice__c
      WHERE Id = :invoiceId
      LIMIT 1
    ];

    if (invoices.isEmpty()) {
      return;
    }

    invoice = invoices[0];
    formattedGrandTotal = formatCurrency(invoice.Total_Amount__c);

    for (Invoice_Line_Item__c item : invoice.Invoice_Line_Items__r) {
      Decimal lineTotal = item.Line_Total__c;
      if (
        lineTotal == null &&
        item.Quantity__c != null &&
        item.Unit_Price__c != null
      ) {
        lineTotal = item.Quantity__c * item.Unit_Price__c;
      }

      displayLineItems.add(
        new LineItemRow(
          item.Product_Name__c,
          formatInteger(item.Quantity__c),
          formatCurrency(item.Unit_Price__c),
          formatCurrency(lineTotal)
        )
      );
    }

    hasInvoice = true;
  }

  // Formats currency for PDF display (two decimal places).
  private static String formatCurrency(Decimal amount) {
    if (amount == null) {
      return '0.00';
    }
    return amount.setScale(2).format();
  }

  // Formats quantity as whole number string for PDF table cells.
  private static String formatInteger(Decimal value) {
    if (value == null) {
      return '0';
    }
    return String.valueOf(value.intValue());
  }

  // Wrapper holding pre-formatted line item values for Visualforce PDF rendering.
  public class LineItemRow {
    public String productName { get; private set; }
    public String quantity { get; private set; }
    public String unitPrice { get; private set; }
    public String lineTotal { get; private set; }

    // Stores display strings for one PDF table row.
    public LineItemRow(
      String productName,
      String quantity,
      String unitPrice,
      String lineTotal
    ) {
      this.productName = productName;
      this.quantity = quantity;
      this.unitPrice = unitPrice;
      this.lineTotal = lineTotal;
    }
  }
}
