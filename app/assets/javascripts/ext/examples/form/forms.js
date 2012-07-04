/*
 * Ext JS Library 1.1
 * Copyright(c) 2006-2007, Ext JS, LLC.
 * licensing@extjs.com
 * 
 * http://www.extjs.com/license
 */

Ext.onReady(function(){
    Ext.QuickTips.init();

    Ext.MessageBox.alert("Warning", "This example is not done and results may vary.");

    // Change field to default to validation message "under" instead of tooltips
    Ext.form.Field.prototype.msgTarget = 'under';


    var date = new Ext.form.DateField({
        allowBlank:false
    });

    date.applyTo('markup-date');

    var tranny = new Ext.form.ComboBox({
        typeAhead: true,
        triggerAction: 'all',
        transform:'light',
        width:120,
        forceSelection:true
    });

    var required = new Ext.form.TextField({
        allowBlank:false
    });
    required.applyTo('required');

    var alpha = new Ext.form.TextField({
        vtype:'alpha'
    });
    alpha.applyTo('alpha');

    var alpha2 = new Ext.form.TextField({
        vtype:'alpha',
        disableKeyFilter:true
    });
    alpha2.applyTo('alpha2');

    var alphanum = new Ext.form.TextField({
        vtype:'alphanum'
    });
    alphanum.applyTo('alphanum');

    var email = new Ext.form.TextField({
        allowBlank:false,
        vtype:'email'
    });
    email.applyTo('email');

    var url = new Ext.form.TextField({
        vtype:'url'
    });
    url.applyTo('url');

    var grow = new Ext.form.TextArea({
        width:200, grow:true
    });
    grow.applyTo('grow');

});