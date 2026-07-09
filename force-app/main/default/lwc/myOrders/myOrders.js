import { LightningElement, wire } from 'lwc';
import getMyOrders from '@salesforce/apex/PortalOrderController.getMyOrders';

export default class MyOrders extends LightningElement {
    orders;
    error;

    @wire(getMyOrders)
    wiredOrders({ error, data }) {
        if (data) {
            this.orders = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : JSON.stringify(error);
        }
    }
}