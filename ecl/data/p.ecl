//p for parameters
EXPORT p := MODULE
		export lastdate := '20200101';
		export lastdate_minus1 := '20191231';
		export Unsigned1 long_av := 90; //in Tagen, für den gleitenden Durchschnitt
		export Unsigned1 short_av := 35; //in Tagen, für den gleitenden Durchschnitt
		export Unsigned4 investdate := 20120306; //Datum für start des Investments
		export Unsigned4 startmoney := 5000;
		export Unsigned1 maxshares_invest := 5; //In wie viele gleichzeitig investiert
		export Unsigned1 deinvest_rank := 15; //Wann deinvestieren (nicht mehr in Top x)
		export Unsigned1 hebel := 2;
		export real trailing_stop := 20/100;
		export real bear_invest := 30/100; //invest % of money in dax short ETF in case bearish market
		export real bezugsverh := 0.1; //Bezugsverhältnis (100 Euro Aktienkurs -> 10 Euro Zertifikat)
		export real bezugsverh_bearadd := 0.1; //Zusätzliches!!! Bzugsverhältnis für Short Dax
END;
		