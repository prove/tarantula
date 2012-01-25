// TextField implementation which fixes focus bug in Windows FF.
// more info at: http://extjs.com/forum/showthread.php?t=19299&highlight=firefox+textfield
Ext.namespace('Ext.testia');
Ext.testia.StepField = function(config) {
    config = config || {};
    config.hideTrigger = true;

    Ext.testia.StepField.superclass.constructor.call(this, config);
    this.onTriggerClick = function() {};
};

Ext.extend(Ext.testia.StepField, Ext.form.TriggerField, {});