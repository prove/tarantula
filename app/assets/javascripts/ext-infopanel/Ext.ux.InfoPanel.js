// vim: ts=4:sw=4:nu:fdc=4:nospell

// Create user extensions namespace (Ext.ux)
Ext.namespace('Ext.ux');

/**
  * Ext.ux.InfoPanel Extension Class
  *
  * @author  Ing. Jozef Sakalos
  * @version $Id: Ext.ux.InfoPanel.js 153 2007-08-24 10:46:19Z jozo $
  *
  * @class Ext.ux.InfoPanel
  * @extends Ext.ContentPanel
  * @constructor
  * Creates new Ext.ux.InfoPanel
  * @param {String/HTMLElement/Element} el The container element for this panel
  * @param {String/Object} config A string to set only the title or a config object
  * @param {String} content (optional) Set the HTML content for this panel
  * @cfg {Boolean} animate set to true to switch animation of expand/collapse on (defaults to undefined)
  * @cfg {String} bodyClass css class added to the body in addition to the default class(es)
  * @cfg {String/HTMLElement/Element} bodyEl This element is used as body of panel.
  * @cfg {String} buttonPosition set this to 'left' to place expand button to the left of titlebar
  * @cfg {Boolean} collapsed false to start with the expanded body (defaults to true)
  * @cfg {String} collapsedIcon Path for icon to display in the title when panel is collapsed
  * @cfg {Boolean} collapseOnUnpin unpinned panel is collapsed when possible (defaults to true)
  * @cfg {Boolean} collapsible false to disable collapsibility (defaults to true)
  * @cfg {Boolean} draggable true to allow panel dragging (defaults to undefined)
  * @cfg {Float} duration Duration of animation in seconds (defaults to 0.35)
  * @cfg {String} easingCollapse Easing to use for collapse animation (e.g. 'backIn')
  * @cfg {String} easingExpand Easing to use for expand animation (e.g. 'backOut')
  * @cfg {String} expandedIcon Path for icon to display in the title when panel is expanded
  * @cfg {String} icon Path for icon to display in the title
  * @cfg {Integer} minWidth minimal width in pixels of the resizable panel (defaults to 0)
  * @cfg {Integer} maxWidth maximal width in pixels of the resizable panel (defaults to 9999)
  * @cfg {Integer} minHeight minimal height in pixels of the resizable panel (defaults to 50)
  * @cfg {Integer} maxHeight maximal height in pixels of the resizable panel (defaults to 9999)
  * @cfg {String} panelClass Set to override the default 'x-dock-panel' class.
  * @cfg {Boolean} pinned true to start in pinned state (implies collapsed:false) (defaults to false)
  * @cfg {Boolean} resizable true to allow use resize width of the panel. (defaults to undefined)
  *  Handles are transparent. (defaults to false)
  * @cfg {String} shadowMode defaults to 'sides'.
  * @cfg {Boolean} showPin Show the pin button - makes sense only if panel is part of Accordion
  * @cfg {String} trigger 'title' or 'button'. Click where expands/collapses the panel (defaults to 'title')
  * @cfg {Boolean} useShadow Use shadows for undocked panels or panels w/o dock. (defaults to undefined = don't use)
  */
