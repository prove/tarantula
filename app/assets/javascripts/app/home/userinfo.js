Ext.namespace('Ext.testia');

Ext.testia.MainContentUser = function(gui) {
    Ext.testia.MainContentUser.superclass.constructor.call(this,gui);

    this.appForm = new Ext.testia.AppForm('form','toolbar',
        {default_buttons: false});

    this.appForm.ajaxResourceUrl = createUrl('/users');

    this. appForm.addToolbarButton({
        config: {text: 'Edit', cls:'tarantula-btn-edit'},
        enableInModes: ['read']
    }, this.appForm.defaultButtonEdit, this.appForm);

    this.appForm.addToolbarButton({
        config:{text:'Save', cls:'tarantula-btn-save'},
        enableInModes: ['new','edit']
    }, this.appForm.defaultButtonSave, this.appForm);

    this.appForm.addToolbarButton({
        config:{text:'Cancel', cls:'tarantula-btn-cancel'},
        enableInModes: ['new', 'edit']
    }, this.appForm.defaultButtonCancel, this.appForm);

    this.createForm();
    this.extendAppForm();
    this.appForm.defaultActionLoad('current');

    gui.project_panel.hide();
    gui.set_panel.hide();
    gui.case_panel.hide();
    gui.exec_panel.hide();
    gui.user_panel.hide();
    gui.test_panel.hide();
    gui.requirement_panel.hide();
    gui.testobjects_panel.hide();
};

Ext.extend(Ext.testia.MainContentUser, Ext.testia.MainContent, {
    appForm: undefined,

    createForm: function() {
        this.appForm.column({labelWidth:"30%"}); // open column, without auto close

        this.appForm.fieldset(
            {legend:'Basic information'},
            new Ext.form.TextField({
                fieldLabel: 'Name',
                name: 'realname',
                isValid: function() {
                    // Remove empty spaces
                    this.setValue( this.getValue().strip());
                    if( this.getValue() === "") { return false; }
                    return true;
                }
            }),

            new Ext.form.TextField({
                fieldLabel: 'Phone',
                name: 'phone',
                isValid: function() {
                    // Remove empty spaces
                    this.setValue( this.getValue().strip());
                    return true;
                }
            }),

            new Ext.form.TextField({
                fieldLabel: 'Email',
                name: 'email',
                vtype: 'email',
                isValid: function() {
                    // Remove empty spaces
                    this.setValue( this.getValue().strip());
                    return true;
                }
            }),

            new Ext.form.TextField({
                fieldLabel: 'New password',
                name: 'password',
                inputType: 'password',
                value: ''
            }),

            new Ext.form.TextField({
                fieldLabel: 'Confirm new password',
                name: 'password_confirmation',
                inputType: 'password',
                value: ''
            }),

            new Ext.form.TextArea({
                fieldLabel: 'Description',
                name: 'description',
                height: 200,
                grow: true,
                isValid: function() {
                    // Remove empty spaces
                    this.setValue( this.getValue().strip());
                    return true;
                }
            })
        );

        this.appForm.end(); // closes the last container element (column, layout,
                     // fieldset, etc) and moves up 1 level in the stack
        this.appForm.end();

        this.appForm.column(
            {style:'margin-left:10px', clear:true}
        );

        this.appForm.fieldset(
            {id:'users_projects',
             legend:'Projects and permissions <br/>' +
             '<div style="color:black" id="projectslist"><div>'}
        );

        this.appForm.end(); // close the column

        this.appForm.end();

        this.appForm.render();

        // Register field, so it can be enabled/disabled with (default)
        // actions/buttons.
        this.appForm.registerField( 'realname');
        this.appForm.registerField( 'email');
        this.appForm.registerField( 'phone');
        this.appForm.registerField( 'description');
        //this.appForm.registerField( 'time_zone');
        this.appForm.registerField( 'password');
        this.appForm.registerField( 'password_confirmation');

        this.appForm.initEnd();

    },

    extendAppForm: function() {
        this.appForm.beforeLoad = function( id) {
            // Load and show permissions to users projects.
            var permissionsStore = new Ext.data.JsonStore({
                url: createUrl('/users/current/permissions'),
                root: 'data',
                fields: [ 'project_name', 'group' ]
            });

            permissionsStore.load({ callback: function( r, options, success){
                var div = Ext.get('projectslist');
                div.dom.innerHTML = '';
                this.each(function(i) {
                              div.dom.innerHTML += '<p>' + i.get('project_name') + ': ' +
                                  i.get('group') + '</p>';
                          });
                }});
        };

        // Get values from record to form fields.
        this.appForm.afterLoad = function( r, options, success){

            if (!success) { return; }

            // Text fields.
            this.setValues(r[0]);
        };

        // Get values from fields and return them as parameters to ajax call.
        this.appForm.beforeSave = function () {
            return Ext.urlEncode({data: Ext.encode(this.getValues())});
        };
  }
});
