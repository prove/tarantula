Ext.namespace('Ext.testia');

Ext.testia.SetDesign = function(gui) {
    Ext.testia.SetDesign.superclass.constructor.call(this,gui);

    this.appStores = new AppStores();
    this.appStores.add('/projects/current/priorities',
        [{name:'name'}, {name: 'value'}]);
    this.appStores.load();

    this.appForm = new Ext.testia.AppForm('form','toolbar',
                                         {toolbarTitle:'Set'});

    this.appForm.ajaxResourceUrl = createUrl('/test_sets');

    this.createForm();
    this.extendAppForm();

    gui.set_panel.expand();
    gui.case_panel.expand();
};

Ext.extend(Ext.testia.SetDesign, Ext.testia.MainContentDesign, {
    set_design_list: undefined,

    createForm: function() {
        var cblist;
        // Set field names exactly same as in web service interface; It
        // allows whole form to be sent back to server when data is
        // being saved.
        var fields = [
            { id: 'testset',
                labelSeparator: "",
                labelWidth: 160
            },

            new Ext.form.TextField({
                fieldLabel: '<span style="color:black;">Name</span>' +
                    '<span style="color:#ea6e04;"> *</span>',
                name: 'name',
                fieldClass: 'tarantula-field-required x-form-field',
                //width:175,
                allowBlank:false,
                isValid: function() {
                    // Remove empty spaces
                    this.setValue( this.getValue().strip());
                    if( this.getValue() === "") {
                        return false;
                    }
                    return true;
                },
                invalidText: 'Please enter name for set.'
            }),

            new Ext.form.DateField({
                fieldLabel: '<span style="color:black;">Date</span>' +
                    '<span style="color:#ea6e04;">*</span>',
                fieldClass: 'tarantula-field-required x-form-field',
                name: 'date',
                allowBlank: true,
                altFormats: "Y/m/d",
                format: 'Y-m-d'
            }),

            new Ext.form.ComboBox({
                name: 'priority',
                store: this.appStores.find('/projects/current/priorities').extStore,
                displayField:'name',
                valueField: 'name',
                editable: false,
                selectOnFocus: true,
                forceSelection: true,
                triggerAction: 'all',
                emptyText:'',
                mode: 'local',
                fieldLabel: '<span style="color:black;">Priority</span>' +
                    '<span style="color:#ea6e04;"> *</span>',
                width: 175,
                allowBlank: false,
                invalidText: 'Please select priority for set.'
            }),

            new Ext.form.TextField({
                fieldLabel: 'Estimated duration',
                name: 'average_duration',
                width: "30%",
                readOnly: true,
                cls: 'x-form-readonly'
            }),

            new Ext.testia.TagField({
                store: new Ext.data.JsonStore({
                    url: createUrl('/projects/current/tags/?taggable_type=TestSet'),
                    root: 'data',
                    id: 'dbid',
                    fields: ['dbid', 'text']
                }),
                mode: 'local',
                fieldLabel: 'Tags',
                displayField: 'text',
                name: 'tag_list',
                ddGroup: 'sets-group',
                 // Fixed with, percentages breaks functionality on IE,.
                width: 600
            })
        ];

        if (!GUI.tagsStore.getById(GUI.tagFilterCombo.getValue()).get('forced')) {
            cblist = new Ext.testia.CheckboxList({
                store: new Ext.data.JsonStore({
                    url: createUrl('/projects/current/test_areas'),
                    root: 'data',
                    id: 'dbid',
                    fields: ['dbid', 'text', 'selected', 'forced']
                }),
                displayField: 'text',
                valueField: 'dbid',
                name: 'test_area_ids',
                fieldLabel: 'Test areas'
            });
            fields.push(cblist);
        }


        this.appForm.fieldset.apply(this.appForm, fields);

        this.appForm.end(); //fieldset

        this.appForm.render();

        this.appForm.registerField('name');
        this.appForm.registerField('date');
        this.appForm.registerField('priority');
        this.appForm.registerField('tag_list');
        if (cblist) {
            this.appForm.registerField(cblist, 'test_area_ids');
        }
        this.appForm.registerField('average_duration');


        /* Cases in the set */


        this.set_design_list = new Ext.ux.ListPanel('cases_in_set',{
            ddGroup:'cases-group',
            cmenuEnabled: false,
            searchEnabled: false,
            toolbarTitle: "Included Cases",
            deletedFolder: false,
            showListPath: false
        }, false);

        this.appForm.registerField(this.set_design_list.toolbar.addButton(
            new Ext.Toolbar.Button(
                {text:'Remove',
                 cls:'tarantula-btn-remove',
                 scope: this,
                 handler: function() {
                     this.set_design_list.removeSelected.call(this.set_design_list);
                 }
                })
        ));
        this.appForm.registerField(this.set_design_list,'set_design_list');


        this.appForm.initEnd();

        var el = this.set_design_list.el.child('div.x-listpanel');
        var nh = this.mainGui.layout.getRegion('center').bodyEl.dom.scrollHeight - this.appForm.el.getHeight();
        el.setHeight((nh > 150) ? nh : 150);

        this.mainGui.on('windowresized', function(dimensions) {
            var lw = dimensions.contentWidth - 20;
            var lh = dimensions.contentHeight -
                this.appForm.el.getHeight() -
                (this.set_design_list.toolbarEl.getHeight() * 2) - 30;
            // 30 leaves space for help text over the list. Number produced
            // with Stetson-Harrison -function.
            var el = this.set_design_list.el.child('div.x-listpanel');
            if (el) {
                el.setHeight((lh > 150) ? lh : 150);
            }
        }, this);
    },

    extendAppForm: function() {
        // Get values from record to form fields.
        this.appForm.afterLoad = function( r, options, success){
            if (!success) {
                return;
            }

            // Text fields.
            r[0].average_duration = r[0].average_duration.toDurationString();
            this.setValues(r[0]);

            var list = this.registered.set_design_list;
            list.url = createUrl('/test_sets/' + this.id + '/cases');
            list.itemUrl = list.url;
            list.reload();
            Ext.get('cases_in_set').show();
        };

        // Get values from fields and return them as parameters to ajax call.
        this.appForm.beforeSave = function () {

            var parameters = this.getValues(false,
                function(f) {return !f.readOnly;});

            parameters.cases = [];
            this.registered.set_design_list.items.each(function(n) {
                parameters.cases.push(n.dbid);
            });

            return Ext.urlEncode({data: Ext.encode(parameters)});
        };


        var gui = this.mainGui;
        // Get values from fields and return them as parameters to ajax call.
        this.appForm.afterSave = function ( options, success, response) {
            gui.set_list.reload();
        };

        this.appForm.afterDelete = function ( options, success, response) {
            gui.set_list.reload();
        };

        this.appForm.afterDelete = function ( options, success, response) {
            gui.set_list.reload();
        };

        this.appForm.beforeReset = function() {
            var list = this.registered.set_design_list;
            list.url = null;
            list.itemUrl = null;
        };
    }
});