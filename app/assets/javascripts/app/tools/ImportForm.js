Ext.namespace('Ext.testia');

/**
 * Ext.testia.ImportForm extension class for Ext.testia.AppForm
 *
 * @class Ext.testia.ImportForm
 * @extend Ext.testia.AppForm
 *
 * Extend basic AppForm to specialize it for the import tools.
 */
Ext.testia.ImportForm = function(form_div, toolbar_div, config) {
    config = config || {};
    var url = config.url;
    delete(config.url);
    config.default_buttons = false;
    config.fileUpload = true;

    Ext.testia.ImportForm.superclass.constructor.call(
        this, form_div, toolbar_div, config);
    this.url = url;

    this.addToolbarButton( {config: {text: 'Import', cls:'tarantula-btn-new'},
                            enableInModes: ['new', 'empty','edit','read']},
                           this.defaultButtonNew, this);

};

Ext.extend(Ext.testia.ImportForm, Ext.testia.AppForm, {
    url: undefined, // import tools action url

    importAction: function() {
        this.submit({
            url: this.url,
            method: 'post',
            enctype: 'multipart/form-data',
            scope: this,
            success: function(f,r) {
                var el = Ext.get('import-log');
                if (!el) {
                    el = Ext.DomHelper.insertAfter(this.el, {
                        tag:'div',
                        id:'import-log'
                    }, true);
                }
                el.dom.innerHTML = r.response.responseText;
                if (this.afterSave) {
                    this.afterSave();
                }
            }
        });
    },

    // Don't use AppForm's disable/enable stuff
    disable: function() {},
    enable: function() {}
});