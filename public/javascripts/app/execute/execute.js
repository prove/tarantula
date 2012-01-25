
  /*
    TODO: Dokumentoi tämä jonnekin, varsinkin case changed yms osalta
  */
var MainContentExecute = function() {
    var tab_id;

    return {
      init: function(gui) {
          // TODO: Purkka pois
          CaseExecute.init(gui);
      },
      tab_changed: function(tab) {
          // FIXME: Probably dead code
          tab_id = tab;
      },
      case_changed: function(n) {
        CaseExecute.case_changed(n);
      },
      set_changed: function(n) {
      },
      exec2_changed: function(n) {
        CaseExecute.exec_changed(n);
      },
      clear: function(){
        // Called when user want's to change view to another.
        // Should return true and clear view, when it is ok to clear view.
        // false otherwise.
      },
    htmlContentOld: function() {
        return('<div id="tabs1"><!--<div id="exec-execstab" class="tab-content"><h2>Execute Case</h2>--><table id="cases"></table><div id="case_information"></div><table id="stepexec"></table><div id="bug-dlg"><div id="bug-panel"></div></div><!--</div>--></div>');
    },
    htmlContent: function() {
       // html = '<div id="exec_case_tb"></div>';
        html = '<div id="exec_case"></div>';

        html += '<div id="exec_steps_tb"></div>';
        html += '<div id="exec_steps_list"></div>';  /*</div>'; <- Bug? */
        return (html);
    }
    };
  }();