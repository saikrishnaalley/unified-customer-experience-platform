@isTest
private class Customer360ControllerTest {

    @isTest
    static void testGetCustomer360() {
        Account acc = new Account(Name = 'C360 Test Account');
        insert acc;

        Contact con = new Contact(
            FirstName = 'C360',
            LastName = 'Tester',
            AccountId = acc.Id
        );
        insert con;

        Opportunity opp = new Opportunity(
            Name = 'C360 Test Opp',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30)
        );
        insert opp;

        Order ord = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = System.today()
        );
        insert ord;

        Shipment__c shipment = new Shipment__c(
            Order__c = ord.Id,
            Status__c = 'Shipped',
            Carrier__c = 'FedEx',
            Tracking_Number__c = 'TRK-123'
        );
        insert shipment;

        Case testCase = new Case(
            AccountId = acc.Id,
            ContactId = con.Id,
            Subject = 'C360 Test Case',
            Status = 'New',
            Origin = 'Web'
        );
        insert testCase;

        Test.startTest();
        Customer360Controller.Customer360Data result = Customer360Controller.getCustomer360(acc.Id);
        Test.stopTest();

        System.assertEquals('C360 Test Account', result.account.Name);
        System.assertEquals(1, result.opportunities.size());
        System.assertEquals(1, result.orders.size());
        System.assertEquals(1, result.shipments.size());
        // Milestones may be 0 if no Entitlement/Process is linked in this test context — that's fine,
        // this just confirms the query itself runs without error
        System.assert(result.milestones != null, 'Milestones list should not be null');
    }
}