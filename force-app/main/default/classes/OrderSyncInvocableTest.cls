@isTest
private class OrderSyncInvocableTest {

    private class MockOrderApiResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"orderId":"TESTORDER1","status":"Shipped","carrier":"FedEx","trackingNumber":"TRK-TEST-777"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testInvocableSync() {
        Account acc = new Account(Name = 'Invocable Test Account');
        insert acc;

        Order testOrder = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = System.today()
        );
        insert testOrder;

        Test.setMock(HttpCalloutMock.class, new MockOrderApiResponse());

        Test.startTest();
        OrderSyncInvocable.syncOrders(new List<Id>{ testOrder.Id });
        Test.stopTest();

        List<Shipment__c> shipments = [SELECT Id FROM Shipment__c WHERE Order__c = :testOrder.Id];
        System.assertEquals(1, shipments.size(), 'Expected the invocable method to create a Shipment record');
    }
}