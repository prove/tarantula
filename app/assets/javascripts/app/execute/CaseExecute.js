Ext.namespace("Ext.testia");
Ext.testia.ExecuteTB = function(container, buttons, config){
    Ext.testia.ExecuteTB.superclass.constructor.call(this, container, buttons, config);
};

Ext.extend(Ext.testia.ExecuteTB, Ext.Toolbar, {
    disable: function() {
        this.items.each(function(i) {
                     if (i.disable) {
                         i.disable();
                     }
                 });
    },

    enable: function() {
        this.items.each(function(i) {
                     if (i.enable) {
                         i.enable();
                     }
                 });
    }
});

/**
 * Manages right part of test execution screen (actual case execution).
 * Responsible for loading/displaying/saving of case execution results.
 *
 * Operates on single case execution.
 *
 * Main interface between Test Execution and rest of GUI.
 *
 */
var CaseExecute = function() {

    /**
    * Number of steps to display before and after currently selected step.
    */
    // No need to limit anymore, as there is more screen space available?
    var DISPLAY_STEPS = 1000;

    /**
    * Number of characters to display from comment or defect. Rest is
    * available asm ouse-over tooltip.
    */
    var DISPLAY_COMMENT_LENGTH = 10;
    var DISPLAY_DEFECT_LENGTH = 10;

    /**
    * ExtJs content panels for displaying case and steps information
    */
    var caseCP;
    var stepsCP;

    /**
    * ExtJs toolbars
    */
    var casesTb;
    var stepsTb;

    /**
    * Navigation keys
    */
    var keymap;

    /**
    * ExtJs buttons
    */
    var btnPass;
    var btnFail;
    var btnSkip;
    var btnNotImplemented;
    var btnClear;

    /**
    * All information needed for single case execution.
    * (Versioned case data, steps, results and comments).
    * Evaluated directly to object from JSON provided by server.
    */
    var caseExecution;


    /**
    * Bug tracker data
    */
    var bugtracker;

    /**
    * Id of execution to which currently executed case belongs.
    * Case execution is identified by execution id and case id
    * not by actual case execution id.
    */
    var executionId;
    var caseId;

    // Execution version.
    // If execution version is changed in midst of testing session,
    // view needs to be refreshed.
    var executionVersion;


    /**
    * Indicates if current case execution has been modified by user.
    * If case execution has been modified, it will be saved before
    * loading another case execution.
    */
    var isDirty;
    // Id for possibly on going save transaction.
    var saveTransaction;

    /**
    * Index of current active step (within caseExecution.steps object).
    */
    var activeStepIndex;


    // For calculating time spend executing case.
    // Timer is reset on case execution load.
    // Time spent is sent to server on case execution
    // save. Time is only reported, if there has been
    // modifications to case execution (e.g. step
    // result has been changed, or comments/defect modified).

    // Array of time spans to be able to support multiple pauses
    // during execution. ie: [[s1, e1], [s2, e2], [s3, e3]]
    var executionTimer = [];


    /**
    * Initiates ajax request to load case execution.
    * After succesful load result (JSON) is evaluated to
    * caseExecution private property and onCaseExecutionLoad
    * eventHandler is launched.
    */
    function ajaxLoadCaseExecution(executionId, caseId){
        Ext.Ajax.request({
            url: createUrl('/executions/'+executionId+'/case_executions/' +
                           caseId),
            method: 'get',
            scope: CaseExecute,
            success: function(response, options) {
                caseExecution = Ext.decode(response.responseText).data[0];
                this.onCaseExecutionLoad();
            }
        });
    }

    /**
    * Saves current case execution (step execution results and comments).
    * IsDirty flag is cleared.
    *
    * Updates result of case execution (returned by server) to case
    * execution grid.
    *
    * Results can also be saved step-by-step by providing stepIndex.
    *
    * @param {Function} callback Optional callback to be called after
    * save request.
    * @param {Integer} stepIndex Optional stepIndex, if only one step is saved
    *
    */
    function ajaxSaveCaseExecution(executionId, caseId, callback, stepIndex) {

        // Create object for data to be sent to server
        var data = {duration: CaseExecute.executionDuration()};

        // Extract step information from CaseExecution
        // (send only relevant information back to server).
        if (stepIndex) {
            var step = caseExecution.steps[stepIndex];
            data.step_executions = [{id: step.id,
                                     result: step.result,
                                     comment: step.comment,
                                     bug: step.bug}];
        } else {
            data.step_executions = caseExecution.steps.map(
                function(e) {
                    return {id: e.id,
                            result: e.result,
                            comment: e.comment,
                            bug: e.bug};
                });
        }

        saveTransaction = Ext.Ajax.request({
            url: createUrl('/executions/' + executionId +
                           '/case_executions/' + caseId),
            method: 'put',
            params: Ext.urlEncode( {data: Ext.encode(data)}),
            scope: CaseExecute,
            success: function(response, options) {
                // Server responds with
                // case execution id, case execution result and
                // execution version
                var r = Ext.decode(response.responseText).data[0];


                // Lets update case execution result directly to grid.

                // Small hack here; we use update execution name to reflect
                // progress of execution (coverage).
                // Later this should be changed to return real
                // progress information and display it in proper place.
                TestGrid.setCaseExecutionResult( r.id, r.result, r.duration,
                                                 r.execution);

                isDirty = false;
                if (callback) {
                    callback();
                }
            }
        });
    }

    /**
    * Display total number of passed/failed/skipped.
    * Not used atm., needs to be updated for new implementation.
    */
    function updateCasesContent() {

        cPassed = 0;
        cFailed = 0;
        cSkipped = 0;
        cNotRun = 0;

        // Count statistics from execution
        for (var i=0,il=cases.length; i<il; ++i) {
            switch(cases[i].result) {
            case 'PASSED':
                cPassed += 1;
                break;
            case 'FAILED':
                cFailed += 1;
                break;
            case 'NOT_IMPLEMENTED':
                cSkipped += 1;
                break;
            default:
                cNotRun += 1;
            }
        }

        html = '<table style="width:100%;">';
        html += '<tr><th>#</th><th>&nbsp;&nbsp;&nbsp;&nbsp;' +
            '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</th>';
        html += '<th style="width: 100%;">Case &nbsp;&nbsp;' +
            '&nbsp;&nbsp;&nbsp; CASES:' + cases.length;
        html += '&nbsp;&nbsp; PASSED:' + cPassed;
        html += '&nbsp;&nbsp; FAILED:' + cFailed;
        html += '&nbsp;&nbsp; NOT IMPLEMENTED:' + cSkipped;
        html += '&nbsp;&nbsp; NOT RUN:' + cNotRun;
        html += '</th></tr>';

        html += '</table>';
        casesCP.setContent( html);
    }

    /**
    * Update case content panel (general case information)
    * from caseExecution object.
    */
    function updateCaseContent() {

        html = '<table class="tarantula-execution">';

        html += '<tr>';
        html += '<td class="header" colspan="2">';
        html +=  caseExecution.title;
        html += '</td>';
        html += '</tr>';

                if (caseExecution.tags.length > 0) {
                        html += '<tr><td colspan="2">TAGS: '+caseExecution.tags+'</td></tr>'
                }

        if( caseExecution.objective) {
            html += '<tr>';
            html += '<td class="label">';
            html += 'Objective';
            html += '</td>';
            html += '<td class="data">';
            if( caseExecution.objective) {
                html += caseExecution.objective.renderAsHTML();
            }
            html += '</td>';
            html += '</tr>';
        }


        if( caseExecution.test_data) {
            html += '<tr>';
            html += '<td class="label">';
            html += 'Test data';
            html += '</td>';
            html += '<td class="data">';
            if( caseExecution.test_data) {
                html += caseExecution.test_data.renderAsHTML();
            }
            html += '</td>';
            html += '</tr>';
        }

        if( caseExecution.preconditions_and_assumptions) {
            html += '</tr>';
            html += '<td class="label">';
            html += 'Preconditions and assumptions';
            html += '</td>';
            html += '<td class="data">';
            if( caseExecution.preconditions_and_assumptions) {
                html += caseExecution.preconditions_and_assumptions
                    .renderAsHTML();
            }
            html += '</td>';
            html += '</tr>';
        }

        html += '<tr id="attachments-row" style="display:none;">';
        html += '<td class="label">';
        html += 'Attachments';
        html += '</td>';
        html += '<td class="data">';
        html += '<table id="attachments"><tbody></tbody></table>';
        html += '</td>';
        html += '</tr>';

        html += '</table>';

        caseCP.setContent( html);

        Ext.Ajax.request({
            url: createUrl('/case_executions/'+caseId+'/attachments/'),
            method: 'get',
            scope: this,
            success: function(r) {
                var data = Ext.decode(r.responseText);
                if (data.length > 0) {
                    var tableEl = Ext.get('attachments').child('tbody');
                    Ext.each(data, function(i) {
                        Ext.DomHelper.append(tableEl, {tag:"tr", children: [{
                            tag:"td", children: [{
                                tag:"a", href: createUrl(i.url),
                                html: i.name, target:'_blank'
                            }]
                        }]});
                    }, this);
                    var rowEl = Ext.get('attachments-row');
                    rowEl.setDisplayed( true);
                }
            }
        });


    }

    /**
    * Update steps content panel (current status of test execution)
    * from caseExecution object.
    */
    function updateStepsContent() {


        // Set comment on combobox (is this right place?)
        //comment = comments[ 's' + steps[activeStepIndex].id];
        //commentsCombo.setRawValue( comment )

        toggleStepButtons();


        var show_bug_url = '';
        if (bugtracker) {
            show_bug_url = createUrl('/projects/current/bugs/');
        }

        // Display only specified number of cases around active case
        var firstDisplayed = activeStepIndex - DISPLAY_STEPS;
        if (firstDisplayed < 0) { firstDisplayed = 0;}

        var lastDisplayed = firstDisplayed + DISPLAY_STEPS * 2;
        if (lastDisplayed >= caseExecution.steps.length) {
            lastDisplayed = caseExecution.steps.length - 1;
            firstDisplayed = lastDisplayed - DISPLAY_STEPS * 2;
            if (firstDisplayed < 0) { firstDisplayed = 0; }
        }



        html = '<table class="tarantula-execution-steps">';

        html += '<tr>';
        html += '<th style="text-align:center">#</th>';
        html += '<th>Action</th>';
        html += '<th>Expected Result</th>';
        html += '<th>Result</th>';
        html += '<th>History</th>';
        html += '<th>Defect</th>';
        html += '<th>Comment</th>';
        html += '</tr>';


        // Table row for each step
        for (var i=firstDisplayed; i<=lastDisplayed; i++) {

            // Mark current case with special css style ( <tr class="current">)
            if( activeStepIndex == i) {
                c = 'tarantula-execution-step-current';
            } else {
                // Alternate row background color.
                // Use modulo operator to determine which rows to
                // highlight with different color.
                if( (i % 2) === 0) {
                    c = 'tarantula-execution-step-alternate';
                } else {
                    c = '';
                }
            }

            html += '<tr onClick="CaseExecute.setActiveStep(' + i +
                ')" class="' + c + '" id="step-'+ i  +'">';

            // Step order number.
            html += '<td class="tarantula-execution-steps-ordinal">' +
                (i + 1) + '</td>';

            // Action.
            html += '<td>';
            if( caseExecution.steps[i].action) {
                html +=
                caseExecution.steps[i].action.escapeHTML().replace(
                        /\n/g, '<br>');
            }
            html += '</td>';

            // Expected result
            // NOTE: result is available from property "stepresult".
            html += '<td>';
            if( caseExecution.steps[i].stepresult) {
                html += caseExecution.steps[i].stepresult.escapeHTML().replace(
                        /\n/g, '<br>');
            }
            html += '</td>';

            // Result
            html += '<td style="text-align: center">';
            var res = caseExecution.steps[i].result;
            if (res) {
                switch(res) {
                case 'PASSED':
                    html += '<img src="' + IMG_PASSED + '" title="Passed" />';
                    break;
                case 'FAILED':
                    html += '<img src="' + IMG_FAILED + '" title="Failed" />';
                    break;
                case 'SKIPPED':
                    html += '<img src="' + IMG_SKIPPED +
                        '" title="Skipped" />';
                    break;
                case 'NOT_IMPLEMENTED':
                    html += '<img src="' + IMG_NOT_IMPLEMENTED +
                        '" title="Not implemented" />';
                    break;
                }
            }
            html += '</td>';

            // History
            html += '<td  style="width: 55px">';
            Ext.each(caseExecution.steps[i].history, function(h) {
                var img;
                var bug = null;
                if (h.bug && h.bug.name) {
                    bug = h.bug.name;
                }
                switch(h.result) {
                case 'PASSED':
                    img = '<img src="' + IMG_PASSED +
                        '" title="' + h.test_object + (h.comment ?
                                                       ':' + h.comment : '') +
                        '"/>';
                    break;
                case 'FAILED':
                    img = '<img src="' + IMG_FAILED +
                        '" title="' + h.test_object + (h.comment||bug ?
                                                       ':' : '') +
                        (h.comment || '') + (h.comment && bug ? ', ' : '') +
                        (bug || '') + '"/>';
                    break;
                case 'SKIPPED':
                    img = '<img src="' + IMG_SKIPPED +
                        '" title="' + h.test_object +
                        (h.comment || bug ? ':' : '') +
                        (h.comment || '') + (h.comment && bug ? ', ' : '') +
                        (bug || '') + '"/>';
                    break;
                case 'NOT_IMPLEMENTED':
                    img = '<img src="' + IMG_NOT_IMPLEMENTED +
                        '" title="' + h.test_object +
                        (h.comment || bug ? ':' : '') +
                        (h.comment || '') + (h.comment && bug ? ', ' : '') +
                        (bug || '') + '"/>';
                    break;
                }
                if (h.bug && h.bug.id) {
                    html += '<a  class="tarantula-execution-step" href="'+
                        show_bug_url+h.bug.id + '" target="_blank">'+img+'</a>';
                } else {
                    html += img;
                }
            }, this);

            html += '</td>';

            // Defect
            var str = '';
            var bug = caseExecution.steps[i].bug;
            if (bug) {
                str = bug.name;
            }

            html += '<td>';
            html +=
            '<a href="#" class="steps step_'+
                i + ' tarantula-execution-step">';
            html += '<img src=' + IMG_DEFECT +
                ' title="Edit Defect" style="vertical-align: bottom;" /></a>';
            if (!Ext.isEmpty(str)) {
                html += '&nbsp;&nbsp;<a href="'+show_bug_url+bug.id+'" target="_blank">'+
                    str+'</a>';
            }
            html += '</td>';

            // Commment.
            // Display only some few first letters of
            // comment due lack of space.
            str = caseExecution.steps[i].comment;

            if(!str) { str = '';}
            str = str.replace(/\n/g, "<br />");

            html += '<td>';
            html += '<a  class="tarantula-execution-step" href="#" '+
                'onClick="CommentDialog.show(' + i +
                ')">';
            html += '<img src=' + IMG_COMMENT +
                ' title="Edit Comment" style="vertical-align: bottom;" />';
            html += str;
            html += '</a>';
            html += '</td>';

            // End of step
            html += '</tr>';
        }

        html += '<tr>';
        html += '<th style="text-align:center" colspan="7">End of Case</th>';
        html += '</tr>';



        html += '</table>';
        stepsCP.setContent( html);
        var links = Ext.DomQuery.select("#exec_steps_list a.steps");
        Ext.each(links, function(i) {
            var index = i.className.match(/step_([0-9]+)/)[1];
            Ext.get(i).on("click", function() {
                DefectDialog.show(index,caseExecution);
            }, this);
        }, this);

    }

    /**
    * Toggle pass/fail/skip buttons according to result of current step.
    */
    function toggleStepButtons() {

        // Disabled for while, because of missing gfx elements (toggled button)
        return;

        btnPass.toggle( false);
        btnFail.toggle( false);
        btnSkip.toggle( false);
        btnNotImplemented.toggle(false);

        switch( caseExecution.steps[activeStepIndex].result) {
        case 'PASSED':
            btnPass.toggle( true);
            break;
        case 'FAILED':
            btnFail.toggle( true);
            break;
        case 'SKIPPED':
            btnSkip.toggle( true);
            break;
        case 'NOT_IMPLEMENTED':
            btnNotImplemented.toggle( true);
            break;
        }
    }


    return {
        /**
        * Called from main GUI when user activates test execution.
        * Creates content panels and other extjs components.
        * Content is hidden initially and is displayed only after user
        * selects some execution and case from Test Grid.
        *
        * Resets also TestGrid component.
        *
        */
        init: function(gui, objId) {
            // Get bugtracker to be used for tracker links.
            Ext.Ajax.request({
                url: createUrl('/projects/current'),
                method: 'get',
                scope: this,
                success: function(r,o) {
                    var p = Ext.decode(r.responseText).data[0];
                    if (p.bug_tracker_id) {
                        Ext.Ajax.request({
                            url: createUrl('/bug_trackers/'+
                                           p.bug_tracker_id),
                            method: 'get',
                            scope: this,
                            success: function(r,o) {
                                bugtracker = Ext.decode(r.responseText).data;
                            }
                        });
                    }
                }
            });
            executionId = objId;
            // Called from inside.rhtml when this test execution screen is
            // activated.
            // Hide content (and toolbars...) until some execution is loaded.
            CaseExecute.hideExecution();

            // Create toolbar and add default buttons
            casesTb = new Ext.testia.ExecuteTB("toolbar");
            casesTb.addField(new Ext.Toolbar.TextItem("Case Execution"));

            casesTb.addButton({
                text: 'Add task',
                cls:'tarantula-btn-note',

                handler: function() {
                    if (!caseExecution) {
                        return;
                    }
                    gui.taskList.addTaskPrompt({
                        name: 'Review',
                        description: 'Review case',
                        resource_type: 'cases',
                        resource_id: caseExecution.case_id});
                },
                scope: this});

            casesTb.addButton({
                text: 'Edit case',
                cls: 'tarantula-btn-edit',
                handler: function() {
                    var cb = function() {
                        var d = new Ext.testia.DesignDialog(
                            gui, Ext.testia.CaseDesign);
                        d.content.attachmentForm.on('uploadcomplete', function() {
                            // Clear grid and refresh list of available executions.
                            TestGrid.refreshGridAndStore();
                            CaseExecute.loadCase(executionId, caseId);
                        }, this);
                        d.load(caseExecution.case_id, caseExecution.id, executionId);
                    };
                    // Save test execution status, before editing case
                    if (isDirty) {
                        ajaxSaveCaseExecution(executionId, caseId, cb.createDelegate(this));
                    } else {
                        cb.call(this);
                    }
                },
                scope: this
            });

            casesTb.addButton({
                text: 'Remove case execution',
                cls: 'tarantula-btn-delete',
                handler: function() {
                    Ext.Ajax.request({
                        url: createUrl('/executions/'+executionId+'/case_executions/'+caseId),
                        method: 'delete',
                        success: function() {
                            TestGrid.refreshGridAndStore();
                            if (!TestGrid.isLastCaseSelected()) {
                                TestGrid.nextCase.apply(CaseExecute);
                            } else {
                                TestGrid.prevCase.apply(CaseExecute);
                            }
                        }
                    });
                },
                scope: this
            });

            casesTb.addSpacer();

            caseCP = new Ext.ContentPanel("exec_case", {
                fitToFrame: true
                //autoScroll: true
            });


            stepsCP = new Ext.ContentPanel("exec_steps_list", {
                fitToFrame: true
                //autoScroll: true
            });

            //casesTb.addButton( {text: 'Comment Case'});

            stepsTb = new Ext.testia.ExecuteTB("exec_steps_tb");




            stepsTb.addField(new Ext.Toolbar.TextItem("Case"));

            stepsTb.addButton( {text: 'Prev',
                                cls:'tarantula-btn-prev',
                                handler: TestGrid.prevCase,
                                scope: CaseExecute });

            stepsTb.addSeparator();

            stepsTb.addButton( {text: 'Next',
                                cls:'tarantula-btn-next',
                                handler: TestGrid.nextCase,
                                scope: CaseExecute });



            stepsTb.addField(
                new Ext.Toolbar.TextItem(
                    '<span style="padding-left:30px">&nbsp;</span>Step')
            );

            btnPass = stepsTb.addButton({
                text: 'Pass',
                cls:'tarantula-btn-pass',
                handler: function() {
                    // Move also to next step when passing step.
                    this.setStepResult('PASSED', true);
                },
                scope: CaseExecute
                //,enableToggle: true
            });

            btnFail = stepsTb.addButton({
                text: 'Fail',
                cls:'tarantula-btn-fail',
                handler: function() {
                    this.setStepResult('FAILED', false);
                },
                scope: CaseExecute
                //,enableToggle: true
            });

            btnSkip = stepsTb.addButton({
                text: 'Skip',
                cls:'tarantula-btn-skip',
                handler: function() {
                    this.setStepResult('SKIPPED', false);
                },
                scope: CaseExecute
                //,enableToggle: true
            });

            btnNotImplemented = stepsTb.addButton({
                text: 'Not Implemented',
                cls:'tarantula-btn-notimplemented',
                handler: function() {
                    this.setStepResult('NOT_IMPLEMENTED', false);
                },
                scope: CaseExecute
                //,enableToggle: true
            });

            btnClear = stepsTb.addButton({
                text: 'Not Run',
                cls:'tarantula-btn-clear',
                handler: function() {
                    this.setStepResult('NOT_RUN', false);
                },
                scope: CaseExecute
                //,enableToggle: true
            });

            stepsTb.addButton( {
                text: 'Pause',
                cls: 'tarantula-btn-pause',
                handler: function() {
                    this.pauseExecution();
                },
                scope: CaseExecute
            });


            stepsTb.addButton( {text: 'Prev',
                                cls:'tarantula-btn-prev',
                                handler: CaseExecute.prevStep,
                                scope: CaseExecute });

            stepsTb.addSeparator();

            stepsTb.addButton( {text: 'Next',
                                handler: CaseExecute.nextStep,
                                cls:'tarantula-btn-next',
                                scope: CaseExecute });

            // Initialize dialogs.

            CommentDialog.init(this.setComment);
            DefectDialog.init(this.setDefect);

            // Clear grid and refresh list of available executions.
            TestGrid.clear(objId);

            gui.project_panel.hide();
            gui.set_panel.hide();
            gui.case_panel.hide();
            gui.exec_panel.hide();
            gui.user_panel.hide();
            gui.requirement_panel.hide();
            gui.testobjects_panel.hide();
            gui.test_panel.show();

            gui.test_panel.expand();
            gui.layout.getRegion( 'west').expand();
            gui.acc.updatePanelHeights(gui.test_panel, 0);

            // Disabled, causes GUI to jump and eat top navigator
            // on IE..
            gui.layout.getRegion( 'west').resizeTo(433);
        },

        pauseExecution: function() {
            if (!caseExecution) {
                return;
            }
            var f = function(v) {
                var a = [];
                a[0] = Math.floor(v / 3600);
                a[1] = Math.floor( (v % 3600) / 60 );
                a[2] = Math.floor( (v % 3600) % 60 );
                a = a.map(function(i) {
                    return (i.toString().length < 2) ? '0'+i : i;
                });
                return a.join(':');
            };
            this.toggleTimerPause();
            Ext.Msg.alert(
                "Paused",
                "Time spent on this case: " +
                    f(this.executionDuration()) +
                    ". Press ok to continue execution.",
                function() {
                    this.toggleTimerPause();
                },
                this);
        },

        /**
        * Return bug_tracker used in this project
        */
        getBugtracker: function() {
            return bugtracker;
        },

        /**
        * Update content panels to new execution.
        * Refresh also TestGrid.
        */
        onCaseExecutionLoad: function() {
            // Keep track of possible changes to execution (design)
            CaseExecute.setExecutionVersion( caseExecution.execution_version);
            CaseExecute.resetTimer();
            activeStepIndex = 0;

            // Refresh Test Grid.
            // Let's try to manage without refresh for now....
            //TestGrid.refreshGridAndStore();

            CaseExecute.showExecution();


            updateCaseContent();
            updateStepsContent();

            casesTb.enable();
            stepsTb.enable();
        },

        /**
        * Activate selected step and update steps content panel.
        */
        setActiveStep: function ( index) {
            if(!caseExecution.steps) { return false; }

            activeStepIndex = index;

            if( activeStepIndex >= caseExecution.steps.length) {
                activeStepIndex = caseExecution.steps.length - 1;
            }

            if( activeStepIndex < 0) {
                activeStepIndex = 0;
            }

            updateStepsContent();
        },

        /**
        * Activate next step (if available) and update steps content panel.
        */
        nextStep: function() {

            if((!caseExecution) || (!caseExecution.steps)) { return false; }

            activeStepIndex += 1;

            if( activeStepIndex >= caseExecution.steps.length) {
                activeStepIndex = caseExecution.steps.length - 1;
            }
            updateStepsContent();
        },

        /**
        * Activate previous step ( if not in first step already)) and update
        * steps content panel.
        */
        prevStep: function() {

            if((!caseExecution) || (!caseExecution.steps)) { return false; }

            activeStepIndex -= 1;

            if( activeStepIndex < 0) {
                activeStepIndex = 0;
            }
            updateStepsContent();
        },

        /**
        * Sets current step result and marks case execution as modified.
        * Mark current case execution as dirty.
        */
        setStepResult: function(stepResult, moveToNext) {
            if (!caseExecution) {
                return;
            }
            isDirty = true;
            caseExecution.steps[activeStepIndex].result = stepResult;
            ajaxSaveCaseExecution(executionId, caseId, null, activeStepIndex);
            if( moveToNext) {
                this.nextStep();
            } else {
                updateStepsContent();
            }
        },


        /**
        * Save existing case execution, if needed (modifications).
        */
        loadCase: function( executionId_, caseId_){
            f = function(exec_id, case_id) {
                if (Ext.Ajax.isLoading(saveTransaction)) {
                    f.defer(1000, this);
                } else {
                    casesTb.disable();
                    stepsTb.disable();
                    // ok to load directly
                    executionId = exec_id;
                    caseId = case_id;
                    // Make main view to reload after loading.          OBS!
                    ajaxLoadCaseExecution( executionId, caseId);
                }
            };
            if(isDirty && !Ext.Ajax.isLoading(saveTransaction)) {
                // Main view is refreshed on successful save.       OBS!
                ajaxSaveCaseExecution(executionId, caseId,
                                      f.createDelegate(this, [executionId_, caseId_]));
            } else {
                f.call(this, executionId_, caseId_);
            }
        },

        // Reload current case.
        reloadCase: function() {
            CaseExecute.loadCase( executionId, caseId);
        },

        /**
        * Returns true, if given case execution is already displayed.
        */
        isCaseExecution: function(executionId_, caseId_){

            if( executionId_ != executionId || caseId_!= caseId) {
                return false;
            } else {
                return true;
            }
        },

        hideExecution: function(){
            Ext.get( 'content').setVisible( false);
        },


        showExecution: function(){
            Ext.get( 'content').setVisible( true);
        },

        // Clear whole screen (TestGrid and CaseExecute).

        // @param {Boolean} keepExecutionComboValue
        // Do no clear selected execution from combobox or
        // refresh executions store.
        // Set true, when function is called by combobox
        // execution selection.
        //
        // @param {Function} callback Optional callback function which is
        // called after clear is run.
        clear: function( keepExecutionComboValue, callback){

            // Create close from operations of this function
            // to make sure that those are run last if saving
            // old results is necessary.
            var f = function() {
                // Clear test screen.
                TestGrid.clear(keepExecutionComboValue);
                executionVersion = null;
                executionId = null;
                if (callback) {
                    callback();
                }
            };

            if(isDirty){
                ajaxSaveCaseExecution(executionId, caseId,
                                      f.createDelegate(this));
            } else {
                f();
            }
            return true;
        },


        /**
        *
        */
        getComment: function(stepIndex) {
            return caseExecution.steps[stepIndex].comment;
        },

        /**
        *
        */
        setComment: function( stepIndex, txt) {
            caseExecution.steps[stepIndex].comment=txt;
            isDirty=true;
            ajaxSaveCaseExecution(executionId, caseId, null, activeStepIndex);
            updateStepsContent();
        },

        /**
        *
        */
        getDefect: function(stepIndex) {
            return caseExecution.steps[stepIndex].bug;
        },

        // Get all defects.
        getDefects: function() {
            arr = [];
            Ext.each(caseExecution.steps, function(v) {
                if (v.bug) {
                    arr.push(v.bug);
                }
            }, this);
            return arr;
      },

        /**
        *
        */
        setDefect: function( stepIndex, defect) {
            caseExecution.steps[stepIndex].bug=defect;
            isDirty=true;
            ajaxSaveCaseExecution(executionId, caseId, null, activeStepIndex);
            updateStepsContent();
        },

        // For keeping track of current version
        // in server.
        // If version changes, test execution screen
        // needs to be reloaded.
        // This is called everytime we get
        // version information from server.
        // Not very elegant solution, something
        // more standard way of tracking changes
        // is needed.
        setExecutionVersion: function(version){
            if( executionVersion) {
                if( executionVersion != version){
                    //Execution has been changed.
                    //Just clear everything and make user
                    //to reselect execution.
                    CaseExecute.clear();
                    executionVersion = null;
                    Ext.Msg.alert('Execution Changed',
                                  'Execution (plan) has been modified by ' +
                                  'someone else. Please reload execution.');
                }
            } else {
                // We didn't know yet current execution version.
                executionVersion = version;
            }
        },


        // Reset case execution timer.
        // Set timer to current date.
        resetTimer: function() {
            executionTimer = [[new Date()]];
        },

        // Toggle pausing of timer
        toggleTimerPause: function() {
            if ( (!caseExecution) || (!executionTimer)) {
                return;
            }
            var l = executionTimer.last();
            if (l.length == 1) {
                l.push(new Date());
            } else {
                executionTimer.push([new Date()]);
            }
        },

        // Time spent executing current case.
        // In seconds.
        executionDuration: function() {
            var msecs = 0;
            var start = caseExecution.duration || 0;
            Ext.each(executionTimer, function(i) {
                if (i.length == 2) {
                    msecs += i[1].getTime() - i[0].getTime();
                } else {
                    msecs += new Date().getTime() - i[0];
                    return false;
                }
            }, this);
            return start + parseInt( (msecs / 1000).toFixed(), 10);
        }

    };
}();
