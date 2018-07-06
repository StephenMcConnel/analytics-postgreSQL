--DROP FUNCTION migrate_MPData_upload_book_success();

CREATE OR REPLACE FUNCTION migrate_MPData_upload_book_success()
RETURNS SETOF varchar AS $BODY$
DECLARE time_max_for_historical_data timestamp;
DECLARE new_id varchar(1024);
DECLARE err_constraint varchar(100);
DECLARE country_code_temp varchar(2);
DECLARE country_name_temp varchar(64);
DECLARE region_temp varchar(100);
DECLARE city_temp varchar(100);
DECLARE hold_country_code varchar(2);
DECLARE hold_country_name varchar(64);
DECLARE hold_region varchar(100);
DECLARE hold_city varchar(100);
DECLARE loc_uid_temp bigint;
DECLARE counter bigint;
DECLARE xyz CURSOR FOR SELECT * from bloomreadertest.mpdata_upload_book_success AS a
      WHERE to_timestamp(a.received_at) < time_max_for_historical_data 
	   ORDER BY a.mp_country, a.region, a.city;
DECLARE xyz_row RECORD;
BEGIN
new_id := '';
SELECT MAX(c.loc_uid) FROM public.countryregioncitylu AS c INTO counter;
SELECT MIN(b.timestamp) FROM bloomreadertest.clone_upload_book_success AS b 
 		into time_max_for_historical_data ;
FOR xyz_row IN xyz
    LOOP
	new_id := '';
	country_code_temp := NULL;
	country_name_temp := NULL;
	region_temp := NULL;
	city_temp := NULL;
	hold_country_code := NULL;
	hold_country_name := NULL;
	hold_region := NULL;
	hold_city := NULL;	
	SELECT gen_random_uuid() INTO new_id;
	country_code_temp := public.empty_to_null(xyz_row.mp_country);
	region_temp := public.empty_to_null(xyz_row.region);
	city_temp := public.empty_to_null(xyz_row.city);
	IF country_code_temp ='-' or country_code_temp IS NULL THEN 
	   country_code_temp := '-';
	END IF;	
	IF region_temp ='-' or region_temp IS NULL THEN 
	   region_temp := '-';
	END IF;
	IF city_temp ='-' or city_temp IS NULL THEN 
	   city_temp := '-';
	END IF;	
	SELECT DISTINCT (d.country_name) FROM public.ip2loc_sm_tab AS d 
		WHERE  d.country_code = country_code_temp  INTO country_name_temp;	
	IF public.empty_to_null(country_name_temp) IS NULL THEN
		SELECT DISTINCT (e.country_name) FROM public.ipv42location AS e 
		WHERE  e.country_code = country_code_temp  INTO country_name_temp;
		IF public.empty_to_null(country_name_temp) IS NULL THEN
			country_name_temp := '-';
		END IF;
	END IF;
	
	loc_uid_temp := NULL;
	SELECT i.loc_uid from public.countryregioncitylu AS i
		where i.country_code = country_code_temp
		AND i.region = region_temp
		AND i.city = city_temp
		INTO loc_uid_temp;
	IF loc_uid_temp IS NULL THEN
        counter := counter + CAST('1' AS bigint);
		loc_uid_temp := counter ;
		INSERT INTO  public.countryregioncitylu as p  
		( loc_uid, country_code, country_name, region, city  )  
		VALUES
		( loc_uid_temp, country_code_temp, country_name_temp, region_temp, city_temp ) ;
	END IF;

   	INSERT INTO bloomreadertest.clone_upload_book_success as s  
	( id, received_at, browser, channel, command_line, context_library_name, 
	  context_library_version, 
	  culture, --book_id, layout, portion, --mode,
	  --error, 
	  title, url, 
          current_directory, desktop_environment, 
	  dot_net_version, event, event_text, 
	  full_version, --ip, 
          original_timestamp, osversion, sent_at, timestamp, user_id, user_name, version, 
	  working_set, branding_project_name,
	  collection_country, country, 
	  language1_iso639_code, language1_iso639_name, language2_iso639_code, language3_iso639_code,
	  location_uid )
	VALUES
	(new_id, to_timestamp(xyz_row.received_at), public.empty_to_null(xyz_row.browser), 
	  public.empty_to_null(xyz_row.channel), 
	  public.empty_to_null(xyz_row.command_line), public.empty_to_null(xyz_row.context_library_name), 
	  public.empty_to_null(xyz_row.context_library_version), 
	  public.empty_to_null(xyz_row.culture),-- public.empty_to_null(xyz_row.error), 
	  public.empty_to_null(xyz_row.title), public.empty_to_null(xyz_row.url),
	  --public.empty_to_null(xyz_row.book_id), public.empty_to_null(xyz_row.layout),
	 -- public.empty_to_null(xyz_row.portion), --public.empty_to_null(xyz_row.mode), 
	  public.empty_to_null(xyz_row.current_directory), 
	  public.empty_to_null(xyz_row.desktop_environment), 
	  public.empty_to_null(xyz_row.dot_net_version), 
	  public.empty_to_null(xyz_row.event), public.empty_to_null(xyz_row.event_text), 
	  public.empty_to_null(xyz_row.full_version), 
	  --xyz_row.ip,
	  to_timestamp(xyz_row.received_at), public.empty_to_null(xyz_row.osversion), 
	  to_timestamp(xyz_row.received_at), to_timestamp(xyz_row.received_at),
	  public.empty_to_null(xyz_row.user_id), public.empty_to_null(initcap(xyz_row.user_name)), 
	  public.empty_to_null(xyz_row.version), public.empty_to_null(xyz_row.working_set), 
	  public.empty_to_null(xyz_row.branding_project_name), 	
	  public.empty_to_null(xyz_row.collection_country),
	  public.empty_to_null(xyz_row.country),
	  public.empty_to_null(xyz_row.language1_iso639_code), public.empty_to_null(xyz_row.language1_iso639_name), 
	  public.empty_to_null(xyz_row.language2_iso639_code), public.empty_to_null(xyz_row.language3_iso639_code),
	  loc_uid_temp );
     	--ON CONFLICT ON CONSTRAINT clone_created_pkey DO NOTHING;
	RETURN NEXT xyz_row.mp_country;			
