Ext.namespace("Ext.testia");
/**
 * Ext.testia.ReportForm extension class for Ext.testia.AppForm
 *
 * @class Ext.testia.ReportForm
 * @extend Ext.testia.BaseReportForm
 *
 * Extend basic AppForm by adding copy button, and default handler
 * for that.
 */
Ext.testia.ResultsForm = function(form_div, toolbar_div, config) {
    Ext.testia.ResultsForm.superclass.constructor.call(this,
                                                      form_div,
                                                      toolbar_div, config);
    var combo = this.findField('testobject');

    combo.on('expand', function(c) {
        c.store.filterBy(function(r) {
            return (r.get('cls').search('-tag') < 0);
        });
    });
    combo.store.load();

    GUI.on("projectchanged", this.onProjectChange, this);
    GUI.on("testareachanged", this.onProjectChange, this);
};

Ext.extend(Ext.testia.ResultsForm, Ext.testia.BaseReportForm, {

    onProjectChange: function() {
        var combo = this.findField('testobject');
        combo.reset();
        combo.store.clearFilter(true);
        combo.store.reload();
    },

    generate: function() {
        var params = "test_object_ids=" + this.findField('testobject').getValue();
        Ext.testia.ResultsForm.superclass.generate.call(this, params);
    },

    createForm: function() {
        this.add(new Ext.form.ComboBox({
            name: 'testobject',
            store: new Ext.data.JsonStore({
                url: createUrl('/projects/current/test_objects/'),
                root: '',
                id: 'dbid',
                fields: ['dbid', 'text', 'cls']}),
            valueField: 'dbid',
            displayField: 'text',
            allowBlank: false,
            editable: false,
            forceSelection: true,
            triggerAction: 'all',
            fieldLabel: 'Test object',
            mode: 'local',
            width: 150
        }));
    },

    defaultActionClear: function(e) {
        if (e !== 'projectselect') {
            GUI.un("projectchanged", this.onProjectChange);
            GUI.un("testareachanged", this.onProjectChange);
        }
        return Ext.testia.ResultsForm.superclass.defaultActionClear.call(this, e);
    }

});