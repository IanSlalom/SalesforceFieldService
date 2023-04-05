/*
 * Copyright (c) 2020, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

@IsTest
public with sharing class SDO_B2BCommerce_BundleTest {

    private static Id parentProductId;
    private static Id bundleProductId;
    private static Id bundleItemId;
    private static Id bundlePbeId;
    private static Id bundleStdPbeId;

    private static String bundleProductSku = '999AAA000222';

    private static void setupTestData() {

        parentProductId =  SDO_B2BCommerce_BundleTestUtils.createProduct('Parent Product', '999AAA000111', '');

        bundleProductId =  SDO_B2BCommerce_BundleTestUtils.createProduct('Bundle Product', bundleProductSku, '');

        bundleItemId = SDO_B2BCommerce_BundleTestUtils.createBundleItem(parentProductId, bundleProductId, 2);

        Id pricebookId = SDO_B2BCommerce_BundleTestUtils.createPricebook();

        SDO_B2BCommerce_BundleTestUtils.createStandardPricebookEntry(parentProductId);

        SDO_B2BCommerce_BundleTestUtils.createPricebookEntry(pricebookId, parentProductId);

        bundleStdPbeId = SDO_B2BCommerce_BundleTestUtils.createStandardPricebookEntry(bundleProductId);

        bundlePbeId = SDO_B2BCommerce_BundleTestUtils.createPricebookEntry(pricebookId, bundleProductId);

    }
    
    @IsTest
    /*
        Test getting the product detail
    */

    public static void testCode1() {

        User adminUser = SDO_B2BCommerce_BundleTestUtils.createAdminUser();
        
        SDO_B2BCommerce_BundleTestUtils.assignPermissionSetToUser(adminUser.Id, 'B2B_LE_Bundle_Product_Admin');

        System.runAs(adminUser) {
            setupTestData();
        }

        String communityId = null;
        String effectiveAccountID = null;

        List<ConnectApi.ProductDetail> myProductsInformations = null;

        Test.startTest();

        System.runAs(adminUser) {
        

        myProductsInformations = SDO_B2BCommerce_B2BBundle.getBundleProducts(communityId, parentProductId, effectiveAccountID);
       
        
        
        }

        Test.stopTest();

        System.debug('myProductsInformations: ' + JSON.serialize(myProductsInformations));

        ConnectApi.ProductDetail pd = null;

        pd = myProductsInformations.get(0);

        Map<String, String> fieldMap = pd.fields;

        Product2 product = null;

        System.runAs(adminUser) {
            product = SDO_B2BCommerce_BundleTestUtils.getProduct(bundleProductId);
        }

        String sku = fieldMap.get('StockKeepingUnit');

        System.assertEquals(bundleProductSku, sku);
    }

    @IsTest
    /*
        Test getting the product price
    */
    

    public static void testCode2() {

        User adminUser = SDO_B2BCommerce_BundleTestUtils.createAdminUser();
        
        SDO_B2BCommerce_BundleTestUtils.assignPermissionSetToUser(adminUser.Id, 'B2B_LE_Bundle_Product_Admin');

        System.runAs(adminUser) {
            setupTestData();
        }

        String communityId = null;
        String effectiveAccountID = null;

        ConnectApi.ProductPrice price = null;

        Test.startTest();
        
        price = SDO_B2BCommerce_B2BBundle.getProductPrice(communityId, bundleProductId, effectiveAccountID);
        
        Test.stopTest();

        System.debug('price: ' + JSON.serialize(price));

        String listPrice = price.listPrice;
        String unitPrice = price.unitPrice;

        PricebookEntry pbe = SDO_B2BCommerce_BundleTestUtils.getPricebookEntry(bundleStdPbeId, bundleProductId);

        System.assertEquals(listPrice, pbe.UnitPrice.format());

        PricebookEntry pbe2 = SDO_B2BCommerce_BundleTestUtils.getPricebookEntry(bundlePbeId, bundleProductId);

        System.assertEquals(unitPrice, pbe2.UnitPrice.format());
        

        

    }

    @IsTest
    /*
        Test adding to the cart
    */
    
    public static void testCode3() {

        User adminUser = SDO_B2BCommerce_BundleTestUtils.createAdminUser();
        
        SDO_B2BCommerce_BundleTestUtils.assignPermissionSetToUser(adminUser.Id, 'B2B_LE_Bundle_Product_Admin');

        System.runAs(adminUser) {
            setupTestData();
        }

        String communityId = null;
        String effectiveAccountID = null;

        ConnectApi.CartItem cartItem = null;

        Test.startTest();


        cartItem = SDO_B2BCommerce_B2BBundle.addToCart(communityId, bundleProductId, '1', effectiveAccountID);
        
        Test.stopTest();
        System.assertEquals(cartItem, null);

    }


    @IsTest
    /*
        Test getting the bundle item qty
    */
    
    
    
    public static void testCode4() {

        User adminUser = SDO_B2BCommerce_BundleTestUtils.createAdminUser();
        
        SDO_B2BCommerce_BundleTestUtils.assignPermissionSetToUser(adminUser.Id, 'B2B_LE_Bundle_Product_Admin');

        System.runAs(adminUser) {
            setupTestData();
        }

        String communityId = null;
        String effectiveAccountID = null;

        Decimal qty = null;

        Test.startTest();

        SDO_B2BCommerce_Bundle_Item__c bundle = null;

        System.runAs(adminUser) {
        
            qty = SDO_B2BCommerce_B2BBundle.getItemQuantity(parentProductId, bundleProductId);

            bundle = SDO_B2BCommerce_BundleTestUtils.getBundleItem(bundleItemId);
        }

        Test.stopTest();

        System.assertEquals(qty, bundle.Quantity__c);

    }

    @IsTest
    /*
        Test the search page url function
    */
    
    

    public static void testCode5() {

        User adminUser = SDO_B2BCommerce_BundleTestUtils.createAdminUser();
        
        SDO_B2BCommerce_BundleTestUtils.assignPermissionSetToUser(adminUser.Id, 'B2B_LE_Bundle_Product_Admin');

        System.runAs(adminUser) {
            setupTestData();
        }

        String myCurrentProductURL = null;

        Test.startTest();
        
        myCurrentProductURL = SDO_B2BCommerce_B2BBundle.searchCurrentProductPageURL();          

        Test.stopTest();

        System.debug(myCurrentProductURL);

        Boolean checkIt = myCurrentProductURL.endsWith('/s/product/');

        System.assertEquals(checkIt, true);

    }

}