import $, STD;
/*
	importfile := DATASET([{'A',20090101,2,2,2,2,0,2},
													{'A',20090102,3,3,3,3,0,3},
													{'A',20090103,3,3,3,3,0,3},
													{'A',20090104,4,4,4,4,0,4},
													{'A',20090106,2,2,2,2,0,2},
													{'A',20090107,1,1,1,1,0,1},
													{'B',20090101,4,4,4,4,0,4},
													{'C',20090101,5,5,5,5,0,5}]
													,$.shares_prices.layout);
	
	SortedPrices := SORT(importfile,Date);
	GroupedPrices := GROUP(SortedPrices,Date); 
	//Keep only Topx per Date;
	GroupedPrices_lmd := TOPN(GroupedPrices,2,-Close);
	
	output(count(GroupedPrices_lmd(Date=20090101)));*/

//test mdax
// if(not exists($.mdax.file - $.mdax.file_test),'Ok','Error');
//$.mdax.file;
// $.invest_data.layout Trans($.invest_data.layout L) :=TRANSFORM
	// self.Date:= L.Date+1;
	// self := L;
// END;
// PROJECT(TOPN($.invest_data.file(Date>=$.p.investdate-5),0,Date),Trans(LEFT));
$.invest_do.file;

// if(not exists($.prices_shares.file - $.prices_shares.file_test),'Ok','Error');
// $.shares_prices.file;
// $.shares_invest.file
//sort($.dax_invest.file,-date);
//sort($.mdax_invest.file,-date);
//$.invest_plan.file;
// $.mdax_import.file(date='20020312');
// $.mdax.file(startdate=20020312);
// $.invest_data.invest_tbl2(Date=20020312);
//$.invest_exec.SortedPrices(Date>=20140318);
//$.invest_exec.GroupedPrices(Date>=20140318);
//$.invest_exec.GroupedPrices_lmd(Date>=20140318);
//$.mdax_import.file; 

//$.shares.file;
//test dax
// $.dax_import.file;  
// $.dax.file;


