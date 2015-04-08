import java.util.HashMap;


public class AllShares {
	private HashMap<String,Share> shares = new HashMap <String,Share>();

	public AllShares() {
		
	}
	
	
	public Share addShare (String wkn, String name) {
		if (!shares.containsKey(wkn)) {
			Share newshare = new Share(wkn,name);
			shares.put(wkn, newshare);
		}
		return shares.get(wkn);
	}
	
	public Share getShare (String wkn) {
		return shares.get(wkn);
	}
	
	public void updatePricesHistoric () {
		for (Share s : shares.values()) {
			s.getPricesHistoric();
		}
	}
	
	public void updatePricesIntraday () {
		for (Share s : shares.values()) {
			s.getPricesIntraday();
		}
	}

}
