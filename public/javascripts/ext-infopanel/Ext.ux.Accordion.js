// vim: ts=2:sw=2:nu:fdc=4:nospell

// Create user extensions namespace (Ext.ux)
Ext.namespace('Ext.ux');

/**
  * Ext.ux.Accordion Extension Class
	*
	* @author  Ing. Jozef Sakalos
	* @version $Id: Ext.ux.Accordion.js 152 2007-08-21 17:46:03Z jozo $
  *
  * @class Ext.ux.Accordion
  * @extends Ext.ContentPanel
  * @constructor
  * @param {String/HTMLElement/Element} el The container element for this panel
  * @param {String/Object} config A string to set only the title or a config object
	* @cfg {Boolean} animate global animation flag for all panels. (defaults to true)
	* @cfg {Boolean} boxWrap set to true to wrap wrapEl the body is child of (defaults to false)
	* @cfg {Boolean} draggable set to false to disallow panels dragging (defaults to true)
	* @cfg {Boolean} fitHeight set to true if you use fixed height dock
	* @cfg {Boolean} forceOrder set to true if to disable reordering of panels (defaults to false)
	* @cfg {Boolean} independent true to make panels independent (defaults to false)
	* @cfg {Integer} initialHeight Initial height to set box to (defaults to 0)
	* @cfg {Boolean} keepState Set to false to exclude this accordion from state management (defaults to true)
	* @cfg {Boolean} monitorWindowResize if true panels are moved to 
	*  viewport if window is small (defaults to true)
	* @cfg {Boolean} resizable global resizable flag for all panels (defaults to true)
	* @cfg {Boolean} undockable true to allow undocking of panels (defaults to true)
	* @cfg {Boolean} useShadow global useShadow flag for all panels. (defaults to true)
	* @cfg {Element/HTMLElement/String} wrapEl Element to wrap with nice surrounding
  */
Ext.ux.Accordion = function(el, config) {
	
	// call parent constructor
	Ext.ux.Accordion.superclass.constructor.call(this, el, config);

	// create collection for panels
	this.items = new Ext.util.MixedCollection();

	// assume no panel is expanded
	this.expanded = null;

	// {{{
	// install event handlers
	this.on({

		// {{{
		// runs before expansion. Triggered by panel's beforeexpand event
		beforeexpand: {
			  scope: this
			, fn: function(panel) {
					// raise panel above others
					if(!panel.docked) {
						this.raise(panel);
					}

					// set fixed height
					panel.autoSize();
//					var panelBodyHeight;
//					if(this.fitHeight && panel.docked) {
//						panelBodyHeight = this.getPanelBodyHeight();
//						if(panelBodyHeight) {
//							panel.body.setHeight(panelBodyHeight);
//						}
//					}

					if(panel.docked) {
						this.expandCount++;
						this.expanding = true;
//						this.setDockScroll(false);
					}

					// don't collapse others if independent or not docked
					if(this.independent || !panel.docked) {
						return this;
					}

					// collapse expanded panel
					if(this.expanded && this.expanded.docked) {
						this.expanded.collapse();
					}

					// remember this panel as expanded
					this.expanded = panel;
		}}
		// }}}
		// {{{
		// runs before panel collapses. Triggered by panel's beforecollapse event
		, beforecollapse: {
			  scope: this
			, fn: function(panel) {

				// raise panel if not docked
				if(!panel.docked) {
					this.raise(panel);
				}
				return this;
		}}
		// }}}
		// {{{
		// runs on when panel expands (before animation). Triggered by panel's expand event
		, expand: {
			  scope: this
			, fn: function(panel) {
				if(this.hideOtherOnExpand) {
					this.hideOther(panel);
				}
				this.fireEvent('panelexpand', panel);
		}}
		// }}}
		// {{{
		// runs on when panel collapses (before animation). Triggered by panel's collapse event
		, collapse: {
		 	  scope: this
			, fn: function(panel) {
				this.fireEvent('panelcollapse', panel);
		}}
		// }}}
		// {{{
		// runs on when animation is completed. Triggered by panel's animationcompleted event
		, animationcompleted: {
			scope: this
			, fn: function(panel) {
				var box = panel.el.getBox();
				this.expandCount = (this.expandCount && this.expanding) ? --this.expandCount : 0;
				if((0 === this.expandCount) && this.expanding) {
//					this.setDockScroll(true);
					this.expanding = false;
				}
				if(this.hideOtherOnExpand) {
					if(panel.collapsed && panel.docked) {
						this.showOther(panel);
					}
//					else if(panel.docked) {
//						this.hideOther(panel);
//					}
				}
//				this.fireEvent('panelbox', panel, box);
		}}
		// }}}
		// {{{
		// runs when panel is pinned. Triggered by panel's pinned event
		, pinned: {
			  scope: this
			, fn: function(panel, pinned) {
				if(!pinned) {
					if(panel.collapseOnUnpin) {
						panel.collapse();
					}
					else if(!this.independent) {
						this.items.each(function(p) {
							if(p !== panel && p.docked && !p.pinned) {
								p.collapse();
							}
						});
						this.expanded = panel;
					}
				}
				if(this.hideOtherOnExpand) {
					if(panel.docked && pinned) {
						this.showOther(panel);
					}
				}
				this.fireEvent('panelpinned', panel, pinned);
		}}
		// }}}

		, destroy: {
			scope:this
			, fn: function(panel) {
				this.items.removeKey(panel.id);
				this.updateOrder();
		}}
	});
	// }}}
	// {{{
	// add events
	this.addEvents({
		/**
			* Fires when a panel of the dock is collapsed
			* @event panelcollapse
			* @param {Ext.ux.InfoPanel} panel
			*/
		panelcollapse: true

		/**
			* Fires when a panel of the dock is expanded
			* @event panelexpand
			* @param {Ext.ux.InfoPanel} panel
			*/
		, panelexpand: true

		/**
			* Fires when a panel of the dock is pinned
			* @event panelpinned
			* @param {Ext.ux.InfoPanel} panel
			* @param {Boolean} pinned true if panel was pinned false if unpinned
			*/
		, panelpinned: true

		/**
			* Fires when the independent state of dock changes
			* @event independent
			* @param {Ext.ux.Accordion} this
			* @param {Boolean} independent New independent state
			*/
		, independent: true

		/**
			* Fires when the order of panel is changed
			* @event orderchange
			* @param {Ext.ux.Accordion} this
			* @param {Array} order New order array
			*/
		, orderchange: true

		/**
			* Fires when the undockable state of dock changes
			* @event undockable
			* @param {Ext.ux.Accordion} this
			* @param {Array} undockable New undockable state
			*/
		, undockable: true

		/**
			* Fires when a panel is undocked
			* @event panelundock
			* @param {Ext.ux.InfoPanel} panel
			* @param {Object} box Position and size object
			*/
		, panelundock: true

		/**
			* Fires when a panel is undocked
			* @event paneldock
			* @param {Ext.ux.InfoPanel} panel
			*/
		, paneldock: true

		/**
			* Fires when a panel box is changed, e.g. after dragging
			* @event panelbox
			* @param {Ext.ux.InfoPanel} panel
			* @param {Object} box Position and size object
			*/
		, panelbox: true
		
		/**
			* Fires when useShadow status changes
			* @event useshadow
			* @param {Ext.ux.Accordion} this
			* @param {Boolean} shadow Use shadow (for undocked panels) flag
			*/
		, useshadow: true

		/**
			* Fires before the panel is detached from this accordion. Return false to cancel the detach
			* @event beforedetach
			* @param {Ext.ux.Accordion} this
			* @param {Ext.ux.InfoPanel} panel being detached
			*/
		, beforedetach: true

		/**
			* Fires after the panel has been detached from this accordion
			* @event detach
			* @param {Ext.ux.Accordion} this
			* @param {Ext.ux.InfoPanel} panel detached panel
			*/
		, detach: true

		/**
			* Fires before the panel is attached from this accordion. Return false to cancel the attach
			* @event beforeattach
			* @param {Ext.ux.Accordion} this
			* @param {Ext.ux.InfoPanel} panel being attached
			*/
		, beforeattach: true

		/**
			* Fires after the panel is attached to this accordion
			* @event attach
			* @param {Ext.ux.Accordion} this
			* @param {Ext.ux.InfoPanel} panel attached panel
			*/
		, attach: true

	});
	// }}}

	// setup body
	this.body = Ext.get(this.body) || this.el;
	this.resizeEl = this.body;
	this.id = this.id || this.body.id;
	this.body.addClass('x-dock-body');

	// setup desktop
	this.desktop = Ext.get(this.desktop || document.body);
	//this.desktop = this.desktop.dom || this.desktop;

	// setup fixed hight
	this.wrapEl = Ext.get(this.wrapEl);
	if(this.fitHeight) {
		this.body.setStyle('overflow', 'hidden');
//		this.bodyHeight = this.initialHeight || this.body.getHeight();
		this.body.setHeight(this.initialHeight || this.body.getHeight());
		if(this.boxWrap && this.wrapEl) {
			this.wrapEl.boxWrap();
		}
	}

	// watch window resize
	if(this.monitorWindowResize) {
		Ext.EventManager.onWindowResize(this.adjustViewport, this);
	}

	// create drop zone for panels
	this.dd = new Ext.dd.DropZone(this.body.dom, {
		ddGroup: this.ddGroup || 'dock-' + this.id 
	});

	Ext.ux.AccordionManager.add(this);

}; // end of constructor

