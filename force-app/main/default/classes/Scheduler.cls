// Scheduler class framework to handle all type of scheduled batch/other apex classes for Fin-Planner

public class Scheduler implements Schedulable {

    // @overridden method from SChedulable interface
    public void execute(SchedulableContext ctx) {
        RefreshInvestmentDataController.refresh();  // Refresh the Investment Data on schedule (Runs 10AM and 4PM)
    }
    
}