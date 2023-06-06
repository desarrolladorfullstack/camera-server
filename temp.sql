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

