import $, STD;
EXPORT shares_invest := MODULE

//***********************************************************************
//Test datasets: import and output


 //für p.long_av := 3 und p.short_av := 2
 /*
	export file_test := DATASET([
														{'A',20090101,2,2,2,2,0,2,2,2},
														{'A',20090102,3,3,3,3,0,3,2.5,2.5},
														{'A',20090103,3,3,3,3,0,3,3,2.67},
														{'A',20090104,4,4,4,4,0,4,3.5,3.33},
														{'A',20090106,2,2,2,2,0,2,2,3},
														{'A',20090107,1,1,1,1,0,1,1.5,1.5},
														{'B',20090101,1,1,1,1,0,1,1,1},
														{'B',20090102,2,2,2,2,0,2,1.5,1.5}],
															{$.shares_prices.layout,UDECIMAL8_3 short_av,UDECIMAL8_3 long_av});
																														
	importfile := DATASET([{'A',20090101,2,2,2,2,0,2},
													{'A',20090102,3,3,3,3,0,3},
													{'A',20090103,3,3,3,3,0,3},
													{'A',20090104,4,4,4,4,0,4},
													{'A',20090106,2,2,2,2,0,2},
													{'A',20090107,1,1,1,1,0,1},
													{'B',20090101,1,1,1,1,0,1},
													{'B',20090102,2,2,2,2,0,2}]
													,$.shares_prices.layout);
*/
//***********************************************************************
	//real data	 
	 importfile := $.shares_prices.file;
	 
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
		//Build Start Table mit single childset (since=today and close-value), grouped by shortcut
		T := GROUP(TABLE(importfile,R),shortcut,LOCAL);
	 
		R build_history(R le,R ri) := TRANSFORM
				SELF.val_history := (le.val_history +ri.val_history)( Since > ri.val_history[1].Since - $.p.long_av);				
				SELF := ri;
		END;	
		//Build full child data sets for each entry, with all max. needed previous values
		Built := ITERATE(SORT(T,date),build_history(LEFT,RIGHT));
		// Output(Built);

		av_layout := RECORD
				Built.shortcut;
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
		
		//2. Add strengths
		EXPORT layout := RECORD
			av_file.shortcut;
			av_file.date;
			av_file.Close;
			av_file.short_av;
			av_file.long_av;
			UDECIMAL8_3 strength := ROUND(av_file.Close / av_file.long_av,3);
			UDECIMAL8_3 strength_control := ROUND(av_file.short_av / av_file.long_av,3);
		END;
		//ungroup
		EXPORT file := GROUP(TABLE(av_file,layout)):persist('~momentum::persist::shares_invest');
END;