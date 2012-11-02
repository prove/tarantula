Ext.namespace('Ext.testia');


Ext.testia.CaseDesign = function(gui,formEl,toolbarEl,dialog) {
    Ext.testia.CaseDesign.superclass.constructor.call(this,gui, formEl, toolbarEl, dialog);

    this.appStores = new AppStores();
    this.appStores.add('/projects/current/priorities',
        [{name:'name'}, {name: 'value'}]);
    this.appStores.load();

    // Parameters are used when case appForm is rendered as popup dialog
    this.appForm = new Ext.testia.CaseForm(formEl || 'form',
                                           toolbarEl || 'toolbar', {toolbarTitle:'Case'});

    this.appForm.addToolbarButton({ config: {text: 'Add task', cls:'tarantula-btn-task'},
                                    enableInModes: ['read', 'edit']},
                                  function() {
                                      gui.taskList.addTaskPrompt({name: 'Review',
                                                                  description: 'Review case',
                                                                  resource_type: 'cases',
                                                                  resource_id: this.appForm.id});
                                  }, this);

    this.appForm.ajaxResourceUrl = createUrl('/cases');

    this.createForm();
    this.extendAppForm();
    this.copiedSteps = [];

    if (!dialog) {
        gui.case_panel.expand();
    }



    Ext.EventManager.onWindowResize(this.resizeGrid, this);
};

