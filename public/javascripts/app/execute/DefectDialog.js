var DefectDialog = function() {

    var dialog;

    var commentsStore = new Ext.data.JsonStore({
        url: createUrl('/projects/current/bugs'),
        root: 'data',
        id: 'id',
        fields: ['id','name','external_id']
    });

    var commentsCombo;
    var productsCombo;
    var ok, cancel, refresh;

    var textArea;

    var stepIndex;

    var callBack;

    var currentCaseExec;

    var DefectRecord = Ext.data.Record.create(
        {name: 'name'},
        {name: 'id'},
        {name: 'external_id'}
    );

    function ajaxLoadComments(caseId, cb) {
        if (cb) {
            commentsStore.load({callback: cb});
        } else {
            commentsStore.load();
        }
    }


    function createAndShowDialog() {

        if( dialog && dialog.isVisible()) {
            return false;
        }

        var el = Ext.get('dlgDefect');

        if( el) { el.remove(); }

        el = Ext.DomHelper.append(
            document.body,
            {tag:'div',
             id:'dlgDefect',
             cls:'dialog'}, true);

        dialog = new Ext.LayoutDialog( el, {
            modal:false,
            width:580,
            height:370,
            shadow:true,
            proxyDrag: true,
            modal: true,
            center: {
                autoScroll:true
            }
        });

        dialog.setTitle("Associate defect");

        ok = dialog.addButton('Ok', function() {
            dialog.hide();
            var v = commentsCombo.getValue();
            var bug;
            if (v && (v > 0)) {
                bug = commentsCombo.store.getById(v).data;
            }
            callBack(stepIndex,bug);
            dialog.destroy( true);
        }, dialog);

        refresh = dialog.addButton({
            text: 'Refresh',
            handler: function() {
                cancel.disable();
                ok.disable();
                refresh.disable();
                commentsStore.load();
            }
        });

        cancel = dialog.addButton('Cancel', function() {
            dialog.hide();
            dialog.destroy( true);
        }, dialog);

        var layout = dialog.getLayout();
        layout.beginUpdate();

        var cp = new Ext.ContentPanel(Ext.id(), {
            autoCreate:true, background:true});
        layout.add('center', cp);

        // Add div into content panel for actual form..
        cp.setContent(
            '<p>Select existing defect or enter new defect. ' +
                'Defect can be chosen from defects entered ' +
                'previously for current case.' +
                '</p><div id="dlgDefectForm"></div>');

        layout.endUpdate();

        var simple = new Ext.form.Form({
            labelSeparator: ':',
            itemCls: 'dialogFormItem'
        });

        commentsCombo = new Ext.testia.Combo({
            store: commentsStore,
            displayField: 'name',
            valueField: 'id',
            typeAhead: true,
            mode: 'local',
            triggerAction: 'all',
            emptyText:'',
            selectOnFocus:true,
            forceSelection:true,
            fieldLabel: 'Defect',
            width:400
        });

        commentsCombo.on('select', function(combo, record) {
            ok.enable();
            var el = Ext.fly('defect_info').child('a');
            if (el) {
                el.remove();
            }
            if (record.data.id > 0) {
                Ext.DomHelper.append('defect_info',
                                     {cls: 'bug_tracker_link', tag: 'a',
                                      href: createUrl('/projects/current/bugs/'+record.get('id')),
                                      html:'View defect in bug tracker.', target:'_blank'});
            }
        });

        commentsStore.on('load', function() {
            ok.enable();
            cancel.enable();
            refresh.enable();
            var rec = Ext.data.Record.create([{name: 'id'}, {name: 'name'},
                {name: 'external_id'}]);
            // Data is loaded firs time, add option to remove defect
            // from the step.
            if (!this.getById(0)) {
                this.add(new rec({id:0, name:'(None)', external_id:0},0));
            }
        }, commentsStore);

        var rec = Ext.data.Record.create([{name: 'id'}, {name: 'name'},
                {name: 'external_id'}]);

        if (!commentsStore.getById(0)) {
            commentsStore.add(new rec({id:0, name:'(None)', external_id:0},0));
        }

        simple.fieldset({legend: 'Existing defects'},
                        commentsCombo);

        productsCombo = new Ext.form.ComboBox({
            displayField: 'name',
            valueField: 'name',
            typeAhead: true,
            mode: 'local',
            triggerAction: 'all',
            emptyText:'',
            selectOnFocus:true,
            forceSelection:false,
            fieldLabel: 'Test product',
            width:200,
            allowBlank: false,
            store: new Ext.data.JsonStore({
                url: createUrl('/projects/current/products'),
                root: 'data',
                id: 'id',
                fields: ['id','name']
            })
        });
        productsCombo.on('select', function() {
            var input = Ext.get('bug_tracker_link').child('#bug_tracker_product');
            input.set({value: this.getValue()});
        }, productsCombo);
        simple.fieldset({id: 'new_bug_fieldset', legend: 'New defect'},
                       productsCombo);

        simple.render("dlgDefectForm");

        productsCombo.store.load();
        dialog.center();
        dialog.show();

        var bt = CaseExecute.getBugtracker();

        // Make sure that there is proper amount of / chars
        // between bugzilla root and cgi files.
        var btLinkEl = Ext.DomHelper.append(
            Ext.get('new_bug_fieldset'),
            {tag:'p', children: [
                {id: 'bug_tracker_link', tag: 'a',
                 href: '#', html:'Add defect to bug tracker'},
                {tag:'form', id: 'dummy_bug_post',
                 style: 'display:none',
                 action: createUrl('/projects/current/bugs/'),
                 method: 'post', target: '_blank', children: [
                     {tag:'input', type:'hidden', name:'step_execution_id',
                      value: currentCaseExec.steps[stepIndex].id},
                     {tag:'input', type:'hidden', name:'product', id:'bug_tracker_product'}
                 ]}
            ]}, true);
        btLinkEl.child('a').on('click', function() {
            btLinkEl.child('form').dom.submit();
        });

        Ext.DomHelper.insertAfter(commentsCombo.container, {tag:'p', id:'defect_info'});

        var old_bug = CaseExecute.getDefect(stepIndex);
        if (old_bug) {
            var oldRec = commentsStore.getById(old_bug.id);
            if (!oldRec) {
                commentsStore.add(new DefectRecord(old_bug, old_bug.id));
                Ext.DomHelper.append('defect_info',
                    {tag:'span', html:'Defect may be closed or resolved. '});
            } else {
                var tEl = Ext.get('defect_info').child('span');
                if (tEl) {
                    tEl.remove();
                }
            }
            Ext.DomHelper.append('defect_info',
                {cls: 'bug_tracker_link', tag: 'a',
                    href: createUrl('/projects/current/bugs/'+old_bug.id),
                    html:'View defect in bug tracker.', target:'_blank'});
            commentsCombo.setValue(old_bug.id);
        }
    }

    return{

        // Recreate dialog everytime to get fresh values.
        init: function(fnOk) {
            callBack = fnOk;
        },

        show: function( _stepIndex, caseExec) {
            
            // Load defects, and after loaded, display dialog.
            stepIndex = _stepIndex;

            if( (!currentCaseExec) || (currentCaseExec.id != caseExec.id)) {
                // Dialog is not initialized to current case, so
                // load defects for current case.
                // Dialog will be displayed by store.onLoad event.
                ajaxLoadComments( caseExec.id, createAndShowDialog.createCallback());
                currentCaseExec = caseExec;
            } else {
                createAndShowDialog();
            }
        }
    };
}();