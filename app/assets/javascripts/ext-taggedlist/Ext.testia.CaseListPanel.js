Ext.namespace("Ext.testia");
/**
 * Ext.testia.ListPanel extension class
 *
 * @class Ext.testia.CaseListPanel
 * @extend Ext.testia.ListPanel
 */
Ext.testia.CaseListPanel = function(el, config, initial_load) {
    Ext.testia.CaseListPanel.superclass.constructor.call(this, el, config,
                                                         initial_load);

    var f = function(v) {
        return v.dbid;
    };
    if (this.itemContext) {
        this.itemContext.insert(1,
            new Ext.menu.Item({
                text:'Copy case(s)',
                //icon:createUrl('/images/famfamfam/bin.png'),
                scope: this,
                handler: function(c,e) {
                    var case_ids = this.selectedItems.filter(
                        function(i) {
                            return (i.cls.search(/item/) >= 0);
                        }
                    ).map(f);
                    this.copyItems({name:'case_ids', value:case_ids});
                }
            })
        );
    }
    if (this.tagContext) {
        this.tagContext.insert(0,
            new Ext.menu.Item({
                text:'Copy tag(s)',
                //icon:createUrl('/images/famfamfam/bin.png'),
                scope: this,
                handler: function(c,e) {
                    var tag_ids = this.selectedItems.filter(
                        function(i) {
                            return (i.cls.search(/tag/) >= 0);
                        }).map(f).concat(this.getTagIds());
                    this.copyItems({name:'tag_ids', value:tag_ids});
                }
            })
        );
    }
};

Ext.extend(Ext.testia.CaseListPanel, Ext.ux.ListPanel, {
    copyItems: function(params) {
        new Ext.testia.CopyCasesDialog(params);
    },

    deleteItems: function() {
        var case_ids = this.selectedItems.filter(
                        function(i) {
                            return (i.cls.search(/item/) >= 0);
                        }
        ).map(function(i) {return i.dbid;});
        Ext.Ajax.request(
            {url: this.itemUrl + case_ids.join(','),
             method: 'DELETE',
             scope: this,
             success: function() {this.reload();}
            });
    }
});