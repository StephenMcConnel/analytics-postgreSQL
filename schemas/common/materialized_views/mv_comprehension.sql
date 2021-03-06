-- Materialized View: common.mv_comprehension

-- DROP MATERIALIZED VIEW common.mv_comprehension;

CREATE MATERIALIZED VIEW common.mv_comprehension AS
    SELECT  *,
            'bloomreader' AS source
    FROM    bloomreader.v_comprehension
    UNION ALL
    SELECT  *,
            'bloomlibrary' AS source
    FROM    bloomlibrary_org.v_comprehension;

-- Be sure to recreate these if you need to drop the view.
CREATE INDEX idx_mvcomp_book_instance_id
    ON common.mv_comprehension USING btree
    (book_instance_id COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;

CREATE INDEX idx_mvcomp_book_instance_id_and_source
    ON common.mv_comprehension USING btree
    (book_instance_id COLLATE pg_catalog."default" ASC NULLS LAST, 
    source COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;

CREATE INDEX idx_mvcomp_book_instance_id_and_source_and_date_local
    ON common.mv_comprehension USING btree
    (book_instance_id COLLATE pg_catalog."default" ASC NULLS LAST, 
    source COLLATE pg_catalog."default" ASC NULLS LAST, 
    date_local ASC NULLS LAST)
    TABLESPACE pg_default;

CREATE INDEX idx_mvcomp_book_instance_id_and_date_local
    ON common.mv_comprehension USING btree
    (book_instance_id COLLATE pg_catalog."default" ASC NULLS LAST, 
    date_local ASC NULLS LAST)
    TABLESPACE pg_default;