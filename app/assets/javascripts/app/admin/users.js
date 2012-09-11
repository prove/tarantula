var Users = function() {
    // Re-usable UI functionality is defined in AppForm class.
    var appForm;

    // Private functions.
    function createForm(){

        // When stores have been loaded, create fields on form.

        // Set field names exactly same as in web service interface;
        // It allows whole form to be sent back to server when data is
        // being saved.
        appForm.fieldset(
            { id: 'user',
              legend: 'User - Required fields marked with asterisk (*)'},

            new Ext.form.TextField({
                fieldLabel: '* Login',
                name: 'login',
                width: 175,
                isValid: function() {
                    // Remove empty spaces
                    this.setValue( this.getValue().strip());
                    if( this.getValue() === "") { return false; }
                    return true;
                },
                invalidText: 'Please enter login.'
            }),
            new Ext.form.TextField({
                fieldLabel: '* Realname',
                name: 'realname',
                width: 175,
                isValid: function() {
                    // Remove empty spaces
                    this.setValue( this.getValue().strip());
                    if( this.getValue() === "") { return false; }
                    return true;
                },
                invalidText: 'Please enter name.'
            }),
            new Ext.form.TextField({
                fieldLabel: '* Email',
                name: 'email',
                width: 175,
                isValid: function() {
                    // Remove empty spaces
                    this.setValue( this.getValue().strip());
                    if( this.getValue() === "") { return false; }
                    return true;
                },
                invalidText: 'Please enter email.'
            }),
            new Ext.form.TextField({
                fieldLabel: 'Phone',
                name: 'phone',
                width: 175,
                isValid: function() {
                    // Remove empty spaces
                    this.setValue( this.getValue().strip());
                    return true;
                }
            }),
            new Ext.form.Checkbox({
                fieldLabel: 'Admin',
                name: 'admin',
                width: 12
            }),
            new Ext.form.TextField({
                fieldLabel: 'New password',
                width: 175,
                name: 'password',
                inputType: 'password',
                value: ''
            }),
            new Ext.form.TextField({
                fieldLabel: 'Confirm password',
                width: 175,
                name: 'password_confirmation',
                inputType: 'password',
                value: ''
            })
        );

        appForm.end(); //fieldset

        appForm.end(); //fieldset

        // All done.
        appForm.render();

        // Register field, so it can be enabled/disabled with (default)
        // actions/buttons.
        appForm.registerField('login');
        appForm.registerField('realname');
        appForm.registerField('email');
        appForm.registerField('phone');
        appForm.registerField('admin');
        appForm.registerField('password');
        appForm.registerField('password_confirmation');

        appForm.initEnd();

    }

    function extendAppForm() {

        // Get values from record to form fields.
        appForm.afterLoad = function( r, options, success){

            if (!success) { return; }

            // Text fields.
            appForm.setValues(r[0]);
        };


        // Get values from fields and return them as parameters to ajax call.
        appForm.beforeSave = function () {
            var parameters = this.getValues();
            if (!parameters.admin) {
                parameters.admin= 0;
            }
            return Ext.urlEncode({data: Ext.encode(parameters)});
        };

        appForm.afterSave = function( options, success, response) {
            if( success) { GUI.user_list.reload(); }
        };

        appForm.afterDelete = function( options, success, response) {
            if( success) { GUI.user_list.reload(); }
        };
    }

    // Public space.
    return{

        // Public properties, e.g. strings to translate.

        // Public methods
        init: function(gui){

            appForm = new Ext.testia.AppForm('userform','toolbar');

            Ext.each(appForm.toolbarButtons, function(i) {
                if (i.extButton.text == 'New') {
                    i.allowedGroups = ['admin'];
                    return false;
                }
            });

            appForm.ajaxResourceUrl = createUrl('/users');

            createForm();

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

            gui.user_panel.expand();
            gui.project_panel.collapse();

            gui.layout.getRegion( 'west').expand();
        },


        // Actual public interface of this ui component.  Methods,
        // which needs to be accessible from rest of the UI are
        // declared here (i.e. from navigator).
        load: function( id){
            // Loading of object triggered from rest of ui.  This should
            // return false, if loading is not allowed (i.e. form is in
            // edit mode).
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
