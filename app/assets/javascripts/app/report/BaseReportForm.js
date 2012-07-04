Ext.namespace("Ext.testia");
/**
 * Ext.testia.BaseReportForm extension class for Ext.testia.AppForm
 *
 * @class Ext.testia.BaseReportForm
 * @extend Ext.testia.AppForm
 *
 * Extend basic AppForm by adding copy button, and default handler
 * for that.
 */
Ext.testia.BaseReportForm = function(form_div, toolbar_div, config) {
    config = config || {};
    config.default_buttons = false;

    if (config.reportUrl) {
        this.reportUrl = config.reportUrl;
        delete(config.reportUrl);
    }

    Ext.testia.BaseReportForm.superclass.constructor.call(this,
                                                      form_div,
                                                      toolbar_div, config);

    this.addToolbarButton({
        config: {text: 'Generate', cls:'tarantula-btn-report'},
        text: 'Generate',
        enableInModes: ['empty','new','edit','read']},
                          this.generate.createDelegate(this, [{}]), this);
    this.addToolbarButton({
        config: {text: 'Export PDF', cls:'tarantula-btn-report'},
        text: 'Export PDF',
        enableInModes: ['empty','new','edit','read']},
                             this.exportPDF, this);

    this.addToolbarButton({
        config: {text: 'Export spreadsheet', cls:'tarantula-btn-report'},
        text: 'Export spreadsheet',
        enableInModes: ['empty','new','edit','read']},
                             this.exportSpreadsheet, this);


    this.createForm();
    this.render();
};

Ext.extend(Ext.testia.BaseReportForm, Ext.testia.AppForm, {
    reportUrl: undefined,
    report: undefined,

    exportPDF: function() {
        this.report.exportPDF();
    },
    exportSpreadsheet: function() {
        this.report.exportSpreadsheet();
    },
    generate: function(parameters) {
        Ext.get('reports').clearContent();

        Ext.Ajax.request({
            url: createUrl(this.reportUrl),
            method: 'get',
            params: parameters,
            scope: this,
            success: function(r) {
                var el = Ext.get('reports');
                this.report = new Report(r.responseText);
                this.report.render(el);
            }
        });

    },
    createForm: function() {},

    setMode: function() {}
});