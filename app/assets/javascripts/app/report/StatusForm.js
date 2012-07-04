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
Ext.testia.StatusForm = function(form_div, toolbar_div, config) {
    Ext.testia.StatusForm.superclass.constructor.call(this,
        form_div, toolbar_div, config);
};

Ext.extend(Ext.testia.StatusForm, Ext.testia.ReportForm, {

    createForm: function() {
        this.fieldset({id:'item_selection',
                       legend:'Select Test Objects'});
    },

    generate: function() {
        Ext.get('reports').clearContent();
        var items = [];
        Ext.each(this.itemList.selectedItems,
                 function(i) {
                     items.push(i.dbid);
                 }, this);

        Ext.Ajax.request({
            url: createUrl(this.reportUrl),
            method: 'get',
            params: "test_object_ids=" + items.join(','),
            scope: this,
            success: function(r) {
                var el = Ext.get('reports');
                el.set({cls: 'project-status'});
                this.report = new Report(r.responseText);
                this.report.render(el);
            }
        });

    }

});