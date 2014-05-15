import java.sql.DriverManager;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;


public class JConnectorTest
{
	public static void main (String argv[])	
	{
		ResultSet rs;
		Boolean ret;
		int updCount = 0, updCountTotal = 0;
		try {
			Statement st = DriverManager.getConnection("jdbc:mysql://localhost:3306/","root","").createStatement();
			st.execute("use test");
			updCount = st.getUpdateCount();
			System.out.println("Updated rows (1st get): " + updCount);
			st.getMoreResults();
			updCount = st.getUpdateCount();
			System.out.println("Updated rows (2nd get): " + updCount);
		}
		catch (Exception e)
		{
			System.out.println("Exception: " + e + "\n");
		}
	} 
}

