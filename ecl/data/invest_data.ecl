import $;

//module prepare all data for investment decision / roll-through
EXPORT invest_data := MODULE

	//Use min Date from MDAX file 
	MinDate := MIN($.mdax.file,startdate);
	
	//******************************************************************
	//0. Get MDAX-Price-Data and strength, starting from MinDate
	R1 := RECORD
		$.mdax_invest.file.date;
		mdax_close := $.mdax_invest.file.close;
		mdax_strength := $.mdax_invest.file.strength;
	END;
	MdaxInvest := TABLE($.mdax_invest.file(Date>=MinDate),R1);
	
	//****************************************************************
	//1. Add all valid MDAX_Shares, grouped per Date
	//1.a Only valid shares
	$.shares_invest.layout KeepSharesOnly ($.shares_invest.layout L, $.mdax.layout R ) := transform
			self := L;
	END;
	ValidPrices := join($.shares_invest.file(Date>=MinDate),$.mdax.file,LEFT.shortcut=RIGHT.shortcut and LEFT.Date between RIGHT.startdate and RIGHT.enddate,KeepSharesOnly(LEFT,RIGHT));
	//1b. Sort and Group share prices by date
	SortedPrices := SORT(ValidPrices,Date,-strength,-strength_control);
	GroupedPrices := GROUP(SortedPrices,Date); 
	//Keep only Topx per Date;
	// GroupedPrices_lmd := TOPN(GroupedPrices,$.p.deinvest_rank,-strength,-strength_control);
	
	
	//********************************************************
	//2. add shares per investment date
	//2a; change parent = MdaxInvest structure.
	R2 := RECORD
		MdaxInvest;
		DATASET($.shares_invest.layout) shares {MAXCOUNT(70)};
	END;
	R2 RestructureParent (MdaxInvest L) := transform
			self := L;
			self := [];
	END;
	MdaxInvestChilds := project(MdaxInvest,RestructureParent(left));
	//2b add shares 
	R2 DenormalizeThem (R2 L,DATASET($.shares_invest.layout) R) := transform
			self.shares := R;
			self := L;
	END;
	SHARED MdaxInvestShares := denormalize(MdaxInvestChilds,GroupedPrices,Left.Date = right.Date,GROUP,DenormalizeThem(left,ROWS(RIGHT)));
	
	
	//********************************************************
	//3. add dax investment
	export layout := RECORD
		MdaxInvestShares;
		UDECIMAL7_2 dax_close;
		UDECIMAL8_3 dax_strength;
	END;
	layout JoinThem (MdaxInvestShares L, $.dax_invest.layout R) := transform
			SELF.dax_close := R.close;
			SELF.dax_strength := R.strength;
			self := L;
	END;
	export file := JOIN(MdaxInvestShares,$.dax_invest.file,LEFT.date = RIGHT.date,JoinThem(LEFT,RIGHT),LEFT OUTER):persist('~momentum::persist::invest_data');
	
	
END;