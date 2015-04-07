import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;


public final class Consts {

	public static final SimpleDateFormat dateFormatDE1 = new SimpleDateFormat("dd.MM.yyyy", Locale.GERMAN);
	public static final SimpleDateFormat dateFormatDE2 = new SimpleDateFormat("yyyyMMdd", Locale.GERMAN);
	public static final Date anEnddate = new Date(4133894400000L); //="31.12.2100";
	public static final Date aStartdate = new Date(946684800000L); //="01.01.2000";

	
 	private Consts(){
		    //this prevents even the native class from 
		    //calling this ctor as well :
		    throw new AssertionError();
	 }

}