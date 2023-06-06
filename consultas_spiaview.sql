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