// TextField implementation which fixes focus bug in Windows FF.
// more info at: http://extjs.com/forum/showthread.php?t=19299&highlight=firefox+textfield


// Changed functionality so that selection box only operates on last tag.
// IE doesn't support readily caret (cursor) location, so it is not straightforward
// to detect what tag user is currently editing.

Ext.namespace('Ext.testia');
Ext.testia.TagField = function(config) {
    config = config || {};
    config.hideTrigger = true;
    config.forceSelection = false;
    config.emptyText = '';
    config.minChars = -1;

    Ext.testia.TagField.superclass.constructor.call(this, config);

    this.onTriggerClick = function() { this.doQuery();};

    // Refresh tag store when field is enabled.
    this.on( 'enable', function() {
        // Clear any earlier filters to make sure latest choices are available.
        this.store.filter(this.displayField, '', true, true);
        this.store.load();
    }, this);

    // Do query after store is loaded.
    // This filters combobox according to last tag currently in field.
    // Otherwise all tags would be displayed, and user could
    // easily accidentally replace latest tag with something.
    this.store.on( 'load', function() {
        delete this.lastQuery;
        this.doQuery();
    }, this);

};

Ext.extend(Ext.testia.TagField, Ext.testia.Combo, {
    dropTarget: undefined,
    ddGroup: undefined,

    getTagsArray: function( ){
        // Make sure that value is string.
        str = this.getRawValue() + "";
        return str.split(',');
    },

    // Trim function is not provided by IE
    trim: function( stringToTrim){
	return stringToTrim.replace(/^\s+|\s+$/g,"");
    },

    // Return last tag in trimmed format.
    getLastTag: function( ){
        var t_arr = this.getTagsArray();
        var lt = t_arr[ t_arr.length - 1];
        return this.trim( lt);
    },

    // Trim given value and replace last tag with it.
    setLastTag: function( tag){
        var t_arr = this.getTagsArray();
        t_arr[ t_arr.length - 1] = this.trim( tag);
        this.setRawValue( t_arr.join(',') + ',');
    },
    
    doQuery: function(q, forceAll) {
        if(q === undefined || q === null){
            q = '';
        }

        q = this.getLastTag();
        Ext.testia.TagField.superclass.doQuery.call(this, q, forceAll);
    },

    /* Normal ExtJS ComboBox onLoad function selects all text in the
    field if query equals to querying all items. Eg. empty query after
    typing comma in the field. That would make TagField unusable, so
    we override onLoad and remove text selection functionality. */
    onLoad: function() {

        if(!this.hasFocus){
            return;
        }
        if(this.store.getCount() > 0){
            this.expand();
            this.restrictHeight();
            if(this.lastQuery == this.allQuery){
                if(!this.selectByValue(this.value, true)){
                    this.select(0, true);
                }
            }else{
                this.selectNext();
                if(this.typeAhead && this.lastKey != Ext.EventObject.BACKSPACE && this.lastKey != Ext.EventObject.DELETE) {
                    this.taTask.delay(this.typeAheadDelay);
                }
            }
        }else{
            this.onEmptyResults();
        }
    },

    onRender: function(ct, position) {
        Ext.testia.TagField.superclass.onRender.call(this, ct, position);
        this.el.setWidth('100%');

        var notifyDrop = function(dd, e, data) {
            if (this.disabled === true) {
                return;
            }
            var tags = data.obj.parent.selectedItems.select(
                function(i) {
                    if (i.cls.search(/tag/) >= 0) {
                        return true;
                    }
                    return false;
                });
            tags = tags.map(function(i) {return i.text;});
            var s = this.getValue();
            if (!Ext.isEmpty(s)) {
                tags.unshift(s);
            }
            this.setValue(tags.join(','));
        };

        this.dropTarget = new Ext.dd.DropTarget(this.el,{
            ddGroup: this.ddGroup || 'DDGroup',
            copy: false,
            notifyDrop: notifyDrop.createDelegate(this)
        });
    },

    onSelect: function(rec) {
        // Select last tag from selection and add it to field.
        this.setLastTag( rec.data[this.displayField]);

        // Refresh choices (display all).
        this.doQuery();
    }
});