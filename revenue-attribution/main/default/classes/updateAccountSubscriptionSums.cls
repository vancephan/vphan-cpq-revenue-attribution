public class updateAccountSubscriptionSums{
    Contract c;
    Account acct;
    List<SBQQ__Subscription__c> cSubs;
    List<Id> prods;
    List<Subscription_Install_Base_Summary__c> sibs;

    public updateAccountSubscriptionSums(){

    }

    public Contract getContract(Id cid){
        c = [SELECT Id, AccountId
                FROM Contract
                WHERE Id =: cid].get(0);

        system.debug('Contract that started process is ' + c.Id);

        return c;
    }

    public Account getAccount(){
        acct = [SELECT Id, Name
                FROM Account
                WHERE Id =: c.AccountId].get(0);

        system.debug('Account to be summarized is ' + acct.name);

        return acct;
    }

    public void clearCurrentSummaries(){
        List<Subscription_Install_Base_Summary__c> currentSums = [SELECT Id
                                                                    FROM Subscription_Install_Base_Summary__c
                                                                    WHERE Account__c =: acct.Id];

        delete currentSums;
    }

    public List<SBQQ__Subscription__c> getCurrentSubs(){
        cSubs = new List<SBQQ__Subscription__c>();

        cSubs = [SELECT Id, SBQQ__Product__c, 
                    SBQQ__StartDate__c, SBQQ__EndDate__c,
                    SBQQ__Quantity__c
                    FROM SBQQ__Subscription__c
                    WHERE SBQQ__Account__c =: acct.Id];

        system.debug('Count of subscriptions is ' + cSubs.size());

        return cSubs;
    }

    public List<Id> getProds(){
        prods = new List<Id>();

        List<Id> dupsProds = new List<Id>();

        for(SBQQ__Subscription__c sub: cSubs){
            dupsProds.add(sub.SBQQ__Product__c);
        }

        Set<Id> ddProds = new Set<Id>();

        ddProds.addAll(dupsProds);

        for(Id p: ddProds){
            prods.add(p);
        }

        system.debug('Count of product IDs is ' + prods.size());

        return prods;       
    }

    public Decimal sumExistingSubs(Id pid, Date sd){
        AggregateResult[] sumValue = [SELECT SUM(SBQQ__Quantity__c) sum
                                        FROM SBQQ__Subscription__c
                                        WHERE (SBQQ__Product__c =: pid AND SBQQ__Account__c =: acct.Id
                                         AND (SBQQ__StartDate__c <=: sd AND SBQQ__EndDate__c >: sd))];

        Decimal eQty = (Decimal)sumValue[0].get('sum');

        system.debug(pid + ' has existing quantity of ' + eQty);

        return eQty;
    }

    public List<Date> dateList(List<SBQQ__Subscription__c> datedsubs){
        List<Date> subDates1 = new List<Date>();
        Set<Date> subDatesSet = new Set<Date>();
        List<Date> subDates2 = new List<Date>();

        for(SBQQ__Subscription__c s: datedsubs){
            subDates1.add(s.SBQQ__StartDate__c);
            subDates1.add(s.SBQQ__EndDate__c);
        }

        subDates1.sort();

        subDatesSet.addAll(subDates1);

        subDates2.addAll(subDatesSet);
        
        return subDates2;

    }

    public void createSummaries(){
        sibs = new List<Subscription_Install_Base_Summary__c>();

        for(Id prod: prods){
            List<Date> sibDates = new List<Date>();

            List<SBQQ__Subscription__c> pSubs = [SELECT Id, SBQQ__Product__c,
                                                    SBQQ__StartDate__c, SBQQ__EndDate__c
                                                    FROM SBQQ__Subscription__c
                                                    WHERE (SBQQ__Account__c =: acct.Id AND SBQQ__Product__c =: prod)];

            sibDates = dateList(pSubs);

            for(Integer i=0; i<sibDates.size()-1; i++){
                Subscription_Install_Base_Summary__c sib = new Subscription_Install_Base_Summary__c(Account__c = acct.id,
                                                            Product__c = prod, Effective_Start_Date__c = sibDates.get(i),
                                                            Effective_End_Date__c = sibDates.get(i+1), 
                                                            Quantity__c = sumExistingSubs(prod, sibDates.get(i)));

                sibs.add(sib); 
            }
        }

        system.debug('Count of sibs to be inserted is ' + sibs.size());
        
        insert sibs;

    }

    public void execute(Contract con){
        getContract(con.Id);
        getAccount();
        clearCurrentSummaries();
        getCurrentSubs();
        getProds();
        createSummaries();
    }
    
}