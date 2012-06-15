Ext.namespace("Ext.testia");
/**
 * Ext.testia.ReportForm extension class for Ext.testia.AppForm
 *
 * @class Ext.testia.StatusForm
 * @extend Ext.testia.ReportForm
 *
 * Extend basic AppForm by adding copy button, and default handler
 * for that.
 */
Ext.testia.CoverageForm = function(form_div, toolbar_div, config) {
    Ext.testia.CoverageForm.superclass.constructor.call(this,
        form_div, toolbar_div, config);
};

Ext.extend(Ext.testia.CoverageForm, Ext.testia.ReportForm, {

    createForm: function() {
        var cblist = new Ext.testia.CheckboxList({
            store: new Ext.data.JsonStore({
                url: createUrl('/projects/current/priorities'),
                root: 'data',
                fields: ['name', 'value']
            }),
            displayField: 'name',
            valueField: 'value',
            name: 'priorities',
            fieldLabel: 'Priorities',
            checked: true,
            disabled: false
        });
        this.fieldset({}, cblist);
        this.fieldset({id:'item_selection',
                       legend:'Select Test Objects'});

        this.registerField(cblist, 'priorities');
    },

    generate: function() {
        var items = [];
        Ext.each(this.itemList.selectedItems,
                 function(i) {
                     items.push(i.dbid);
                 }, this);
        var priors = this.findField('priorities').getValue();
        var params = "test_object_ids=" + items.join(',') + "&piorities=" + priors.join(',');

        Ext.testia.CoverageForm.superclass.generate.call(this, params);
    }

});