END LOOP;

EXCEPTION
   WHEN SQLSTATE '23000' THEN  -- Class 23 Integrity Constraint Violation
      GET STACKED DIAGNOSTICS err_constraint = CONSTRAINT_NAME;
      -- do something with it, for instance:
      RAISE NOTICE '%', err_constraint;
      RAISE;  -- raise original error
END;
$BODY$ LANGUAGE plpgsql;

-- Column: bloomreadertest.clone_upload_book_success.location_uid
-- ALTER TABLE bloomreadertest.clone_upload_book_success DROP COLUMN location_uid;
ALTER TABLE bloomreadertest.clone_upload_book_success
    ADD COLUMN location_uid bigint;	
	
SELECT MIN(b.timestamp) FROM bloomreadertest.clone_upload_book_success AS b

--SELECT * FROM migrate_MPData_upload_book_success();
select * from bloomreadertest.mpdata_upload_book_success
select to_timestamp('1522771253');
select count(*) from bloomreadertest.clone_upload_book_success;
select count(*) from bloomreadertest.clone_upload_book_success;
select count(*) from bloomreadertest.mpdata_upload_book_success AS a
 where to_timestamp(a.received_at) < (SELECT MIN(b.timestamp) FROM bloomreadertest.clone_upload_book_success AS b);
SELECT * from bloomreadertest.clone_upload_book_success AS a;
SELECT * from bloomreadertest.mpdata_upload_book_success AS a
       WHERE to_timestamp(a.received_at) < 
	   (SELECT MIN(b.timestamp) FROM bloomreadertest.clone_upload_book_success AS b) 
	   ORDER BY a.mp_country, a.region, a.city;




