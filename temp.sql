SELECT f.*, ARRAY_TO_STRING(ARRAY_AGG(r.content_block), ' ') as content FROM records r
INNER JOIN file_records x ON r.record_id = x.record_key
INNER JOIN files f ON f.file_id = x.file_key 
AND f.mime_type like '%image/jpeg%' AND f.file_stamp BETWEEN '2022-09-27' AND '2022-09-28'
GROUP BY f.file_id;