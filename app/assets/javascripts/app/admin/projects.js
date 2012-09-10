Ext.namespace('Ext.testia');

Ext.testia.BugtrackerDlg = function(config) {
    config = config || {};

    config.width = config.width || 375;
    config.height = config.height || 600;
    config.scope = config.scope || this;
    config.center = config.center || {autoScroll: true};
    config.autoCreate = true;

    //var el = Ext.DomHelper.append(document.body, {tag:'div'});
    Ext.testia.BugtrackerDlg.superclass.constructor.call(this, Ext.id(),
                                                         config);

    this.handler = config.fn.createDelegate(config.scope);

    // Call provided dialog handler with scope provided in the config.
    this.addButton('Ok', function() {
       this.closeDialog('ok');
    }, this);
    this.addButton('Delete', function() {
        this.closeDialog('delete');
    }, this);
    this.addButton('Cancel', function() {
        this.closeDialog('cancel');
    }, this);

    var layout = this.getLayout();
    layout.beginUpdate();
    var cp = new Ext.ContentPanel(Ext.id(), {autoCreate: true,
        background: true});
    layout.add('center', cp);
    layout.endUpdate();
    this.dForm = new Ext.form.Form({
        //labelAlign: 'top',
        itemCls: 'dialogForm'
    });

    this.dForm.add(new Ext.form.ComboBox({
                fieldLabel: 'Bugtracker',
                name: 'bug_tracker_id',
                width: 175,
                store: new Ext.data.JsonStore({
                    url: createUrl('/bug_trackers'),
                    root: 'data',
                    fields: ['name', 'id']}),
                displayField:'name',
                valueField: 'id',
                editable: false,
                allowBlank: false,
                lazyRender: true,
                triggerAction: 'all',
                mode: 'local',
                selectOnFocus:true
    }));

    this.dForm.add(new Ext.form.TextField({fieldLabel: 'Name', name: 'name'}));
    this.dForm.add(new Ext.form.TextField({fieldLabel: 'Url',
                                           name: 'base_url'}));
    this.dForm.fieldset({legend:'Database configuration'},
                        // Radiobutton fields for selecting
                        // type.
                        //
                        new Ext.form.Radio({
                            fieldLabel: 'Type',
                            id: 'typeBugzilla',    // Identifies field in ui
                            name: 'type',
                            inputValue: 'Bugzilla',
                            boxLabel: 'Bugzilla'
                        }),
                        new Ext.form.Radio({
                            id: 'typeJira',
                            labelSeparator: '',
                            name: 'type',
                            inputValue: 'Jira',
                            boxLabel: 'Jira'
                        }),
                        new Ext.form.Checkbox({
                            fieldLabel: 'Sync Tarantula project with Bugzilla classification',
                            name: 'sync_project_with_classification',
                            width: 10,
                            inputValue: 1
                        }),
                        new Ext.form.TextField({
                            fieldLabel: 'DB adapter',
                            name: 'db_adapter',
                            value: 'mysql2'
                        }),
                        new Ext.form.TextField({
                            fieldLabel: 'DB host',
                            name: 'db_host'
                        }),
                        new Ext.form.TextField({
                            fieldLabel: 'DB name',
                            name: 'db_name'
                        }),
                        new Ext.form.TextField({
                            fieldLabel: 'DB user',
                            name: 'db_user'
                        }),
                        new Ext.form.TextField({
                            fieldLabel: 'DB password',
                            name: 'db_passwd',
                            inputType: 'password'
                        }));
    this.dForm.render(Ext.DomHelper.append(cp.el, {tag:'div'}, true));

    this.setTitle(config.title);

    this.center();

    var bugtrackerCombo = this.dForm.findField('bug_tracker_id');
    bugtrackerCombo.store.on('load', function() {
        var rec = Ext.data.Record.create([{name: 'id'}, {name: 'name'}]);
        this.add(new rec({name:'(new bug tracker)', id:0}));
    }, bugtrackerCombo.store);
    bugtrackerCombo.store.load();
    bugtrackerCombo.on('select', function() {
        var id = bugtrackerCombo.getValue();
        if (id > 0) {
            Ext.Ajax.request({
                url: createUrl('/bug_trackers/'+id),
                method: 'get',
                scope: this,
                success: function(r, o) {
                    var d = Ext.decode(r.responseText);
                    var f;
                    for (var i in d.data) {
                        if (d.data[i] && typeof d.data[i] != 'function') {
                            if ((f = this.dForm.findField(i))) {
                                f.setValue(d.data[i]);
                            }
                        }
                    }
                    // Set bugtracker type on form.
                    // Ui is expected to have radiobutton with name
                    // "type" + actual field value of bugtracker
                    // (bugzilla, jira...)
                    f = this.dForm.findField('type' + d.data.type);
                    if (f) {
                        f.setValue( true);
                    } else {
                        alert( "Undefined bugtracker type: " + d.data.type);
                    }
                    // Disable type changin on saved trackers
                    this.dForm.findField( 'typeJira').disable();
                    this.dForm.findField( 'typeBugzilla').disable();
                }
            });
        } else {
            this.dForm.reset();
            // Disable type changin on saved trackers
            this.dForm.findField( 'typeJira').enable();
            this.dForm.findField( 'typeBugzilla').enable();
        }
    }, this);

    this.on('hide', function() {
        this.destroy(true);
    }, this);

    this.show();
};
Ext.extend(Ext.testia.BugtrackerDlg, Ext.LayoutDialog, {
    handler: undefined,
    dForm: undefined,

    closeDialog: function(button) {
        var id = this.dForm.findField('bug_tracker_id').getValue();
        if (button == 'ok') {
            var url = createUrl('/bug_trackers/');
            if (id > 0) {
                url += id;
            }
            var params = this.dForm.getValues();
            delete(params.bug_tracker_id);
            Ext.Ajax.request({
                url: url,
                method: (id > 0) ? 'put' : 'post',
                params: Ext.urlEncode({data: Ext.encode(params)}),
                scope: this,
                success: function() {
                    this.handler(button);
                    this.destroy(true);
                }
            });
        } else if ( (button == 'delete') && (id > 0) ) {
            Ext.Ajax.request({
                url: createUrl('/bug_trackers/'+id),
                method: 'delete',
                scope: this,
                success: function() {
                    this.dForm.findField('bug_tracker_id').store.load();
                    this.handler(button);
                    this.dForm.reset();
                }
            });

       } else {
            this.handler(button);
            this.destroy(true);
        }
    }
});


