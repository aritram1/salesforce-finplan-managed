trigger triggerOnInvestmentTransaction on Investment_Transaction__c (before Insert) {
    for(Investment_Transaction__c it : Trigger.new){
        if(it.FinPlan__Bond_Details__c != null){ it.Investment_Type__c = 'Bond';}
        else if(it.FinPlan__EPF_Details__c != null){ it.Investment_Type__c = 'EPF';}
        else if(it.FinPlan__FD_Details__c != null){ it.Investment_Type__c = 'FD';}
        else if(it.FinPlan__Fund_Details__c != null){ it.Investment_Type__c = 'MF';}
        else if(it.FinPlan__Metal_Investment_Details__c != null){ it.Investment_Type__c = 'Metal';}
        else if(it.FinPlan__PPF_Details__c != null){ it.Investment_Type__c = 'PPF';}
        else if(it.FinPlan__SIP_Details__c != null){ it.Investment_Type__c = 'SIP';}
        else if(it.FinPlan__SmallCase_Details__c != null){ it.Investment_Type__c = 'SmallCase';}
        else if(it.FinPlan__Stock_Details__c != null){ it.Investment_Type__c = 'Stock';}
        else if(it.FinPlan__Treasury_Bill_Details__c != null){ it.Investment_Type__c = 'TreasuryBill';}
        else if(it.FinPlan__ULIP_Details__c != null){ it.Investment_Type__c = 'ULIP';}
        else if(it.FinPlan__NPS_Details__c != null){ it.Investment_Type__c = 'NPS';}
        else { it.Investment_Type__c = 'None';}
    }
}