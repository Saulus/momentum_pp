import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.HashMap;
import java.util.Set;

import org.joda.time.LocalDate;

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
	private HashMap<LocalDate,Price> prices = new HashMap <LocalDate,Price>();
	

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
	
	private LocalDate maxDateOf(Set<LocalDate> dates) {
		LocalDate maxdate = Consts.aStartdate;
		for (LocalDate d : dates) {
			if (d.isAfter(maxdate)) maxdate = d;
		}
		return maxdate;
	}
	
	//Cave: Alternative WKN (with/without numbers?)
	public void getPricesHistoric () {
		String qurl = Consts.priceurl.replace(Consts.priceurlreplacer, this.wkn);;
		if (prices.size() != 0) {
			LocalDate maxdate = maxDateOf(prices.keySet());
			qurl = qurl + "&a=" + maxdate.getDayOfMonth() + "&b=" + maxdate.getMonthOfYear() + "&c=" + maxdate.getYear(); 
		};
		
		//REST API URL
		try {
			URL url = new URL(qurl);
			HttpURLConnection conn = (HttpURLConnection) url.openConnection();
			
			if (conn.getResponseCode() == 200) {
				//read as csv
				CSVReader reader = new CSVReader(new InputStreamReader(conn.getInputStream()), ',');

				String[] nextline = reader.readNext(); //header
				LocalDate day;
				Price newPrice;
				while ((nextline = reader.readNext()) != null) {
					if (!nextline[0].isEmpty()) {
						day= LocalDate.parse(nextline[0], Consts.dateFormatYahoo);
						double open = Double.parseDouble(nextline[1]);
						double high = Double.parseDouble(nextline[2]);
						double low = Double.parseDouble(nextline[3]);
						double close = Double.parseDouble(nextline[4]);
						double volume = Double.parseDouble(nextline[5]);
						double close_adj = Double.parseDouble(nextline[6]);
						newPrice = new Price(open,high,low,close,volume,close_adj);
						prices.put(day, newPrice);
					}
				}
				reader.close();
			}
		} catch (NumberFormatException | IOException e) {}
	}
	
	public void getPricesIntraday () {
		/*ToDo: query yahoo (or others) for 
			- current price
			- this days opening
			- and set: high(highest so far), low (lowest so far), close (current price)
			Cave: Opening Hours?
		*/ 
	}

}
