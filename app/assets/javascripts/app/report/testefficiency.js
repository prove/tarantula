Ext.namespace('Ext.testia');

Ext.testia.TestEfficiency = function(gui) {
    Ext.testia.TestEfficiency.superclass.constructor.call(this, gui);

    this.appForm = new Ext.testia.AppForm(
        'report-form','toolbar',
        {
            toolbarTitle: 'Test Efficiency',
            default_buttons: false
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

    gui.on("testareachanged", this.onProjectChange, this);
    gui.on("projectchanged", this.onProjectChange, this);
};

Ext.extend(Ext.testia.TestEfficiency, Ext.testia.MainContentReport, {
    report: undefined,
    itemList: undefined,

    onProjectChange: function() {
        this.appForm.reset();
        this.itemList.reset();
        this.itemList.reload();
    },

    createForm: function () {
        var r  = new Ext.form.Radio({
            name: 'paramType',
            inputValue: 'date',
            boxLabel: "Select by date",
            labelSeparator: '',
            checked: true
        });
        r.on('check', function(b,c) {
            var e = this.appForm.findField('edate');
            var s = this.appForm.findField('sdate');
            if (e) {
                e.setDisabled(!c);
            }
            if (s) {
                s.setDisabled(!c);
            }
        }, this);
        this.appForm.add(r);
        this.appForm.add(
            new Ext.form.DateField({
                fieldLabel: 'Start date (yyyy-mm-dd)',
                format: 'Y-m-d',
                name: 'sdate',
                width:100,
                allowBlank:false,
                validator: (function(val) {
                    if (this.appForm.findField('sdate').getValue() <=
                        this.appForm.findField('edate').getValue()) {
                        return true;
                    }
                    return "Start date must be lesser than end date.";
                }).createDelegate(this)
            })
        );
        this.appForm.add(
            new Ext.form.DateField({
                fieldLabel: 'End date (yyyy-mm-dd)',
                format: 'Y-m-d',
                name: 'edate',
                width:100,
                allowBlank:false,
                validator: (function(val) {
                    if (this.appForm.findField('edate').getValue() >=
                        this.appForm.findField('sdate').getValue()) {
                        return true;
                    }
                    return "End date must be greater than start date.";
                }).createDelegate(this)
            })
        );

        r = new Ext.form.Radio({
            name: 'paramType',
            inputValue: 'testobject',
            boxLabel: "Select by test object",
            labelSeparator: ''
        });
        r.on('check', function(b,c) {
            if (!this.itemList) {
                return;
            }
            if (c) {
                this.itemList.enable();
            } else {
                this.itemList.disable();
            }
        }, this);
        this.appForm.add(r);

        this.appForm.fieldset({id:'item_selection',
                       legend:'Select Test Objects'});

        this.appForm.render();
        this.appForm.initEnd();
    },

    exportPDF: function() {
        this.report.exportPDF();
    },

    exportSpreadsheet: function() {
        this.report.exportSpreadsheet();
    },

    generate: function() {
        Ext.get('reports').clearContent();

        // Remove empty spaces
        var sf = this.appForm.findField('sdate');
        sf.setValue( sf.getRawValue().toString().strip());

        var ef = this.appForm.findField('edate');
        ef.setValue( ef.getRawValue().toString().strip());

        var values = this.appForm.getValues();
        var ok = true;
        var type = values.paramType;
        var sdate = values.sdate;
        var edate = values.edate;
        values = {};

        if (type === 'date') {
            if ( (sf.isValid() && ef.isValid() ) ||
                 ( (sf.isValid() && (edate.length === 0) ) ||
                   ((sdate.length === 0) && ef.isValid()) ||
                   ( (sdate.length === 0)&&(edate.length === 0)))){
                values.sdate = sdate;
                values.edate = edate;
            } else {
                ok = false;
                Ext.Msg.alert("Error", "Start date must be lesser than end date.");
            }
        } else if (type === 'testobject') {
            var items = [];
            Ext.each(this.itemList.selectedItems,
                     function(i) {
                         items.push(i.dbid);
                     }, this);
            values.test_object_ids = items.join(',');
        }
        if (ok) {
            Ext.Ajax.request({
                url: createUrl('/report/test_efficiency/'),
                method: 'get',
                params: values,
                scope: this,
                success: function(r) {
                    var el = Ext.get('reports');
                    this.report = new Report(r.responseText);
                    this.report.render(el);
                }
            });
        }
    },

    clear: function(e) {
        if (e !== "projectselect") {
            GUI.un("testareachanged", this.onProjectChange);
            GUI.un("projectchanged", this.onProjectChange);
        }
        return Ext.testia.RequirementCoverage.superclass.clear.call(this, e);
    }
});