Ext.ux.InfoPanel = function(el, config, content) {

	config = config || el;
	// {{{
	// basic setup
	var oldHtml = content || null;
	if(config && config.content) {
		oldHtml = oldHtml || config.content;
		delete(config.content);
	}

	// save autoScroll to this.bodyScroll
	if(config && config.autoScroll) {
		this.bodyScroll = config.autoScroll;
		delete(config.autoScroll);
	}

	var url;
	if(el && el.url) {
		url = el.url;
		delete(el.url);
	}
	if(config && config.url) {
		url = config.url;
		delete(config.url);
	}

	// call parent constructor
	Ext.ux.InfoPanel.superclass.constructor.call(this, el, config);

	this.desktop = Ext.get(this.desktop) || Ext.get(document.body);

	// shortcut of DomHelper
	var dh = Ext.DomHelper, oldTitleEl;

	this.el.clean();
	this.el.addClass(this.panelClass);

	// handle autoCreate
	if(this.autoCreate) {
		oldHtml = this.el.dom.innerHTML;
		this.el.update('');
		this.desktop.appendChild(this.el);
		this.el.removeClass('x-layout-inactive-content');
	}
	// handle markup
	else {
		this.el.clean();
		if(this.el.dom.firstChild && !this.bodyEl) {
			this.title = this.title || this.el.dom.firstChild.innerHTML;
			if(this.el.dom.firstChild.nextSibling) {
				this.body = Ext.get(this.el.dom.firstChild.nextSibling);
			}
			oldTitleEl = this.el.dom.firstChild;
			oldTitleEl = oldTitleEl.parentNode.removeChild(oldTitleEl);
			oldTitleEl = null;
		}
	}

	// get body element
	if(this.bodyEl) {
		this.body = Ext.get(this.bodyEl);
		this.el.appendChild(this.body);
	}
	// }}}
	// {{{
	// create title element
	var create;
	if('left' === this.buttonPosition ) {
		create = {
			tag:'div', unselectable:'on', cls:'x-unselectable x-layout-panel-hd x-dock-panel-title', children: [
				{tag:'table', cellspacing:0, children: [
					{tag:'tr', children: [
						{tag:'td', children:[
							{tag:'div', cls:'x-dock-panel x-dock-panel-tools'}
						]}
						, {tag:'td', width:'100%', children: [
							{tag:'div', cls:'x-dock-panel x-layout-panel-hd-text x-dock-panel-title-text'}
						]}
						, {tag:'td', cls:'x-dock-panel-title-icon-ct', children: [
							{tag:'img', alt:'', cls:'x-dock-panel-title-icon'}
						]}
					]}
				]}
			]};
	}
	else {
		create = {
			tag:'div', unselectable:'on', cls:'x-unselectable x-layout-panel-hd x-dock-panel-title', children: [
				{tag:'table', cellspacing:0, children: [
					{tag:'tr', children: [
						{tag:'td', cls:'x-dock-panel-title-icon-ct', children: [
							{tag:'img', alt:'', cls:'x-dock-panel-title-icon'}
						]}
						, {tag:'td', width:'100%', children: [
							{tag:'div', cls:'x-dock-panel x-layout-panel-hd-text x-dock-panel-title-text'}
						]}
						, {tag:'td', children:[
							{tag:'div', cls:'x-dock-panel x-dock-panel-tools'}
						]}
					]}
				]}
			]};
	}
	this.titleEl = dh.insertFirst(this.el.dom, create, true);
	this.iconImg = this.titleEl.select('img.x-dock-panel-title-icon').item(0);
	this.titleEl.addClassOnOver('x-dock-panel-title-over');
	this.titleEl.enableDisplayMode();
	this.titleTextEl = Ext.get(this.titleEl.select('.x-dock-panel-title-text').elements[0]);
	this.tools = Ext.get(this.titleEl.select('.x-dock-panel-tools').elements[0]);
	if('right' === this.titleTextAlign) {
		this.titleTextEl.addClass('x-dock-panel-title-right');
	}

	this.tm = Ext.util.TextMetrics.createInstance(this.titleTextEl);
	// }}}
	// {{{
	// set title
	if(this.title) {
		this.setTitle(this.title);
	}
	// }}}
	// {{{
	// create pin button
	if(this.showPin) {
		this.stickBtn = this.createTool(this.tools.dom, 'x-layout-stick');
		this.stickBtn.enableDisplayMode();
		this.stickBtn.on('click', function(e, target) {
			e.stopEvent();
			this.pinned = ! this.pinned;
			this.updateVisuals();
			this.fireEvent('pinned', this, this.pinned);
		}, this);
		this.stickBtn.hide();	
	}
	// }}}
	// {{{
	// create collapse button
	if(this.collapsible) {
	    this.collapseBtn = this.createTool(this.tools.dom,
			                       (this.collapsed ? 'x-layout-collapse-east' : 'x-layout-collapse-south')
		                              );
		this.collapseBtn.enableDisplayMode();
		if('title' === this.trigger) {
			this.titleEl.addClass('x-window-header-text');
			this.titleEl.on({
				  click:{scope: this, fn:this.toggle}
				, selectstart:{scope: this, fn: function(e) {
						e.preventDefault();
						return false;
				}}
			}, this);
		}
		else {
			this.collapseBtn.on("click", this.toggle, this);
		}
	}
	// }}}
	// {{{
	// create body if it doesn't exist yet
	if(!this.body) {
			this.body = dh.append(this.el, {
			    tag: 'div',
			    cls: this.bodyClass || null,
			    html: oldHtml || ''
			}, true);
	}
	this.body.enableDisplayMode();
	if(this.collapsed && !this.pinned) {
		this.body.hide();
	}
	else if(this.pinned) {
		this.body.show();
		this.collapsed = false;
	}
	this.body.addClass(this.bodyClass);
	this.body.addClass('x-dock-panel-body-undocked');

	// bodyScroll

	this.scrollEl = this.body;

	// autoScroll -> bodyScroll is experimental due to IE bugs
	this.scrollEl.setStyle('overflow', 
		this.bodyScroll === true && !this.collapsed ? 'auto' : 'hidden');
	// }}}

	if(this.fixedHeight) {
		this.setHeight(this.fixedHeight);
	}

	if(url) {
		this.setUrl(url, this.params, this.loadOnce);
	}

	// install hook for title context menu
	if(this.titleMenu) {
		this.setTitleMenu(this.titleMenu);
	}

	// install hook for icon menu
	if(this.iconMenu) {
		this.setIconMenu(this.iconMenu);
	}

	// {{{
	// add events
	this.addEvents({
		/**
			* @event beforecollapse
			* Fires before collapse is taking place. Return false to cancel collapse
			* @param {Ext.ux.InfoPanel} this
			*/
		beforecollapse: true
		/**
			* @event collapse
			* Fires after collapse
			* @param {Ext.ux.InfoPanel} this
			*/
		, collapse: true
		/**
			* @event beforecollapse
			* Fires before expand is taking place. Return false to cancel expand
			* @param {Ext.ux.InfoPanel} this
			*/
		, beforeexpand: true
		/**
			* @event expand
			* Fires after expand
			* @param {Ext.ux.InfoPanel} this
			*/
		, expand: true
		/**
			* @event pinned
			* Fires when panel is pinned/unpinned
			* @param {Ext.ux.InfoPanel} this
			* @param {Boolean} pinned true if the panel is pinned
			*/
		, pinned: true
		/**
			* @event animationcompleted
			* Fires when animation is completed
			* @param {Ext.ux.InfoPanel} this
			*/
		, animationcompleted: true
		/**
			* @event boxchange
			* Fires when the panel is resized
			* @param {Ext.ux.InfoPanel} this
			* @param {Object} box
			*/
		, boxchange: true

		/**
			* @event redize
			* Fires when info panel is resized
			* @param {Ext.ux.InfoPanel} this
			* @param {Integer} width New width
			* @param {Integer} height New height
			*/
		, resize: true

		/**
			* @event destroy
			* Fires after the panel is destroyed
			* @param {Ext.ux.InfoPanel} this
			*/
		, destroy: true

	});
	// }}}
	// {{{
	// setup dragging, resizing, and shadow
	this.setDraggable(this.draggable);
	this.setResizable(!this.collapsed);
	this.setShadow(this.useShadow);

	// }}}

	this.el.setStyle('z-index', this.zindex);
	this.updateVisuals();

	this.id = this.id || this.el.id;

}; // end of constructor

