import java.sql.DriverManager;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.SQLException;
import java.sql.SQLDataException;
import java.sql.SQLWarning;
import java.sql.Timestamp;


public class JConnectorTest2
{
	public static void main (String argv[])	
	{
		ResultSet rs;
		Boolean ret;
        PreparedStatement injerto;
        Connection conn;
		int year = 1, mes = 1, dia = 1;
        Timestamp sqldate = new java.sql.Timestamp(System.currentTimeMillis());
        String sql;
		try {
//         JdbcTemplate jdbcTemplate = getJdbcTemplate();
			 conn = DriverManager.getConnection("jdbc:mariadb://localhost:3308/test","root","");

            try {
    //            jdbcTemplate.execute("DROP TABLE customers IF EXISTS");
                sql = "INSERT INTO t (start_date) VALUES (?)";
                PreparedStatement ps = conn.prepareStatement(sql);
              ps.setTimestamp(1, new Timestamp(null));

    //            Statement st = conn.createStatement();
    //            st.execute("INSERT INTO t (start_date) VALUES ('2016-12-14 00:27:01.919000')" );

            ps.addBatch();
            ps.executeBatch();
                SQLWarning warning = ps.getWarnings();
                if (warning != null)
                {
                    System.out.println("---Warning---");
                    while (warning != null)
                    {
                        System.out.println("Message: " + warning.getMessage());
                        System.out.println("SQLState: " + warning.getSQLState());
                        System.out.println(warning.getErrorCode());
                        warning = warning.getNextWarning();
                    }
                }
            }
            catch (SQLDataException sqle) {
                System.out.println("Got exception");
                sqle.printStackTrace();
                System.exit(0);
            }
        }
        catch (SQLDataException sqle) {
            System.out.println("Exception");
//            sqle.printStackTrace();
            System.exit(0);
        }
		catch (Exception e)
		{
			System.out.println("Exception: " + e + "\n");
		}
	} 
}

