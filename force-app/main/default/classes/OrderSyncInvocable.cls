public class OrderSyncInvocable {

    @InvocableMethod(label='Sync Order Status' description='Calls the mock order API and updates the Shipment record for this Order.')
    public static void syncOrders(List<Id> orderIds) {
        OrderSyncService.syncOrderStatuses(orderIds);
    }
}