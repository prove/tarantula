/*
 * Ext JS Library 1.1
 * Copyright(c) 2006-2007, Ext JS, LLC.
 * licensing@extjs.com
 * 
 * http://www.extjs.com/license
 */

var TabsExample = {
    init : function(){
        // basic tabs 1, built from existing content
        var tabs = new Ext.TabPanel('tabs1');
        tabs.addTab('script', "View Script");
        tabs.addTab('markup', "View Markup");
        tabs.activate('script');
    
        // second tabs built from JS
        var jtabs = new Ext.TabPanel('jtabs');
        jtabs.addTab('jtabs-1', "Normal Tab", "My content was added during construction.");
    
        var tab2 = jtabs.addTab('jtabs-2', "Ajax Tab 1");
        var updater = tab2.getUpdateManager();
        updater.setDefaultUrl('ajax1.htm');
        tab2.on('activate', updater.refresh, updater, true);
    
        var tab3 = jtabs.addTab('jtabs-3', "Ajax Tab 2");
        tab3.setUrl('ajax2.htm', null, true);
    
        var tab4 = jtabs.addTab('jtabs-4', "Event Tab");
        tab4.setContent("I am tab 4's content. My content was set with setContent() after I was created. I also have an event listener attached.");
        tab4.on('activate', function(){
            alert('Tab 4 was activated.');
        });
    
        jtabs.addTab('tabs1-5', "Disabled Tab", "Can't see me cause I'm disabled");
        jtabs.disableTab('tabs1-5');
    
        jtabs.activate('jtabs-1');
    }
}
Ext.EventManager.onDocumentReady(TabsExample.init, TabsExample, true);