Ext.extend(Ext.testia.CaseDesign, Ext.testia.MainContentDesign, {
    stepsgrid: undefined,
    attachmentForm: undefined,
    appStores: undefined,
    copiedSteps: undefined,
    req_list: undefined,


    createForm: function() {
        var content = this;
        var tmpEl;
        var cblist;

        var fields = [
            {   id: 'case',
                labelSeparator: "",
                labelWidth: 190
            },

            new Ext.form.TextField({
                fieldLabel: '<span style="color:black;">Title</span> <span style="color:#ea6e04;">*</span>',
                fieldClass: 'tarantula-field-required x-form-field',
                name: 'title',
                allowBlank:false,
                isValid: function() {
                    // Remove empty spaces
                    this.setValue( this.getValue().strip());
                    if( this.getValue() === "") {
                        return false;
                    }
                    return true;
                },
                invalidText: 'Please enter name for case.'
            }),

            new Ext.form.DateField({
                fieldLabel: '<span style="color:black;">Date</span>' +
                    '<span style="color:#ea6e04;">*</span>',
                fieldClass: 'tarantula-field-required x-form-field',
                name: 'date',
                allowBlank: true,
                altFormats: "Y/m/d",
                format: 'Y-m-d'
            }),

            new Ext.form.ComboBox({
                name: 'priority',
                store: this.appStores.find('/projects/current/priorities').extStore,
                displayField:'name',
                valueField: 'name',
                editable: false,
                selectOnFocus: true,
                forceSelection: true,
                triggerAction: 'all',
                emptyText:'',
                mode: 'local',
                fieldLabel: '<span style="color:black;">Priority</span>' +
                    '<span style="color:#ea6e04;"> *</span>',
                width: 175,
                allowBlank: false,
                invalidText: 'Please select priority for case.'
            }),

            new Ext.form.TextField({
                fieldLabel: 'Planned duration (minutes)',
                name: 'time_estimate',
                width: "30%",
                isValid: function() {
                    var v = this.getValue();
                    if (isNaN(parseInt(v,10)) && !Ext.isEmpty(v)) {
                        return false;
                    }
                    return true;
                },
                invalidText: 'Please use integer values only for planned duration.'
            }),

            new Ext.form.TextField({
                fieldLabel: 'Average duration',
                name: 'average_duration',
                width: "30%",
                readOnly: true,
                cls: 'x-form-readonly'
            }),

            new Ext.testia.TagField({
                store: new Ext.data.JsonStore({
                    url: createUrl('/projects/current/tags/?taggable_type=Case'),
                    root: 'data',
                    id: 'dbid',
                    fields: ['dbid', 'text']
                }),
                mode: 'local',
                fieldLabel: 'Tags',
                displayField: 'text',
                name: 'tag_list',
                ddGroup: 'cases-group',
                // Width must be specified as pixels, percentage breaks on IE.
                width: 600
            }),


            new Ext.tarantula.TextArea({
                fieldLabel: 'Objective',
                name: 'objective'
            }),

            new Ext.tarantula.TextArea({
                fieldLabel: 'Test data',
                name: 'test_data'
            }),

            new Ext.tarantula.TextArea({
                fieldLabel: 'Preconditions & assumptions',
                name: 'preconditions_and_assumptions'
            }),

            new Ext.form.TextField({
                fieldLabel: 'Change comment',
                name: 'change_comment',
                isValid: function() {
                    if ( (content.appForm.mode != 'new') &&
                         Ext.isEmpty(this.getValue())) {
                        return false;
                    }
                    return true;
                },
                invalidText: "Enter change comment."
            })
        ];
        if (!GUI.tagsStore.getById(GUI.tagFilterCombo.getValue()).get('forced')) {
            cblist = new Ext.testia.CheckboxList({
                store: new Ext.data.JsonStore({
                    url: createUrl('/projects/current/test_areas'),
                    root: 'data',
                    id: 'dbid',
                    fields: ['dbid', 'text', 'selected', 'forced']
                }),
                displayField: 'text',
                valueField: 'dbid',
                name: 'test_area_ids',
                fieldLabel: 'Test areas'
            });
            fields.splice(5, 0, cblist);
        }
        // Set field names exactly same as in web service interface;
        // It allows whole form to be sent back to server when data is
        // being saved.
        this.appForm.fieldset.apply(this.appForm,fields);

        this.appForm.end(); //column

        this.appForm.end(); //fieldset


        this.appForm.render();

        // Register fields, so it can be enabled/disabled with
        //(default) actions/buttons.
        this.appForm.registerField( 'title');
        this.appForm.registerField( 'date');
        this.appForm.registerField('priority');
        this.appForm.registerField( 'time_estimate');
        this.appForm.registerField( 'average_duration');
        this.appForm.registerField( 'objective');
        this.appForm.registerField( 'test_data');
        this.appForm.registerField( 'preconditions_and_assumptions');
        this.appForm.registerField( 'tag_list');
        if (cblist) {
            this.appForm.registerField(cblist, 'test_area_ids');
        }
        this.appForm.registerField( 'change_comment');
        this.appForm.findField('change_comment').onInvalid = function(form, field, msg) {
            Ext.Msg.prompt(
                "Change comment missing", msg,
                function(b,t) {
                    if (b == "ok") {
                        field.setValue(t);
                        form.defaultButtonSave();
                    }
                });
        };

        tmpEl = Ext.DomHelper.append(this.appForm.el.dom.parentNode,
                                     {tag:'div', cls:'attachments'}, true);
        this.attachmentForm = new Ext.testia.AttachmentForm(tmpEl, {
            urlTemplate: createUrl('/cases/%p/attachments/%i')
        });
        this.attachmentForm.render();

        this.appForm.registerField(this.attachmentForm,'attachmentForm');


        tmpEl = Ext.DomHelper.append(this.appForm.el.dom.parentNode,{tag:'div', cls:'steps',
                                                   children: [
                                                       {tag:'div', cls:'steps-form'}
                                                   ]}, true);

        var maincontent = this;
        var eField = {
            allowBlank: false,
            grow: true,
            validateOnBlur: false,
            validationEvent: 'keyup',
            validator: function() {
                var val = this.getValue();
                var a = [];
                /* Check if value is formatted like paste from OO Calc / Excel */
                if (val.match(/([^\x09]*\x09+[^\x09\x0a\x0d]*(\x0d?\x0a\x0d?)?)+/)) {
                    a = val.split(/[\x09\x0a\x0d]+/);
                }
                if (a.length <= 1) {
                    return true;
                } else if ( (a.length % 2 == 1) && Ext.isEmpty(a.last())) {
                    a.pop();
                }
                this.setValue('');
                var g = maincontent.stepsgrid;
                var ds = g.getDataSource();
                var r = new Ext.data.Record.create(
                        [{name: 'id'},
                         {name: 'position'},
                         {name: 'action'},
                         {name: 'result'}
                        ]);
                for (var i=0,il=a.length;i<il;++i) {
                    ds.insert(g.editedRowIndex+(i/2),
                              [new r({action:a[i],
                                      result:a[++i]})]
                             );
                }

                g.stopEditing();
                ds.remove(ds.getAt(g.editedRowIndex +
                                   Math.floor(a.length/2)));
                g.update_steps_order();


                return true;
            }
        };
        this.stepsgrid = new Ext.grid.EditorGrid(tmpEl.child('div'), {
            enableColumnHide: false,
            enableColumnMove: false,
            //autoSizeColumns: true,

            ds: new Ext.data.JsonStore({
                url: '/cases/0/steps',
                root: 'steps',
                fields: [ 'id', 'position', 'action', 'result', 'version' ]
            }),

            cm: new Ext.grid.ColumnModel([
                {
                    header: '<span style="color:black">#</span>',
                 width: 23,
                 dataIndex: 'position',
                 align: 'center',
                 resizable: false,
                 sortable: false},
                {
                    header: '<span style="color:black">Action</span> <span style="color:#ea6e04;">*</span>',
                    //width: "45%",
                    width: 400,
                    dataIndex: 'action',
                    resizable: false,
                    sortable: false,
                    editor: new Ext.grid.GridEditor(new Ext.testia.StepArea(eField)),
                    renderer: function(v) {
                        var s = v.replace(/</g, '&lt;');
                        s = s.replace(/>/g, '&gt;');
                        return s.replace(/\n/g, '<br />');
                    },
                    editable: false
                },
                {
                    header: '<span style="color:black">Result</span> <span style="color:#ea6e04;">*</span>',
                    //width: "45%",
                    width: 400,
                    dataIndex: 'result',
                    resizable: false,
                    sortable: false,
                    editor: new Ext.grid.GridEditor(new Ext.testia.StepArea(eField)),
                    renderer: function(v) {
                        var s = v.replace(/</g, '&lt;');
                        s = s.replace(/>/g, '&gt;');
                        return s.replace(/\n/g, '<br />');
                    },
                    editable: false
                }
            ]),
            selModel: new Ext.grid.RowSelectionModel(),
            enableDragDrop:true,
            clicksToEdit: 2,
            trackMouseOver: true,
            //autoHeight: true,
            //maxHeight: 400
            height: 500
        });

        this.stepsgrid.enable = function() {
            this.disabled = false;
            var cm = this.getColumnModel();
            cm.setEditable(1,true);
            cm.setEditable(2,true);
            this.toolbar_buttons.each(function(i){
                i.enable();
            });
        };

        this.stepsgrid.disable = function() {
            this.disabled = true;
            var cm = this.getColumnModel();
            cm.setEditable(1,false);
            cm.setEditable(2,false);
            Ext.each(this.toolbar_buttons, function(i){
                if ( !(i.cls && (i.cls.search('tarantula-btn-copy') >= 0)) ) {
                    i.disable();
                }
            });
        };

        this.stepsgrid.reset = function() {
            this.getDataSource().removeAll();
            this.deleted_steps = [];
        };

        this.stepsgrid.update_steps_order = function() {
            var ds = this.getDataSource();
            Ext.each(ds.data.items, function(i,c) {
                i.set("position",c+1);
            });
        };

        this.stepsgrid.copySteps = function() {
            var selected = this.getSelectionModel().getSelections();
            maincontent.copiedSteps = [];
            Ext.each(selected, function(i) {
                maincontent.copiedSteps.push({
                    action: i.data.action,
                    result: i.data.result
                });
            });
        };

        this.stepsgrid.pasteSteps = function() {
            var sel = this.getSelectionModel().getSelections();
            var ds = this.getDataSource();
            var pos = 0;
            var a = maincontent.copiedSteps;
            var rec = Ext.data.Record.create([
                {name: 'id'},
                {name: 'position'},
                {name: 'action'},
                {name: 'result'}
            ]);
            if (sel && (sel.length > 0)) {
                pos = ds.indexOf(sel[0]);

                for(var i=a.length;(--i)>=0;) {
                    ds.insert(pos, new rec({position:0,
                                        action: a[i].action,
                                        result: a[i].result}
                                      ));
                }
            } else {
                Ext.each(a, function(i) {
                    ds.add(new rec({position:0,
                                    action: i.action,
                                    result: i.result}
                                  ));
                });
            }
            this.update_steps_order();
        };

        this.stepsgrid.isValid = function(b) {
            /* Parameter b doesn't do anything here, but normal
             * Ext form field objects will need it. */
            var ds = this.getDataSource();
            var ok = true;
            Ext.each(ds.data.items, function(i) {
                // Remove leading/trailing empty space
                i.data.action = i.data.action.strip();
                i.data.result = i.data.result.strip();

                ok = ((i.get('action') !== "") && (i.get('result') !== ""));
                return ok;
            });
            ok &= (ds.data.items.length > 0);
            return ok;
        };

        this.stepsgrid.invalidText = "Case must have at least one step. " +
            "Each step must have action and result specified.";

        this.stepsgrid.on('keydown', function(e) {
            if (e.ctrlKey) {
                switch(e.keyCode) {
                case 67:
                    this.copySteps();
                    break;
                case 86:
                    if (!this.disabled) {
                        this.pasteSteps();
                    }
                    break;
                }
            }
        }, this.stepsgrid);

        this.stepsgrid.on('beforeedit', function(e) {
            this.stepsgrid.editedRowIndex = e.row;
            this.stepsgrid.getSelectionModel().clearSelections();
        }, this);

        var ddrow = new Ext.dd.DropTarget(this.stepsgrid.container, {
            ddGroup : 'GridDD',
            copy:false,
            notifyDrop : function(dd, e, data){
                var ds = maincontent.stepsgrid.getDataSource();
                var rows = maincontent.stepsgrid.getSelectionModel().getSelections() || [];
                var target = ds.getAt(dd.getDragData(e).rowIndex);

                // Cannot drop unto self
                for(var i=0,il=rows.length; i<il; ++i) {
                    if( target && (rows[i].id == target.id)) {
                        return false;
                    }
                }

                // Remove records
                Ext.each(rows, function(i) {
                    ds.remove(i);
                });

                // And add them back...right where they belong
                var index = (target) ? ds.indexOf(target) : 0;
                rows.sort(function(a,b) {
                              return (b.get('position') - a.get('position'));
                          });
                ds.insert( index+1, rows);

                maincontent.stepsgrid.update_steps_order();
            }
        });

        this.stepsgrid.render();



        this.appForm.registerField(this.stepsgrid, 'stepsgrid');
        var gridHead = this.stepsgrid.getView().getHeaderPanel(true);

        this.stepsgrid.toolbar_buttons = [

            new Ext.Toolbar.TextItem("Steps"),

            new Ext.Toolbar.Button({
                text: 'New Step',
                cls:'tarantula-btn-new',
                disabled: true,
                scope: this,
                handler : function(){
                    var ds = this.stepsgrid.getDataSource();

                    var s = new (Ext.data.Record.create([
                        {name: 'id'},
                        //{name: 'version'},
                        // Version = Undefined, so we know this is
                        // client generated
                        {name: 'position'},
                        {name: 'action'},
                        {name: 'result'}
                    ]))({action: '', result: '',
                         position: ds.data.getCount()+1});

                    ds.add(s);
                }
            }),
            new Ext.Toolbar.Button({
                text: 'Delete Steps',
                cls:'tarantula-btn-delete',
                disabled: true,
                scope: this,
                handler : function(){
                    this.stepsgrid.stopEditing();
                    var ds = this.stepsgrid.getDataSource();
                    var rows = this.stepsgrid.selModel.getSelections();
                    Ext.each(rows, function(i){
                        // If this step exists in server, mark it as deleted.
                        if( i.data.id) {
                            this.stepsgrid.deleted_steps.push(i.data.id);
                        }
                        ds.remove(i);
                    }, this);
                    this.stepsgrid.update_steps_order();
                }
            }),
            new Ext.Toolbar.Button({
                text: 'Copy steps',
                cls: 'tarantula-btn-copy',
                disabled: false,
                scope: this,
                handler: function() {
                    this.stepsgrid.copySteps();
                }
            }),
            new Ext.Toolbar.Button({
                text: 'Paste steps',
                cls: 'tarantula-btn-paste',
                disabled: true,
                scope: this,
                handler: function() {
                    this.stepsgrid.pasteSteps();
                }
            })
        ];
        this.stepsgrid.toolbar = new Ext.Toolbar(gridHead,
                                            this.stepsgrid.toolbar_buttons);


        tmpEl = Ext.DomHelper.append(this.appForm.el.dom.parentNode,
                                     {tag:'div', cls:'req_list'}, true);

        this.req_list = new Ext.ux.ListPanel( tmpEl, {
             ddGroup:'requirements-group',
             cmenuEnabled: false,
             searchEnabled: false,
             deletedFolder: false,
             toolbarTitle: "Related Requirements",
             showListPath: false
         }, false);


         this.appForm.registerField(this.req_list.toolbar.addButton(
             new Ext.Toolbar.Button(
                 {text:'Remove',
                  cls:'tarantula-btn-remove',
                  scope: this,
                  handler: function() {
                      this.req_list.removeSelected();
                  }
                 })
         ));

         this.appForm.registerField(this.req_list, 'req_list');

        this.appForm.initEnd();
    },

    extendAppForm: function() {
        var content = this;
        // Get values from record to form fields.
        this.appForm.afterLoad = function( r, options, success){

            if (!success) { return; }

            // Text fields.
            r[0].average_duration = r[0].average_duration.toDurationString();
            this.setValues(r[0]);

            // Steps
            var Record = Ext.data.Record.create([
                {name: 'id'},
                {name: 'version'},
                {name: 'position'},
                {name: 'action'},
                {name: 'result'}
            ]);

            var ds = this.registered.stepsgrid.getDataSource();
            Ext.each(r[0].steps, function(i) {
                ds.add(new Record(i));
            });

            // Load requirements
            var list = this.registered.req_list;
            list.url = createUrl('/cases/' + this.id + '/requirements');
            list.itemUrl = list.url;
            list.reload();

            var optionals = r[0].optionals;
            Ext.DomHelper.useDom = false;
            var table = Ext.DomQuery.selectNode('#form form table.optional tbody');
            if (table) {
                Ext.get(table).clearContent();
            } else {
                table = Ext.DomHelper.append(Ext.get('form').child('form'), {
                    tag: 'table', cls:'optional', children: [
                        {tag:'tbody'}]}, true).child('tbody');
            }
            if (optionals) {
                for (i in optionals) {
                    if (typeof i != 'function') {
                        Ext.DomHelper.append(table, {
                            tag:'tr',
                            children: [
                                {tag:'th', html:i},
                                {tag:'td', html:optionals[i]}
                            ]
                        });
                    }
                }
            }

            this.registered.attachmentForm.load(this.id);
        };

        // Get values from fields and return them as parameters to ajax call.
        this.appForm.beforeSave = function () {

            // Create object from values and turn it to json string.
            obj = this.getValues(false, function(f) {return !f.readOnly;});

            // Create case objects from grid values
            var steps = [];
            items = this.registered.stepsgrid.getDataSource().data.items;
            for(var i=0; i<items.length; i++) {
                step = {};

                if( items[i].data.version !== undefined){
                    step.id = items[i].data.id;
                    step.version = items[i].data.version;
                } else {
                    step.id = null;
                }

                step.position = items[i].data.position;
                step.action = items[i].data.action;
                step.result = items[i].data.result;

                steps[i] = step;
            }
            obj.steps = steps;

            // Requirements
            var requirements = [];
            this.registered.req_list.items.each(function(n) {
                requirements.push( n.dbid);
            });
            obj.requirements = requirements;

            parameters = Ext.urlEncode( {data: Ext.encode(obj)});

            return parameters;
        };

        // Get values from fields and return them as parameters to ajax call.
        this.appForm.afterSave = function( options, success, response) {
            var cid = Ext.decode(response.responseText);
            this.registered.attachmentForm.upload(cid);
            content.mainGui.case_list.reload();
        };

        this.appForm.afterDelete = function ( options, success, response) {
            content.mainGui.case_list.reload();
        };

        this.appForm.beforeNew = function() {
            this.registered.attachmentForm.resetContent();
        };

        this.appForm.beforeReset = function() {
            var list = this.registered.req_list;
            list.url = null;
            list.itemUrl = null;
        };

        this.appForm.afterNew = function() {
            var ds = content.stepsgrid.getDataSource();

            var s = new (Ext.data.Record.create([
                        {name: 'id'},
                        //{name: 'version'},
                        // Version = Undefined, so we know this is
                        // client generated
                        {name: 'position'},
                        {name: 'action'},
                        {name: 'result'}
                    ]))({action: 'Dummy action', result: 'Dummy result',
                         position: ds.data.getCount()+1});

            ds.add(s);
        };
    },

    clear: function() {
        // Clearing of object triggered from rest of ui.
        // This should return false, if clearing is not allowed
        // (i.e. form is in edit mode).
        ret = this.appForm.defaultActionClear( id);
        if (ret) {
            Ext.EventManager.removeResizeListener(this.resizeGrid,this);
            this.attachmentForm.resetContent();
        }
        return ret;
    },

    resizeGrid: function(nw, nh) {
        if (!this.stepsgrid || !this.stepsgrid.el || !this.stepsgrid.el.dom) {
            return;
        }
        var h = nh - this.stepsgrid.el.dom.top;
        this.stepsgrid.maxHeight = h;
        this.stepsgrid.height = h;
    }
});
