/*
 * Ext JS Library 1.1
 * Copyright(c) 2006-2007, Ext JS, LLC.
 * licensing@extjs.com
 * 
 * http://www.extjs.com/license
 */

var Comments = function(){
    var dialog, postLink, viewLink, txtComment;
    var tabs, commentsList, postBtn, renderer;
    var wait, error, errorMsg;
    var posting = false;
    
    return {
        init : function(){
             // cache some elements for quick access
             txtComment = Ext.get('comment');
             commentsList = Ext.get('comments-list');
             postLink = Ext.get('post-comment');
             viewLink = Ext.get('view-comments');
             wait = Ext.get('post-wait');
             error = Ext.get('post-error');
             errorMsg = Ext.get('post-error-msg');
             
             this.createDialog();
             
             postLink.on('click', function(e){
                 e.stopEvent();
                 tabs.activate('post-tab');
                 dialog.show(postLink);
             });
             
             viewLink.on('click', function(e){
                 e.stopEvent();
                 tabs.activate('view-tab');
                 dialog.show(viewLink);
             });             
        },
        
        // submit the comment to the server
        submitComment : function(){
            postBtn.disable();
            wait.radioClass('active-msg');
            
            var commentSuccess = function(o){
                postBtn.enable();
                var data = renderer.parse(o.responseText);
                // if we got a comment back
                if(data){
                    wait.removeClass('active-msg');
                    renderer.append(data.comments[0]);
                    dialog.hide();
                }else{
                    error.radioClass('active-msg');
                    errorMsg.update(o.responseText);
                }
            };
            
            var commentFailure = function(o){
                postBtn.enable();
                error.radioClass('active-msg');
                errorMsg.update('Unable to connect.');
            };
    
            Ext.lib.Ajax.formRequest('comment-form', 'post.php',
                    {success: commentSuccess, failure: commentFailure});          
        },
        
        createDialog : function(){
            dialog = new Ext.BasicDialog("comments-dlg", { 
                    autoTabs:true,
                    width:500,
                    height:300,
                    shadow:true,
                    minWidth:300,
                    minHeight:300
            });
            dialog.addKeyListener(27, dialog.hide, dialog);
            postBtn = dialog.addButton('Post', this.submitComment, this);
            dialog.addButton('Close', dialog.hide, dialog);

            
            // clear any messages and indicators when the dialog is closed
            dialog.on('hide', function(){
                wait.removeClass('active-msg');
                error.removeClass('active-msg');
                txtComment.dom.value = '';
            });
            
            // stoe a refeence to the tabs
            tabs = dialog.getTabs();
            
            // auto fit the comment box to the dialog size
            var sizeTextBox = function(){
                txtComment.setSize(dialog.size.width-44, dialog.size.height-264);
            };
            sizeTextBox();
            dialog.on('resize', sizeTextBox);
            
            // hide the post button if not on Post tab
            tabs.on('tabchange', function(panel, tab){
                postBtn.setVisible(tab.id == 'post-tab');
            });
            
            // set up the comment renderer, all ajax requests for commentsList
            // go through this render
            renderer = new CommentRenderer(commentsList);
            var um = commentsList.getUpdateManager();
            um.setRenderer(renderer);
            
            // lazy load the comments when the view tab is activated
            var commentsLoaded = false;
            tabs.getTab('view-tab').on('activate', function(){
                if(!commentsLoaded){
                    um.update('comments.txt');
                    commentsLoaded = true;
                }
            });
        }
    };
}();

// This class handles rendering JSON into comments
var CommentRenderer = function(list){
    // create a template for each JSON object
    var tpl = new Ext.DomHelper.Template(
          '<li id="comment-{id}">' +
          '<div class="cheader">' +
          '<div class="cuser">{author}:</div>' +
          '<div class="commentmetadata">{date}</div>' +
          '</div>{text}</li>'
    );
    
    this.parse = function(json){
        try{
            return eval('(' + json + ')');
        }catch(e){}
        return null;
    };
    
    // public render function for use with UpdateManager
    this.render = function(el, response){
        var data = this.parse(response.responseText);
        if(!data || !data.comments || data.comments.length < 1){
            el.update('There are no comments for this post.');
            return;
        }
        // clear loading
        el.update('');
        for(var i = 0, len = data.comments.length; i < len; i++){
            this.append(data.comments[i]);
        }
    };
    
    // appends a comment 
    this.append = function(data){
        tpl.append(list.dom, data);
    };
};

Ext.EventManager.onDocumentReady(Comments.init, Comments, true);