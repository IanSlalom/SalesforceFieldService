/*
==========================================
    Title: OrderGridController
    Purpose: This is the controller for
        the orderGridMain LWC. 
    Author: Clay Phillips
    Created Date: 08/24/2020 
    Last Modified Date: 01/26/2021 
==========================================
*/

public with sharing class SDO_B2BCommerce_OrderGridController{
    //Method to get the list of order products owned by the current community user
    @AuraEnabled(cacheable=true)
    public static SDO_B2BCommerce_OrderGridWrapper getOrderProducts(String communityId, String effectiveAccountId, String productIdTest){
        //Return no results if the component isn't run in a community by a community user
        if((communityId == null || effectiveAccountId == null) && productIdTest == null){
            return null;
        }

        //Return no results if the user can't access the necessary objects
        if(!canReadOrderProducts() || !canReadOrders() || !canReadProducts() || !canReadWebStoreNetworks()){
            return null;
        }

        Id currentUserId = UserInfo.getUserId();

        List<OrderItem> orderProducts = [SELECT Id,
                                                Order.Id,
                                                Order.OrderedDate,
                                                Product2.Id,
                                                Product2.Name,
                                                Product2.StockKeepingUnit,
                                                Quantity
                                            FROM OrderItem
                                            WHERE Order.OwnerId = :currentUserId
                                            AND Order.Status = 'Activated'
                                            ORDER BY Order.OrderedDate DESC];
        
        //Stores the list of order products returned by the SOQL query. This list doesn't doesn't contain the
        //product image information which requires a connect API call.
        List<SDO_B2BCommerce_OrderProductWrapper> orderProductWrappers = new List<SDO_B2BCommerce_OrderProductWrapper>();

        //Stores the list of order products that have product entitlements with their images. 
        List<SDO_B2BCommerce_OrderProductWrapper> orderProductWrappersTwo = new List<SDO_B2BCommerce_OrderProductWrapper>();

        SDO_B2BCommerce_OrderGridWrapper orderGridWrapper = new SDO_B2BCommerce_OrderGridWrapper();
        
        if(orderProducts.size() > 0){
            Set<String> productIds = new Set<String>();
            
            //Loops through the order product list and creates the orderProductWrappers list.
            for(OrderItem op: orderProducts){
                SDO_B2BCommerce_OrderProductWrapper opw = new SDO_B2BCommerce_OrderProductWrapper();
                opw.Id = op.Id;
                opw.orderId = op.Order.Id;
                opw.orderedDate = op.Order.OrderedDate;
                opw.productId = op.Product2.Id;
                opw.productName = op.Product2.Name;
                opw.productSKU = op.Product2.StockKeepingUnit;
                opw.quantity = op.Quantity;
                opw.productImageURL = null;
                orderProductWrappers.add(opw);

                productIds.add((String)op.Product2.Id);
            }

            List<String> productIdList = new List<String>(productIds); 
            List<ConnectApi.ProductDetail> products = new List<ConnectApi.ProductDetail>();
            String webstoreId = getStoreId(communityId);

            //If this method is run in a test class, use the method from the test utility class to get the ConnectApi products.
            //Else, use the method in this class which actually calls the ConnectApi.
            if(Test.isRunningTest()){
                products = getProductsTest(productIdTest);
            }
            else{   
                products = getProducts(productIdList, webstoreId, effectiveAccountId);
            }
            
            //Loop through the order product wrappers list and then loop through the ConnectApi products to match the records
            //and create the order product wrappers 2 list with the product image URLs. 
            for(Integer i = 0; i < orderProductWrappers.size(); i++){
                Boolean productFound = false;
                SDO_B2BCommerce_OrderProductWrapper opw = orderProductWrappers[i];
                for(ConnectApi.ProductDetail product : products){
                    if(product.id == opw.productId){
                        if(product.defaultImage.url != null){
                            opw.productImageURL = product.defaultImage.url;
                        }
                        if(product.variationAttributeSet != null)
                        {
                            opw.attributeDeveloperName = product.variationAttributeSet.developerName;
                            opw.attributeMap = (Map<String,String>)product.variationAttributeSet.attributes;
                            opw.attributeSetInfo = (Map<String,ConnectApi.ProductAttributeSetInfo>)product.attributeSetInfo;
                        }
                        productFound = true;
                        break;
                    }
                }

                if(productFound == true){
                    orderProductWrappersTwo.add(opw);
                }
            }
            orderGridWrapper.orderProducts = orderProductWrappersTwo;
            orderGridWrapper.webstoreId = webstoreId;
        }
        else{
            return null;
        }

        return orderGridWrapper;
    }
    
    //Method to grab the items in the current user's cart
    @AuraEnabled(cacheable=true)
    public static SDO_B2BCommerce_CartSummaryWrapper getCartSummary(String webstoreId, String effectiveAccountId){
        if(String.isBlank(webstoreId)){
            return null;
        }

        ConnectApi.CartItemCollection cartItemCollection;
        SDO_B2BCommerce_CartSummaryWrapper SDO_B2BCommerce_cartSummary = new SDO_B2BCommerce_CartSummaryWrapper();
        List<SDO_B2BCommerce_CartProductWrapper> cartItems = new List<SDO_B2BCommerce_CartProductWrapper>();

        //Returns a fake cart summary during a test for code coverage
        if(Test.isRunningTest()){
            SDO_B2BCommerce_cartSummary.cartId = 'testCartId1';

            SDO_B2BCommerce_CartProductWrapper cartItem = new SDO_B2BCommerce_CartProductWrapper();
            cartItem.productId = 'testProductId1';
            cartItem.quantity = 1;
            cartItem.errorMessage = 'testErrorMessage';
            cartItem.requestStatus = 'testRequestStatus';
            cartItems.add(cartItem);
        }
        else{
            try{cartItemCollection = ConnectApi.CommerceCart.getCartItems(webstoreId, effectiveAccountId, 'active');}
            catch(ConnectApi.ConnectApiException e){System.debug('ConnectApi.CommerceCart.getCartItems ConnectApiException: ' + e); return null;}
            catch(ConnectApi.NotFoundException e){System.debug('ConnectApi.CommerceCart.getCartItems NotFoundException: ' + e); return null;}
            catch(ConnectApi.RateLimitException e){System.debug('ConnectApi.CommerceCart.getCartItems RateLimitException: ' + e); return null;}

            SDO_B2BCommerce_cartSummary.cartId = cartItemCollection.cartSummary.cartId;
            
            for(ConnectApi.CartItemResult cartItemResult : cartItemCollection.cartItems){
                if(cartItemResult.cartItem != null){
                    SDO_B2BCommerce_CartProductWrapper cartItem = new SDO_B2BCommerce_CartProductWrapper();
                    cartItem.productId = cartItemResult.cartItem.productId;
                    cartItem.quantity = Integer.valueOf(cartItemResult.cartItem.quantity);
                    cartItem.errorMessage = cartItemResult.message;
                    cartItems.add(cartItem);
                }
            }
        }

        SDO_B2BCommerce_cartSummary.cartItems = cartItems;
        return SDO_B2BCommerce_cartSummary;
    }

    //Method to add selected products to the current user's cart.
    //Returning wrapper classes because I couldn't figure out a way to pull values from a ConnectApi.BatchInput
    //in my test class. Returning a list of ConnectApi.CartItemInput records causes an error on the client side
    //even though there aren't any Apex errors which makes it so I can't do accurate error handling.
    //Returning a list of wrapper classes solves both problems. 
    @AuraEnabled
    public static List<SDO_B2BCommerce_CartProductWrapper> addToCart(String productsJSON, String communityId, String effectiveAccountId){
        String webstoreId = getStoreId(communityId);

        List<Object> cartProducts = (List<Object>)JSON.deserializeUntyped(productsJSON);
        List<ConnectApi.BatchInput> batchInputList = new List<ConnectApi.BatchInput>();
        List<SDO_B2BCommerce_CartProductWrapper> cartItemWrappers = new List<SDO_B2BCommerce_CartProductWrapper>(); 

        //Create the batch input list for the add to cart ConnectApi call and create the cartItemWrappers list
        //that is returned for error handling.
        for(Object cartProduct : cartProducts){
            Map<String, Object> cpObjectMap = (Map<String, Object>)cartProduct;
            ConnectApi.CartItemInput cartItem = new ConnectApi.CartItemInput();
            SDO_B2BCommerce_CartProductWrapper cartItemWrapper = new SDO_B2BCommerce_CartProductWrapper();

            cartItem.productId = (String)cpObjectMap.get('productId');
            cartItemWrapper.productId = cartItem.productId;

            Integer quantity = (Integer)cpObjectMap.get('quantity');
            cartItem.quantity = quantity.format();
            cartItemWrapper.quantity = quantity;

            cartItem.type = ConnectApi.CartItemType.Product;
            
            ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(cartItem);
            batchInputList.add(batchInput);
            cartItemWrappers.add(cartItemWrapper);
        }

        //If the method isn't being called within a test class, use the ConnectApi method to add the products
        //to the current user's cart. If there is an error, return null for error handling.
        if(!Test.isRunningTest()){
            try{List<ConnectApi.BatchResult> batchResults = ConnectApi.CommerceCart.addItemsToCart(webstoreId, effectiveAccountId, 'active', batchInputList);}
            catch(ConnectApi.ConnectApiException e){System.debug('ConnectApi.CommerceCatalog.getProduct ConnectApiException: ' + e); return null;}
            catch(ConnectApi.NotFoundException e){System.debug('ConnectApi.CommerceCatalog.getProduct NotFoundException: ' + e); return null;}
            catch(ConnectApi.RateLimitException e){System.debug('ConnectApi.CommerceCatalog.getProduct RateLimitException: ' + e); return null;}
        }

        return cartItemWrappers;
    }

    //Method that returns the WebStoreId using the passed in community Id or null if no community Id is provided.
    private static String getStoreId(String communityId){
        if(communityId == null){
            return null;
        }

        return [SELECT WebStoreId FROM WebStoreNetwork WHERE NetworkId = :communityId LIMIT 1].WebStoreId;
    }

    //Method that uses the ConnectApi to get the ConnectApi product detail records which include
    //product images and entitlement information.
    private static List<ConnectApi.ProductDetail> getProducts(List<String> productIdList, String webstoreId, String effectiveAccountId){
        List<ConnectApi.ProductDetail> products = new List<ConnectApi.ProductDetail>();

        for(String productId : productIdList){
            try{
                ConnectApi.ProductDetail product = ConnectApi.CommerceCatalog.getProduct(webstoreId, productId, effectiveAccountId, null, false, null, false, false, true);
                products.add(product);
            }
            catch(ConnectApi.ConnectApiException e){
                System.debug('ConnectApi.CommerceCatalog.getProduct ConnectApiException: ' + e);
            }
            catch(ConnectApi.NotFoundException e){
                System.debug('ConnectApi.CommerceCatalog.getProduct NotFoundException: ' + e);
            }
            catch(ConnectApi.RateLimitException e){
                System.debug('ConnectApi.CommerceCatalog.getProduct RateLimitException: ' + e);
            }
        }

        return products;
    }

    //Method that determines whether the user can access order products. 
    @TestVisible
    private static Boolean canReadOrderProducts(){
        Boolean canReadOrderProducts = false;
        if(Schema.sObjectType.OrderItem.isAccessible() && Schema.sObjectType.OrderItem.fields.Quantity.isAccessible()){
            canReadOrderProducts = true;
        }
        return canReadOrderProducts;
    }

    //Method that determines whether the user can access orders.
    @TestVisible
    private static Boolean canReadOrders(){
        Boolean canReadOrders = false;
        if(Schema.sObjectType.Order.isAccessible() &&
            Schema.sObjectType.Order.fields.OrderedDate.isAccessible() &&
            Schema.sObjectType.Order.fields.OwnerId.isAccessible()){
            canReadOrders = true;
        }
        return canReadOrders;
    }

    //Method that determines whether the user can access products.
    @TestVisible
    private static Boolean canReadProducts(){
        Boolean canReadProducts = false;
        if(Schema.sObjectType.Product2.isAccessible() &&
            Schema.sObjectType.Product2.fields.Name.isAccessible() &&
            Schema.sObjectType.Product2.fields.StockKeepingUnit.isAccessible()){
            canReadProducts = true;
        }
        return canReadProducts;
    }

    //Method that determines whether the user can access wen store networks.
    @TestVisible
    private static Boolean canReadWebStoreNetworks(){
        Boolean canReadWebStoreNetworks = false;
        if(Schema.sObjectType.WebStoreNetwork.isAccessible() &&
            Schema.sObjectType.WebStoreNetwork.fields.WebStoreId.isAccessible() &&
            Schema.sObjectType.WebStoreNetwork.fields.NetworkId.isAccessible()){
            canReadWebStoreNetworks = true;
        }
        return canReadWebStoreNetworks;
    }

    //Method to return mocked ConnectApi.ProductDetail records for testing.
    private static List<ConnectApi.ProductDetail> getProductsTest(String productId){
        List<ConnectApi.ProductDetail> products = new List<ConnectApi.ProductDetail>();

        ConnectApi.ProductDetail product = new ConnectApi.ProductDetail();
        product.Id = productId;
        ConnectApi.ProductMedia pm = new ConnectApi.ProductMedia();
        pm.url = '';
        product.defaultImage = pm;
        products.add(product);

        return products;
    }
}