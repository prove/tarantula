
Ext.namespace('Ext.ux');

/**
 * Ext.testia.ListItem extension class
 *
 * @class Ext.testia.ListItem
 * @extend Ext.util.Observable
 *
 * @constructor
 * Creates new Ext.testia.ListItem
 * @param {String/HTMLElement/Element} el The container element for this panel
 * @param {String/Object} config
 * @param {String} pos 'after', 'before' - position where new nodes are
 * inserted
 * @target {Object} Insert item after/before this item
 */
Ext.ux.ListItem = function(el, config, pos, target) {
    if (config) {
        Ext.applyIf(this, config);
        if (config.flags) {
            this.flags = config.flags;
        } else {
            this.flags = [];
        }
    }

    var dh = Ext.DomHelper;
    Ext.DomHelper.useDom = false;

    var tag = {tag:'li', cls: this.cls, children: [
        {tag:'a', href:'#', children: [ {tag:'span', html: this.text}]}
    ]};
    if (this.flags.length > 0) {
        tag.children.unshift({tag:'div', cls:'flags', children: []});
        Ext.each(this.flags, function(i) {
            if (i.flag_type == 'review') {
                tag.children[0].children.push({
                    tag:'img', src:IMG_REVIEW, title:i.comment});
            }
        }, this);
    }
    if (target) {
        if (pos == 'before') {
            this.el = dh.insertBefore(target.el, tag, true);
        } else {
            this.el = dh.insertAfter(target.el, tag, true);
        }
    } else if (pos == 'before') {
        this.el = dh.insertFirst(el, tag, true);
    } else {
        this.el = dh.append(el, tag, true);
    }
    this.el.setVisibilityMode(Ext.Element.DISPLAY);

    this.addEvents({
        "click": true,
        "contexmenu": true
    });
    this.el.on("click", function(e) {
        this.parent.fireEvent('itemselect', this, e);
        this.parent.fireEvent('click', this, e);
        if (this.el) {
            this.el.child('a').focus();
        }
    }, this);
    this.el.on("contextmenu", function(e) {
        this.parent.fireEvent('contextmenu', this, e);
        e.stopEvent();
    }, this);
    if (Ext.isIE) {
        this.el.dom.onselectstart = function() {return false;};
    }

  // Initialize dnd
  Ext.dd.Registry.register(this.el.id,{
      obj: this,
      handles: [this.el.child('a span')],
      isHandle: true
  });

    Ext.DomHelper.useDom = true;

};

Ext.extend(Ext.ux.ListItem, Ext.util.Observable, {
    dbid: undefined,
    cls: undefined,
    text: undefined,
    tags: undefined,
    offset: 0, // from which list offset this item was loaded
                       // used to restore proper scrolling position
                       // after list reload.
    leaf: undefined,
    el: undefined,
    parent: undefined,
    position: 0,
    dd: undefined,
    dz: undefined,
    selected: undefined,

    flags: undefined, // []

    destroy: function() {
        if (this.el) {
            Ext.dd.Registry.unregister(this.el.id);
            this.el.remove();
            this.el = undefined;
        }
    },

    delete_from_db: function() {
        Ext.Ajax.request({
            url: this.parent.itemUrl + this.dbid,
            method: 'DELETE',
            scope: this,
            success: function() {this.parent.reload();}
        });
    },

    select: function() {
        this.selected = true;
        this.el.addClass('x-listpanel-selected');
    },

    unselect: function() {
        this.selected = false;
        this.el.removeClass('x-listpanel-selected');
    },

    tag_with: function(tags) {
        Ext.Ajax.request({
            url: createUrl('/projects/current/tags'),
            method: 'post',
            params: Ext.urlEncode({data: Ext.encode({
                type: this.parent.url.match(/\/([^\/]*)\/?$/)[1],
                tags: tags,
                items: [this.dbid]
            })}),
            scope: this,
            success: function() {this.parent.reload();}
        });
    }
});
