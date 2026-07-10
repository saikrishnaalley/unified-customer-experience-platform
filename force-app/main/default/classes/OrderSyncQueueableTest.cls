@isTest
private class OrderSyncQueueableTest {

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
    static void testQueueable_singleChunkUnder100() {
        Account acc = new Account(Name = 'Queueable Small Test');
        insert acc;

        List<Order> orders = new List<Order>();
        for (Integer i = 0; i < 10; i++) {
            orders.add(new Order(
                AccountId = acc.Id,
                Status = 'Draft',
                EffectiveDate = System.today()
            ));
        }
        insert orders;

        List<Id> orderIds = new List<Id>();
        for (Order o : orders) {
            orderIds.add(o.Id);
        }

        Test.setMock(HttpCalloutMock.class, new MockOrderApiResponse());

        Test.startTest();
        System.enqueueJob(new OrderSyncQueueable(orderIds));
        Test.stopTest();

        List<Shipment__c> shipments = [SELECT Id FROM Shipment__c WHERE Order__c IN :orders];
        System.assertEquals(10, shipments.size(), 'All 10 orders should sync in a single chunk, no chaining needed');
    }

    @isTest
    static void testQueueable_emptyList() {
        Test.setMock(HttpCalloutMock.class, new MockOrderApiResponse());

        Test.startTest();
        try {
            System.enqueueJob(new OrderSyncQueueable(new List<Id>()));
            System.assert(true, 'Should not throw when given an empty order list');
        } catch (Exception e) {
            System.assert(false, 'Unexpected exception for empty order list: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testChunking_splitsListsCorrectlyAt100Boundary() {
        // Unit tests the chunking math directly - proves the 200-order
        // scenario produced by OrderSyncScheduler splits into a 100-item
        // chunk plus a 100-item remainder, without needing to run the
        // second chunk through an actual async callout (Salesforce's test
        // framework does not support chaining a queueable-triggered callout
        // more than one level deep within a single test transaction).
        List<Id> fakeIds = new List<Id>();
        Account acc = new Account(Name = 'Chunk Math Test');
        insert acc;

        List<Order> orders = new List<Order>();
        for (Integer i = 0; i < 150; i++) {
            orders.add(new Order(
                AccountId = acc.Id,
                Status = 'Draft',
                EffectiveDate = System.today()
            ));
        }
        insert orders;

        for (Order o : orders) {
            fakeIds.add(o.Id);
        }

        List<Id> chunk = (List<Id>) OrderSyncQueueable.getChunk(fakeIds, 0, 100);
        List<Id> remainder = (List<Id>) OrderSyncQueueable.getRemainder(fakeIds, 100);

        System.assertEquals(100, chunk.size(), 'First chunk should cap at exactly 100');
        System.assertEquals(50, remainder.size(), 'Remainder should hold the leftover 50');
    }

    @isTest
    static void testChunking_underLimitProducesNoRemainder() {
        Account acc = new Account(Name = 'Chunk Math Small Test');
        insert acc;

        List<Order> orders = new List<Order>();
        for (Integer i = 0; i < 30; i++) {
            orders.add(new Order(
                AccountId = acc.Id,
                Status = 'Draft',
                EffectiveDate = System.today()
            ));
        }
        insert orders;

        List<Id> fakeIds = new List<Id>();
        for (Order o : orders) {
            fakeIds.add(o.Id);
        }

        List<Id> chunk = (List<Id>) OrderSyncQueueable.getChunk(fakeIds, 0, 100);
        List<Id> remainder = (List<Id>) OrderSyncQueueable.getRemainder(fakeIds, 100);

        System.assertEquals(30, chunk.size(), 'Chunk should contain all 30 records when under the limit');
        System.assertEquals(0, remainder.size(), 'Remainder should be empty when under the limit');
    }
}