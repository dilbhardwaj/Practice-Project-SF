@RestResource(urlMapping='/v1/opportunities/*')
global with sharing virtual class OpportunityApiV1 {
	@HttpGet
    global static void doGet(){
        
        String lastPart=RestContext.request.requestURI.substringAfterLast('/');
        if(lastPart.length()>=15){
            Opportunity opp=[select id,name,stagename,closedate,amount,(select id,quantity,unitprice from OpportunityLineItems) from opportunity where id=:lastPart limit 1];
            RestContext.response.statusCode=200;
            RestContext.response.responseBody=Blob.valueOf(JSON.serialize(opp));
        }else{
            String accountId=RestContext.request.params.get('accountId');
            List<Opportunity> oppList=[select id,name,stageName,closedate from Opportunity where accountId=:accountId limit 10];
            RestContext.response.statusCode=200;
            RestContext.response.responseBody=Blob.valueOf(JSON.serialize(oppList));
        }
    }
    
    @HttpPost
global static void doPost() {
    Boolean hasPermission = FeatureManagement.checkPermission('Partner_Write_Access');
    if (hasPermission == null || !hasPermission) {
        RestContext.response.statusCode  = 403;
        RestContext.response.responseBody = Blob.valueOf('Access Denied');
        return;
    }

    Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(
        RestContext.request.requestBody.toString()
    );
    Opportunity opp = new Opportunity();
    opp.Name      = (String) data.get('name');
    opp.AccountId = (String) data.get('accountId');
    opp.StageName = (String) data.get('stageName');
    opp.CloseDate = Date.valueOf((String) data.get('closedate'));
    insert opp;

    List<Object> items = (List<Object>) data.get('lineItems');
    if (items != null && items.size() > 0) {
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        for (Object item : items) {
            Map<String, Object> li = (Map<String, Object>) item;
            OpportunityLineItem oli = new OpportunityLineItem();
            oli.OpportunityId    = opp.Id;
            oli.PricebookEntryId = (String) li.get('pricebookEntryId');
            oli.Quantity         = Integer.valueOf(li.get('quantity'));
            oli.UnitPrice        = Decimal.valueOf(String.valueOf(li.get('unitPrice')));
            oliList.add(oli);
        }
        Database.insert(oliList, false);
    }

    RestContext.response.statusCode   = 201;
    RestContext.response.responseBody = Blob.valueOf('Done');
}

        
    @HttpDelete
global static void doDelete() {
    Boolean hasPermission = FeatureManagement.checkPermission('Partner_Write_Access');
    if (hasPermission == null || !hasPermission) {
        RestContext.response.statusCode   = 403;
        RestContext.response.responseBody = Blob.valueOf('Access Denied');
        return;
    }

    String lastPart = RestContext.request.requestURI.substringAfterLast('/');
    Opportunity opp = [
        SELECT Id, StageName FROM Opportunity WHERE Id = :lastPart LIMIT 1
    ];
    opp.StageName = 'Closed Lost';
    update opp;

    RestContext.response.statusCode   = 200;
    RestContext.response.responseBody = Blob.valueOf('Done');
}
    }