public class OrderSyncQueueable implements Queueable, Database.AllowsCallouts {

    public static final Integer MAX_CALLOUTS_PER_TRANSACTION = 100;

    private List<Id> orderIds;

    public OrderSyncQueueable(List<Id> orderIds) {
        this.orderIds = orderIds;
    }

    public void execute(QueueableContext context) {
        List<Id> currentChunk = getChunk(orderIds, 0, MAX_CALLOUTS_PER_TRANSACTION);
        List<Id> remaining = getRemainder(orderIds, MAX_CALLOUTS_PER_TRANSACTION);

        OrderSyncService.syncOrderStatuses(currentChunk);

        if (!remaining.isEmpty()) {
            System.enqueueJob(new OrderSyncQueueable(remaining));
        }
    }

    @TestVisible
    private static List<Id> getChunk(List<Id> ids, Integer startIndex, Integer size) {
        List<Id> chunk = new List<Id>();
        Integer endIndex = Math.min(ids.size(), startIndex + size);
        for (Integer i = startIndex; i < endIndex; i++) {
            chunk.add(ids[i]);
        }
        return chunk;
    }

    @TestVisible
    private static List<Id> getRemainder(List<Id> ids, Integer afterIndex) {
        List<Id> remainder = new List<Id>();
        for (Integer i = afterIndex; i < ids.size(); i++) {
            remainder.add(ids[i]);
        }
        return remainder;
    }
}