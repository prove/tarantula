Ext.namespace('Ext.testia');
/**
 * Ext.testia.AppForm extension class for Ext.Form
 *
 * @class Ext.testia.AppForm
 * @extend Ext.form.Form
 *
 * Common functionality shared between all design screens.
 *
 * Provides toolbar with default actions (new, edit, delete, save, cancel).
 * if parameter default_buttons is false, don't generate those in toolbar.

 * Using object must define following additional default methods for
 * this object:
 * AppForm.loadHandler( id) - Method to load form from server.
 * AppForm.saveHandler( ) - Save form contents to server.

 * Using object must also define following interfaces for rest of the UI
 * (navigator)
 * load( id) - Interface for loading specified object.
 * clear - Interface for clearing form (in case of e.g. object or screen
 * change).


  Todo: There are still some potential problems with current implementation.
  Should toolbar etc. be disabled when there is ajax request going on?
*/

Ext.testia.AppForm = function(form_div,toolbar_div,config){
    config = config || {};

    var default_buttons;

    default_buttons = config.default_buttons;
    if (default_buttons === undefined) {
        default_buttons = true;
    } else {
        default_buttons = config.default_buttons;
        delete(config.default_buttons);
    }
    if (!config.labelWidth) {
        config.labelWidth = 210;
    }
    if (config.toolbarTitle) {
    }


    this.initialized = false;
    Ext.testia.AppForm.superclass.constructor.call(this, config);

    this.form_id = form_div;

    this.toolbarButtons = [];
    this.extFields = [];
    this.registered = {};

    // Create toolbar and add default buttons
    this.extToolbar = new Ext.Toolbar(toolbar_div);

    if( config.toolbarTitle) this.extToolbar.addField(new Ext.Toolbar.TextItem(config.toolbarTitle));

    if (default_buttons) {
        this.addToolbarButton( {config: {text: 'New', cls:'tarantula-btn-new'},
                                enableInModes: ['empty', 'read']},
                               this.defaultButtonNew, this);
        this.addToolbarButton( {config:{text: 'Edit', cls:'tarantula-btn-edit'},
                                enableInModes: ['read']},
                               this.defaultButtonEdit, this);
        this.addToolbarButton( {config:{text:'Save', cls:'tarantula-btn-save'},
                                enableInModes: ['new','edit']},
                               this.defaultButtonSave, this);
        this.addToolbarButton( {config:{text:'Cancel', cls:'tarantula-btn-cancel'},
                                enableInModes: ['new', 'edit']},
                               this.defaultButtonCancel, this);
        this.deleteButton = this.addToolbarButton( {config:{text:'Delete', cls:'tarantula-btn-delete'},
                                                    enableInModes: ['read']},
                               this.defaultButtonDelete, this);
        this.keymap = new Ext.KeyMap(Ext.get(form_div), [
        {
            key: 's',
            ctrl: true,
            fn: this.onKeyEvent(this.defaultButtonSave, this, ['new', 'edit']),
            scope: this
        },
        {
            key: 'e',
            ctrl: true,
            fn: this.onKeyEvent(this.defaultButtonEdit, this, ['read']),
            scope: this
        },
        {
            key: 'n',
            ctrl: true,
            fn: this.onKeyEvent(this.defaultButtonNew, this, ['read']),
            scope: this
        }
    ]);
    }

    GUI.on('projectchanged', this.onProjectChanged, this);
};


