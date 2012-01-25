var Docs = function(){
    var layout, center;
    
    var classClicked = function(e, target){
        Docs.loadDoc(target.href);
    };
    
    return {
        init : function(){
            // initialize state manager, we will use cookies
            Ext.state.Manager.setProvider(new Ext.state.CookieProvider());
            
            // create the main layout
            layout = new Ext.BorderLayout(document.body, {
                north: {
                    split:false,
                    initialSize: 32,
                    titlebar: false
                },
                west: {
                    split:true,
                    initialSize: 250,
                    minSize: 175,
                    maxSize: 400,
                    titlebar: true,
                    collapsible: true,
                    animate: true,
                    useShim:true,
                    cmargins: {top:2,bottom:2,right:2,left:2}
                },
                center: {
                    titlebar: true,
                    title: 'View Documentation',
                    autoScroll:false,
                    tabPosition: 'top',
                    closeOnTab: true,
                    //alwaysShowTabs: true,
                    resizeTabs: true
                }
            });
            // tell the layout not to perform layouts until we're done adding everything
            layout.beginUpdate();
            layout.add('north', new Ext.ContentPanel('header'));
            
            layout.add('west', new Ext.ContentPanel('classes', {title: 'Documentation Explorer', fitToFrame:true}));
            center = layout.getRegion('center');
            center.add(new Ext.ContentPanel('main', {fitToFrame:true}));
            
            layout.restoreState();
            layout.endUpdate();
            
            var classes = Ext.get('classes');
			if(Docs.classData){
				var tree = new Ext.tree.TreePanel(classes, {
					loader: new Ext.tree.TreeLoader(),
					rootVisible:false,
                    animate:false
                });
                new Ext.tree.TreeSorter(tree, {folderSort:true,leafAttr:'isClass'});
                var root = new Ext.tree.AsyncTreeNode({
					text:'Ext Docs',
					children: [Docs.classData]
				});
				tree.setRootNode(root);

                tree.on('click', function(n){
                    if(n.isLeaf()){
                        Docs.loadDoc('output/'+n.attributes.fullName+'.html');
                    }
                });

                tree.render();
			}else{
            	 classes.on('click', classClicked, null, {delegate: 'a', stopEvent:true});
		         classes.select('h3').each(function(el){
		             var c = new NavNode(el.dom);
		             if(!/^\s*(?:API Reference|Examples and Demos)\s*$/.test(el.dom.innerHTML)){
		                 c.collapse();
		             }
		         });
		    }
            var page = window.location.href.split('#')[1];
            if(!page){
                page = 'welcome.html';
            }
            this.loadDoc(page);
            // safari and opera have iframe sizing issue, relayout fixes it
			if(Ext.isSafari || Ext.isOpera){
				layout.layout();
			}
			
			var loading = Ext.get('loading');
			var mask = Ext.get('loading-mask');
			mask.setOpacity(.8);
			mask.shift({
				xy:loading.getXY(),
				width:loading.getWidth(),
				height:loading.getHeight(), 
				remove:true,
				duration:1,
				opacity:.3,
				easing:'bounceOut',
				callback : function(){
					loading.fadeOut({duration:.2,remove:true});
				}
			});
        },
        
        loadDoc : function(url){
            Ext.get('main').dom.src = url;
        }
    };
}();
Ext.onReady(Docs.init, Docs, true);

/**
 * Simple tree node class based on Collapser and predetermined markup.
 */
var NavNode = function(clickEl, collapseEl){
    this.clickEl = Ext.get(clickEl);
    if(!collapseEl){
        collapseEl = this.clickEl.dom.nextSibling;
        while(collapseEl.nodeType != 1){
            collapseEl = collapseEl.nextSibling;
        }
    }
    this.collapseEl = Ext.get(collapseEl);
    this.clickEl.addClass('collapser-expanded');
    this.clickEl.mon('click', function(){
        this.collapsed === true ? 
            this.expand() : this.collapse();
    }, this, true);
};

NavNode.prototype = {
    collapse : function(){
        this.collapsed = true;
        this.collapseEl.setDisplayed(false);
        this.clickEl.replaceClass('collapser-expanded','collapser-collapsed');
    },
    
    expand : function(){
        this.collapseEl.setDisplayed(true);
        this.collapsed = false;
        this.collapseEl.setStyle('height', '');   
        this.clickEl.replaceClass('collapser-collapsed','collapser-expanded');
    }
};