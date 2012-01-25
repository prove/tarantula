// Dialog which contains AppFrom object for agile editing during execution.
Ext.namespace('Ext.testia');

Ext.testia.DesignDialog = function(gui, Content, cb) {
    var config = {};
    config.width = config.width || 850;
    config.height = config.height || 600;
    config.scope = config.scope || this;
    config.center = config.center || {autoScroll: true};

    Ext.DomHelper.useDom = true;
    var el = Ext.DomHelper.append(document.body, {tag:'div'});
    Ext.testia.DesignDialog.superclass.constructor.call(this, el, config);

    var layout = this.getLayout();
    layout.beginUpdate();
    var cp = new Ext.ContentPanel(Ext.id(), {autoCreate: true,
        background: true});
    layout.add('center', cp);
    layout.endUpdate();

    var tbEl = Ext.DomHelper.append(cp.el, {tag:'div'}, true);
    var formEl = Ext.DomHelper.append(cp.el, {tag:'div'}, true);
    this.content = new Content(gui, formEl.id, tbEl.id, true);

    var appForm = this.content.appForm;
    var d = this;
    this.callback = cb || function() {};
    appForm.originalBeforeSave = appForm.beforeSave;
    appForm.beforeSave = appForm.originalBeforeSave.createChain(appForm, function(p) {
        var params = Ext.decode(Ext.urlDecode(p).data);

        if (this.mode == 'new') {
            params.execution_id = d.execution;
            params.case_execution_id = d.caseExecution;
        } else {
            params.update_case_execution = d.caseExecution;
        }
        return Ext.urlEncode({data: Ext.encode(params)});
    });
    appForm.originalAfterSave = appForm.afterSave;
    appForm.afterSave = appForm.originalAfterSave.createChain(appForm, this.callback);

    this.on('hide', function() {
        this.content.appForm.setMode('read');
        this.destroy(true);
    }, this);

    this.setTitle("Edit case");
    this.center();
    this.show();
};

Ext.extend(Ext.testia.DesignDialog, Ext.LayoutDialog, {
    content: undefined,
    caseExecution: undefined,
    callback: undefined,

    load: function(id, case_exec_id, exec_id) {
        if (id) {
            this.content.appForm.defaultActionLoad(id);
            this.caseExecution = case_exec_id;
            this.execution = exec_id;
        }
    }
});