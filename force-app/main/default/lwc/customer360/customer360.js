import { LightningElement, api, wire } from 'lwc';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import getCustomer360 from '@salesforce/apex/Customer360Controller.getCustomer360';
import { refreshApex } from '@salesforce/apex';

export default class Customer360 extends LightningElement {
    @api recordId;

    account;
    opportunities;
    orders;
    shipments;
    milestones;
    error;
    liveUpdateBanner;

    wiredResult;
    subscription;
    channelName = '/event/Order_Status_Change__e';

    @wire(getCustomer360, { accountId: '$recordId' })
    wiredData(result) {
        this.wiredResult = result;
        const { error, data } = result;
        if (data) {
            this.account = data.account;
            this.opportunities = data.opportunities;
            this.orders = data.orders;
            this.shipments = data.shipments;
            this.milestones = this.processMilestones(data.milestones);
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : JSON.stringify(error);
        }
    }

    processMilestones(rawMilestones) {
        return (rawMilestones || []).map((m) => {
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
    }

    connectedCallback() {
        this.subscribeToChannel();
    }

    disconnectedCallback() {
        this.unsubscribeChannel();
    }

    subscribeToChannel() {
    const messageCallback = (response) => {
        this.liveUpdateBanner = 'Order status updated live — refreshing...';
        refreshApex(this.wiredResult).then(() => {
            setTimeout(() => {
                this.liveUpdateBanner = undefined;
            }, 4000);
        });
    };

    subscribe(this.channelName, -1, messageCallback)
        .then((response) => {
            this.subscription = response;
        })
        .catch((subscribeError) => {
            console.error('Failed to subscribe to Order status updates:', subscribeError);
        });

    onError((error) => {
        console.error('Platform Event subscription error:', error);
    });
}subscribeToChannel() {
    const messageCallback = (response) => {
        this.liveUpdateBanner = 'Order status updated live — refreshing...';
        refreshApex(this.wiredResult).then(() => {
            setTimeout(() => {
                this.liveUpdateBanner = undefined;
            }, 4000);
        });
    };

    subscribe(this.channelName, -1, messageCallback)
        .then((response) => {
            this.subscription = response;
        })
        .catch((subscribeError) => {
            console.error('Failed to subscribe to Order status updates:', subscribeError);
        });

    onError((error) => {
        console.error('Platform Event subscription error:', error);
    });
}

    unsubscribeChannel() {
        if (this.subscription) {
            unsubscribe(this.subscription);
        }
    }
}