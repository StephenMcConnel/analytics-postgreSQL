REVOKE SELECT ON bloomreader.ComprehensionPNG FROM bloomreaderuser;
DROP VIEW bloomreader.ComprehensionPNG CASCADE;

CREATE VIEW bloomreader.ComprehensionPNG AS
	SELECT DISTINCT a.title AS Title_Tested,
          COUNT(a.title) AS Tests_Taken,
          a.timestamp,
          a.percent_right,
          a.right_first_time AS Number_Right_1st_Time,
          a.question_count AS Number_of_Questions,
          a.branding_project_name AS Branding,
          b.country_name AS Country,
          x.title, x.median_percent_right 
          FROM (SELECT y.title, ROUND(AVG(y.percent_right), 0) AS median_percent_right  
	 			FROM (
   				 SELECT z.title, z.percent_right, COUNT(z.title),
      				ROW_NUMBER() OVER (ORDER BY z.title ASC, COUNT(z.title)*z.percent_right  ASC) AS rows_ascending,
      				ROW_NUMBER() OVER (ORDER BY z.title ASC, COUNT(z.title)*z.percent_right DESC) AS rows_descending
                    FROM (SELECT * FROM bloomreader.questions_correct 
							UNION ALL
							SELECT * FROM bloomreaderbeta.questions_correct) AS z
                    GROUP BY z.title, z.percent_right
	 			     ) AS y
                 WHERE rows_ascending BETWEEN rows_descending - 1 AND rows_descending + 1
                 GROUP BY y.title
             ) AS x 
    INNER JOIN (SELECT * FROM bloomreader.questions_correct 
				UNION ALL
				SELECT * FROM bloomreaderbeta.questions_correct) AS a 
				ON a.title = x.title  
	INNER JOIN public.ip2loc_sm_tab AS b ON	   	       
			public.ip2int(a.context_ip) = b.context_ip				
    GROUP BY a.title, x.title,  x.median_percent_right,  
             a.question_count, a.right_first_time, a.percent_right, b.country_name, a.branding_project_name, a.timestamp  
    ORDER BY a.title;
    
GRANT SELECT ON bloomreader.ComprehensionPNG TO bloomreaderuser;
select * FROM bloomreader.ComprehensionPNG;