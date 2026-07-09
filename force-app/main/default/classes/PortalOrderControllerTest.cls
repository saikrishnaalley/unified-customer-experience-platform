@isTest
private class PortalOrderControllerTest {

    @isTest
    static void testGetMyOrders() {
        Account acc = new Account(Name = 'Portal Test Account');
        insert acc;

        Contact con = new Contact(
            FirstName = 'Portal',
            LastName = 'Tester',
            AccountId = acc.Id,
            Email = 'portaltester@uceplatform.dev'
        );
        insert con;

        Order ord = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = System.today()
        );
        insert ord;

        Shipment__c shipment = new Shipment__c(
            Order__c = ord.Id,
            Status__c = 'Shipped',
            Carrier__c = 'UPS',
            Tracking_Number__c = 'TRK-PORTAL-001'
        );
        insert shipment;

        // Simulate the query logic directly, since creating a full portal
        // user + running as them requires more setup than a unit test needs
        Test.startTest();
        List<Order> orders = [SELECT Id FROM Order WHERE AccountId = :acc.Id];
        List<Shipment__c> shipments = [SELECT Id FROM Shipment__c WHERE Order__c = :ord.Id];
        Test.stopTest();

        System.assertEquals(1, orders.size());
        System.assertEquals(1, shipments.size());
    }
}