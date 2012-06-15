Ext.namespace('Ext.testia');


Ext.testia.TaskDialog = function(config) {
    config = config || {};

    config.width = config.width || 370;
    config.height = config.height || 220;
    config.center = config.center || {autoScroll: true};
    config.content = config.content || '';
    config.collapsible = false;

    if (config.fn) {
        this.fn = config.fn;
    }
    var defaults = config.defaults;

    var el = Ext.DomHelper.append(document.body, {tag:'div'});
    Ext.testia.TaskDialog.superclass.constructor.call(this, el, config);

    // Call provided dialog handler with scope provided in the config.
    this.addButton('Add', function() {
        if (this.fn) {
            var data = this.dForm.getValues();
            data.assigned_to = this.dForm.findField('assigned_to').getValue();
            this.fn.call(config.scope || this, data);
        }
        this.closeDialog();
    }, this);
    this.addButton('Cancel', function() {
        this.closeDialog();
    }, this);

    var layout = this.getLayout();
    layout.beginUpdate();
    var cp = new Ext.ContentPanel(Ext.id(), {autoCreate: true,
        background: true});
    layout.add('center', cp);
    layout.endUpdate();

    this.dForm = new Ext.form.Form({
        labelSeparator: '',
        labelAlign: 'top',
        itemCls: 'dialogForm task-dialog'
    });

    this.dForm.add(new Ext.form.ComboBox({
        store: new Ext.data.JsonStore({
            url: createUrl('/projects/current/users'),
            root: '',
            id: 'dbid',
            fields: ['dbid','text']
        }),
        displayField:'text',
        valueField: 'dbid',
        editable: false,
        allowBlank: false,
        lazyRender: true,
        triggerAction: 'all',
        mode: 'local',
        selectOnFocus:true,
        name: 'assigned_to',
        fieldLabel: 'Assign to'
    }));

    this.dForm.add(new Ext.form.TextArea({
        fieldLabel: 'Description',
        name: 'description'
    }));
    this.dForm.render(Ext.DomHelper.append(cp.el, {tag:'div'}, true));

    this.dForm.findField('assigned_to').store.load();

    if (defaults) {
        this.dForm.setValues(defaults);
    }

    this.setTitle(config.title || 'Add task');

    this.center();

    this.show();
};

Ext.extend(Ext.testia.TaskDialog, Ext.LayoutDialog, {
    fn: undefined,
    dform: undefined,

    closeDialog: function() {
        this.destroy(true);
    }
});

/**
 * @class Ext.testia.TaskList
 * @extends Ext.util.Observable
 */
Ext.testia.TaskList = function(el,config) {
    config = config || {};
    this.ownId = USER_ID;
    this.taskEls = {};
    this.taskRec = Ext.data.Record.create({name: 'id'},{name: 'name'},
                                          {name: 'description'},
                                          {name: 'assigned_to'},
                                          {name: 'assignee'},
                                          {name: 'finished'},
                                          {name: 'finished_at'},
                                          {name: 'resource_type'},
                                          {name: 'resource_id'},
                                          {name: 'link'},
                                          {name: 'created_by'},
                                          {name: 'creator'});
    if (config.store) {
        this.store = config.store;
    } else {
        this.store = new Ext.data.JsonStore({
            url: createUrl('/users/current/tasks'),
            root: '',
            id: 'id',
            fields: ['id', 'name', 'description', 'assigned_to', 'assignee', 'finished',
                     'finished_at', 'resource_type', 'resource_id', 'link', 'project_id',
                     'created_by']});
    }
    var dh = Ext.DomHelper;
    var tag = {tag:'div', cls: config.cls, style: 'float: right', children: [
        {tag:'p', cls:'emulate-link', html:config.text},
        {tag:'div', cls: 'testia-task-items', style:'display:none;', children: [
            {tag:'ul', cls: 'commands', children: [
                {tag: 'li', cls:'emulate-link selected', html: 'Todo'},
                {tag: 'li', cls:'emulate-link', html: 'Finished'},
                {tag: 'li', cls:'emulate-link', html: 'Monitored tasks'}
            ]},
            {tag:'ul', cls: 'testia-task-items'},
            {tag:'div', cls: 'add emulate-link', html: 'New task'}
        ]}
    ]};
    this.el = dh.insertFirst(el, tag, true);
    this.collapsed = true;
    this.el.child('ul').setVisibilityMode(Ext.Element.DISPLAY);
    this.el.child('p').on('click', function() {
        if (this.collapsed) {
            this.load();
            this.expand();
        } else {
            this.collapse();
        }
    }, this);
    this.el.child('div.add').on('click', function() {
        this.addTaskPrompt({name: 'Task'});
    }, this);

    if (this.store) {
        this.todoFilter = function(r) {
            if(this.ownId) {
                return (r.get('assigned_to') == this.ownId) && !r.get('finished');
            }
            return !r.get('finished');
        };
        this.finishedFilter = function(r) {
            if(this.ownId) {
                return (r.get('assigned_to') == this.ownId) && r.get('finished');
            }
            return r.get('finished');
        };
        this.monitoredFilter = function(r) {
            if(this.ownId) {
                return (r.get('created_by') == this.ownId) &&
                    (r.get('assigned_to') != this.ownId);
            }
            return false;
        };
        this.filter = this.todoFilter.createDelegate(this);
        this.store.on('datachanged', function(store) {
            for(var i in this.taskEls) {
                this.taskEls[i].hide();
                this.taskEls[i].removeClass('odd');
            }
            store.each(function(r,c) {
                var tmpEl = this.taskEls[r.get('id')];
                var dEl;
                if (tmpEl) {
                    dEl = tmpEl.child('.finish_date');
                    if ( (r.get('assigned_to') != this.ownId) && r.get('finished_at') &&
                         !dEl) {
                        Ext.DomHelper.append(tmpEl, {tag:'span', cls:'finish_date', html:" Finished at: " + r.get('finished_at')});
                    }
                    tmpEl.show();
                } else {
                    this.addTaskEl(r);
                }
                if ( (c % 2) === 1) {
                    this.taskEls[r.get('id')].addClass('odd');
                }
            }, this);
        }, this);
        this.load();
    }
    this.el.child('ul.commands li:nth(1)').on('click', function(e, t) {
        t.addClassName('selected');
        t.siblings().map(function(i) {i.removeClassName('selected');});
        this.filter = this.todoFilter.createDelegate(this);
        this.store.filterBy(this.filter);
    }, this);
    this.el.child('ul.commands li:nth(2)').on('click', function(e, t) {
        t.addClassName('selected');
        t.siblings().map(function(i) {i.removeClassName('selected');});

        this.filter = this.finishedFilter.createDelegate(this);
        this.store.filterBy(this.filter);
    }, this);
    this.el.child('ul.commands li:nth(3)').on('click', function(e, t) {
        t.addClassName('selected');
        t.siblings().map(function(i) {i.removeClassName('selected');});

        this.filter = this.monitoredFilter.createDelegate(this);
        this.store.filterBy(this.filter);
    }, this);
};

