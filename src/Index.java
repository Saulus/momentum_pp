import java.io.File;
import java.io.FileReader;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.List;

import au.com.bytecode.opencsv.CSVReader;

class IndexTime {
	private Date startdate;
	private Date enddate;
	
	public IndexTime (Date startdate, Date enddate) {
		this.setStartdate(startdate);
		this.setEnddate(enddate);
	}

	public Date getStartdate() {
		return startdate;
	}

	public void setStartdate(Date startdate) {
		this.startdate = startdate;
	}

	public Date getEnddate() {
		return enddate;
	}

	public void setEnddate(Date enddate) {
		this.enddate = enddate;
	}
}

public class Index {
	protected HashMap<String,Share> aktien = new HashMap <String,Share>();
	private List<IndexTime> dates = new ArrayList<IndexTime>();

	/*
	 * Fileformat: no colnames, "yyyyMMdd; wkn; name"
	 * "yyyyMMdd" = Tag, an dem die Aktie im INdex war (wird genutzt, um Start- und Enddatum ggfs. anzupassen)
	 */
	public Index (File inputcsv) throws Exception {
		CSVReader reader = new CSVReader(new FileReader(inputcsv), ';', '"');
		
		String[] nextline;
		Date startdate;
		Date enddate;
		Share newAktie;
		while ((nextline = reader.readNext()) != null) {
			if (!nextline[1].isEmpty()) {
				try { startdate= Consts.dateFormatDE.parse(nextline[2]); } catch (ParseException e) { startdate=Consts.aStartdate; }
				try { enddate= Consts.dateFormatDE.parse(nextline[3]); } catch (ParseException e) { enddate=Consts.anEnddate; }
				String wkn = nextline[0].replaceAll("\\s","");
				newAktie = new Share(wkn,nextline[1],startdate,enddate);
				aktien.put(wkn,newAktie);
			}
		}
		reader.close();
		//make Uppercase
	}
	
	public void addValidDay(Date startdate) {
		boolean alreadythere = false;
		for (IndexTime i : dates) {
			if (i.getStartdate().compareTo(startdate)<=0 && i.getEnddate().compareTo(startdate) >=0) {
				alreadythere=true;
				break;
			}
		}
		if (!alreadythere) dates.add(new IndexTime(startdate,Consts.anEnddate));
	}
	
	public void addInvalidDay (Date enddate) {
		//subtract 1 weekday
		Calendar cal = Calendar.getInstance();
		cal.setTime(enddate);
		boolean isweekday = false;
		do {
			 cal.add(Calendar.DATE, -1);
			 isweekday = cal.get(Calendar.DAY_OF_WEEK) != Calendar.SATURDAY && cal.get(Calendar.DAY_OF_WEEK) != Calendar.SUNDAY;
	      } while(!isweekday);
		Date newenddate = cal.getTime();
		//now look whether some indextime needs closing
		for (IndexTime i : dates) {
			if (i.getStartdate().compareTo(newenddate)<=0 && i.getEnddate().compareTo(newenddate) >0) {
				i.setEnddate(newenddate);
			}
		}
	}
	
	public boolean isValidOn (Date mydate) {
		boolean alreadythere = false;
		for (IndexTime i : dates) {
			if (i.getStartdate().compareTo(mydate)<=0 && i.getEnddate().compareTo(mydate) >=0) {
				alreadythere=true;
				break;
			}
		}
		return alreadythere;
	}

}
