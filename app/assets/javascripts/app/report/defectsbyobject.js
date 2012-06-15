Ext.namespace('Ext.testia');

Ext.testia.DefectsByObjectReport = function(gui) {
    Ext.testia.DefectsByObjectReport.superclass.constructor.call(this, gui);

    this.appForm = new Ext.testia.BaseReportForm(
        'report-form','toolbar',
        {
            toolbarTitle: 'Defect Analysis',
            reportUrl: '/report/bug_trend/'
        });
};

Ext.extend(Ext.testia.DefectsByObjectReport, Ext.testia.MainContentReport);
