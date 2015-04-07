import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.List;

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


public class Aktie {
	private String wkn;
	private String name;
	private List<IndexTime> dates = new ArrayList<IndexTime>();
	

	public Aktie(String wkn, String name) {
		this.setWkn(wkn);
		this.setName(name);
	}


	public String getWkn() {
		return wkn;
	}


	public void setWkn(String wkn) {
		this.wkn = wkn;
	}


	public String getName() {
		return name;
	}


	public void setName(String name) {
		this.name = name;
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
