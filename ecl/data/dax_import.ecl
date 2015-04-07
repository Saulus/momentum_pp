import STD;

EXPORT dax_import := MODULE

 pre_layout := record
		string4 shortcut;
		string50 share;
		string10 startdate;
		string10 enddate;
	END;	

// EXPORT File := dataset('~momentum::import::index_mdax',Layout,CSV(SEPARATOR(':'),QUOTE('""')));
	shared pre_File := dataset('~momentum::import::index_dax',pre_layout,CSV(SEPARATOR(';'),QUOTE('""'),HEADING(1)));

 export layout := record
		pre_File.shortcut;
		pre_File.share;
		string8 startdate := STD.Str.FilterOut(pre_File.startdate,'-');
		string8 enddate := STD.Str.FilterOut(pre_File.enddate,'-');
	END;	
	
	export file := table(pre_File,layout);
	
END;