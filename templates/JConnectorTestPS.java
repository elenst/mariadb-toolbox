import java.sql.DriverManager;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.util.Arrays;

public class JConnectorTestPS
{
  public static void main (String argv[])	
  {
    Boolean ret;
    PreparedStatement injerto;
    Connection conn;
    try {
      conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/test","root","");
      PreparedStatement ps = conn.prepareStatement("EXPLAIN SELECT * INTO OUTFILE 'load.data' FROM mysql.db");
      ps.addBatch();
      int[] count = ps.executeBatch();
      System.out.println("Result: " + Arrays.toString(count));
    }
    catch (Exception e)
    {
      System.out.println("Exception: " + e + "\n");
    }
  }
} 

