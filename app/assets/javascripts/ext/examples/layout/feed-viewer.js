/*
 * Ext JS Library 1.1
 * Copyright(c) 2006-2007, Ext JS, LLC.
 * licensing@extjs.com
 * 
 * http://www.extjs.com/license
 */

var Viewer = function(){
    // a bunch of private variables accessible by member function
    var layout, statusPanel, south, preview, previewBody, feedPanel;
    var grid, ds, sm;
    var addFeed, currentItem, tpl;
    var suggested, feeds;
    var sfeeds, myfeeds;
    var seed = 0;
    
    // feed clicks bubble up to this universal handler
    var feedClicked = function(e){
        // find the "a" element that was clicked
        var a = e.getTarget('a');
        if(a){
            e.preventDefault();
            Viewer.loadFeed(a.href);
            Viewer.changeActiveFeed(a.id.substr(5));
        }  
    };
    
    return {
        init : function(){
            // initialize state manager, we will use cookies
            Ext.state.Manager.setProvider(new Ext.state.CookieProvider());
            
            // initialize the add feed overlay and buttons
            addFeed = Ext.get('add-feed');
            var addBtn = Ext.get('add-btn');
            addBtn.on('click', this.validateFeed, this);
            var closeBtn = Ext.get('add-feed-close');
            closeBtn.on('click', addFeed.hide, addFeed, true);
            
            // create Elements for the feed and suggested lists
            feeds = Ext.get('feeds'); suggested = Ext.get('suggested');
            
            // delegate clicks on the lists
            feeds.on('click', feedClicked);
            suggested.on('click', feedClicked);
            
            //create feed template
            tpl = new Ext.DomHelper.Template('<a id="feed-{id}" href="{url}"><span class="body">{name}<br><span class="desc">{desc}</span></span></a>');
            
            // collection of feeds added by the user
            myfeeds = {};
            
            // some default feeds
            sfeeds = {
                'ajaxian':{id:'ajaxian', name: 'Ajaxian', desc: 'Cleaning up the web with Ajax.', url:'http://feeds.feedburner.com/ajaxian'},
                'yui':{id:'yui', name: 'YUI Blog', desc: 'News and Articles about Designing and Developing with Yahoo! Libraries.', url:'http://feeds.yuiblog.com/YahooUserInterfaceBlog'},
                'sports':{id:'sports', name: 'Yahoo! Sports', desc: 'Latest news and information for the world of sports.', url:'http://sports.yahoo.com/top/rss.xml'}
            };
            
            // go through the suggested feeds and add them to the list
            for(var id in sfeeds) {
            	var f = sfeeds[id];
            	tpl.append(suggested.dom, f);
            }
            
            // create the main layout
            layout = new Ext.BorderLayout(document.body, {
                north: {
                    split:false,
                    initialSize: 25,
                    titlebar: false
                },
                west: {
                    split:true,
                    initialSize: 200,
                    minSize: 175,
                    maxSize: 400,
                    titlebar: true,
                    collapsible: true,
                    animate: true,
                    autoScroll:false,
                    useShim:true,
                    cmargins: {top:0,bottom:2,right:2,left:2}
                },
                east: {
                    split:true,
                    initialSize: 200,
                    minSize: 175,
                    maxSize: 400,
                    titlebar: true,
                    collapsible: true,
                    animate: true,
                    autoScroll:false,
                    useShim:true,
                    collapsed:true,
                    cmargins: {top:0,bottom:2,right:2,left:2}
                },
                south: {
                    split:false,
                    initialSize: 22,
                    titlebar: false,
                    collapsible: false,
                    animate: false
                },
                center: {
                    titlebar: false,
                    autoScroll:false,
                    tabPosition: 'top',
                    closeOnTab: true,
                    alwaysShowTabs: true,
                    resizeTabs: true
                }
            });
            // tell the layout not to perform layouts until we're done adding everything
            layout.beginUpdate();
            layout.add('north', new Ext.ContentPanel('header'));
            
            // initialize the statusbar
            statusPanel = new Ext.ContentPanel('status');
            south = layout.getRegion('south');
            south.add(statusPanel);
            
            // create the add feed toolbar
            var feedtb = new Ext.Toolbar('myfeeds-tb');
            // They can also be referenced by id in or components
            feedtb.add( {
              id:'add-feed-btn',
              icon: 'images/add-feed.gif', // icons can also be specified inline
              cls: 'x-btn-text-icon',
              text: 'Add feed',
              handler: this.showAddFeed.createDelegate(this),
              tooltip: '<b>Add Feed</b><br/>Button with tooltip'
          });            
            
            layout.add('west', new Ext.ContentPanel('feeds', {title: 'My Feeds', fitToFrame:true, toolbar: feedtb, resizeEl:'myfeeds-body'}));
            layout.add('east', new Ext.ContentPanel('suggested', {title: 'Suggested Feeds', fitToFrame:true}));
            
            // the inner layout houses the grid panel and the preview panel
            var innerLayout = new Ext.BorderLayout('main', {
                south: {
                    split:true,
                    initialSize: 250,
                    minSize: 100,
                    maxSize: 400,
                    autoScroll:false,
                    collapsible:true,
                    titlebar: true,
                    animate: true,
                    cmargins: {top:2,bottom:0,right:0,left:0}
                },
                center: {
                    autoScroll:false,
                    titlebar:false
                }
            });
            // add the nested layout
            feedPanel = new Ext.NestedLayoutPanel(innerLayout, 'View Feed');
            layout.add('center', feedPanel);
            
            innerLayout.beginUpdate();
            
            var lv = innerLayout.add('center', new Ext.ContentPanel('feed-grid', {title: 'Feed Articles', fitToFrame:true}));
            this.createView(lv.getEl());
            
            // create the preview panel and toolbar
            previewBody = Ext.get('preview-body');
            var tb = new Ext.Toolbar('preview-tb');
            
            tb.addButton({text: 'View in New Tab',icon: 'images/new_tab.gif',cls: 'x-btn-text-icon', handler: this.showInTab.createDelegate(this)});
            tb.addSeparator();
            tb.addButton({text: 'View in New Window',icon: 'images/new_window.gif',cls: 'x-btn-text-icon', handler: this.showInWindow.createDelegate(this)});
            
            preview = new Ext.ContentPanel('preview', {title: "Preview", fitToFrame:true, toolbar: tb, resizeEl:'preview-body'});
            innerLayout.add('south', preview);
            
            // restore innerLayout state
            innerLayout.restoreState();
            innerLayout.endUpdate(true);
            
            // restore any state information
            layout.restoreState();
            layout.endUpdate();
            
            this.loadFeed('http://feeds.feedburner.com/ajaxian');
            this.changeActiveFeed('ajaxian');
        },
        
        createView : function(el){
            function reformatDate(feedDate){
                var d = new Date(Date.parse(feedDate));
                return d ? d.dateFormat('D M j, Y, g:i a') : '';
            }
            
            var reader = new Ext.data.XmlReader({record: 'item'},
                ['title', {name:'pubDate', type:'date'}, 'link', 'description']
            );

            ds = new Ext.data.Store({
                proxy: new Ext.data.HttpProxy({
                    url: 'feed-proxy.php'
                }),
                reader : reader
            });
            
            ds.on('load', this.onLoad, this);
            
            var tpl = new Ext.Template(
                  '<div class="feed-item">' +
                  '<div class="item-title">{title}</div>' +
                  '<div class="item-date">{date}</div>' +
                  '{desc}</div>'
            );
            
            var view = new Ext.View(el, tpl, {store: ds, singleSelect:true, selectedClass:'selected-article'});
            view.prepareData = function(data){
                return {
                    title: data.title,
                    date: reformatDate(data.pubDate),
                    desc: data.description.replace(/<\/?[^>]+>/gi, '').ellipse(350)
                
                };
            };
            view.on('click', this.showPost, this);
            view.on('dblclick', this.showFullPost, this);
        },
        
        onLoad : function(){
            if(ds.getCount() < 1){
        		preview.setContent('');
        	}
            statusPanel.getEl().addClass('done');
            statusPanel.setContent('Done.');
        },
        
        loadFeed : function(feed){
        	statusPanel.setContent('Loading feed ' + feed + '...');
        	statusPanel.getEl().removeClass('done');
            //ds.load({'feed': feed});
            //cgsktca
            ds.load({params:{'feed': feed}});
        },
        
        showPost : function(view, dataIndex){            
            var node = ds.getAt(dataIndex);
            var title = node.data.title;
            var link = node.data.link;
            var desc = node.data.description;
              		
    		    currentItem = {
    		        index: dataIndex, link: link
    		    };
    		    preview.setTitle(title.ellipse(80));
    		    previewBody.update(desc);
        },
        
        showFullPost : function(view, rowIndex){
          var node = ds.getAt(rowIndex);
    		  var link = node.data.link;
    		  var title = node.data.title;
    		  
    		  if(!title){
    		      title = 'View Post';
    		  }
    		  var iframe = Ext.DomHelper.append(document.body, 
    		              {tag: 'iframe', frameBorder: 0, src: link});
    		  var panel = new Ext.ContentPanel(iframe, 
    		              {title: title, fitToFrame:true, closable:true});
    		  layout.add('center', panel);     	
        },
        
        showInTab : function(){
            if(currentItem){
                this.showFullPost(grid, currentItem.index);
            }
        },
        
        showInWindow : function(){
            if(currentItem){
                window.open(currentItem.link, 'win');
            }
        },
        
        changeActiveFeed : function(feedId){
            suggested.select('a').removeClass('selected');
            feeds.select('a').removeClass('selected');
            Ext.fly('feed-'+feedId).addClass('selected');
            var feed = sfeeds[feedId] || myfeeds[feedId];
            feedPanel.setTitle('View Feed (' + feed.name.ellipse(16) + ')');
        },
        
        showAddFeed : function(btn){
            Ext.get('feed-url').dom.value = '';
            Ext.get('add-title').radioClass('active-msg');
            var el = Ext.get('myfeeds-tb');

            addFeed.alignTo('myfeeds-tb', 'tl', [3,3]);
            addFeed.show();
        },        
        
        validateFeed : function(){
            var url = Ext.get('feed-url').dom.value;
            Ext.get('loading-feed').radioClass('active-msg');
            var success = function(o){
                try{
                    var xml = o.responseXML;
                    var channel = xml.getElementsByTagName('channel')[0];
                    var titleEl = channel.getElementsByTagName('title')[0];
                    var descEl = channel.getElementsByTagName('description')[0];
                    var name = titleEl.firstChild.nodeValue;
                    var desc = (descEl.firstChild ? descEl.firstChild.nodeValue : '');
                    var id = ++seed;
                    myfeeds[id] = {id:id, name:name, desc:desc, url:url};
                    tpl.append('myfeeds-body', myfeeds[id]);
                    
                    addFeed.hide();  
                   
                      
                    ds.loadData(xml); 
                    this.changeActiveFeed(id);
                                       
                }catch(e){
                    Ext.get('invalid-feed').radioClass('active-msg');                   
                }                     
            }.createDelegate(this);
            var failure = function(o){
                Ext.get('invalid-feed').radioClass('active-msg');
            };
            Ext.lib.Ajax.request('POST', 'feed-proxy.php', {success:success, failure:failure}, 'feed='+encodeURIComponent(url));
        }
    };
}();
Ext.onReady(Viewer.init, Viewer);

String.prototype.ellipse = function(maxLength){
    if(this.length > maxLength){
        return this.substr(0, maxLength-3) + '...';
    }
    return this;
};

