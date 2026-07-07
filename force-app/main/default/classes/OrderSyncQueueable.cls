public class OrderSyncQueueable implements Queueable, Database.AllowsCallouts {

    private List<Id> orderIds;

    public OrderSyncQueueable(List<Id> orderIds) {
        this.orderIds = orderIds;
    }

    public void execute(QueueableContext context) {
        OrderSyncService.syncOrderStatuses(orderIds);
    }
}