// extend
Ext.extend(Ext.ux.InfoPanel, Ext.ContentPanel, {

	// {{{
	// defaults
    adjustments: [0,0],
    collapsible: true,
    collapsed: true,
    collapseOnUnpin: true,
    pinned: false,
    trigger: 'title',
    animate: undefined,
    duration: 0.35,
    draggable: undefined,
    resizable: undefined,
    docked: false,
    useShadow: undefined,
    bodyClass: 'x-dock-panel-body',
    panelClass: 'x-dock-panel',
    shadowMode: 'sides',
    dragPadding: {
	left:8,
	right:16,
	top:0,
	bottom:8
    },
    lastWidth: 0,
    lastHeight: 0,
    minWidth: 0,
    maxWidth: 9999,
    minHeight: 50,
    maxHeight: 9999,
    autoScroll: false,
    fixedHeight: undefined,
    zindex: 10000,
	// }}}
	// {{{
	/**
		* Called internally to create collapse button
		* Calls utility method of Ext.LayoutRegion createTool
		* @param {Element/HTMLElement/String} parentEl element to create the tool in
		* @param {String} className class of the tool
		*/
    createTool : function(parentEl, className){
	return Ext.LayoutRegion.prototype.createTool(parentEl, className);
    }
	// }}}
	// {{{
	/**
		* Set title of the InfoPanel
		* @param {String} title Title to set
		* @return {Ext.ux.InfoPanel} this
		*/
	, setTitle: function(title) {
		this.title = title;
		this.titleTextEl.update(title);
		this.setIcon();
		return this;
	}
	// }}}
	// {{{
	/**
		* Set the icon to display in title
		* @param {String} iconPath path to use for src property of icon img
		*/
	, setIcon: function(iconPath) {
		iconPath = iconPath || (this.collapsed ? this.collapsedIcon : this.expandedIcon) || this.icon;
		if(iconPath) {
			this.iconImg.dom.src = iconPath;
		}
		else {
			this.iconImg.dom.src = Ext.BLANK_IMAGE_URL;
		}
	}
	// }}}
	// {{{
	/**
		* Assigns menu to title icon
		* @param {Ext.menu.Menu} menu menu to assign
		*/
	, setIconMenu: function(menu) {
		if(this.iconMenu) {
			this.iconImg.removeAllListeners();
		}
		menu.panel = this;
		this.iconImg.on({
			click: {
				scope: this
				, fn: function(e, target) {
				e.stopEvent();
				menu.showAt(e.xy);
			}}
		});
		this.iconMenu = menu;
	}
	// }}}
	// {{{
	/**
		* private - title menu click handler
		* @param {Ext.Event} e event
		* @param {Element} target target
		*/
	, onTitleMenu: function(e, target) {
		e.stopEvent();
		e.preventDefault();
		this.titleMenu.showAt(e.xy);	
	}
	// }}}
	// {{{
	/**
		* Assigns context menu (right click) to the title 
		* @param {Ext.menu.Menu} menu menu to assign
		*/
	, setTitleMenu: function(menu) {
		if(this.titleMenu) {
			this.titleEl.un('contextmenu', this.onTitleMenu, this);
		}
		menu.panel = this;
		this.titleEl.on('contextmenu', this.onTitleMenu, this);
		this.titleMenu = menu;
	}
	// }}}
	// {{{
	/**
		* Get current title
		* @return {String} Current title
		*/
	, getTitle: function() {
		return this.title;
	}
	// }}}
	// {{{
	/**
		* Returns body element
		* This overrides the ContentPanel getEl for convenient access to the body element
		* @return {Element} this.body
		*/
	, getEl: function() {
		return this.body;
	}
	// }}}
	// {{{
	/**
		* Returns title height
		* @return {Integer} title height
		*/
	, getTitleHeight: function() {
		return this.titleEl.getComputedHeight();
	}
	// }}}
	// {{{
	/**
		* Returns body height
		* @return {Integer} body height
		*/
	, getBodyHeight: function() {
		return this.body.getComputedHeight();
	}
	// }}}
	// {{{
	/**
		* Returns panel height
		* @return {Integer} panel height
		*/
	, getHeight: function() {
		return this.getBodyHeight() + this.getTitleHeight();
	}
	// }}}
	// {{{
	/**
		* Returns body client height
		* @return {Integer} body client height
		*/
	, getBodyClientHeight: function() {
		return this.body.getHeight(true);
	}
	// }}}
	// {{{
	/**
		* Update the innerHTML of this element, optionally searching for and processing scripts
    * @param {String} html The new HTML
    * @param {Boolean} loadScripts (optional) true to look for and process scripts
    * @param {Function} callback For async script loading you can be noticed when the update completes
    * @return {Ext.Element} this
		*/
	, update: function(html, loadScripts, callback) {
		this.body.update(html, loadScripts, callback);
		return this;
	}
	// }}}
	// {{{
	/**
	 * Updates this panel's element
	 * @param {String} content The new content
	 * @param {Boolean} loadScripts (optional) true to look for and process scripts
	*/
	, setContent: function(content, loadScripts) {
			this.body.update(content, loadScripts);
	}
	// }}}
	// {{{
	/**
	 * Get the {@link Ext.UpdateManager} for this panel. Enables you to perform Ajax updates.
	 * @return {Ext.UpdateManager} The UpdateManager
	 */
	, getUpdateManager: function() {
			return this.body.getUpdateManager();
	}
	// }}}
	// {{{
	/**
	 * The only required property is url. The optional properties nocache, text and scripts 
	 * are shorthand for disableCaching, indicatorText and loadScripts and are used to set their associated property on this panel UpdateManager instance.
	 * @param {String/Object} params (optional) The parameters to pass as either a url encoded string "param1=1&amp;param2=2" or an object {param1: 1, param2: 2}
	 * @param {Function} callback (optional) Callback when transaction is complete - called with signature (oElement, bSuccess, oResponse)
	 * @param {Boolean} discardUrl (optional) By default when you execute an update the defaultUrl is changed to the last used url. If true, it will not store the url.
	 * @return {Ext.ContentPanel} this
	 */
	, load: function() {
			var um = this.getUpdateManager();
			um.update.apply(um, arguments);
			return this;
	}
	// }}}
	// {{{
	/**
	 * Set a URL to be used to load the content for this panel. When this panel is activated, the content will be loaded from that URL.
	 * @param {String/Function} url The url to load the content from or a function to call to get the url
	 * @param {String/Object} params (optional) The string params for the update call or an object of the params. See {@link Ext.UpdateManager#update} for more details. (Defaults to null)
	 * @param {Boolean} loadOnce (optional) Whether to only load the content once. If this is false it makes the Ajax call every time this panel is activated. (Defaults to false)
	 * @return {Ext.UpdateManager} The UpdateManager
	 */
	, setUrl: function(url, params, loadOnce) {
			if(this.refreshDelegate){
					this.removeListener("expand", this.refreshDelegate);
			}
			this.refreshDelegate = this._handleRefresh.createDelegate(this, [url, params, loadOnce]);
			this.on("expand", this.refreshDelegate);
			this.on({
				beforeexpand: {
					scope: this
					, single: this.loadOnce ? true : false
					, fn: function() {
						this.body.update('');
				}}
			});
			return this.getUpdateManager();
	}
	// }}}
	// {{{
	, _handleRefresh: function(url, params, loadOnce) {
			var updater;
			if(!loadOnce || !this.loaded){
					updater = this.getUpdateManager();
					updater.on({
						update: {
							scope: this
							, single: true
							, fn: function() {
								if(true === this.useShadow && this.shadow) {
									this.shadow.show(this.el);
								}
						}}
					});
					updater.update(url, params, this._setLoaded.createDelegate(this));
			}
	}
	// }}}
	// {{{
	, _setLoaded: function() {
			this.loaded = true;
	} 
	// }}}
  // {{{
	/**
	 *   Force a content refresh from the URL specified in the setUrl() method.
	 *   Will fail silently if the setUrl method has not been called.
	 *   This does not activate the panel, just updates its content.
	 */
	, refresh: function() {
			if(this.refreshDelegate){
				 this.loaded = false;
				 this.refreshDelegate();
			}
	}
	// }}}
	// {{{
	/**
		* Expands the panel
		* @param {Boolean} skipAnimation Set to true to skip animation
		* @return {Ext.ux.InfoPanel} this
		*/
	, expand: function(skipAnimation) {

		// do nothing if already expanded
		if(!this.collapsed) {
			return this;
		}

		// fire beforeexpand event
		if(false === this.fireEvent('beforeexpand', this)) {
			return this;
		}

		if(Ext.isGecko) {
			this.autoScrolls = this.body.select('{overflow=auto}');
			this.autoScrolls.setStyle('overflow', 'hidden');
		}

		// reset collapsed flag
		this.collapsed = false;

		this.autoSize();

		// hide shadow
		if(!this.docked) {
			this.setShadow(false);
		}

		// enable resizing
		if(this.resizer && !this.docked) {
			this.setResizable(true);
		}
		
                // Fix #425 -- iiska
		//if(Ext.isIE) {
		//	this.body.setWidth(this.el.getWidth());
		//}

		// animate expand
		if(true === this.animate && true !== skipAnimation) {
				this.body.slideIn('t', {
				    easing: this.easingExpand || null,
				    scope: this,
				    duration: this.duration,
				    callback: this.updateVisuals
				});
		}

		// don't animate, just show
		else {
			this.body.show();
			this.updateVisuals();
			this.fireEvent('animationcompleted', this);
		}

		// fire expand event
		this.fireEvent('expand', this);

		return this;

	}
	// }}}
	// {{{
	/**
		* Toggles the expanded/collapsed states
		* @param {Boolean} skipAnimation Set to true to skip animation
		* @return {Ext.ux.InfoPanel} this
		*/
	, toggle: function(skipAnimation) {
			if(this.collapsed) {
				this.expand(skipAnimation);
			}
			else {
				this.collapse(skipAnimation);
			}
			return this;
	}
	// }}}
	// {{{
	/**
		* Collapses the panel
		* @param {Boolean} skipAnimation Set to true to skip animation
		* @return {Ext.ux.InfoPanel} this
		*/
	, collapse: function(skipAnimation) {

		// do nothing if already collapsed or pinned
		if(this.collapsed || this.pinned) {
			return this;
		}

		// fire beforecollapse event
		if(false === this.fireEvent('beforecollapse', this)) {
				return this;
		}

		if(Ext.isGecko) {
			this.autoScrolls = this.body.select('{overflow=auto}');
			this.autoScrolls.setStyle('overflow', 'hidden');
		}

		if(this.bodyScroll /*&& !Ext.isIE*/) {
			this.scrollEl.setStyle('overflow','hidden');
		}

		// set collapsed flag
		this.collapsed = true;

		// hide shadow
		this.setShadow(false);

		// disable resizing of collapsed panel
		if(this.resizer) {
			this.setResizable(false);
		}

		// animate collapse
		if(true === this.animate && true !== skipAnimation) {
				this.body.slideOut('t', {
				    easing: this.easingCollapse || null,
				    scope: this,
				    duration: this.duration,
				    callback: this.updateVisuals
				});
		}

		// don't animate, just hide
		else {
			this.body.hide();
			this.updateVisuals();
			this.fireEvent('animationcompleted', this);
		}

		// fire collapse event
		this.fireEvent('collapse', this);

		return this;

	}
	// }}}
	// {{{
	/**
		* Called internally to update class of the collapse button 
		* as part of expand and collapse methods
		*
		* @return {Ext.ux.InfoPanel} this
		*/
	, updateVisuals: function() {

			// handle collapsed state
			if(this.collapsed) {
				if(this.showPin) {
					if(this.collapseBtn) {
						this.collapseBtn.show();
					}
					if(this.stickBtn) {
						this.stickBtn.hide();
					}
				}
				if(this.collapseBtn) {
					Ext.fly(this.collapseBtn.dom.firstChild).replaceClass('x-layout-collapse-south',
                                                                                          'x-layout-collapse-east');
				}
				this.body.replaceClass('x-dock-panel-body-expanded', 'x-dock-panel-body-collapsed');
				this.titleEl.replaceClass('x-dock-panel-title-expanded', 'x-dock-panel-title-collapsed');
			}
			
			// handle expanded state
			else {
				if(this.showPin) {
					if(this.pinned) {	
						if(this.stickBtn) {
							Ext.fly(this.stickBtn.dom.firstChild).replaceClass('x-layout-stick', 'x-layout-stuck');
						}
						this.titleEl.addClass('x-dock-panel-title-pinned');
					}
					else {
						if(this.stickBtn) {
							Ext.fly(this.stickBtn.dom.firstChild).replaceClass('x-layout-stuck', 'x-layout-stick');
						}
						this.titleEl.removeClass('x-dock-panel-title-pinned');
					}
					if(this.collapseBtn) {
						this.collapseBtn.hide();
					}
					if(this.stickBtn) {
						this.stickBtn.show();
					}
				}
				else {
					if(this.collapseBtn) {
						Ext.fly(this.collapseBtn.dom.firstChild).replaceClass('x-layout-collapse-east',
                                                                                                      'x-layout-collapse-south');
					}
				}
				this.body.replaceClass('x-dock-panel-body-collapsed', 'x-dock-panel-body-expanded');
				this.titleEl.replaceClass('x-dock-panel-title-collapsed', 'x-dock-panel-title-expanded');
			}

			// show shadow if necessary
			if(!this.docked) {
				this.setShadow(true);
			}

			if(this.autoScrolls) {
				this.autoScrolls.setStyle('overflow', 'auto');
			}

			this.setIcon();

			if(this.bodyScroll && !this.docked && !this.collapsed /*&& !Ext.isIE*/) {
				this.scrollEl.setStyle('overflow', 'auto');
			}

			this.constrainToDesktop();

			// fire animationcompleted event
			this.fireEvent('animationcompleted', this);

			// clear visibility style of body's children
			var kids = this.body.select('div[className!=x-grid-viewport],input{visibility}');
			kids.setStyle.defer(1, kids, ['visibility','']);

			// restore body overflow
			if(this.bodyScroll && !this.collapsed /*&& !Ext.isIE*/) {
				this.setHeight(this.getHeight());
				this.scrollEl.setStyle('overflow','auto');
			}

			return this;
	}
	// }}}
	// {{{
	/**
		* Creates toolbar
		* @param {Array} config Configuration for Ext.Toolbar
		* @param {Boolean} bottom true to create bottom toolbar. (defaults to false = top toolbar)
		* @return {Ext.Toolbar} Ext.Toolbar object
		*/
	, createToolbar: function(config, bottom) {

		// we need clean body
		this.body.clean();

		// copy body to new container
		this.scrollEl = Ext.DomHelper.append(document.body, {tag:'div'}, true);
		var el;
	    while((el = this.body.down('*'))) {
			this.scrollEl.appendChild(el);
		}

		if(this.bodyScroll) {
			this.body.setStyle('overflow', '');
			if(!this.collapsed) {
				this.scrollEl.setStyle('overflow', 'auto');
			}
		}

		var create = {tag:'div'}, tbEl;
		config = config || null;
		if(bottom) {
			this.body.appendChild(this.scrollEl);
			tbEl = Ext.DomHelper.append(this.body, create, true);
			tbEl.addClass('x-dock-panel-toolbar-bottom');
		}
		else {
			tbEl = Ext.DomHelper.insertFirst(this.body, create, true);
			tbEl.addClass('x-dock-panel-toolbar');
			this.body.appendChild(this.scrollEl);
		}
		this.toolbar = new Ext.Toolbar(tbEl, config);
		this.setHeight(this.getHeight());
		return this.toolbar;
	}
	// }}}
	// {{{
	/**
		* Set the panel draggable
		* Uses lazy creation of dd object
		* @param {Boolean} enable pass false to disable dragging
		* @return {Ext.ux.InfoPanel} this
		*/
	, setDraggable: function(enable) {

		if(true !== this.draggable) {
			return this;
		}

		// lazy create proxy
		var dragTitleEl;
		if(!this.proxy) {
			this.proxy = this.el.createProxy('x-dlg-proxy');

			// setup title
			dragTitleEl = Ext.DomHelper.append(this.proxy, {tag:'div'}, true);
			dragTitleEl.update(this.el.dom.firstChild.innerHTML);
			dragTitleEl.dom.className = this.el.dom.firstChild.className;
			if(this.collapsed && Ext.isIE) {
				dragTitleEl.dom.style.borderBottom = "0";
			}

			this.proxy.hide();
			this.proxy.setOpacity(0.5);
			this.dd = new Ext.dd.DDProxy(this.el.dom, 'PanelDrag', {
			    dragElId: this.proxy.id,
			    scroll: false
			});
			this.dd.scroll = false;
			this.dd.afterDrag = function() {
				this.panel.moveToViewport();
				if(this.panel && this.panel.shadow && !this.panel.docked) {
					this.panel.shadow.show(this.panel.el);
				}
			};

			this.constrainToDesktop();
			Ext.EventManager.onWindowResize(this.moveToViewport, this);
		}

		this.dd.panel = this;
		this.dd.setHandleElId(this.titleEl.id);
		if(false === enable) {
			this.dd.lock();
		}
		else {
			this.dd.unlock();
		}

		return this;
	}
	// }}}
	// {{{
	/**
		* Set the panel resizable
		* Uses lazy creation of the resizer object
		* @param {Boolean} pass false to disable resizing
		* @return {Ext.ux.InfoPanel} this
		*/
	, setResizable: function(enable) {

		if(true !== this.resizable) {
			return this;
		}

		// {{{
		// lazy create resizer
		if(!this.resizer) {

			// {{{
			// create resizer
			this.resizer = new Ext.Resizable(this.el, {
			    handles: 's w e sw se',
			    minWidth: this.minWidth || this.tm.getWidth(this.getTitle()) + 56 || 48,
			    maxWidth: this.maxWidth,
			    minHeight: this.minHeight,
			    maxHeight: this.maxHeight,
			    transparent: true,
			    draggable: false
			});
			// }}}
			// {{{
			// install event handlers
			this.resizer.on({
				beforeresize: {
					scope:this
					, fn: function(resizer, e) {
						var viewport = this.getViewport();
						var box = this.getBox();

						var pos = resizer.activeHandle.position;

						// left constraint
						if(pos.match(/west/)) {
							resizer.minX = viewport.x + (this.dragPadding.left || 8);
						}

						// down constraint
						var maxH;
						if(pos.match(/south/)) {
							resizer.oldMaxHeight = resizer.maxHeight;
							maxH = viewport.y + viewport.height - box.y - (this.dragPadding.bottom || 8);
							resizer.maxHeight = maxH < resizer.maxHeight ? maxH : resizer.maxHeight;
						}

						// right constraint
						var maxW;
						if(pos.match(/east/)) {
							resizer.oldMaxWidth = resizer.maxWidth;
							maxW = viewport.x + viewport.width - box.x - (this.dragPadding.right || 10);
							resizer.maxWidth = maxW < resizer.maxWidth ? maxW : resizer.maxWidth;
						}
				}}
				, resize: {
					scope: this
					, fn: function(resizer, width, height, e) {
						resizer.maxHeight = resizer.oldMaxHeight || resizer.maxHeight;
						resizer.maxWidth = resizer.oldMaxWidth || resizer.maxWidth;
						this.setSize(width, height);
						this.constrainToDesktop();
						this.fireEvent('boxchange', this, this.el.getBox());
						this.fireEvent('resize', this, width, height);
						this.lastHeight = height;
						this.lastWidth = width;
				}}
			});
			// }}}

		}
		// }}}

		this.resizer.enabled = enable;

		// this is custom override of Ext.Resizer
		this.resizer.showHandles(enable);

		return this;
	}
	// }}}
	// {{{
	/**
		* Called internally to clip passed width and height to viewport
		* @param {Integer} w width
		* @param {Integer} h height
		* @return {Object} {width:safeWidth, height:safeHeight}
		*/
	, safeSize: function(w, h) {
		var viewport = this.getViewport();
		var box = this.getBox();
		var gap = 0;
		var safeSize = {width:w, height:h};

		safeSize.height = 
		box.y + h + this.dragPadding.bottom + gap > viewport.height + viewport.y ? 
		viewport.height - box.y + viewport.y - this.dragPadding.bottom - gap : 
		safeSize.height;

		safeSize.width = 
		box.x + w + this.dragPadding.right + gap > viewport.width + viewport.x ?
		viewport.width - box.x + viewport.x - this.dragPadding.right - gap : 
		safeSize.width;

		return safeSize;
	}
	// }}}
	// {{{
	/**
		* Called internally to get current viewport
		* @param {Element/HTMLElement/String} desktop Element to get size and position of
		* @return {Object} viewport {x:x, y:y, width:width, height:height} x and y are page coords
		*/
	, getViewport: function(desktop) {

		desktop = desktop || this.desktop || document.body;
		var viewport = Ext.get(desktop).getViewSize();
		var xy;
		if(document.body === desktop.dom) {
			viewport.x = 0;
			viewport.y = 0;
		}
		else {
			xy = desktop.getXY();
			viewport.x = isNaN(xy[0]) ? 0 : xy[0];
			viewport.y = isNaN(xy[1]) ? 0 : xy[1];
		}

		return viewport;
	}
	// }}}
	// {{{
	/**
		* Sets the size of the panel. Demanded size is clipped to the viewport
		*
		* @param {Integer} w width to set
		* @param {Integer} h height to set
		* @return {Ext.ux.InfoPanel} this
		*/
	, setSize: function(w, h) {
		var safeSize = this.safeSize(w, h);
		this.setWidth(safeSize.width);
		this.setHeight(safeSize.height);
		if(Ext.isIE) {
			this.body.setWidth(safeSize.width);
		}

		if(!this.docked) {
			this.setShadow(true);
		}
	}
	// }}}
	// {{{
	/**
		* Sets the width of the panel. Demanded width is clipped to the viewport
		*
		* @param {Integer} w width to set
		* @return {Ext.ux.InfoPanel} this
		*/
	, setWidth: function(w) {
		this.el.setWidth(w);
		this.body.setStyle('width','');
		if(!this.docked) {
			this.setShadow(true);
		}
		this.lastWidth = w;

		return this;
	}
	// }}}
	// {{{
	/**
		* Sets the height of the panel. Demanded height is clipped to the viewport
		*
		* @param {Integer} h height to set
		* @return {Ext.ux.InfoPanel} this
		*/
	, setHeight: function(h) {
		var newH = h - this.getTitleHeight();
		var scrollH = newH;
		if(1 < newH) {
			if(this.scrollEl !== this.body) {
				scrollH -= this.toolbar ? this.toolbar.getEl().getHeight() : 0;
//				scrollH -= 27;
				scrollH -= this.adjustments[1] || 0;
				this.scrollEl.setHeight(scrollH);
			}
			this.body.setHeight(newH);
		}
		else {
			this.body.setStyle('height','');
		}

		if(!this.docked) {
			this.setShadow(true);
		}
//		this.lastHeight = h;
		this.el.setStyle('height','');

		return this;
	}
	// }}}
	// {{{
	/**
		* Called internally to set x, y, width and height of the panel
		*
		* @param {Object} box
		* @return {Ext.ux.InfoPanel} this
		*/
	, setBox: function(box) {
		this.el.setBox(box);
		this.moveToViewport();
		this.setSize(box.width, box.height);

		return this;
	}
	// }}}
	// {{{
	/**
		* Called internally to get the box of the panel
		*
		* @return {Object} box
		*/
	, getBox: function() {
		return this.el.getBox();
	}
	// }}}
	// {{{
	, autoSize: function() {

		var width = 0;
		var height = this.fixedHeight || 0;
		var dock = this.dock;

		// docked
		if(this.docked && this.dock) {
			if(dock.fitHeight) {
				height = dock.getPanelBodyHeight() + this.getTitleHeight();
			}
		}

		// undocked
		else {
			// height logic
			height = this.lastHeight || this.fixedHeight || 0;
			height = height < this.maxHeight ? height : (this.maxHeight < 9999 ? this.maxHeight : 0);
			height = (height && height < this.minHeight ) ? this.minHeight : height;
			this.lastHeight = height ? height : this.lastHeight;
		}

		this.setHeight(height);

	}
	// }}}
	// {{{
	/**
		* Turns shadow on/off
		* Uses lazy creation of the shadow object
		* @param {Boolean} shadow pass false to hide, true to show the shadow
		* @return {Ext.ux.InfoPanel} this
		*/
	, setShadow: function(shadow) {

		// if I have shadow but shouldn't use it
		if(this.shadow && true !== this.useShadow) {
			this.shadow.hide();
			return this;
		}

		// if I shouldn't use shadow
		if(true !== this.useShadow) {
			return this;
		}

		// if I don't have shadow
		if(!this.shadow) {
			this.shadow = new Ext.Shadow({mode:this.shadowMode});
		}

		// show or hide
		var zindex;
		if(shadow) {
			this.shadow.show(this.el);

			// fix the Ext shadow z-index bug
			zindex = parseInt(this.el.getStyle('z-index'), 10);
			zindex = isNaN(zindex) ? '' : zindex - 1;
			this.shadow.el.setStyle('z-index', zindex);
		}
		else {
			this.shadow.hide();
		}

		return this;

	}
	// }}}
	// {{{
	/**
		* Show the panel
		* @param {Boolean} show (optional) if false hides the panel instead of show
		* @param {Boolean} alsoUndocked show/hide also undocked panel (defaults to false)
		* @return {Ext.ux.InfoPanel} this
		*/
	, show: function(show, alsoUndocked) {

		// ignore undocked panels if not forced to
		if(!this.docked && true !== alsoUndocked) {
			return this;
		}

		show = (false === show ? false : true);
		if(!this.docked) {
			this.setShadow(show);
		}

		this.el.setStyle('display', show ? '' : 'none');
		return this;
	}
	// }}}
	// {{{
	/**
		* Hide the panel
		* @param {Boolean} alsoUndocked show/hide also undocked panel (defaults to false)
		* @return {Ext.ux.InfoPanel} this
		*/
	, hide: function(alsoUndocked) {
		this.show(false, alsoUndocked);
	}
	// }}}
	// {{{
	/**
		* Constrains dragging of this panel to desktop boundaries
		* @param {Element} desktop the panel is to be constrained to
		* @return {Ext.ux.InfoPanel} this
		*/
	, constrainToDesktop: function(desktop) {
		desktop = desktop || this.desktop;
		if(desktop && this.dd) {
			this.dd.constrainTo(desktop, this.dragPadding, false);
		}
		return this;
	}
	// }}}
	// {{{
	/**
		* Called internally to move the panel to the viewport. 
		* Also constrains the dragging to the desktop
		*
		* @param {Object} viewport (optional) object {x:x, y:y, width:width, height:height}
		* @return {Ext.ux.InfoPanel} this
		*/
	, moveToViewport: function(viewport) {
		viewport = viewport && !isNaN(viewport.x) ? viewport : this.getViewport();
		var box = this.getBox();
		var moved = false;
		var gap = 10;

		// horizontal
		if(box.x + box.width + this.dragPadding.right > viewport.x + viewport.width) {
			moved = true;
			box.x = viewport.width + viewport.x - box.width - this.dragPadding.right - gap;
		}
		if(box.x - this.dragPadding.left < viewport.x) {
			moved = true;
			box.x = viewport.x + this.dragPadding.left + gap;
		}

		// vertical
		if(box.y + box.height + this.dragPadding.bottom > viewport.y + viewport.height) {
			moved = true;
			box.y = viewport.height + viewport.y - box.height - this.dragPadding.bottom - gap;
		}
		if(box.y - this.dragPadding.top < viewport.y) {
			moved = true;
			box.y = viewport.y + this.dragPadding.top + gap;
		}

		var oldOverflow;
		if(moved) {
			// sanity clip
			box.x = box.x < viewport.x ? viewport.x : box.x;
			box.y = box.y < viewport.y ? viewport.y : box.y;

			// prevent scrollbars from appearing
			this.desktop.oldOverflow = this.desktop.oldOverflow || this.desktop.getStyle('overflow');
			this.desktop.setStyle('overflow', 'hidden');

			// set position
			this.el.setXY([box.x, box.y]);

			// restore overflow
			this.desktop.setStyle.defer(100, this.desktop, ['overflow', this.desktop.oldOverflow]);

			if(!this.docked) {
				this.setShadow(true);
			}
		}

		this.constrainToDesktop();

		return this;
	}
	// }}}
	// {{{
	/**
		* destroys the panel
		*/
	, destroy: function() {
		if(this.shadow) {
			this.shadow.hide();
		}
		if(this.collapsible) {
			this.collapseBtn.removeAllListeners();
			this.titleEl.removeAllListeners();
		}

		if(this.resizer) {
			this.resizer.destroy();
		}
		if(this.dd) {
			if(this.proxy) {
				this.proxy.removeAllListeners();
				this.proxy.remove();
			}
			this.dd.unreg();
			this.dd = null;
		}
		if(this.dock) {
			this.dock.detach(this);
		}

		this.body.removeAllListeners();

		// call parent destroy
		Ext.ux.InfoPanel.superclass.destroy.call(this);

		this.fireEvent('destroy', this);

	}
	// }}}

}); // end of extend

// {{{
// show/hide resizer handles override
Ext.override(Ext.Resizable, {
	
	/**
		* Hide resizer handles
		*/
	hideHandles: function() {
		this.showHandles(false);
	} // end of function hideHandles

	/**
		* Show resizer handles
		*
		* @param {Boolean} show (true = show, false = hide)
		*/
	, showHandles: function(show) {
		show = (false === show ? false : true);
		var pos;
		for(var p in Ext.Resizable.positions) {
			pos = Ext.Resizable.positions[p];
			if(this[pos]) {
				this[pos].el.setStyle('display', show ?
                                                      '' : 'none');
			}
		}
	} // end of function showHandles
// }}}

});

// end of file
