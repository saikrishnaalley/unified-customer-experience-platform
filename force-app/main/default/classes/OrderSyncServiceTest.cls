@isTest
private class OrderSyncServiceTest {

    // Mock class that simulates the external API's response
    private class MockOrderApiResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"orderId":"TESTORDER1","status":"Shipped","carrier":"FedEx","trackingNumber":"TRK-TEST-123"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testSyncOrderStatus_success() {
        // Create test data
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Order testOrder = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = System.today()
        );
        insert testOrder;

        // Set the mock callout
        Test.setMock(HttpCalloutMock.class, new MockOrderApiResponse());

        Test.startTest();
        OrderSyncService.syncOrderStatus(testOrder.Id);
        Test.stopTest();

        // Verify a Shipment__c record was created with the mocked data
        List<Shipment__c> shipments = [
            SELECT Id, Status__c, Carrier__c, Tracking_Number__c
            FROM Shipment__c
            WHERE Order__c = :testOrder.Id
        ];
        System.assertEquals(1, shipments.size(), 'Expected one Shipment record to be created');
        System.assertEquals('Shipped', shipments[0].Status__c);
        System.assertEquals('FedEx', shipments[0].Carrier__c);
    }

     @isTest
    static void testSyncOrderStatus_bulk() {
        Account acc = new Account(Name = 'Bulk Test Account');
        insert acc;

        List<Order> orders = new List<Order>();
        for (Integer i = 0; i < 5; i++) {
            orders.add(new Order(
                AccountId = acc.Id,
                Status = 'Draft',
                EffectiveDate = System.today()
            ));
        }
        insert orders;

        Test.setMock(HttpCalloutMock.class, new MockOrderApiResponse());

        List<Id> orderIds = new List<Id>();
        for (Order o : orders) {
            orderIds.add(o.Id);
        }

        Test.startTest();
        OrderSyncService.syncOrderStatuses(orderIds);
        Test.stopTest();

        List<Shipment__c> shipments = [SELECT Id FROM Shipment__c WHERE Order__c IN :orders];
        System.assertEquals(5, shipments.size(), 'Expected a Shipment record for each order');
    }
}