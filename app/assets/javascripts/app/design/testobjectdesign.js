Ext.namespace('Ext.testia');

Ext.testia.TestObjectsDesign = function(gui) {
    Ext.testia.TestObjectsDesign.superclass.constructor.call(this,gui);

    this.appForm = new Ext.testia.AppForm('form','toolbar',
        {toolbarTitle:'Test Object'});

    this.appForm.ajaxResourceUrl = createUrl('/projects/current/test_objects');

    this.createForm();
    this.extendAppForm();

    gui.testobjects_panel.expand();
};

Ext.extend(Ext.testia.TestObjectsDesign, Ext.testia.MainContentDesign, {
    attachmentForm: undefined,

    clear: function() {
        // Clearing of object triggered from rest of ui.  This should
        // return false, if clearing is not allowed (i.e. form is in
        // edit mode).
        ret = this.appForm.defaultActionClear( id);
        if (ret) {
            this.attachmentForm.resetContent();
        }
        return ret;
    },

    createForm: function() {
        var tmpEl;
        var cblist;
        // Set field names exactly same as in web service interface; It
        // allows whole form to be sent back to server when data is
        // being saved.
        var fields = [
            {
                labelSeparator: "",
                labelWidth: 100
            },
            new Ext.form.TextField({
                fieldLabel: '<span style="color:black;">Name</span>' +
                    '<span style="color:#ea6e04;">*</span>',
                fieldClass: 'tarantula-field-required x-form-field',
                name: 'name',
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
                invalidText: 'Please enter name for test object.'
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
            new Ext.form.TextField({
                fieldLabel: 'ESW',
                name: 'esw'
            }),
            new Ext.form.TextField({
                fieldLabel: 'SWA',
                name: 'swa'
            }),
            new Ext.form.TextField({
                fieldLabel: 'Hardware',
                name: 'hardware'
            }),
            new Ext.form.TextField({
                fieldLabel: 'Mechanics',
                name: 'mechanics'
            }),
            new Ext.tarantula.TextArea({
                fieldLabel: 'Description',
                name: 'description'
            }),
            new Ext.testia.TagField({
                store: new Ext.data.JsonStore({
                    url: createUrl('/projects/current/tags/?taggable_type=TestObject'),
                    root: 'data',
                    id: 'dbid',
                    fields: ['dbid', 'text']
                }),
                mode: 'local',
                fieldLabel: 'Tags',
                displayField: 'text',
                name: 'tag_list',
                ddGroup: 'testobjects-group',
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

        this.appForm.registerField('esw');
        this.appForm.registerField('swa');
        this.appForm.registerField('hardware');
        this.appForm.registerField('mechanics');

        this.appForm.registerField('description');

        this.appForm.registerField('tag_list');
        if (cblist) {
            this.appForm.registerField(cblist, 'test_area_ids');
        }


        tmpEl = Ext.DomHelper.append(this.appForm.el.dom.parentNode,
                                     {tag:'div', cls:'attachments'}, true);
        this.attachmentForm = new Ext.testia.AttachmentForm(tmpEl, {
            urlTemplate: createUrl('/projects/current/test_objects/%p/attachments/%i')
        });
        this.attachmentForm.render();

        this.appForm.registerField(this.attachmentForm, 'attachmentForm');

        this.appForm.initEnd();
     },

     extendAppForm: function() {
        // Get values from record to form fields.
        this.appForm.afterLoad = function( r, options, success){
            if (!success) {
                return;
            }
            // Text fields.
            this.setValues(r[0]);
            this.registered.attachmentForm.load(this.id);
        };

        // Get values from fields and return them as parameters to ajax call.
        this.appForm.beforeSave = function () {
            var parameters = this.getValues();
            return  Ext.urlEncode({data: Ext.encode(parameters)});
        };

        var gui = this.mainGui;
        // Get values from fields and return them as parameters to ajax call.
        this.appForm.afterSave = function ( options, success, response) {
            var cid = Ext.decode(response.responseText);
            this.registered.attachmentForm.upload(cid);
            gui.testobjects_list.reload();
        };

        this.appForm.afterDelete = function ( options, success, response) {
            gui.testobjects_list.reload();
        };

        this.appForm.beforeNew = function() {
            this.registered.attachmentForm.resetContent();
        };
    }

});