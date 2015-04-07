import java.io.File;
import java.io.FileReader;
import java.text.ParseException;
import java.util.Date;
import java.util.HashMap;

import au.com.bytecode.opencsv.CSVReader;


public class Dax {
	private HashMap<String,Share> aktien = new HashMap <String,Share>();

	/*
	 * Dax Format file: inkl. colnames = aktie_wkn	aktie	startdate	enddate
	 */
	public Dax (File inputcsv) throws Exception {
		CSVReader reader = new CSVReader(new FileReader(inputcsv), ';', '"');
		
		String [] colnames;
		if ((colnames = reader.readNext()) == null || !colnames[0].equalsIgnoreCase("aktie_wkn")) {
			reader.close();
			throw new Exception("Input-CSV nicht in richtigem Format (Spalte1=aktie_wkn)");
		}
		String[] nextline;
		Date startdate;
		Date enddate;
		Share newAktie;
		while ((nextline = reader.readNext()) != null) {
			if (!nextline[0].isEmpty()) {
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

}
