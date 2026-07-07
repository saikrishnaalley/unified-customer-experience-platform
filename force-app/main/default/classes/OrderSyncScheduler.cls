public class OrderSyncScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        List<Order> ordersToSync = [
            SELECT Id
            FROM Order
            WHERE Status != 'Delivered'
            LIMIT 200
        ];

        if (!ordersToSync.isEmpty()) {
            List<Id> orderIds = new List<Id>();
            for (Order o : ordersToSync) {
                orderIds.add(o.Id);
            }
            System.enqueueJob(new OrderSyncQueueable(orderIds));
        }
    }
}