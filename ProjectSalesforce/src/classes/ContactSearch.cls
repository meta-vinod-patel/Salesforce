public class ContactSearch {
    public static List<Contact> searchForContacts(String in1, String in2){
        List<Contact> contactList = [SELECT Id From Contact WHERE LastName = :in1 AND MailingPostalCode = :in2 ];
        return contactList;
    }
}