/*
 * Ext JS Library 1.1
 * Copyright(c) 2006-2007, Ext JS, LLC.
 * licensing@extjs.com
 * 
 * http://www.extjs.com/license
 */

Ext.onReady(function(){
    Ext.get('mb1').on('click', function(e){
        Ext.MessageBox.confirm('Confirm', 'Are you sure you want to do that?', showResult);
    });

    Ext.get('mb2').on('click', function(e){
        Ext.MessageBox.prompt('Name', 'Please enter your name:', showResultText);
    });

    Ext.get('mb3').on('click', function(e){
        Ext.MessageBox.show({
           title: 'Address',
           msg: 'Please enter your address:',
           width:300,
           buttons: Ext.MessageBox.OKCANCEL,
           multiline: true,
           fn: showResultText,
           animEl: 'mb3'
       });
    });

    Ext.get('mb4').on('click', function(e){
        Ext.MessageBox.show({
           title:'Save Changes?',
           msg: 'Your are closing a tab that has unsaved changes. Would you like to save your changes?',
           buttons: Ext.MessageBox.YESNOCANCEL,
           fn: showResult,
           animEl: 'mb4'
       });
    });

    Ext.get('mb6').on('click', function(){
        Ext.MessageBox.show({
           title: 'Please wait...',
           msg: 'Initializing...',
           width:240,
           progress:true,
           closable:false,
           animEl: 'mb6'
       });

       // this hideous block creates the bogus progress
       var f = function(v){
            return function(){
                if(v == 11){
                    Ext.MessageBox.hide();
                }else{
                    Ext.MessageBox.updateProgress(v/10, 'Loading item ' + v + ' of 10...');
                }
           };
       };
       for(var i = 1; i < 12; i++){
           setTimeout(f(i), i*1000);
       }
    });

    Ext.get('mb7').on('click', function(){
        Ext.MessageBox.alert('Status', 'Changes saved successfully.', showResult);
    });


    function showResult(btn){
        Ext.example.msg('Button Click', 'You clicked the {0} button', btn);
    };

    function showResultText(btn, text){
        Ext.example.msg('Button Click', 'You clicked the {0} button and entered the text "{1}".', btn, text);
    };
});