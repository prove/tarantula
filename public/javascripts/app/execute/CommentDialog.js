var CommentDialog = function() {


    var textArea;
    var dialog;

    var stepIndex;

    return{

        init: function( fnOk) {
            // fn: callback function called with argument
            if(!dialog){ // lazy initialize the dialog and only create it once
                el = Ext.get('dlgComment');

                if( !el) {
                    el = Ext.DomHelper.append(document.body,
                                              {tag:'div',
                                               id:'dlgComment',
                                               cls:'dialog'});
                }

                dialog = new Ext.LayoutDialog( el, {
                    modal:false,
                    width:500,
                    height:300,
                    shadow:true,
                    minWidth:500,
                    minHeight:300,
                    proxyDrag: true,
                    modal: true,
                    center: {
                        autoScroll:true
                    }
                });

                dialog.addKeyListener(27, dialog.hide, dialog);

                dialog.addButton('Ok', function() {
                    dialog.hide();
                    fnOk( stepIndex, textArea.getValue());
                }, dialog);

                dialog.addButton('Cancel', function() {
                    dialog.hide();
                    //fnCancel();
                }, dialog);

                var layout = dialog.getLayout();
                layout.beginUpdate();

                cp = new Ext.ContentPanel(Ext.id(), { autoCreate:true, background:true});
                layout.add('center', cp);

                // Add div into content panel for actual form..
                cp.setContent('<p>' +
                              '</p><div id="dlgCommentForm"></div>');


                layout.endUpdate();

                var simple = new Ext.form.Form({
                    labelSeparator: ':',
                    labelAlign: 'top',
                    itemCls: 'dialogFormItem'
                });

                textArea = new Ext.form.TextArea({
                    autoCreate: true,
                    height: 160,
                    width: 350,
                    fieldLabel: 'Comment'
                });


                simple.add( textArea);

                simple.render("dlgCommentForm");


            }
        },

        show: function( _stepIndex) {
            stepIndex = _stepIndex;
            textArea.setValue(CaseExecute.getComment(stepIndex));
            dialog.center();
            dialog.show();
            textArea.focus();
        }

    };

}();