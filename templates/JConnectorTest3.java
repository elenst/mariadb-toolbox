import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;
import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

public class JConnectorTest2
{
    public static void main (String argv[])    
    {
        Connection conn;
        try {
            conn = DriverManager.getConnection("jdbc:mariadb://localhost:3306/test","root","");
            Statement st = conn.createStatement();
            st.execute("CREATE TABLE IF NOT EXISTS t1 (i INT) AS SELECT 1 AS i");
            st.execute("CREATE PROCEDURE IF NOT EXISTS pr (OUT x INT) SELECT * FROM t1 LIMIT 0");
            CallableStatement ps = conn.prepareCall("call pr(?)");
            ps.registerOutParameter(1, Types.INTEGER);
            ps.execute();
        }
        catch (Exception e)
        {
            System.out.println("Exception: " + e + "\n");
        }
    } 
}
