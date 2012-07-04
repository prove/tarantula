Ext.namespace('Ext.testia');

Ext.testia.CaseAnalysis = function(gui) {
    Ext.testia.CaseAnalysis.superclass.constructor.call(this, gui);

    this.appForm = new Ext.testia.SortableReportForm(
        'report-form','toolbar',
        {
            toolbarTitle: 'Case Execution List',
            reportUrl: '/report/case_execution_list/'
        });
};

Ext.extend(Ext.testia.CaseAnalysis, Ext.testia.MainContentReport, {});
