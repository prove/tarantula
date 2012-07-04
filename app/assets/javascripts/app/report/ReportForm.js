Ext.namespace("Ext.testia");
/**
 * Ext.testia.ReportForm extension class for Ext.testia.AppForm
 *
 * @class Ext.testia.ReportForm
 * @extend Ext.testia.BaseReportForm
 *
 * Extend basic AppForm by adding copy button, and default handler
 * for that.
 */
Ext.testia.ReportForm = function(form_div, toolbar_div, config) {
    Ext.testia.ReportForm.superclass.constructor.call(this,
                                                      form_div,
                                                      toolbar_div, config);

    this.itemList = new Ext.ux.ListPanel('item_selection', {
        treeUrl: createUrl('/projects/current/test_objects/'),
        itemUrl: createUrl('/projects/current/test_objects/'),
        ddGroup:'report-item-selection',
        cmenuEnabled: false,
        searchEnabled: false,
        deletedFolder: false,
        tagging: false,
        toggleSelection: true,
        toolbarEnabled: false,
        cls: 'testobjects-list'
    });

    GUI.on("testareachanged", this.onProjectChange, this);
    GUI.on("projectchanged", this.onProjectChange, this);
};

Ext.extend(Ext.testia.ReportForm, Ext.testia.BaseReportForm, {
    itemList: undefined,

    onProjectChange: function() {
        this.itemList.reset();
        this.itemList.reload();
    },

    generate: function(parameters) {
        var items = [];
        Ext.each(this.itemList.selectedItems,
                 function(i) {
                     items.push(i.dbid);
                 }, this);

        var values = this.getValues();
        var params = "";

        if (values.type == 'objects') {
            params = "test_object_ids=" + items.join(',');
        } else if (values.type == 'executions') {
            params = "execution_ids=" + items.join(',');
        } else {
            params = "all=1";
        }

        if (typeof parameters == 'string') {
            params = [params, parameters].join('&');
        }

        Ext.testia.ReportForm.superclass.generate.call(this, params);
    },

    createForm: function() {
        // report mode selection
        var b1 = new Ext.form.Radio({
                                        fieldLabel: 'Selected test objects',
                                        name: 'type',
                                        inputValue: 'objects',
                                        checked: true
                                    });
        b1.on('check', function(t,v) {
                  if (v && this.itemList) {
                      var l = Ext.get('item_selection');
                      l.show();
                      l = l.child('legend');
                      l.dom.innerHTML = 'Select Test Objects';
                      this.itemList.url = createUrl(
                          '/projects/current/test_objects');
                      this.itemList.itemUrl = this.itemList.url;
                      this.itemList.reload();
                      this.itemList.el.removeClass('executions-list');
                      this.itemList.el.addClass('testobjects-list');
                  }
              }, this);

        var b2 = new Ext.form.Radio({
                                        fieldLabel: 'Selected test executions',
                                        name: 'type',
                                        inputValue: 'executions'
                                    });
        b2.on('check', function(t,v) {
                  if (v && this.itemList) {
                      var l = Ext.get('item_selection');
                      l.show();
                      l = l.child('legend');
                      l.dom.innerHTML = 'Select Executions';
                      this.itemList.url = createUrl('/executions');
                      this.itemList.itemUrl = this.itemList.url;
                      this.itemList.reload();
                      this.itemList.el.removeClass('testobjects-list');
                      this.itemList.el.addClass('executions-list');
                  }
              }, this);

        this.column({}, b1, b2);

        this.fieldset({id:'item_selection',
                       legend:'Select Test Objects'});
    },


    defaultActionClear: function(e) {
        if (e !== "projectselect") {
            GUI.un("testareachanged", this.onProjectChange);
            GUI.un("projectchanged", this.onProjectChange);
        }
        return Ext.testia.ReportForm.superclass.defaultActionClear.call(this, e);
    }

});