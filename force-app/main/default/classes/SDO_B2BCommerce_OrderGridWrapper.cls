/*
==========================================
    Title: OrderGridWrapper
    Purpose: Wrapper class store to the
        order products and webstore Id.
    Author: Clay Phillips
    Created Date: 08/24/2020 
==========================================
*/

public with sharing class SDO_B2BCommerce_OrderGridWrapper{
    @AuraEnabled
    public List<SDO_B2BCommerce_OrderProductWrapper> orderProducts{get;set;}

    @AuraEnabled
    public String webstoreId{get;set;}
}