// gcc -c -I/data/repo/bzr/5.5/include/mysql -I/data/repo/bzr/5.5/include/mysql/.. test2.c && gcc -o test2 test2.o -L/data/repo/bzr/5.5/libmysql -lmysqlclient  && ./test2


#include <my_global.h>
#include <mysql.h>

void run_ps(MYSQL *con, const char *query)
{
  MYSQL_STMT *stmt = mysql_stmt_init(con);
//  fprintf(stderr,"Running %s\n",query);
  if (mysql_stmt_prepare(stmt,query, strlen(query))) 
  {
    fprintf(stderr, "Error on query \n%s\n: %s\n", query,mysql_error(con));
//    exit(1);
  }
  else {
  if (mysql_stmt_execute(stmt))
      {
        fprintf(stderr, "Error on query %s: %s\n", query, mysql_stmt_error(stmt));
    //    exit(1);
      }
  }
  mysql_stmt_close(stmt);
}

int main(int argc, char **argv)
{  
  MYSQL *con = mysql_init(NULL);

  if (con == NULL) 
  {
      fprintf(stderr, "%s\n", mysql_error(con));
      exit(1);
  }
  if (mysql_real_connect(con, "127.0.0.1", "root", "", 
          "supp", 19300, NULL, 0) == NULL) 
  {
      fprintf(stderr, "%s\n", mysql_error(con));
      mysql_close(con);
      exit(1);
  }

    run_ps(con,"set names 'utf8' collate 'utf8_unicode_ci'");
    run_ps(con,"set session sql_mode=''");
    run_ps(con,"truncate `certified`");
    
    run_ps(con,
    "insert into certified SELECT *                                                              -- Parte 1 : Emitidos\n"
    "                     FROM ( SELECT NULL AS organizacion, t1.subjectDN,\n"
    "                        SUBSTRING(\n"
    "                         SUBSTRING(t2.userDataVO, LOCATE('1.3.6.1.4.1.35300.1.1.2.2.1=', t2.userDataVO) + 28, 15),\n"
    "                          1,\n"
    "                        LOCATE(\n"
    "                           '<',\n"
    "                           REPLACE(\n"
    "                          SUBSTRING( t2.userDataVO, LOCATE('1.3.6.1.4.1.35300.1.1.2.2.1=',t2.userDataVO) + 28, 15),\n"
    "                          ',',\n"
    "                          '<'))\n"
    "                          - 1) AS solicitud,\n"
    "                       SUBSTRING(t1.issuerDN, 1, 21) AS emisor,\n"
    "                       FROM_UNIXTIME(SUBSTRING(t2.userDataVO, LOCATE('timeModified', t2.userDataVO) + 62, 10)) AS fecha_solicitud,\n"
    "                       FROM_UNIXTIME(SUBSTRING(t2.timestamp, 1, 10)) AS fecha_gencer,\n"
    "                       FROM_UNIXTIME(SUBSTRING(t1.expireDate, 1, 10)) AS fecha_expira,\n"
    "                       NULL AS fecha_revocado,\n"
    "                       NULL AS fecha_anulado,\n"
    "                       NULL AS repetido,\n"
    "                       'Emitido' AS estado,\n"
    "                       t1.username\n"
    "                      FROM CertificateData t1\n"
    "                       LEFT JOIN CertReqHistoryData t2\n"
    "                          ON t1.fingerprint = t2.fingerprint\n"
    "                          ) a\n"
    "                    WHERE fecha_expira IS NOT NULL\n"
    "                    AND solicitud NOT IN ('-1', '-2', '', 'NULL')\n"
    "                UNION\n"
    "                    SELECT *                                                              -- Parte 2 : Pendientes\n"
    "                    FROM ( SELECT NULL AS organizacion, t1.subjectDN,\n"
    "                       SUBSTRING(subjectAltName, LOCATE('1.3.6.1.4.1.35300.1.1.2.2.1=', t1.subjectAltName)+ 28) AS solicitud,\n"
    "                       IF(SUBSTRING(t2.certificateProfileName, 1, 8) = 'ReniecC1','CN=RENIEC Class I CA',\n"
    "                       IF(SUBSTRING(t2.certificateProfileName, 1, 8) = 'ReniecC2','CN=RENIEC Class II CA',\n"
    "                       IF(SUBSTRING(t2.certificateProfileName, 1, 8) = 'ReniecC3','CN=RENIEC Class III C','CN=RENIEC Class V CA'))) AS emisor,\n"
    "                       FROM_UNIXTIME(SUBSTRING(t1.timeModified, 1, 10)) AS fecha_solicitud,\n"
    "                       NULL AS fecha_gencer,\n"
    "                       NULL AS fecha_expira,\n"
    "                       NULL AS fecha_revocado,\n"
    "                       NULL AS fecha_anulado,\n"
    "                       NULL AS repetido,\n"
    "                       'Pendiente' AS estado,\n"
    "                       t1.username\n"
    "                      FROM UserData t1\n"
    "                      INNER JOIN CertificateProfileData t2 ON t1.certificateProfileId = t2.id\n"
    "                     WHERE t1.status = 10 ) b\n"
    "                UNION\n"
    "                    SELECT *                                           -- Parte 3 : Anulado\n"
    "                    FROM ( SELECT NULL AS organizacion, t1.subjectDN,\n"
    "                        SUBSTRING(t1.subjectAltName, LOCATE('1.3.6.1.4.1.35300.1.1.2.2.1=', t1.subjectAltName) + 28, 15) AS solicitud,\n"
    "                        IF(SUBSTRING(t2.certificateProfileName, 1, 8) = 'ReniecC1','CN=RENIEC Class I CA',\n"
    "                        IF(SUBSTRING(t2.certificateProfileName, 1, 8) = 'ReniecC2','CN=RENIEC Class II CA',\n"
    "                        IF(SUBSTRING(t2.certificateProfileName, 1, 8) = 'ReniecC3','CN=RENIEC Class III C','CN=RENIEC Class V CA'))) AS emisor,\n"
    "                        FROM_UNIXTIME(SUBSTRING(t1.timeModified, 1, 10)) AS fecha_solicitud,\n"
    "                        NULL AS fecha_gencer,\n"
    "                        NULL AS fecha_expira,\n"
    "                        NULL AS fecha_revocado,\n"
    "                        t1.almacenado AS fecha_anulado,\n"
    "                        NULL AS repetido,\n"
    "                        'Anulado' AS estado,\n"
    "                        t1.username\n"
    "                    FROM UserDataAnulado t1\n"
    "                    INNER JOIN CertificateProfileData t2 ON t2.id = t1.certificateProfileId\n"
    "                    WHERE t1.status = 10\n"
    "                    ) c\n"
    "                UNION\n"
    "                    SELECT NULL AS organizacion, subjectDN,                                       -- Parte 4 : Cancelado\n"
    "                    solicitud,\n"
    "                    (SELECT CASE\n"
    "                          WHEN SUBSTRING(t2.certificateProfileName, 1, 8) =\n"
    "                          'ReniecC1'\n"
    "                          THEN\n"
    "                         'CN=RENIEC Class I CA'\n"
    "                          WHEN SUBSTRING(t2.certificateProfileName, 1, 8) =\n"
    "                          'ReniecC2'\n"
    "                          THEN\n"
    "                         'CN=RENIEC Class II CA'\n"
    "                          WHEN SUBSTRING(t2.certificateProfileName, 1, 8) =\n"
    "                          'ReniecC3'\n"
    "                          THEN\n"
    "                         'CN=RENIEC Class III C,'\n"
    "                          ELSE\n"
    "                         'CN=RENIEC Class V CA'\n"
    "                       END\n"
    "                      FROM CertificateProfileData t2\n"
    "                     WHERE t2.id = tabla_cancelado.certificateProfileId)\n"
    "                      AS emisor,\n"
    "                      fechasol,\n"
    "                    NULL AS fecha_gencer,\n"
    "                    NULL AS fechaexpira,\n"
    "                    fecharevocado,\n"
    "                    NULL AS fechaanulado,\n"
    "                    repetido,\n"
    "                    'Cancelado' AS estado,\n"
    "                    username\n"
    "                    FROM (SELECT MAX(subjectDN) AS subjectDN,\n"
    "                       FROM_UNIXTIME(SUBSTRING(MAX(updateTime), 1, 10)) AS fechasol,\n"
    "                       CONCAT('EREP:', tag) AS solicitud,\n"
    "                       COUNT(tag) AS repetido,\n"
    "                       FROM_UNIXTIME(SUBSTRING(revocationDate, 1, 10))\n"
    "                          AS fecharevocado,\n"
    "                       STATUS,\n"
    "                       certificateProfileId,\n"
    "                       username\n"
    "                      FROM CertificateData\n"
    "                     WHERE tag IS NOT NULL AND (LENGTH(tag) > 0)\n"
    "                    GROUP BY tag) tabla_cancelado"
    );
    run_ps(con,"select count(*) as total from (  select * from certified   ) a");
    
    run_ps(con,"select * from certified  limit 0, 15000");
    run_ps(con,"select * from certified  limit 15000, 15000");
    run_ps(con,"select * from certified  limit 30000, 15000");
    run_ps(con,"select * from certified  limit 45000, 15000");
    run_ps(con,"select * from certified  limit 60000, 15000");
    run_ps(con,"select * from certified  limit 75000, 15000");
    run_ps(con,"select * from certified  limit 90000, 15000");
    run_ps(con,"select * from certified  limit 105000, 15000");
    run_ps(con,"select * from certified  limit 120000, 15000");
    run_ps(con,"select * from certified  limit 135000, 15000");
    run_ps(con,"select * from certified  limit 150000, 15000");
    run_ps(con,"select * from certified  limit 165000, 15000");
  mysql_close(con);

  exit(0);
}