// extend
Ext.extend(Ext.ux.Accordion, Ext.ContentPanel, {

	// {{{
	// defaults
    independent: false,
    undockable: true,
    useShadow: true,
    boxWrap: false,
    fitHeight: false,
    initialHeight: 0,
    animate: true, // global animation flag
    expandCount: 0,
    expanding: false,
    monitorWindowResize: true,
    resizable: true, // global resizable flag
    draggable: true, // global draggable flag
    forceOrder: false,
    keepState: true,
    hideOtherOnExpand: false
	// }}}
	// {{{
	/**
		* Adds the panel to Accordion
		* @param {Ext.ux.InfoPanel} panel Panel to add
		* @return {Ext.ux.InfoPanel} added panel
		*/
	, add: function(panel) {

		// append panel to body
		this.body.appendChild(panel.el);

		this.attach(panel);

		// panel dragging 
		if(undefined === panel.draggable && this.draggable) {
			panel.draggable = true;
			panel.dd = new Ext.ux.Accordion.DDDock(panel, this.ddGroup || 'dock-' + this.id, this);
		}

		// panel resizing
		if(undefined === panel.resizable && this.resizable) {
			panel.resizable = true;
//			panel.setResizable(true);
		}

		// panel shadow
		panel.useShadow = undefined === panel.useShadow ? this.useShadow : panel.useShadow;
		panel.setShadow(panel.useShadow);
		if(panel.shadow) {
			panel.shadow.hide();
		}

		// panel animation
		panel.animate = undefined === panel.animate ? this.animate : panel.animate;

		// z-index for panel
		panel.zindex = Ext.ux.AccordionManager.getNextZindex();

		panel.docked = true;
		panel.desktop = this.desktop;

		if(false === panel.collapsed) {
			panel.collapsed = true;
			panel.expand(true);
		}
		return panel;

	}
	// }}}
	// {{{
	/**
		* attach panel to this accordion
		* @param {Ext.ux.InfoPanel} panel panel to attach
		* @return {Ext.ux.Accordion} this
		*/
	, attach: function(panel) {

		// fire beforeattach event
		if(false === this.fireEvent('beforeattach', this, panel)) {
			return this;
		}

		// add panel to items
		this.items.add(panel.id, panel);

		// install event handlers
		this.installRelays(panel);
		panel.bodyClickDelegate = this.onClickPanelBody.createDelegate(this, [panel]);
		panel.body.on('click', panel.bodyClickDelegate);

  		// set panel dock
		panel.dock = this;

		// add docked class to panel body
		panel.body.replaceClass('x-dock-panel-body-undocked', 'x-dock-panel-body-docked');

		// repair panel height
		panel.autoSize();
		if(this.fitHeight) {
			this.setPanelHeight(panel);
		}

		// fire attach event
		this.fireEvent('attach', this, panel);

		return this;
	}
	// }}}
	// {{{
	/**
		* detach panel from this accordion
		* @param {Ext.ux.InfoPanel} panel to detach
		* @return {Ext.ux.Accordion} this
		*/
	, detach: function(panel) {

		// fire beforedetach event
		if(false === this.fireEvent('beforedetach', this, panel)) {
			return this;
		}

		// unhook events from panel
		this.removeRelays(panel);
		panel.body.un('click', panel.bodyClickDelegate);

		// remove panel from items
		this.items.remove(panel);
		panel.dock = null;

		// remove docked class from panel body
		panel.body.replaceClass('x-dock-panel-body-docked', 'x-dock-panel-body-undocked');

		// repair expanded property
		if(this.expanded === panel) {
			this.expanded = null;
		}

		// repair panel height
		panel.autoSize();
		if(this.fitHeight) {
			this.setPanelHeight();
		}

		// fire detach event
		this.fireEvent('detach', this, panel);

		return this;
	}
	// }}}
	// {{{
	/**
		* Called internally to raise panel above others
		* @param {Ext.ux.InfoPanel} panel Panel to raise
		* @return {Ext.ux.InfoPanel} panel Panel that has been raised
		*/
	, raise: function(panel) {
		return Ext.ux.AccordionManager.raise(panel);
	}
	// }}}
	// {{{
	/**
		* Resets the order of panels within the dock
		*
		* @return {Ext.ux.Accordion} this
		*/
	, resetOrder: function() {
		this.items.each(function(panel) {
			if(!panel.docked) {
				return;
			}
			this.body.appendChild(panel.el);
		}, this);
		this.updateOrder();
		return this;
	}
	// }}}
	// {{{
	/**
		* Called internally to update the order variable after dragging
		*/
	, updateOrder: function() {
		var order = [];
		var titles = this.body.select('div.x-layout-panel-hd');
		titles.each(function(titleEl) {
			order.push(titleEl.dom.parentNode.id);
		});
		this.order = order;
		this.fireEvent('orderchange', this, order);
	}
	// }}}
	// {{{
	/**
		* Returns array of panel ids in the current order
		* @return {Array} order of panels
		*/
	, getOrder: function() {
		return this.order;
	}
	// }}}
	// {{{
	/**
		* Set the order of panels
		* @param {Array} order Array of ids of panels in required order.
		* @return {Ext.ux.Accordion} this
		*/
	, setOrder: function(order) {
		if('object' !== typeof order || undefined === order.length) {
			throw "setOrder: Argument is not array.";
		}
		var panelEl, dock, panelId, panel;
		for(var i = 0; i < order.length; i++) {
			panelId = order[i];
			dock = Ext.ux.AccordionManager.get(panelId);
			if(dock && dock !== this) {
				panel = dock.items.get(panelId);
				dock.detach(panel);
				this.attach(panel);
			}
			panelEl = Ext.get(panelId);
			if(panelEl) {
				this.body.appendChild(panelEl);
			}
		}
		this.updateOrder();
		return this;
	}
	// }}}
	// {{{
	/**
		* Collapse all docked panels
		* @param {Boolean} alsoPinned true to first unpin then collapse
		* @param {Ext.ux.InfoPanel} except This panel will not be collapsed.
		* @return {Ext.ux.Accordion} this
		*/
	, collapseAll: function(alsoPinned, except) {
		this.items.each(function(panel) {
			if(panel.docked) {
				panel.pinned = alsoPinned ? false : panel.pinned;
				if(!except || panel !== except) {
					panel.collapse();
				}
			}
		}, this);
		return this;
	}
	// }}}
	// {{{
	/**
		* Expand all docked panels in independent mode
		* @return {Ext.ux.Accordion} this
		*/
	, expandAll: function() {
		if(this.independent) {
			this.items.each(function(panel) {
				if(panel.docked && panel.collapsed) {
					panel.expand();
				}
			}, this);
		}
	}
	// }}}
	// {{{
	/**
		* Called internally while dragging and by state manager
		* @param {Ext.ux.InfoPanel/String} panel Panel object or id of the panel
		* @box {Object} box coordinates with target position and size
		* @return {Ext.ux.Accordion} this
		*/
	, undock: function(panel, box) {

		// get panel if necessary
		panel = 'string' === typeof panel ? this.items.get(panel) : panel;

		// proceed only if we have docked panel and in undockable mode
		if(panel && panel.docked && this.undockable) {

			// sanity check
			if(box.x < 0 || box.y < 0) {
				return this;
			}

			// todo: check this
//			if(panel.collapsed) {
//				box.height = panel.lastHeight || panel.maxHeight || box.height;
//			}

			// move the panel in the dom (append to desktop)
			this.desktop.appendChild(panel.el.dom);

			// adjust panel visuals
			panel.el.applyStyles({
			    position:'absolute',
			    'z-index': panel.zindex
			});
			panel.body.replaceClass('x-dock-panel-body-docked', 'x-dock-panel-body-undocked');

			// position the panel
			panel.setBox(box);

			// reset docked flag
			panel.docked = false;

			// hide panel shadow (will be shown by raise)
			if(panel.shadow) {
				panel.shadow.hide();
			}

			// raise panel above others
			this.raise(panel);

			panel.autoSize();

			if(panel === this.expanded) {
				this.expanded = null;
			}

			// set the height of a docked expanded panel
			this.setPanelHeight(this.expanded);

			// enable resizing and scrolling
			panel.setResizable(!panel.collapsed);

			// remember size of the undocked panel
			panel.lastWidth = box.width;
//			panel.lastHeight = box.height;

			// fire panelundock event
			this.fireEvent('panelundock', panel, {x:box.x, y:box.y, width:box.width, height:box.height});

//			this.updateOrder();
		}

		return this;
	}
	// }}}
	// {{{
	/**
		* Called internally while dragging 
		* @param {Ext.ux.InfoPanel/String} panel Panel object or id of the panel
		* @param {String} targetId id of panel after which this panel will be docked
		* @return {Ext.ux.Accordion} this
		*/
	, dock: function(panel, targetId) {

		// get panel if necessary
		panel = 'string' === typeof panel ? this.items.get(panel) : panel;

		// proceed only if we have a docked panel
		var dockWidth, newTargetId, panelHeight, idx, i, targetPanel;
		if(panel && !panel.docked) {

			// find correct target if order is forced
			if(this.forceOrder) {
				idx = this.items.indexOf(panel);
				for(i = idx + 1; i < this.items.getCount(); i++) {
					targetPanel = this.items.itemAt(i);
					if(targetPanel.docked) {
						newTargetId = targetPanel.id;
						break;
					}
				}
				targetId = newTargetId || this.id;
			}

			// remember width and height
			if(!panel.collapsed) {
//				panel.lastWidth = panel.el.getWidth();
//				panel.lastHeight = panel.el.getHeight();
				if(!this.independent && this.expanded) {
					this.expanded.collapse();
				}
				this.expanded = panel;
			}

			dockWidth = this.body.getWidth(true);

			// move the panel element in the dom
			if(targetId && (this.body.id !== targetId)) {
				panel.el.insertBefore(Ext.fly(targetId));
			}
			else {
				panel.el.appendTo(this.body);
			}

			// set docked flag
			panel.docked = true;

			// adjust panel visuals
			panel.body.replaceClass('x-dock-panel-body-undocked', 'x-dock-panel-body-docked');
			panel.el.applyStyles({
			    top:'',
			    left:'',
			    width:'',
                            height:'',
			    'z-index':'',
			    position:'relative',
			    visibility:''
			});
			panel.body.applyStyles({width: Ext.isIE ? dockWidth + 'px' : '', height:''});

			panel.autoSize();
//			if(!this.fitHeight) {
//				panelHeight = panel.fixedHeight || panel.maxHeight;
//				if(panelHeight) {
//					panel.setHeight(panelHeight);
//				}
//			}

			// disable resizing and shadow
			panel.setResizable(false);
			if(panel.shadow) {
				panel.shadow.hide();
			}

			// set panel height (only if this.fitHeight = true)
			this.setPanelHeight(panel.collapsed ? this.expanded : panel);

			// fire paneldock event
			this.fireEvent('paneldock', panel);

//			this.updateOrder();
		}

		return this;
	}
	// }}}
	// {{{
	/**
		* Moves panel from this dock (accordion) to another
		* @param {Ext.ux.InfoPanel} panel Panel to move
		* @param {Ext.ux.Accordion} targetDock Dock to move to
		*/
	, moveToDock: function(panel, targetDock) {
		this.detach(panel);
		targetDock.attach(panel);
		panel.docked = false;
		targetDock.dock(panel);
		this.setPanelHeight();
		this.updateOrder();
		targetDock.updateOrder();
	}
	// }}}
	// {{{
	/**
		* Sets the independent mode
		* @param {Boolean} independent set to false for normal mode
		* @return {Ext.ux.Accordion} this
		*/
	, setIndependent: function(independent) {
		this.independent = independent ? true : false;
		this.fireEvent('independent', this, independent);
		return this;
	}
	// }}}
	// {{{
	/**
		* Sets the undockable mode 
		* If undockable === true all undocked panels are docked and collapsed (except pinned)
		* @param {Boolean} undockable set to true to not allow undocking
		* @return {Ext.ux.Accordion} this
		*/
	, setUndockable: function(undockable) {
		this.items.each(function(panel) {

			// dock and collapse (except pinned) all undocked panels if not undockable
			if(!undockable && !panel.docked) {
				this.dock(panel);
				if(!this.independent && !panel.collapsed && !panel.pinned) {
					panel.collapse();
				}
			}

			// refresh dragging constraints
			if(panel.docked && panel.draggable) {
				panel.dd.constrainTo(this.body, 0, false);
				panel.dd.clearConstraints();
				if(undockable) {
					panel.constrainToDesktop();
				}
				else {
					panel.dd.setXConstraint(0,0);
				}
			}
		}, this);

		// set the flag and fire event
		this.undockable = undockable;
		this.fireEvent('undockable', this, undockable);
		return this;
	}
	// }}}
	// {{{
	/**
		* Sets the shadows for all panels
		* @param {Boolean} shadow set to false to disable shadows
		* @return {Ext.ux.Accordion} this
		*/
	, setShadow: function(shadow) {
		this.items.each(function(panel) {
			panel.useShadow = shadow;
			panel.setShadow(false);
			if(!panel.docked) {
				panel.setShadow(shadow);
			}
		});
		this.useShadow = shadow;
		this.fireEvent('useshadow', this, shadow);
		return this;
	}
	// }}}
// {{{
	/**
		* Called when user clicks the panel body
		* @param {Ext.ux.InfoPanel} panel
		*/
	, onClickPanelBody: function(panel) {
		if(!panel.docked) {
			this.raise(panel);
		}
	}
	// }}}
	// {{{
	/**
		* Called internally for fixed height docks to get current height of panel(s)
		*/
	, getPanelBodyHeight: function() {
			var titleHeight = 0;
			this.items.each(function(panel) {
				titleHeight += panel.docked ? panel.titleEl.getHeight() : 0;
			});
			this.panelBodyHeight = this.body.getHeight() - titleHeight - this.body.getFrameWidth('tb') + 1;
//			this.panelBodyHeight = this.body.getHeight() - titleHeight - this.body.getFrameWidth('tb');
			return this.panelBodyHeight;
	}
	// }}}
	// {{{
	/**
		* Sets the height of panel body 
		* Used with fixed height (fitHeight:true) docs
		* @param {Ext.ux.InfoPanel} panel (defaults to this.expanded)
		* @return {Ext.ux.Accordion} this
		*/
	, setPanelHeight: function(panel) {
		panel = panel || this.expanded;
		if(this.fitHeight && panel && panel.docked) {
			panel.body.setHeight(this.getPanelBodyHeight());
			panel.setHeight(panel.getHeight());
		}
		return this;
	}
	// }}}
	// {{{
	/**
		* Constrains the dragging of panels do the desktop
		* @return {Ext.ux.Accordion} this
		*/
	, constrainToDesktop: function() {
		this.items.each(function(panel) {
			panel.constrainToDesktop();
		}, this);
		return this;
	}
	// }}}
	// {{{
	/** 
		* Clears dragging constraints of panels
		* @return {Ext.ux.Accordion} this
		*/
	, clearConstraints: function() {
		this.items.each(function(panel) {
			panel.dd.clearConstraints();
		});
	}
	// }}}
	// {{{
	/**
		* Shows all panels
		* @param {Boolean} show (optional) if false hides the panels instead of showing
		* @param {Boolean} alsoUndocked show also undocked panels (defaults to false)
		* @return {Ext.ux.Accordion} this
		*/
	, showAll: function(show, alsoUndocked) {
		show = (false === show ? false : true);
		this.items.each(function(panel) {
			panel.show(show, alsoUndocked);
		});
		return this;
	}
	// }}}

	, showOther: function(panel, show, alsoPinned) {
		show = (false === show ? false : true);
		this.items.each(function(p) {
				if(p === panel || (p.pinned && !alsoPinned)) {
					return;
				}
				if(show) {
					p.show();		
				}
				else {
					p.hide();
				}
		});
	}

	, hideOther: function(panel, alsoPinned) {
		this.showOther(panel, false, alsoPinned);
	}

	// {{{
	/**
		* Hides all panels
		* @param {Boolean} alsoUndocked hide also undocked panels (defaults to false)
		* @return {Ext.ux.Accordion} this
		*/
	, hideAll: function(alsoUndocked) {
		return this.showAll(false, alsoUndocked);
	}
	// }}}
	// {{{
	/**
		* Called internally to disable/enable scrolling of the dock while animating
		* @param {Boolean} enable true to enable, false to disable
		* @return {void}
		* @todo not used at present - revise
		*/
	, setDockScroll: function(enable) {
		if(enable && !this.fitHeight) {
			this.body.setStyle('overflow','auto');
		}
		else {
			this.body.setStyle('overflow','hidden');
		}
	}
	// }}}
	// {{{
	/**
		* Set Accordion size
		* Overrides ContentPanel.setSize
		*
		* @param {Integer} w width
		* @param {Integer} h height
		* @return {Ext.ux.Accordion} this
		*/
	, setSize: function(w, h) {
		// call parent's setSize
		Ext.ux.Accordion.superclass.setSize.call(this, w, h);
//		this.body.setHeight(h);
		this.setPanelHeight();

		return this;
	}
	// }}}
	// {{{
	/** 
		* Called as windowResize event handler
		*
		* @todo: review
		*/
	, adjustViewport: function() {
		var viewport = this.desktop.dom === document.body ? {} : Ext.get(this.desktop).getBox();

		viewport.height = 
		this.desktop === document.body ?
                window.innerHeight || document.documentElement.clientHeight || document.body.clientHeight :
		viewport.height;

		viewport.width = 
		this.desktop === document.body ? 
		window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth :
		viewport.width;

		viewport.x = this.desktop === document.body ? 0 : viewport.x;
		viewport.y = this.desktop === document.body ? 0 : viewport.y;

		this.items.each(function(panel) {
			if(!panel.docked) {
				panel.moveToViewport(viewport);
			}
		});

	}
	// }}}
	// {{{
	/**
		* private - called internally to create relay event function
		* @param {String} ename event name to relay
		* @return {Function} relay event function
		*/
	, createRelay: function(ename) {
		return function() {
			return this.fireEvent.apply(this, Ext.combine(ename, Array.prototype.slice.call(arguments, 0)));
		};
	}
	// }}}
	// {{{
	/**
		* Array of event names to relay
		*/
	, relayedEvents: [
	    'beforecollapse',
	    'collapse',
	    'beforeexpand',
	    'expand',
	    'animationcompleted',
	    'pinned',
	    'boxchange',
	    'destroy'
        ],
	// }}}
	// {{{
	/**
		* private - called internaly to install event relays on panel
		* @param {Ext.ux.InfoPanel} panel panel to install events on
		*/
	installRelays: function(panel) {
		panel.relays = {};
		var ename, fn;
		for(var i = 0; i < this.relayedEvents.length; i++) {
			ename = this.relayedEvents[i];
			fn = this.createRelay(ename);
			panel.relays[ename] = fn;
			panel.on(ename, fn, this);
		}
	}
	// }}}
	// {{{
	/**
		* private - called internaly to remove installed relays
		* @param {Ext.ux.InfoPanel} panel panel to remove relays from
		*/
	, removeRelays: function(panel) {
		for(var ename in panel.relays) {
			panel.un(ename, panel.relays[ename], this);
		}
		panel.relays = {};
	}
	// }}}
	// {{{
	/**
		* Removes and destroys panel
		* @param {String/InfoPanel} panel Panel object or id
		*/
	, remove: function(panel) {
		panel = this.items.get(panel.id || panel);
		if(panel) {
			this.detach(panel);
			panel.destroy();
		}
	}
	// }}}
	// {{{
	/**
		* Removes and destroys all panels
		*/
	, removeAll: function() {
		this.items.each(function(panel) {
				this.remove(panel);
		}, this);
	}
	// }}}
	// {{{
	/**
		* Destroys Accrodion
		*/
	, destroy: function() {
		this.removeAll();
		Ext.ux.Accordion.superclass.destroy.call(this);
	}
	// }}}

}); // end of extend

