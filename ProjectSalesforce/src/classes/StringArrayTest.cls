public class StringArrayTest {
    public Static List<String> generateStringArray(Integer input){
      	List<String> test = new List<String>();
        for(Integer i=0;i<input;i++){
            test.add('Test '+i);
        }
        return test;
    }
}