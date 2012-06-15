Ext.namespace('Ext.testia');

Ext.testia.MainContent = function(gui,formEl, toolbarEl, dialog) {
    this.mainGui = gui;
    this.titleToolbar = new Ext.Toolbar(toolbarEl || 'toolbar');
    if (!dialog) {
        gui.maincontent.setContent(this.htmlContent());
    }
};

Ext.testia.MainContent.prototype = {
    appForm: undefined,
    mainGui: undefined,
    titleToolbar: undefined,

    clear: function(e){
        // Called when user want's to change view to another.
        // Should return true and clear view, when it is ok to clear view.
        if (this.appForm && this.appForm.defaultActionClear) {
            return this.appForm.defaultActionClear(e);
        }
        return true;
    },

    load: function(id){
        // Loading of object triggered from rest of ui.
        // This should return false, if loading is not allowed (i.e. form is in
        // edit mode).
        if (this.appForm) {
            return this.appForm.defaultActionLoad(id);
        }
        return null;
    },

    htmlContent: function() {
        return('<div id="form"></div>');
    }
};