// {{{
// {{{
/**
	* @class Ext.ux.Accordion.DDDock
	* @constructor
	* @extends Ext.dd.DDProxy
	* @param {Ext.ux.InfoPanel} panel Panel the dragging object is created for
	* @param {String} group Only elements of same group interact
	* @param {Ext.ux.Accordion} dock Place where panels are docked/undocked
	*/
Ext.ux.Accordion.DDDock = function(panel, group, dock) {

	// call parent constructor
	Ext.ux.Accordion.DDDock.superclass.constructor.call(this, panel.el.dom, group);

	// save panel and dock references for use in methods
	this.panel = panel;
	this.dock = dock;

	// drag by grabbing the title only
	this.setHandleElId(panel.titleEl.id);

	// move only in the dock if undockable
	if(false === dock.undockable) {
		this.setXConstraint(0, 0);
	}

	// init internal variables
	this.lastY = 0;

	//this.DDM.mode = Ext.dd.DDM.INTERSECT;
	this.DDM.mode = Ext.dd.DDM.POINT;

}; // end of constructor
// }}}

// extend
Ext.extend(Ext.ux.Accordion.DDDock, Ext.dd.DDProxy, {

	// {{{
	/**
		* Default DDProxy startDrag override
		* Saves some variable for use by other methods 
		* and creates nice dragging proxy (ghost)
		*
		* Passed x, y arguments are not used
		*/
	startDrag: function(x, y) {

		this.createIframeMasks();

		this.lastMoveTarget = null;

		// create nice dragging ghost
		this.createGhost();

		// get srcEl (the original) and dragEl (the ghost)
		var srcEl = Ext.get(this.getEl());
		var dragEl = Ext.get(this.getDragEl());

		// refresh constraints
		this.panel.constrainToDesktop();
		var dragHeight, rightC, bottomC;
		if(this.panel.dock.undockable) {
			if(this.panel.collapsed) {
				dragHeight = this.panel.titleEl.getHeight();
			}
			else {
				dragHeight = dragEl.getHeight();
				dragHeight = dragHeight <= this.panel.titleEl.getHeight() ? srcEl.getHeight() : dragHeight;
			}

			rightC = this.rightConstraint + srcEl.getWidth() - dragEl.getWidth();
			bottomC = this.bottomConstraint + srcEl.getHeight() - dragHeight;
			this.setXConstraint(this.leftConstraint, rightC);
			this.setYConstraint(this.topConstraint, bottomC);
		}
		else {
			if(this.panel.docked) {
				this.setXConstraint(0, 0);
			}
		}

		// hide dragEl (will be shown by onDrag)
		dragEl.hide();

		// raise panel's "window" above others
		if(!this.panel.docked) {
			this.panel.dock.raise(this.panel);
		}

		// hide panel's shadow if any
		this.panel.setShadow(false);

		// clear visibility of panel's body (was setup by animations)
		this.panel.body.dom.style.visibility = '';

		// hide source panel if undocked
		if(!this.panel.docked) {
//			srcEl.hide();
			srcEl.setDisplayed(false);
			dragEl.show();
		}

	} // end of function startDrag
	// }}}
	// {{{
	/**
		* Called internally to create nice dragging proxy (ghost)
		*/
	, createGhost: function() {

		// get variables
		var srcEl = Ext.get(this.getEl());
		var dragEl = Ext.get(this.getDragEl());
		var panel = this.panel;
		var dock = panel.dock;

		// adjust look of ghost
		var am = Ext.ux.AccordionManager;
		dragEl.addClass('x-dock-panel-ghost');
		dragEl.applyStyles({border:'1px solid #84a0c4','z-index': am.zindex + am.zindexInc});

		// set size of ghost same as original
		dragEl.setBox(srcEl.getBox());
		if(panel.docked) {
			if(panel.lastWidth && dock.undockable) {
				dragEl.setWidth(panel.lastWidth);
			}
			if(!panel.collapsed && dock.undockable && (panel.lastHeight > panel.titleEl.getHeight())) {
				dragEl.setHeight(panel.lastHeight);
			}
		}

		// remove unnecessary text nodes from srcEl
		srcEl.clean();

		// setup title
		var dragTitleEl = Ext.DomHelper.append(dragEl, {tag:'div'}, true);
		dragTitleEl.update(srcEl.dom.firstChild.innerHTML);
		dragTitleEl.dom.className = srcEl.dom.firstChild.className;
		if(panel.collapsed && Ext.isIE) {
			dragTitleEl.dom.style.borderBottom = "0";
		}

	} // end of function createGhost
	// }}}
	// {{{
	/**
		* Default DDProxy onDragOver override
		* It is called when dragging over a panel
		* or over the dock.body DropZone
		*
		* @param {Event} e not used
		* @param {String} targetId id of the target we're over
		*
		* Beware: While dragging over docked panels it's called
		* twice. Once for panel and once for DropZone
		*/
	, onDragOver: function(e, targetId) {

		// get panel element
		var srcEl = Ext.get(this.getEl());

		// get target panel and dock
		var targetDock = Ext.ux.AccordionManager.get(targetId);
		var targetPanel = targetDock ? targetDock.items.get(targetId) : this.panel;

		// setup current target for endDrag
		if(targetPanel) {
			this.currentTarget = targetPanel.id;
		}
		if(targetDock && !this.currentTarget) {
			this.currentTarget = targetDock.id;
		}

		// landing indicators
		if(targetPanel && targetPanel.docked && !this.panel.dock.forceOrder) {
			targetPanel.titleEl.addClass('x-dock-panel-title-dragover');
		}
		if(targetDock) {
			targetDock.body.addClass('x-dock-body-dragover');
		}
		if(this.panel.docked) {
			this.panel.titleEl.addClass('x-dock-panel-title-dragover');
		}

		// reorder panels in dock if we're docked too
		var targetEl;

		if(targetDock === this.panel.dock && 
		   targetPanel && targetPanel.docked &&
                   this.panel.docked && !this.panel.dock.forceOrder) {
			targetEl = targetPanel.el;

			if(targetPanel.collapsed || this.lastMoveTarget !== targetPanel) {
				if(this.movingUp) {
					srcEl.insertBefore(targetEl);
					this.lastMoveTarget = targetPanel;
				}
				else {
					srcEl.insertAfter(targetEl);
					this.lastMoveTarget = targetPanel;
				}
			}
			this.DDM.refreshCache(this.groups);
		}

	} // end of function onDragOver
	// }}}
	// {{{
	/**
		* called internally to attach this.panel to accordion
		* @param {Ext.ux.Accordion} targetDock the dock to attach the panel to
		*/
	, attachToDock: function(targetDock) {
		if(targetDock && this.panel.dock !== targetDock) {
			// detach panel
			this.panel.dock.detach(this.panel);

			// attach panel
			targetDock.attach(this.panel);

		}
	}
	// }}}
	// {{{
	/**
		* Called internally when cursor leaves a drop target
		* @param {Ext.Event} e
		* @param {String} targetId id of target we're leaving
		*/
	, onDragOut: function(e, targetId) {

		var targetDock = Ext.ux.AccordionManager.get(targetId);
		var targetPanel = targetDock ? targetDock.items.get(targetId) : this.panel;

		if(targetDock) {
			targetDock.body.removeClass('x-dock-body-dragover');
		}

		if(targetPanel) {
			targetPanel.titleEl.removeClass('x-dock-panel-title-dragover');
		}
		this.currentTarget = null;
	}
	// }}}
	// {{{
	/**
		* Default DDProxy onDrag override
		*
		* It's called while dragging
		* @param {Event} e used to get coordinates
		*/
	, onDrag: function(e) {

		// get source (original) and proxy (ghost) elements
		var srcEl = Ext.get(this.getEl());
		var dragEl = Ext.get(this.getDragEl());

		if(!dragEl.isVisible()) {
			dragEl.show();
		}

		var y = e.getPageY();

		this.movingUp = this.lastY > y;
		this.lastY = y;

	} // end of function onDrag
	// }}}
	// {{{
	/**
		* Default DDProxy endDrag override
		*
		* Called when dragging is finished
		*/
	, endDrag: function() {

		this.destroyIframeMasks();

		// get the source (original) and proxy (ghost) elements
		var srcEl = Ext.get(this.getEl());
		var dragEl = Ext.get(this.getDragEl());

		srcEl.setDisplayed(true);

		// get box and hide the ghost
		var box = dragEl.getBox();

		var sourceDock = this.panel.dock;
		var targetDock = Ext.ux.AccordionManager.get(this.currentTarget);
		var targetPanel = targetDock ? targetDock.items.get(this.currentTarget) : this.panel;
		var orderChanged = false;

		// remove any dragover classes from panel title and dock
		this.panel.titleEl.removeClass('x-dock-panel-title-dragover');
		this.dock.body.removeClass('x-dock-body-dragover');
		if(targetDock) {
			targetDock.items.each(function(panel) {
				panel.titleEl.removeClass('x-dock-panel-title-dragover');
			});
		}

		// undock (docked panel dropped out of dock)
		if(!this.panel.dock.catchPanels && (this.panel.docked && !this.currentTarget && !targetDock) || (targetPanel && !targetPanel.docked)) {
			this.dock.undock(this.panel, box);
			orderChanged = true;
		}

		// dock undocked panel
		else if(!this.panel.docked) {
			this.attachToDock(targetDock);
			this.panel.dock.dock(this.panel, this.currentTarget);
			orderChanged = true;
		}

		// do nothing for panel moved over it's own dock
		// handling has already been done by onDragOver
		else if(this.panel.docked && (this.panel.dock === targetDock)) {
			// do nothing on purpose - do not remove
			orderChanged = true;
		}
		
		// dock panel to another dock
		else if(this.currentTarget || targetDock) {
			this.attachToDock(targetDock);
			if(targetDock) {
				targetDock.body.removeClass('x-dock-body-dragover');
				this.panel.docked = false;
				targetDock.dock(this.panel, this.currentTarget);
			}
			orderChanged = true;
		}

		// just free dragging
		if(!this.panel.docked) {
			this.panel.setBox(box);

			// let the state manager know the new panel position
			this.dock.fireEvent('panelbox', this.panel, {x:box.x, y:box.y, width:box.width, height:box.height});
		}

		// clear the ghost content, hide id and move it off screen
		dragEl.hide();
		dragEl.update('');
		dragEl.applyStyles({
		    top:'-9999px',
		    left:'-9999px',
		    height:'0px',
		    width:'0px'
		});

		if(orderChanged) {
			sourceDock.updateOrder();
			if(targetDock && targetDock !== sourceDock) {
				targetDock.updateOrder();
			}
		}
		this.DDM.refreshCache(this.groups);

	} // end of function endDrag
	// }}}
	// {{{
	, createIframeMasks: function() {
		this.destroyIframeMasks();
		
		var masks = [];
		var iframes = Ext.get(document.body).select('iframe');
		iframes.each(function(iframe) {
			var mask = Ext.DomHelper.append(document.body, {tag:'div'}, true);
			mask.setBox(iframe.getBox());
			masks.push(mask);
		});
		this.iframeMasks = masks;
	}
	// }}}
	// {{{
	, destroyIframeMasks: function() {
		if(!this.iframeMasks || ! this.iframeMasks.length) {
			return;
		}
		for(var i = 0; i < this.iframeMasks.length; i++) {
			this.iframeMasks[i].remove();
		}
		this.iframeMasks = [];
	}
	// }}}

});
// }}}
// {{{
/**
	* Private class for keeping and restoring state of the Accordion
	*/
