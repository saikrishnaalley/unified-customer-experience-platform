@isTest
private class OrderSyncSchedulerTest {

    private class MockOrderApiResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"orderId":"TESTORDER1","status":"Shipped","carrier":"FedEx","trackingNumber":"TRK-TEST-999"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testScheduledSyncLogic() {
        Account acc = new Account(Name = 'Scheduler Test Account');
        insert acc;

        Order testOrder = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = System.today()
        );
        insert testOrder;

        Test.setMock(HttpCalloutMock.class, new MockOrderApiResponse());

        Test.startTest();
        // Call execute() directly instead of via System.schedule() —
        // this tests the real sync logic without hitting the test-only
        // restriction that blocks callouts from a truly scheduled job.
        new OrderSyncScheduler().execute(null);
        Test.stopTest();

        List<Shipment__c> shipments = [SELECT Id FROM Shipment__c WHERE Order__c = :testOrder.Id];
        System.assertEquals(1, shipments.size(), 'Expected the sync logic to create a Shipment record');
    }

    @isTest
    static void testJobCanBeScheduled() {
        Test.startTest();
        String cronExp = '0 0 * * * ?';
        String uniqueJobName = 'Order Sync Job Test ' + String.valueOf(Datetime.now().getTime());
        String jobId = System.schedule(uniqueJobName, cronExp, new OrderSyncScheduler());
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(cronExp, ct.CronExpression, 'Expected the job to be scheduled with the correct cron expression');
    }      
}