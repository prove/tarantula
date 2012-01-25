Ext.namespace('Ext.testia');

Ext.testia.ResultsByTestObject = function(gui) {
    Ext.testia.ResultsByTestObject.superclass.constructor.call(this, gui);

    this.appForm = new Ext.testia.CoverageForm(
        'report-form','toolbar',
        {
            toolbarTitle: 'Prioritized Testing Maturity',
            reportUrl: '/report/results_by_test_object/'
        });
};

Ext.extend(Ext.testia.ResultsByTestObject, Ext.testia.MainContentReport);
