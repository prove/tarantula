Ext.namespace('Ext.testia');

Ext.testia.FormDialog = function(config) {
    config = config || {};

    config.width = config.width || 300;
    config.height = config.height || 300;
    config.center = config.center || {autoScroll: true};
    config.fields = config.fields || [];

    var el = Ext.DomHelper.append(document.body, {tag:'div'});
    Ext.testia.FormDialog.superclass.constructor.call(this, el, config);

    this.fields = config.fields;

    this.handler = config.fn.createDelegate(config.scope);

    // Call provided dialog handler with scope provided in the config.
    this.addButton('Ok', function() {
        this.okPressed();
    }, this);
    this.addButton('Cancel', function() {
        this.closeDialog();
    }, this);

    if (config.disabledButtons) {
        for(var i=0,il=config.disabledButtons.length;i<il;++i) {
            this.buttons[config.disabledButtons[i]].setDisabled(true);
        }
        delete config.disabledButtons;
    }

    var layout = this.getLayout();
    layout.beginUpdate();
    var cp = new Ext.ContentPanel(Ext.id(), {autoCreate: true,
                                             background: true});
    layout.add('center', cp);
    layout.endUpdate();
    this.dForm = new Ext.form.Form({
        labelSeparator: '',
        labelAlign: 'top',
        itemCls: 'dialogForm'
    });

    Ext.each(config.fields, function(i) {
        this.dForm.add(i);
        if (i.store) {
            i.store.load();
        }
    }, this);
    this.dForm.render(Ext.DomHelper.append(cp.el, {tag:'div'}, true));

    this.setTitle(config.title);

    this.center();
    this.show();
};

Ext.extend(Ext.testia.FormDialog, Ext.LayoutDialog, {
    dForm: undefined,
    handler: undefined,
    fields: undefined,

    okPressed: function() {
        this.handler(this.getValues());
        this.closeDialog();
    },
    closeDialog: function() {
        this.destroy(true);
    },
    getValues: function() {
        var ret = {};

        Ext.each(this.fields, function(i) {
            ret[i.name] = i.getValue();
        }, this);

        return ret;
    }
});