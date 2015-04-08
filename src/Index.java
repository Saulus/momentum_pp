import java.io.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import org.apache.http.HttpEntity;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.poi.ss.usermodel.DataFormatter;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.joda.time.LocalDate;

import au.com.bytecode.opencsv.CSVReader;

class IndexTime {
	private LocalDate startdate;
	private LocalDate enddate;
	
	public IndexTime (LocalDate startdate, LocalDate enddate) {
		this.startdate = startdate;
		this.enddate = enddate;
	}

	public LocalDate getStartdate() {
		return startdate;
	}

	public LocalDate getEnddate() {
		return enddate;
	}
	
	public void setEnddate(LocalDate day) {
		this.enddate = day;
	}
}


class ShareTime {
	private List<IndexTime> validtimes = new ArrayList<IndexTime>();
	
	public ShareTime (LocalDate validday) {
		this.addValidDay(validday);
	}
	
	public ShareTime (LocalDate startday, LocalDate endday) {
		this.addValidDay(startday);
		this.addInvalidDay(endday.plusDays(1));
	}
	
	public void addValidDay(LocalDate validday) {
		boolean alreadythere = false;
		for (IndexTime i : validtimes) {
			if (i.getStartdate().compareTo(validday)<=0 && i.getEnddate().compareTo(validday) >=0) {
				alreadythere=true;
				break;
			}
		}
		if (!alreadythere) validtimes.add(new IndexTime(validday,Consts.anEnddate));
	}
	
	public void addInvalidDay (LocalDate invalidday) {
		//get previous 1 weekday
		LocalDate newenddate = Utils.getPreviousWeekday(invalidday);
		//now look whether some validtime needs closing
		for (IndexTime i : validtimes) {
			if (i.getStartdate().compareTo(newenddate)<=0 && i.getEnddate().compareTo(newenddate) >0) {
				i.setEnddate(newenddate);
			}
		}
	}
	
	public boolean isValidOn (LocalDate mydate) {
		boolean alreadythere = false;
		for (IndexTime i : validtimes) {
			if (i.getStartdate().compareTo(mydate)<=0 && i.getEnddate().compareTo(mydate) >=0) {
				alreadythere=true;
				break;
			}
		}
		return alreadythere;
	}
	
	public String getPrintableDates() {
		String printable = "";
		for (IndexTime i : validtimes) {
			printable = printable+i.getStartdate().toString(Consts.dateFormatDE)+"-"+i.getEnddate().toString(Consts.dateFormatDE)+" ";
		}
		return printable;
	}
	
}


public class Index {
	private String name; //UpperCase, e.g. DAX
	private HashMap<Share,ShareTime> myShares = new HashMap <Share,ShareTime>();
	private AllShares allshares;
	private LocalDate lastDayProcessed = Consts.aStartdate;
	

	public Index (String name, AllShares allshares) {
		this.name=name;
		this.allshares=allshares;
	}
	
	
	/*
	 * Fileformat: no colnames, "yyyyMMdd; wkn; name"
	 * "yyyyMMdd" = Tag, an dem die Aktie im INdex war (wird genutzt, um Start- und Enddatum ggfs. anzupassen)
	 */
	public void initFromCSV (File inputcsv) throws Exception {
		CSVReader reader = new CSVReader(new FileReader(inputcsv), ';', '"');
		String[] nextline;
		LocalDate day = null;
		LocalDate lastday = null;
		Share newshare;
		List<Share> todaysShares = new ArrayList<Share>();
		while ((nextline = reader.readNext()) != null) {
			//read in day for day and put shares on pile to indicate present
			try {
				day= LocalDate.parse(nextline[0], Consts.dateFormatYearfirst);
			} catch (Exception e) {day = Utils.getNextWeekday(lastday); }
			String wkn = nextline[0].replaceAll("\\s","");
			newshare = allshares.addShare(wkn, nextline[1]);
			//either add share to index shares or simply update valid days for share
			if (!myShares.containsKey(newshare)) myShares.put(newshare, new ShareTime(day));
			else myShares.get(newshare).addValidDay(day);
			//now: test for change in dates
			if (lastday != null && day.compareTo(lastday) != 0) {
				//if change: add invalid days for all non present and reset
				for (Share s : myShares.keySet()) {
					if (!todaysShares.contains(s)) myShares.get(s).addInvalidDay(lastday);
				}
				todaysShares = new ArrayList<Share>();
			} else todaysShares.add(newshare);
			lastday = day;
			if (day.isAfter(lastDayProcessed)) lastDayProcessed = day;
		}
		reader.close();
	}
	
