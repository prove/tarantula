
var MainContentTools = function() {
  return {
    htmlContent: function() {
      return('<div id="form"></div>');
    }
  };
}();

var DoorsImport = function() {
    var appForm;

    function createForm() {

        // Set field names exactly same as in web service interface;
        // It allows whole form to be sent back to server when data is
        // being saved.
        appForm.fieldset(
            {legend: 'Doors Import'},

            new Ext.form.TextField({
                fieldLabel: 'Import file',
                name: 'file',
                allowBlank:false,
                inputType: 'file',
                blankText: 'Please select import file.'
            }),

            new Ext.form.TextField({
                fieldLabel: 'Tag imported data with',
                name: 'tags',
                width: "30%"
            }),

            new Ext.form.TextField({
                fieldLabel: 'Import sublevels',
                name: 'sublevels',
                width: "30%"
            }),

            new Ext.form.Checkbox({
                fieldLabel: 'Do not create requirement from top level, use them as requirements tags instead',
                name: 'toplevel_tags'
            }),

            new Ext.form.Checkbox({
                fieldLabel: 'Create cases and test sets from new requirements',
                name: 'create_cases'
            }),

            new Ext.form.Checkbox({
                fieldLabel: 'Simulate import',
                name: 'simulate'
            })
        );

        appForm.end(); //column

        appForm.end(); //fieldset


        appForm.render();

        appForm.initEnd();
    }

    function extendAppForm() {
        appForm.afterSave = function() {
            GUI.requirement_list.reload();
        };
    }

    return {

        init: function(gui) {
            appForm = new Ext.testia.ImportForm('form','toolbar',{
                url: createUrl('/import/doors')
            });

            // Init form, i.e. create actual extjs form.
            //appForm.initStart();
            createForm();
            extendAppForm();
            gui.project_panel.hide();
            gui.set_panel.hide();
            gui.case_panel.hide();
            gui.exec_panel.hide();
            gui.user_panel.hide();
            gui.test_panel.hide();

            gui.layout.getRegion( 'west').collapse();
        },

        clear: function() {
            return true;
        }

    };
}();
