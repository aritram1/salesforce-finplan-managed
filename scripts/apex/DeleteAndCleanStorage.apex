// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the apex text and running the command:
// - SFDX: Execute Anonymous Apex with Currently Selected Text
// - SFDX: Execute Anonymous Apex with Editor Contents (execute the entire file by running the command)

////////////////////////////////////////////////////////////////////////////////////////////

// Script to delete existing records and clean up storage

List<SMS_Message__c> messagesToDelete = [SELECT Id FROM SMS_Message__c];
Database.DeleteResult[] deleteResults1 = Database.delete(messagesToDelete, false);
if(messagesToDelete.size() > 0) Database.emptyRecycleBin(messagesToDelete);

List<FinPlan__Bank_Transaction__c> bankTxntoDelete = [SELECT Id FROM FinPlan__Bank_Transaction__c];
Database.DeleteResult[] deleteResults2 = Database.delete(bankTxntoDelete, false);
if(bankTxntoDelete.size() > 0) Database.emptyRecycleBin(bankTxntoDelete); 

List<FinPlan__Investment_Transaction__c> invTxntoDelete = [SELECT Id FROM FinPlan__Investment_Transaction__c];
Database.DeleteResult[] deleteResults3 = Database.delete(invTxntoDelete, false);
if(invTxntoDelete.size() > 0) Database.emptyRecycleBin(invTxntoDelete);

List<Campaign> campaigns = [SELECT id from Campaign];
delete campaigns;
if(campaigns.size() > 0) Database.emptyRecycleBin(campaigns);

List<Lead> leads = [SELECT id from Lead];
delete leads;
if(leads.size() > 0) Database.emptyRecycleBin(leads);

List<Case> cases = [SELECT id from Case];
delete cases;
if(cases.size() > 0) Database.emptyRecycleBin(cases);

List<Opportunity> opps = [SELECT id from Opportunity];
delete opps;
if(opps.size() > 0) Database.emptyRecycleBin(opps);

List<Entitlement> entitlements = [SELECT id from Entitlement];
delete entitlements;
if(entitlements.size() > 0) Database.emptyRecycleBin(entitlements);

List<Account> accounts = [SELECT id from Account];
delete accounts;
if(accounts.size() > 0) Database.emptyRecycleBin(accounts);

List<FinPlan__Savings_Account_Transaction__c> sa_txns = [SELECT id from FinPlan__Savings_Account_Transaction__c];
delete sa_txns;
if(sa_txns.size() > 0) Database.emptyRecycleBin(sa_txns);

List<FinPlan__Savings_Account_Transaction_Email__c> sa_txn_emails = [SELECT id from FinPlan__Savings_Account_Transaction_Email__c];
delete sa_txn_emails;
if(sa_txn_emails.size() > 0) Database.emptyRecycleBin(sa_txn_emails);

List<FinPlan__System_Log__c> logs = [SELECT id from FinPlan__System_Log__c];
delete logs;
if(logs.size() > 0) Database.emptyRecycleBin(logs);