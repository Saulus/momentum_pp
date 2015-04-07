import $,STD;

// Date,Open,High,Low,Close,Volume,Adj Close
// 2014-03-14,112.80,113.20,112.75,112.75,8000,112.75


myrec := RECORD
	string10 date;
	real4 Open;
	real4 High;
	real4 Low;
	real4 Close;
	Unsigned4 Volume;
	real4 Adj_Close;
END;

//1. Get Dax Prices
 // dax_p := PIPE('/home/hpccdemo/wget_shares.sh %5EGDAXI', myrec,CSV(SEPARATOR(',')));
 // output(dax_p,,'~momentum::calc::prices_dax',CSV(SEPARATOR(',')),overwrite);
//2. Get Mdax Prices
 // mdax_p := PIPE('/home/hpccdemo/wget_shares.sh %5EMDAXI', myrec,CSV(SEPARATOR(','))); 
 // output(mdax_p,,'~momentum::calc::prices_mdax',CSV(SEPARATOR(',')),overwrite);

//3. Get mdax share prices
	//3.a get all mdax shares ever
		Shares := RECORD
			$.mdax.file.shortcut;
		END;
		allshares := dedup(sort(table($.mdax.file,Shares),shortcut),shortcut);
		//allshares := DATASET([{'AFI'},{'AMB2'}],Shares); //TEST

	//3.b get prices for all shares with PIPE, use different exchanges
		Shares_p  := RECORD
			$.mdax.layout.shortcut;
			DATASET(myrec) prices_DE {MAXCOUNT(18000)}; //app. 50 years
			DATASET(myrec) prices_F {MAXCOUNT(18000)}; //app. 50 years
			DATASET(myrec) prices_MU {MAXCOUNT(18000)}; //app. 50 years
			DATASET(myrec) prices_BE {MAXCOUNT(18000)}; //app. 50 years
		END;
		Shares_p Get_allshares_prices(Shares s)  := transform 
			self.shortcut := s.shortcut;
			self.prices_DE := PIPE('/home/hpccdemo/wget_shares.sh '+STD.Str.CleanSpaces(s.shortcut)+'.DE', myrec,CSV(SEPARATOR(',')));
			self.prices_F := PIPE('/home/hpccdemo/wget_shares.sh '+STD.Str.CleanSpaces(s.shortcut)+'.F', myrec,CSV(SEPARATOR(',')));
			self.prices_MU := PIPE('/home/hpccdemo/wget_shares.sh '+STD.Str.CleanSpaces(s.shortcut)+'.MU', myrec,CSV(SEPARATOR(',')));
			self.prices_BE := PIPE('/home/hpccdemo/wget_shares.sh '+STD.Str.CleanSpaces(s.shortcut)+'.BE', myrec,CSV(SEPARATOR(',')));
		END;
		allshares_p := PROJECT(allshares, Get_allshares_prices(LEFT));

		
	//3.c reformat: normalize as shortcut,row, then dedup
	//normalize separately for all exchanges, then add up, and dedup
		Shares_p_part := RECORD
			$.mdax.layout.shortcut;
			DATASET(myrec) prices {MAXCOUNT(18000)}; //app. 50 years
		END;
		Shares_p_norm  := RECORD
			$.mdax.layout.shortcut;
			string3 exchange;
			myrec;
		END;
		Shares_p_norm NormIt(Shares_p_part L, INTEGER C, STRING3 ex) := TRANSFORM
			SELF.shortcut := L.shortcut;
			SELF.exchange := ex;
			SELF := L.prices[c];
		END;
		allshares_p_DE := NORMALIZE(table(allshares_p,{allshares_p.shortcut,prices := allshares_p.prices_DE}),count(LEFT.prices),NormIt(LEFT,COUNTER,'1DE'));
		allshares_p_F := NORMALIZE(table(allshares_p,{allshares_p.shortcut,prices := allshares_p.prices_F}),count(LEFT.prices),NormIt(LEFT,COUNTER,'2F'));
		allshares_p_MU := NORMALIZE(table(allshares_p,{allshares_p.shortcut,prices := allshares_p.prices_MU}),count(LEFT.prices),NormIt(LEFT,COUNTER,'3MU'));
		allshares_p_BE := NORMALIZE(table(allshares_p,{allshares_p.shortcut,prices := allshares_p.prices_BE}),count(LEFT.prices),NormIt(LEFT,COUNTER,'4BE'));
		
		allshares_p_final := dedup(
					sort(allshares_p_DE+allshares_p_F+allshares_p_MU+allshares_p_BE,shortcut,Date,exchange),
					LEFT.shortcut = RIGHT.shortcut and LEFT.Date = RIGHT.Date);
		//Keep only shares with korrekt Date
		output(allshares_p_final(NOT Date='N/A'),,'~momentum::calc::prices_shares',CSV(SEPARATOR(',')),overwrite);
		
		//3.d find all shares with unknown shortcuts
		unknown_layout := RECORD
			allshares_p_final.shortcut;
		END;
		allshares_unknown := table(allshares_p_final(Date='N/A'),unknown_layout) - table(allshares_p_final(NOT Date='N/A'),unknown_layout);
	
	unknown_layout_ext := RECORD
		$.mdax.file.shortcut;
		$.mdax.file.share;
	END;
	allshares_unknown_ext := JOIN(allshares_unknown ,dedup(sort(table($.mdax.file,unknown_layout_ext),shortcut),shortcut),LEFT.shortcut=RIGHT.shortcut);
	
	output(allshares_unknown_ext ,,'~momentum::calc::shares_unknown',CSV(SEPARATOR(',')),overwrite);