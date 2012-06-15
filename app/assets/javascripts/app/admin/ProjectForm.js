Ext.namespace('Ext.testia');

/**
 * Ext.testia.ProjectForm extension class for Ext.testia.AppForm
 *
 * @class Ext.testia.ProjectForm
 * @extend Ext.testia.AppForm
 *
 * Extend basic AppForm by adding purge button for project administration.
 */
Ext.testia.ProjectForm = function(form_div, toolbar_div, config) {
    config = config || {};

    if (config.default_buttons) {
        delete(config.default_buttons);
    }

    Ext.testia.ProjectForm.superclass.constructor.call(this,
                                                    form_div,
                                                    toolbar_div, config);

    this.extToolbar.addFill();

    this.addToolbarButton( {config: {text: 'Purge', cls:'tarantula-btn-purge'},
                            enableInModes: ['read', 'edit']},
                           this.purgeProject, this);

    Ext.each(this.toolbarButtons, function(i) {
        // FIXME: Evil bubblegum-patch which breaks when localization
        // will be implemented...
        if (i.extButton.text == 'New') {
            i.allowedGroups = ['admin'];
            return false;
        }
    }, this);
};

Ext.extend(Ext.testia.ProjectForm, Ext.testia.AppForm, {
    purgeProject: function() {
        Ext.Msg.confirm("Purge project", "This will remove all resources \
placed in deleted folders. Continue?",
                        function(b, t) {
                            if (b == 'yes') {
                                Ext.Ajax.request({
                                    url: createUrl('/projects/'+this.id+
                                                   '/deleted'),
                                    method: 'delete'
                                });
                            }
                        }, this);
    }

});