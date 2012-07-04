// -*- encoding: utf-8 -*-

/**
 * @class DashboardRenderer
 * Renders dashboard items from json.
 * @constructor
 * @param {Ext.testia.GUI} gui Reference to main gui object.
 */
var DashboardRenderer = function() {

    return {
        render: function(el, response, mgr) {
            if (Ext.isEmpty(response.responseText.trim())) {
                return;
            }

            Ext.DomHelper.useDom = true;
            if (mgr.rep) {
                mgr.rep.setData(response.responseText);
            } else {
                mgr.rep = new Report(response.responseText);
            }
            mgr.rep.render(el);
        }
    };
}();


Ext.namespace('Ext.testia');

Ext.testia.MainContentHome = function(gui) {
    Ext.testia.MainContentHome.superclass.constructor.call(this,gui);
    this.startDashboard();

    gui.project_panel.hide();
    gui.requirement_panel.hide();
    gui.set_panel.hide();
    gui.case_panel.hide();
    gui.exec_panel.hide();
    gui.user_panel.hide();
    gui.test_panel.hide();

    gui.layout.getRegion('west').collapse();

    this.testObjectCombo = new Ext.form.ComboBox({
        store: new Ext.data.JsonStore({
            url: createUrl("/projects/current/users/current/test_object"),
            id: 'id',
            fields: ['name', 'id', 'selected'],
            root: 'data'
        }),
        width: 150,
        displayField: 'name',
        valueField: 'id',
        mode: 'local',
        selectOnFocus: true,
        lazyRender: true,
        editable: false,
        allowBlank: false,
        triggerAction: 'all'
    });

    this.testObjectCombo.on('select', function() {
                Ext.Ajax.request({
                    url: createUrl("/projects/current/users/current/test_object"),
                    method: 'put',
                    params: {test_object_id: this.testObjectCombo.getValue()},
                    scope: this,
                    callback: function() {
                        this.startDashboard();
                    }
                });
            }, this);

    this.testObjectCombo.store.on('load', function(s, r) {
        Ext.each(r, function(i) {
            if (i.get('selected')) {
                this.testObjectCombo.setValue(i.get('id'));
                return false;
            }
        }, this);
    }, this);

    gui.on('projectchanged', this.refreshTestObjects, this);
    gui.on('testareachanged', this.refreshTestObjects, this);

    this.titleToolbar.addText('Dashboard');
    this.titleToolbar.addSeparator();
    this.titleToolbar.addText("Test Object");
    this.titleToolbar.add(this.testObjectCombo);
    this.testObjectCombo.store.load();
};

Ext.extend(Ext.testia.MainContentHome, Ext.testia.MainContent, {
    mgr: undefined,
    testObjectCombo: undefined,
    update_id: undefined,
    update_delay: 500,

    onComplete:  function(el, s, o) {
        if (this.update_delay < 20000) {
            this.update_delay *= 2;
        } else {
            this.update_delay = 500;
        }
        if (Ext.isEmpty(o.responseText.trim())) {
            this.update_id = this.updateDashboard.defer(this.update_delay,this);
        }
    },

    updateDashboard: function() {
        if (this.mgr) {
            this.mgr.update(createUrl('/report/dashboard'), null,
                            this.onComplete.createDelegate(this));
        }
    },

    refreshTestObjects: function() {
        this.testObjectCombo.reset();
        this.testObjectCombo.store.load();
        this.startDashboard();
    },

    startDashboard: function() {
        if (this.mgr) {
            this.stopDashboard();
        }

        var main_div = Ext.get('monitor_boxes');
        main_div.clearContent();
        var el = Ext.DomHelper.append(main_div,
                     {tag:'div', cls:'dashboard_item'}, true);
        this.mgr = el.getUpdateManager();

        this.mgr.setRenderer(DashboardRenderer);
        // Disable loading indicator
        this.mgr.showLoading = function() {};
        this.updateDashboard();
    },


    stopDashboard: function() {
        // Stop all update managers from the front page and remove
        // associated DOM elements.
        if (!this.mgr) {
            return;
        }
        if (this.update_id) {
            clearTimeout(this.update_id);
        }
        if (this.mgr.isUpdating()) {
            this.mgr.abort();
        }

        if (Ext.isIE) {
            this.mgr.el.clearContent(); // to safely remove flash objects when using IE
        }
        this.mgr.el.remove();
    },

    clear: function(event){
        // Called when user want's to change view to another.
        // Should return true and clear view, when it is ok to clear view.
        this.stopDashboard();
        this.mgr = null;
        if (event !== 'projectselect') {
            this.mainGui.un('projectchanged', this.refreshTestObjects, this);
            this.mainGui.un('testareachanged', this.refreshTestObjects, this);
        }
        return true;
    },

    htmlContent: function() {
        return('<div id="monitor_boxes"></div>');
    }
});

