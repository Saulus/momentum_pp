import java.io.File;
import java.io.FileReader;
import java.text.ParseException;
import java.util.Date;
import java.util.HashMap;

import au.com.bytecode.opencsv.CSVReader;


public class Index {
	protected HashMap<String,Aktie> aktien = new HashMap <String,Aktie>();

	/*
	 * Fileformat: no colnames, "yyyyMMdd; wkn; name"
	 * "yyyyMMdd" = Tag, an dem die Aktie im INdex war (wird genutzt, um Start- und Enddatum ggfs. anzupassen)
	 */
	public Index (File inputcsv) throws Exception {
		CSVReader reader = new CSVReader(new FileReader(inputcsv), ';', '"');
		
		String[] nextline;
		Date startdate;
		Date enddate;
		Aktie newAktie;
		while ((nextline = reader.readNext()) != null) {
			if (!nextline[1].isEmpty()) {
				try { startdate= Consts.dateFormatDE.parse(nextline[2]); } catch (ParseException e) { startdate=Consts.aStartdate; }
				try { enddate= Consts.dateFormatDE.parse(nextline[3]); } catch (ParseException e) { enddate=Consts.anEnddate; }
				String wkn = nextline[0].replaceAll("\\s","");
				newAktie = new Aktie(wkn,nextline[1],startdate,enddate);
				aktien.put(wkn,newAktie);
			}
		}
		reader.close();
		//make Uppercase
	}

}
