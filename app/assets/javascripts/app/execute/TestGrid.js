/**
 * Manages left part of test execution screen (case execution grid
 * displayed in infopanel).
 *
 * Should interface only CaseExecute which in turn
 * communicates with main GUI.
 *
 * Responsible for loading and displaying case execution plan
 * and results. Routes grid row selection events to CaseExecute.js
 * to load/display/save actual case execution results.
 *
 * TODO:
 * Handle execution design changes (reload current execution)
 * Make sure executions are reset whenever screen is opened from ui.
 *
 */
var TestGrid = function() {

    /**
   * Maximum number of latest executions available for selecting
   * in combobox.
   */
    var MAX_EXECUTIONS = 20000;

    // reference to main GUI component.
    var gui;

    // ExtJs panel. Component is rendered to panel's body element.
    var panel;

    /**
   * ExtJs grid component for displaying cases.
   */
    var grid;

    /**
   *  ExtJs combobox for selecting execution.
   */
    var combo;
    var executionChanging;

    /**
   * ExtJs store for all executions of current project.
   * Displayed in combobox.
   * (Re)loaded when test execution view is opened.
   */
    var executionsStore;

    /**
   * ExtJs store for all users of current project.
   * Displayed in grid (to display login instead of user_id).
   * (Re)loaded when test execution view is opened.
   */
    var usersStore;

    /**
   * ExtJs store for cases of selected execution.
   * Displayed in grid.
   * Reloaded on combobox item selection.
  */
    var casesStore;


    /**
   * Flag indicating if grid is already configured to display
   * current execution.
  */
    var gridConfigured;

    return {

     /*
     * Set up ExtJs components and event handlers.
     */
        init: function( panel_, gui_) {

            panel = panel_;
            gui = gui_;

            // Executions store.
            executionsStore = new Ext.data.JsonStore({
                url: createUrl(
                    '/projects/current/users/current/executions?not_completed=1&max=' +
                        MAX_EXECUTIONS),
                root: 'data',
                fields: [
                    {name: 'id'},     // Case execution id
                    {name: 'name'}
                ],
                id: 'id'
            });

            // Refresh executions if project is changed.
            gui.on('projectchanged', function() {
                    executionsStore.load();
                }, this);

            executionsStore.load();

            // Users store.
            usersStore = new Ext.data.JsonStore({
                url: createUrl('/projects/current/users'),
                //root: 'data',
                fields: [
                    {name: 'user_id', mapping: 'dbid'},
                    {name: 'login', mapping: 'text'}
                ]
            });

            usersStore.load();

            // Execution selection combobox.
            combo = new Ext.form.ComboBox({
                store: executionsStore,
                displayField:'name',
                valueField: 'id',
                editable: true,
                forceSelection: true,
                lazyRender: true,
                triggerAction: 'all',
                emptyText:'(select execution)',
                mode: 'local',
                fieldLabel: '* Select execution (required)',
                selectOnFocus:true
            });


            // After is selected, load cases (store).
            combo.on('select', function() {
                executionChanging = true;
                // Create closure, which will be run as a call back
                // CaseExecute.ajaxSaveCaseExecution to make sure that
                // old results are saved before new exution is loaded.
                var f = function() {
                    // Cases grid needs to reconfigured.
                    gridConfigured = false;
                    casesStore.load();
                    executionChanging = false;
                };
                // Clear screens, but keep combovalue.
                CaseExecute.clear(true, f.createDelegate(this));

            });

            // Cases store.
            casesStore = new Ext.data.JsonStore({
                // Get execution to load from combobox.
                url: function() {
                    return createUrl('/executions/' + combo.getValue() +
                                     '/case_executions');},
                fields: [
                    {name: 'id'},                         // Case execution id
                    {name: 'position'},
                    {name: 'case_id'},
                    {name: 'title'},
                    {name: 'assigned_to'},
                    {name: 'result'},
                    {name: 'history'},
                    {name: 'duration'},
                    {name: 'priority'}
                ],
                id: 'id'
            });

            casesStore.on( 'beforeload', function() {
                //Ext.Msg.wait( 'Waiting for server response');
            });

            casesStore.on( 'load', function() {
                //Ext.Msg.wait( 'Rendering user interface');

                // Handler is bit complex and involves also grid,
                // so do not define it here.
                TestGrid.onCasesStoreLoad();
            });

            // Cases grid.
            grid = new Ext.grid.EditorGrid( panel.body, {

                ds: casesStore,
                // Configure gridview to maintain scrollbar positions
                // through refreshes.
                view: new Ext.grid.GridView({
                    onLoad: Ext.emptyFn,
                    getRowClass: function(record, index) {
                        return "priority_"+record.get('priority');
                    },
                    listeners: {
                        beforerefresh: function(v) {
                            v.scrollTop = v.scroller.dom.scrollTop;
                        },
                        refresh: function(v) {
                            v.scroller.dom.scrollTop = v.scrollTop;
                        }
                    }
                }),

                cm: new Ext.grid.ColumnModel([
                    {
                        header: "#",
                        width: 30,
                        dataIndex: 'position',
                        editable: false
                    },
                    {
                        header: "Case",
                        dataIndex: 'title',
                        editable: false,
                        width: 150
                    },
                    {
                        header: "Assigned to",
                        editable: false,
                        dataIndex: 'assigned_to',
                        width: 80,
                        renderer:
                        CommonStores.findStore(ALL_USERS_STORE).renderer
                    },
                    {
                        header: "R",
                        dataIndex: 'result',
                        editable: false,
                        width: 30,
                        renderer: function(v) {
                            d = '';
                            switch(v ? v.ui || v : null) {
                            case 'PASSED':
                                d= '<img src="' + IMG_PASSED +
                                    '" title="Passed" />';
                                break;
                            case 'FAILED':
                                d= '<img src="' + IMG_FAILED +
                                    '" title="Failed" />';
                                break;
                            case 'SKIPPED':
                                d= '<img src="' + IMG_SKIPPED +
                                    '" title="Skipped" />';
                                break;
                            case 'NOT_IMPLEMENTED':
                                d= '<img src="' + IMG_NOT_IMPLEMENTED +
                                    '" title="Not implemented" />';
                                break;
                            }
                            return d;
                        }
                    },
                    {
                        header: "History",
                        dataIndex: 'history',
                        editable: false,
                        width: 70,
                        renderer: function(v,meta,rec) {
                            var html = '';
                            if (v[0] && (v[0].id == rec.get('id'))) {
                                v.shift();
                            } else if (v.length == 4) {
                                v.pop();
                            }
                            Ext.each(v, function(h) {
                                switch(h.result) {
                                case 'PASSED':
                                    html += '<img src="' + IMG_PASSED;
                                    break;
                                case 'FAILED':
                                    html += '<img src="' + IMG_FAILED;
                                    break;
                                case 'SKIPPED':
                                    html += '<img src="' + IMG_SKIPPED;
                                    break;
                                case 'NOT_IMPLEMENTED':
                                    html += '<img src="' + IMG_NOT_IMPLEMENTED;
                                    break;
                                }
                                html += '" title="' + h.execution_name +
                                    (h.test_object_name ? ':' + h.test_object_name : '') + '"/>';
                            }, this);
                            return html;
                        }
                    },
                    {
                        header: "Duration",
                        editable: true,
                        dataIndex: 'duration',
                        width: 55,
                        align: "right",
                        editor: new Ext.grid.GridEditor(
                            new Ext.form.TextField({})),
                        renderer: function(v) {
                            if(typeof v == 'number') {
                                return v.toDurationString();
                            } else if (typeof v == 'string'){
                                return parseInt(v,10).toDurationString();
                            } else {
                                return "";
                            }
                        }
                    }
                ]),

                selModel: new Ext.grid.RowSelectionModel({
                    singleSelect: true
                }),
                clicksToEdit: 1,
                trackMouseOver: true,
                stripeRows: false,

                // For some strange reason
                // following settings combined with accordion
                // panel height adjustment code causes
                // height of grid to be set (almost) correctly.
                // Note that height/maxHeight must be specified as functions
                // for settings to work, direct values do not work.
                // Also leaving values unspecified don't work.

                // Update 2008-06-19 Specifying height/maxheight as function
                // fungerar inte med IE. Switching back to fixed values for
                // time being. Autoresizing is needed.
                autoHeight: true,

                height: 550, //function() {return 100;}
                maxHeight: 550 //function() {return 100;}
            });

            grid.on('afteredit', function(e) {
                Ext.Ajax.request({
                    url: createUrl('/case_executions/' + e.record.get('id')),
                    method: 'put',
                    params: Ext.urlEncode({
                        data: Ext.encode({
                            duration: parseInt(e.record.get('duration'), 10),
                            step_executions: []
                        })
                    }),
                    success: function() {
                        casesStore.commitChanges();
                    }
                });
            }, this);

            grid.render();

            // Create toolbar and add combo for selecting execution.
            var gridHead = grid.getView().getHeaderPanel(true);
            grid.toolbar = new Ext.Toolbar(gridHead);


            grid.toolbar.addButton(new Ext.Toolbar.Button({
                //text: 'Export',
                icon: IMG_EXPORT,
                iconCls: 'x-btn-text-icon',
                tooltip: 'Export',
                tooltipType: 'title',
                handler: function() {
                    var exec_id = combo.getValue();
                    if (Ext.isEmpty(exec_id)) {
                        return;
                    }
                    var dEl = Ext.get('downloadIframe') || Ext.DomHelper.append(
                        document.body, {tag:'iframe', id:'downloadIframe',
                                        style:'display:none'}, true);
                    dEl.set({src:createUrl('/executions/'+exec_id+'.csv')});
                }
            }));
            grid.toolbar.addButton(new Ext.Toolbar.Button({
                //text: 'Import',
                icon: IMG_IMPORT,
                iconCls: 'x-btn-text-icon',
                tooltip: 'Import',
                tooltipType: 'title',
                handler: function() {
                    var exec_id = combo.getValue();
                    if (Ext.isEmpty(exec_id)) {
                        return;
                    }
                    var d = new Ext.testia.CSVImportDialog({
                        url: createUrl('/executions/'+exec_id),
                        callback: function() {
                            combo.fireEvent('select');
                        }
                    });
                }
            }));
            grid.toolbar.addButton(new Ext.Toolbar.Button({
                icon: IMG_REFRESH,
                iconCls: 'x-btn-text-icon',
                handler: this.refreshGridAndStore
            }));

            grid.toolbar.add(combo);


            // On grid selection, load case into test screen.
            // This event includes some more complex logic,
            // so not defined here.
            grid.getSelectionModel().on( 'rowselect', TestGrid.onRowSelect);
            gui.on('navigatorresized', function(height) {
                grid.maxHeight = height;
                grid.autoSize();
            }, this);


        },

        /**
        * Eventhandler for LayoutRegion's 'resized' event.
        * This listener is added by GUI to LayoutRegion.
        */
        resize: function( newWidth) {
            grid.autoSize();
            //combo.setSize( newWidth - 30, combo.getSize().height);
            // Quickfix
            combo.setSize( newWidth - 70, combo.getSize().height);
        },

        /**
        * EventHandler for cases store load.
        * Cases store is (re)loaded when execution is changed
        * (to load cases from new, different url),
        * or when case grid is refreshed (new execution results).
        */
        onCasesStoreLoad: function() {
            if( !gridConfigured) {

                // Configure grid to display selected execution.
                grid.reconfigure( casesStore, grid.getColumnModel() );
                // Select first row ( this will also launch eventhandler to
                // display case and steps)
                grid.getSelectionModel().selectFirstRow();

                gridConfigured = true;
            } else {

                // Cases store and grid was refreshed.
                // Reselect row which was selected before refresh.

                // Id of the case to be selected is stored into
                // grid.selectAfterLoad
                // First locate matching record from store, and
                // create array from it
                // ....
                records = [casesStore.getById( grid.selectAfterLoad)];

                if( grid.selectAfterLoad) {
                    // .... which can then be fed to selectRecords method.
                    grid.getSelectionModel().selectRecords(records);
                }
            }

            //Ext.Msg.hide();

        },

        /**
        * For navigation buttons in CaseExecute
        */
        prevCase: function() {
            grid.getSelectionModel().selectPrevious();
        },

        /**
        * For navigation buttons in CaseExecute
        */
        nextCase: function() {
            // Small usability environment:
            // If we are already in last case,
            // notify user and save current case
            // execution.
            //
            // (rowselect event does not fire,
            // if we are already in last case,
            // and user presses 'next').
            //
            //
            // Is last row selected?
            if (TestGrid.isLastCaseSelected()){
                // Reselect last case, which causes
                // case execution to be saved and reloaded.
                CaseExecute.reloadCase();

                // Do we actually need notification?
                /*
                Ext.Msg.show({
                    title:'No more cases',
                    msg: 'No more cases',
                    buttons: Ext.Msg.OK,
                    width: 400
                });
                */
            } else {
                grid.getSelectionModel().selectNext();
            }
        },

        /**
        * Is last case in grid currently active?
        **/
        isLastCaseSelected: function() {
            return grid.getSelectionModel().isSelected(
                casesStore.getCount() - 1 );
        },

        /**
        * Reloads store to refresh grid view to current case execution results.
        * Because grid loses current selection on refresh, it is stored
        * into grid.selectAfterLoad property.
        *
        * This is currently called after new case execution has
        * been saved/loaded
        * by CaseExecute.js.
        *
        */
        refreshGridAndStore: function() {

            // Reload also executions.
            // These should be actually updated automatically/periodically
            executionsStore.reload();

            // Is there really a execution displayed?
            if (! (gridConfigured && combo.getValue())){
                return false;
            }

            record = grid.getSelectionModel().getSelected();
            if( record) {
                grid.selectAfterLoad = record.get('id');
            }
            casesStore.reload();
        },


        /**
        * Resets case grid.
        * Execution selection combobox value is cleared and
        * list of available executions refreshed.
        * Case list is cleared.
        * Called by CaseExecute.clear();
        *
        * @param {Boolean/Number} keepExecutionComboValue
        * Do no clear selected execution from combobox or
        * refresh executions store if param is interpreted as true.
        * If it's number combobox value will be set to that.
        */
        clear: function(keepExecutionComboValue) {

            if( !keepExecutionComboValue){
                executionsStore.reload();
                combo.setRawValue(null);
            } else if (typeof keepExecutionComboValue === 'number') {
                combo.setValue(keepExecutionComboValue);
                combo.fireEvent('select');
            }

            casesStore.removeAll();

            gridConfigured = false;
            //grid.destroy();
        },


        /**
        * Set single case execution result in store.
        * This allows setting single case after execution instead
        * of loading all results from server.
        */
        setCaseExecutionResult: function( caseExecutionId, result, duration,
                                        progress) {

            r = casesStore.getById( caseExecutionId);
            if( r) {
                r.set( 'duration', duration);
            }

            // Setting value seems to cause loss of record handle,
            // so get it again....
            r = casesStore.getById( caseExecutionId);
            if( r) {
                r.set( 'result', result);
            }

            // Temporary solution:
            // Display current progress in execution name in combobox.
            if (!executionChanging) {
                var execRecord = executionsStore.getById( combo.getValue());

                execRecord.set( 'name', progress);


                combo.setRawValue( progress);

                // 'Commit' just to remove those modified marks on grid.
                casesStore.commitChanges();
            }
        },

        /**
        * Event handler for grid row selection.
        * Starts event chain, which first saves current case execution
        * (CaseExecute.js) if needed, loads selected new case execution and
        * updates store and grid.
        *
        * This actually gets called twice when user selects row.
        * First time when user selects, and then second time after
        * case executions store has been reloaded [onCasesStoreLoad()]
        */
        onRowSelect: function(selectionModel, rowIndex, record) {

            // Check if selected case execution is already displayed.
            // Without this, we would end in forever loop
            // Case execution load ->
            // row reselection in onCasesStoreLoad() ->
            // Case execution load ....

            if( !CaseExecute.isCaseExecution(combo.getValue(),
                  record.get('id'))) {
                CaseExecute.loadCase( combo.getValue(), record.get('id'));
            }
        }
    };
}();
