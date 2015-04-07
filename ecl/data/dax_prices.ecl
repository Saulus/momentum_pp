import $, STD;
EXPORT dax_prices := MODULE

	pre_layout := RECORD
			string10 date;
			UDECIMAL7_2 Open;
			UDECIMAL7_2 High;
			UDECIMAL7_2 Low;
			UDECIMAL7_2 Close;
			Unsigned4 Volume;
			UDECIMAL7_2 Adj_Close;
	END;
	
	shared pre_file := dataset('~momentum::calc::prices_dax',pre_layout ,CSV(SEPARATOR(',')));
	
	 export layout := record
		unsigned4 date := (unsigned4) STD.Str.FilterOut(pre_File.date,'-');
		pre_file.Open;
		pre_file.High;
		pre_file.Low;
		pre_file.Close;
		pre_file.Volume;
		pre_file.Adj_Close;
	END;	
	
	export file := table(pre_File,layout);
END;