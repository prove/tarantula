var MainContentAdmin = function() {
  var tab_id; //Currently active tab.

  var currentTabFunc = function() {
  // Helper function to determine function providing currently active tab.
    switch(tab_id) {
      case 'admin-userstab':
        return Users;
        break;
      case 'admin-projectstab':
        return Projects;
        break;
    }
  };

  return {

    init: function() {
      tab_id = 'admin-userstab';
      setTimeout("Users.init()",500);
    },

    tab_changed: function(tab) {
          // FIXME: Probably dead code?
      tab_id = tab;
      switch(tab) {
        case 'admin-userstab':
          // TODO: Purkka pois
          setTimeout("Users.init()",500);
          break;
        case 'admin-projectstab':
          Projects.init();
          break;
      }
    },

    case_changed: function(n) {
    },

    set_changed: function(n) {
    },

    exec2_changed: function(n){
    },

    project_changed: function(n) {
      if (tab_id == 'admin-projectstab') {
        Projects.load(n.attributes.dbid);
      }
    },

    user_changed: function(id) {
      if (tab_id == 'admin-userstab') {
        Users.load(id);
      }
    },

    clear: function(){
      // Called when user want's to change view to another.
      // Should return true and clear view, when it is ok to clear view.
      // false otherwise.
      if ( currentTabFunc().clear != undefined) {
        // View defines clear() method, return it's value...
        return currentTabFunc().clear();
      } else {
        // Otherwise just assume it's ok to clear.
        return true;
      }
    }
        ,
    htmlContent: function() {
      return('<div id="tabs1"><div id="admin-userstab" class="tab-content"><h2>Users</h2><div id="usertoolbar"></div><div id="userform"></div></div><div id="admin-projectstab" class="tab-content"><h2>Projects</h2><div id="projecttoolbar"></div><div id="projectform"></div><div id="users-grid"></div></div></div>')
    },
    htmlContentUsers: function() {
      return('<div id="userform"></div>');

    },
    htmlContentProjects: function() {
     return('<div id="projectform"></div><div id="users-grid"></div></div>');
    }
  }
}();
