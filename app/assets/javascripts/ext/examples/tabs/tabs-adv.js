/*
 * Ext JS Library 1.1
 * Copyright(c) 2006-2007, Ext JS, LLC.
 * licensing@extjs.com
 * 
 * http://www.extjs.com/license
 */

Ext.onReady(function(){
    var tabs = new Ext.TabPanel('tab-panel1', {
        resizeTabs:true, // turn on tab resizing
        minTabWidth: 20,
        preferredTabWidth:150
    });

    tabs.addTab('root-tab', 'Home Tab');
    tabs.activate(0);

    var content = Ext.getDom('content').innerHTML; // bogus markup for tabs
    var index = 0;
    Ext.get('add-link').on('click', function(){
        tabs.addTab(
             Ext.id(),
             'New Tab ' + (++index),
             'Tab Body ' + index + content,
             true
        );
    });
});