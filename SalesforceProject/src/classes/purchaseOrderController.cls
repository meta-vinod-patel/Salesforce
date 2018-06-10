public with sharing class purchaseOrderController {
    public purchaseOrderController(){
        fetchDataFromOrg();
        showCartMessage = true;
        showUserForm = false;
        userAccount = new purchasedOrder__c();
        orderPurchased = false;
        showCart = true;
    }
    public List<ProductWrapperClass> allProductInOrg {get;set;}
    public List<ProductWrapperClass> selectedProductList {get; set;}
    public boolean showCartMessage {get;set;}
    public string paramProductId{get;set;}
    public Decimal cartTotal {get; set;}
    public Id selectedProductID {get;set;}
    public Id updateProductQuantity {get;set;}
    public purchasedOrder__c userAccount {get;set;}
    public boolean showUserForm {get;set;}
    public boolean orderPurchased {get;set;}
    public boolean showCart {get;set;}
    
    public class ProductWrapperClass{
        public Product2 product {get; set;}
        public Boolean isSelected {get; set;}
        public Decimal quantity {get; set;}
        public Decimal amount {get;set;}
        public ProductWrapperClass(){
            isSelected = false;
            quantity = 1;
            amount = 0;
        }
        public Product2 getMyProduct(){
            return new Product2(Quantity__c = this.quantity);
        }
    }
    
    public void fetchDataFromOrg(){
        List<Product2> allProducts = [SELECT Id, Name, Price__c, Quantity__c, ProductCode
                                      FROM Product2];
        allProductInOrg = new List<ProductWrapperClass>();
        for(Product2 prod : allProducts){
            ProductWrapperClass productRecord = new ProductWrapperClass();
            productRecord.product = prod;
            allProductInOrg.add(productRecord);
        }
    }
    
    public PageReference processWithSelected(){
        selectedProductList = new List<ProductWrapperClass>();
        cartTotal = 0.0;
        for(ProductWrapperClass selectedProduct : allProductInOrg){
            if(selectedProduct.isSelected == true){
                if(selectedProduct.product.Id == selectedProductID){
                    selectedProduct.product.Quantity__c -= 1 ; 
                }
                cartTotal = selectedProduct.product.price__c + cartTotal;
                selectedProduct.amount = selectedProduct.quantity*selectedProduct.product.Price__c;
                selectedProductList.add(selectedProduct);
            }
            
            if(selectedProduct.isSelected == false && selectedProduct.product.Id == selectedProductID){
                selectedProduct.product.Quantity__c += 1; 
            }
        } 
        if(selectedProductList.size() != 0){
            showCartMessage = false;
        }else{
            showCartMessage = true;
        }
        return null;
    }
    
    public void remove(){
        paramProductId = apexpages.currentPage().getParameters().get('productId');
        Integer i = 1;
        Integer index;
        for(ProductWrapperClass selectedProduct : selectedProductList){
            if(selectedProduct.product.Id == paramProductId){
                selectedProduct.isSelected = false;
                selectedProduct.product.Quantity__c += 1;
                cartTotal = cartTotal - selectedProduct.product.price__c;
                index = selectedProductList.indexOf(selectedProduct);
            }
            i++;
        }
        selectedProductList.remove(index);
        if(selectedProductList.isEmpty()){
            showCartMessage = true;
        }
    }
    
    public void getSelectedList(){
        system.debug(selectedProductList);
    }
    
    public PageReference cancel(){
        showUserForm = false;
        return null;
    }
    
    public void showUser(){
        showUserForm = true;
    }
    
    public void setQuantity(){
        
    }
    
    public PageReference save(){
        userAccount.OrderAmount__c = cartTotal;
        userAccount.PurchasedOn__c = system.today();
        Insert userAccount;
        Id userId = userAccount.Id;
        system.debug(userId);
        List<purchasedOrderLineItem__c> purchasedProductList = new List<purchasedOrderLineItem__c>();
        for(ProductWrapperClass addPurchased : selectedProductList){
            purchasedOrderLineItem__c purchasedProduct = new purchasedOrderLineItem__c();
            purchasedProduct.Product_Purchased_By__c = userId;
            purchasedProduct.ProductCode__c = addPurchased.product.ProductCode;
            purchasedProduct.ProductId__c = addPurchased.product.Id;
            purchasedProduct.Name = userAccount.Name;
            purchasedProduct.Quantity__c = addPurchased.quantity;
            purchasedProduct.Service_Date__c = System.today();
            purchasedProduct.SubTotal__c = addPurchased.amount;
            purchasedProductList.add(purchasedProduct);
            Insert purchasedProduct;
        }
        if(selectedProductList.size()!=0){
            List<product2> listOfProduct = new List<product2>(); 
            for(ProductWrapperClass products : selectedProductList){
                listOfProduct.add(products.product);
            }
            update listOfProduct;
        }
        showUserForm = false;
        showCart = false;
        showCartMessage = true;
        orderPurchased = true;
        selectedProductList.clear();
        PageReference pageRef = new PageReference('/apex/purchaseOrder');
        return pageRef;
       // return null;
    }
    
    public PageReference buyMore(){
        PageReference pageRef = new PageReference('/apex/RedirectToPurchaseOrder');
        return pageRef;	
    }
    
    public PageReference setQuantityInLine(){
        return null;
    }
    
}