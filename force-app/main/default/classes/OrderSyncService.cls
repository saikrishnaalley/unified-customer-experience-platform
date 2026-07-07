public with sharing class OrderSyncService {

    public static void syncOrderStatus(Id orderId) {
        syncOrderStatuses(new List<Id>{ orderId });
    }

    public static void syncOrderStatuses(List<Id> orderIds) {
        Map<Id, Order> orders = new Map<Id, Order>(
            [SELECT Id, OrderNumber FROM Order WHERE Id IN :orderIds]
        );

        List<Shipment__c> shipmentsToUpsert = new List<Shipment__c>();
        List<Order_Status_Change__e> eventsToPublish = new List<Order_Status_Change__e>();

        for (Id orderId : orderIds) {
            Order ord = orders.get(orderId);
            if (ord == null) {
                continue;
            }

            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Mock_Order_API/orders/' + ord.OrderNumber);
            req.setMethod('GET');
            req.setTimeout(10000);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                Shipment__c shipment = new Shipment__c();
                shipment.Order__c = orderId;
                shipment.External_Order_Id__c = (String) result.get('orderId');
                shipment.Carrier__c = (String) result.get('carrier');
                shipment.Tracking_Number__c = (String) result.get('trackingNumber');
                shipment.Status__c = (String) result.get('status');
                shipment.Last_Synced__c = System.now();
                shipmentsToUpsert.add(shipment);

                Order_Status_Change__e statusEvent = new Order_Status_Change__e();
                statusEvent.Order_Id__c = orderId;
                statusEvent.New_Status__c = (String) result.get('status');
                statusEvent.Changed_Date__c = System.now();
                eventsToPublish.add(statusEvent);
            } else {
                System.debug('Order sync failed for ' + orderId + ' with status: ' + res.getStatusCode());
            }
        }

        if (!shipmentsToUpsert.isEmpty()) {
            upsert shipmentsToUpsert;
        }
        if (!eventsToPublish.isEmpty()) {
            EventBus.publish(eventsToPublish);
        }
    }
}