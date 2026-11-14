CREATE VIEW weld_inspection_summary AS
SELECT w.weld_joint_id, w.weld_joint_no, COUNT(i.inspection_id) AS inspection_count
FROM weld_joint AS w
LEFT JOIN inspection AS i ON i.weld_joint_id = w.weld_joint_id
GROUP BY w.weld_joint_id, w.weld_joint_no;

SELECT * FROM weld_inspection_summary ORDER BY weld_joint_no;

SELECT s.spool_code, COUNT(c.component_id) AS component_count
FROM spool AS s
LEFT JOIN component AS c ON c.spool_id = s.spool_id
GROUP BY s.spool_id, s.spool_code
ORDER BY s.spool_code;
