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
SELECT f.*, ARRAY_TO_STRING(ARRAY_AGG(convert_from(r.content_block, 'UTF8') ORDER BY x.record_key),'') as content FROM records r
    INNER JOIN file_records x ON r.record_id = x.record_key
    INNER JOIN files f ON f.file_id = x.file_key
    AND f.mime_type like '%image/jpeg%'
   -- AND f.file_stamp BETWEEN '2022-09-27' AND '2022-09-28'
GROUP BY f.file_id
ORDER BY f.file_id DESC;

-- load video
SELECT f.*, ARRAY_TO_STRING(ARRAY_AGG(convert_from(r.content_block, 'UTF8') ORDER BY r.record_stamp),'') as content FROM records r
    INNER JOIN file_records x ON r.record_id = x.record_key
    INNER JOIN files f ON f.file_id = x.file_key
    AND f.mime_type like '%application/octet-stream%'
-- AND f.file_stamp BETWEEN '2022-09-27' AND '2022-09-28'
GROUP BY f.file_id
ORDER BY f.file_id DESC;


SELECT x.*, LENGTH(r.content_block) size 
FROM file_records x, records r WHERE r.record_id = x.record_key AND x.file_key = 6715;