public with sharing class PortalOrderController {

    public class OrderWithShipment {
        @AuraEnabled public Order ord;
        @AuraEnabled public Shipment__c shipment;
    }

    @AuraEnabled(cacheable=true)
    public static List<OrderWithShipment> getMyOrders() {
        Id currentContactId = [
            SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1
        ].ContactId;

        if (currentContactId == null) {
            return new List<OrderWithShipment>();
        }

        Id accountId = [
            SELECT AccountId FROM Contact WHERE Id = :currentContactId LIMIT 1
        ].AccountId;

        List<Order> orders = [
            SELECT Id, OrderNumber, Status, TotalAmount, EffectiveDate
            FROM Order
            WHERE AccountId = :accountId
            ORDER BY EffectiveDate DESC
            LIMIT 20
        ];

        List<Id> orderIds = new List<Id>();
        for (Order o : orders) {
            orderIds.add(o.Id);
        }

        Map<Id, Shipment__c> shipmentsByOrder = new Map<Id, Shipment__c>();
        List<Shipment__c> shipmentList = [
            SELECT Id, Order__c, Status__c, Carrier__c, Tracking_Number__c, Last_Synced__c
            FROM Shipment__c
            WHERE Order__c IN :orderIds
            ORDER BY Last_Synced__c DESC
        ];

        for (Shipment__c s : shipmentList) {
            if (!shipmentsByOrder.containsKey(s.Order__c)) {
                shipmentsByOrder.put(s.Order__c, s);
            }
        }

        List<OrderWithShipment> results = new List<OrderWithShipment>();
        for (Order o : orders) {
            OrderWithShipment ows = new OrderWithShipment();
            ows.ord = o;
            ows.shipment = shipmentsByOrder.get(o.Id);
            results.add(ows);
        }

        return results;
    }
}