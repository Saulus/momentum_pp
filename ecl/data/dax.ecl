import $, STD;

EXPORT dax := MODULE

	//Real data
	 shared dax_import_file := $.dax_import.file;
	 
	 	export layout := record
			dax_import_file.shortcut;
			dax_import_file.share;
			Unsigned4 startdate := (Unsigned4) dax_import_file.startdate;
			Unsigned4 enddate := (Unsigned4) if(dax_import_file.enddate='',$.p.lastdate_minus1, dax_import_file.enddate);
	END;	
	
	export file := table(dax_import_file,layout):persist('~momentum::persist::dax');
END;