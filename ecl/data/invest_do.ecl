
import $;
EXPORT invest_do := MODULE

/* ToDo:
	PROBLEM: Re-Invest Shares (newshares( funktioniert nicht)
		test that startdate >= mindate
	  allow multiple startdates (join with invest_plan)
Transaktionskosten
Steuer
*/

//****************************************************************************
	//0. Prepare file for investment data
	//0.a kassa + bear-values (for bearish market, e.g. DAX short ETF)
	R1 := RECORD
		$.invest_data.file;
		BOOLEAN DoInvest := $.invest_data.file.mdax_strength > 1; //invest yes/no?
		DECIMAL9_2 kassa := 0;
		UNSIGNED4 quantity_bear := 0;
		DECIMAL9_2 money_invested_bear := 0;
		UDECIMAL7_2 buy_price_bear := 0;
	END;
	T1 := TABLE($.invest_data.file,R1);
	
	//0.b invested shares
	invest_rec := RECORD
		$.shares_invest.layout.shortcut;
		UNSIGNED4 quantity;
		DECIMAL9_2 money_invested;
		UDECIMAL7_2 buy_price;
		UDECIMAL7_2 highest_price;
	END;
	layout := RECORD
		R1;
		DATASET(invest_rec) invested_shares {MAXCOUNT($.p.maxshares_invest)};
	END;
	layout RestructureParent (R1 L) := transform
			self := L;
			self := [];
	END;
	prep_invest  := project(T1,RestructureParent(left));
	
	
	//****************************************************************************
	// Define Helper Functions
	//TopX mit rel. Stärke = Strength> mdax_strength, sorted descending by strength and strength_control
	GetTopX(DATASET($.shares_invest.layout) S, UDECIMAL8_3 mdax_strength, UNSIGNED4 number) := TOPN(S(S.strength >= mdax_strength,S.strength_control > 1),number,-strength,-strength_control);
	//CalcDesInvest: Calculate Money from Desinvest
		//Input: quantity, money_invested, buy_price, Current Close
		//Processing: Calculate new money
		//Output: Sum
	CalcDesinvest(UNSIGNED4 quantity, DECIMAL9_2 money_invested, UDECIMAL7_2 buy_price, UDECIMAL7_2 NewClose) := FUNCTION
			newmoney := (DECIMAL9_2) money_invested + (NewClose-buy_price)*$.p.bezugsverh*quantity*$.p.hebel;
			RETURN newmoney;
	END;	
	//CalcInvestQuantity: Calculate Quantiy used for Invest
		//Input: current money, current close 
		//Processing: calculate quantity incl. hebel
		//Output: Quantity
	CalcInvestQuantity(DECIMAL9_2 money, UDECIMAL7_2 Close) := FUNCTION
			quantity := (UNSIGNED4) TRUNCATE(money/Close/$.p.bezugsverh);
			RETURN quantity;
	END;	
	//CalcInvest: Calculate Money used for Invest
		//Input: current money, current close 
		//Processing: calculate money_invested incl. hebel
		//Output: Money
	CalcInvest(DECIMAL9_2 money, UDECIMAL7_2 Close) := FUNCTION
			newmoney := (DECIMAL9_2) CalcInvestQuantity(money,Close) *Close*$.p.bezugsverh;
			RETURN newmoney;
	END;	
	// Find Desinvest-Shares during normal operation
		//Input: All invested shares, all current shares
		//Processing: find invested shares that satisfy Trailing Stop X% or not in TopY
		// Output: invested shares to desinvest in, plus money and quantity
	DesinvestShares(DATASET(invest_rec) iS, DATASET($.shares_invest.layout) eS)  := FUNCTION
				full_iS := JOIN(iS,eS,LEFT.shortcut = RIGHT.shortcut);
	
				BothRules  := full_iS(
								Close < (highest_price-(highest_price*$.p.trailing_stop)) //trailing stop
								OR
								shortcut NOT IN SET(TOPN(eS,$.p.deinvest_rank,-strength,-strength_control),shortcut) // Not in TopY
				);
				
				sharesrec := RECORD
							full_iS.shortcut;
							full_iS.quantity;
							full_iS.money_invested;
							full_iS.buy_price;
							full_iS.highest_price;
				END;
				BothRules_tbl := TABLE(BothRules,sharesrec);
				return BothRules_tbl ;
	END;
	// Return-Money for Desinvest-Shares 
		//Input: invested shares to be desinvested, all current shares
		//Processing: join, then calculate money sum incl. hebel
		//Output: Sum
	DesinvestSharesMoney (DATASET(invest_rec) iS, DATASET($.shares_invest.layout) eS)  := FUNCTION
				full_iS := JOIN(iS,eS,LEFT.shortcut = RIGHT.shortcut);
				mymoney := (DECIMAL9_2) SUM(full_iS,CalcDesinvest(quantity,money_invested,buy_price,Close));
			return mymoney;
	END;
	
	//New invest-shares: 
		// Input: all current shares, mdax_strength, number to invest in (should be: MAX - CurrentInvest# + Desinvest#), current kassa-money
		//PRocessing: GetTopX, change record to invest_rec, calculate Quantity and money_invested incl. hebel
		// Output: new invested shares dataset
	NewInvestShares (DATASET($.shares_invest.layout) eS, UDECIMAL8_3 mdax_strength, UNSIGNED4 number, DECIMAL9_2 money) := FUNCTION
			newshares := GetTopX(eS,mdax_strength,number);
			invest_rec FormatNewshares($.shares_invest.layout L) := TRANSFORM
				self.shortcut := L.shortcut;
				self.quantity := CalcInvestQuantity(money / number,L.Close);
				self.money_invested := CalcInvest(money / number,L.Close);
				self.buy_price := L.Close;
				self.highest_price := L.Close;
			END;
			newshares_tbl := PROJECT(newshares,FormatNewshares(LEFT));
			return newshares_tbl;
	END;		
	//Update Shares with highest price (for trailing stop)
		//Input: All invested shares, all current shares
		//Processing:join both datasets with transform to invest_rec (set new highest_price)
		//Output: invested_shares update
	UpdateInvestedShares (DATASET(invest_rec) iS, DATASET($.shares_invest.layout) eS)  := FUNCTION
			invest_rec ProcessInvestment (invest_rec L, $.shares_invest.layout R ) := transform
					self.highest_price := MAX(L.highest_price,R.Close);
					self := L;
			END;
			full_iS := JOIN(iS,eS,LEFT.shortcut = RIGHT.shortcut,ProcessInvestment(LEFT,RIGHT));
			return full_iS;
	END;
	//BearishMarketInvest: Invest e.g. in DAX ETF 
		//Input: bear_invest% of current kassa-money, Current Close
		//Processing: Invest bear_invest% of money in Dax (or similar), incl. hebel
		//Return: recordset with quantity_bear, money_invested_bear, buy_price_bear;
	BearishMarketInvest(DECIMAL9_2 money, UDECIMAL7_2 Close) := FUNCTION
		MyRec := RECORD
			UNSIGNED4 quantity_bear;
			DECIMAL9_2 money_invested_bear;
		END;
		MyDataset := DATASET([{CalcInvestQuantity(money,Close*$.p.bezugsverh_bearadd),CalcInvest(money,Close*$.p.bezugsverh_bearadd)}],MyRec);
		return MyDataset;
	END;
	
	//****************************************************************************
	//**** some Sum functions for crunching through *****************************
	//Invest follows after Invest
	CalcKassa_Invest2Invest (layout L, layout R) := FUNCTION
		DeShares := DesinvestShares(L.invested_shares,R.shares);
		KeepSharesNum := count(L.invested_shares)-count(DeShares);
		DeSharesMoney := DesinvestSharesMoney(DeShares,R.shares);
		NewShares := NewInvestShares(R.shares,R.mdax_strength,
													$.p.maxshares_invest-KeepSharesNum, //find quantity to invest in
													L.Kassa + DeSharesMoney //calculate money for investments
											);
		NewSharesMoney := SUM(NewShares,money_invested);  				//Money spent for new Investments
		newkassa := L.kassa 
									+ DeSharesMoney //Money from Deinvestments
									- NewSharesMoney;
		return newkassa;
	END;
	//Invest follows after Desinvest
	CalcKassa_Desinvest2Invest (layout L, layout R) := FUNCTION
		BearDesinvestMoney := CalcDesinvest(L.quantity_bear,L.money_invested_bear,-L.buy_price_bear*$.p.bezugsverh_bearadd,-R.dax_close*$.p.bezugsverh_bearadd); 
																	//Money from Bear-desinvest (AChtung: Short und Bezugsverhältnis)
		NewShares := NewInvestShares(R.shares,R.mdax_strength,
													$.p.maxshares_invest, //find quantity to invest in
													L.Kassa + BearDesinvestMoney //calculate money for investments
											);
		NewSharesMoney := SUM(NewShares,money_invested);  				//Money spent for new Investments
		newkassa := L.kassa
									+ BearDesinvestMoney 
									- NewSharesMoney;
		return newkassa;
	END;
	//Desinvest follows after Invest
	CalcKassa_Invest2Desinvest (layout L, layout R) := FUNCTION
		DeSharesMoney := DesinvestSharesMoney(L.invested_shares,R.shares); 
		BearInvestMoney := BearishMarketInvest((L.kassa+DeSharesMoney )*$.p.bear_invest,R.dax_close)[1].money_invested_bear;	//Money spent for Bearish Investments (Dax ETF)
			
		newkassa := L.kassa
									+ DeSharesMoney //Money from Deinvestments
									- BearInvestMoney;
		return newkassa;
	END;
	//Invest follows after Invest
	CalcShares_Invest2Invest (layout L, layout R) := FUNCTION
		DeShares := DesinvestShares(L.invested_shares,R.shares);
		UpdatedShares := UpdateInvestedShares(L.invested_shares-DeShares,R.shares);
		KeepSharesNum := count(UpdatedShares);
		DeSharesMoney := DesinvestSharesMoney(DeShares,R.shares);
		newshares := 	UpdatedShares 
										+ NewInvestShares(R.shares,R.mdax_strength,
												$.p.maxshares_invest-KeepSharesNum, //find quantity to invest in
													L.Kassa +DeSharesMoney //calculate money for investments
										);
		return newshares;
	END;
		//Invest follows after Desinvest
	CalcShares_Desinvest2Invest (layout L, layout R) := FUNCTION
		BearDesinvestMoney := CalcDesinvest(L.quantity_bear,L.money_invested_bear,-L.buy_price_bear*$.p.bezugsverh_bearadd,-R.dax_close*$.p.bezugsverh_bearadd); 
																	//Money from Bear-desinvest (AChtung: Short und Bezugsverhältnis)
		newshares := NewInvestShares(R.shares,R.mdax_strength,
													$.p.maxshares_invest, //find quantity to invest in
													L.Kassa + BearDesinvestMoney //calculate money for investments
									);
		return newshares;
	END;
	
	
	//****************************************************************************
	// Crunch through Investments using functions only, starting with startdate
	layout DoInvest (layout L, layout R, UNSIGNED4 c) := transform
		StartInvestShares := NewInvestShares(R.shares,R.mdax_strength,$.p.maxshares_invest,$.p.startmoney);
		StartBearInvest := BearishMarketInvest($.p.startmoney*$.p.bear_invest,R.dax_close)[1];	//Money spent for Bearish Investments (Dax ETF)		
		DeSharesMoney := DesinvestSharesMoney(L.invested_shares,R.shares);
		BearInvest := BearishMarketInvest((L.kassa+DeSharesMoney)*$.p.bear_invest,R.dax_close)[1];
		
		self.kassa := MAP(
										c=1 and R.DoInvest => $.p.startmoney-SUM(StartInvestShares,money_invested),
										c=1 and not R.DoInvest => $.p.startmoney-StartBearInvest.money_invested_bear,
										L.DoInvest and R.DoInvest => CalcKassa_Invest2Invest(L,R),
										not L.DoInvest and R.DoInvest => CalcKassa_Desinvest2Invest(L,R),
										L.DoInvest and not R.DoInvest => CalcKassa_Invest2Desinvest(L,R),
										L.Kassa);		
		self.invested_shares := MAP(
										c=1 and R.DoInvest => StartInvestShares,
										c=1 and not R.DoInvest => R.invested_shares, //= empty
										L.DoInvest and R.DoInvest => CalcShares_Invest2Invest(L,R),
										not L.DoInvest and R.DoInvest => CalcShares_Desinvest2Invest(L,R),
										L.DoInvest and not R.DoInvest => R.invested_shares, //= empty
										L.invested_shares);		
		self.quantity_bear := MAP(
										c=1 and R.DoInvest => 0,
										c=1 and not R.DoInvest => StartBearInvest.quantity_bear,
										L.DoInvest and R.DoInvest => L.quantity_bear,
										not L.DoInvest and R.DoInvest => 0,
										L.DoInvest and not R.DoInvest =>  BearInvest.quantity_bear,
										L.quantity_bear);		
		self.money_invested_bear := MAP(
										c=1 and R.DoInvest => 0,
										c=1 and not R.DoInvest => StartBearInvest.money_invested_bear,
										L.DoInvest and R.DoInvest => L.money_invested_bear,
										not L.DoInvest and R.DoInvest => 0,
										L.DoInvest and not R.DoInvest =>  BearInvest.money_invested_bear,
										L.money_invested_bear);		
		self.buy_price_bear := MAP(
										c=1 and R.DoInvest => 0,
										c=1 and not R.DoInvest => R.dax_close,
										L.DoInvest and R.DoInvest => L.buy_price_bear,
										not L.DoInvest and R.DoInvest => 0,
										L.DoInvest and not R.DoInvest => R.dax_close,
										L.buy_price_bear);		
		self := R;
	END;
	invest_do_file:=ITERATE(prep_invest(Date>=$.p.investdate),DoInvest(LEFT,RIGHT, COUNTER)):persist('~momentum::persist::invest_do');

	//****************************************************************************
	//STatistics 
	stats_rec := RECORD
			invest_do_file;
			DECIMAL9_2 current_value := 0;
			DECIMAL5_2 change_1d := 0;
			DECIMAL5_2 change_all := 0;
	END;
	
	stats_tbl := TABLE(invest_do_file, stats_rec);
	//****************************************************************************
	// ADD Stats
	stats_rec AddStats (stats_rec L, stats_rec R) := TRANSFORM
		BearDesinvestMoney := CalcDesinvest(R.quantity_bear,R.money_invested_bear,-R.buy_price_bear*$.p.bezugsverh_bearadd,-R.dax_close*$.p.bezugsverh_bearadd); 
																	//Money from Bear-desinvest (AChtung: Short und Bezugsverhältnis)
		DeSharesMoney := DesinvestSharesMoney(R.invested_shares,R.shares); 
		SELF.current_value := R.kassa + BearDesinvestMoney + DeSharesMoney;
		SELF.change_1d := ROUND((R.kassa + BearDesinvestMoney + DeSharesMoney)*100/L.current_value,2)-100;
		SELF.change_all := ROUND((R.kassa + BearDesinvestMoney + DeSharesMoney)*100/$.p.startmoney,2)-100;
		SELF := R;
	END;
		
	export file := ITERATE(stats_tbl,AddStats(LEFT,RIGHT)):persist('~momentum::persist::invest_stats');
	
END;