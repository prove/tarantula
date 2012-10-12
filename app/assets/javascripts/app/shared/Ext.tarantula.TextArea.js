Ext.namespace("Ext.tarantula");

/**
 * Ext.tarantula.TextArea extends basic Ext.form.TextArea by adding
 * support to render urls as links.
 *
 * Ext.tarantula.TextArea updates additional div containing html
 * rendered version of textarea's content. Urls are replaced with a
 * -tags when rendered as html.
 *
 * HTML rendered content is shown only when textarea itself is
 * disabled. Enable and disable methods take care of showing correct
 * elements. Content is updated when textarea is changed.
 *
 * @class Ext.tarantula.TextArea
 * @extend Ext.form.TextArea
 */
Ext.tarantula.TextArea = function(config) {
    var cfg = config || {};

    Ext.tarantula.TextArea.superclass.constructor.call(this, config);

    this.on('change', this.renderReadonlyContent, this);
};

Ext.extend(Ext.tarantula.TextArea, Ext.form.TextArea, {
    /**
     * @cfg {Boolean} grow True if this field should automatically
     * grow and shrink to its content
     */
    grow: true,

    /**
     * Returns content of the text area. Multiple whitespaces are
     * stripped from the end and beginning.
     */
    getValue: function() {
        var v = Ext.tarantula.TextArea.superclass.getValue.call(this);
        return v.strip();
    },

    /**
     * Generate readonly content in addition to basic TextArea's
     * setValue functionality
     */
    setValue: function(v) {
        Ext.tarantula.TextArea.superclass.setValue.call(this, v);
        this.renderReadonlyContent();
    },


    /**
     * Hides textarea and displays the readonly content with properly
     * rendered links.
     */
    disable: function() {
        Ext.tarantula.TextArea.superclass.disable.call(this, arguments);
        if (this.readonlyEl) {
            this.el.hide();
            this.readonlyEl.show();
        }
        return this;
    },

    /**
     * Show textarea and hide readonly content
     */
    enable: function() {
        Ext.tarantula.TextArea.superclass.enable.call(this, arguments);
        if (this.readonlyEl) {
            this.readonlyEl.hide();
            this.el.show();
        }
        return this;
    },

    renderReadonlyContent: function() {
        var content = this.getValue().renderAsHTML();

        if (!this.readonlyEl) {
            this.readonlyEl = this.container.createChild({
                cls: 'tarantula-textarea-readonly',
                content: content}, this.getEl());
            this.readonlyEl.setVisibilityMode(Ext.Element.DISPLAY);
            this.el.setVisibilityMode(Ext.Element.DISPLAY);
        } else {
            this.readonlyEl.update(content, false);
        }
    }

});