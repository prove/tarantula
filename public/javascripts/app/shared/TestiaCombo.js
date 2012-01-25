/*
 * @class Ext.testia.Combo
 * @extends Ext.form.ComboBox
 * Extended combobox control with typeAhead matching in the middle of the value.
 */
Ext.testia.Combo = function(config) {
    Ext.testia.Combo.superclass.constructor.call(this, config);
};

Ext.extend(Ext.testia.Combo, Ext.form.ComboBox, {

    doQuery: function(q, forceAll) {
        if(q === undefined || q === null){
            q = '';
        }
        var qe = {
            query: q,
            forceAll: forceAll,
            combo: this,
            cancel:false
        };
        if(this.fireEvent('beforequery', qe)===false || qe.cancel){
            return false;
        }
        q = qe.query;
        forceAll = qe.forceAll;
        if(forceAll === true || (q.length >= this.minChars)){
            if(this.lastQuery !== q){
                this.lastQuery = q;
                if(this.mode == 'local'){
                    this.selectedIndex = -1;
                    if(forceAll){
                        this.store.clearFilter();
                    }else{
                        // Match any, ignore case
                        this.store.filter(this.displayField, q, true, true);
                    }
                    this.onLoad();
                }else{
                    this.store.baseParams[this.queryParam] = q;
                    this.store.load({
                        params: this.getParams(q)
                    });
                    this.expand();
                }
            }else{
                this.selectedIndex = -1;
                this.onLoad();
            }
        }
    },

    onTypeAhead: function() {
        var nodes = this.view.getNodes();
        for(var i=0,il=nodes.length; i<il; ++i) {
            var n = nodes[i];
            // getRecord(node) is available for DataView class in ext2 -->
            // http://extjs.com/deploy/dev/docs/source/DataView.html#method-Ext.DataView-getRecord
            // using this.store.getAt(i) should provide right results.
            //var d = this.view.getRecord( n ).data;
            var d = this.store.getAt(i).data;
            var re = new RegExp('(.*?)(' + this.getRawValue() + ')(.*)', 'i');
            var h = d[this.displayField];
            h = h.replace( re, '$1<span class="mark-combo-match">$2</span>$3' );
            n.innerHTML = h;
        }
    }
});