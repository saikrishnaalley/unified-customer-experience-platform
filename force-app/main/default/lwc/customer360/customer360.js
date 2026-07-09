import { LightningElement, api, wire } from 'lwc';
import getCustomer360 from '@salesforce/apex/Customer360Controller.getCustomer360';

export default class Customer360 extends LightningElement {
    @api recordId;

    account;
    opportunities;
    orders;
    shipments;
    milestones;
    error;

    @wire(getCustomer360, { accountId: '$recordId' })
    wiredData({ error, data }) {
        if (data) {
            this.account = data.account;
            this.opportunities = data.opportunities;
            this.orders = data.orders;
            this.shipments = data.shipments;
            this.milestones = (data.milestones || []).map((m) => {
                const target = new Date(m.TargetDate);
                const now = new Date();
                const diffMs = target - now;
                const diffHours = diffMs / (1000 * 60 * 60);

                let countdownText;
                let urgencyClass;

                if (diffMs < 0) {
                    const overdueHours = Math.abs(diffHours).toFixed(1);
                    countdownText = `${overdueHours} hr overdue`;
                    urgencyClass = 'slds-text-color_error';
                } else if (diffHours < 4) {
                    countdownText = `${diffHours.toFixed(1)} hr remaining`;
                    urgencyClass = 'slds-text-color_error';
                } else if (diffHours < 24) {
                    countdownText = `${diffHours.toFixed(1)} hr remaining`;
                    urgencyClass = 'slds-text-color_warning';
                } else {
                    const diffDays = (diffHours / 24).toFixed(1);
                    countdownText = `${diffDays} days remaining`;
                    urgencyClass = 'slds-text-color_success';
                }

                return {
                    id: m.Id,
                    caseNumber: m.Case.CaseNumber,
                    subject: m.Case.Subject,
                    milestoneType: m.MilestoneType.Name,
                    countdownText,
                    urgencyClass
                };
            });
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : JSON.stringify(error);
        }
    }
}