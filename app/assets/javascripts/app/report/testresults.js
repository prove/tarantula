Ext.namespace('Ext.testia');

Ext.testia.TestResults = function(gui) {
    Ext.testia.TestResults.superclass.constructor.call(this, gui);

    this.appForm = new Ext.testia.ResultsForm(
        'report-form','toolbar',
        {
            toolbarTitle: 'Test Result Status',
            reportUrl: '/report/test_result_status/'
        });
};

Ext.extend(Ext.testia.TestResults, Ext.testia.MainContentReport);