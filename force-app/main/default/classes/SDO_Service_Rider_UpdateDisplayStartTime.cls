global class SDO_Service_Rider_UpdateDisplayStartTime 
{
    @InvocableMethod(label='Rider - Update Display StartTime')
    public static List<String> updateDisplayStartTime(List<updateDisplayStartTimeRequest> requests) 
    {
        List<String> results = new List<String>();
        string result = '';
        
        for (updateDisplayStartTimeRequest request : requests)
        {
            try
            {
                if (request != null && request.starttime != null)
                {
                    //Init the result to userinfo.
                    //Get timezone of runing user
                    TimeZone tz = UserInfo.getTimeZone();
                    result = request.starttime.format('EEE MMM d h:mmaaa', tz.getID());
                    
                    //First see if a contact is passed (prefer over sa territory)
                    if (String.isNotBlank(request.contactID))
                    {
                        //Get the contact
                        List<Contact> objContacts = new List<Contact>([SELECT ID, SDO_SFS_Rider_ServiceTerritory__c FROM CONTACT WHERE ID =: request.contactID]);
                        
                        //See if we can get the contact's tz from service territory
                        if (objContacts.size() > 0 && objContacts[0].SDO_SFS_Rider_ServiceTerritory__c != null)
                        {
                            request.territoryID = objContacts[0].SDO_SFS_Rider_ServiceTerritory__c;
                        }
                    }
                    
                    //Now see if a territory is passed
                    if (String.isNotBlank(request.territoryID))
                    {
                        //Get service Territory TimeZone
                        List<ServiceTerritory> objSTs = new List<ServiceTerritory>([SELECT ID, OperatingHours.TimeZone FROM ServiceTerritory WHERE ID =: request.territoryID LIMIT 1]);
                        if (objSTs.size() > 0 && String.isNotBlank(objSTs[0].OperatingHours.TimeZone))
                        {
                            tz = Timezone.getTimeZone(objSTs[0].OperatingHours.TimeZone);
                            result = request.starttime.format('EEE MMM d h:mmaaa', tz.getID());
                        }
                    }
                }
                
                if (request != null && request.saID != null)
                {
                    //Now update the SA
                    List<ServiceAppointment> objSAs = new List<ServiceAppointment>([SELECT ID, Rider_StartTime__c FROM ServiceAppointment WHERE ID=: request.saID LIMIT 1]);
                    if (objSAs.size() > 0)
                    {
                        objSAs[0].Rider_StartTime__c = result;
                        UPDATE objSAs[0];
                    }
                }
                
            }
            catch (Exception ex)
            {
                
            }
            break;
        }
        results.add(result);
        return results;
    }
    
    global class updateDisplayStartTimeRequest
    {
        @InvocableVariable(required=false)
        global string territoryId;
        @InvocableVariable(required=false)
        global string contactID;
        @InvocableVariable(required=false)
        global datetime starttime;
        @InvocableVariable(required=true)
        global Id saID;
    }
}