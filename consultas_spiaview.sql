SELECT /*f.*, */ARRAY_TO_STRING(ARRAY_AGG(convert_from(r.content_block, 'UTF8') ORDER BY r.record_offset),'') as content,
       LENGTH(ARRAY_TO_STRING(ARRAY_AGG(convert_from(r.content_block, 'UTF8') ORDER BY r.record_offset),''))/2 size
FROM records r
         INNER JOIN file_records x ON r.record_id = x.record_key
         INNER JOIN files f ON f.file_id = x.file_key
    AND f.mime_type like '%application/octet-stream%'
    AND f.file_stamp BETWEEN '2023-05-16' AND '2023-05-18' AND f.file_id=8178
GROUP BY f.file_id
ORDER BY f.file_id DESC