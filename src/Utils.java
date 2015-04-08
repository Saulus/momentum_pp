
import org.joda.time.LocalDate;


public final class Utils {
	public Utils() {	
		//this prevents even the native class from 
	    //calling this ctor as well :
	    throw new AssertionError();
	}

	
	public final static boolean isWeekday(LocalDate day) {
		return day.getDayOfWeek()<=5;
	}
	
	public final static LocalDate getPreviousWeekday(LocalDate day) {
		LocalDate newDate = day.minusDays(1);
		while(!isWeekday(newDate)) { newDate = newDate.minusDays(1); }
		return newDate;
	}
	
	public final static LocalDate getNextWeekday(LocalDate day) {
		LocalDate newDate = day.plusDays(1);
		while(!isWeekday(newDate)) { newDate = newDate.plusDays(1); }
		return newDate;
	}
}