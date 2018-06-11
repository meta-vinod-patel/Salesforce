public class AccountUtils {
    public static List<Account> accountsByState(String state){
        List<Account> listOfAccount = new List<Account>();
        string stateAbri = '%'+state+'%';
		system.debug(stateAbri);
        listOfAccount = [Select Id,Name From Account WHERE BillingState LIKE :stateAbri];
        return listOfAccount;
    }
}