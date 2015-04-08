import java.io.File;


public class Momentum_pp {

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		AllShares allshares = new AllShares();
		//Dax
		Index dax = new Index("DAX",allshares);
		try {
			dax.initFromCSVDAXonly(new File("C:\\Users\\HellwigP\\Documents\\4 Technology\\00 Development\\momentum_pp\\data\\index_dax.csv"));
		} catch (Exception e) {
			e.printStackTrace();
		}
		dax.addFromWeb();
		System.out.println("-----------------DAX---------------------------");
		String[] p = dax.getPrintableShares();
		for (int i=0; i<p.length;i++) System.out.println(p[i]);
	    System.out.println("-----------------------------------------------");
	   
	    /*
	    Index mdax = new Index("MDAX",allshares);
		try {
			mdax.initFromCSV(new File("C:\\Users\\HellwigP\\Documents\\4 Technology\\00 Development\\momentum_pp\\data\\index_mdax.csv"));
		} catch (Exception e) {
			e.printStackTrace();
		}
		mdax.addFromWeb();
		System.out.println("-----------------MDAX---------------------------");
		p = mdax.getPrintableShares();
		for (int i=0; i<p.length;i++) System.out.println(p[i]);
		System.out.println("-----------------------------------------------");
		*/
	}

}
