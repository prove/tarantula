Ext.namespace("Ext.testia");

Ext.testia.SortableReportForm = function(form_div, toolbar_div, config) {
    Ext.testia.SortableReportForm.superclass.constructor.call(this,
                                                      form_div,
                                                      toolbar_div, config);
};

Ext.extend(Ext.testia.SortableReportForm, Ext.testia.ReportForm, {

	createSortColumns: function(){
		t = Ext.DomQuery.select('div.tbl table');
		
		Ext.each(Ext.DomQuery.select('th', t[0]), function(elem, i) {
			// Get real Ext.element
			ee = Ext.get(elem);

			// Get text
			text = elem.innerHTML;

			// Recreate as hyperlink
			ee.update('<a href="#">' + text + '</a>')
			
			// Add click listener with proper scope and function 
			a = ee.child('a')
	 		a.addListener('click', function(){
					this.sortByColumn( i+1 );
			}, this);
		}, this);
	},

	sortByColumn: function(col) {
		if (col == this.sort_by) {
			if (this.sort_dir == 'asc') {
				this.sort_dir = 'desc'
		  	} else {
				this.sort_dir = 'asc'
		  	}
		} else {
			this.sort_dir = 'asc'
		}
        this.sort_by = col;
		this.generate('sort_by='+col+'&sort_dir='+this.sort_dir);
	},
			
    generate: function(parameters) {
        var items = [];
        Ext.each(this.itemList.selectedItems,
                 function(i) {
                     items.push(i.dbid);
                 }, this);

        var values = this.getValues();
        var params = "";

        if (values.type == 'objects') {
            params = "test_object_ids=" + items.join(',');
        } else if (values.type == 'executions') {
            params = "execution_ids=" + items.join(',');
        } else {
            params = "all=1";
        }

        if (this.categorize) {
        	params = [params, 'tags=1'].join('&');
        }

        if (typeof parameters == 'string') {
            params = [params, parameters].join('&');
        }

        Ext.get('reports').clearContent();

        Ext.Ajax.request({
            url: createUrl(this.reportUrl),
            method: 'get',
            params: params,
            scope: this,
            success: function(r) {
                var el = Ext.get('reports');
                this.report = new Report(r.responseText);
                this.report.render(el);
				this.createSortColumns();
            }
        });

    },

	createForm: function() {
        // Ext.testia.SortableReportForm.superclass.createForm.call(this);

		var b1 = new Ext.form.Radio({
                                        fieldLabel: 'Selected test objects',
                                        name: 'type',
                                        inputValue: 'objects',
                                        checked: true
                                    });
        b1.on('check', function(t,v) {
                  if (v && this.itemList) {
                      var l = Ext.get('item_selection');
                      l.show();
                      l = l.child('legend');
                      l.dom.innerHTML = 'Select Test Objects';
                      this.itemList.url = createUrl(
                          '/projects/current/test_objects');
                      this.itemList.itemUrl = this.itemList.url;
                      this.itemList.reload();
                      this.itemList.el.removeClass('executions-list');
                      this.itemList.el.addClass('testobjects-list');
                  }
              }, this);

        var b2 = new Ext.form.Radio({
                                        fieldLabel: 'Selected test executions',
                                        name: 'type',
                                        inputValue: 'executions'
                                    });
        b2.on('check', function(t,v) {
                  if (v && this.itemList) {
                      var l = Ext.get('item_selection');
                      l.show();
                      l = l.child('legend');
                      l.dom.innerHTML = 'Select Executions';
                      this.itemList.url = createUrl('/executions');
                      this.itemList.itemUrl = this.itemList.url;
                      this.itemList.reload();
                      this.itemList.el.removeClass('testobjects-list');
                      this.itemList.el.addClass('executions-list');
                  }
              }, this);

		var b3 = new Ext.form.Checkbox({
		                             fieldLabel: 'Categorize by Tags',
		                             name: 'categorize',
		                             inputValue: 'tags'
		                            });

		b3.on('check', function(t,v) {
				if (this.categorize) {
					this.categorize = false;
				} else {
					this.categorize = true
				}
			}, this);

        this.column({}, b1, b2, b3);

        this.fieldset({id:'item_selection',
                       legend:'Select Test Objects'});
	
    }
});