Ext.namespace('Ext.testia');

Ext.testia.ComboDialog = function(config) {
    config = config || {};

    config.width = config.width || 300;
    config.height = config.height || 300;
    config.scope = config.scope || this;
    config.center = config.center || {autoScroll: true};

    var el = Ext.DomHelper.append(document.body, {tag:'div'});
    Ext.testia.ComboDialog.superclass.constructor.call(this, el, config);

    this.handler = config.fn.createDelegate(config.scope);

    // Call provided dialog handler with scope provided in the config.
    this.addButton('Ok', function() {
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
    var cForm = new Ext.form.Form({
        labelSeparator: '',
        labelAlign: 'top',
        itemCls: 'dialogForm'
    });

    this.comboBox = config.combo || new Ext.form.ComboBox({
        store: config.store,
        fieldLabel: config.msg,
        mode: 'local',
        width: 180,
        displayField: config.displayField,
        valueField: config.valueField,
        typeAhead:true,
        triggerAction: 'all',
        emptyText:'',
        selectOnFocus: true,
        forceSelection:true
    });
    cForm.add(this.comboBox);
    cForm.render(Ext.DomHelper.append(cp.el, {tag:'div'}, true));

    this.setTitle(config.title);

    this.center();

    this.comboBox.store.each(function(i) {
        if (i.get('selected')) {
            this.comboBox.setValue(i.get(this.comboBox.valueField));
            return false;
        }
    }, this);
    this.show();
};
Ext.extend(Ext.testia.ComboDialog, Ext.LayoutDialog, {
    comboBox: undefined,
    handler: undefined,

    getValue: function() {
        return this.comboBox.getValue();
    },

    closeDialog: function(button) {
        this.handler(button, this.getValue());
        this.destroy(true);
    }
});


Ext.testia.ViewDialog = function(config) {
    config = config || {};

    config.width = config.width || 600;
    config.height = config.height || 400;
    config.center = config.center || {autoScroll: true};
    config.content = config.content || '';
    config.collapsible = false;

    var el = Ext.DomHelper.append(document.body, {tag:'div'});
    Ext.testia.ViewDialog.superclass.constructor.call(this, el, config);

    // Call provided dialog handler with scope provided in the config.
    this.addButton('Close', function() {
        this.closeDialog();
    }, this);

    var layout = this.getLayout();
    layout.beginUpdate();
    var cp = new Ext.ContentPanel(Ext.id(), {autoCreate: true,
        background: true});
    layout.add('center', cp);
    layout.endUpdate();

    cp.setContent(config.content);

    this.setTitle("Change history");

    this.center();

    this.show();
};

Ext.extend(Ext.testia.ViewDialog, Ext.LayoutDialog, {
    closeDialog: function() {
        this.destroy(true);
    }
});

/**
 * Ext.testia.CopyCasesDialog extends Ext.testia.FormDialog
 * @class Ext.testia.CopyCasesDialog
 * @extend Ext.testia.FormDialog
 *
 * Provide UI for selecting target project and test area for copy
 * cases operation.
 *
 * @param copy_params Contains parameters for copyItems operation
 * ie. selected cases etc.
 */
Ext.testia.CopyCasesDialog = function(params) {
    Ext.testia.CopyCasesDialog.superclass.constructor.call(this, {
        title:"Copy Case" + ((params.value.length > 1) ?'s':''),
        fields: [
            new Ext.form.ComboBox({
                fieldLabel: 'Project',
                store: GUI.projectsStore,
                displayField: 'text',
                valueField: 'dbid',
                name: 'project_id',
                mode: 'local',
                typeAhead:true,
                triggerAction: 'all',
                emptyText:'',
                selectOnFocus: true,
                forceSelection:true
            }),
            new Ext.form.ComboBox({
                fieldLabel: 'Testarea',
                name: 'test_area_id',
                store: new Ext.data.JsonStore({
                    url: createUrl('/projects/current/test_areas'),
                    root: 'data',
                    id: 'dbid',
                    fields: ['dbid', 'text', 'selected', 'forced']
                }),
                displayField: 'text',
                valueField: 'dbid',
                mode: 'local',
                typeAhead:true,
                triggerAction: 'all',
                emptyText:'',
                selectOnFocus: true,
                forceSelection:true,
                disabled: true
            })
        ],
        fn: function(values) {
            var p = {};
            p[params.name] = params.value.join(',');
            p.test_area_ids = values.test_area_id;
            Ext.Ajax.request({
                url: createUrl('/projects/' + values.project_id + '/cases'),
                method: 'post',
                params: p,
                scope: this,
                success: function() {
                    Ext.Msg.alert('Success', 'Case copied.');
                    GUI.case_list.reload();
                }
            });
        },
        disabledButtons: [0],
        scope: this
    });
    this.fields[0].on('select', function(cb, r, i) {
        // Enable OK button and test area selection only when project
        // is selected.
        if (!Ext.isEmpty(this.fields[0].getValue())) {
            this.buttons[0].setDisabled(false);
            this.fields[1].setDisabled(false);
        } else {
            this.buttons[0].setDisabled(false);
            this.fields[1].setDisabled(false);
        }
        this.fields[1].store.proxy.conn.url = createUrl('/projects/'+r.get('dbid')+'/test_areas');
        this.fields[1].store.load();
        this.fields[1].reset();

    }, this);
};
Ext.extend(Ext.testia.CopyCasesDialog, Ext.testia.FormDialog);

/**
 * Ext.testia.CaseForm extension class for Ext.testia.AppForm
 *
 * @class Ext.testia.CaseForm
 * @extend Ext.testia.AppForm
 *
 * Extend basic AppForm by adding copy button, and default handler
 * for that.
 */
Ext.testia.CaseForm = function(form_div, toolbar_div, config) {
    config = config || {};

    if (config.default_buttons) {
        delete(config.default_buttons);
    }

    Ext.testia.CaseForm.superclass.constructor.call(this,
                                                    form_div,

                                                       toolbar_div, config);

    this.addToolbarButton({ config: {text: 'Copy', cls:'tarantula-btn-copy'}, enableInModes: ['read']},
                          this.defaultButtonCopy, this);
    this.extToolbar.addFill();
    this.addToolbarButton({ config: {text: 'View history', cls:'tarantula-btn-view'},
                           enableInModes: ['read', 'edit']},
                          this.showHistory, this);
};

Ext.extend(Ext.testia.CaseForm, Ext.testia.AppForm, {
    // set when copy is made.
    defaultButtonCopy: function() {
        new Ext.testia.CopyCasesDialog({name: 'case_ids', value: [this.id]});
    },

    showHistory: function() {
        Ext.Ajax.request({
            url: createUrl('/cases/'+this.id+'/change_history'),
            method: 'get',
            scope: this,
            success: function(r) {
                var data = Ext.decode(r.responseText);
                var html = "<table class=\"history\"><thead>" +
                    "<tr><th class=\"date\">Date</th><th class=\"user\">Modified by</th><th class=\"comment\">Comment</th></tr></thead><tbody>";
                Ext.each(data, function(i,c) {
                    html = [html,"<tr class=\"", ((c%2 == 0) ? "even" : "odd"),
                            "\"><td class=\"date\">",i.time,"</td><td class=\"user\">",
                            i.user,"</td><td class=\"comment\">",i.comment,
                            "</td></tr>"].join('');
                }, this);
                html += "</tbody></table>";
                var d = new Ext.testia.ViewDialog({content: html});
            }
        });
    }


});