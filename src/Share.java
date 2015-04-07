import java.io.FileReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.text.ParseException;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.Set;

import au.com.bytecode.opencsv.CSVReader;

/*
 * Die gelieferten Kursdaten sind in einer besonderen Art Split- und Dividenden-bereinigt.
 * Neben den Spalten Date, Open, High, Low, Close und Volume wird die Spalte Adjusted Close mitgeliefert.
 * Hierin versteckt sich der nach Split- und Dividenden bereinigte Schlusskurs des jeweiligen Wertpapiers vom jeweiligen Tag, Monat etc. 
 * Möchte man mit den Daten eine komplett bereinigte Kurshistorie erzeugen, müssen alle Spalten vorher über die Werte der Spalte 
 * Adjusted Close neu berechnet werden. Eigentlich eine sehr praktische Art, die Split- und Dividendeninformationen unterzubringen. 
 * Somit muss man diese nicht separat laden und daraufhin die Kursreihen anpassen. Die Ermittlung der angepassten Kurswerte je Zeile 
 * erfolgt ganz einfach über folgende Formel: 

 nOpen_Adj = nOpen * nAdjusted_Close / nClose 

 Der Wert nOpen_Adj ergibt den bereinigten Eröffnungskurs, nOpen und nClose sind die vorhandenen unbereinigten Eröffnungs- bzw. Schlusskurse und nAdjusted_Close der vorhandene bereinigte Schlusskurs. Für den jeweiligen Höchstkurs würde die Formel wie folgt lauten: 

 nHigh_Adj = nHigh * nAdjusted_Close / nClose 
 */
class Price {
	public double openAdj = 0;
	public double highAdj = 0;
	public double lowAdj = 0;
	public double closeAdj = 0;
	public double volume = 0;
	
	public Price (double open, double high, double low, double close, double volume, double adj_close) {
		this.openAdj = open*adj_close/close;
		this.highAdj = high*adj_close/close;
		this.lowAdj = low*adj_close/close;
		this.closeAdj = adj_close;
		this.volume = volume;
	}
}


public class Share {
	private String wkn;
	private String name;
	private HashMap<Date,Price> prices = new HashMap <Date,Price>();
	

	public Share(String wkn, String name) {
		this.wkn=wkn;
		this.name=name;
	}


	public String getWkn() {
		return wkn;
	}

	public String getName() {
		return name;
	}
	
	private Date getMaxDate (Set<Date> dates) {
		Date maxdate = new Date(0);
		for (Date d : dates) {
			if (d.compareTo(maxdate) > 0) maxdate = d;
		}
		return maxdate;
	}
	
	public void getLatestKurse () {
		String qurl = Consts.priceurl + this.wkn + Consts.wknsuffix;;
		if (prices.size() != 0) {
			Calendar cal = Calendar.getInstance();
			cal.setTime(getMaxDate(prices.keySet()));
			qurl = qurl + "&a=" + cal.get(Calendar.DATE) + "&b=" + cal.get(Calendar.MONTH) + "&c=" + cal.get(Calendar.YEAR); 
		};
		
		//REST API URL
		try {
			URL url = new URL(qurl);
			HttpURLConnection conn = (HttpURLConnection) url.openConnection();
			
			if (conn.getResponseCode() == 200) {
				//read as csv
				CSVReader reader = new CSVReader(new InputStreamReader(conn.getInputStream()), ',');

				String[] nextline = reader.readNext(); //header
				Date day;
				Price newPrice;
				while ((nextline = reader.readNext()) != null) {
					if (!nextline[0].isEmpty()) {
						try {
							day= Consts.dateFormatYahoo.parse(nextline[0]);
							double open = Double.parseDouble(nextline[1]);
							double high = Double.parseDouble(nextline[2]);
							double low = Double.parseDouble(nextline[3]);
							double close = Double.parseDouble(nextline[4]);
							double volume = Double.parseDouble(nextline[5]);
							double close_adj = Double.parseDouble(nextline[6]);
							newPrice = new Price(open,high,low,close,volume,close_adj);
							prices.put(day, newPrice);
						} catch (ParseException e) { }
					}
				}
				reader.close();
			}
		} catch (NumberFormatException | IOException e) {}
	}
	
	

}
