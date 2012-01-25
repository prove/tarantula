Ext.namespace('Ext.testia');

Ext.testia.MainContentReport = function(gui) {
    Ext.testia.MainContentReport.superclass.constructor.call(this, gui);
    gui.layout.getRegion('west').collapse();
};

Ext.extend(Ext.testia.MainContentReport, Ext.testia.MainContent, {
    report: undefined,

    exportPDF: function() {
        this.report.exportPDF();
    },

    htmlContent: function() {
        return('<div id="report-form"></div><div id="reports"></div>');
    }

});