Ext.extend(Ext.testia.TaskList, Ext.util.Observable, {
    el: undefined,
    store: undefined,
    collapsed: undefined,
    taskEls: undefined,
    taskRec: undefined,

    filter: undefined, // current filter
    todoFilter: undefined,
    finishedFilter: undefined,
    monitoredFilter: undefined,
    ownId: undefined,

    addTaskPrompt: function(defaults) {
        defaults = defaults || {};
        defaults.finished = false;

        var d = new Ext.testia.TaskDialog({
            defaults: defaults,
            scope: this,
            fn: function(data) {
                data.project_id = GUI.projectCombo.getValue();
                var url;
                if (defaults.resource_type && defaults.resource_id) {
                    url = "/" + defaults.resource_type + "/" +
                        defaults.resource_id + "/tasks/";
                } else {
                    url = '/projects/' + data.project_id + '/tasks/';
                }
                Ext.Ajax.request({
                    url: createUrl(url),
                    method: 'post',
                    params: Ext.urlEncode({data: Ext.encode(data)}),
                    scope: this,
                    success: function(r,o) {
                        this.load();
                    }
                });
            }
        });
    },

    addTaskEl: function(rec) {
        var data, tags, tmpEl;
        if (rec instanceof Array) {
            rec = rec[0];
        }
        if (rec instanceof Ext.data.Record) {
            data = rec.data;
        } else {
            data = rec;
        }
        var f = function(target, id) {
            this.fireEvent('resourceobjectselected', target, id);
        };
        tags = {tag:'li', id:'taskel-'+data.id, cls:'task', children:[]};
        if (data.assigned_to != this.ownId) {
            tags.children = tags.children.concat([
                {tag:'span', cls:'description', html: data.description},
                {tag:'span', html:" Assigned to: "},
                {tag:'span', cls:'assignee', html:data.assignee}
            ]);
            if (data.finished_at) {
                tags.children.push({tag:'span', cls:'finish_date', html:" Finished at: " + data.finished_at});
            }
        } else {
            tags.children = tags.children.concat([
                {tag:'span', cls:'button emulate-link', html:'X&nbsp;&nbsp;'},
                {tag:'span', cls:'description', html: data.description}
            ]);
        }
        this.taskEls[data.id] = Ext.DomHelper.append(
            this.el.child('ul.testia-task-items'), tags, true);
        this.taskEls[data.id].setVisibilityMode(Ext.Element.DISPLAY);
        this.taskEls[data.id].hide();
        if (data.link) {
            tmpEl = this.taskEls[data.id].child('.description');
            if ( data.link.match(/^https?:\/\//) ) {
                tmpEl.dom.innerHTML = '<a href="' + data.link + '" target="_blank">' +
                    tmpEl.dom.innerHTML + '</a>';
            } else {
                tmpEl.addClass('emulate-link');
                tmpEl.on('click', function() {
                    f.call(GUI, data.link, data.resource_id);
                }, this);
            }
        }
        if ( (tmpEl = this.taskEls[data.id].child('.button')) ) {
            tmpEl.on('click', function() {
                Ext.Ajax.request({
                    url: createUrl('/projects/' + data.project_id + '/tasks/'+data.id),
                    method: 'put',
                    params: Ext.urlEncode({data: Ext.encode({
                        finished: !this.store.getById(data.id).get('finished')
                    })}),
                    scope: this,
                    success: function() {
                        this.finishTask(data.id);
                    }
                });
            }, this);
        }

        return this.taskEls[data.id];
    },

    finishTask: function(id) {
        if (!(this.taskEls && this.taskEls[id])) {
            return;
        }
        var rec = this.store.getById(id);
        rec.set('finished', !rec.get('finished'));
        this.taskEls[id].hide({
            duration: 0.5
        });
    },

    expand: function() {
        this.collapsed = false;
        this.el.child('div.testia-task-items').show({duration: 0.5});
    },

    collapse: function() {
        this.collapsed = true;
        this.el.child('div.testia-task-items').hide({duration: 0.5});
    },

    load: function() {
        this.store.clearFilter(true);
        this.store.removeAll();
        this.store.load({
            callback: function() {
                this.store.filterBy(this.filter);
            },
            scope: this
        });
    }

});