trigger SDO_Tool_SalesforceRewind_OpportunitySplit on OpportunitySplit (after insert, after update, after delete) {
    if(System.isBatch()) return;
    SDO_Tool_SalesforceRewindTriggerHandler.publishNotifications(Trigger.oldMap, Trigger.new, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete);
}