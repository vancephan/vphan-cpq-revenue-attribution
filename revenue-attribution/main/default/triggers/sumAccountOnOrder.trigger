trigger sumAccountOnOrder on Order(after update){
    for(Order o: trigger.new){
        if(o.SBQQ__Contracted__c == TRUE && trigger.oldMap.get(o.Id).SBQQ__Contracted__c != TRUE){
            
            List<Contract> conts = [SELECT Id
                                    FROM Contract
                                    WHERE SBQQ__Order__c =: o.Id];

            for(Contract cont: conts){
                updateAccountSubscriptionSums sumSubCode = new updateAccountSubscriptionSums();

                sumSubCode.execute(cont);
            }
        }
    }
}