Ext.ux.AccordionStateManager = function() {
	this.state = { docks:{}, panels:{} };
};

Ext.ux.AccordionStateManager.prototype = {
	init: function(provider) {

		// save state provider
		this.provider = provider;
//		var state = provider.get('accjs-state');
//		if(state) {
//			this.state = state;
//		}
		state = this.state;

		var am = Ext.ux.AccordionManager;
		var dockState;

		// {{{
		// docks loop
		am.each(function(dock) {
			if(false === dock.keepState) {
				return;
			}

			state.docks[dock.id] = provider.get('accjsd-' + dock.id);
			dockState = state.docks[dock.id];
			if(dockState) {

				// {{{
				// handle docks (accordions)
				if(dockState) {

					// {{{
					// restore order of panels
					if(dockState.order) {
						dock.setOrder(dockState.order);
					}
					// }}}
					// {{{
					// restore independent
					if(undefined !== dockState.independent) {
						dock.setIndependent(dockState.independent);
					}
					// }}}
					// {{{
					// restore undockable
					if(undefined !== dockState.undockable) {
						dock.setUndockable(dockState.undockable);
					}
					// }}}
					// {{{
					// restore useShadow
					if(undefined !== dockState.useShadow) {
						dock.setShadow(dockState.useShadow);
					}
					// }}}

				} // end of if(dockState)
				// }}}

			}

			// install event handlers on docks
			dock.on({
				orderchange: {scope:this, fn:this.onOrderChange}
				, independent: {scope:this, fn:this.onIndependent}
				, undockable: {scope:this, fn:this.onUndockable}
				, useshadow: {scope: this, fn: this.onUseShadow}
				, panelexpand: {scope: this, fn: this.onPanelCollapse}
				, panelcollapse: {scope: this, fn: this.onPanelCollapse}
				, panelpinned: {scope: this, fn: this.onPanelPinned}
				, paneldock: {scope: this, fn: this.onPanelUnDock}
				, panelundock: {scope: this, fn: this.onPanelUnDock}
				, boxchange: {scope: this, fn: this.onPanelUnDock}
				, panelbox: {scope: this, fn: this.onPanelUnDock}
			});
		}, this);
		// }}}

		// {{{
		// panels loop
		am.each(function(dock) {
			if(!dock.keepState) {
				return;
			}

			// panels within dock loop
			var panelState;
			dock.items.each(function(panel) {

				state.panels[panel.id] = provider.get('accjsp-' + panel.id);
				panelState = state.panels[panel.id];
				
				if(panelState) {

					// {{{
					// restore docked/undocked state
					if(undefined !== panelState.docked) {
						if(!panelState.docked) {
							if('object' === typeof panelState.box) {
								panel.docked = true;
								panel.dock.undock(panel, panelState.box);
							}
						}
					}
					// }}}
					// {{{
					// restore pinned state
					if(undefined !== panelState.pinned) {
						panel.pinned = panelState.pinned;
						if(panel.pinned) {
							panel.expand(true);
						}
						else {
							panel.updateVisuals();
						}
					}
					// }}}
					// {{{
					// restore collapsed/expanded state
					if(undefined !== panelState.collapsed) {
						if(panelState.collapsed) {
							panel.collapsed = false;
							panel.collapse(true);
						}
						else {
							panel.collapsed = true;
							panel.expand(true);
						}
					}
					// }}}

				}
			}, this); // end of panels within dock loop
		}, this); // end of docks loop
		// }}}


	}

	// event handlers
	// {{{
	, onOrderChange: function(dock, order) {
		if(false !== dock.keepState) {
			this.state.docks[dock.id] = this.state.docks[dock.id] ? this.state.docks[dock.id] : {};
			this.state.docks[dock.id].order = order;
			this.storeDockState(dock);
		}
	}
	// }}}
	// {{{
	, onIndependent: function(dock, independent) {
		if(false !== dock.keepState) {
			this.state.docks[dock.id] = this.state.docks[dock.id] ? this.state.docks[dock.id] : {};
			this.state.docks[dock.id].independent = independent;
			this.storeDockState(dock);
		}
	}
	// }}}
	// {{{
	, onUndockable: function(dock, undockable) {
		if(false !== dock.keepState) {
			this.state.docks[dock.id] = this.state.docks[dock.id] ? this.state.docks[dock.id] : {};
			this.state.docks[dock.id].undockable = undockable;
			this.storeDockState(dock);
		}
	}
	// }}}
	// {{{
	, onUseShadow: function(dock, shadow) {
		if(false !== dock.keepState) {
			this.state.docks[dock.id] = this.state.docks[dock.id] ? this.state.docks[dock.id] : {};
			this.state.docks[dock.id].useShadow = shadow;
			this.storeDockState(dock);
		}
	}
	// }}}
	// {{{
	, onPanelCollapse: function(panel) {
		if(panel.dock.keepState) {
			this.state.panels[panel.id] = this.state.panels[panel.id] || {};
			this.state.panels[panel.id].collapsed = panel.collapsed;
		}
		else {
			try {delete(this.state.panels[panel.id].collapsed);}
			catch(e){}
		}
		this.storePanelState(panel);
	}
	// }}}
	// {{{
	, onPanelPinned: function(panel, pinned) {
		if(panel.dock.keepState) {
			this.state.panels[panel.id] = this.state.panels[panel.id] || {};
			this.state.panels[panel.id].pinned = pinned;
		}
		else {
			try {delete(this.state.panels[panel.id].pinned);}
			catch(e){}
		}
		this.storePanelState(panel);
	}
	// }}}
	// {{{
	, onPanelUnDock: function(panel, box) {
		if(panel.dock.keepState) {
			this.state.panels[panel.id] = this.state.panels[panel.id] || {};
			this.state.panels[panel.id].docked = panel.docked ? true : false;
			this.state.panels[panel.id].box = box || null;
		}
		else {
			try {delete(this.state.panels[panel.id].docked);}
			catch(e){}
			try {delete(this.state.panels[panel.id].box);}
			catch(e){}
		}
//		console.log('onPanelUnDock: ', + panel.id);
		this.storePanelState(panel);
	}
	// }}}
	// {{{
	, storeDockState: function(dock) {
		this.provider.set.defer(700, this, ['accjsd-' + dock.id, this.state.docks[dock.id]]);
	}
	// }}}
	// {{{
	, storePanelState: function(panel) {
		this.provider.set.defer(700, this, ['accjsp-' + panel.id, this.state.panels[panel.id]]);
	}
	// }}}

}; // end of Ext.ux.AccordionManager.prototype
// }}}
// {{{
/**
	* Singleton to manage multiple accordions
	* @singleton
	*/
