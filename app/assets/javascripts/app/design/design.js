Ext.namespace('Ext.testia');

Ext.testia.MainContentDesign = function(gui, formEl, toolbarEl, dialog) {
    Ext.testia.MainContentDesign.superclass.constructor.call(this,gui,formEl,toolbarEl,dialog);


    if (!dialog) {
        gui.project_panel.hide();
        gui.set_panel.show();
        gui.case_panel.show();
        gui.exec_panel.show();
        gui.requirement_panel.show();
        gui.testobjects_panel.show();
        gui.user_panel.hide();
        gui.test_panel.hide();

        gui.layout.getRegion( 'west').expand();

        gui.testobjects_panel.collapse();
        gui.set_panel.collapse();
        gui.case_panel.collapse();
        gui.exec_panel.collapse();
        gui.requirement_panel.collapse();
    }
};

Ext.extend(Ext.testia.MainContentDesign, Ext.testia.MainContent, {
    appForm: undefined,
    appStores: undefined,

    htmlContent: function() {
        return('<div id="form"></div><!-- Divs for casedesign -->' +
               '<div id="cases_in_set"></div>' +
               '</br> <!-- IE7 FIX for #313 -->' +
               '<div id="cases-grid"></div>');
    },

    clear: function() {
        return this.appForm.defaultActionClear();
    }
});
