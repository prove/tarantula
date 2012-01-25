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

    /*
     * ================  Simple form  =======================
     */
    var simple = new Ext.form.Form({
        labelWidth: 75, // label settings here cascade unless overridden
        url:'save-form.php'
    });
    simple.add(
        new Ext.form.TextField({
            fieldLabel: 'First Name',
            name: 'first',
            width:175,
            allowBlank:false
        }),

        new Ext.form.TextField({
            fieldLabel: 'Last Name',
            name: 'last',
            width:175
        }),

        new Ext.form.TextField({
            fieldLabel: 'Company',
            name: 'company',
            width:175
        }),

        new Ext.form.TextField({
            fieldLabel: 'Email',
            name: 'email',
            vtype:'email',
            width:175
        })
    );

    simple.addButton('Save');
    simple.addButton('Cancel');

    simple.render('form-ct');


    /*
     * ================  Form 2  =======================
     */
    var top = new Ext.form.Form({
        labelAlign: 'top'
    });

    top.column(
        {width:282}, // precise column sizes or percentages or straight CSS
        new Ext.form.TextField({
            fieldLabel: 'First Name',
            name: 'first',
            width:225
        }),

        new Ext.form.TextField({
            fieldLabel: 'Company',
            name: 'company',
            width:225
        })
    );

    top.column(
        {width:272, style:'margin-left:10px', clear:true}, // apply custom css, clear:true means it is the last column
        new Ext.form.TextField({
            fieldLabel: 'Last Name',
            name: 'last',
            width:225
        }),

        new Ext.form.TextField({
            fieldLabel: 'Email',
            name: 'email',
            vtype:'email',
            width:225
        })
    );

    top.container({},
        new Ext.form.HtmlEditor({
            id:'bio',
            fieldLabel:'Biography',
            width:550,
            height:200
        })
    );

    top.addButton('Save');
    top.addButton('Cancel');

    top.render('form-ct2');

    /*
     * ================  Form 3  =======================
     */
    var fs = new Ext.form.Form({
        labelAlign: 'right',
        labelWidth: 80
    });

    fs.fieldset(
        {legend:'Contact Information'},
        new Ext.form.TextField({
            fieldLabel: 'First Name',
            name: 'first',
            width:190
        }),

        new Ext.form.TextField({
            fieldLabel: 'Last Name',
            name: 'last',
            width:190
        }),

        new Ext.form.TextField({
            fieldLabel: 'Company',
            name: 'company',
            width:190
        }),

        new Ext.form.TextField({
            fieldLabel: 'Email',
            name: 'email',
            vtype:'email',
            width:190
        }),

        new Ext.form.ComboBox({
            fieldLabel: 'State',
            hiddenName:'state',
            store: new Ext.data.SimpleStore({
                fields: ['abbr', 'state'],
                data : Ext.exampledata.states // from states.js
            }),
            displayField:'state',
            typeAhead: true,
            mode: 'local',
            triggerAction: 'all',
            emptyText:'Select a state...',
            selectOnFocus:true,
            width:190
        }),

        new Ext.form.DateField({
            fieldLabel: 'Date of Birth',
            name: 'dob',
            width:190,
            allowBlank:false
        })
    );

    fs.addButton('Save');
    fs.addButton('Cancel');

    fs.render('form-ct3');

    /*
     * ================  Form 4  =======================
     */
    var form = new Ext.form.Form({
        labelAlign: 'right',
        labelWidth: 75
    });

    form.column({width:342, labelWidth:75}); // open column, without auto close
    form.fieldset(
        {legend:'Contact Information'},
        new Ext.form.TextField({
            fieldLabel: 'Full Name',
            name: 'fullName',
            allowBlank:false,
            value: 'Jack Slocum'
        }),

        new Ext.form.TextField({
            fieldLabel: 'Job Title',
            name: 'title',
            value: 'Jr. Developer'
        }),

        new Ext.form.TextField({
            fieldLabel: 'Company',
            name: 'company',
            value: 'Ext JS'
        }),

        new Ext.form.TextArea({
            fieldLabel: 'Address',
            name: 'address',
            grow: true,
            preventScrollbars:true,
            value: '4 Redbulls Drive'
        })
    );
    form.fieldset(
        {legend:'Phone Numbers'},
        new Ext.form.TextField({
            fieldLabel: 'Home',
            name: 'home',
            value: '(888) 555-1212'
        }),

        new Ext.form.TextField({
            fieldLabel: 'Business',
            name: 'business'
        }),

        new Ext.form.TextField({
            fieldLabel: 'Mobile',
            name: 'mobile'
        }),

        new Ext.form.TextField({
            fieldLabel: 'Fax',
            name: 'fax'
        })
    );
    form.end(); // closes the last container element (column, layout, fieldset, etc) and moves up 1 level in the stack

    
    form.column(
        {width:202, style:'margin-left:10px', clear:true}
    );

    form.fieldset(
        {id:'photo', legend:'Photo'}
    );
    form.end();

    form.fieldset(
        {legend:'Options', hideLabels:true},
        new Ext.form.Checkbox({
            boxLabel:'Ext 1.0 User',
            name:'extuser',
            width:'auto'
        }),
        new Ext.form.Checkbox({
            boxLabel:'Ext Commercial User',
            name:'extcomm',
            width:'auto'
        }),
        new Ext.form.Checkbox({
            boxLabel:'Ext Premium Member',
            name:'extprem',
            width:'auto'
        }),
        new Ext.form.Checkbox({
            boxLabel:'Ext Team Member',
            name:'extteam',
            checked:true,
            width:'auto'
        })
    );

    form.end(); // close the column

    
    form.applyIfToFields({
        width:230
    });

    form.addButton('Save');
    form.addButton('Cancel');

    form.render('form-ct4');

    // The form elements are standard HTML elements. By assigning an id (as we did above)
    // we can manipulate them like any other element
    var photo = Ext.get('photo');
    var c = photo.createChild({
        tag:'center', 
        cn: {
            tag:'img',
            src: 'http://extjs.com/forum/image.php?u=2&dateline=1175747336',
            style:'margin-bottom:5px;'
        }
    });
    new Ext.Button(c, {
        text: 'Change Photo'
    });
});