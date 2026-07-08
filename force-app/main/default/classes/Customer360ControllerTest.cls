@isTest
private class Customer360ControllerTest {

    @isTest
    static void testGetCustomer360() {
        Account acc = new Account(Name = 'C360 Test Account');
        insert acc;

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

        Test.startTest();
        Customer360Controller.Customer360Data result = Customer360Controller.getCustomer360(acc.Id);
        Test.stopTest();

        System.assertEquals('C360 Test Account', result.account.Name);
        System.assertEquals(1, result.opportunities.size());
        System.assertEquals(1, result.orders.size());
        System.assertEquals(1, result.shipments.size());
    }
}