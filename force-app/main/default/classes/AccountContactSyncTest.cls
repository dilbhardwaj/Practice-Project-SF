@isTest
public class AccountContactSyncTest { 
   
    
    @isTest
    public static void AccountContactSyncMethod(){
        List<Account> accList=Datafactory.getAccounts();
        Test.startTest();
        if(!accList.isEmpty()){
            insert accList;
        }
        Test.stopTest();
        
        
    }
    @isTest
    public static void AccountContactSyncMethodForUpdate(){
        List<Account> accList=Datafactory.getAccounts();
        insert accList;
        List<Contact> conList=new List<Contact>();
        for(Integer i=0;i<250;i++){
            Contact con=new Contact(lastName='Contact Test'+i, AccountId=accList[i].Id);
            conList.add(con);
        }
        if(!conList.isEmpty()){
            insert conList;
        }
         List<Opportunity> oppList=new List<Opportunity>();
        
        for(Integer i=0;i<250;i++){
            Opportunity opp=new Opportunity(AccountId=accList[i].Id,StageName='Prospecting',closeDate=Date.Today(),Name='Opp Test'+i);
            oppList.add(opp);
        }
        if(!oppList.isEmpty()){
            insert oppList;
        }
        for(Account acc : accList){
    		acc.Industry = 'Banking';
				}
           Test.startTest();
        if(!accList.isEmpty()){
            update accList;
        }
        Test.stopTest();
    }
}