Ext.extend(Ext.testia.AppForm, Ext.form.Form, {
    // Defines base serverside resource url for this object.
    // E.g. /cases

    // Set from using module.
    ajaxResourceUrl: undefined,
    form_id: undefined,

    // Identifies object currently loaded into form.
    id: undefined,
    project_id: undefined,
    // Currently loaded object version, if information is available
    // i.e. object uses acts_as_versioned
    version: undefined,

    // Array of Ext.Fields added to form.
    extFields: undefined, // []
    registered: undefined, // {}

    // Ext.Toolbar
    extToolbar: undefined,

    deleteButton: undefined,

    // Modes of form.
    modes: ['empty', 'new', 'read', 'edit'],

    // current mode
    mode: undefined,

    // Initialized
    initialized: undefined,

    // If load method is called before form is initialized,
    // store object id to pendingLoad and load after initialization.
    pendingLoad: undefined,

    // shortcut keys
    keymap: undefined,

    // Add button to toolbar.
    // config: Config properties for button
    //   config.config: Button config (e.g. {text: "new", cls: "style"})
    //   config.enableInModes: Array of modes when button is enabled
    //                (empty, new, read, edit).
    //   config.allowedGroups: User groups which are allowed to use this
    // fn: Callback function to be called when button is activated.
    // scope: Scope of callback function.
    addToolbarButton: function(config, fn, scope){

        // TODO Validate enableInModes is array and are valid modes

        button = {};
        button.enableInModes = config.enableInModes;
        button.allowedGroups = config.allowedGroups;

//        button.extButton = this.extToolbar.addButton({text:config.text});
        button.extButton = this.extToolbar.addButton(config.config);
        button.extButton.setHandler( fn, scope);

        this.toolbarButtons.push( button);
        return button;
    },

    // Shortcut keys
    initKeymap: function() {
    },

    // Extends Ext.form.Form's findField method
    findField: function(name) {
        var r = Ext.testia.AppForm.superclass.findField.call(this, name);
        if (r) {
            return r;
        }

        Ext.each(this.extFields, function(i) {
            if (i.name === name) {
                r = i;
                return false;
            }
        }, this);

        return r;
    },

    // Sets form mode and enables/disables fields and buttons accordingly.
    // mode: empty, new, read, edit.
    setMode: function( mode){
        var f, v;

        this.toolbarButtons.forEach(
            function( element, index, array) {
                // Disable every button on default, when mode is changed
                element.extButton.disable();

                // Loop through all buttons and enable correct ones.
                if ( element.enableInModes.some(
                    function( element, index, array){
                        return element == mode;
                    }
                ) && ( (element.allowedGroups === undefined) ||
                       (element.allowedGroups.length == 0) ||
                       (element.allowedGroups.some(function(e) {
                           return e.toLowerCase() == user_group.toLowerCase();
                       }))
                     )) {
                    element.extButton.enable();
                }
            }
        );

        if( mode == 'empty' || mode == 'read') {
            this.disable();
        } else {
            this.enable();
        }

        // Set current date to default value for date fields if any.
        if ( (mode == 'new') && (f = this.findField('date')) ) {
            f.setValue(new Date().format("Y/m/d"));
        }

        if ( (mode == 'new') && (f = this.findField('test_area_ids')) ) {
            v = GUI.tagFilterCombo.getValue();
            if (v == 0) {
                f.checkAll();
            } else {
                f.setValue([v]);
            }
        }

        // Disable changing test areas or projects when editing
        if ((mode == 'new') || (mode == 'edit')) {
            GUI.projectCombo.disable();
            GUI.tagFilterCombo.disable();
        } else {
            GUI.projectCombo.enable();
            f = GUI.tagsStore.getById(GUI.tagFilterCombo.getValue());
            if ( (f === undefined) || (!f.get('forced')) ) {
                GUI.tagFilterCombo.enable();
            }
        }

        this.mode = mode;
    },

    // Helper function to create radiobutton on form
    // from ext.data.Record values.
    // Each radiobutton field is given id as fieldName+Inputvalue
    // fieldName: (Internal) name of the field.
    // records: array of Ext.data.Record objects containing data used for
    //            individual radiobutton names and values.
    // nameProperty: Name of the record property containing value used for
    //            radiobutton name.
    // inputValueProperty: Name of the record property containing value used
    //            for radiobutton value.
    addFieldRadiobutton: function( fieldName, records,
                                   nameProperty,
                                   inputValueProperty){

        Ext.each(records, function(r){
            this.add( new Ext.form.Radio({
                name: fieldName,
                id: fieldName + r.get( inputValueProperty),
                boxLabel: r.get( nameProperty),
                inputValue: r.get( inputValueProperty)
            }));
            this.registerField( fieldName + r.get( inputValueProperty));
        }, this);
    },


    // Helper function to create checkbox field on form from ext.data.
    // Record values.
    // Each radiobutton field is given id as fieldName+Inputvalue
    // fieldName: (Internal) name of the field. Do not use '[]' in fieldname,
    //            it is added automatically.
    // records: Array of Ext.data.Record objects containing data used for
    //            individual checkbox names and values.
    // nameProperty: Name of the record property containing value used for
    //                checkbox name.
    // inputValueProperty: Name of the record property containing value
    //                     used for  checkbox value.
    addFieldCheckbox: function(fieldName, records,
                               nameProperty,
                               inputValueProperty){

        Ext.each(records, function(r){
            this.add(new Ext.form.Checkbox({
                name: fieldName + '[]',
                id: fieldName + r.get( inputValueProperty),
                boxLabel: r.get( nameProperty),
                inputValue: r.get( inputValueProperty)
            }));
            this.registerField( fieldName + r.get( inputValueProperty));
        }, this);
    },

    // Helper function to set checkbox values.
    // Assumes that individual checkboxes are given id as fieldName+Inputvalue
    // (i.e. by function addFieldCheckbox)
    // fieldName: (Internal) name of field.
    // values: Values to be set.
    setFieldCheckbox: function( fieldName, values) {

        for(var i=0,il=values.length; i<il; ++i){
            f = fieldName + values[i];
            fi = this.findField(f);
            if (fi) { fi.setValue( true); }
        }

    },

    // Registers field to be enabled/disabled by mode change.
    // fieldId: Id of the field.
    // Changes
    //  2008-01-04: Accept Ext object as fieldId parameter, so grids and
    //  other non-form fields can be added to the disable/enable list.
    //  Check creation of the stepsgrid object from CaseDesign.js for example.
    //      -- iiska
    //
    // TODO: override Ext.form.Form.add method, and handle add + register in
    //       single method. Handle also situations where added object isn't
    //       normal form object.
    registerField: function( fieldId, name) {
        var field, fName;
        if ( !(field = this.findField(fieldId)) ) {
            field = fieldId;
        }
        this.extFields.push(field);
        if (name) {
            fName = name;
        } else {
            fName = fieldId.toString();
        }
        this.registered[fName] = this.extFields.last();
    },


    // We need separate render phase,
    // so fields will become available
    // and they can be registered from using module.
    render: function(){
        this.applyIfToFields({width:"98%"});
        Ext.testia.AppForm.superclass.render.call(this,this.form_id);
    },

    // Form initialization done.
    // Initial mode can be set.
    // If there is pending load requests, load it.
    //
    // TODO: Could these be relocated somewhere else.
    initEnd: function( ){
        //this.extForm.render(this.form_id);

        this.setMode( 'empty');

        this.initialized = true;

        if( this.pendingLoad) {
            this.defaultActionLoad( this.pendingLoad);
            this.pendingLoad = null;
        }
    },


    // Disables all fields on form.
    disable: function(){
        Ext.each(this.extFields, function(i) {
            if (i.disable) {
                i.disable();
            }
        }, this);
    },

    // Enables all fields on form.
    enable: function(){
        Ext.each(this.extFields, function(i) {
            if (!i.readOnly) {
                i.enable();
            }
        });
    },

    // Reset extForm and non-form components
    // from the extFields array.
    reset: function(){
        if (this.beforeReset !== undefined) {
            this.beforeReset();
        }
        Ext.each(this.extFields, function(i) {
            if (i.reset) {
                i.reset();
            }
        });
        Ext.testia.AppForm.superclass.reset.call(this);
    },

    // Override Ext.form.Form.getValues(), return values from
    // registered fields which are instances of Ext.form.Field
    // as json object.
    //
    // @param {Function} filter Define filter function to be used for
    // selecting fields. ie function(f) {return !f.readOnly} will include
    // only editable fields.
    getValues: function(str, filter) {
        if (!this.extFields.length || (this.extFields.length <= 0)) {
            return Ext.testia.AppForm.superclass.getValues.call(this,str);
        }
        obj = {};
        Ext.each(this.extFields, function(f) {
            if (f instanceof Ext.form.Field) {
                // Handle nested values inside objects like:
                // value: {bug_tracker: {id: 1}}
                // field: bug_tracker[id]
                var a = f.name.match(/^([^[]+)(\[([^\]]*)\])*/);
                if (typeof obj[a[1]] == 'undefined' && a[3]) {
                    obj[a[1]] = {};
                }
                var ref = obj[a[1]];
                var i, il;
                for (i=3,il=a.length;i<il;i+=2) {
                    if (a[i]) {
                        if (typeof ref[a[i]] == 'undefined') {
                            if (a[i+2]) {
                                ref[a[i]] = {};
                            }
                        } else {
                            ref = ref[a[i]];
                        }
                    } else {
                        ref = obj;
                        break;
                    }
                }
                if (!a[i]) {
                    i -= 2;
                }


                if (filter && filter(f)) {
                    ref[a[i]] = f.getValue();
                } else if (!filter) {
                    ref[a[i]] = f.getValue();
                }
            }
        }, this);
        if (this.project_id) {
            obj.project_id = this.project_id;
        }
        if (this.original_id) {
            obj.original_id = this.original_id;
        }
        if (this.version) {
            obj.version = this.version;
        }
        if (str) {
            return Ext.urlEncode(obj);
        }
        return obj;
    },

    // Override default setValues. Loop through registered field
    // and populate instances of Ext.form.Field with values in
    // parameter object.
    setValues: function(values) {
        Ext.each(this.extFields, function(f) {
            if ( f instanceof Ext.form.Field ) {
                // Handle nested values inside objects like:
                // value: {bug_tracker: {id: 1}}
                // field: bug_tracker[id]
                var a = f.name.match(/^([^[]+)(\[([^\]]*)\])*/);
                var v = values[a[1]];
                for (var i=3,il=a.length;i<il;i+=2) {
                    if (a[i]) {
                        v = v[a[i]];
                    } else {
                        break;
                    }
                }
                f.setValue(v);
            }
        }, this);
    },

    // Set "Delete" button text depending on displayed object's state
    setDeleteButtonText: function( isDeleted){
        if( isDeleted){
            this.deleteButton.extButton.setText('Undelete');
        } else {
            this.deleteButton.extButton.setText('Delete');
        }
    },


    // Default actions follow.

    // Loading of form is activated (e.g. by Navigator).
    // id: Id of the object to be loaded onto form.
    //
    // returns false, if loading is not allowed (object is being edited)
    defaultActionLoad: function( id){

        // Do not allow loading in editing mode.  Also, if id is not
        // given, do not load ( Navigator UI may call load without id
        // (e.g. folder).
        if( this.mode == 'new' || this.mode == 'edit' || (!id)) {
            return false;
        }

        if( !this.initialized) {
            this.pendingLoad = id;
            return true;
        }


        //this.id = id;
        //this.reset();
        // ---> code moved to onLoad event

        this.ajaxLoadObject( id);

        this.setMode( 'read');

        return true;
    },

    // Reloads current object, if any.
    defaultActionReload: function(){
        if( !this.id) { return false; }
        this.defaultActionLoad( this.id);
    },

    // Clears form.
    // returns false, if clearing is not allowed (object is being edited)
    defaultActionClear: function(e){

        // Validation - Not in editing mode...return false, if fails...
        if( this.mode == 'new' || this.mode == 'edit') {
            return false;
        }

        this.id = null;
        this.reset();
        this.setMode( 'empty');

        if (e !== "projectselect") {
            GUI.un('projectchanged', this.onProjectChanged);
        }

        return true;
    },

    // Create new object.
    defaultButtonNew: function( ){

        // Call beforeNew if defined.
        if( this.beforeNew !== undefined) {
            this.beforeNew( );
        }

        // Validation not needed, button available only in valid modes.
        this.id = null;

        this.reset();
        this.setMode( 'new');

        // Call beforeNew if defined.
        if( this.afterNew !== undefined) {
            this.afterNew( );
        }
    },

    // Switches from read mode to edit mode.
    defaultButtonEdit: function( ){


        // Reload object.
        //this.reset();

        // Quickfix to #224?
        // If object is not yet loaded, don't allow editing.
        // Correct fix would be that buttons are disabled...
        if( !this.id) { return false; }

        this.ajaxLoadObject( this.id);
        this.setMode( 'edit');
    },

    // Deletes object from database.
    defaultButtonDelete: function( ){
        // Validation not needed, button available only in valid modes.
        this.ajaxDeleteObject( this.id);
    },

    // Saves object to database.
    defaultButtonSave: function( ){

        // While data is loaded, no saving is allowed to happen.
        // If user e.g. saves case, before related requirements
        // have been loaded, requirement info is lost!
        // Better solution would be to set toolbar actions enabled/disabled
        // AFTER server communication is completed...

        if ( GUI.requestCount > 0) return false;
        

        // Call actual savehandler for sending actual ajax requests.
        if (this.validate()) {
            this.ajaxSaveObject();
        }
    },

    // Cancel changes (reload object from database).
    defaultButtonCancel: function( ){

        this.reset();

        if( this.id) {
            //Reload object
            this.ajaxLoadObject( this.id);
            this.setMode( 'read');
        } else {
            this.setMode( 'empty');
        }
    },

    // Validate fields and run possible additional form validation,
    // if specified.
    validate: function( ){

        // Client side validation done for fields,
        // which define isValid() function.
        var data_ok = true;
        Ext.each(this.extFields, function(field) {
            if (field.isValid !== undefined) {
                if (!field.isValid(false)) {
                    if (field.onInvalid) {
                        field.onInvalid(this, field, field.invalidText);
                    } else {
                        Ext.Msg.show({
                                         title: 'Invalid values',
                                         msg: field.invalidText,
                                         buttons: Ext.Msg.OK,
                                         minWidth: 300,
                                         fn: function() {
                                             if (field.focus !== undefined) {
                                                 field.focus();
                                             }
                                         } //Focus field after messagebox, if possible.
                                     });
                    }
                    data_ok = false;
                    return false;
                }
            }
        }, this);

        // If form defines additional isValid() function and no errors so far,
        // call form validation.
        if( this.isValid !== undefined && data_ok) {
            if( !this.isValid()){
                //Failed.
                data_ok = false;

                msg = 'Form contains invalid values.'; // Default message
                if (this.invalidText !== undefined) {
                    msg = this.invalidText;
                }

                Ext.Msg.show({
                    title: 'Invalid values',
                    msg: msg, //'Data not saved. Fix invalid fields first.',
                    buttons: Ext.Msg.OK,
                    minWidth: 300
                });
            }
        }

        return data_ok;
    },

    /* --------------- Load --------------- */

    ajaxLoadObject: function( id) {
        if (!id) {
            return;
        }

        // Call beforeLoad if defined.
        if( this.beforeLoad !== undefined) { this.beforeLoad( id); }

        Ext.Ajax.request({
            url: this.ajaxResourceUrl + '/' + id,
            method: 'get',
            scope: this,
            success: function(r,o) {
                var data = Ext.decode(r.responseText).data;
                this.onLoad(data, o, true);
            }
        });
    },

    onKeyEvent: function(fn, scope, enableInModes) {
        if (enableInModes.indexOf(this.mode) >= 0) {
            fn.call(scope);
        }
    },

    onLoad: function ( r, options, success){

        this.isLoadingEditMode = false;

        if( success) {
            this.id = r[0].id;
            this.version = r[0].version;
            this.project_id = r[0].project_id;
            this.reset();
        }

        if( this.afterLoad) {
            this.afterLoad(r, options, success);
        }

        this.setDeleteButtonText( r[0].deleted);
    },


    /* --------------- Save --------------- */
    ajaxSaveObject: function() {

        var parameters = this.beforeSave();
        if (parameters === false) {
            return;
        }
        if (this.version !== undefined) {
            parameters += "&version=" + this.version;
        }

        if( this.id){
            // Existing object, use put method and add id.
            httpMethod = 'put';
            url = this.ajaxResourceUrl + '/' + this.id;
        } else {
            // New object, post.
            httpMethod = 'post';
            url = this.ajaxResourceUrl;
        }

        Ext.Ajax.request({
            url: url,
            params: parameters,
            method: httpMethod,
            callback: this.onSave,
            scope: this
        });
    },

    onProjectChanged: function() {
        var f = this.findField('test_area_ids');
        if (f) {
            f.store.load();
        }
    },


    onSave: function( options, success, response) {

        // Default onsave handler.
        // Scope is set to appForm
        if( success && (response.responseText.length > 0)) {
            // All ok, reload object.
            // Server returns 2XX code and id of modifed or created
            // object in body.
            this.reset();
            this.id = response.responseText;
            this.setMode( 'read');

        } else {
            // Exception or failure occurred.
            // Server returns forbidden code and error message in body.

            // No need to define here anymore....
            //Ext.Msg.alert( 'Validation error', response.responseText);

            // Set back to edit mode to allow user to make corrections
            if(this.id) {
                this.setMode( 'edit');
            } else {
                this.setMode( 'new');
            }
        }

        // Call additional user specifed onSave function, if defined.
        if( this.afterSave) {
            this.afterSave(options, success, response);
        }
        this.ajaxLoadObject( this.id);
    },

    /* --------------- Delete --------------- */

    ajaxDeleteObject: function() {

        Ext.Ajax.request({
            url: this.ajaxResourceUrl + '/' + this.id,
            // Looks like IE7 doesn't support delete method,
            // emulate delete instead on post.
            // method: 'delete',
            params: { _method: 'delete' },
            method: 'post',
            callback: this.onDelete,
            scope: this
        });
    },

    onDelete: function(options, success, response) {
        // Scope is set to appForm
        if (success) {
            this.id = null;
            this.reset();
            this.setMode( 'empty');
        }
        if( this.afterDelete) {
            this.afterDelete(options, success, response);
        }
    }

});
