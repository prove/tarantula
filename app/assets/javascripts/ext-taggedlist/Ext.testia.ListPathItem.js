
Ext.namespace('Ext.ux');

/**
 * Ext.testia.ListPathItem extension class
 * Class for items in selected tags / path status bar.
 *
 * @class Ext.testia.ListPathItem
 * @extend Ext.util.Observable
 *
 * @constructor
 * Creates and renders new Ext.testia.ListPathItem
 * @param {String/HTMLElement/Element} el Path container element
 * @param {String/Object} config
 */
Ext.ux.ListPathItem = function(el, config) {
    config = config || {};
    if (config) {
        if (config.text) {this.text = config.text;}
        if (config.parent) {this.parent = config.parent;}
        if (config.tagId) {this.tagId = config.tagId;}
    }

    var dh = Ext.DomHelper;

    var tag = {tag:'li', children: [ {tag:'a', href:'#', children: [
        {tag:'span', html: this.text}
    ]}]};
    this.el = dh.append(el, tag, true);
    this.el.fadeIn({duration: 0.75});

    this.addEvents({"click": true});

    this.el.on("click", function(e) {
        if (this.parent.loading === false) {
            this.destroy();
        }
    }, this);

    this.el.child('a').focus();
};

Ext.extend(Ext.ux.ListPathItem, Ext.util.Observable, {
    text: '',
    tagId: 0,
    el: undefined,
    parent: undefined,

    destroy: function() {
        if (this.el) {
            this.el.fadeOut({
                endOpacity: 0, //can be any value between 0 and 1 (e.g. .5)
                easing: 'easeOut',
                duration: 0.75,
                remove: true
            });
            this.el = undefined;
        }
        this.parent.unselectTag(this);
    }
});