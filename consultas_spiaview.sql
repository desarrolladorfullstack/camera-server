SELECT /*f.*, */ARRAY_TO_STRING(ARRAY_AGG(convert_from(r.content_block, 'UTF8') ORDER BY r.record_offset),'') as content,
       LENGTH(ARRAY_TO_STRING(ARRAY_AGG(convert_from(r.content_block, 'UTF8') ORDER BY r.record_offset),''))/2 size
FROM records r
         INNER JOIN file_records x ON r.record_id = x.record_key
         INNER JOIN files f ON f.file_id = x.file_key
    AND f.mime_type like '%application/octet-stream%'
    AND f.file_stamp BETWEEN '2023-05-16' AND '2023-05-18' AND f.file_id=8178
GROUP BY f.file_id
ORDER BY f.file_id DESC;

 UPDATE properties
SET event_key = decode(encode('longitude','hex'),'hex'),
    property_value = decode(encode('-74.0905233','hex'),'hex') WHERE property_id =1;
UPDATE events SET event_id = decode(encode('longitude','hex'),'hex')
WHERE event_name = 'longitude';

UPDATE properties
SET event_key = decode(encode('latitude','hex'),'hex'),
    property_value = decode(encode('4.6245366','hex'),'hex') WHERE property_id = 2;
UPDATE events SET event_id = decode(encode('latitude','hex'),'hex')
WHERE event_name = 'latitude';

SELECT convert_from(event_key, 'utf8') evt,  convert_from(property_value, 'utf8') prop,  *
FROM properties;

SELECT encode(event_id, 'hex')::text evt, *
FROM events;

UPDATE events SET event_id = decode(replace(upper(encode(event_id,'hex')), 'EFBBBF', ''),'hex')
WHERE encode(event_id,'hex') ILIKE 'EFBBBF%';

UPDATE properties
SET property_value = decode(replace(upper(encode(property_value,'hex')), 'EFBBBF', ''),'hex')
WHERE encode(property_value,'hex') ILIKE 'EFBBBF%';

UPDATE properties
SET event_key = decode(replace(upper(encode(event_key,'hex')), 'EFBBBF', ''),'hex')
WHERE encode(event_key,'hex') ILIKE 'EFBBBF%';

UPDATE codes
SET code_id = decode(replace(upper(encode(code_id,'hex')), 'EFBBBF', ''),'hex')
WHERE encode(code_id,'hex') ILIKE 'EFBBBF%';

SELECT concat(
    '{"datetime":"', dp.property_stamp,'",', string_agg( concat('"',
        COALESCE(e2.event_name, convert_from(p.event_key, 'utf8')), '":"',
            convert_from(p.property_value, 'utf8'), '"')
        , ',' order by dp.property_stamp, p.property_id), ',"event":"', e.event_name,'"}' )  prop_json
      FROM properties p
               INNER JOIN device_properties dp ON p.property_id = dp.property_key
          -- AND dp.property_stamp BETWEEN ? AND ?
               INNER JOIN device d ON dp.device_key = d.device_id
          -- AND d.device_id IN (?)
               LEFT JOIN events e ON dp.parent_event = e.event_id
               LEFT JOIN events e2 ON p.event_key = e2.event_id
      GROUP BY dp.property_stamp, e.event_id;

SELECT concat(
    '{"datetime":"', dp.property_stamp,'",', string_agg( concat('"',
        COALESCE( COALESCE(cn.code_name, e2.event_name), convert_from(p.event_key, 'utf8')), '":"',
            COALESCE(cv.value_name, convert_from(p.property_value, 'utf8')) , '"')
        , ',' order by dp.property_stamp, p.property_id), ',"event":"', e.event_name,'"}' )  prop_json,
        d.device_id _id
      FROM properties p
               INNER JOIN device_properties dp ON p.property_id = dp.property_key
           AND dp.property_stamp BETWEEN ? AND ?
               INNER JOIN device d ON dp.device_key = d.device_id
            AND d.device_id IN (?)
               LEFT JOIN events e ON dp.parent_event = e.event_id
               LEFT JOIN events e2 ON p.event_key = e2.event_id
               LEFT JOIN codes c
                   ON e2.event_id = c.code_id
                          AND c.code_status NOT IN (0)
               LEFT JOIN code_names cn
                   ON c.code_id = cn.code_key
                          AND cn.code_name_status NOT IN (0)
                       AND cn.country_language_iso ILIKE ?
               LEFT JOIN code_values cv
                         ON p.property_value = cv.value_id AND p.event_key = cv.code_key
                             AND cv.code_value_status NOT IN (0)
                             AND cv.country_language_iso = cn.country_language_iso
           -- AND cn.country_language_iso ILIKE ?
      GROUP BY dp.property_stamp, e.event_id, d.device_id;

SELECT 
/* to_timestamp( */CAST (
(prop_json)::json ->> 'datetime'
 AS VARCHAR)/* , '"YYYY-MM-DD HH:MI:SS"') */ AS prop_date, _id
FROM view_device_properties
WHERE _id = '860896051208304'
AND (prop_json)::json ->> 'datetime' BETWEEN '2023-08-10' AND '2023-08-11 23:59:59';

SELECT concat('[', string_agg(prop_json, ', '), ']')::json prop_array
FROM view_device_properties_es
WHERE _id = '860896051208304'
AND prop_json::json ->> 'datetime'
    BETWEEN '2023-08-10' AND '2023-08-11 23:59:59';