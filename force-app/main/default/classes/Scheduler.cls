public class Scheduler implements Schedulable {
    
    public void execute(SchedulableContext ctx) {
        // Refresh the Investment Data on schedule
        RefreshInvestmentDataController.refresh();
    }

}
