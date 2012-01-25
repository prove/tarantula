Ext.namespace('Ext.testia');

Ext.testia.CheckboxList = function(config) {
    Ext.testia.CheckboxList.superclass.constructor.call(this, config);
    this.displayField = config.displayField || config.valueField || 'name';
    this.valueField = config.valueField || config.displayField || 'value';
    this.checked = config.checked || false;
    this.store = config.store;
    this.disabled = (config.disabled !== undefined) ? config.disabled : false;

    this.store.on('load', function() {
        this.onStoreChange();
    }, this);
};

Ext.extend(Ext.testia.CheckboxList, Ext.form.Field, {
    disabled: undefined,
    store: undefined,
    displayField: undefined, // labels for checkboxes
    valueField: undefined, // name attributes for checkboxes
    labelRenderer: undefined, // optional function for trimming displayField values
    checked: undefined, // whether all should be checked by default or not

    reset: function() { // set all checkboxes to un checked.
        this.uncheckAll();
    },

    disable: function() {
        Ext.testia.CheckboxList.superclass.disable.call(this);
        var inputs = Ext.DomQuery.select("input", this.el.dom);
        Ext.each(inputs, function(i) {
            i.disabled = true;
        });
    },

    enable: function() {
        Ext.testia.CheckboxList.superclass.enable.call(this);
        var inputs = Ext.DomQuery.select("input", this.el.dom);
        Ext.each(inputs, function(i) {
            i.disabled = false;
        });
    },

    onStoreChange: function() {
        var inputs = Ext.DomQuery.select("input", this.el.dom);
        Ext.each(inputs, function(i) {
            Ext.fly(i.parentNode).remove();
        });
        this.store.each(function(i) {
            var df = i.get(this.displayField);
            var vf = i.get(this.valueField);
            var el = Ext.DomHelper.append(this.el, {tag:'div', children: [
                {tag:'input', name:vf, type:'checkbox', checked:this.checked},
                {tag:'span', html:df}
            ]}, true);
            el.child('input').dom.disabled = this.disabled;
        }, this);
    },

    getValue: function() {
        var inputs = Ext.DomQuery.select("input", this.el.dom);
        var ret = [];
        Ext.each(inputs, function(i) {
            if (i.checked) {
                ret.push(i.getAttribute('name'));
            }
        });
        return ret;
    },

    setValue: function(v) {
        var a = [];
        var inputs = {};
        var values;
        a = Ext.DomQuery.select("input", this.el.dom);
        Ext.each(a, function(i) {
            inputs[i.getAttribute('name')] = i;
            i.checked = false;
        });
        if (typeof v == 'string') {
            values = v.split(',');
        } else if ( (typeof v == 'boolean') && (v === true)) {
            values = [];
            for (var i in inputs) {
                values.push(i);
            }
        } else {
            values = v;
        }

        Ext.each(values, function(i) {
            if (inputs[i]) {
                inputs[i].checked = true;
            }
        });

    },

    checkAll: function() {
        var inputs = Ext.DomQuery.select("input", this.el.dom);
        Ext.each(inputs, function(i) {
            i.checked = true;
        });
    },

    uncheckAll: function() {
        var inputs = Ext.DomQuery.select("input", this.el.dom);
        Ext.each(inputs, function(i) {
            i.checked = false;
        });
    },

    render: function(el) {
        this.el = Ext.get(el);
        this.store.load();
    }
});