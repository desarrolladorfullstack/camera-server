SELECT f.*, ARRAY_TO_STRING(ARRAY_AGG(r.content_block), ' ') as content FROM records r
INNER JOIN file_records x ON r.record_id = x.record_key
INNER JOIN files f ON f.file_id = x.file_key 
AND f.mime_type like '%image/jpeg%' AND f.file_stamp BETWEEN '2022-09-27' AND '2022-09-28'
GROUP BY f.file_id;

SELECT /*f.*, */ARRAY_TO_STRING(ARRAY_AGG(convert_from(r.content_block, 'UTF8') ORDER BY r.record_offset),'') as content,
                LENGTH(ARRAY_TO_STRING(ARRAY_AGG(convert_from(r.content_block, 'UTF8') ORDER BY r.record_offset),''))/2 size
FROM records r
         INNER JOIN file_records x ON r.record_id = x.record_key
         INNER JOIN files f ON f.file_id = x.file_key
    AND f.mime_type ILIKE CONCAT('%', ?, '%')
    AND f.file_stamp BETWEEN ? AND ? /*AND f.file_id=8178*/
        INNER JOIN device d ON f.device_key = d.device_id
            AND d.device_id IN (?)
GROUP BY f.file_id
ORDER BY f.file_id DESC;

SELECT concat('"', convert_from(event_key, 'utf8'), '": "', convert_from(property_value, 'utf8'), '"') prop_json
     /*, convert_from(event_key, 'utf8') evt,  convert_from(property_value, 'utf8') prop*/
     , concat(encode(event_key, 'hex'), chr(9), encode(property_value, 'hex')) prop_bin
     /*,  encode(event_key, 'hex') evt_hex, encode(property_value, 'hex') prop_hex*/
     , event_key, property_value
     /* ,  * */
    , property_id _id
FROM properties p
INNER JOIN device_properties dp ON p.property_id = dp.property_key
    AND dp.property_stamp BETWEEN ? AND ?
INNER JOIN device d ON dp.device_key = d.device_id
    AND d.device_id IN (?);

SELECT concat('{', string_agg(
    concat('"', convert_from(event_key, 'utf8'), '": "', convert_from(p.property_value, 'utf8'), '"')
    , ',' order by dp.property_stamp), '}' )::json  prop_json
    /*, convert_from(event_key, 'utf8') evt,  convert_from(property_value, 'utf8') prop*/
     /*, concat(encode(event_key, 'hex'), chr(9), encode(property_value, 'hex')) prop_bin*/
    /*,  encode(event_key, 'hex') evt_hex, encode(property_value, 'hex') prop_hex*/
     /*, event_key, property_value*/
    /* ,  * */
    /* , property_id _id*/
FROM properties p
         INNER JOIN device_properties dp ON p.property_id = dp.property_key
    AND dp.property_stamp BETWEEN ? AND ?
         INNER JOIN device d ON dp.device_key = d.device_id
    AND d.device_id IN (?)
GROUP BY dp.property_stamp;

SELECT concat('[', string_agg(prop_json, ', '), ']')::json prop_array
FROM (SELECT concat('{"', dp.property_stamp,'":','{', string_agg(
        concat('"', convert_from(event_key, 'utf8'), '": "', convert_from(p.property_value, 'utf8'), '"')
    , ',' order by dp.property_stamp), '}}' )/*::json*/ prop_json
          /*, convert_from(event_key, 'utf8') evt,  convert_from(property_value, 'utf8') prop*/
          /*, concat(encode(event_key, 'hex'), chr(9), encode(property_value, 'hex')) prop_bin*/
          /*,  encode(event_key, 'hex') evt_hex, encode(property_value, 'hex') prop_hex*/
          /*, event_key, property_value*/
          /* ,  * */
          /* , property_id _id*/
      FROM properties p
               INNER JOIN device_properties dp ON p.property_id = dp.property_key
          AND dp.property_stamp BETWEEN ? AND ?
               INNER JOIN device d ON dp.device_key = d.device_id
          AND d.device_id IN (?)
      GROUP BY dp.property_stamp) prop_query;

-- Consulta de propiedades por fecha e imei
SELECT concat('[', string_agg(prop_json, ', '), ']')::json prop_array
FROM (SELECT concat(/*'{"', dp.property_stamp,'":',*/
    '{"timestamp":"', dp.property_stamp,'",', string_agg( concat('"',
            convert_from(event_key, 'utf8'), '":"', convert_from(p.property_value, 'utf8'),
            '"') , ',' order by dp.property_stamp), ',"event":"', e.event_name,'"}'/*,'}'*/ )/*::json*/ prop_json
          /*, convert_from(event_key, 'utf8') evt,  convert_from(property_value, 'utf8') prop*/
          /*, concat(encode(event_key, 'hex'), chr(9), encode(property_value, 'hex')) prop_bin*/
          /*,  encode(event_key, 'hex') evt_hex, encode(property_value, 'hex') prop_hex*/
          /*, event_key, property_value*/
          /* ,  * */
          /* , property_id _id*/
      FROM properties p
               INNER JOIN device_properties dp ON p.property_id = dp.property_key
          AND dp.property_stamp BETWEEN ? AND ?
               INNER JOIN device d ON dp.device_key = d.device_id
          AND d.device_id IN (?)
                LEFT JOIN events e ON dp.parent_event = e.event_id
      GROUP BY dp.property_stamp, e.event_id) prop_query;

DELETE FROM device_properties
WHERE property_stamp >= '2023-06-01';-- '55401-12-10';
DELETE FROM properties WHERE property_id NOT IN (SELECT property_key FROM device_properties);

SELECT property_id FROM properties WHERE
        event_key = decode('6576656e745f6964', 'hex')
                                     AND property_value =  decode('343939', 'hex');

INSERT INTO properties (event_key, property_value)
VALUES (decode('6576656e745f6964', 'hex'), decode('343939', 'hex'));

SELECT p.property_id, EXTRACT(EPOCH FROM dp.property_stamp::timestamp)
FROM properties p
         INNER JOIN device_properties dp ON dp.device_key IN ('860896050794858')
    AND dp.parent_event IN (decode('343939', 'hex'))
    AND dp.property_key = p.property_id
    AND EXTRACT(EPOCH FROM dp.property_stamp::timestamp) = 1668696842
WHERE p.event_key = decode('6C61746974756465', 'hex')
  AND p.property_value = decode('342E36323435333636', 'hex');

INSERT INTO device_properties (device_key, property_key, property_stamp, parent_event)
SELECT '860896050794858', sq.last_value,
       to_timestamp(1685616348), decode('343939', 'hex')
FROM properties_property_id_seq sq;

SELECT p.property_id, EXTRACT(EPOCH FROM dp.property_stamp::timestamp),
       EXTRACT(EPOCH FROM dp.property_stamp::timestamp) + 18000
FROM properties p
         INNER JOIN device_properties dp
                    ON dp.device_key IN ('860896050794858')
                        AND dp.parent_event IN (decode('323532', 'hex'))
                        AND dp.property_key = p.property_id
--                AND EXTRACT(EPOCH FROM dp.property_stamp::timestamp) = 1685611046
WHERE p.event_key = decode('6576656e745f6964', 'hex')
  AND p.property_value = decode('323532', 'hex');