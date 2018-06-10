public class ShopifyController {

    //declarations
    public List<ProductWrapperClass> allProductsInOrg {get;set;}
    public Id selectedProductID {get;set;}
    public List<ProductWrapperClass> selectedProductList {get; set;}
    public Decimal cartTotal {get; set;}
    public boolean showCartMessage {get;set;}
    public boolean showUserForm{get;set;}
    public purchasedOrder__c userAccount {get;set;}
    public Id cartProductId {get;set;}

    //constructor
    public ShopifyController(){
        fetchAllProductsFromOrg();
        showCartMessage = true;
        userAccount = new purchasedOrder__c();
    }

    //features
    public void fetchAllProductsFromOrg(){
        List<Product2> allProducts = [SELECT Id, Name, Price__c, Quantity__c, ProductCode
        FROM Product2
        WHERE Quantity__c > 0
        AND Quantity__c !=Null
        AND Price__c !=NUll
        LIMIT 7];
        allProductsInOrg = new List<ProductWrapperClass>();
        for(Product2 product : allProducts){
            allProductsInOrg.add(new ProductWrapperClass(product));
        }
    }

    public void processSelected(){
        selectedProductList = new List<ProductWrapperClass>();
        cartTotal = 0.0;
        Integer count = 0;
        for(ProductWrapperClass selectedProduct : allProductsInOrg){
            Product2 newProduct = selectedProduct.product.clone();
            if(selectedProduct.isSelected == true){
                selectedProductList.add(new ProductWrapperClass(newProduct));
                cartTotal = selectedProduct.product.price__c + cartTotal;
                selectedProductList.get(count).productId = selectedProduct.product.Id;
                selectedProductList.get(count).product.Quantity__c = 1;
                selectedProductList.get(count).amount = selectedProductList.get(count).product.Quantity__c*selectedProductList.get(count).product.Price__c;
                count++;
            }
        }

        if(selectedProductList.size() != 0){
            showCartMessage = false;
        }else{
            showCartMessage = true;
        }
    }

    public void goCheckOut(){
        showUserForm = true;
    }
    //check Availability
    public void setQuantityInLine(){
        cartTotal = 0.0;
        for(ProductWrapperClass orgProduct : allProductsInOrg){
            for(ProductWrapperClass selectedProduct : selectedProductList){
                if(orgProduct.product.id == selectedProduct.productId){
                    if(orgProduct.product.Quantity__c < selectedProduct.product.Quantity__c || selectedProduct.product.Quantity__c < 0 ){
                        selectedProduct.product.Quantity__c = 1;
                    }
                    selectedProduct.amount = selectedProduct.product.Quantity__c*selectedProduct.product.Price__c;
                    //selectedProduct.quantity = orgProduct.product.Quantity__c;
                    cartTotal += selectedProduct.amount;
                    break;
                }
            }
        }
    }

    public PageReference save(){
        userAccount.OrderAmount__c = cartTotal;
        userAccount.PurchasedOn__c = system.today();
        Insert userAccount;
        Id userId = userAccount.Id;
        List<purchasedOrderLineItem__c> purchasedProductList = new List<purchasedOrderLineItem__c>();
        for(ProductWrapperClass addPurchased : selectedProductList){
            purchasedOrderLineItem__c purchasedProduct = new purchasedOrderLineItem__c();
            purchasedProduct.Product_Purchased_By__c = Id.valueOf(userId);
            purchasedProduct.ProductCode__c = addPurchased.product.ProductCode;
            purchasedProduct.ProductId__c = Id.valueOf(addPurchased.productId);
            purchasedProduct.Name = addPurchased.product.Name;
            purchasedProduct.Quantity__c = addPurchased.product.Quantity__c;
            purchasedProduct.Service_Date__c = System.today();
            purchasedProduct.SubTotal__c = addPurchased.amount;
            purchasedProductList.add(purchasedProduct);
        }
        //Insert purchasedProductList;
        system.debug('-->saving records<--');
        system.debug(purchasedProductList);
        system.debug(allProductsInOrg);
        List<Product2> productToBeUpdated = new List<Product2>();
        for(ProductWrapperClass orgProduct : allProductsInOrg){
            for(purchasedOrderLineItem__c purchasedProduct : purchasedProductList){
                if(purchasedProduct.productId__c == orgProduct.product.Id){
                    system.debug('Do operation with org Product ->>'+orgProduct.product);
                    orgProduct.product.Quantity__c = orgProduct.product.Quantity__c - purchasedProduct.Quantity__c;
                    system.debug('after Operation->>'+orgProduct.product);
                    productToBeUpdated.add(orgProduct.product);

                }
            }
        }
        system.debug(productToBeUpdated);
        update productToBeUpdated;
        PageReference redirectPage = new PageReference('/' + userId);
        redirectPage.setRedirect(true);
        return redirectPage;
    }

    public PageReference cancel(){
        PageReference redirectPage = new PageReference('/apex/shopify');
        redirectPage.setRedirect(true);
        return redirectPage;
    }

    public void addMore(){
        cartProductId = apexpages.currentPage().getParameters().get('productId');
        system.debug(cartProductId);
        Decimal quantity = getProductQuantity(cartProductId);
        if(quantity != null){
            for(ProductWrapperClass selectedProduct : selectedProductList){
                if(selectedProduct.productId == cartProductId && selectedProduct.product.Quantity__c <= quantity){
                    selectedProduct.product.Quantity__c += 1 ;
                    selectedProduct.amount = selectedProduct.product.price__c + selectedProduct.amount;
                    cartTotal = cartTotal + selectedProduct.product.price__c;
                }
            }
        }
    }

    public void remove(){
        cartProductId = apexpages.currentPage().getParameters().get('productId');
        system.debug(cartProductId);
        for(ProductWrapperClass selectedProduct : selectedProductList){
            if(selectedProduct.productId == cartProductId && selectedProduct.product.Quantity__c > 1){
                selectedProduct.product.Quantity__c -= 1 ;
                selectedProduct.amount = selectedProduct.amount - selectedProduct.product.price__c;
                cartTotal = cartTotal - selectedProduct.product.price__c;
            }
        }
    }

    public Decimal getProductQuantity(Id productId){
        for(ProductWrapperClass product : allProductsInOrg){
            if(productId == product.product.Id)
                return product.product.Quantity__c;
        }
        return null;
    }

    public class ProductWrapperClass{
        public Id productId{get;set;}
        public Product2 product {get; set;}
        public Boolean isSelected {get; set;}
        public Decimal amount {get;set;}
        public Decimal quantity{get;set;}
        public ProductWrapperClass(Product2 p){
            this.product = p;
            isSelected = false;
            amount = 0;
            quantity = 1;
        }
    }
}