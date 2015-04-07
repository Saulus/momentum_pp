import $;

EXPORT invest_plan := MODULE

	export layout := RECORD
		$.mdax_invest.file.date;
		mdax_close := $.mdax_invest.file.close;
		mdax_strength := $.mdax_invest.file.strength;
		BOOLEAN do_invest := $.mdax_invest.file.strength > 1;
	END;
	 export file := TABLE($.mdax_invest.file(Date>=$.p.investdate),layout);
END;
		