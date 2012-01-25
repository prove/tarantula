/*
 * Ext JS Library 1.1
 * Copyright(c) 2006-2007, Ext JS, LLC.
 * licensing@extjs.com
 * 
 * http://www.extjs.com/license
 */

Ext.onReady(function(){

    Ext.QuickTips.init();

    // turn on validation errors beside the field globally
    Ext.form.Field.prototype.msgTarget = 'side';

    var fs = new Ext.form.Form({
        labelAlign: 'right',
        labelWidth: 95
    });

    fs.fieldset(
        {legend:'Contact Informatie'},
        new Ext.form.TextField({
            fieldLabel: 'Voornaam',
            name: 'first',
            width:190
        }),

        new Ext.form.TextField({
            fieldLabel: 'Achternaam',
            name: 'last',
            width:190
        }),

        new Ext.form.TextField({
            fieldLabel: 'Bedrijf',
            name: 'company',
            width:190
        }),

        new Ext.form.TextField({
            fieldLabel: 'E-mail',
            name: 'email',
            vtype:'email',
            width:190
        }),

        new Ext.form.ComboBox({
            fieldLabel: 'Provincie',
            hiddenName: 'state',
            store: new Ext.data.SimpleStore({
                fields: ['province'],
                data : Ext.exampledata.dutch_provinces // from dutch-provinces.js
            }),
            displayField: 'province',
            typeAhead: true,
            mode: 'local',
            triggerAction: 'all',
            emptyText:'Kies uw provincie...',
            selectOnFocus:true,
            width:190
        }),

        new Ext.form.DateField({
            fieldLabel: 'Geboorte datum',
            name: 'dob',
            width:190,
            allowBlank:false
        })
    );

    fs.addButton('Opslaan');
    fs.addButton('Annuleren');

    fs.render('form-ct');
});