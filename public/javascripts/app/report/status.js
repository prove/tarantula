Ext.namespace('Ext.testia');

Ext.testia.StatusReport = function(gui) {
    Ext.testia.StatusReport.superclass.constructor.call(this, gui);

    this.appForm = new Ext.testia.StatusForm(
        'report-form','toolbar',{
            toolbarTitle:'Project Status',
            reportUrl:'/report/status'
        });
};

Ext.extend(Ext.testia.StatusReport, Ext.testia.MainContentReport, {});
