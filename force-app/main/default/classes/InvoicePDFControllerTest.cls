@isTest
private class InvoicePDFControllerTest {
  @isTest
  static void testPDFControllerWithLineItems() {
    Account acc = new Account(Name = 'PDF Test Account');
    insert acc;

    Opportunity opp = new Opportunity(
      Name = 'PDF Test Opportunity',
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(14),
      AccountId = acc.Id
    );
    insert opp;

    Invoice__c invoice = new Invoice__c(
      Customer__c = acc.Id,
      Opportunity__c = opp.Id,
      Status__c = 'Draft',
      Total_Amount__c = 1500
    );
    insert invoice;

    insert new Invoice_Line_Item__c(
      Invoice__c = invoice.Id,
      Product_Name__c = 'Consulting',
      Quantity__c = 3,
      Unit_Price__c = 500
    );

    Test.setCurrentPage(Page.InvoicePDF);
    ApexPages.currentPage().getParameters().put('id', invoice.Id);

    Test.startTest();
    InvoicePDFController controller = new InvoicePDFController();
    Test.stopTest();

    System.assertEquals(true, controller.hasInvoice);
    System.assertEquals(invoice.Id, controller.invoice.Id);
    System.assertEquals(1500, controller.invoice.Total_Amount__c);
    System.assertEquals(1, controller.displayLineItems.size());
    System.assertEquals(
      'Consulting',
      controller.displayLineItems[0].productName
    );
    System.assertNotEquals(null, controller.displayLineItems[0].lineTotal);
    System.assertNotEquals(null, controller.formattedGrandTotal);
  }

  @isTest
  static void testPDFControllerWithoutId() {
    Test.setCurrentPage(Page.InvoicePDF);

    Test.startTest();
    InvoicePDFController controller = new InvoicePDFController();
    Test.stopTest();

    System.assertEquals(false, controller.hasInvoice);
    System.assertEquals(0, controller.displayLineItems.size());
  }
}
