Ext.namespace('Ext.testia');

Ext.testia.RequirementCoverage = function(gui) {
    Ext.testia.RequirementCoverage.superclass.constructor.call(this, gui);

    this.appForm = new Ext.testia.AppForm(
        'report-form','toolbar',
        {
            toolbarTitle: 'Requirement Coverage',
            default_buttons: false,
            labelWidth: 30
        });

    this.appForm.addToolbarButton({
        config: {text: 'Generate', cls:'tarantula-btn-report'},
        enableInModes: [
            'empty','new','edit','read']},
        this.generate, this);

    this.appForm.addToolbarButton({
        config: {text: 'Export PDF', cls:'tarantula-btn-report'},
        text: 'Export PDF',
        enableInModes: ['empty','new','edit','read']},
        this.exportPDF, this);

    this.appForm.addToolbarButton({
        config: {text: 'Export spreadsheet', cls:'tarantula-btn-report'},
        text: 'Export spreadsheet',
        enableInModes: ['empty','new','edit','read']},
        this.exportSpreadsheet, this);

    this.createForm();

    gui.on("testareachanged", this.onProjectChange, this);
    gui.on("projectchanged", this.onProjectChange, this);
};

Ext.extend(Ext.testia.RequirementCoverage, Ext.testia.MainContentReport, {
    report: undefined,
    itemList: undefined,

    onProjectChange: function() {
        this.appForm.reset();
        this.itemList.reset();
        this.itemList.reload();
    },

    createForm: function () {
        this.appForm.fieldset(
            {legend: 'Sort by'},
            new Ext.form.Radio({
                boxLabel: 'ID',
                name: 'sort_by',
                checked: true,
                labelSeparator: '',
                labelWidth: 30,
                inputValue: 'id'
            }),
            new Ext.form.Radio({
                boxLabel: 'Priority',
                name: 'sort_by',
                labelSeparator: '',
                labelWidth: 30,
                inputValue: 'priority'
            })
        );
        this.appForm.fieldset({id:'item_selection',
                       legend:'Select Test Objects'});
        this.appForm.render();
        this.appForm.initEnd();

        this.itemList = new Ext.ux.ListPanel('item_selection', {
            treeUrl: createUrl('/projects/current/test_objects/'),
            itemUrl: createUrl('/projects/current/test_objects/'),
            ddGroup:'report-item-selection',
            cmenuEnabled: false,
            searchEnabled: false,
            deletedFolder: false,
            tagging: false,
            toggleSelection: true,
            toolbarEnabled: false,
            cls: 'testobjects-list'
        });
    },

    exportPDF: function() {
        this.report.exportPDF();
    },

    exportSpreadsheet: function() {
        this.report.exportSpreadsheet();
    },

    generate: function() {
        var values = this.appForm.getValues();

        var items = [];
        Ext.each(this.itemList.selectedItems,
                 function(i) {
                     items.push(i.dbid);
                 }, this);

        Ext.get('reports').clearContent();

        Ext.Ajax.request({
            url: createUrl('/report/requirement_coverage/'),
            method: 'get',
            params: 'sort_by=' + values.sort_by + "&test_object_ids=" + items.join(","),
            scope: this,
            success: function(r) {
                var el = Ext.get('reports');
                this.report = new Report(r.responseText);
                this.report.render(el);
            }
        });
    },

    clear: function(e) {
        if (e !== "projectselect") {
            GUI.un("testareachanged", this.onProjectChange);
            GUI.un("projectchanged", this.onProjectChange);
        }
        return Ext.testia.RequirementCoverage.superclass.clear.call(this, e);
    }
});