/*
  TODO: Adding/removing of users needs improvement.
          - User can now select same user several times
          from dropdown list (altough error is raised)
          - There is only one error message describing all (both)
          error conditions of user selection box.
*/

var Projects = function() {
    // Re-usable UI functionality is defined in AppForm class.
    var appForm;

    // Class for loading several stores at once.
    var appStores;

    var usersgrid;
    var productsGrid;

    // Generic store which holds tag_list field items to be used in combobox
    var defaultTagsStore;
    var productsStore;

    var btRemoved;

    // Private functions.
    function createForm() {

        // When stores have been loaded, create fields on form.

        // Set field names exactly same as in web service interface;
        // It allows whole form to be sent back to server when data is
        // being saved.
        appForm.fieldset(
            { id: 'project',
              legend: 'Project - Required fields marked with asterisk (*)'},

            new Ext.form.TextField({
                fieldLabel: '* Name',
                name: 'name',
                width: 175,
                isValid: function() {
                    // Remove empty spaces
                    this.setValue( this.getValue().strip());
                    if( Ext.isEmpty(this.getValue())) {return false;}
                    return true;
                },
                invalidText: 'Please enter name.'
            }),
            new Ext.form.TextArea({
                fieldLabel: 'Description',
                name: 'description',
                width: 175,
                grow: true,
                isValid: function() {
                    // Remove empty spaces
                    this.setValue( this.getValue().strip());
                    return true;
                }
            }),
            new Ext.form.Checkbox({
                fieldLabel: 'Use project as a case library',
                name: 'library',
                width: 10
            }),

            new Ext.form.TextField({
                fieldLabel: 'Test areas',
                name: 'test_areas',
                width: 175
            })

        );

        appForm.fieldset({id:'bugtracker', legend:'Bugtracker'},
            new Ext.form.ComboBox({
                fieldLabel: 'Bugtracker',
                name: 'bug_tracker_id',
                width: 175,
                store: new Ext.data.JsonStore({
                    url: createUrl('/bug_trackers'),
                    root: 'data',
                    fields: ['name', 'id']}),
                displayField:'name',
                valueField: 'id',
                editable: false,
                allowBlank: true,
                lazyRender: true,
                triggerAction: 'all',
                mode: 'local',
                selectOnFocus:true
            })
        );

        defaultTagsStore = new Ext.data.SimpleStore({fields: [{name: 'tag'}]});
        productsStore = new Ext.data.JsonStore({
            root: 'data',
            id: 'bug_product_id',
            fields: ['bug_product_id','bug_product_name']
        });
        productsStore.on('load', function() {
            this.filterBy(function(r) {
                return !r.get('included');
            });
        }, productsStore);

        appForm.end(); //fieldset

        // All done.
        appForm.render();

        Ext.DomHelper.insertAfter(Ext.get('projectform'), {tag:'div',
                                                           id:'product_list'});
        productsGrid = new Ext.grid.EditorGrid('product_list', {
            ds: new Ext.data.JsonStore({
                root: 'data',
                fields: ['included', 'bug_product_name', 'bug_product_id',
                         'test_area_id', 'test_area_name']
                }),
            cm: new Ext.grid.ColumnModel([{
                header: "Product name",
                dataIndex: 'bug_product_id',
                renderer: function(v) {
                    var ds = productsGrid.getDataSource();

                    var items = ds.queryBy(function(r,id) {
                        return r.get('bug_product_id') == v;
                    });
                    var rec = items.first();
                    if (rec) {
                        return rec.get('bug_product_name');
                    }
                    return '';
                },
                editor: new Ext.grid.GridEditor(new Ext.form.ComboBox({
                    displayField: 'bug_product_name',
                    valueField: 'bug_product_id',
                    typeAhead: true,
                    mode: 'local',
                    triggerAction: 'all',
                    emptyText:'',
                    selectOnFocus:true,
                    forceSelection:true,
                    fieldLabel: 'Test product',
                    allowBlank: true,
                    store: productsStore
                }))
                },{
                header: "Test area",
                dataIndex: 'test_area_name',
                editor: new Ext.grid.GridEditor(new Ext.form.ComboBox({
                    store: defaultTagsStore,
                    editable: false,
                    displayField: 'tag_text',
                    valueField: 'tag_value',
                    emptyText: '',
                    triggerAction: 'all',
                    lazyRender: true,
                    mode: 'local'
                    }))
                }]),
            selModel: new Ext.grid.RowSelectionModel(),
            clicksToEdit: 1
        });

        productsGrid.getDataSource().on('load', function() {
            this.filterBy(function(r) {
                return r.get('included');
            });
        }, productsGrid.getDataSource());

        productsGrid.enable = function() {
            var cm = this.getColumnModel();
            cm.setEditable(0,true);
            cm.setEditable(1,true);
            this.toolbar_buttons.each(function(i){
                i.enable();
            });
        };

        productsGrid.disable = function() {
            var cm = this.getColumnModel();
            cm.setEditable(0,false);
            cm.setEditable(1,false);
            this.toolbar_buttons.each(function(i){
                i.disable();
            });
        };

        productsGrid.reset = function() {
            this.getDataSource().removeAll();
        };

        productsGrid.isValid = function(b) {
            /* Parameter b doesn't do anything here, but normal
             * Ext form field objects will need it. */
            var ds = this.getDataSource();
            var ok = true;

            ds.each(function(i) {
                var v = i.get('bug_product_id');
                if ((v === 0) || Ext.isEmpty(v)) {
                    ok = false;
                    return false;
                }
            });
            return ok;
        };

        productsGrid.invalidText =
            'Please specify test products or remove empty product rows.';

        productsGrid.render();

        var gridHead = productsGrid.getView().getHeaderPanel(true);
        productsGrid.toolbar_buttons = [
            new Ext.Toolbar.Button({
                text: 'New product',
                cls: 'tarantula-btn-new',
                disabled: true,
                scope: productsGrid,
                handler : function(){
                    var ds = this.getDataSource();
                    var s = new (Ext.data.Record.create([
                        {name: 'included'},
                        {name: 'bug_product_id'},
                        {name: 'bug_product_name'},
                        {name: 'test_area_id'},
                        {name: 'test_area_name'}]))(
                        {included: true,
                         bug_product_name: '',
                         bug_product_id: '',
                         test_area_name: '',
                         test_area_id: 0});
                    ds.add(s);
                }
            }),
            new Ext.Toolbar.Button({
                text: 'Remove selected product(s)',
                cls: 'tarantula-btn-remove',
                disabled: true,
                scope: productsGrid,
                handler : function(){
                    this.stopEditing();
                    var ds = this.getDataSource();
                    var rows = this.selModel.getSelections();
                    Ext.each(rows, function(i){
                        ds.remove(i);
                    }, this);
                }})];

        productsGrid.toolbar = new Ext.Toolbar(gridHead,
                                               productsGrid.toolbar_buttons);

        // Register field, so it can be enabled/disabled with
        // (default) actions/buttons.
        appForm.registerField( 'name');
        appForm.registerField( 'description');
        appForm.registerField('library');
        appForm.registerField('test_areas');
        appForm.registerField('bug_tracker_id');

        appForm.registerField(productsGrid);

        var bugsCombo = appForm.findField('bug_tracker_id');
        bugsCombo.store.on('load', function(){
            var rec = Ext.data.Record.create([
                {name:'id'},{name:'name'}
            ]);
            this.add(new rec({id:0, name:'(None)'}));
        }, bugsCombo.store);

        bugsCombo.on('select', function() {
            var btid = this.getValue();
            if (btid > 0) {
                var params = {project_name:
                              appForm.findField('name').getValue()};
                var url = createUrl((appForm.id) ?
                                    '/projects/'+appForm.id+'/bug_trackers/'+btid+'/products/':
                                    '/bug_trackers/'+btid+'/products/');

                Ext.Ajax.request({
                    url: url,
                    params: params,
                    method: 'get',
                    success: function(r,o) {
                        var d = Ext.decode(r.responseText);
                        var ds = productsGrid.getDataSource();
                        ds.clearFilter(true);
                        ds.removeAll();
                        ds.loadData(d);

                        productsStore.clearFilter(true);
                        productsStore.removeAll();
                        productsStore.loadData(d);
                    }
                });
                btRemoved = false;

            } else {
                var ds = productsGrid.getDataSource();
                ds.clearFilter(true);
                ds.removeAll();
                productsStore.clearFilter(true);
                productsStore.removeAll();
                // Set only to true, when really removing bug tracker.
                // Otherwise it's assumed that project was already without bt.
                btRemoved = (btRemoved === false);
            }
        }, bugsCombo);

        appForm.findField('test_areas').on('change', function() {
            // Validates field, and update defaultTagsStore
            var t = this.getValue().split(',');
            // Fix odd split behaviour. If str is "" split returns [""]
            if ( (t.length == 1) && Ext.isEmpty(t[0])) {
                t = [];
            }
            var valid = true;
            Ext.each(t, function(i) {
                if (Ext.isEmpty(i)) {
                    valid = false;
                    return false;
                }
            }, this);
            if (valid) {
                defaultTagsStore.removeAll();
                var r = Ext.data.Record.create([
                    {name: 'tag_text'},
                    {name: 'tag_value'}
                ]);
                Ext.each(t, function(i) {
                    defaultTagsStore.add(new r({tag_text: i,
                                                tag_value: i}));
                }, this);
                defaultTagsStore.add(new r({tag_text: '(none)',
                                            tag_value: ''}));
            }
        }, appForm.findField('test_areas'));

        usersgrid = new Ext.grid.EditorGrid('users-grid', {

            ds: new Ext.data.JsonStore({url: createUrl('/projects/0/users'),
                                        root: '',
                                        fields: [ 'id', 'login', 'group',
                                                  'version', 'test_area' ]
                                       }),

            cm: new Ext.grid.ColumnModel([
                {
                    header: "Login",
                    width: 250,
                    dataIndex: 'login',
                    editor: new Ext.grid.GridEditor(new Ext.form.ComboBox({
                        store: appStores.find('/users').extStore,
                        displayField:'text',
                        valueField: 'text',
                        editable: false,
                        allowBlank: false,
                        lazyRender: true,
                        triggerAction: 'all',
                        mode: 'local',
                        selectOnFocus:true
                    })),
                    editable: false
                },
                {
                    header: "Role",
                    width: 250,
                    dataIndex: 'group',
                    editor: new Ext.grid.GridEditor(new Ext.form.ComboBox({
                        store: appStores.find(
                            '/users/current/available_groups').extStore,
                        editable: false,
                        displayField: 'text',
                        emptyText: 'TEST_ENGINEER',
                        triggerAction: 'all',
                        lazyRender: true,
                        mode: 'local'
                    })),
                    editable: false
                },
                {
                    header: "Forced test area",
                    dataIndex: 'test_area',
                    editor: new Ext.grid.GridEditor(new Ext.form.ComboBox({
                        store: defaultTagsStore,
                        editable: false,
                        displayField: 'tag_text',
                        valueField: 'tag_value',
                        emptyText: '',
                        triggerAction: 'all',
                        lazyRender: true,
                        mode: 'local'
                        })),
                    editable: false
                }
            ]),

            selModel: new Ext.grid.RowSelectionModel(),
            clicksToEdit: 1,
            trackMouseOver: true
        });

        usersgrid.enable = function() {
            var cm = this.getColumnModel();
            cm.setEditable(0,true);
            cm.setEditable(1,true);
            cm.setEditable(2,true);
            this.toolbar_buttons.each(function(i){
                i.enable();
            });
        };

        usersgrid.disable = function() {
            var cm = this.getColumnModel();
            cm.setEditable(0,false);
            cm.setEditable(1,false);
            cm.setEditable(2,false);
            this.toolbar_buttons.each(function(i){
                i.disable();
            });
        };

        usersgrid.reset = function() {
            this.getDataSource().removeAll();
        };

        usersgrid.isValid = function(b) {
            /* Parameter b doesn't do anything here, but normal
             * Ext form field objects will need it. */
            var ds = this.getDataSource();
            var ok = true;

            logins = [];

            ds.data.items.each(function(i) {
                // Check that each login is defined only once.
                if( logins.indexOf( i.get('login')) != -1) { ok = false;}
                logins.push( i.get('login'));

                if ((i.get('login').length === 0) ||
                    (i.get('group').length === 0)) {
                    ok = false;
                }
            });
            return ok;
        };

        usersgrid.invalidText =
            'Please specify login and role for each row. Login must not be ' +
            'added more than once to project.';

        usersgrid.render();
        appForm.registerField(usersgrid);

        gridHead = usersgrid.getView().getHeaderPanel(true);
        usersgrid.toolbar_buttons = [
            new Ext.Toolbar.Button({
                text: 'New User',
                cls: 'tarantula-btn-new',
                disabled: true,
                handler : function(){
                    var ds = usersgrid.getDataSource();
                    var s = new (Ext.data.Record.create([
                        {name: 'id'},
                        {name: 'login'},
                        {name: 'group'},
                        {name: 'test_area'}]))(
                        {login:
                         appStores.find('/users').extStore.getAt(0).data.text,
                         group: 'TEST_ENGINEER', test_area: ''});
                    ds.add(s);
                }
            }),
            new Ext.Toolbar.Button({
                text: 'Remove selected user(s)',
                cls: 'tarantula-btn-remove',
                disabled: true,
                handler : function(){

                    // Ext.Msg.confirm('Removing users',
                    //'Do you really want to remove selected users
                    //from the project?',
                    //function(btn) {
                    //if (btn == 'yes') {
                    usersgrid.stopEditing();
                    var ds = usersgrid.getDataSource();
                    var rows = usersgrid.selModel.getSelections();
                    var p = '';
                    var amp = '';
                    Ext.each(rows, function(i){
                        p += amp + 'users[]=' + i.data.id;
                        ds.remove(i);
                        amp = '&';
                    }, this);
                }})];

        usersgrid.toolbar = new Ext.Toolbar(gridHead,
                                            usersgrid.toolbar_buttons);


        view = usersgrid.getView();
        view.getRowClass = function( record, index ){
            if(record.get('deleted')) { return 'testia-grid-row-red'; }
        };

        appForm.initEnd();
        appForm.findField('bug_tracker_id').store.load();
    }

    function extendAppForm() {

        // Get values from record to form fields.
        appForm.afterLoad = function( r, options, success){

            if (!success) {return;}


            // Text fields.
            btRemoved = null;
            appForm.setValues(r[0]);
            appForm.findField('test_areas').fireEvent('change');
            var ds;
            // Bug tracker products
            appForm.findField('bug_tracker_id').fireEvent('select');

            // Assigned users
            var Record = Ext.data.Record.create([
                {name: 'login'},
                {name: 'group'},
                {name: 'test_area'}
            ]);

            ds = usersgrid.getDataSource();
            r[0].assigned_users.each(function(i) {
                if (!i.test_area_forced) {
                    i.test_area = '';
                }
                ds.add(new Record(i));
            });
        };

        // Get values from fields and return them as parameters to ajax call.
        appForm.beforeSave = function () {
            var parameters = appForm.getValues();
            var users = [];
            // Joko btRemoved === true
            //tai sitten niin että ladatessa käsitellään
            // arvon muutos eventti eri tavalla.
            if (btRemoved === true) {
                Ext.Msg.show({title: 'Warning',
                              msg: 'Removing bug tracker from'+
                              ' the project will' +
                              'clear all defect associations. Are you sure?',
                              buttons: {ok: 'Remove tracker',
                                        cancel: 'Cancel'},
                              fn: function(btn) {
                                  if (btn == 'ok') {
                                      btRemoved = false;
                                      appForm.defaultButtonSave();
                                  }
                              }
                             });
                return false;
            }

            Ext.each(usersgrid.getDataSource().data.items, function(i) {
                var u = {login: i.data.login, group: i.data.group};
                if (!Ext.isEmpty(i.data.test_area)) {
                    u.test_area = i.data.test_area;
                    u.test_area_forced = true;
                } else {
                    u.test_area_forced = false;
                }
                users.push(u);
            }, this);
            parameters.assigned_users = users;
            var products = [];
            Ext.each(productsGrid.getDataSource().data.items, function(i) {
                if (i.data.included) {
                    products.push({bug_product_id: i.data.bug_product_id,
                                   test_area_name: i.data.test_area_name});
                }
            }, this);
            parameters.bug_products = products;
            return Ext.urlEncode({data: Ext.encode(parameters)});
        };

        appForm.afterSave = function( options, success, response) {
            GUI.tagsStore.load();
            GUI.projectsStore.load();
            GUI.project_list.reload();
        };

        appForm.afterDelete = function( options, success, response) {
            GUI.project_list.reload();
            GUI.projectsStore.load();
        };
    }



    // Public space.
    return{

        // Public properties, e.g. strings to translate.

        // Public methods
        init: function(gui){

            appForm = new Ext.testia.ProjectForm('projectform','toolbar');

            appForm.ajaxResourceUrl = createUrl('/projects');

            appStores = new AppStores();
            appStores.add( '/users',
                           [ 'dbid', 'text', 'realname'],
                           {root: ''});
            appStores.add('/users/current/available_groups',
                          ['value', 'text']);
            // When all stores have been loaded, create actual form.
            appStores.load(this.onAppStoresLoad);

            // Meanwhile, define form specific handler functions.
            extendAppForm();

            gui.project_panel.show();
            gui.set_panel.hide();
            gui.case_panel.hide();
            gui.exec_panel.hide();
            gui.user_panel.show();
            gui.test_panel.hide();
            gui.requirement_panel.hide();
            gui.testobjects_panel.hide();

            gui.user_panel.collapse();
            gui.project_panel.expand();

            gui.layout.getRegion( 'west').expand();
        },

        editBugtrackers: function() {
            var d = new Ext.testia.BugtrackerDlg({
                title: 'Add bugtracker',
                scope: this,
                fn: function(b) {
                    if ( ((b == 'ok') || (b == 'delete')) && appForm) {
                        var f = appForm.findField('bug_tracker_id');
                        if (f && f.store) {
                            f.store.load();
                        }
                    }
                }
            });
        },

        onAppStoresLoad: function(){
            createForm();
        },

        // Actual public interface of this ui component.  Methods,
        // which needs to be accessible from rest of the UI are
        // declared here (i.e. from navigator).
        //
        load: function( id){
            // Loading of object triggered from rest of ui.  This
            // should return false, if loading is not allowed
            // (i.e. form is in edit mode).
            return( appForm.defaultActionLoad( id));
        },

        clear: function() {
            // Clearing of object triggered from rest of ui.  This
            // should return false, if clearing is not allowed
            // (i.e. form is in edit mode).
            return( appForm.defaultActionClear( id));
        }
    };
}();
