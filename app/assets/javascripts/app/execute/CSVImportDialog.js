Ext.namespace('Ext.testia');

Ext.testia.CSVImportDialog = function(config) {
    config = config || {};

    config.width = config.width || 330;
    config.height = config.height || 130;
    config.scope = config.scope || this;
    config.center = config.center || {autoScroll: true};
    var url = config.url;
    var cb = config.callback;
    delete(config.callback);

    var el = Ext.DomHelper.append(document.body, {tag:'div'});
    Ext.testia.CSVImportDialog.superclass.constructor.call(this, el, config);

    this.callback = cb;
    this.uploadUrl = url;

    this.addButton('Import', function() {
        this.closeDialog('ok');
    }, this);
    this.addButton('Cancel', function() {
        this.closeDialog('cancel');
    }, this);

    var layout = this.getLayout();
    layout.beginUpdate();
    var cp = new Ext.ContentPanel(Ext.id(), {autoCreate: true,
        background: true});
    layout.add('center', cp);
    layout.endUpdate();
    this.dForm = new Ext.form.Form({
        fileUpload: true
    });
    this.dForm.render(Ext.DomHelper.append(cp.el, {tag:'div'}, true));

    Ext.DomHelper.append(this.dForm.el.child('.x-form-ct'),{
        tag: 'input',
        type: 'file',
        size: 0,
        name: 'file',
        cls: 'importDialogForm'
    });
    this.setTitle('Import results from CSV file');
    this.center();
    this.show();
};

Ext.extend(Ext.testia.CSVImportDialog, Ext.LayoutDialog, {
    dForm: undefined,
    uploadUrl: undefined,
    callback: undefined,

    closeDialog: function(b) {
        if (b === 'ok') {
            this.upload({
                callback: function() {
                    if (this.callback) {
                        this.callback();
                    }
                    this.destroy(true);
                },
                scope: this
            });
        } else {
            this.destroy(true);
        }
    },

    upload: function(options) {
        var cb = function() {
            if (options.callback) {
                options.callback.call(options.scope || this);
            }
        };
        this.dForm.submit({
            url: this.uploadUrl,
            params: '_method=put',
            enctype:'multipart/form-data',
            success: cb,
            failure: cb
        });
    }
});