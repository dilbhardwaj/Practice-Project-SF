public class DemoTriggerHandler {

    public static void handleInsert(Map<Id, Demo__c> demoMap) {
        processChain(demoMap.keySet());
    }

    public static void handleUpdate(List<Demo__c> demoList, Map<Id, Demo__c> demoOldMap) {
        Set<Id> affectedIds = new Set<Id>();
        for (Demo__c d : demoList) {
            if (d.Parent_Demo__c != demoOldMap.get(d.Id).Parent_Demo__c) {
                affectedIds.add(d.Id);
                if (demoOldMap.get(d.Id).Parent_Demo__c != null) {
                    affectedIds.add(demoOldMap.get(d.Id).Parent_Demo__c);
                }
            }
        }
        if (!affectedIds.isEmpty()) {
            processChain(affectedIds);
        }
    }

    public static void processChain(Set<Id> affectedIds) {

        Map<Id, Demo__c> allRecs = new Map<Id, Demo__c>([SELECT Id,Name, Parent_Demo__c FROM Demo__c]);

        Map<Id, Id> childOf = new Map<Id, Id>();
        for (Demo__c r : allRecs.values())
            if (r.Parent_Demo__c != null)
                childOf.put(r.Parent_Demo__c, r.Id);

        List<Demo__c> toUpdate = new List<Demo__c>();
 		 for (Id startId : affectedIds) {
   				 Id root = startId;
  				  while (true) {
     				   Demo__c currentRec = allRecs.get(root);
      						  if (currentRec == null) {
          						  break;
      							  }
        						if (currentRec.Parent_Demo__c == null) {
         						   break;
      								  }
      							  root = currentRec.Parent_Demo__c;
   								 }
    Id leaf = root;
    while (true) {
        if (childOf.containsKey(leaf)) {
            leaf = childOf.get(leaf);
        } else {
            break;
        }
    } 
    Id cur = root;
    while (cur != null) {
        Demo__c recToUpdate = new Demo__c();
        recToUpdate.Id = cur;
        if (cur == root) {
            recToUpdate.Last_GrandParent__c = null;
        } else {
            recToUpdate.Last_GrandParent__c = allRecs.get(root).Name;
        }
        if (cur == leaf) {
            recToUpdate.Last_GrandChild__c = null;
        } else {
            recToUpdate.Last_GrandChild__c = allRecs.get(leaf).Name;
        }
        toUpdate.add(recToUpdate);
        cur = childOf.get(cur); 
    }
}
        Database.update(toUpdate, false);
    }
}