Ext.ux.AccordionManager = function() {

	// collection of accordions
	var items = new Ext.util.MixedCollection();

	// public stuff
	return {
		// starting z-index for panels
	    zindex: 9999,
		// z-index increment (2 as 1 is for shadow)
	    zindexInc: 2,

		// {{{
		/**
			* increments (by this.zindexInc) this.zindex and returns new value
			* @return {Integer} next zindex value
			*/
	    getNextZindex: function() {
		this.zindex += this.zindexInc;
		return this.zindex;
	    }
		// }}}
		// {{{
		/**
			* raises panel above others (in the same desktop)
			* Maintains z-index stack
			* @param {Ext.ux.InfoPanel} panel panel to raise
			* @return {Ext.ux.InfoPanel} panel panel that has been raised
			*/
		, raise: function(panel) {
			items.each(function(dock) {
				dock.items.each(function(p) {
					if(p.zindex > panel.zindex) {
						p.zindex -= this.zindexInc;
						p.el.applyStyles({'z-index':p.zindex});
						if(!p.docked) {
							p.setShadow(true);
						}
					}
				}, this);
			}, this);

			if(panel.zindex !== this.zindex) {
				panel.zindex = this.zindex;
				panel.el.applyStyles({'z-index':panel.zindex});
				if(panel.desktop.lastChild !== panel.el.dom) {
					panel.dock.desktop.appendChild(panel.el.dom);
				}
				if(!panel.docked) {
					panel.setShadow(true);
				}
			}

			return panel;
		}
		// }}}
		// {{{
		/**
			* Adds accordion to items
			* @param {Ext.ux.Accordion} acc accordion to add
			* @return {Ext.ux.Accordion} added accordion
			*/
		, add: function(acc) {
			items.add(acc.id, acc);
			return acc;
		}
		// }}}
		// {{{
		/**
			* get accordion by it's id or by id of some ot it's panels
			* @param {String} key id of accordion or panel
			* @return {Ext.ux.Accordion} or undefined if not found
			*/
		, get: function(key) {
			var dock = items.get(key);
			if(!dock) {
				items.each(function(acc) {
					if(dock) {
						return;
					}
					var panel = acc.items.get(key);
					if(panel) {
						dock = panel.dock;	
					}
				});
			}
			return dock;
		}
		// }}}
	// {{{
		/**
			* get panel by it's id
			* @param {String} key id of the panel to get
			* @return {Ext.ux.InfoPanel} panel found or null
			*/
		, getPanel: function(key) {
			var dock = this.get(key);
			return dock && dock.items ? this.get(key).items.get(key) : null;
		}
	// }}}
		// {{{
		/**
			* Restores state of dock and panels
			* @param {Ext.state.Provider} provider (optional) An alternate state provider
			*/
		, restoreState: function(provider) {
			if(!provider) {
				provider = Ext.state.Manager;
			}
			var sm = new Ext.ux.AccordionStateManager();
			sm.init(provider);

		}
		// }}}

		, each: function(fn, scope) {
			items.each(fn, scope);
		}

	}; // end of return

}();
// }}}

// end of file
