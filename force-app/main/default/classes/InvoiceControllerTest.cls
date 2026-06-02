@isTest
private class InvoiceControllerTest {
  @testSetup
  static void setupData() {
    Account acc = new Account(Name = 'Test Account');
    insert acc;

    Opportunity opp = new Opportunity(
      Name = 'Test Opportunity',
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30),
      AccountId = acc.Id
    );
    insert opp;
  }

  @isTest
  static void testGetOpportunities() {
    Test.startTest();
    List<Opportunity> opportunities = InvoiceController.getOpportunities();
    Test.stopTest();

    System.assertNotEquals(
      null,
      opportunities,
      'Opportunities list should not be null'
    );
    System.assert(
      opportunities.size() > 0,
      'At least one opportunity should be returned'
    );
  }

  @isTest
  static void testSaveInvoiceSuccess() {
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

    Invoice__c invoice = new Invoice__c(
      Customer__c = acc.Id,
      Opportunity__c = opp.Id,
      Status__c = 'Draft',
      Total_Amount__c = 1000
    );

    List<Invoice_Line_Item__c> lineItems = new List<Invoice_Line_Item__c>{
      new Invoice_Line_Item__c(
        Product_Name__c = 'Laptop',
        Quantity__c = 2,
        Unit_Price__c = 500
      )
    };

    Test.startTest();
    Id invoiceId = InvoiceController.saveInvoice(invoice, lineItems);
    Test.stopTest();

    System.assertNotEquals(null, invoiceId, 'Invoice Id should be returned');

    Invoice__c savedInvoice = [
      SELECT Id, Customer__c, Opportunity__c, Status__c, Total_Amount__c
      FROM Invoice__c
      WHERE Id = :invoiceId
    ];
    System.assertEquals(acc.Id, savedInvoice.Customer__c);
    System.assertEquals(opp.Id, savedInvoice.Opportunity__c);
    System.assertEquals(1000, savedInvoice.Total_Amount__c);

    List<Invoice_Line_Item__c> savedLineItems = [
      SELECT Id, Invoice__c, Product_Name__c, Quantity__c, Unit_Price__c
      FROM Invoice_Line_Item__c
      WHERE Invoice__c = :invoiceId
    ];
    System.assertEquals(1, savedLineItems.size());
    System.assertEquals('Laptop', savedLineItems[0].Product_Name__c);
  }

  @isTest
  static void testSaveInvoiceMismatchedTotal() {
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

    Invoice__c invoice = new Invoice__c(
      Customer__c = acc.Id,
      Opportunity__c = opp.Id,
      Total_Amount__c = 999
    );

    List<Invoice_Line_Item__c> lineItems = new List<Invoice_Line_Item__c>{
      new Invoice_Line_Item__c(
        Product_Name__c = 'Mouse',
        Quantity__c = 1,
        Unit_Price__c = 25
      )
    };

    Boolean exceptionThrown = false;
    Test.startTest();
    try {
      InvoiceController.saveInvoice(invoice, lineItems);
    } catch (AuraHandledException e) {
      exceptionThrown = true;
    }
    Test.stopTest();

    System.assertEquals(true, exceptionThrown);
  }

  @isTest
  static void testSaveInvoiceValidationFailure() {
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

    Invoice__c invoice = new Invoice__c(
      Customer__c = acc.Id,
      Opportunity__c = opp.Id,
      Total_Amount__c = 100
    );

    Boolean exceptionThrown = false;
    Test.startTest();
    try {
      InvoiceController.saveInvoice(invoice, new List<Invoice_Line_Item__c>());
    } catch (AuraHandledException e) {
      exceptionThrown = true;
    }
    Test.stopTest();

    System.assertEquals(
      true,
      exceptionThrown,
      'Validation should fail without line items'
    );
    System.assertEquals(
      0,
      [SELECT COUNT() FROM Invoice__c],
      'Invoice should roll back when validation fails'
    );
  }
}
