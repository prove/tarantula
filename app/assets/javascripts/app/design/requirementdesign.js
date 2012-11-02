Ext.namespace('Ext.testia');

Ext.testia.RequirementDesign = function(gui) {
    Ext.testia.RequirementDesign.superclass.constructor.call(this,gui);

    this.appForm = new Ext.testia.AppForm('form','toolbar',
        {toolbarTitle:'Requirement'});

    this.appForm.ajaxResourceUrl = createUrl('/requirements');

    this.createForm();
    this.extendAppForm();

    gui.case_panel.expand();
    gui.requirement_panel.expand();
};

Ext.extend(Ext.testia.RequirementDesign, Ext.testia.MainContentDesign, {
    case_list: undefined,
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
                 invalidText: 'Please enter title for requirement.'
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
                 fieldLabel: '<span style="color:black;">Id</span>' +
                     '<span style="color:#ea6e04;">*</span>',
                 fieldClass: 'tarantula-field-required x-form-field',
                 name: 'external_id',
                 width: "30%",
                 allowBlank: false,
                 invalidText: "External id is required"
             }),

             new Ext.form.TextField({
                 fieldLabel: 'Priority',
                 name: 'priority',
                 width: '30%'
             }),

             new Ext.form.TextField({
                 fieldLabel: 'Modified at',
                 name: 'updated_at',
                 width: "30%",
                 readOnly: true,
                 cls: 'x-form-readonly'
             }),

             new Ext.testia.TagField({
                store: new Ext.data.JsonStore({
                    url: createUrl('/projects/current/tags/?taggable_type=Requirement'),
                    root: 'data',
                    id: 'dbid',
                    fields: ['dbid', 'text']
                }),
                mode: 'local',
                fieldLabel: 'Tags',
                displayField: 'text',
                name: 'tag_list',
                ddGroup: 'reqs-group',
                 // Fixed with, percentages breaks functionality on IE,.
                width: 600
             }),

             new Ext.tarantula.TextArea({
                 fieldLabel: 'Description',
                 name: 'description'
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
             fields.splice(7,0,cblist);
         }

         this.appForm.fieldset.apply(this.appForm, fields);

         this.appForm.end(); //fieldset

         this.appForm.render();

         this.appForm.registerField('name');
         this.appForm.registerField('date');
         this.appForm.registerField('external_id');

         this.appForm.registerField('priority');
         this.appForm.registerField('updated_at');
         this.appForm.registerField('tag_list');
         if (cblist) {
             this.appForm.registerField(cblist, 'test_area_ids');
         }
         this.appForm.registerField('description');


         tmpEl = Ext.DomHelper.append(this.appForm.el.dom.parentNode,
                                     {tag:'div', cls:'attachments'}, true);
         this.attachmentForm = new Ext.testia.AttachmentForm(tmpEl, {
             urlTemplate: createUrl('/requirements/%p/attachments/%i')
         });
         this.attachmentForm.render();

         this.appForm.registerField(this.attachmentForm, 'attachmentForm');

         this.case_list = new Ext.ux.ListPanel('cases_in_set',{
             ddGroup:'cases-group',
             cmenuEnabled: false,
             searchEnabled: false,
             deletedFolder: false,
             toolbarTitle: "Related Cases",
             showListPath: false
         }, false);

         this.appForm.registerField(this.case_list.toolbar.addButton(
             new Ext.Toolbar.Button(
                 {text:'Remove',
                  cls:'tarantula-btn-remove',
                  scope: this,
                  handler: function() {
                      this.case_list.removeSelected();
                  }
                 })
         ));
         this.appForm.registerField(this.case_list, 'case_list');

         this.appForm.initEnd();

         var el = this.case_list.el.child('div.x-listpanel');
         var nh = this.mainGui.layout.getRegion('center').bodyEl.dom.scrollHeight - this.appForm.el.getHeight();
         el.setHeight((nh > 150) ? nh : 150);

         this.mainGui.on('windowresized', function(dimensions) {
             var lw = dimensions.contentWidth - 20;
             var lh = dimensions.contentHeight -
                 this.appForm.el.getHeight() -
                 (this.case_list.toolbarEl.getHeight() * 2) - 30;
             // 30 leaves space for help text over the list. Number produced
             // with Stetson-Harrison -function.
             var el = this.case_list.el.child('div.x-listpanel');
             if (el) {
                 //el.setWidth(lw);
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
            this.setValues(r[0]);

            var list = this.registered.case_list;
            list.url = createUrl('/requirements/' + this.id + '/cases');
            list.itemUrl = list.url;
            list.reload();

            var optionals = r[0].optionals;
            Ext.DomHelper.useDom = false;
            var table = Ext.DomQuery.selectNode('#form form table.optional tbody');
            if (table) {
                Ext.get(table).clearContent();
            } else {
                table = Ext.DomHelper.append(Ext.get('form').child('form'), {
                    tag: 'table', cls:'optional', children: [
                        {tag:'tbody'}]}, true).child('tbody');
            }
            if (optionals) {
                for (i in optionals) {
                    if (typeof i != 'function') {
                        Ext.DomHelper.append(table, {
                            tag:'tr',
                            children: [
                                {tag:'th', html:i},
                                {tag:'td', html:optionals[i]}
                            ]
                        });
                    }
                }
            }
            Ext.get('cases_in_set').show();

            this.registered.attachmentForm.load(this.id);
        };

        // Get values from fields and return them as parameters to ajax call.
        this.appForm.beforeSave = function () {

            var parameters = this.getValues();

            var cases = [];
            this.registered.case_list.items.each(function(n) {
                cases.push(n.dbid);
            });
            parameters.cases = cases;
            return  Ext.urlEncode({data: Ext.encode(parameters)});
        };

        var gui = this.mainGui;
        // Get values from fields and return them as parameters to ajax call.
        this.appForm.afterSave = function ( options, success, response) {
            var cid = Ext.decode(response.responseText);
            this.registered.attachmentForm.upload(cid);
            gui.requirement_list.reload();
        };

        this.appForm.afterDelete = function ( options, success, response) {
            gui.requirement_list.reload();
        };

        this.appForm.beforeReset = function() {
            var list = this.registered.case_list;
            list.url = null;
            list.itemUrl = null;
        };

        this.appForm.beforeNew = function() {
            // Reset Doors optional fields.
            var table = Ext.DomQuery.selectNode('#form table:last tbody');
            if (table) {
                Ext.get(table).clearContent();
            }
            this.registered.attachmentForm.resetContent();
        };
    }

});