	/*
	 * Fileformat: colnames; "wkn; name; startdate;endate"
	 * "yyyyMMdd" = Tag, an dem die Aktie im INdex war (wird genutzt, um Start- und Enddatum ggfs. anzupassen)
	 */
	public void initFromCSVDAXonly (File inputcsv) throws Exception {
		CSVReader reader = new CSVReader(new FileReader(inputcsv), ';', '"');
		String[] nextline;
		nextline = reader.readNext();
		LocalDate startdate = null;
		LocalDate enddate = null;
		Share newshare;
		while ((nextline = reader.readNext()) != null) {
			String wkn = nextline[0].replaceAll("\\s","");
			if (!wkn.isEmpty()) {
				newshare = allshares.addShare(wkn, nextline[1]);
				
				try { startdate= LocalDate.parse(nextline[2], Consts.dateFormatDE);} catch (Exception e) {startdate = Consts.aStartdate; }
				try { enddate= LocalDate.parse(nextline[3], Consts.dateFormatDE);} catch (Exception e) {enddate = Consts.anEnddate; }
				//either add share to index shares or simply update valid days for share
				if (!myShares.containsKey(newshare)) myShares.put(newshare, new ShareTime(startdate,enddate));
				else {
					myShares.get(newshare).addValidDay(startdate);
					myShares.get(newshare).addInvalidDay(enddate.plusDays(1));
				}
				if (startdate != null && startdate.isAfter(lastDayProcessed)) lastDayProcessed = startdate;
			}
		}
		reader.close();
	}
	
	
	public void addFromWeb () {
		CloseableHttpClient httpclient = HttpClients.createDefault();
		String qurl = Consts.indexurl.replace(Consts.indexurlreplacer, this.name);
		LocalDate startdate = Utils.getNextWeekday(lastDayProcessed);
		LocalDate enddate = Utils.getPreviousWeekday(new LocalDate());
		HttpGet httpGetRequest;
		CloseableHttpResponse httpResponse = null;
		HttpEntity entity;
		InputStream inputStream;
		Workbook myWorkbook;
		Sheet mySheet;
		DataFormatter df = new DataFormatter();
		Share newshare;
		List<Share> todaysShares;
		while (startdate.compareTo(enddate)<=0) {
			//add day
			String qurldate = qurl.replace(Consts.indexurlreplacerdate, startdate.toString(Consts.dateFormatYearfirst));
			//REST API URL
			try {
				httpGetRequest = new HttpGet(qurldate);
				// Execute HTTP request
				httpResponse = httpclient.execute(httpGetRequest);
				//httpResponse.getStatusLine()
				// Get hold of the response entity
				entity = httpResponse.getEntity();

				// If the response does not enclose an entity, there is no need
				// to bother about connection release
				if (entity != null && httpResponse.getStatusLine().getStatusCode() == 200) {
					inputStream = entity.getContent();
					try {
						myWorkbook = WorkbookFactory.create(inputStream);
						mySheet = myWorkbook.getSheet("Data");

						int rowno =6;
						todaysShares = new ArrayList<Share>();
						while (mySheet.getRow(rowno).getCell(0) != null) {
							//is correct index?
							if (df.formatCellValue(mySheet.getRow(rowno).getCell(0)).replaceAll("\\s","").equals(this.name)) {
								//get wkn from col 3 (D)
								String wkn = df.formatCellValue(mySheet.getRow(rowno).getCell(3)).replaceAll("\\s","");
								String name = df.formatCellValue(mySheet.getRow(rowno).getCell(4));
								newshare = allshares.addShare(wkn, name);
								//either add share to index shares or simply update valid days for share
								if (!myShares.containsKey(newshare)) myShares.put(newshare, new ShareTime(startdate));
								else myShares.get(newshare).addValidDay(startdate);
								todaysShares.add(newshare);
							}
							rowno++;
						}
						//add invalid days for all non present 
						for (Share s : myShares.keySet()) {
							if (!todaysShares.contains(s)) myShares.get(s).addInvalidDay(startdate);
						}
					} catch (Exception e) {
						System.out.println(httpResponse.getStatusLine());
						e.printStackTrace();
					} finally {
						try { inputStream.close(); } catch (Exception ignore) {}
					}
				} 
			} catch (Exception e) {
				e.printStackTrace();
			} finally {
				try { httpResponse.close(); } catch (Exception ignore) {}
			}
			startdate = Utils.getNextWeekday(startdate);
		} //while
		try { httpclient.close(); } catch (Exception ignore) {}
	}
	
	public String[] getPrintableShares() {
		String[] printable = new String[myShares.size()];
		int i = 0;
		for (Share share : myShares.keySet()) {
			printable[i] = share.getWkn() +  ": " + myShares.get(share).getPrintableDates();
			i++;
		}
		return printable;
	}
}
