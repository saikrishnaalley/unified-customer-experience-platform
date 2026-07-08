import { LightningElement, api, wire } from 'lwc';
import getCustomer360 from '@salesforce/apex/Customer360Controller.getCustomer360';

export default class Customer360 extends LightningElement {
    @api recordId; // Auto-populated by Salesforce when placed on any record page

    account;
    opportunities;
    orders;
    shipments;
    error;

    @wire(getCustomer360, { accountId: '$recordId' })
    wiredData({ error, data }) {
        if (data) {
            this.account = data.account;
            this.opportunities = data.opportunities;
            this.orders = data.orders;
            this.shipments = data.shipments;
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : JSON.stringify(error);
        }
    }
}