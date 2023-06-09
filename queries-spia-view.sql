-- SCHEMA: public

-- estimate size videos
SELECT f.* , sum(LENGTH(r.content_block)/2) size
FROM files f
INNER JOIN file_records x ON x.file_key = f.file_id 
INNER JOIN records r ON x.record_key = r.record_id
WHERE f.mime_type like '%application/octet-stream%'
-- AND f.file_stamp BETWEEN '2022-11-17' AND '2022-11-18'
GROUP BY f.file_id
ORDER BY f.file_id DESC;

-- estimate size images
SELECT f.* , sum(LENGTH(r.content_block)/2) size
FROM files f
INNER JOIN file_records x ON x.file_key = f.file_id 
INNER JOIN records r ON x.record_key = r.record_id
WHERE f.mime_type like '%image/jpeg%'
-- AND f.file_stamp BETWEEN '2022-11-17' AND '2022-11-18'
GROUP BY f.file_id
ORDER BY f.file_id DESC;

-- estimate length
SELECT r.record_id , r.record_stamp, LENGTH(r.content_block)/2 size
FROM records r;

-- load image
SELECT f.*, ARRAY_TO_STRING(ARRAY_AGG(convert_from(r.content_block, 'UTF8')
        ORDER BY x.record_key),'') as content FROM records r
    INNER JOIN file_records x ON r.record_id = x.record_key
    INNER JOIN files f ON f.file_id = x.file_key
    AND f.mime_type like '%image/jpeg%'
   -- AND f.file_stamp BETWEEN '2022-09-27' AND '2022-09-28'
GROUP BY f.file_id
ORDER BY f.file_id DESC;

-- load video
SELECT f.*, ARRAY_TO_STRING(ARRAY_AGG(convert_from(r.content_block, 'UTF8')
        ORDER BY r.record_offset),'') as content FROM records r
    INNER JOIN file_records x ON r.record_id = x.record_key
    INNER JOIN files f ON f.file_id = x.file_key
    AND f.mime_type like '%application/octet-stream%'
-- AND f.file_stamp BETWEEN '2022-09-27' AND '2022-09-28'
GROUP BY f.file_id
ORDER BY f.file_id DESC;

-- records & size
SELECT x.*, LENGTH(r.content_block) size 
FROM file_records x, records r WHERE r.record_id = x.record_key AND x.file_key = 8177;

-- props name
SELECT convert_from(event_key, 'utf8') evt,  convert_from(property_value, 'utf8') prop, property_id
     -- , *
FROM properties;

-- events (_id: hex)
SELECT encode(event_id, 'hex')::text evt, event_name
     -- , *
FROM events;

-- device properties By: timestamp & device_id
SELECT concat('[', string_agg(prop_json, ', '), ']')::json prop_array
FROM (SELECT concat(
    '{"datetime":"', dp.property_stamp,'",', string_agg( concat('"',
        COALESCE(e2.event_name, convert_from(p.event_key, 'utf8')), '":"',
            convert_from(p.property_value, 'utf8'), '"')
        , ',' order by dp.property_stamp, p.property_id), ',"event":"', e.event_name,'"}' )  prop_json
      FROM properties p
               INNER JOIN device_properties dp ON p.property_id = dp.property_key
          AND dp.property_stamp BETWEEN ? AND ?
               INNER JOIN device d ON dp.device_key = d.device_id
          AND d.device_id IN (?)
               LEFT JOIN events e ON dp.parent_event = e.event_id
               LEFT JOIN events e2 ON p.event_key = e2.event_id
      GROUP BY dp.property_stamp, e.event_id) prop_query;