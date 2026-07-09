@isTest(SeeAllData=true)
private class PortalAccessDiagnosticTest {

    @isTest
    static void testPortalUserSeesShipments() {
        User portalUser = [SELECT Id FROM User WHERE Username = 'acme.contact@uceplatform.dev' LIMIT 1];

        System.runAs(portalUser) {
            List<PortalOrderController.OrderWithShipment> results = PortalOrderController.getMyOrders();
            System.debug('RESULT COUNT: ' + results.size());
            for (PortalOrderController.OrderWithShipment r : results) {
                System.debug('Order: ' + r.ord.OrderNumber + ' | Shipment: ' + (r.shipment != null ? r.shipment.Status__c : 'NULL'));
            }
        }
    }
}