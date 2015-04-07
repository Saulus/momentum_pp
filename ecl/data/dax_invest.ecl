import $, STD;
EXPORT dax_invest := MODULE

	//real data	 
	 importfile := $.dax_prices.file;
	 
	 //1. attach averages
		H := RECORD
			Unsigned4 Since;
			UDECIMAL7_2 Close;
		END;

		R := RECORD
			importfile;
			Unsigned4 today := STD.Date.FromGregorianDate(importfile.date);
			DATASET(H) val_history := DATASET([{STD.Date.FromGregorianDate(importfile.date),importfile.Close}],H);	
		END;	
		//Build Start Table mit single childset (since=today and close-value)
		T := TABLE(importfile,R);
	 
		R build_history(R le,R ri) := TRANSFORM
				SELF.val_history := (le.val_history +ri.val_history)( Since > ri.val_history[1].Since - $.p.long_av);				
				SELF := ri;
		END;	
		//Build full child data sets for each entry, with all max. needed previous values
		Built := ITERATE(SORT(T,date),build_history(LEFT,RIGHT));
		// Output(Built);

		av_layout := RECORD
				Built.date;
				Built.Open;
				Built.High;
			  Built.Low;
				Built.Close;
				Built.Volume;
				Built.Adj_Close;
				UDECIMAL8_3 short_av := ROUND(AVE(Built.val_history(Since>Built.Today-$.p.short_av),Close),3);
				UDECIMAL8_3 long_av := ROUND(AVE(Built.val_history(Since>Built.Today-$.p.long_av),Close),3);
			END;
		SHARED av_file := TABLE(Built,av_layout);	 
		
		EXPORT layout := RECORD
			av_file.date;
			av_file.Close;
			av_file.short_av;
			av_file.long_av;
			UDECIMAL8_3 strength := ROUND(av_file.Close / av_file.long_av,3);
			UDECIMAL8_3 strength_control := ROUND(av_file.short_av / av_file.long_av,3);
		END;
		EXPORT file := TABLE(av_file,layout):persist('~momentum::persist::dax_invest');
END;