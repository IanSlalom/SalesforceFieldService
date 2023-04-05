@isTest
public class SDO_Service_OpenCTI_LiveAgent {
	@AuraEnabled
    public static Live_Agent_ID__c getId() {
      	Live_Agent_ID__c liveAgentId = [SELECT Chat_Button_ID__c, Deployment_ID_1__c, Deployment_ID_2__c FROM Live_Agent_ID__c][0];
        return liveAgentId;
  }
}