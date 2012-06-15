Ext.namespace('Ext.testia');

Ext.testia.RequestWatcher = function() {

    this.addEvents({
        "complete": true
    });

    this.connections = [];
    this.stopped = false;
    this.done = false;


    Ext.Ajax.on('beforerequest', this.ajaxListener, this);
};

Ext.extend(Ext.testia.RequestWatcher, Ext.util.Observable, {
    connections: undefined,
    stopped: undefined,
    done: undefined,


    onComplete: function(c) {
        this.connections.remove(c);
        if ((this.connections.length === 0) && this.stopped && !this.done) {
            this.fireEvent('complete');
            this.done = true;
            c.un('requestcomplete', this.onComplete, this);
        }
    },

    ajaxListener: function(c) {
        if (this.stopped) {
            return;
        }
        this.connections.push(c);
        c.on('requestcomplete', this.onComplete, this);
    },

    stop: function() {
        Ext.Ajax.un('beforerequest', this.ajaxListener, this);
        this.stopped = true;
    }
});
