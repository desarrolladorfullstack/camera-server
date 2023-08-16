create table codes
(
    code_id            bytea not null
        constraint codes_pk
            primary key,
    code_length        integer default 1,
    code_status        integer default 1,
    code_measure_unit  varchar,
    code_math_multiple double precision
);

create table code_names
  (
      code_key             bytea not null,
      code_name            varchar not null,
      country_language_iso varchar default 'en-US',
      code_name_status     integer default 1
  );
comment on table code_names is 'codes (avl) names by country/language ISO';
comment on column code_names.code_key is 'codes->codes_pk(foreign code_id)';
comment on column code_names.code_name_status is '1 activated (...)';
create unique index code_names_code_name_uindex
    on code_names (code_name);

create table code_values
(
    value_id             bytea   not null,
    code_key             bytea   not null,
    value_name           varchar not null,
    country_language_iso varchar default 'en-US',
    code_value_status    integer default 1
);

create unique index code_values_value_name_uindex
    on code_values (value_name);

DROP VIEW IF EXISTS view_device_properties;
CREATE MATERIALIZED VIEW view_device_properties
AS
SELECT concat(
    '{"datetime":"', dp.property_stamp,'",', string_agg( concat('"',
        COALESCE( COALESCE(cn.code_name, e2.event_name), convert_from(p.event_key, 'utf8')), '":"',
            COALESCE(cv.value_name, convert_from(p.property_value, 'utf8')) , '"')
        , ',' order by dp.property_stamp, p.property_id), ',"event":"', e.event_name,'"}' )  prop_json,
        d.device_id _id
      FROM properties p
               INNER JOIN device_properties dp ON p.property_id = dp.property_key
          -- AND dp.property_stamp BETWEEN ? AND ?
               INNER JOIN device d ON dp.device_key = d.device_id
          -- AND d.device_id IN (?)
               LEFT JOIN events e ON dp.parent_event = e.event_id
               LEFT JOIN events e2 ON p.event_key = e2.event_id
               LEFT JOIN codes c
                   ON e2.event_id = c.code_id
                          AND c.code_status NOT IN (0)
               LEFT JOIN code_names cn
                   ON c.code_id = cn.code_key
                          AND cn.code_name_status NOT IN (0)
            AND cn.country_language_iso ILIKE 'en-%'
               LEFT JOIN code_values cv
                   ON p.property_value = cv.value_id AND p.event_key = cv.code_key
                          AND cv.code_value_status NOT IN (0)
                          AND cv.country_language_iso = cn.country_language_iso
           -- AND cn.country_language_iso ILIKE ?
      GROUP BY dp.property_stamp, e.event_id, d.device_id;

DROP VIEW IF EXISTS view_device_properties_es;
CREATE MATERIALIZED VIEW view_device_properties_es
AS
SELECT concat(
    '{"datetime":"', dp.property_stamp,'",', string_agg( concat('"',
        COALESCE( COALESCE(cn.code_name, e2.event_name), convert_from(p.event_key, 'utf8')), '":"',
        COALESCE(cv.value_name, convert_from(p.property_value, 'utf8')) , '"')
        , ',' order by dp.property_stamp, p.property_id), ',"event":"', e.event_name,'"}' )  prop_json,
       d.device_id _id
FROM properties p
         INNER JOIN device_properties dp ON p.property_id = dp.property_key
    -- AND dp.property_stamp BETWEEN ? AND ?
         INNER JOIN device d ON dp.device_key = d.device_id
    -- AND d.device_id IN (?)
         LEFT JOIN events e ON dp.parent_event = e.event_id
         LEFT JOIN events e2 ON p.event_key = e2.event_id
         LEFT JOIN codes c
             ON e2.event_id = c.code_id
                      AND c.code_status NOT IN (0)
        LEFT JOIN code_names cn
            ON c.code_id = cn.code_key
                  AND cn.code_name_status NOT IN (0)
    AND cn.country_language_iso ILIKE 'es-%'
        LEFT JOIN code_values cv
           ON p.property_value = cv.value_id AND p.event_key = cv.code_key
                  AND cv.code_value_status NOT IN (0)
                  AND cv.country_language_iso = cn.country_language_iso
    -- AND cn.country_language_iso ILIKE ?
GROUP BY dp.property_stamp, e.event_id, d.device_id;

DROP MATERIALIZED VIEW IF EXISTS view_property_id_by;
create MATERIALIZED VIEW view_property_id_by AS
SELECT distinct p.property_id, dp.device_key, dp.parent_event,
                dp.property_stamp, p.event_key, p.property_value
FROM properties p
     INNER JOIN device_properties dp
        ON dp.property_key = p.property_id
ORDER BY p.property_id DESC;

create index files_mime_type_index
    on files (mime_type);

create index files_temp_file_index
    on files (temp_file);

create index device_properties_device_key_index
    on device_properties (device_key);

create index device_properties_parent_event_index
    on device_properties (parent_event);

create index device_properties_property_key_index
    on device_properties (property_key);

