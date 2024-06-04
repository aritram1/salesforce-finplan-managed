// Scheduler class framework to handle all type of scheduled batch/other apex classes for Fin-Planner

public class Scheduler implements Schedulable {

    // @overridden method from SChedulable interface
    public void execute(SchedulableContext ctx) {

        // Delete the logs everyday
        List<FinPlan__System_Log__c> logs = [SELECT id from FinPlan__System_Log__c];
        delete logs;
        if(logs.size() > 0) Database.emptyRecycleBin(logs);
        
        // To be uncommented later
        // Refresh the Investment Data on schedule (Runs 10AM and 4PM)
        // RefreshInvestmentDataController.refresh();
    }
    
}