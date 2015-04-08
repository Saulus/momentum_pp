import org.joda.time.LocalDate;
import org.joda.time.format.DateTimeFormat;
import org.joda.time.format.DateTimeFormatter;


public final class Consts {

	public static final DateTimeFormatter dateFormatDE = DateTimeFormat.forPattern("dd.MM.YYYY");
	public static final DateTimeFormatter dateFormatYearfirst = DateTimeFormat.forPattern("YYYYMMdd");
	public static final DateTimeFormatter dateFormatYahoo = DateTimeFormat.forPattern("YYYY-MM-dd");
	public static final LocalDate anEnddate = new LocalDate(2100,12,31); //="31.12.2100";
	public static final LocalDate aStartdate = new LocalDate(2000,1,1); //="01.01.2000";
	
	public static final String priceurl = "http://ichart.finance.yahoo.com/table.csv?g=d&ignore=.csv&s=%SHARE%.DE";
	public static final String priceurlreplacer = "%SHARE%";
	
	public static final String indexurl = "http://www.dax-indices.com/MediaLibrary/Document/WeightingFiles/%INDEX%_ICR.%DATE%.xls";
	public static final String indexurlreplacer = "%INDEX%";
	public static final String indexurlreplacerdate = "%DATE%";

	
 	private Consts(){
		    //this prevents even the native class from 
		    //calling this ctor as well :
		    throw new AssertionError();
	 }

}
