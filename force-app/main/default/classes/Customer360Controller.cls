public with sharing class Customer360Controller {

    public class Customer360Data {
        @AuraEnabled public Account account;
        @AuraEnabled public List<Opportunity> opportunities;
        @AuraEnabled public List<Order> orders;
        @AuraEnabled public List<Shipment__c> shipments;
        @AuraEnabled public List<CaseMilestone> milestones;
    }

    @AuraEnabled(cacheable=true)
    public static Customer360Data getCustomer360(Id accountId) {
        Customer360Data data = new Customer360Data();

        data.account = [
            SELECT Id, Name, Industry, Type, Phone
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        data.opportunities = [
            SELECT Id, Name, StageName, Amount, CloseDate
            FROM Opportunity
            WHERE AccountId = :accountId
            ORDER BY CloseDate DESC
            LIMIT 10
        ];

        data.orders = [
            SELECT Id, OrderNumber, Status, TotalAmount, EffectiveDate
            FROM Order
            WHERE AccountId = :accountId
            ORDER BY EffectiveDate DESC
            LIMIT 10
        ];

        data.shipments = [
            SELECT Id, Order__r.OrderNumber, Status__c, Carrier__c, Tracking_Number__c, Last_Synced__c
            FROM Shipment__c
            WHERE Order__r.AccountId = :accountId
            ORDER BY Last_Synced__c DESC
            LIMIT 10
        ];

        data.milestones = [
            SELECT Id, CaseId, Case.CaseNumber, Case.Subject, MilestoneTypeId, MilestoneType.Name,
                   TargetDate, IsCompleted, CompletionDate
            FROM CaseMilestone
            WHERE Case.AccountId = :accountId AND IsCompleted = false
            ORDER BY TargetDate ASC
            LIMIT 10
        ];

        return data;
    }
}