SELECT f.*, 1024*count(r.record_id) size records
FROM files f
INNER JOIN file_records x ON f.file_id = x.file_key
INNER JOIN records r ON r.record_id = x.record_key
GROUP BY f.file_id
ORDER BY f.file_id;

SELECT last_value FROM files_file_id_seq;